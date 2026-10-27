(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.branch)

(local ast (require :fennel-extras.lint.rules.ast))
(local registry (require :fennel-extras.lint.rules.registry))
(local list-head ast.list-head)
(local meaningful-children ast.meaningful-children)
(local symbol-text ast.symbol-text)
(local do-branch? ast.do-branch?)
(local make-finding registry.finding)
(local enabled? registry.enabled?)
(local rule-severity registry.rule-severity)

(defn- contains?
  [items target index]
  (if (> index (length items))
    false
    (or (= (. items index) target)
        (contains? items target (+ index 1)))))

(defn- default-conditional-form?
  [form]
  (or (string.match form.form " > then$")
      (string.match form.form " > else$")
      (string.match form.form " > then#[0-9]+$")))

(defn- named-conditional-form?
  [form name]
  (or (string.match form.form (.. " > " name "[^ >]* > then$") )
      (string.match form.form (.. " > " name "[^ >]* > else$") )
      (string.match form.form (.. " > " name "[^ >]* > then#[0-9]+$") )))

(defn- conditional-form?
  [form policy index]
  (let [forms (. (registry.rule-options policy "if-branch-call") :forms)
        name  (. forms index)]
    (or (and (= name "if") (default-conditional-form? form))
        (and (not= name "if") (named-conditional-form? form name))
        (and (< index (length forms))
             (conditional-form? form policy (+ index 1))))))

(defn- custom-branch?
  [node forms]
  (let [children (meaningful-children node)
        head     (list-head node)]
    (and (= node.kind :list)
         (contains? forms head 1)
         (not= head "if")
         (or (do-branch? (. children 3))
             (do-branch? (. children 4))))))

(defn finding
  [path form policy node]
  (let [forms  (. (registry.rule-options policy "if-branch-call") :forms)
        custom (and forms (not= (. forms 1) "if"))]
    (if (and (or (and (= (list-head node) "do")
                      (do-branch? node)
                      (or custom (conditional-form? form policy 1)))
                 (custom-branch? node forms))
             (enabled? policy "if-branch-call"))
      [(make-finding path
                     form
                     (rule-severity policy "if-branch-call")
                     "if-branch-call"
                     "if branch contains multiple expressions; move them to a named helper"
                     node)]
      [])))
