(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint)

(local identity (require :fennel-extras.lint.identity))
(local rules (require :fennel-extras.lint.rules))
(local selection (require :fennel-extras.lint.selection))

(defn- exclusion-match? [exclusion finding]
  (and (= exclusion.rule finding.rule)
       (= exclusion.form finding.form)))

(defn- excluded? [exclusions finding index]
  (if (> index (length exclusions))
      false
      (or (and (exclusion-match? (. exclusions index) finding) true)
          (excluded? exclusions finding (+ index 1)))))

(defn- branch-base [form suffix]
  (string.gsub form suffix ""))

(defn- branch-form [form]
  (let [then-base (branch-base form " > then$")
        else-base (branch-base form " > else$")]
    (or (and (not= then-base form) then-base)
        (and (not= else-base form) else-base))))

(defn- selected-form? [forms target scope index]
  (if (> index (length forms))
      false
      (let [form (. forms index)]
        (if (= form.form target)
            (selection.form-selected? form scope)
            (selected-form? forms target scope (+ index 1))))))

(defn- selected-branch? [finding forms scope]
  (let [branch (branch-form finding.form)]
    (and branch (selected-form? forms branch scope 1))))

(defn- selected-scope? [finding forms scope]
  (if (or (= finding.rule "module-style") (= finding.rule "spec-macro-import"))
      (> (length scope) 0)
      (or (selection.form-selected? finding scope)
          (selected-branch? finding forms scope))))

(defn- selected? [finding forms scope]
  (or (= scope nil)
      (= scope true)
      (selected-scope? finding forms scope)))

(defn- filter-findings [findings forms exclusions scope index result]
  (if (> index (length findings))
      result
      (let [finding (. findings index)]
        (if (and (selected? finding forms scope)
                 (not (excluded? exclusions finding 1)))
            (table.insert result finding))
        (filter-findings findings forms exclusions scope (+ index 1) result))))

(defn check [source context]
  (let [path (or (. context :path) "")
        policy (or (. context :rules) {})
        exclusions (or (. context :exclusions) [])
        scope (. context :selection)
        (forms error) (identity.forms source path)]
    (if error
        (values nil error)
        (filter-findings (rules.check path forms policy source) forms exclusions scope 1 []))))
