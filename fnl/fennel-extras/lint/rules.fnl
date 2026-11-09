(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules)

(local core (require :eca.nfnl.core))
(local ast (require :fennel-extras.lint.rules.ast))
(local registry (require :fennel-extras.lint.rules.registry))
(local module-rule (require :fennel-extras.lint.rules.module))
(local spec-rule (require :fennel-extras.lint.rules.spec))
(local forbidden-rule (require :fennel-extras.lint.rules.forbidden))
(local size-rule (require :fennel-extras.lint.rules.size))

(local root-forms ast.root-forms)
(local list-head ast.list-head)
(local import-macros? ast.import-macros?)
(local has-module-import? ast.has-module-import?)
(local enabled? registry.enabled?)
(local finding registry.finding)
(local rule-severity registry.rule-severity)

(defn defaults
  []
  (registry.defaults))

(defn- update-check-state
  [state import-info head policy]
  {:module-import state.module-import})

(defn- check-state-step
  [nodes index state policy recurse]
  (let [node (. nodes index)]
    (recurse nodes (+ index 1) (update-check-state state (import-macros? node) (list-head node) policy) policy)))

(defn- check-state
  [nodes index state policy]
  (if (> index (length nodes))
    state
    (check-state-step nodes index state policy check-state)))

(defn- append-all
  [target items]
  (each [_ value (ipairs (or items []))]
        (table.insert target value))
  target)

(defn- contains?
  [items target index]
  (if (> index (length items))
    false
    (or (= (. items index) target)
        (contains? items target (+ index 1)))))

(defn- evaluate-form
  [path form forms policy]
  (let [node     form.node
        head     (list-head node)
        findings []]
    (when (enabled? policy "form-child-count")
          (spec-rule.form-child-count-finding findings path form policy node))
    (when (enabled? policy "child-count")
          (spec-rule.child-count-finding findings path form policy node))
    (when (enabled? policy "forbidden-form")
          (forbidden-rule.findings findings path form policy node "forbidden-form"))
    (when (and node (enabled? policy "module-import"))
          (module-rule.module-import-finding findings path form head node policy))
    findings))

(defn- append-form-findings
  [all path forms policy]
  (each [_ form (ipairs forms)]
        (append-all all (evaluate-form path form forms policy)))
  all)

(defn- append-file-size-findings
  [findings path policy source]
  (if (enabled? policy "file-size")
    (size-rule.finding path policy source)
    findings))

(defn- check-result
  [path forms policy source state]
  (let [findings (append-file-size-findings [] path policy source)
        findings (append-all findings (module-rule.required-form-finding path source policy))
        findings (append-form-findings findings path forms policy)]
    findings))

(defn- check-instance
  [path forms policy source instance]
  (let [instance-policy (registry.evaluator-policy policy instance.rule instance.value)
        state           (check-state (root-forms source) 1 {:module-import false} instance-policy)
        result          (check-result path forms instance-policy source state)]
    (icollect [_ finding (ipairs result)]
              (when (registry.instance-applies-to? instance.rule instance.value finding policy.matcher)
                    (let [with-instance (core.assoc finding :instance instance.index)]
                      (if instance.value.description
                        (core.assoc with-instance :description instance.value.description)
                        with-instance))))))

(defn- append-instance-findings
  [result path forms policy source instance]
  (each [_ finding (ipairs (check-instance path forms policy source instance))]
        (table.insert result finding))
  result)

(defn check
  [path forms policy source]
  (accumulate [result [] _ instance (ipairs (registry.instances policy))]
              (append-instance-findings result path forms policy source instance)))
