(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.options)

(local parse (require :fennel-extras.config.parse))

(local option-names
       {"forbidden-form"   ["module"]
        "module-style"     ["module" "forms"]
        "macro-import"     ["module" "forms" "exempt-files"]
        "no-module"        ["module"]
        "direct-require"   ["mode" "modules" "exempt-files" "module" "binding"]
        "form-child-count" ["children" "max-count"]
        "if-branch-call"   ["forms"]
        "if-without-else"  ["forms" "nil-else"]
        "control-layout"   ["forms"]
        "unused-and-or"    ["forms"]
        "function-shape"   ["forms" "max-depth"]
        "no-mutation"      ["forms"]
        "multiline-layout" ["clauses" "bindings"]
        "file-size"        ["max-code-lines"]
        "binding-per-line" ["forms"]
        "call-data-arg"    ["forms"]})

(local required-option-names
       {"forbidden-form"   ["module"]
        "module-style"     ["module" "forms"]
        "macro-import"     ["module" "forms" "exempt-files"]
        "no-module"        ["module"]
        "direct-require"   ["mode"]
        "form-child-count" ["children" "max-count"]
        "if-branch-call"   ["forms"]
        "if-without-else"  ["forms"]
        "control-layout"   ["forms"]
        "unused-and-or"    ["forms"]
        "function-shape"   ["forms"]
        "no-mutation"      ["forms"]
        "multiline-layout" ["clauses" "bindings"]
        "file-size"        ["max-code-lines"]
        "binding-per-line" ["forms"]
        "call-data-arg"    ["forms"]})

(local option-types
       {
        "module"         :string
        "mode"           :string
        "modules"        :strings
        "forms"          :strings
        "exempt-files"   :strings
        "children"       :strings
        "max-count"      :positive-integer
        "nil-else"       :boolean
        "clauses"        :strings
        "bindings"       :strings
        "max-depth"      :positive-integer
        "max-code-lines" :positive-integer
        "binding"        :string})

(defn schema
  [rule]
  (let [result {}]
    (each [_ name (ipairs (or (. option-names rule) []))]
      (tset result name (. option-types name)))
    result))



(defn names
  [rule]
  (. option-names rule))



(defn required-names
  [rule]
  (. required-option-names rule))



(defn defaults
  []
  {})



(defn- boolean?
  [value]
  (or (= value true) (= value false)))



(defn- positive-integer?
  [value]
  (and (= (type value) :number)
       (= value (math.floor value))
       (> value 0)))



(defn- strings-step
  [value index]
  (if (> index (length value))
    true
    (and (= (type (. value index)) :string)
         (strings-step value (+ index 1)))))



(defn- strings?
  [value]
  (and (parse.sequence? value)
       (strings-step value 1)))



(local validators
       {:string           (fn [value] (= (type value) :string))


        :strings          strings?
        :positive-integer positive-integer?
        :boolean          boolean?})

(local type-messages
       {:strings          " must be a list of strings"
        :positive-integer " must be a positive integer"
        :boolean          " must be a boolean"
        :string           " must be a string"})

(defn- option-type-valid?
  [kind value]
  (let [validator (. validators kind)]
    (if validator
      (validator value)
      true)))



(defn- option-type-message
  [kind option]
  (let [message (. type-messages kind)]
    (.. option message)))



(defn- first-option-error-step
  [rule options keys index]
  (let [key   (. keys index)
        value (and key (. options key))
        kind  (and key (. (schema rule) key))]
    (if (= key nil)
      nil
      (or (and (= kind nil)
               {:unknown true :message (.. "unknown option " (tostring key))})
          (and (not (option-type-valid? kind value))
               {:message (option-type-message kind key)})
          (first-option-error-step rule options keys (+ index 1))))))



(defn- first-option-error
  [rule options]
  (let [keys (vim.tbl_keys options)]
    (table.sort keys)
    (first-option-error-step rule options keys 1)))



(defn- unknown-option-result
  [rule error]
  {:message (.. error.message " for lint rule " rule)})



(defn- table-validation-result
  [rule error]
  (if error.unknown
    (unknown-option-result rule error)
    error))



(defn- table-validation-error
  [rule options]
  (let [error (first-option-error rule options)]
    (and error
         (table-validation-result rule error))))



(defn- validate-present
  [rule options]
  (if (= (type options) :table)
    (table-validation-error rule options)
    {:message "options must be a table"}))



(defn validate
  [rule options]
  (if (= options nil)
    nil
    (validate-present rule options)))



(defn normalized
  [overrides]
  (or overrides {}))
