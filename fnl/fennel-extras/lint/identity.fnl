(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.identity)

(local core (require :eca.nfnl.core))
(local reader (require :fennel-extras.reader))
(local naming (require :fennel-extras.lint.identity.naming))

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
       (not= (naming.list-head node) "is")))

(defn- state-for-branch [state branch-segment]
  (let [branch-path (naming.append-path state.ancestor branch-segment)]
    {:state {:forms       state.forms
             :ancestor    branch-path
             :ordinals    {}
             :top-ordinal 0}
     :path  branch-path}))

(defn- child-state-ordinals [state segmented?]
  (if segmented? {} state.ordinals))

(defn- child-state [state final-path segmented?]
  {:forms       state.forms
   :ancestor    final-path
   :ordinals    (child-state-ordinals state segmented?)
   :top-ordinal 0})

(defn- add-identity [state path node]
  (core.assoc state :forms (core.concat state.forms [(naming.identity-form path node)])))

(defn- walk-local-fn-child [walker node fn-child next-state fn-index]
  (if (and (naming.container? fn-child)
           (not (naming.quoted-child? node.children fn-index)))
      (walker fn-child next-state false nil false
              (naming.parameter-list? node fn-index fn-child))
      next-state))

(defn- walk-local-fn-children [walker node state]
  (accumulate [next-state state
               fn-index fn-child (ipairs node.children)]
    (walk-local-fn-child walker node fn-child next-state fn-index)))

(defn- regular-child-branch [node index]
  (if (= (naming.list-head node) "if")
      (naming.branch-kind node index)))

(defn- walk-regular-child [walker node child state index]
  (let [child-branch (regular-child-branch node index)]
    (walker child state false child-branch false
            (naming.parameter-list? node index child))))

(defn- walk-child [walker node child state index local-fn]
  (if (and local-fn (= (naming.list-head child) "fn"))
      (walk-local-fn-children walker child state)
      (walk-regular-child walker node child state index)))

(defn- walk-child-step [walker node local-fn current index child]
  (if (naming.container? child)
      (walk-child walker node child current index local-fn)
      current))

(defn- walk-children-step [walker node state final-path segmented? head]
  (let [next-state (child-state state final-path segmented?)
        local-fn   (and (= head "local") (naming.local-fn? node))]
    (accumulate [current next-state
                 index child (ipairs node.children)]
      (walk-child-step walker node local-fn current index child))))

(defn- walk-children [walker node state final-path segmented? head quoted?]
  (if (not quoted?)
      (walk-children-step walker node state final-path segmented? head)
      state))

(defn- non-interesting-path [state branch-path skip-identity?]
  (if skip-identity?
      state.ancestor
      branch-path))

(defn- final-path-for-node [node state node-state branch-path top-level? node-interesting? skip-identity?]
  (if node-interesting?
      (naming.node-path node node-state top-level?)
      (values (non-interesting-path state branch-path skip-identity?) node-state)))

(defn- branch-info [state branch-segment]
  (if branch-segment
      (state-for-branch state branch-segment)
      {:state state :path (naming.append-path state.ancestor branch-segment)}))

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
  (let [segment                  (naming.named-segment node)
        head                     (naming.list-head node)
        node-interesting?        (interesting-node? node segment head top-level? skip-identity?)
        branch?                  (branch-node? branch-segment node skip-identity?)
        branch-info              (branch-info state branch-segment)
        node-state               (. branch-info :state)
        branch-path              (. branch-info :path)
        (final-path final-state) (final-path-for-node node state node-state branch-path top-level?
                                                      node-interesting? skip-identity?)
        with-branch              (add-branch-identity branch? final-state branch-path node)
        with-node                (add-node-identity node-interesting? with-branch final-path node)
        child-result             (walk-children walk-node node with-node final-path
                                                   (or branch-segment node-interesting?) head quoted?)]
    {:forms       child-result.forms
     :ancestor    state.ancestor
     :ordinals    (walk-node-ordinals node-interesting? final-state child-result)
     :top-ordinal final-state.top-ordinal}))

(defn- walk-root-child [root path state index child]
  (let [quoted?    (naming.quoted-child? root.children index)
        segment    (naming.named-segment child)
        next-state (walk-node child state true nil quoted? false)]
    (if (= (naming.list-head child) "module")
        (core.assoc next-state :ancestor (naming.append-path path segment))
        next-state)))

(defn- walk-root-container-child [root path current index child]
  (if (naming.container? child)
      (walk-root-child root path current index child)
      current))

(defn- walk-root-state [root path state]
  (accumulate [current state
               index child (ipairs root.children)]
    (walk-root-container-child root path current index child)))

(defn- walk-root [root path]
  (let [state       {:forms [] :ancestor path :ordinals {} :top-ordinal 0}
        final-state (walk-root-state root path state)]
    final-state.forms))

(defn forms [source path]
  (let [(root error) (reader.parse source)]
    (if root
        (walk-root root path)
        (values nil error))))
