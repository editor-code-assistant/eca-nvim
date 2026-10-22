(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.config.parse)

(local reader (require :fennel-extras.reader))

(local reader (require :fennel-extras.reader))

(local sequence-marker :fennel-extras-sequence)
(local table-marker :fennel-extras-table)

(defn- marked-sequence
  [value]
  (setmetatable value {sequence-marker true}))

(defn- marked-table
  [value]
  (setmetatable value {table-marker true}))

(defn- plain-sequence-step
  [value key count maximum]
  (let [(next-key next-value) (next value key)]
    (if (= next-key nil)
      (and (= count maximum) (= count (length value)))
      (and (= (type next-key) :number)
           (= next-key (math.floor next-key))
           (> next-key 0)
           (not= next-value nil)
           (plain-sequence-step value next-key (+ count 1) (math.max maximum next-key))))))

(defn sequence?
  [value]
  (and (= (type value) :table)
       (let [metadata (getmetatable value)]
         (or (and metadata (. metadata sequence-marker))
             (and (= metadata nil)
                  (plain-sequence-step value nil 0 0))))))

(defn- parsed-table?
  [value]
  (and (= (type value) :table)
       (let [metadata (getmetatable value)]
         (and metadata
              (. metadata table-marker)))))

(defn- error-at
  [message token]
  {:message message :line token.line :col token.col})

(defn- trivia?
  [child]
  (if child
    (if child.kind
      (or (= child.kind :whitespace)
          (= child.kind :newline)
          (= child.kind :comment)
          (= child.kind :tab))
      false)
    false))

(defn- append-meaningful-child
  [result child]
  (when (not (trivia? child))
    (table.insert result child)))

(defn- meaningful-children
  [children]
  (let [result []]
    (each [_ child (ipairs children)]
      (append-meaningful-child result child))
    result))

(defn- append-decoded-char
  [result c]
  (table.insert result c))

(defn- normalize-escaped-delimiters-step
  [state]
  (let [text      state.text
        index     state.index
        in-string state.in-string
        result    state.result]
    (if (> index (string.len text))
      result
      (let [c    (string.sub text index index)
            next (string.sub text (+ index 1) (+ index 1))]
        (if (and (not in-string) (= c "\\") (= next "\""))
          (normalize-escaped-delimiters-step {:text text :index (+ index 2) :in-string in-string :result (.. result next)})
          (if (and in-string (= c "\\"))
            (normalize-escaped-delimiters-step {:text text :index (+ index 2) :in-string in-string :result (.. result c next)})
            (normalize-escaped-delimiters-step {:text text :index (+ index 1) :in-string (if (= c "\"") (not in-string) in-string) :result (.. result c)})))))))

(defn- normalize-escaped-delimiters
  [text]
  (let [state {:text text :index 1 :in-string false :result ""}]
    (normalize-escaped-delimiters-step state)))

(defn- append-unsupported-escape
  [result escaped]
  (table.insert result "\\")
  (table.insert result escaped))

(defn- decode-string
  [token]
  (let [text   token.text
        n      (string.len text)
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
                    (append-unsupported-escape result escaped)))))
            (set i (+ i 2)))
          (let [_ (append-decoded-char result c)]
            (set i (+ i 1))))))
    (table.concat result)))

(defn- convert-symbol
  [token]
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

(defn- convert-table-children
  [convert-fn children result]
  (var i 1)
  (var failure nil)
  (while (and (<= i (length children)) (not failure))
    (let [(key key-error)     (convert-fn (. children i))
          (value value-error) (convert-fn (rawget children (+ i 1)))]
      (if key-error
        (set failure key-error)
        (if value-error
          (set failure value-error)
          (tset result key value))))
    (set i (+ i 2)))
  failure)

(defn- convert
  [node]
  (if (= node.kind :table)
    (let [children (meaningful-children node.children)
          result   {}]
      (if (= (math.fmod (length children) 2) 1)
        (error (error-at "table must contain key/value pairs" node.open) 0)
        (let [failure (convert-table-children convert children result)]
          (if failure
            (error failure 0)
            (marked-table result)))))
    (if (= node.kind :sequence)
      (let [result []]
        (var failure nil)
        (each [_ child (ipairs (meaningful-children node.children))]
          (when (not failure)
            (let [(value error) (convert child)]
              (if error
                (set failure error)
                (table.insert result value)))))
        (if failure
          (error failure 0)
          (marked-sequence result)))
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

(defn parse-string
  [text]
  (let [(ok result) (pcall (fn []
                             (let [(root reader-error) (reader.parse (normalize-escaped-delimiters text))]
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
