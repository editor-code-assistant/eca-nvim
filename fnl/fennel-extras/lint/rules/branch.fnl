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

(defn finding [path form policy node]
  (if (and (= (list-head node) "do")
           (do-branch? node)
           (or (string.match form.form " > then$")
               (string.match form.form " > else$")
               (string.match form.form " > then#[0-9]+$"))
           (enabled? policy "if-branch-call"))
    [(make-finding path form (rule-severity policy "if-branch-call")
                   "if-branch-call"
                   "if branch contains multiple expressions; move them to a named helper"
                   node)]
    []))
