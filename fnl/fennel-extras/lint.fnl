(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint)

(local identity (require :fennel-extras.lint.identity))
(local rules (require :fennel-extras.lint.rules))
(local registry (require :fennel-extras.lint.rules.registry))
(local selection (require :fennel-extras.lint.selection))

(defn- exclusion-match?
  [exclusion finding]
  (and (= exclusion.rule finding.rule)
       (= exclusion.form finding.form)))

(defn- excluded?
  [exclusions finding index]
  (if (> index (length exclusions))
    false
    (or (and (exclusion-match? (. exclusions index) finding) true)
        (excluded? exclusions finding (+ index 1)))))

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
  [result finding forms exclusions scope]
  (when (and (selected? finding forms scope)
             (not (excluded? exclusions finding 1)))
    (table.insert result finding))
  result)

(defn- filter-findings-step
  [findings forms exclusions scope index result recurse]
  (let [finding     (. findings index)
        next-result (append-selected-finding result finding forms exclusions scope)]
    (recurse findings forms exclusions scope (+ index 1) next-result)))

(defn- filter-findings
  [findings forms exclusions scope index result]
  (if (> index (length findings))
    result
    (filter-findings-step findings forms exclusions scope index result filter-findings)))

(defn- checked-findings
  [forms error path policy max-code-lines exclusions scope source]
  (if error
    (values nil error)
    (filter-findings (rules.check path forms policy source max-code-lines) forms exclusions scope 1 [])))

(defn check
  [source context]
  (let [path           (or (. context :path) "")
        policy         (or (. context :rules) {})
        max-code-lines (or (. context :max-code-lines) 300)
        exclusions     (or (. context :exclusions) [])
        scope          (. context :selection)
        (forms error)  (identity.forms source path)]
    (checked-findings forms error path policy max-code-lines exclusions scope source)))
