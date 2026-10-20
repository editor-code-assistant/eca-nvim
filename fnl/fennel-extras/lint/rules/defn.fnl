(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.defn)

(local ast (require :fennel-extras.lint.rules.ast))
(local mutation (require :fennel-extras.lint.rules.mutation))
(local registry (require :fennel-extras.lint.rules.registry))
(local meaningful-children ast.meaningful-children)
(local list-head ast.list-head)
(local form-for-node ast.form-for-node)
(local nearest-form ast.nearest-form)
(local finding registry.finding)
(local enabled? registry.enabled?)
(local rule-severity registry.rule-severity)

(defn- defn-node?
  [node]
  (and (= node.kind :list)
       (or (= (list-head node) "defn")
           (= (list-head node) "defn-"))))

(defn- docstring?
  [children]
  (let [third (. children 3)]
    (and third (= third.kind :string))))

(defn- parameter-index
  [children]
  (if (docstring? children) 4 3))

(defn- parameter-vector
  [node]
  (let [children (meaningful-children node)
        index    (parameter-index children)]
    (. children index)))

(defn- invalid-layout?
  [node]
  (let [children (meaningful-children node)
        name     (. children 2)
        args     (parameter-vector node)]
    (and name args (<= args.open.line name.line))))

(defn- finding-form
  [path forms node]
  (let [existing (form-for-node forms node nil)
        base     (or existing (nearest-form forms node) {:form path})]
    (or existing
        {:line     node.open.line
         :col      node.open.col
         :end-line node.close.line
         :end-col  (+ node.close.col 1)
         :form     (.. base.form " > defn-args-newline")
         :node     node})))

(defn- add-finding
  [findings path policy node form]
  (table.insert findings
                (finding path
                         form
                         (rule-severity policy "defn-args-newline")
                         "defn-args-newline"
                         "put the defn argument vector on the line below the name"
                         node)))

(defn- append-finding
  [findings path forms policy node]
  (when (invalid-layout? node)
    (add-finding findings path policy node (finding-form path forms node)))
  findings)

(defn- append-node-finding
  [findings path forms policy node]
  (append-finding findings path forms policy node))

(defn- append-node-findings
  [findings path forms policy source]
  (each [_ node (ipairs (mutation.executable-nodes source defn-node?))]
    (append-node-finding findings path forms policy node))
  findings)

(defn findings
  [findings path forms policy source]
  (when (enabled? policy "defn-args-newline")
    (append-node-findings findings path forms policy source))
  findings)
