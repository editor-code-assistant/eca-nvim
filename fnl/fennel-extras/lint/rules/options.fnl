(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.options)

(local parse (require :fennel-extras.config.parse))

(local option-names
       {"required-form"    ["forms"]
        "module-import"    ["mode" "modules" "module" "binding" "forms"]
        "child-count"      ["children" "max-count" "min-count" "nil-count" "not-counted"]
        "form-child-count" ["children" "max-count"]
        "file-size"        ["max-code-lines"]
        "form-chain"       ["allowed-chains" "forms-between" "forbidden-chains"]})

(local required-option-names
       {"required-form"    []
        "module-import"    ["mode"]
        "child-count"      []
        "form-child-count" ["children" "max-count"]
        "file-size"        ["max-code-lines"]
        "form-chain"       ["allowed-chains"]})

(local option-types
       {
        "module"           :string
        "exception"        :exception
        "mode"             :string
        "modules"          :strings
        "forms"            :strings
        "children"         :strings
        "max-count"        :positive-integer
        "min-count"        :non-negative-integer
        "nil-count"        :boolean
        "not-counted"      :non-empty-strings
        "nil-else"         :boolean
        "clauses"          :strings
        "bindings"         :strings
        "max-depth"        :positive-integer
        "max-code-lines"   :positive-integer
        "binding"          :string
        "allowed-chains"   :chains
        "forms-between"    :strings
        "forbidden-chains" :chains})

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

(defn- non-negative-integer?
  [value]
  (and (= (type value) :number)
       (= value (math.floor value))
       (>= value 0)))

(defn- strings-step
  [value index]
  (or (> index (length value))
      (and (= (type (. value index)) :string)
           (strings-step value (+ index 1)))))

(defn- strings?
  [value]
  (and (parse.sequence? value)
       (strings-step value 1)))

(defn- non-empty-strings?
  [value]
  (and (strings? value)
       (> (length value) 0)))

(defn- chains?
  [value]
  (and (parse.sequence? value)
       (> (length value) 0)
       (accumulate [valid true _ chain (ipairs value)]
                   (and valid (non-empty-strings? chain)))))

(defn- exception?
  [value]
  (and (parse.sequence? value)
       (= (length value) 1)
       (= (. value 1) "top-level")))

(local validators
       {:string               (fn
                                [value]
                                (= (type value) :string))


        :strings              strings?
        :non-empty-strings    non-empty-strings?
        :chains               chains?
        :exception            exception?
        :positive-integer     positive-integer?
        :non-negative-integer non-negative-integer?
        :boolean              boolean?})

(local type-messages
       {:strings              " must be a list of strings"
        :non-empty-strings    " must be a non-empty list of strings"
        :chains               " must be a non-empty list of non-empty string lists"
        :positive-integer     " must be a positive integer"
        :non-negative-integer " must be a non-negative integer"
        :boolean              " must be a boolean"
        :string               " must be a string"})

(defn- option-type-valid?
  [kind value]
  (let [validator (. validators kind)]
    (or (and (not validator) true)
        (and validator (validator value)))))

(defn- option-type-message
  [kind option]
  (let [message (. type-messages kind)]
    (.. option message)))

(defn- first-option-error-step
  [rule options keys index]
  (let [key   (. keys index)
        value (and key (. options key))
        kind  (and key (. (schema rule) key))]
    (and key
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
  (and options
       (validate-present rule options)))

(defn normalized
  [overrides]
  (or overrides {}))
