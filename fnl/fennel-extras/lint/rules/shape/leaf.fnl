(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.shape.leaf)

(local ast (require :fennel-extras.lint.rules.ast))
(local meaningful-children ast.meaningful-children)
(local symbol-text ast.symbol-text)
(local list-head ast.list-head)
(local quoted-child? ast.quoted-child?)
(local append-nodes ast.append-nodes)

(defn function-head? [head]
  (or (= head "defn") (= head "defn-") (= head "fn")
      (= head "lambda") (= head "λ")))

(defn layer-head? [head]
  (or (= head "if") (= head "when") (= head "case") (= head "match")
      (= head "each") (= head "for") (= head "icollect")
      (= head "collect") (= head "accumulate") (= head "while")
      (function-head? head)))

(defn loop-head? [head]
  (or (= head "each") (= head "for") (= head "icollect")
      (= head "collect") (= head "accumulate") (= head "while")))

(defn- append-nodes [target nodes]
  (each [_ node (ipairs nodes)]
    (table.insert target node))
  target)

(defn- parameter-index [children head index]
  (if (> index (length children))
      nil
      (or (and (not= head "defn") (not= head "defn-")
               (= (. (. children index) :kind) :sequence)
               index)
          (parameter-index children head (+ index 1)))))

(defn- docstring-adjusted-index [children index]
  (if (and index (. children index)
           (= (. (. children index) :kind) :string))
      (+ index 1)
      index))

(defn- function-body-child [children body-start index child]
  (if (and body-start (>= index body-start)
           (not (quoted-child? children index)))
      child))

(defn- function-body [children body-start]
  (icollect [index child (ipairs children)]
    (function-body-child children body-start index child)))

(defn- function-parameter [children head]
  (if (or (= head "defn") (= head "defn-"))
      3
      (parameter-index children head 2)))

(defn- function-body-index [parameter]
  (and parameter (+ parameter 1)))

(defn- function-body-start [children parameter]
  (docstring-adjusted-index children (function-body-index parameter)))

(defn function-info [node]
  (let [children   (meaningful-children node)
        head       (symbol-text (. children 1))
        parameter  (function-parameter children head)
        body-start (function-body-start children parameter)
        body       (function-body children body-start)]
    (and (function-head? head) parameter
         {:head head :children children :parameter parameter :body body})))

(defn- marker? [node text]
  (and node (= node.kind :symbol) (= node.text text)))

(defn- direct-layer? [children index]
  (and (not (quoted-child? children index))
       (or (loop-head? (list-head (. children index)))
           (function-head? (list-head (. children index))))))

(defn- direct-layer-value [children index]
  (if (direct-layer? children index) 1 0))

(defn- layer-value [layer?]
  (if layer? 1 0))

(defn- direct-layer-count [children index]
  (or (and (> index (length children)) 0)
      (+ (direct-layer-value children index)
         (direct-layer-count children (+ index 1)))))

(defn- leaf-valid-sequence-step [state children child index valid?]
  (and state
       (or (quoted-child? children index)
           (valid? child))))

(defn- leaf-valid-sequence? [node valid?]
  (let [children (meaningful-children node)]
    (accumulate [state true
                 index child (ipairs children)]
      (leaf-valid-sequence-step state children child index valid?))))

(defn- leaf-valid-binding-step [state children child index valid?]
  (and state
       (or (< index 2)
           (quoted-child? children index)
           (valid? child))))

(defn- leaf-valid-binding-list? [children valid?]
  (accumulate [state true
               index child (ipairs children)]
    (leaf-valid-binding-step state children child index valid?)))

(defn- function-argument-leaf-valid? [node valid?]
  (let [info (function-info node)
        body (or (and info info.body) [])]
    (and info
         (accumulate [state true
                      _ child (ipairs body)]
           (and state (valid? child))))))

(defn- loop-start-index [bindings]
  (if (and bindings (> (length bindings) 0)) 3 2))

(defn- loop-argument-leaf-valid? [node valid?]
  (let [children (meaningful-children node)
        bindings (and (. children 2)
                      (= (. (. children 2) :kind) :sequence)
                      (meaningful-children (. children 2)))
        start    (loop-start-index bindings)]
    (and (or (not bindings)
             (leaf-valid-sequence? (. children 2) valid?))
         (accumulate [state true
                      index child (ipairs children)]
           (and state
                (or (< index start)
                    (quoted-child? children index)
                    (valid? child)))))))

(defn- layer-argument-valid? [node valid?]
  (let [head (list-head node)]
    (or (and (function-head? head) (function-argument-leaf-valid? node valid?))
        (and (loop-head? head) (loop-argument-leaf-valid? node valid?)))))

(defn- leaf-valid-call-state-update [state child valid?]
  {:valid  (and state.valid (valid? child))
   :layers state.layers})

(defn- leaf-valid-call-state-step [children state child index valid?]
  (if (and state.valid (>= index 2)
           (not (quoted-child? children index)))
      (leaf-valid-call-state-update state child valid?)
      state))

(defn- leaf-valid-call-state [children valid?]
  (accumulate [state {:valid true :layers 0}
               index child (ipairs children)]
    (leaf-valid-call-state-step children state child index valid?)))

(defn- leaf-valid-call? [children valid?]
  (let [result (leaf-valid-call-state children valid?)]
    (and result.valid (<= result.layers 1))))

(defn- leaf-valid-list? [children head valid?]
  (and (not (or (loop-head? head) (function-head? head)))
       (or (and (or (= head "var") (= head "set") (= head "local")
                    (= head "tset"))
                (leaf-valid-binding-list? children valid?))
           (and (not (or (= head "var") (= head "set") (= head "local")
                         (= head "tset")))
                (leaf-valid-call? children valid?)))))

(defn- leaf-node-kind [node]
  (or (and (or (not node) (= node.kind :prefix)
               (= node.kind :whitespace) (= node.kind :newline)
               (= node.kind :comment) (= node.kind :string)
               (= node.kind :symbol) (= node.kind :number)
               (= node.kind :boolean))
           "atomic")
      (and (= node.kind :sequence) "sequence")
      (and (= node.kind :table) "table")
      (and (= node.kind :list) "list")
      "other"))

(defn- leaf-valid-list-node? [node valid?]
  (let [children (meaningful-children node)
        head     (symbol-text (. children 1))]
    (case head
      "do" (and (= (length children) 2)
                (or (quoted-child? children 2)
                    (valid? (. children 2))))
      "if" false
      "when" false
      "case" false
      "match" false
      "let" false
      _ (leaf-valid-list? children head valid?))))

(defn leaf-valid? [node]
  (case (leaf-node-kind node)
    "atomic" true
    "sequence" (leaf-valid-sequence? node leaf-valid?)
    "table" (leaf-valid-sequence? node leaf-valid?)
    "list" (leaf-valid-list-node? node leaf-valid?)
    "other" true))

(defn- plain-call-layer-count [layer?]
  (if layer? 1 0))

(defn- plain-call-layer-state [state child]
  (let [child-head (list-head child)
        layer?     (or (loop-head? child-head)
                          (function-head? child-head))]
    {:valid  (or (and layer? (layer-argument-valid? child leaf-valid?))
                    (and (not layer?) (leaf-valid? child)))
     :layers (+ state.layers (plain-call-layer-count layer?))}))

(defn- plain-call-state-step [children state child index]
  (if (and state.valid (>= index 2)
           (not (quoted-child? children index)))
      (plain-call-layer-state state child)
      state))

(defn- plain-call-result [children]
  (accumulate [state {:valid true :layers 0}
               index child (ipairs children)]
    (plain-call-state-step children state child index)))

(defn plain-call-one-layer? [node]
  (let [children (meaningful-children node)
        result   (plain-call-result children)]
    (and result.valid (>= result.layers 1))))

(defn leaf-violations [node]
  (if (leaf-valid? node) [] [node]))

(defn expression-violations [node]
  (let [head (list-head node)]
    (or (and (= head "do") [node])
        (and (= head "let") [node])
        (and (= node.kind :list)
             (or (and (loop-head? head)
                      (not (or (= head "icollect") (= head "collect") (= head "accumulate"))))
                 (function-head? head))
             [node])
        (leaf-violations node))))
