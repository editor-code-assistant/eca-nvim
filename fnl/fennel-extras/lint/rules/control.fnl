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

(local control-heads {:if true :when true :and true :or true :case true :match true})
(local function-heads {:defn true :defn- true :fn true :lambda true :λ true})
(local binding-heads {:let true :when-let true :if-let true :with-open true})
(local loop-heads {:each true :for true :while true :icollect true :collect true :accumulate true})

(defn- quoted-mode-for-prefix
  [prefix mode]
  (or (and (= prefix "'") :quoted)
      (and (= mode :quoted) :quoted)
      (and (= prefix "`") (+ mode 1))
      (and (= prefix ",") (math.max 0 (- mode 1)))
      mode))

(defn- quoted-mode-for-child
  [node index mode]
  (let [previous-index (previous-meaningful-index node.children index) previous       (and previous-index (. node.children previous-index))]
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

(defn- body-start
  [head children]
  (let [argument (. children 2)]
    (or (and (. function-heads head)
             (+ 3 (function-body-offset argument)))
        (and (or (. binding-heads head) (. loop-heads head)) 3)
        (and (= head "do") 2)
        0)))

(defn- statement-child?
  [parent child]
  (let [head     (list-head parent) children (meaningful-children parent) index    (meaningful-index parent child) start    (body-start head children)]
    (and (> start 0)
         (>= index start))))

(defn- executable-child?
  [child mode]
  (and (or (= child.kind :list) (= child.kind :sequence) (= child.kind :table))
       (not= mode :quoted)))

(defn- control-form?
  [node statement?]
  (and statement?
       (= node.kind :list)
       (. control-heads (list-head node))))

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
  [node statement? mode]
  (and (= mode 0)
       (control-form? node statement?)
       (= node.open.line node.close.line)))

(defn- next-ordinals
  [findings path forms policy node statement? mode ordinals]
  (if (offending-control? node statement? mode)
    (append-control-finding findings path forms policy node ordinals)
    ordinals))

(defn- visit-child
  [state index child]
  (let [child-mode (quoted-mode-for-child state.node index state.mode)]
    (if (executable-child? child child-mode)
      (state.visit state.findings state.path state.forms state.policy child (statement-child? state.node child) child-mode state.ordinals)
      state.ordinals)))

(defn- visit-node
  [findings path forms policy node statement? mode ordinals]
  (let [next-ordinals (next-ordinals findings path forms policy node statement? mode ordinals)
        state         {:findings findings :path     path :forms    forms :policy   policy :node     node :mode     mode :ordinals next-ordinals :visit    visit-node}]
    (accumulate [result next-ordinals index child (ipairs (or node.children []))]
      (visit-child (core.assoc state :ordinals result) index child))))

(defn- visit-root
  [findings path forms policy root]
  (visit-node findings path forms policy root false 0 {})
  findings)

(defn- append-control-findings
  [findings path forms policy source]
  (let [reader (require :fennel-extras.reader) root   (reader.parse source)]
    (if root
      (visit-root findings path forms policy root)
      findings)))

(defn findings
  [findings path forms policy source]
  (if (enabled? policy "control-layout")
    (append-control-findings findings path forms policy source)
    findings))
