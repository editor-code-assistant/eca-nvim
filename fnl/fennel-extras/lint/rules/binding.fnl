(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.binding)

(local core (require :eca.nfnl.core))
(local ast (require :fennel-extras.lint.rules.ast))
(local bindings (require :fennel-extras.indent.bindings))
(local registry (require :fennel-extras.lint.rules.registry))
(local traverse (require :fennel-extras.lint.rules.traverse))

(defn- contains?
  [items target index]
  (and (<= index (length (or items [])))
       (or (= (. items index) target)
           (contains? items target (+ index 1)))))

(defn- single-binding?
  [node]
  (let [children (ast.meaningful-children node)]
    (and (= (length children) 3)
         (= (length (bindings.pairs (. children 2))) 1))))

(defn- form-for-node
  [forms path node]
  (let [form (ast.form-for-node forms node
                                {:line     node.open.line
                                 :col      node.open.col
                                 :end-line node.close.line
                                 :end-col  (+ node.close.col 1)
                                 :form     (.. path " > " (or (ast.list-head node) "form"))
                                 :node     node})
        head (ast.list-head node)]
    (core.assoc form :form (vim.fn.substitute form.form "top#\\d\\+$" (.. head "#1") ""))))

(defn findings
  [path forms policy source rule]
  (let [result   []
        selected (and (registry.enabled? policy rule)
                      (or policy.options.forms []))]
    (each [_ node (ipairs (traverse.executable-nodes source
                                                     (fn [candidate]
                                                       (and (contains? selected (ast.list-head candidate) 1)
                                                            (single-binding? candidate)))))]
          (table.insert result
                        (registry.finding path
                                          (form-for-node forms path node)
                                          (registry.rule-severity policy rule)
                                          rule
                                          "avoid introducing a local binding for a single body expression"
                                          node)))
    result))
