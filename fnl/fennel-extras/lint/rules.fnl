(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules)

(local ast (require :fennel-extras.lint.rules.ast))
(local registry (require :fennel-extras.lint.rules.registry))
(local module-rule (require :fennel-extras.lint.rules.module))
(local spec-rule (require :fennel-extras.lint.rules.spec))
(local branch-rule (require :fennel-extras.lint.rules.branch))
(local size-rule (require :fennel-extras.lint.rules.size))
(local mutation-rule (require :fennel-extras.lint.rules.mutation))
(local defn-rule (require :fennel-extras.lint.rules.defn))
(local layout-rule (require :fennel-extras.lint.rules.layout))
(local control-rule (require :fennel-extras.lint.rules.control))
(local discard-rule (require :fennel-extras.lint.rules.discard))
(local when-rule (require :fennel-extras.lint.rules.when))
(local binding-rule (require :fennel-extras.lint.rules.binding))
(local call-rule (require :fennel-extras.lint.rules.call))
(local shape-rule (require :fennel-extras.lint.rules.shape))
(local shape-leaf (require :fennel-extras.lint.rules.shape.leaf))

(local root-forms ast.root-forms)
(local list-head ast.list-head)
(local macro-import? ast.macro-import?)
(local has-all? ast.has-all?)
(local has-module-import? ast.has-module-import?)
(local spec-file? ast.spec-file?)
(local require-node? ast.require-node?)
(local enabled? registry.enabled?)
(local finding registry.finding)
(local rule-severity registry.rule-severity)

(defn defaults
  []
  (registry.defaults))

(defn- module-import-state-enabled
  [state import-info policy]
  (let [target-module (. (registry.rule-options policy "module-style") :macro-module)]
    (if (and import-info (= import-info.target target-module))
      (has-module-import? import-info.names)
      state.module-import)))

(defn- module-import-state
  [state import-info policy]
  (if (enabled? policy "module-style")
    (module-import-state-enabled state import-info policy)
    state.module-import))

(defn- spec-import-state-enabled
  [state import-info policy]
  (let [options (registry.rule-options policy "spec-macro-import")]
    (if (and import-info (= import-info.target options.macro-module))
      (has-all? import-info.names options.required-macros)
      state.spec-import)))

(defn- spec-import-state
  [state import-info policy]
  (if (enabled? policy "spec-macro-import")
    (spec-import-state-enabled state import-info policy)
    state.spec-import))

(defn- update-check-state
  [state import-info head policy]
  {:module-import (module-import-state state import-info policy) :module-form (or state.module-form (= head "module")) :spec-import (spec-import-state state import-info policy)})

(defn- check-state-step
  [nodes index state policy recurse]
  (let [node (. nodes index)]
    (recurse nodes (+ index 1) (update-check-state state (macro-import? node) (list-head node) policy) policy)))

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
    (when (and (enabled? policy "spec-no-module")
               (spec-file? path policy.spec-files policy.matcher)
               (= head (. (registry.rule-options policy "spec-no-module") :module-form)))
      (table.insert findings
                    (finding path form (rule-severity policy "spec-no-module") "spec-no-module" "specs must not declare a module" node)))
    (when (and (enabled? policy "spec-direct-require")
               (spec-file? path policy.spec-files policy.matcher)
               (require-node? node))
      (spec-rule.spec-direct-require-finding findings path form policy node))
    (when (and (= head "testing") (enabled? policy "one-is-per-testing"))
      (spec-rule.testing-finding findings path form policy node))
    (when (and (enabled? policy "function-shape")
               node
               (contains? (. (registry.rule-options policy "function-shape") :function-forms) head 1))
      (shape-rule.add-function-findings findings path form forms policy node))
    (when (enabled? policy "if-branch-call")
      (append-all findings (branch-rule.finding path form policy node)))
    (when (and (or (= head "local") (= head "require"))
               node
               (enabled? policy "core-require"))
      (module-rule.core-require-finding findings path form head node policy))
    findings))

(defn- append-form-findings
  [all path forms policy spec-import]
  (when (enabled? policy "spec-macro-import")
    (append-all all (spec-rule.spec-import-finding path forms policy spec-import)))
  (each [_ form (ipairs forms)]
    (append-all all (evaluate-form path form forms policy)))
  all)

(defn- append-synthetic-findings
  [all path forms policy source]
  (shape-rule.synthetic-findings all path forms policy source))

(defn- remove-contained-function-findings
  [findings]
  (shape-rule.remove-contained-function-findings findings))

(defn- append-applicable-finding
  [result finding policy spec?]
  (when (registry.applies-to? policy finding.rule spec?)
    (table.insert result finding))
  result)

(defn- applicable-findings-step
  [findings policy spec? index result recurse]
  (let [next-result (append-applicable-finding result (. findings index) policy spec?)]
    (recurse findings policy spec? (+ index 1) next-result)))

(defn- applicable-findings
  [findings policy spec? index result]
  (if (> index (length findings))
    result
    (applicable-findings-step findings policy spec? index result applicable-findings)))

(defn- append-file-size-findings
  [findings path policy source]
  (if (enabled? policy "file-size")
    (size-rule.finding path policy source)
    findings))

(defn- append-module-findings
  [findings path forms policy state]
  (if (enabled? policy "module-style")
    (append-all findings
                (module-rule.module-finding path forms policy (and state.module-import state.module-form)))
    findings))

(defn- append-shape-findings
  [findings path forms policy source]
  (if (enabled? policy "function-shape")
    (append-synthetic-findings findings path forms policy source)
    findings))

(defn- append-when-findings
  [findings path forms policy source]
  (if (enabled? policy "if-without-else")
    (when-rule.findings findings path forms policy source)
    findings))

(defn- append-defn-findings
  [findings path forms policy source]
  (if (enabled? policy "defn-args-newline")
    (defn-rule.findings findings path forms policy source)
    findings))

(defn- append-layout-findings
  [findings path forms policy source]
  (if (or (enabled? policy "multiline-layout")
          (enabled? policy "if-branch-call"))
    (layout-rule.findings findings path forms policy source)
    findings))

(defn- append-control-findings
  [findings path forms policy source]
  (if (enabled? policy "control-layout")
    (control-rule.findings findings path forms policy source)
    findings))

(defn- append-discard-findings
  [findings path forms policy source]
  (if (enabled? policy "unused-and-or")
    (discard-rule.findings findings path forms policy source)
    findings))

(defn- append-mutation-findings
  [findings path forms policy source]
  (if (enabled? policy "no-mutation")
    (mutation-rule.findings findings path forms policy source)
    findings))

(defn- append-binding-findings
  [findings path forms policy source]
  (if (enabled? policy "binding-per-line")
    (binding-rule.findings findings path forms policy source)
    findings))

(defn- append-call-findings
  [findings path forms policy source]
  (if (enabled? policy "call-data-arg")
    (call-rule.findings findings path forms policy source)
    findings))

(defn- check-result
  [path forms policy source state]
  (let [findings (append-file-size-findings [] path policy source)
        findings (append-module-findings findings path forms policy state)
        findings (append-form-findings findings path forms policy state.spec-import)
        findings (append-shape-findings findings path forms policy source)
        findings (append-when-findings findings path forms policy source)
        findings (append-defn-findings findings path forms policy source)
        findings (append-layout-findings findings path forms policy source)
        findings (append-control-findings findings path forms policy source)
        findings (append-discard-findings findings path forms policy source)
        findings (append-mutation-findings findings path forms policy source)
        findings (append-binding-findings findings path forms policy source)
        findings (append-call-findings findings path forms policy source)]
    (remove-contained-function-findings findings)))

(defn check
  [path forms policy source]
  (let [state  (check-state (root-forms source) 1 {:module-import false :module-form false :spec-import false} policy)
        result (check-result path forms policy source state)
        spec?  (spec-file? path policy.spec-files policy.matcher)]
    (applicable-findings result policy spec? 1 [])))
