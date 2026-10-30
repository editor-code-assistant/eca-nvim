(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.spec)

(local ast (require :fennel-extras.lint.rules.ast))
(local registry (require :fennel-extras.lint.rules.registry))
(local meaningful-children ast.meaningful-children)
(local list-head ast.list-head)
(local rule-options registry.rule-options)
(local enabled? registry.enabled?)
(local rule-severity registry.rule-severity)
(local finding registry.finding)
(local count-is ast.count-is)

(defn- count-child-forms
  [node children index result]
  (if (> index (length children))
    result
    (count-child-forms node children (+ index 1)
                       (+ result (count-is node 1 0 (list-head node) (. children index))))))

(defn form-child-count-finding
  [findings path form policy node]
  (let [options (rule-options policy "form-child-count")
        count   (count-child-forms node options.children 1 0)]
    (when (and (enabled? policy "form-child-count")
               (not= count options.max-count))
      (table.insert findings
                    (finding path form (rule-severity policy "form-child-count") "form-child-count" "each testing form must contain exactly one is" node)))))