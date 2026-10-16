(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.identity)

(local core (require :eca.nfnl.core))
(local reader (require :fennel-extras.reader))

(defn- trivia? [node]
  (and (not= node.kind :list)
       (not= node.kind :sequence)
       (not= node.kind :table)
       (or (= node.kind :whitespace)
           (= node.kind :newline)
           (= node.kind :comment)
           (= node.kind :tab)
           (= node.kind :cr))))

(defn- meaningful-child [child]
  (when (not (trivia? child)) child))

(defn- container? [node]
  (or (= node.kind :list)
      (= node.kind :sequence)
      (= node.kind :table)))

(defn- meaningful-children [node]
  (icollect [_ child (ipairs node.children)]
    (meaningful-child child)))

(defn- symbol-text [node]
  (if (and node (= node.kind :symbol))
      node.text))

(defn- head-name [node]
  (let [children (meaningful-children node)
        head (symbol-text (. children 1))
        name (symbol-text (. children 2))]
    (if (and head name)
        (values head name)
        (values head nil))))

(defn- named-declaration? [head]
  (or (= head "module")
      (= head "def")
      (= head "defn")
      (= head "defn-")
      (= head "deftest")
      (= head "fn")))

(defn- local-fn-value-children [value]
  (if (and value (= value.kind :list))
      (meaningful-children value)
      []))

(defn- local-fn? [node]
  (let [children (meaningful-children node)
        value (. children 3)
        value-children (local-fn-value-children value)]
    (= "fn" (symbol-text (. value-children 1)))))

(defn- local-named-segment [head name node]
  (if (and (= head "local") (local-fn? node))
      (.. "local:" name)))

(defn- declaration-segment [head name node]
  (if (named-declaration? head)
      (.. head ":" name)
      (local-named-segment head name node)))

(defn- named-segment [node]
  (let [(head name) (head-name node)]
    (if (and head name)
        (declaration-segment head name node))))

(defn- anonymous-list-kind [node]
  (let [children (meaningful-children node)]
    (or (symbol-text (. children 1)) "list")))

(defn- anonymous-container-kind [node]
  (case node.kind
    :sequence "sequence"
    :table "table"
    _ "form"))

(defn- anonymous-kind [node]
  (if (= node.kind :list)
      (anonymous-list-kind node)
      (anonymous-container-kind node)))

(defn- node-end [node]
  (values node.close.line (+ node.close.col 1)))

(defn- quoted-child? [children index]
  (let [previous (. children (- index 1))]
    (and previous (= previous.kind :prefix)
         (or (= previous.text "'")
             (= previous.text "`")))))

(defn- increment-meaningful [ordinal child]
  (if (not (trivia? child))
      (+ ordinal 1)
      ordinal))

(defn- advance-meaningful-index [ordinal child-index index child]
  (if (<= index child-index)
      (increment-meaningful ordinal child)
      ordinal))

(defn- index-result [child-index index ordinal result]
  (if (= index child-index)
      ordinal
      result))

(defn- meaningful-index-state [state child-index index child]
  (let [ordinal (advance-meaningful-index state.ordinal child-index index child)]
    {:ordinal ordinal
     :result (index-result child-index index ordinal state.result)}))

(defn- meaningful-index-result [children child-index]
  (accumulate [state {:ordinal 0 :result nil}
               index child (ipairs children)]
    (meaningful-index-state state child-index index child)))

(defn- meaningful-index [children child-index]
  (let [result (meaningful-index-result children child-index)]
    result.result))

(defn- numbered-then-kind [branch-index]
  (if (and (> branch-index 3)
           (= (% branch-index 2) 1))
      (.. "then#" (+ 1 (/ (- branch-index 3) 2)))))

(defn- branch-kind-after-then [branch-index child-count]
  (if (and (> child-count 3)
           (= branch-index child-count)
           (= (% branch-index 2) 0))
      "else"
      (numbered-then-kind branch-index)))

(defn- branch-kind-for-index [branch-index child-count]
  (if (= branch-index 3)
      "then"
      (branch-kind-after-then branch-index child-count)))

(defn- branch-kind [parent child-index]
  (branch-kind-for-index
   (meaningful-index parent.children child-index)
   (# (meaningful-children parent))))

(defn- list-head [node]
  (let [children (meaningful-children node)]
    (symbol-text (. children 1))))

(defn- function-parameter-index [named-fn?]
  (if named-fn? 3 2))

(defn- parameter-list? [parent child-index child]
  (let [head (list-head parent)
        children (meaningful-children parent)
        index (meaningful-index parent.children child-index)
        named-fn? (and (or (= head "fn")
                           (= head "lambda")
                           (= head "λ"))
                       (symbol-text (. children 2)))
        binding-form? (or (= head "let")
                          (= head "when-let")
                          (= head "if-let")
                          (= head "each")
                          (= head "for")
                          (= head "icollect")
                          (= head "collect")
                          (= head "accumulate")
                          (= head "with-open"))
        function-form? (or (= head "fn")
                           (= head "lambda")
                           (= head "λ"))
        declaration-form? (or (= head "defn")
                              (= head "defn-")
                              (= head "macro"))]
    (and (= child.kind :sequence)
         (or (and binding-form? (= index 2))
             (and declaration-form? (= index 3))
             (and function-form? (= index (function-parameter-index named-fn?)))))))

(defn- append-path [path segment]
  (if segment
      (.. path " > " segment)
      path))

(defn- identity-form [path node]
  (let [(end-line end-col) (node-end node)]
    {:form path
     :line node.open.line
     :col node.open.col
     :end-line end-line
     :end-col end-col
     :node node}))

(defn- top-level-path [state]
  (let [ordinal (+ state.top-ordinal 1)]
    (values (append-path state.ancestor (.. "top#" ordinal))
            (core.assoc state :top-ordinal ordinal))))

(defn- anonymous-path [node state]
  (let [kind (anonymous-kind node)
        ordinal (+ (or (. state.ordinals kind) 0) 1)]
    (values (append-path state.ancestor (.. kind "#" ordinal))
            (core.assoc state :ordinals (core.assoc state.ordinals kind ordinal)))))

(defn- node-path-without-segment [node state top-level?]
  (if top-level?
      (top-level-path state)
      (anonymous-path node state)))

(defn- node-path [node state top-level?]
  (let [segment (named-segment node)]
    (if segment
        (values (append-path state.ancestor segment) state)
        (node-path-without-segment node state top-level?))))

(defn- interesting-node? [node segment head top-level? skip-identity?]
  (and (not skip-identity?)
       (or top-level?
           segment
           (= head "if")
           (= head "testing")
           (= node.kind :sequence)
           (= node.kind :table))))

(defn- branch-node? [branch-segment node skip-identity?]
  (and (not skip-identity?)
       branch-segment
       (not= (list-head node) "is")))

(defn- state-for-branch [state branch-segment]
  (let [branch-path (append-path state.ancestor branch-segment)]
    {:state {:forms state.forms
             :ancestor branch-path
             :ordinals {}
             :top-ordinal 0}
     :path branch-path}))

(defn- child-state-ordinals [state segmented?]
  (if segmented? {} state.ordinals))

(defn- child-state [state final-path segmented?]
  {:forms state.forms
   :ancestor final-path
   :ordinals (child-state-ordinals state segmented?)
   :top-ordinal 0})

(defn- add-identity [state path node]
  (core.assoc state :forms (core.concat state.forms [(identity-form path node)])))

(defn- walk-local-fn-child [walker node fn-child next-state fn-index]
  (if (and (container? fn-child)
           (not (quoted-child? node.children fn-index)))
      (walker fn-child next-state false nil false
              (parameter-list? node fn-index fn-child))
      next-state))

(defn- walk-local-fn-children [walker node state]
  (accumulate [next-state state
               fn-index fn-child (ipairs node.children)]
    (walk-local-fn-child walker node fn-child next-state fn-index)))

(defn- regular-child-branch [node index]
  (if (= (list-head node) "if")
      (branch-kind node index)))

(defn- walk-regular-child [walker node child state index]
  (let [child-branch (regular-child-branch node index)]
    (walker child state false child-branch false
            (parameter-list? node index child))))

(defn- walk-child [walker node child state index local-fn]
  (if (and local-fn (= (list-head child) "fn"))
      (walk-local-fn-children walker child state)
      (walk-regular-child walker node child state index)))

(defn- walk-children [walker node state final-path segmented? head quoted?]
  (if (not quoted?)
      (let [next-state (child-state state final-path segmented?)
            local-fn (and (= head "local") (local-fn? node))]
        (accumulate [current next-state
                     index child (ipairs node.children)]
          (if (container? child)
              (walk-child walker node child current index local-fn)
              current)))
      state))

(defn- non-interesting-path [state branch-path skip-identity?]
  (if skip-identity?
      state.ancestor
      branch-path))

(defn- final-path-for-node [node state node-state branch-path top-level? node-interesting? skip-identity?]
  (if node-interesting?
      (node-path node node-state top-level?)
      (values (non-interesting-path state branch-path skip-identity?) node-state)))

(defn- branch-info [state branch-segment]
  (if branch-segment
      (state-for-branch state branch-segment)
      {:state state :path (append-path state.ancestor branch-segment)}))

(defn- add-branch-identity [branch? final-state branch-path node]
  (if branch?
      (add-identity final-state branch-path node)
      final-state))

(defn- add-node-identity [node-interesting? with-branch final-path node]
  (if node-interesting?
      (add-identity with-branch final-path node)
      with-branch))

(defn- walk-node-ordinals [node-interesting? final-state child-result]
  (if node-interesting? final-state.ordinals child-result.ordinals))

(defn- walk-node [node state top-level? branch-segment quoted? skip-identity?]
  (let [segment (named-segment node)
        head (list-head node)
        node-interesting? (interesting-node? node segment head top-level? skip-identity?)
        branch? (branch-node? branch-segment node skip-identity?)
        branch-info (branch-info state branch-segment)
        node-state (. branch-info :state)
        branch-path (. branch-info :path)
        (final-path final-state) (final-path-for-node node state node-state branch-path top-level?
                                                      node-interesting? skip-identity?)
        with-branch (add-branch-identity branch? final-state branch-path node)
        with-node (add-node-identity node-interesting? with-branch final-path node)
        child-result (walk-children walk-node node with-node final-path
                                    (or branch-segment node-interesting?) head quoted?)]
    {:forms child-result.forms
     :ancestor state.ancestor
     :ordinals (walk-node-ordinals node-interesting? final-state child-result)
     :top-ordinal final-state.top-ordinal}))

(defn- walk-root-child [root path state index child]
  (let [quoted? (quoted-child? root.children index)
        segment (named-segment child)
        next-state (walk-node child state true nil quoted? false)]
    (if (= (list-head child) "module")
        (core.assoc next-state :ancestor (append-path path segment))
        next-state)))

(defn- walk-root-container-child [root path current index child]
  (if (container? child)
      (walk-root-child root path current index child)
      current))

(defn- walk-root-state [root path state]
  (accumulate [current state
               index child (ipairs root.children)]
    (walk-root-container-child root path current index child)))

(defn- walk-root [root path]
  (let [state {:forms [] :ancestor path :ordinals {} :top-ordinal 0}
        final-state (walk-root-state root path state)]
    final-state.forms))

(defn forms [source path]
  (let [(root error) (reader.parse source)]
    (if root
        (walk-root root path)
        (values nil error))))
