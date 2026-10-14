(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.config)

(local reader (require :fennel-extras.reader))

(defn- error-at [message token]
  {:message message :line token.line :col token.col})

(defn- trivia? [child]
  (if child
      (if child.kind
          (or (= child.kind :whitespace)
              (= child.kind :newline)
              (= child.kind :comment)
              (= child.kind :tab))
          false)
      false))

(defn- meaningful-children [children]
  (let [result []]
    (each [_ child (ipairs children)]
      (if (not (trivia? child))
          (table.insert result child)))
    result))

(defn- decode-string [token]
  (let [text token.text
        n (string.len text)
        result []]
    (var i 2)
    (while (< i n)
      (let [c (string.sub text i i)]
        (if (= c "\\")
            (let [escaped (string.sub text (+ i 1) (+ i 1))]
              (if (= escaped "\"")
                  (table.insert result "\"")
                  (if (= escaped "\\")
                      (table.insert result "\\")
                      (if (= escaped "n")
                          (table.insert result "\n")
                          (if (= escaped "t")
                              (table.insert result "\t")
                              (error (error-at "unsupported string escape" token) 0)))))
              (set i (+ i 2)))
            (do
              (table.insert result c)
              (set i (+ i 1))))))
    (table.concat result)))

(defn- convert-symbol [token]
  (let [text token.text]
    (if (= (string.sub text 1 1) ":")
        (string.sub text 2)
        (if (= text "true")
            true
            (if (= text "false")
                false
                (if (= text "nil")
                    nil
                    (error (error-at "symbols are not allowed" token) 0)))))))

(defn- convert [node]
  (if (= node.kind :table)
      (let [children (meaningful-children node.children)
            result {}]
        (var i 1)
        (var failure nil)
        (if (= (math.fmod (length children) 2) 1)
            (error (error-at "table must contain key/value pairs" node.open) 0)
            (do
              (while (and (<= i (length children)) (not failure))
                (let [(key key-error) (convert (. children i))
                      (value value-error) (convert (rawget children (+ i 1)))]
                  (if key-error
                      (set failure key-error)
                      (if value-error
                          (set failure value-error)
                          (tset result key value))))
                (set i (+ i 2)))
              (if failure
                  (error failure 0)
                  result))))
      (if (= node.kind :sequence)
          (let [result []]
            (var failure nil)
            (each [_ child (ipairs (meaningful-children node.children))]
              (if (not failure)
                  (let [(value error) (convert child)]
                    (if error
                        (set failure error)
                        (table.insert result value)))))
            (if failure
                (error failure 0)
                result))
          (if (= node.kind :list)
              (error (error-at "lists are not allowed" node.open) 0)
              (if (= node.kind :string)
                  (decode-string node)
                  (if (= node.kind :symbol)
                      (convert-symbol node)
                      (if (= node.kind :number)
                          (let [(clean) (string.gsub node.text "_" "")]
                            (tonumber clean))
                          (if (= node.kind :prefix)
                              (error (error-at "reader prefixes are not allowed" node) 0)
                              (error (error-at "unsupported form" node) 0)))))))))

(defn parse-string [text]
  (let [(ok result) (pcall
                     (fn []
                       (let [(root reader-error) (reader.parse text)]
                         (if reader-error
                             {:error reader-error}
                             (let [children (meaningful-children root.children)]
                               (if (= (length children) 0)
                                   {:error {:message "expected one top-level table" :line 1 :col 1}}
                                   (if (> (length children) 1)
                                       {:error (error-at "expected exactly one top-level form" (. children 2))}
                                       (let [top (. children 1)]
                                         (if (= top.kind :table)
                                             {:value (convert top)}
                                             {:error (error-at "top-level form must be a table" (or top.open top))})))))))))]
    (if (not ok)
        (values nil result)
        (if result.error
            (values nil result.error)
            result.value))))

(defn- array-of-strings? [value]
  (if (not= (type value) :table)
      false
      (let []
        (var valid true)
        (var index 1)
        (while (and valid (not= (. value index) nil))
          (if (not= (type (. value index)) :string)
              (set valid false))
          (set index (+ index 1)))
        valid)))

(defn validate [tbl]
  (if (not= (type tbl) :table)
      (values nil {:message "configuration must be a table"})
      (let [allowed {:indents true :format-as true :indent-patterns true :paths true :exclude true}]
        (var failure nil)
        (each [key _ (pairs tbl)]
          (if (not (. allowed key))
              (set failure {:message (.. "unknown configuration key: " key)})))
        (if failure
            (values nil failure)
            (if (and (. tbl :paths) (not (array-of-strings? (. tbl :paths))))
                (values nil {:message "paths must be an array of strings"})
                (if (and (. tbl :exclude) (not (array-of-strings? (. tbl :exclude))))
                    (values nil {:message "exclude must be an array of strings"})
                    tbl))))))

(defn- join-path [dir name]
  (if (= (string.sub dir -1) "/")
      (.. dir name)
      (.. dir "/" name)))

(defn- exists? [path]
  (let [uv (or (and vim vim.loop) (and vim vim.uv))]
    (if uv
        (not= nil (uv.fs_stat path))
        (let [file (io.open path :r)]
          (if file
              (do (file:close) true)
              false)))))

(defn- git-marker? [dir]
  (or (exists? (join-path dir ".git"))
      (exists? (join-path (join-path dir ".git") "HEAD"))))

(defn- parent-dir [dir]
  (let [trimmed (if (and (> (string.len dir) 1) (= (string.sub dir -1) "/"))
                    (string.sub dir 1 -2)
                    dir)
        parent (string.match trimmed "^(.*)/[^/]+$")]
    (if parent
        (if (= parent "") "/" parent)
        nil)))

(defn find [start-dir]
  (var dir start-dir)
  (var result nil)
  (var searching true)
  (while searching
    (let [candidate (join-path dir ".fnl-extras.fnl")]
      (if (exists? candidate)
          (do (set result candidate) (set searching false))
          (if (git-marker? dir)
              (set searching false)
              (let [parent (parent-dir dir)]
                (if parent
                    (set dir parent)
                    (set searching false)))))))
  result)

(defn load [path]
  (let [file (io.open path :r)]
    (if (not file)
        (values nil {:message (.. "could not read config file: " path)})
        (let [text (file:read "*a")]
          (file:close)
          (let [(ok parsed-or-error) (pcall (fn [] (parse-string text)))]
            (if (not ok)
                (values nil parsed-or-error)
                (validate parsed-or-error)))))))
