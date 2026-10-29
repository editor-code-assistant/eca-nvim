(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.registry)

(local core (require :eca.nfnl.core))
(local lint-rule-name-list ["forbidden-form" "required-form" "module-style" "module-import" "form-child-count" "control-layout" "unused-and-or" "multiline-layout" "file-size" "call-data-arg"])
(local design-rule-name-list ["function-shape" "if-branch-call" "if-without-else" "nested-forms" "leading-bindings" "no-mutation"])
(local rule-name-list (core.concat lint-rule-name-list ["function-shape" "if-branch-call" "if-without-else"]))
(local ast (require :fennel-extras.lint.rules.ast))
(local options (require :fennel-extras.lint.rules.options))
(local rule-properties {:module-style {:scope :file} :required-form {:scope :file} :file-size {:scope :file}})

(defn defaults
  []
  (let [result {}]
    (each [_ rule (ipairs rule-name-list)]
      (tset result rule "off"))
    result))



(defn rule-names
  []
  rule-name-list)



(defn lint-rule-names
  []
  lint-rule-name-list)



(defn design-rule-names
  []
  design-rule-name-list)



(defn rule-domain
  [rule]
  (if (accumulate [found false _ name (ipairs design-rule-name-list)]
        (or found (= name rule)))
    :design
    :lint))



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
  (let [lint-rules   (or (and policy policy.rules)
                         (and policy (not policy.rules) policy)
                         {})
        design-rules (or (and policy policy.design)
                         lint-rules
                         {})
        result       []]
    (each [_ rule (ipairs lint-rule-name-list)]
      (append-instances result rule (or (. lint-rules rule) [])))
    (each [_ rule (ipairs design-rule-name-list)]
      (append-instances result rule (or (. design-rules rule) [])))
    result))



(defn evaluator-policy
  [policy rule instance]
  (let [base-result  (core.assoc (defaults) rule instance.severity)
        result       (if (= rule "no-mutation")
                       (core.assoc base-result "forbidden-form" instance.severity)
                       base-result)
        with-options (core.assoc result :options (or instance.options {}))]
    (core.assoc with-options :matcher policy.matcher)))



(defn- matches?
  [matcher pattern value]
  (and pattern
       value
       (if matcher
         (matcher pattern value)
         (= pattern value))))



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
