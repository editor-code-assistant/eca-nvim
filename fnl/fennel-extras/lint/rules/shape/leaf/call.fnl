(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.shape.leaf.call)


(local ast (require :fennel-extras.lint.rules.ast))
(local valid (require :fennel-extras.lint.rules.shape.leaf.valid))
(local meaningful-children ast.meaningful-children)
(local list-head ast.list-head)
(local quoted-child? ast.quoted-child?)
(local loop-head? valid.loop-head?)
(local function-head? valid.function-head?)
(local layer-argument-valid? valid.layer-argument-valid?)
(local leaf-valid? valid.leaf-valid?)
(defn- plain-call-layer-count
  [layer?]
  (if
    layer?
    1
    0))

(defn- plain-call-layer-state
  [state child]
  (let [child-head (list-head child)
        layer?     (or (loop-head? child-head)
                       (function-head? child-head))]
    {:valid  (or (and layer? (layer-argument-valid? child leaf-valid?))
                 (and (not layer?) (leaf-valid? child)))
     :layers (+ state.layers (plain-call-layer-count layer?))}))

(defn- plain-call-state-step
  [children state child index]
  (if
    (and state.valid
         (>= index 2)
         (not (quoted-child? children index)))
    (plain-call-layer-state state child)
    state))

(defn- plain-call-result
  [children]
  (accumulate [state {:valid true :layers 0} index child (ipairs children)]
    (plain-call-state-step children state child index)))

(defn plain-call-one-layer?
  [node]
  (let [children (meaningful-children node) result   (plain-call-result children)]
    (and
     result.valid
     (>= result.layers 1))))

(defn leaf-violations
  [node]
  (if
    (leaf-valid? node)
    []
    [node]))

(defn expression-violations
  [node]
  (let [head (list-head node)]
    (or (and (= head "do") [node])
        (and (= head "let") [node])
        (and (= node.kind :list)
             (or (and (loop-head? head)
                      (not (or (= head "icollect") (= head "collect") (= head "accumulate"))))
                 (function-head? head))
             [node])
        (leaf-violations node))))
