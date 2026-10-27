(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.options)

(local parse (require :fennel-extras.config.parse))

(local option-names
       {"forbidden-form"      ["applies-to" "module"]
        "module-style"        ["applies-to" "module" "forms"]
        "spec-macro-import"   ["applies-to" "module" "forms" "exempt-files"]
        "spec-no-module"      ["applies-to" "module"]
        "spec-direct-require" ["applies-to" "modules" "exempt-files"]
        "one-is-per-testing"  ["applies-to" "testing" "assertion" "count"]
        "if-branch-call"      ["applies-to" "forms"]
        "if-without-else"     ["applies-to" "forms" "nil-else"]
        "control-layout"      ["applies-to" "forms"]
        "unused-and-or"       ["applies-to" "forms"]
        "defn-args-newline"   ["applies-to" "forms"]
        "function-shape"      ["applies-to" "forms" "max-depth"]
        "no-mutation"         ["applies-to" "forms"]
        "multiline-layout"    ["applies-to" "clauses" "bindings"]
        "file-size"           ["applies-to" "max-code-lines"]
        "core-require"        ["applies-to" "module" "binding"]
        "binding-per-line"    ["applies-to" "forms"]
        "call-data-arg"       ["applies-to" "forms"]})

(local required-option-names
       {"forbidden-form"      ["module"]
        "module-style"        ["module" "forms"]
        "spec-macro-import"   ["module" "forms" "exempt-files"]
        "spec-no-module"      ["module"]
        "spec-direct-require" ["modules" "exempt-files"]
        "one-is-per-testing"  ["testing" "assertion" "count"]
        "if-branch-call"      ["forms"]
        "if-without-else"     ["forms"]
        "control-layout"      ["forms"]
        "unused-and-or"       ["forms"]
        "defn-args-newline"   ["forms"]
        "function-shape"      ["forms"]
        "no-mutation"         ["forms"]
        "multiline-layout"    ["clauses" "bindings"]
        "file-size"           ["max-code-lines"]
        "core-require"        ["module" "binding"]
        "binding-per-line"    ["forms"]
        "call-data-arg"       ["forms"]})

(local option-types
       {"applies-to"     :enum
        "module"         :string
        "modules"        :strings
        "forms"          :strings
        "exempt-files"   :strings
        "testing"        :string
        "assertion"      :string
        "count"          :positive-integer
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
        :boolean          boolean?
        :enum             (fn [value] (or (= value "source") (= value "spec") (= value "all")))})

(local type-messages
       {:strings          " must be a list of strings"
        :positive-integer " must be a positive integer"
        :boolean          " must be a boolean"
        :enum             "applies-to must be source, spec, or all"
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
    (if (= kind :enum)
      message
      (.. option message))))

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
