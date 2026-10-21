(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.when)

(local ast (require :fennel-extras.lint.rules.ast))
(local mutation (require :fennel-extras.lint.rules.mutation))
(local registry (require :fennel-extras.lint.rules.registry))
(local list-head ast.list-head)
(local meaningful-children ast.meaningful-children)
(local form-for-node ast.form-for-node)
(local nearest-form ast.nearest-form)
(local finding registry.finding)
(local enabled? registry.enabled?)
(local rule-severity registry.rule-severity)

(defn- if-without-else?
  [node]
  (let [children   (meaningful-children node)
        else-child (. children 4)]
    (and (= node.kind :list)
         (= (list-head node) "if")
         (or (= (length children) 3)
             (and (= (length children) 4)
                  (= else-child.kind :symbol)
                  (= else-child.text "nil"))))))

(defn- finding-form
  [path forms node]
  (or (form-for-node forms node nil)
      (nearest-form forms node)
      {:line node.open.line :col node.open.col :end-line node.close.line :end-col (+ node.close.col 1) :form path :node node}))

(defn- append-finding
  [findings path forms policy node]
  (table.insert findings
                (finding path
                         (finding-form path forms node)
                         (rule-severity policy "if-without-else")
                         "if-without-else"
                         "if without else; use when"
                         node))
  findings)

(defn- append-node-findings
  [findings path forms policy nodes]
  (each [_ node (ipairs nodes)]
    (append-finding findings path forms policy node))
  findings)

(defn findings
  [findings path forms policy source]
  (when (enabled? policy "if-without-else")
    (append-node-findings findings path forms policy (mutation.executable-nodes source if-without-else?)))
  findings)
