(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.control)

(local core (require :eca.nfnl.core))
(local ast (require :fennel-extras.lint.rules.ast))
(local registry (require :fennel-extras.lint.rules.registry))
(local list-head ast.list-head)
(local meaningful-children ast.meaningful-children)
(local previous-meaningful-index ast.previous-meaningful-index)
(local form-for-node ast.form-for-node)
(local nearest-form ast.nearest-form)
(local finding registry.finding)
(local enabled? registry.enabled?)
(local rule-severity registry.rule-severity)

(defn- contains?
  [items target index]
  (if (> index (length items))
    false
    (or (= (. items index) target)
        (contains? items target (+ index 1)))))

(local function-heads {:defn true :defn- true :fn true :lambda true :λ true})
(local binding-heads {:let true :when-let true :if-let true :with-open true})

(defn- quoted-mode-for-prefix
  [prefix mode]
  (or (and (= prefix "'") :quoted)
      (and (= mode :quoted) :quoted)
      (and (= prefix "`") (+ mode 1))
      (and (= prefix ",") (math.max 0 (- mode 1)))
      mode))

(defn- quoted-mode-for-child
  [node index mode]
  (let [previous-index (previous-meaningful-index node.children index)
        previous       (and previous-index (. node.children previous-index))]
    (if (and previous (= previous.kind :prefix))
      (quoted-mode-for-prefix previous.text (quoted-mode-for-child node previous-index mode))
      mode)))

(defn- meaningful-index-step
  [result child target index]
  (if (and (= result 0) (= child target))
    index
    result))

(defn- meaningful-index
  [node target]
  (let [children (meaningful-children node)]
    (accumulate [result 0 index child (ipairs children)]
      (meaningful-index-step result child target index))))

(defn- function-body-offset
  [argument]
  (if (and argument (= argument.kind :string))
    1
    0))

(local body-heads
       {:let        true
        :when       true
        :when-let   true
        :if-let     true
        :with-open  true
        :each       true
        :for        true
        :while      true
        :icollect   true
        :collect    true
        :accumulate true})
(local built-in-control-heads {:if true :when true :and true :or true :case true :match true})

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

(defn- body-form?
  [head policy]
  (or (. body-heads head)
      (and (not (. built-in-control-heads head))
           (contains? (. (registry.rule-options policy "control-layout") :forms) head 1))))

(defn- body-start
  [head children policy]
  (let [argument (. children (function-argument-index head))]
    (or (and (. function-heads head)
             (+ (function-base head) (function-body-offset argument)))
        (and (body-form? head policy) 3)
        (and (= head "do") 2)
        0)))

(defn- body-child?
  [head children index policy]
  (let [start (body-start head children policy)]
    (and (> start 0) (>= index start))))

(defn- last-body-child?
  [head children index policy]
  (and (body-child? head children index policy)
       (= index (length children))))

(defn- custom-control-root?
  [parent child policy]
  (and (= (list-head parent) nil)
       (= child.kind :list)
       (not (. built-in-control-heads (list-head child)))
       (contains? (. (registry.rule-options policy "control-layout") :forms) (list-head child) 1)))

(defn- statement-child?
  [parent child policy]
  (let [head     (list-head parent)
        children (meaningful-children parent)
        index    (meaningful-index parent child)]
    (or (custom-control-root? parent child policy)
        (and (body-child? head children index policy)
             (= (length children) (body-start head children policy))
             (not (and (last-body-child? head children index policy)
                       (or (= (list-head child) "and")
                           (= (list-head child) "or"))))))))

(defn- executable-child?
  [child mode]
  (and (or (= child.kind :list) (= child.kind :sequence) (= child.kind :table))
       (not= mode :quoted)))

(defn- control-form?
  [node statement? policy]
  (let [heads (. (registry.rule-options policy "control-layout") :forms)]
    (and statement?
         (= node.kind :list)
         (contains? heads (list-head node) 1))))

(defn- append-control-finding
  [findings path forms policy node ordinals]
  (let [existing (form-for-node forms node nil)
        base     (or existing (nearest-form forms node) {:form path})
        head     (list-head node)
        key      (.. base.form ":" head)
        ordinal  (+ (or (. ordinals key) 0) 1)
        form     (or existing
                     {:line node.open.line :col node.open.col :end-line node.close.line :end-col (+ node.close.col 1) :form (.. base.form " > " head "#" ordinal) :node node})]
    (table.insert findings
                  (finding path form (rule-severity policy "control-layout") "control-layout" "put this control form on several lines" node))
    (core.assoc ordinals key ordinal)))

(defn- offending-control?
  [node statement? mode policy]
  (and (= mode 0)
       (control-form? node statement? policy)
       (= node.open.line node.close.line)))

(defn- next-ordinals
  [findings path forms policy node statement? mode ordinals]
  (if (offending-control? node statement? mode policy)
    (append-control-finding findings path forms policy node ordinals)
    ordinals))

(defn- visit-child
  [state index child]
  (let [child-mode (quoted-mode-for-child state.node index state.mode)]
    (if (executable-child? child child-mode)
      (state.visit state.findings state.path state.forms state.policy child (statement-child? state.node child state.policy) child-mode state.ordinals)
      state.ordinals)))

(defn- visit-node
  [findings path forms policy node statement? mode ordinals]
  (let [next-ordinals (next-ordinals findings path forms policy node statement? mode ordinals)
        state         {:findings findings :path path :forms forms :policy policy :node node :mode mode :ordinals next-ordinals :visit visit-node}]
    (accumulate [result next-ordinals index child (ipairs (or node.children []))]
      (visit-child (core.assoc state :ordinals result) index child))))

(defn- visit-root
  [findings path forms policy root]
  (visit-node findings path forms policy root false 0 {})
  findings)

(defn- append-control-findings
  [findings path forms policy source]
  (let [reader (require :fennel-extras.reader)
        root   (reader.parse source)]
    (if root
      (visit-root findings path forms policy root)
      findings)))

(defn findings
  [findings path forms policy source]
  (if (enabled? policy "control-layout")
    (append-control-findings findings path forms policy source)
    findings))
