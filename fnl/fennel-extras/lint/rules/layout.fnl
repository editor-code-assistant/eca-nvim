(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.layout)

(local core (require :eca.nfnl.core))
(local ast (require :fennel-extras.lint.rules.ast))
(local mutation (require :fennel-extras.lint.rules.mutation))
(local registry (require :fennel-extras.lint.rules.registry))
(local meaningful-children ast.meaningful-children)
(local list-head ast.list-head)
(local form-for-node ast.form-for-node)
(local nearest-form ast.nearest-form)
(local finding registry.finding)
(local enabled? registry.enabled?)
(local rule-severity registry.rule-severity)

(local clause-heads {:case true :match true :case-try true :match-try true})
(local binding-heads {:let true :when-let true :if-let true :with-open true})

(defn- child-line
  [child]
  (or (and child child.open child.open.line)
      (and child child.line)
      0))

(defn- child-end-line
  [child]
  (or (and child child.close child.close.line)
      (and child child.line)
      0))

(defn- unit
  [children first-index last-index]
  {:start (child-line (. children first-index)) :end   (child-end-line (. children last-index))})

(defn- pair-index?
  [index start-index]
  (and (>= index start-index)
       (= (math.fmod (- index start-index) 2) 0)))

(defn- append-pair-unit
  [result children start-index index]
  (if (pair-index? index start-index)
    (core.concat result [(unit children index (math.min (+ index 1) (length children)))])
    result))

(defn- pair-units
  [children start-index]
  (accumulate [result [] index _ (ipairs children)]
    (append-pair-unit result children start-index index)))

(defn- ordinary-units
  [children]
  (icollect [index _ (ipairs children)]
    (unit children index index)))

(defn- units-for-list
  [node children]
  (let [head (list-head node)]
    (or (and (= head "if")
             (>= (length children) 5)
             (pair-units children 2))
        (and (. clause-heads head) (pair-units children 3))
        (ordinary-units children))))

(defn- units-for-node
  [node]
  (let [children (meaningful-children node)]
    (or (and (= node.kind :table) (pair-units children 1))
        (and (= node.kind :list) (units-for-list node children))
        (ordinary-units children))))

(defn- offending-adjacency?
  [node index previous current]
  (let [opening-line     node.open.line opening-list?    (and (= node.kind :list) (= index 2)) allowed-opening? (and opening-list? (= current.start opening-line))]
    (and (not allowed-opening?)
         (<= current.start previous.end))))

(defn- offending-units-step
  [node units index previous]
  (let [current (. units index)]
    (if (> index (length units))
      false
      (or (and previous (offending-adjacency? node index previous current))
          (offending-units-step node units (+ index 1) current)))))

(defn- offending-units?
  [node]
  (let [units (units-for-node node)]
    (and (> node.close.line node.open.line)
         (offending-units-step node units 2 (. units 1)))))

(defn- binding-layout?
  [node]
  (let [children (meaningful-children node)]
    (and (. binding-heads (list-head node))
         (accumulate [result false _ child (ipairs children)]
           (or result
               (and (= child.kind :sequence)
                    (offending-units? (core.assoc child :kind :table))))))))

(defn- layout-container?
  [node]
  (or (= node.kind :list)
      (= node.kind :sequence)
      (= node.kind :table)))

(defn- layout-excluded?
  [node head]
  (or (and (= node.kind :list)
           (or (= head "defn") (= head "defn-")))
      (and (= node.kind :sequence)
           (= (math.fmod (length (meaningful-children node)) 2) 0))))

(defn- delayed-list-argument?
  [node head]
  (let [children (meaningful-children node) argument (. children 2)]
    (and (= node.kind :list)
         (not= head "do")
         argument
         (> node.close.line node.open.line)
         (not= (child-line argument) node.open.line))))

(defn- layout-body-result
  [node head]
  (if (and (= node.kind :list) (. binding-heads head))
    (binding-layout? node)
    (offending-units? node)))

(defn- layout-result
  [node head]
  (or (delayed-list-argument? node head)
      (layout-body-result node head)))

(defn- layout-node?
  [node]
  (let [head (list-head node)]
    (and (layout-container? node)
         (not (layout-excluded? node head))
         (layout-result node head))))

(defn- finding-form
  [path forms node ordinals]
  (let [existing (form-for-node forms node nil) base     (or existing (nearest-form forms node) {:form path}) ordinal  (+ (or (. ordinals base.form) 0) 1)]
    (values (or existing
                {:line     node.open.line :col      node.open.col :end-line node.close.line :end-col  (+ node.close.col 1) :form     (.. base.form " > multiline-layout#" ordinal) :node     node})
            (core.assoc ordinals base.form ordinal))))

(defn- insert-finding
  [findings path forms policy node ordinals key]
  (let [(form next-ordinals) (finding-form path forms node ordinals)]
    (table.insert findings
                  (finding path form (rule-severity policy "multiline-layout") "multiline-layout" "multi-line form: put each item on its own line" node))
    (core.assoc next-ordinals key true)))

(defn- append-finding
  [findings path forms policy node ordinals]
  (let [base (or (form-for-node forms node nil) (nearest-form forms node) {:form path}) key  (.. base.form ":" node.open.line)]
    (if (. ordinals key)
      ordinals
      (insert-finding findings path forms policy node ordinals key))))

(defn- append-layout-findings
  [findings path forms policy source]
  (accumulate [ordinals {} _ node (ipairs (mutation.executable-nodes source layout-node?))]
    (append-finding findings path forms policy node ordinals)))

(defn findings
  [findings path forms policy source]
  (when (enabled? policy "multiline-layout")
    (append-layout-findings findings path forms policy source))
  findings)
