(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.discard)

(local core (require :eca.nfnl.core))
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

(local function-heads {:defn true :defn- true :fn true :lambda true :λ true})
(local binding-heads {:let true :when true :when-let true :if-let true :with-open true})
(local discard-loop-heads {:each true :for true :while true})
(local default-target-heads {:and true :or true})
(defn- contains?
  [items target index]
  (if (> index (length items))
    false
    (or (= (. items index) target)
        (contains? items target (+ index 1)))))

(defn- function-body-offset
  [argument]
  (if (and argument (= argument.kind :string))
    1
    0))

(defn- function-argument-index
  [head]
  (or (and (= head "defn") 3)
      (and (= head "defn-") 3)
      2))

(defn- function-base
  [head]
  (or (and (= head "defn") 4)
      (and (= head "defn-") 4)
      3))

(defn- body-start
  [head children]
  (let [argument (. children (function-argument-index head))]
    (or (and (. function-heads head)
             (+ (function-base head) (function-body-offset argument)))
        (and (or (. binding-heads head) (. discard-loop-heads head)) 3)
        (and (= head "do") 2)
        0)))

(defn- meaningful-index-step
  [result index child target]
  (if (and (= result 0) (= child target))
    index
    result))

(defn- meaningful-index
  [node target]
  (let [children (meaningful-children node)]
    (accumulate [result 0 index child (ipairs children)]
      (meaningful-index-step result index child target))))

(defn- target-node?
  [node policy]
  (let [heads (. (registry.rule-options policy "unused-and-or") :forms)]
    (and (= node.kind :list)
         (contains? heads (list-head node) 1))))

(defn- custom-target-root?
  [parent child policy]
  (and (= (list-head parent) nil)
       (target-node? child policy)
       (not (. default-target-heads (list-head child)))))

(defn- discarded-child?
  [parent child policy]
  (let [head     (list-head parent)
        children (meaningful-children parent)
        index    (meaningful-index parent child)
        start    (body-start head children)]
    (or (custom-target-root? parent child policy)
        (and (> start 0)
             (>= index start)
             (or (. discard-loop-heads head)
                 (< index (length children)))))))

(defn- add-target-key
  [result node]
  (tset result (.. node.open.line ":" node.open.col) true)
  result)

(defn- target-nodes
  [source policy]
  (mutation.executable-nodes source (fn [node] (target-node? node policy))))

(defn- target-keys
  [source policy]
  (accumulate [result {} _ node (ipairs (target-nodes source policy))]
    (add-target-key result node)))

(defn- executable-child?
  [child]
  (or (= child.kind :list) (= child.kind :sequence) (= child.kind :table)))

(defn- append-finding
  [findings path forms policy node ordinals]
  (let [existing (form-for-node forms node nil)
        base     (or existing (nearest-form forms node) {:form path})
        head     (list-head node)
        key      (.. base.form ":" head)
        ordinal  (+ (or (. ordinals key) 0) 1)
        form     (or existing
                     {:line node.open.line :col node.open.col :end-line node.close.line :end-col (+ node.close.col 1) :form (.. base.form " > " head "#" ordinal) :node node})]
    (table.insert findings
                  (finding path form (rule-severity policy "unused-and-or") "unused-and-or" "and/or result is unused; use when" node))
    (core.assoc ordinals key ordinal)))

(defn- visit-child
  [state index child]
  (if (executable-child? child)
    (state.visit state.findings state.path state.forms state.policy state.targets child (discarded-child? state.node child state.policy) state.ordinals)
    state.ordinals))

(defn- next-ordinals
  [findings path forms policy targets node discarded? ordinals]
  (if (and discarded?
           (. targets (.. node.open.line ":" node.open.col)))
    (append-finding findings path forms policy node ordinals)
    ordinals))

(defn- visit-node
  [findings path forms policy targets node discarded? ordinals]
  (let [next-ordinals (next-ordinals findings path forms policy targets node discarded? ordinals)
        state         {:findings findings :path path :forms forms :policy policy :targets targets :node node :ordinals next-ordinals :visit visit-node}]
    (accumulate [result next-ordinals index child (ipairs (or node.children []))]
      (visit-child (core.assoc state :ordinals result) index child))))

(defn- visit-root
  [findings path forms policy targets root]
  (visit-node findings path forms policy targets root false {})
  findings)

(defn- append-findings
  [findings path forms policy source]
  (let [reader (require :fennel-extras.reader)
        root   (reader.parse source)]
    (if root
      (visit-root findings path forms policy (target-keys source policy) root)
      findings)))

(defn findings
  [findings path forms policy source]
  (if (enabled? policy "unused-and-or")
    (append-findings findings path forms policy source)
    findings))
