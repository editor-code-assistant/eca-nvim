(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.config)

(local core (require :eca.nfnl.core))
(local reader (require :fennel-extras.reader))
(local lint-rules (require :fennel-extras.lint.rules))

(local sequence-marker :fennel-extras-sequence)
(local table-marker :fennel-extras-table)

(defn- marked-sequence [value]
  (setmetatable value {sequence-marker true}))

(defn- marked-table [value]
  (setmetatable value {table-marker true}))

(defn- plain-sequence-step [value key count maximum]
  (let [(next-key next-value) (next value key)]
    (if (= next-key nil)
      (and (= count maximum) (= count (length value)))
      (and (= (type next-key) :number)
           (= next-key (math.floor next-key))
           (> next-key 0)
           (not= next-value nil)
           (plain-sequence-step value next-key (+ count 1) (math.max maximum next-key))))))

(defn- sequence? [value]
  (and (= (type value) :table)
       (let [metadata (getmetatable value)]
         (or (and metadata (. metadata sequence-marker))
             (and (= metadata nil)
                  (plain-sequence-step value nil 0 0))))))

(defn- parsed-table? [value]
  (and (= (type value) :table)
       (let [metadata (getmetatable value)]
         (and metadata (. metadata table-marker)))))

(defn- lint-rule-known? [rule]
  (. (lint-rules.defaults) rule))

(defn- lint-severity? [severity]
  (or (= severity "error") (= severity "warning") (= severity "off")))

(defn- lint-key-sort-value [key]
  (.. (type key) ":" (tostring key)))

(defn- first-unknown-lint-key [lint key candidate]
  (let [(next-key) (next lint key)]
    (if (= next-key nil)
      candidate
      (if (or (= next-key :rules)
              (= next-key :exclusions)
              (= next-key :max-code-lines))
        (first-unknown-lint-key lint next-key candidate)
        (if (or (= candidate nil)
                (< (lint-key-sort-value next-key) (lint-key-sort-value candidate)))
          (first-unknown-lint-key lint next-key next-key)
          (first-unknown-lint-key lint next-key candidate))))))

(defn- unknown-lint-key-error [key]
  (if key
    {:message (.. "unknown lint key: " (tostring key))}
    nil))

(defn- blank? [text]
  (= (string.match text "^%s*$") text))

(defn- first-lint-rule-error [rules key]
  (let [(next-key next-value) (next rules key)]
    (if (= next-key nil)
      nil
      (if (not (lint-rule-known? next-key))
        {:message (.. "unknown lint rule: " (tostring next-key))}
        (if (not (lint-severity? next-value))
          {:message (.. "lint rule " (tostring next-key) " must be error, warning, or off")}
          (first-lint-rule-error rules next-key))))))

(defn- next-exclusion-key-error [exclusion index key next-error]
  (next-error exclusion index (next exclusion key)))

(defn- exclusion-keys-error [exclusion index key]
  (if (= key nil)
    nil
    (if (or (= key :rule) (= key :form) (= key :reason))
      (next-exclusion-key-error exclusion index key exclusion-keys-error)
      {:message (.. "lint exclusion " index ": unknown key " (tostring key))})))

(defn- duplicate-exclusion-index-entry [exclusions index rule form candidate entry next-index]
  (if (and (= (. entry :rule) rule) (= (. entry :form) form))
    index
    (next-index exclusions (+ index 1) rule form candidate)))

(defn- duplicate-exclusion-index [exclusions index rule form candidate]
  (if (>= index candidate)
    nil
    (duplicate-exclusion-index-entry exclusions index rule form candidate (. exclusions index) duplicate-exclusion-index)))

(defn- exclusion-duplicate-error [exclusions index duplicate next-error]
  (if duplicate
    {:message (.. "lint exclusion " index ": duplicate of exclusion " duplicate)}
    (next-error exclusions (+ index 1))))

(defn- exclusion-rule-known-error [exclusions index rule form reason duplicate next-error]
  (if (not (lint-rule-known? rule))
    {:message (.. "lint exclusion " index ": unknown rule " rule)}
    (exclusion-duplicate-error exclusions index duplicate next-error)))

(defn- exclusion-reason-error [exclusions index rule form reason duplicate next-error]
  (if (blank? reason)
    {:message (.. "lint exclusion " index ": reason must not be blank")}
    (exclusion-rule-known-error exclusions index rule form reason duplicate next-error)))

(defn- exclusion-form-error [exclusions index rule form reason duplicate next-error]
  (if (not= (type reason) :string)
    {:message (.. "lint exclusion " index ": reason must be a string")}
    (exclusion-reason-error exclusions index rule form reason duplicate next-error)))

(defn- exclusion-rule-error [exclusions index rule form reason duplicate next-error]
  (if (not= (type form) :string)
    {:message (.. "lint exclusion " index ": form must be a string")}
    (exclusion-form-error exclusions index rule form reason duplicate next-error)))

(defn- first-exclusion-error-entry [exclusions index exclusion next-error]
  (let [(unknown-key) (next exclusion nil)
        rule          (. exclusion :rule)
        form          (. exclusion :form)
        reason        (. exclusion :reason)
        duplicate     (duplicate-exclusion-index exclusions 1 rule form index)]
    (or (exclusion-keys-error exclusion index unknown-key)
        (if (not= (type rule) :string)
          {:message (.. "lint exclusion " index ": rule must be a string")}
          (exclusion-rule-error exclusions index rule form reason duplicate next-error)))))

(defn- first-exclusion-error [exclusions index]
  (let [exclusion (. exclusions index)]
    (if (= exclusion nil)
      nil
      (if (not= (type exclusion) :table)
        {:message (.. "lint exclusion " index " must be a table")}
        (first-exclusion-error-entry exclusions index exclusion first-exclusion-error)))))

(defn- lint-max-code-lines-error [max-code-lines]
  (if (and (not= max-code-lines nil)
           (not (and (= (type max-code-lines) :number)
                     (= max-code-lines (math.floor max-code-lines))
                     (> max-code-lines 0))))
    {:message "max-code-lines must be a positive integer"}))

(defn- lint-table-error [rules exclusions max-code-lines unknown-key]
  (or (unknown-lint-key-error unknown-key)
      (if (and rules
               (or (not= (type rules) :table)
                   (and (sequence? rules)
                        (or (not= (getmetatable rules) nil)
                            (> (length rules) 0)))))
        {:message "lint rules must be a table"})
      (if rules (first-lint-rule-error rules nil))
      (lint-max-code-lines-error max-code-lines)
      (if (and exclusions (not (sequence? exclusions)))
        {:message "lint exclusions must be a list"})
      (if exclusions (first-exclusion-error exclusions 1))))

(defn- lint-error [lint]
  (if (not= (type lint) :table)
    {:message "lint must be a table"}
    (let [rules          (. lint :rules)
          exclusions     (. lint :exclusions)
          max-code-lines (. lint :max-code-lines)
          unknown-key    (first-unknown-lint-key lint nil nil)]
      (lint-table-error rules exclusions max-code-lines unknown-key))))

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

(defn- append-decoded-char [result c]
  (table.insert result c))

(defn- decode-string [token]
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
                    (error (error-at "unsupported string escape" token) 0)))))
            (set i (+ i 2)))
          (let [_ (append-decoded-char result c)]
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

(defn- convert-table-children [convert-fn children result]
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

(defn- convert [node]
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
          (if (not failure)
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

(defn- integer? [value]
  (and (= (type value) :number) (= value (math.floor value))))

(defn- valid-rule? [rule]
  (if (and (= (type rule) :table) (= (type (. rule 1)) :string))
    (let [kind (. rule 1) value (. rule 2) index (. rule 3)]
      (if (= kind :block)
        (and (integer? value) (>= value 0) (= index nil))
        (if (= kind :inner)
          (and (= value 0)
               (or (= index nil) (and (integer? index) (>= index 0))))
          false)))
    false))

(defn- valid-rule-list? [value]
  (if (= (type value) :table)
    (let []
      (var valid true)
      (each [_ rule (ipairs value)]
        (if (not (valid-rule? rule))
          (set valid false)))
      valid)
    false))

(defn- rule-map-error [value prefix]
  (if (= (type value) :table)
    (let []
      (var failure nil)
      (each [name rule (pairs value)]
        (if (= failure nil)
          (if (not (valid-rule-list? rule))
            (set failure {:message (.. prefix name ": invalid indentation rule")}))))
      failure)
    {:message (.. prefix ": invalid indentation rule")}))

(defn- boolean? [value]
  (or (= value true) (= value false)))

(defn- extensions? [value]
  (if (and (= (type value) :table) (> (length value) 0))
    (let []
      (var valid true)
      (each [_ extension (ipairs value)]
        (if (or (not= (type extension) :string)
                (not (= (string.sub extension 1 1) ".")))
          (set valid false)))
      valid)
    false))

(defn- configuration-error-with-lint [failure lint]
  (or failure (and lint (lint-error lint))))

(defn- configuration-error [tbl]
  (let [width           (. tbl :indent-width)
        builtins        (. tbl :builtins)
        fallbacks       (. tbl :prefix-fallbacks)
        extensions      (. tbl :extensions)
        skip-dotfiles   (. tbl :skip-dotfiles)
        follow-symlinks (. tbl :follow-symlinks)
        align-bindings  (. tbl :align-bindings)
        parser          (. tbl :parser)
        lint            (. tbl :lint)]
    (var failure nil)
    (if (and (= failure nil) (not= width nil)
             (not (and (integer? width) (> width 0))))
      (set failure {:message "indent-width must be a positive integer"}))
    (if (and (= failure nil) (not= builtins nil)
             (not (= builtins true)) (not (= builtins false))
             (not= (type builtins) :table))
      (set failure {:message "builtins must be true, false, or a table of rules"}))
    (if (and (= failure nil) (= (type builtins) :table))
      (set failure (rule-map-error builtins "builtins rule ")))
    (if (and (= failure nil) (not= fallbacks nil)
             (not (= fallbacks false)) (not= (type fallbacks) :table))
      (set failure {:message "prefix-fallbacks must be false or a table of rules"}))
    (if (and (= failure nil) (= (type fallbacks) :table))
      (set failure (rule-map-error fallbacks "prefix-fallbacks rule ")))
    (if (and (= failure nil) (not= extensions nil) (not (extensions? extensions)))
      (set failure {:message "extensions must be a non-empty list of strings starting with \".\""}))
    (if (and (= failure nil) (not= skip-dotfiles nil) (not (boolean? skip-dotfiles)))
      (set failure {:message "skip-dotfiles must be a boolean"}))
    (if (and (= failure nil) (not= follow-symlinks nil) (not (boolean? follow-symlinks)))
      (set failure {:message "follow-symlinks must be a boolean"}))
    (if (and (= failure nil) (not= align-bindings nil) (not (boolean? align-bindings)))
      (set failure {:message "align-bindings must be a boolean"}))
    (if (and (= failure nil) (not= parser nil) (not= (type parser) :string))
      (set failure {:message "parser must be a string"}))
    (configuration-error-with-lint failure lint)))

(defn validate [tbl]
  (if (not= (type tbl) :table)
    (values nil {:message "configuration must be a table"})
    (let [allowed {:indents true :format-as true :indent-patterns true :paths true :exclude true
                   :indent-width true :builtins true :prefix-fallbacks true :extensions true
                   :skip-dotfiles true :follow-symlinks true :align-bindings true :parser true :lint true}]
      (var failure nil)
      (each [key _ (pairs tbl)]
        (if (not (. allowed key))
          (set failure {:message (.. "unknown configuration key: " key)})))
      (if failure
        (values nil failure)
        (let [new-error (configuration-error tbl)]
          (if new-error
            (values nil new-error)
            (if (and (. tbl :paths) (not (array-of-strings? (. tbl :paths))))
              (values nil {:message "paths must be an array of strings"})
              (if (and (. tbl :exclude) (not (array-of-strings? (. tbl :exclude))))
                (values nil {:message "exclude must be an array of strings"})
                tbl))))))))

(defn- valid-lint-policy [cfg]
  (let [lint           (. cfg :lint)
        overrides      (or (and lint (. lint :rules)) {})
        exclusions     (or (and lint (. lint :exclusions)) [])
        max-code-lines (or (and lint (. lint :max-code-lines)) 300)]
    {:rules          (core.merge (lint-rules.defaults) overrides)
     :exclusions     exclusions
     :max-code-lines max-code-lines}))

(defn lint-policy [cfg]
  (let [(valid error) (validate cfg)]
    (if error
      (values nil error)
      (valid-lint-policy valid))))

(defn- join-path [dir name]
  (if (= (string.sub dir -1) "/")
    (.. dir name)
    (.. dir "/" name)))

(defn- close-file [file]
  (file:close)
  true)

(defn- exists? [path]
  (let [uv (or (and vim vim.loop) (and vim vim.uv))]
    (if uv
      (not= nil (uv.fs_stat path))
      (let [file (io.open path :r)]
        (if file
          (close-file file)
          false)))))

(defn- git-marker? [dir]
  (or (exists? (join-path dir ".git"))
      (exists? (join-path (join-path dir ".git") "HEAD"))))

(defn- parent-dir [dir]
  (let [trimmed (if (and (> (string.len dir) 1) (= (string.sub dir -1) "/"))
                  (string.sub dir 1 -2)
                  dir)
        parent  (string.match trimmed "^(.*)/[^/]+$")]
    (if parent
      (if (= parent "") "/" parent)
      nil)))

(defn- found-config [candidate]
  (values candidate false))

(defn find [start-dir]
  (var dir start-dir)
  (var result nil)
  (var searching true)
  (while searching
    (let [candidate (join-path dir ".fnl-extras.fnl")]
      (if (exists? candidate)
        (let [(new-result new-searching) (found-config candidate)]
          (set result new-result)
          (set searching new-searching))
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
