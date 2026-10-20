(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.identity.naming)

(local core (require :eca.nfnl.core))

(defn- trivia?
  [node]
  (and (not= node.kind :list)
       (not= node.kind :sequence)
       (not= node.kind :table)
       (or (= node.kind :whitespace)
           (= node.kind :newline)
           (= node.kind :comment)
           (= node.kind :tab)
           (= node.kind :cr))))

(defn- meaningful-child
  [child]
  (when (not (trivia? child))
    child))

(defn container?
  [node]
  (or (= node.kind :list)
      (= node.kind :sequence)
      (= node.kind :table)))

(defn- meaningful-children
  [node]
  (icollect [_ child (ipairs node.children)]
    (meaningful-child child)))

(defn- symbol-text
  [node]
  (when (and node (= node.kind :symbol))
    node.text))

(defn- head-name
  [node]
  (let [children (meaningful-children node) head     (symbol-text (. children 1)) name     (symbol-text (. children 2))]
    (if (and head name)
      (values head name)
      (values head nil))))

(defn- named-declaration?
  [head]
  (or (= head "module")
      (= head "def")
      (= head "defn")
      (= head "defn-")
      (= head "deftest")
      (= head "fn")))

(defn- local-fn-value-children
  [value]
  (if (and value (= value.kind :list))
    (meaningful-children value)
    []))

(defn local-fn?
  [node]
  (let [children       (meaningful-children node) value          (. children 3) value-children (local-fn-value-children value)]
    (= "fn" (symbol-text (. value-children 1)))))

(defn- local-named-segment
  [head name node]
  (when (and (= head "local") (local-fn? node))
    (.. "local:" name)))

(defn- declaration-segment
  [head name node]
  (if (named-declaration? head)
    (.. head ":" name)
    (local-named-segment head name node)))

(defn named-segment
  [node]
  (let [(head name) (head-name node)]
    (when (and head name)
      (declaration-segment head name node))))

(defn- anonymous-list-kind
  [node]
  (let [children (meaningful-children node)]
    (or (symbol-text (. children 1))
        "list")))

(defn- anonymous-container-kind
  [node]
  (case node.kind
    :sequence "sequence"
    :table    "table"
    _         "form"))

(defn- anonymous-kind
  [node]
  (if (= node.kind :list)
    (anonymous-list-kind node)
    (anonymous-container-kind node)))

(defn- node-end
  [node]
  (values node.close.line (+ node.close.col 1)))

(defn quoted-child?
  [children index]
  (let [previous (. children (- index 1))]
    (and previous
         (= previous.kind :prefix)
         (or (= previous.text "'")
             (= previous.text "`")))))

(defn- increment-meaningful
  [ordinal child]
  (if (not (trivia? child))
    (+ ordinal 1)
    ordinal))

(defn- advance-meaningful-index
  [ordinal child-index index child]
  (if (<= index child-index)
    (increment-meaningful ordinal child)
    ordinal))

(defn- index-result
  [child-index index ordinal result]
  (if (= index child-index)
    ordinal
    result))

(defn- meaningful-index-state
  [state child-index index child]
  (let [ordinal (advance-meaningful-index state.ordinal child-index index child)]
    {:ordinal ordinal :result  (index-result child-index index ordinal state.result)}))

(defn- meaningful-index-result
  [children child-index]
  (accumulate [state {:ordinal 0 :result nil} index child (ipairs children)]
    (meaningful-index-state state child-index index child)))

(defn- meaningful-index
  [children child-index]
  (let [result (meaningful-index-result children child-index)]
    result.result))

(defn- numbered-then-kind
  [branch-index]
  (when (and (> branch-index 3)
             (= (% branch-index 2) 1))
    (.. "then#" (+ 1 (/ (- branch-index 3) 2)))))

(defn- branch-kind-after-then
  [branch-index child-count]
  (if (and (> child-count 3)
           (= branch-index child-count)
           (= (% branch-index 2) 0))
    "else"
    (numbered-then-kind branch-index)))

(defn- branch-kind-for-index
  [branch-index child-count]
  (if (= branch-index 3)
    "then"
    (branch-kind-after-then branch-index child-count)))

(defn branch-kind
  [parent child-index]
  (branch-kind-for-index (meaningful-index parent.children child-index) (# (meaningful-children parent))))

(defn list-head
  [node]
  (let [children (meaningful-children node)]
    (symbol-text (. children 1))))

(defn- function-parameter-index
  [named-fn?]
  (if named-fn?
    3
    2))

(defn parameter-list?
  [parent child-index child]
  (let [head              (list-head parent)
        children          (meaningful-children parent)
        index             (meaningful-index parent.children child-index)
        named-fn?         (and (or (= head "fn")
                                   (= head "lambda")
                                   (= head "λ"))
                               (symbol-text (. children 2)))
        binding-form?     (or (= head "let")
                              (= head "when-let")
                              (= head "if-let")
                              (= head "each")
                              (= head "for")
                              (= head "icollect")
                              (= head "collect")
                              (= head "accumulate")
                              (= head "with-open"))
        function-form?    (or (= head "fn")
                              (= head "lambda")
                              (= head "λ"))
        declaration-form? (or (= head "defn")
                              (= head "defn-")
                              (= head "macro"))]
    (and (= child.kind :sequence)
         (or (and binding-form? (= index 2))
             (and declaration-form? (= index 3))
             (and function-form? (= index (function-parameter-index named-fn?)))))))

(defn append-path
  [path segment]
  (if segment
    (.. path " > " segment)
    path))

(defn identity-form
  [path node]
  (let [(end-line end-col) (node-end node)]
    {:form     path :line     node.open.line :col      node.open.col :end-line end-line :end-col  end-col :node     node}))

(defn- top-level-path
  [state]
  (let [ordinal (+ state.top-ordinal 1)]
    (values (append-path state.ancestor (.. "top#" ordinal)) (core.assoc state :top-ordinal ordinal))))

(defn- anonymous-path
  [node state]
  (let [kind    (anonymous-kind node) ordinal (+ (or (. state.ordinals kind) 0) 1)]
    (values (append-path state.ancestor (.. kind "#" ordinal)) (core.assoc state :ordinals (core.assoc state.ordinals kind ordinal)))))

(defn- node-path-without-segment
  [node state top-level?]
  (if top-level?
    (top-level-path state)
    (anonymous-path node state)))

(defn node-path
  [node state top-level?]
  (let [segment (named-segment node)]
    (if segment
      (values (append-path state.ancestor segment) state)
      (node-path-without-segment node state top-level?))))
