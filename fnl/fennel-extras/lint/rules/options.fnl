(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.options)

(local parse (require :fennel-extras.config.parse))

(local option-names
       {"module-style"        ["applies-to"
                               "macro-module"
                               "required-macros"]
        "spec-macro-import"   ["applies-to"
                               "macro-module"
                               "required-macros"
                               "exempt-files"]
        "spec-no-module"      ["applies-to" "module-form"]
        "spec-direct-require" ["applies-to"
                               "forbidden-modules"
                               "exempt-files"]
        "one-is-per-testing"  ["applies-to"
                               "testing-form"
                               "assertion-form"
                               "count"]
        "if-branch-call"      ["applies-to" "if-forms"]
        "if-without-else"     ["applies-to" "if-forms" "flag-nil-else"]
        "control-layout"      ["applies-to" "control-forms"]
        "unused-and-or"       ["applies-to" "forms"]
        "defn-args-newline"   ["applies-to" "forms"]
        "function-shape"      ["applies-to" "function-forms"]
        "no-mutation"         ["applies-to" "forms"]
        "multiline-layout"    ["applies-to" "clause-forms" "binding-forms"]
        "file-size"           ["applies-to" "max-code-lines"]
        "core-require"        ["applies-to" "module" "binding"]
        "binding-per-line"    ["applies-to" "forms"]
        "call-data-arg"       ["applies-to" "ignore-forms"]})

(local option-types
       {"applies-to"        :enum
        "macro-module"      :string
        "required-macros"   :strings
        "exempt-files"      :strings
        "module-form"       :string
        "forbidden-modules" :strings
        "testing-form"      :string
        "assertion-form"    :string
        "count"             :positive-integer
        "if-forms"          :strings
        "flag-nil-else"     :boolean
        "control-forms"     :strings
        "forms"             :strings
        "function-forms"    :strings
        "clause-forms"      :strings
        "binding-forms"     :strings
        "max-code-lines"    :positive-integer
        "module"            :string
        "binding"           :string
        "ignore-forms"      :strings})

(defn schema
  [rule]
  (let [result {}]
    (each [_ name (ipairs (or (. option-names rule) []))]
      (tset result name (. option-types name)))
    result))

(defn names
  [rule]
  (. option-names rule))

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

(defn- known-option-error
  [rule options key value kind recurse]
  (if (not (option-type-valid? kind value))
    {:message (option-type-message kind key)}
    (recurse rule options key)))

(defn- first-option-error-step
  [rule options key value recurse]
  (let [kind (. (schema rule) key)]
    (if (= kind nil)
      {:unknown true :message (.. "unknown option " (tostring key))}
      (known-option-error rule options key value kind recurse))))

(defn- first-option-error
  [rule options key]
  (let [(next-key next-value) (next options key)]
    (if (= next-key nil)
      nil
      (first-option-error-step rule options next-key next-value first-option-error))))

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
  (let [error (first-option-error rule options nil)]
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

(defn spec-files-error
  [value]
  (when (and (not= value nil) (not (parse.sequence? value)))
    {:message "spec-files must be a list of strings"}))
