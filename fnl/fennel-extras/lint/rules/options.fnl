(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.options)

(local parse (require :fennel-extras.config.parse))

(local rule-options
       {"module-style"        {:applies-to "source" :macro-module "eca.nfnl.macros.aniseed" :required-macros ["module" "def" "defn" "defn-"]}
        "spec-macro-import"   {:applies-to "spec" :macro-module "spec.eca.macros" :required-macros ["deftest" "testing" "is"] :exempt-files ["^fnl/spec/eca/macros[.]fnlm$"]}
        "spec-no-module"      {:applies-to "spec" :module-form "module"}
        "spec-direct-require" {:applies-to "spec" :forbidden-modules ["plenary.busted" "luassert"] :exempt-files ["^fnl/spec/eca/macros[.]fnlm$"]}
        "one-is-per-testing"  {:applies-to "all" :testing-form "testing" :assertion-form "is" :count 1}
        "if-branch-call"      {:applies-to "all" :if-forms ["if"]}
        "if-without-else"     {:applies-to "all" :if-forms ["if"] :flag-nil-else true}
        "control-layout"      {:applies-to "all" :control-forms ["if" "when" "and" "or" "case" "match"]}
        "unused-and-or"       {:applies-to "all" :forms ["and" "or"]}
        "defn-args-newline"   {:applies-to "all" :forms ["defn" "defn-"]}
        "function-shape"      {:applies-to "all" :function-forms ["defn" "defn-" "fn" "lambda" "λ"]}
        "no-mutation"         {:applies-to "source" :forms ["var" "set" "while"]}
        "multiline-layout"    {:applies-to "all" :clause-forms ["case" "match" "case-try" "match-try"] :binding-forms ["let" "when-let" "if-let" "with-open"]}
        "file-size"           {:applies-to "source" :max-code-lines 300}
        "core-require"        {:applies-to "all" :module "eca.nfnl.core" :binding "core"}
        "binding-per-line"    {:applies-to "all" :forms ["let" "when-let" "if-let" "with-open"]}
        "call-data-arg"       {:applies-to "source" :ignore-forms []}})

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
  (let [defaults (. rule-options rule)
        schema   {}]
    (each [key _ (pairs defaults)]
      (tset schema key (or (. option-types key) :string)))
    schema))

(defn defaults
  []
  rule-options)

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
  [schema options key value kind recurse]
  (if (not (option-type-valid? kind value))
    {:message (option-type-message kind key)}
    (recurse schema options key)))

(defn- first-option-error-step
  [schema options key value recurse]
  (let [kind (. schema key)]
    (if (= kind nil)
      {:unknown true :message (.. "unknown option " (tostring key))}
      (known-option-error schema options key value kind recurse))))

(defn- first-option-error
  [schema options key]
  (let [(next-key next-value) (next options key)]
    (if (= next-key nil)
      nil
      (first-option-error-step schema options next-key next-value first-option-error))))

(defn- unknown-option-result
  [rule error]
  {:message (.. error.message " for lint rule " rule)})

(defn- option-error-known
  [rule error]
  (if error.unknown
    (unknown-option-result rule error)
    error))

(defn- option-error-result
  [rule error]
  (and error (option-error-known rule error)))

(defn- validate-table
  [rule options]
  (option-error-result rule (first-option-error (schema rule) options nil)))

(defn- validate-value
  [rule options]
  (if (= (type options) :table)
    (validate-table rule options)
    {:message "options must be a table"}))

(defn validate
  [rule options]
  (if (= options nil)
    nil
    (validate-value rule options)))

(defn- merge-rule-options
  [result name overrides]
  (let [merged {}]
    (each [key value (pairs (. rule-options name))]
      (tset merged key value))
    (each [key value (pairs (or overrides {}))]
      (tset merged key value))
    (tset result name merged)
    result))

(defn normalized
  [overrides]
  (let [result {}]
    (each [name _ (pairs rule-options)]
      (merge-rule-options result name (. (or overrides {}) name)))
    result))

(defn spec-files
  []
  ["^fnl/spec/"])

(defn spec-files-error
  [value]
  (when (and (not= value nil) (not (strings? value)))
    {:message "spec-files must be a list of strings"}))
