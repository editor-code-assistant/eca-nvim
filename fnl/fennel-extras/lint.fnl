(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint)

(local core (require :eca.nfnl.core))
(local identity (require :fennel-extras.lint.identity))
(local ast (require :fennel-extras.lint.rules.ast))
(local rules (require :fennel-extras.lint.rules))
(local registry (require :fennel-extras.lint.rules.registry))
(local selection (require :fennel-extras.lint.selection))
(local exclusion-matcher (require :fennel-extras.lint.exclusion))
(local config-lint (require :fennel-extras.config.lint))

(defn- policy-for-context
  [context]
  (or (. context :rules) {}))



(defn- normalized-testing-form
  [finding]
  (or (and (string.match finding.form " > top#[0-9]+$")
           (.. finding.form " > testing#1"))
      finding.form))



(defn- normalized-branch-form
  [finding]
  (let [form (string.gsub finding.form " > (top#[0-9]+) > (then.*)$" " > %1 > if#1 > %2")]
    form))



(defn- normalized-form
  [finding]
  (if (= finding.rule "form-child-count")
    (normalized-testing-form finding)
    (normalized-branch-form finding)))



(defn- normalize-finding
  [finding]
  (let [form (normalized-form finding)]
    (if (= finding.form form)
      finding
      (core.assoc finding :form form))))



(defn- excluded?
  [exclusions finding source matcher index]
  (if (> index (length exclusions))
    false
    (or (exclusion-matcher.matches? (. exclusions index) finding source matcher)
        (excluded? exclusions finding source matcher (+ index 1)))))



(defn- branch-base
  [form suffix]
  (string.gsub form suffix ""))



(defn- branch-form
  [form]
  (let [then-base (branch-base form " > then$")
        else-base (branch-base form " > else$")]
    (or (and (not= then-base form) then-base)
        (and (not= else-base form) else-base))))



(defn- selected-form-step
  [forms target scope index recurse]
  (let [form (. forms index)]
    (if (= form.form target)
      (selection.form-selected? form scope)
      (recurse forms target scope (+ index 1)))))



(defn- selected-form?
  [forms target scope index]
  (if (> index (length forms))
    false
    (selected-form-step forms target scope index selected-form?)))



(defn- selected-branch?
  [finding forms scope]
  (let [branch (branch-form finding.form)]
    (and branch
         (selected-form? forms branch scope 1))))



(defn- selected-scope?
  [finding forms scope]
  (if (= (registry.rule-scope finding.rule) :file)
    (> (length scope) 0)
    (or (selection.form-selected? finding scope)
        (selected-branch? finding forms scope))))



(defn- selected?
  [finding forms scope]
  (or (= scope nil)
      (= scope true)
      (selected-scope? finding forms scope)))



(defn- append-selected-finding
  [result finding forms scope exclusions source matcher]
  (let [normalized (normalize-finding finding)]
    (when (and (selected? finding forms scope)
               (not (excluded? exclusions normalized source matcher 1)))
      (table.insert result normalized)))
  result)



(defn- filter-findings-step
  [findings forms scope exclusions source matcher index result recurse]
  (let [finding     (. findings index)
        next-result (append-selected-finding result finding forms scope exclusions source matcher)]
    (recurse findings forms scope exclusions source matcher (+ index 1) next-result)))



(defn- filter-findings
  [findings forms scope exclusions source matcher index result]
  (if (> index (length findings))
    result
    (filter-findings-step findings forms scope exclusions source matcher index result filter-findings)))



(defn- filter-checked-findings
  [findings forms scope exclusions source matcher defer]
  (if defer
    (filter-findings findings forms scope [] source matcher 1 [])
    (filter-findings findings forms scope exclusions source matcher 1 [])))



(defn- checked-findings-success
  [forms path policy exclusions scope source matcher defer]
  (let [findings (rules.check path forms policy source)]
    (filter-checked-findings findings forms scope exclusions source matcher defer)))



(defn- checked-findings
  [forms error path policy exclusions scope source matcher defer]
  (if error
    (values nil error)
    (checked-findings-success forms path policy exclusions scope source matcher defer)))



(defn- copy-context-exclusion
  [rule index value]
  (let [copy {}]
    (each [key item (pairs value)]
      (tset copy key item))
    (core.assoc copy :rule rule :instance index)))



(defn- append-context-values
  [result rule index entries]
  (each [_ value (ipairs entries)]
    (table.insert result (copy-context-exclusion rule index value)))
  result)



(defn- append-context-entry
  [result rule index entry]
  (if (and (= (type entry) :table) entry.exclusions)
    (append-context-values result rule index entry.exclusions)
    result))



(defn- append-context-entries
  [result rule entries]
  (each [index entry (ipairs entries)]
    (append-context-entry result rule index entry))
  result)



(defn- append-context-rule
  [result rule entries]
  (if (= (type entries) :table)
    (append-context-entries result rule entries)
    result))



(defn- context-lint-value
  [context]
  (let [lint-rules   {}
        design-rules (or (. context :design) {})]
    (each [rule entries (pairs (or (. context :rules) {}))]
      (if (= (registry.rule-domain rule) :design)
        (tset design-rules rule entries)
        (tset lint-rules rule entries)))
    {:rules lint-rules :design design-rules}))



(defn- append-context-exclusions
  [result raw-policy]
  (each [_ item (ipairs (registry.instances raw-policy))]
    (each [_ exclusion (ipairs (or item.value.exclusions []))]
      (table.insert result (copy-context-exclusion item.rule item.index exclusion))))
  result)



(defn- context-exclusions
  [context]
  (append-context-exclusions [] (context-lint-value context)))



(defn- regex-exclusion-error-entry
  [entry matcher index]
  (when (and (or entry.pattern entry.code) (= matcher nil))
    {:message (.. "lint exclusion " index ": regex selectors require a matcher")}))



(defn- regex-exclusion-error
  [exclusions matcher index]
  (let [entry (. exclusions index)]
    (if (= entry nil)
      nil
      (or (regex-exclusion-error-entry entry matcher index)
          (regex-exclusion-error exclusions matcher (+ index 1))))))



(defn- context-policy
  [context]
  (core.merge (context-lint-value context)
              {:matcher (. context :matcher)}))



(defn- context-matcher-error
  [context exclusions]
  (regex-exclusion-error exclusions context.matcher 1))



(defn- context-validation-error
  [context]
  (let [value (context-lint-value context)]
    (or (config-lint.lint-error {:rules value.rules})
        (config-lint.design-error {:rules value.design}))))



(defn- context-forms
  [source path]
  (identity.forms source path))



(defn- checked-context
  [forms parse-error path policy exclusions scope source context validation-error matcher-error]
  (let [failure (or validation-error matcher-error)]
    (if failure
      (_G.error failure)
      (checked-findings forms parse-error path policy exclusions scope source context.matcher context.defer-exclusions))))



(defn check
  [source context]
  (let [path                (or (. context :path) "")
        policy              (context-policy context)
        exclusions          (context-exclusions context)
        scope               (. context :selection)
        validation-error    (context-validation-error context)
        (forms parse-error) (context-forms source path)
        matcher-error       (context-matcher-error context exclusions)]
    (checked-context forms parse-error path policy exclusions scope source context validation-error matcher-error)))
