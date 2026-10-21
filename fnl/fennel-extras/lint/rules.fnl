(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules)

(local core (require :eca.nfnl.core))
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

(local defaults-map registry.defaults-map)
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

(defn- module-import-state
  [state import-info]
  (if (and import-info (= import-info.target "eca.nfnl.macros.aniseed"))
    (has-module-import? import-info.names)
    state.module-import))

(defn- spec-import-state
  [state import-info]
  (if (and import-info (= import-info.target "spec.eca.macros"))
    (has-all? import-info.names)
    state.spec-import))

(defn- update-check-state
  [state import-info head]
  {:module-import (module-import-state state import-info) :module-form (or state.module-form (= head "module")) :spec-import (spec-import-state state import-info)})

(defn- check-state-step
  [nodes index state recurse]
  (let [node (. nodes index)]
    (recurse nodes (+ index 1) (update-check-state state (macro-import? node) (list-head node)))))

(defn- check-state
  [nodes index state]
  (if (> index (length nodes))
    state
    (check-state-step nodes index state check-state)))

(defn- append-all
  [target items]
  (each [_ value (ipairs (or items []))]
    (table.insert target value))
  target)

(defn- evaluate-form
  [path form forms policy]
  (let [node     form.node
        head     (list-head node)
        findings []]
    (when (and (spec-file? path) (= head "module") (enabled? policy "spec-no-module"))
      (table.insert findings
                    (finding path form (rule-severity policy "spec-no-module") "spec-no-module" "specs must not declare a module" node)))
    (when (and (spec-file? path) (not (spec-rule.direct-require? path)) (require-node? node))
      (spec-rule.spec-direct-require-finding findings path form policy node))
    (when (= head "testing")
      (spec-rule.testing-finding findings path form policy node))
    (when (and node (shape-leaf.function-head? head))
      (shape-rule.add-function-findings findings path form forms policy node))
    (append-all findings (branch-rule.finding path form policy node))
    (when (and (or (= head "local") (= head "require"))
               node
               (enabled? policy "core-require"))
      (module-rule.core-require-finding findings path form head node policy))
    findings))

(defn- append-form-findings
  [all path forms policy spec-import]
  (append-all all (spec-rule.spec-import-finding path forms policy spec-import))
  (each [_ form (ipairs forms)]
    (append-all all (evaluate-form path form forms policy)))
  all)

(defn- append-synthetic-findings
  [all path forms policy source]
  (shape-rule.synthetic-findings all path forms policy source))

(defn- remove-contained-function-findings
  [findings]
  (shape-rule.remove-contained-function-findings findings))

(defn- check-result
  [path forms policy source max-code-lines state]
  (let [file-policy (core.assoc policy :max-code-lines max-code-lines)
        findings    (size-rule.finding path file-policy source)
        findings    (append-all findings
                                (module-rule.module-finding path forms policy (and state.module-import state.module-form)))
        findings    (append-form-findings findings path forms policy state.spec-import)
        findings    (append-synthetic-findings findings path forms policy source)
        findings    (when-rule.findings findings path forms policy source)
        findings    (defn-rule.findings findings path forms policy source)
        findings    (layout-rule.findings findings path forms policy source)
        findings    (control-rule.findings findings path forms policy source)
        findings    (discard-rule.findings findings path forms policy source)
        findings    (mutation-rule.findings findings path forms policy source)
        findings    (binding-rule.findings findings path forms policy source)
        findings    (call-rule.findings findings path forms policy source)]
    (remove-contained-function-findings findings)))

(defn check
  [path forms policy source max-code-lines]
  (let [state (check-state (root-forms source) 1 {:module-import false :module-form false :spec-import false})]
    (check-result path forms policy source (or max-code-lines 300) state)))
