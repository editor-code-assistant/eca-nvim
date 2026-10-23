(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint)

(local core (require :eca.nfnl.core))
(local identity (require :fennel-extras.lint.identity))
(local ast (require :fennel-extras.lint.rules.ast))
(local rules (require :fennel-extras.lint.rules))
(local registry (require :fennel-extras.lint.rules.registry))
(local selection (require :fennel-extras.lint.selection))
(local exclusion-matcher (require :fennel-extras.lint.exclusion))
(local rule-options (require :fennel-extras.lint.rules.options))

(defn- normalized-policy-entry
  [entry]
  (if (= (type entry) :table)
    entry.severity
    entry))

(defn- normalized-context-policy
  [raw-policy]
  (let [result {}]
    (each [rule entry (pairs raw-policy)]
      (tset result rule (normalized-policy-entry entry)))
    result))

(defn- context-policy
  [context raw-policy]
  (if context.matcher
    (normalized-context-policy raw-policy)
    raw-policy))

(defn- policy-for-context
  [context]
  (let [raw-policy (. context :rules)]
    (if raw-policy
      (context-policy context raw-policy)
      {})))

(defn- append-context-option
  [result rule entry]
  (if (and (= (type entry) :table) entry.options)
    (core.assoc result rule entry.options)
    result))

(defn- context-options
  [context]
  (accumulate [result {} rule entry (pairs (or context.rules {}))]
    (append-context-option result rule entry)))

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
  (if (= finding.rule "one-is-per-testing")
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
  [rule value]
  (let [copy {}]
    (each [key item (pairs value)]
      (tset copy key item))
    (core.assoc copy :rule rule)))

(defn- append-context-values
  [result rule entries]
  (each [_ value (ipairs entries)]
    (table.insert result (copy-context-exclusion rule value)))
  result)

(defn- append-context-entry
  [result rule entry]
  (if (and (= (type entry) :table) entry.exclusions)
    (append-context-values result rule entry.exclusions)
    result))

(defn- append-context-exclusions
  [result raw-policy]
  (each [rule entry (pairs raw-policy)]
    (append-context-entry result rule entry))
  result)

(defn- context-exclusions
  [context]
  (let [result (core.concat [] (or context.exclusions []))]
    (append-context-exclusions result (or context.rules {}))))

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

(defn- regex-spec-files-error-entry
  [spec-files matcher index]
  (when (and (= matcher nil)
             (not (ast.literal-prefix-pattern? (. spec-files index))))
    {:message (.. "lint spec-files " index ": regex patterns require a matcher")}))

(defn- regex-spec-files-error
  [spec-files matcher index]
  (if (> index (length spec-files))
    nil
    (or (regex-spec-files-error-entry spec-files matcher index)
        (regex-spec-files-error spec-files matcher (+ index 1)))))

(defn- missing-option-result
  [option-values names index name recurse]
  (if (or (= option-values nil)
          (= (. option-values name) nil))
    name
    (recurse option-values names (+ index 1))))

(defn- missing-option-step-result
  [option-values names index name recurse]
  (missing-option-result option-values names index name recurse))

(defn- missing-option-step
  [option-values names index]
  (if (> index (length names))
    nil
    (missing-option-step-result option-values names index (. names index) missing-option-step)))

(defn- policy-error-result
  [rules options names index rule severity entry recurse]
  (let [missing (and (not= severity "off")
                     (missing-option-step entry (rule-options.names rule) 1))]
    (if missing
      {:message (.. "missing lint.rules." rule ".options." missing)}
      (recurse rules options names (+ index 1)))))

(defn- policy-error-step-result
  [rules options names index rule severity entry recurse]
  (policy-error-result rules options names index rule severity entry recurse))

(defn- policy-error-step
  [rules options names index]
  (if (> index (length names))
    nil
    (policy-error-step-result rules
                              options
                              names
                              index
                              (. names index)
                              (registry.rule-severity rules (. names index))
                              (. options (. names index))
                              policy-error-step)))

(defn- policy-with-options-missing
  [missing]
  (when missing
    (_G.error {:message (.. "missing lint." missing)})))

(defn- policy-with-options-result
  [base-policy options spec-files matcher missing]
  (if (= (type missing) :table)
    (_G.error missing)
    (or (policy-with-options-missing missing)
        (core.merge base-policy {:options options :spec-files spec-files :matcher matcher}))))

(defn- policy-with-options
  [base-policy context matcher spec-files]
  (let [raw-options (or (. context :options) (context-options context))
        options     (rule-options.normalized raw-options)
        missing     (or (and (= spec-files nil) "spec-files")
                        (policy-error-step base-policy options (registry.rule-names) 1))]
    (policy-with-options-result base-policy options spec-files matcher missing)))

(defn check
  [source context]
  (let [path                (or (. context :path) "")
        base-policy         (policy-for-context context)
        matcher             (. context :matcher)
        spec-files          (. context :spec-files)
        policy              (policy-with-options base-policy context matcher spec-files)
        exclusions          (context-exclusions context)
        scope               (. context :selection)
        (forms parse-error) (identity.forms source path)
        matcher-error       (or (regex-exclusion-error exclusions matcher 1)
                                (regex-spec-files-error spec-files matcher 1))]
    (if matcher-error
      (_G.error matcher-error)
      (checked-findings forms parse-error path policy exclusions scope source matcher context.defer-exclusions))))
