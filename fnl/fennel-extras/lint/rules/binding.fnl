(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.binding)

(local bindings (require :fennel-extras.indent.bindings))
(local ast (require :fennel-extras.lint.rules.ast))
(local mutation (require :fennel-extras.lint.rules.mutation))
(local registry (require :fennel-extras.lint.rules.registry))
(local list-head ast.list-head)
(local form-for-node ast.form-for-node)
(local nearest-form ast.nearest-form)
(local finding registry.finding)
(local enabled? registry.enabled?)
(local rule-severity registry.rule-severity)

(local binding-heads {:let true :when-let true :if-let true :with-open true})

(defn- pair-line
  [pair]
  (or (and pair.name pair.name.line)
      (and pair.name pair.name.open pair.name.open.line)))

(defn- line-state
  [state pair]
  (let [line (pair-line pair)]
    {:valid    (and state.valid
                    line
                    (or (not state.previous) (> line state.previous)))
     :previous line}))

(defn- valid-state?
  [state]
  state.valid)

(defn- lines-valid?
  [pairs]
  (valid-state? (accumulate [state {:valid true :previous nil} _ pair (ipairs pairs)]
                  (line-state state pair))))

(defn- pair-lines-valid?
  [node]
  (and (= node.kind :sequence)
       (lines-valid? (bindings.pairs node))))

(defn- contains?
  [items target index]
  (if (> index (length items))
    false
    (or (= (. items index) target)
        (contains? items target (+ index 1)))))

(defn- offending-node?
  [node policy]
  (let [children (ast.meaningful-children node)
        binding  (. children 2)
        heads    (or (. (registry.rule-options policy "binding-per-line") :forms) [])]
    (and (= node.kind :list)
         (. binding-heads (list-head node))
         (contains? heads (list-head node) 1)
         (not (pair-lines-valid? binding)))))

(defn- binding-nodes
  [source policy]
  (mutation.executable-nodes source (fn [node] (offending-node? node policy))))

(defn- update-ordinal
  [ordinals key ordinal]
  (tset ordinals key ordinal)
  ordinals)

(defn- append-finding
  [findings path forms policy node ordinals]
  (let [existing (form-for-node forms node nil)
        base     (or existing (nearest-form forms node) {:form path})
        ordinal  (+ (or (. ordinals base.form) 0) 1)
        form     (or existing
                     {:line     node.open.line
                      :col      node.open.col
                      :end-line node.close.line
                      :end-col  (+ node.close.col 1)
                      :form     (.. base.form " > binding-per-line#" ordinal)
                      :node     node})]
    (table.insert findings
                  (finding path
                           form
                           (rule-severity policy "binding-per-line")
                           "binding-per-line"
                           "put each binding on its own line"
                           node))
    (update-ordinal ordinals base.form ordinal)))

(defn- append-node-finding
  [findings path forms policy node ordinals]
  (if (enabled? policy "binding-per-line")
    (append-finding findings path forms policy node ordinals)
    ordinals))

(defn findings
  [findings path forms policy source]
  (accumulate [ordinals {} _ node (ipairs (binding-nodes source policy))]
    (append-node-finding findings path forms policy node ordinals))
  findings)
