(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.registry)

(local rule-name-list ["forbidden-form" "module-style" "spec-macro-import" "spec-no-module" "spec-direct-require" "one-is-per-testing" "if-branch-call" "if-without-else" "control-layout" "unused-and-or" "defn-args-newline" "function-shape" "no-mutation" "multiline-layout" "file-size" "core-require" "binding-per-line" "call-data-arg"])
(local core (require :eca.nfnl.core))
(local ast (require :fennel-extras.lint.rules.ast))
(local options (require :fennel-extras.lint.rules.options))
(local rule-properties {:module-style {:scope :file} :spec-macro-import {:scope :file} :file-size {:scope :file}})

(defn defaults
  []
  (let [result {}]
    (each [_ rule (ipairs rule-name-list)]
      (tset result rule "off"))
    result))

(defn rule-names
  []
  rule-name-list)

(defn option-schema
  [rule]
  (options.schema rule))

(defn required-option-names
  [rule]
  (options.required-names rule))

(defn rule-scope
  [rule]
  (let [properties (. rule-properties rule)]
    (and properties
         (. properties :scope))))

(defn- append-instances
  [result rule instances]
  (each [index instance (ipairs instances)]
    (table.insert result {:rule rule :index index :value instance}))
  result)

(defn instances
  [policy]
  (let [rules  (or (and policy policy.rules) policy)
        result []]
    (each [_ rule (ipairs rule-name-list)]
      (append-instances result rule (or (. rules rule) [])))
    result))

(defn evaluator-policy
  [policy rule instance]
  (let [result       (defaults)
        with-options (core.assoc result :options (or instance.options {}))]
    (tset result rule instance.severity)
    (core.assoc with-options :matcher policy.matcher)))

(defn- matches?
  [matcher pattern value]
  (if matcher
    (matcher pattern value)
    (= pattern value)))

(defn- any-match?
  [items matcher value]
  (accumulate [result false _ pattern (ipairs items)]
    (or result (matches? matcher pattern value))))

(defn- node-form
  [node]
  (ast.list-head node))

(defn- node-module
  [node]
  node.text)

(defn- node-matches?
  [items finding matcher value-fn]
  (or (= (length items) 0)
      (and finding.node (any-match? items matcher (value-fn finding.node)))))

(defn- scope-matches?
  [applies finding matcher]
  (and (or (= (length (or applies.files [])) 0)
           (any-match? (or applies.files []) matcher finding.path))
       (node-matches? (or applies.forms []) finding matcher node-form)
       (node-matches? (or applies.modules []) finding matcher node-module)))

(defn instance-applies-to?
  [instance finding matcher]
  (scope-matches? (or instance.applies-to {}) finding matcher))

(defn rule-options
  [policy rule]
  (and policy policy.options))

(defn finding
  [path form severity rule message node]
  {:kind "finding" :path path :line form.line :col form.col :end-line form.end-line :end-col form.end-col :severity severity :rule rule :form form.form :message message :node node})

(defn rule-severity
  [policy rule]
  (or (and policy (. policy rule)) "off"))

(defn enabled?
  [policy rule]
  (not= (rule-severity policy rule) "off"))
