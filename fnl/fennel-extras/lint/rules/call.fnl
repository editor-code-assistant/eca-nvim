(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.call)

(local ast (require :fennel-extras.lint.rules.ast))
(local mutation (require :fennel-extras.lint.rules.mutation))
(local valid (require :fennel-extras.lint.rules.shape.leaf.valid))
(local registry (require :fennel-extras.lint.rules.registry))
(local meaningful-children ast.meaningful-children)
(local list-head ast.list-head)
(local quoted-child? ast.quoted-child?)
(local form-for-node ast.form-for-node)
(local nearest-form ast.nearest-form)
(local finding registry.finding)
(local enabled? registry.enabled?)
(local rule-severity registry.rule-severity)

(local control-heads {:and true :or true :if true :when true :case true :match true :case-try true :match-try true})
(local binding-heads {:let true :when-let true :if-let true :with-open true})
(local definition-heads {:local true :global true :var true :set true :tset true :do true :macro true :import-macros true})
(local function-heads {:defn true :defn- true :fn true :lambda true :λ true})

(defn- special-head?
  [head]
  (or (. control-heads head)
      (. binding-heads head)
      (. definition-heads head)
      (. function-heads head)
      (valid.loop-head? head)))

(defn- multiline-data?
  [node]
  (and (or (= node.kind :sequence) (= node.kind :table))
       (> node.close.line node.open.line)))

(defn- data-argument?
  [children index child]
  (and (>= index 2)
       (not (quoted-child? children index))
       (multiline-data? child)))

(defn- data-argument-step
  [children index child]
  (if (data-argument? children index child)
    true
    false))

(defn- has-data-argument?
  [children]
  (accumulate [result false index child (ipairs children)]
    (or result (data-argument-step children index child))))

(defn- contains?
  [items target index]
  (if (> index (length items))
    false
    (or (= (. items index) target)
        (contains? items target (+ index 1)))))

(defn- plain-call?
  [node policy]
  (let [head   (list-head node)
        ignore (. (registry.rule-options policy "call-data-arg") :forms)]
    (and (= node.kind :list)
         head
         (not (special-head? head))
         (not (contains? ignore head 1)))))

(defn- offending-node?
  [node policy]
  (and (plain-call? node policy)
       (has-data-argument? (meaningful-children node))))

(defn- call-nodes
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
                      :form     (.. base.form " > call-data-arg#" ordinal)
                      :node     node})]
    (table.insert findings
                  (finding path
                           form
                           (rule-severity policy "call-data-arg")
                           "call-data-arg"
                           "move this multi-line map/vector into a let binding so the call fits on one line"
                           node))
    (update-ordinal ordinals base.form ordinal)))

(defn- append-node-finding
  [findings path forms policy node ordinals]
  (if (and (enabled? policy "call-data-arg"))
    (append-finding findings path forms policy node ordinals)
    ordinals))

(defn findings
  [findings path forms policy source]
  (accumulate [ordinals {} _ node (ipairs (call-nodes source policy))]
    (append-node-finding findings path forms policy node ordinals))
  findings)
