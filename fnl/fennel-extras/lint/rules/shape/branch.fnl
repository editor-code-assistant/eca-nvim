(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.shape.branch)

(local ast (require :fennel-extras.lint.rules.ast))
(local leaf (require :fennel-extras.lint.rules.shape.leaf))
(local meaningful-children ast.meaningful-children)
(local quoted-child? ast.quoted-child?)
(local append-nodes ast.append-nodes)
(local list-head ast.list-head)
(local expression-violations leaf.expression-violations)
(local leaf-valid? leaf.leaf-valid?)
(local leaf-violations leaf.leaf-violations)
(local layer-head? leaf.layer-head?)
(local function-info leaf.function-info)
(local plain-call-one-layer? leaf.plain-call-one-layer?)
(local loop-head? leaf.loop-head?)
(local marker? (fn [node text] (and node (= node.kind :symbol) (= node.text text))))
(local function-head? leaf.function-head?)

(defn- explicit-if? [children index]
  (if (> index (length children))
      false
      (or (marker? (. children index) "then")
          (marker? (. children index) "elseif")
          (marker? (. children index) "else")
          (explicit-if? children (+ index 1)))))

(defn- explicit-branch-result [children index result recurse]
  (if (. children (+ index 1))
      (recurse children (+ index 2)
               (append-nodes result (expression-violations (. children (+ index 1)))))
      (recurse children (+ index 1) result)))

(defn- validate-if-explicit-step [children index result recurse]
  (let [child (. children index)]
    (if (or (marker? child "then") (marker? child "elseif") (marker? child "else"))
        (explicit-branch-result children index result recurse)
        (recurse children (+ index 1)
                 (append-nodes result (expression-violations child))))))

(defn- validate-if-explicit [children index result]
  (if (> index (length children))
      result
      (validate-if-explicit-step children index result validate-if-explicit)))

(defn- implicit-branch-values [children index]
  (append-nodes
   (or (and (. children (+ index 1))
            (expression-violations (. children (+ index 1))))
       [])
   (expression-violations (. children index))))

(defn- append-implicit-branch [children index result]
  (append-nodes result (implicit-branch-values children index)))

(defn- validate-if-implicit [children index result]
  (if (> index (length children))
      result
      (or (and (= index (length children)) (= (% index 2) 0)
               (append-nodes result (expression-violations (. children index))))
          (validate-if-implicit children (+ index 2)
                                (append-implicit-branch children index result)))))

(defn- validate-if-children [children]
  (if (explicit-if? children 2)
      (validate-if-explicit children 2 [])
      (validate-if-implicit children 2 [])))

(defn- validate-if [node]
  (validate-if-children (meaningful-children node)))

(defn- validate-when-head [children result]
  (if (. children 2)
      (append-nodes result (expression-violations (. children 2)))
      result))

(defn- append-if-index [result index threshold value]
  (if (>= index threshold)
      (append-nodes result (expression-violations value))))

(defn- validate-when-body [children result]
  (each [index child (ipairs children)]
    (append-if-index result index 3 child))
  result)

(defn- validate-when [node]
  (let [children (meaningful-children node)]
    (validate-when-body children (validate-when-head children []))))

(defn- loop-bindings [children]
  (if (and (. children 2) (= (. (. children 2) :kind) :sequence))
      (meaningful-children (. children 2))
      []))

(defn- loop-start [bindings]
  (if (> (length bindings) 0) 3 2))

(defn- append-if-unquoted [bindings result index value]
  (if (not (quoted-child? bindings index))
      (append-nodes result (expression-violations value))))

(defn- validate-loop-bindings [bindings result]
  (each [index child (ipairs bindings)]
    (append-if-unquoted bindings result index child))
  result)

(defn- validate-loop-body [children start result]
  (each [index child (ipairs children)]
    (append-if-index result index start child))
  result)

(defn- validate-loop [node]
  (let [children (meaningful-children node)
        bindings (loop-bindings children)
        start    (loop-start bindings)]
    (validate-loop-body children start
                        (validate-loop-bindings bindings []))))

(defn- validate-case [node]
  (let [result []]
    (each [index child (ipairs (meaningful-children node))]
      (append-if-index result index 2 child))
    result))

(defn- function-layer-valid? [node]
  (let [info (function-info node)
        body (or (and info info.body) [])]
    (and info
         (accumulate [state true
                      _ child (ipairs body)]
           (and state (leaf-valid? child))))))

(defn- validate-function-layer [node]
  (if (function-layer-valid? node) [] [node]))

(defn- validate-layer-by-head [node head]
  (or (and (= head "if") (validate-if node))
      (and (= head "when") (validate-when node))
      (and (or (= head "case") (= head "match")) (validate-case node))
      (and (loop-head? head) (validate-loop node))
      (and (function-head? head) (validate-function-layer node))
      []))

(defn- validate-layer [node]
  (validate-layer-by-head node (list-head node)))

(defn- body-expression-result [node head]
  (or (and (= head "let") [node])
      (and (= head "do") [node])
      (and (layer-head? head) (validate-layer node))
      (and (= node.kind :list) (plain-call-one-layer? node) [])
      (expression-violations node)))

(defn- body-expression-violations [node]
  (body-expression-result node (list-head node)))

(defn- validate-let-binding-step [binding-children result index child]
  (if (and (= (% index 2) 0) (not (quoted-child? binding-children index)))
      (append-nodes result (leaf-violations child))
      result))

(defn- validate-let-bindings-children [binding-children result]
  (accumulate [state result
               index child (ipairs binding-children)]
    (validate-let-binding-step binding-children state index child)))

(defn- validate-let-bindings [bindings result]
  (if (and bindings (= bindings.kind :sequence))
      (validate-let-bindings-children (meaningful-children bindings) result)
      result))

(defn- validate-let-body [children result]
  (each [index child (ipairs children)]
    (and (>= index 3)
         (append-nodes result (body-expression-violations child))))
  result)

(defn- validate-let [node]
  (let [children (meaningful-children node)
        bindings (. children 2)]
    (validate-let-body children
                       (validate-let-bindings bindings []))))

(defn- function-first-let? [body]
  (and (. body 1) (= (list-head (. body 1)) "let")))

(defn- function-body-start-index [first-let?]
  (if first-let? 2 1))

(defn- function-body-initial [body result first-let?]
  (if first-let?
      (append-nodes result (validate-let (. body 1)))
      result))

(defn validate-function-body [body result]
  (let [first-let? (function-first-let? body)
        start      (function-body-start-index first-let?)
        initial    (function-body-initial body result first-let?)]
    (each [index child (ipairs body)]
      (and (>= index start)
           (append-nodes initial (body-expression-violations child))))
    initial))
