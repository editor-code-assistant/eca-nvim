(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.registry)

(local core (require :eca.nfnl.core))
(local lint-rule-name-list ["forbidden-form" "required-form" "module-style" "module-import" "form-child-count" "control-layout" "unused-and-or" "multiline-layout" "file-size" "call-data-arg"])
(local design-rule-name-list ["function-shape" "if-branch-call" "if-without-else" "nested-forms" "leading-bindings" "no-mutation"])
(local rule-name-list (core.concat lint-rule-name-list ["function-shape" "if-branch-call" "if-without-else"]))
(local ast (require :fennel-extras.lint.rules.ast))
(local options (require :fennel-extras.lint.rules.options))
(local rule-properties {:module-style {:scope :file} :required-form {:scope :file} :file-size {:scope :file}})
(local semantic-applies-to
       {"forbidden-form"   ["module" "forms"]
        "required-form"    ["forms"]
        "module-style"     ["module" "forms"]
        "module-import"    ["module" "modules" "forms"]
        "if-branch-call"   ["forms"]
        "if-without-else"  ["forms"]
        "control-layout"   ["forms"]
        "unused-and-or"    ["forms"]
        "function-shape"   ["forms"]
        "call-data-arg"    ["forms"]
        "nested-forms"     ["forms"]
        "leading-bindings" ["forms"]
        "no-mutation"      ["forms"]})
(local required-semantic-applies-to
       {"required-form"    ["forms"]
        "module-style"     ["module" "forms"]
        "if-branch-call"   ["forms"]
        "if-without-else"  ["forms"]
        "control-layout"   ["forms"]
        "unused-and-or"    ["forms"]
        "function-shape"   ["forms"]
        "call-data-arg"    ["forms"]
        "nested-forms"     ["forms"]
        "leading-bindings" ["forms"]
        "no-mutation"      ["forms"]})

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



(defn applies-to-required-names
  [rule]
  (. required-semantic-applies-to rule))



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



(defn- singleton-module-value
  [value]
  (if (= (type value) :string)
    value
    (if (and (= (type value) :table)
             (= (length value) 1))
      (. value 1)
      value)))



(defn- module-set-value
  [value]
  (if (= (type value) :string)
    [value]
    value))



(defn- semantic-option-value
  [applies name singleton]
  (if (= name "module")
    (if singleton
      (singleton-module-value (. applies :modules))
      nil)
    (if (= name "modules")
      (module-set-value (. applies :modules))
      (. applies :forms))))



(defn- normalized-options
  [rule instance]
  (let [options   (core.merge (or instance.options {}))
        applies   (or instance.applies-to {})
        singleton (or (= rule "forbidden-form")
                      (= rule "module-style")
                      (and (= rule "module-import")
                           (= options.mode "require")))]
    (accumulate [result options _ name (ipairs (or (. semantic-applies-to rule) []))]
      (let [value (semantic-option-value applies name singleton)]
        (if (or (= value nil)
                (and (= rule "module-import")
                     (= name "modules")
                     (= (type applies.modules) :string)
                     options.modules))
          result
          (core.assoc result name value))))))



(defn evaluator-policy
  [policy rule instance]
  (let [base-result  (core.assoc (defaults) rule instance.severity)
        result       (if (= rule "no-mutation")
                       (core.assoc (core.assoc base-result "forbidden-form" instance.severity)
                                   "no-mutation"
                                   instance.severity)
                       base-result)
        raw-options  (normalized-options rule instance)
        normalized   (if (and (= rule "module-import")
                              raw-options.module
                              (= raw-options.mode "forbid"))
                       (core.assoc raw-options :mode "require")
                       raw-options)
        with-options (core.assoc result :options normalized)]
    (core.assoc with-options :matcher policy.matcher)))



(defn- matches?
  [matcher pattern value]
  (and pattern
       value
       (if matcher
         (matcher pattern value)
         (>= (vim.fn.match value pattern) 0))))



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



(defn- semantic-name?
  [rule name]
  (accumulate [found false _ candidate (ipairs (or (. semantic-applies-to rule) []))]
    (or found (= candidate name))))



(defn- generic-applies-to
  [rule applies]
  (let [result {}]
    (each [_ name (ipairs ["files" "forms" "modules"])]
      (when (and (. applies name)
                 (not (or (semantic-name? rule name)
                          (and (= name "modules") (semantic-name? rule "module")))))
        (tset result name (or (and (= name "modules") (module-set-value (. applies name)))
                              (. applies name)))))
    result))



(defn instance-applies-to?
  [rule instance finding matcher]
  (scope-matches? (generic-applies-to rule (or instance.applies-to {})) finding matcher))



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
