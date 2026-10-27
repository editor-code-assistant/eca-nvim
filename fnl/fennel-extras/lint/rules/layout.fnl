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

(defn- contains?
  [items target index]
  (if (> index (length items))
    false
    (or (= (. items index) target)
        (contains? items target (+ index 1)))))

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
  {:start (child-line (. children first-index)) :end (child-end-line (. children last-index))})

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

(defn- clause-units
  [head children]
  (if (or (= head "case") (= head "match") (= head "case-try") (= head "match-try"))
    (pair-units children 3)
    (ordinary-units children)))

(defn- units-for-list
  [node children policy]
  (let [head         (list-head node)
        clause-forms (. (registry.rule-options policy "multiline-layout") :clauses)]
    (or (and (= head "if")
             (>= (length children) 5)
             (pair-units children 2))
        (and (contains? clause-forms head 1)
             (clause-units head children))
        (ordinary-units children))))

(defn- units-for-node
  [node policy]
  (let [children (meaningful-children node)]
    (or (and (= node.kind :table) (pair-units children 1))
        (and (= node.kind :list) (units-for-list node children policy))
        (ordinary-units children))))

(defn- offending-adjacency?
  [node index previous current]
  (let [opening-line     node.open.line
        opening-list?    (and (= node.kind :list) (= index 2))
        allowed-opening? (and opening-list? (= current.start opening-line))]
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
  [node policy]
  (let [units (units-for-node node policy)]
    (and (> node.close.line node.open.line)
         (offending-units-step node units 2 (. units 1)))))

(defn- binding-layout?
  [node policy]
  (let [children      (meaningful-children node)
        binding-forms (. (registry.rule-options policy "multiline-layout") :bindings)]
    (and (contains? binding-forms (list-head node) 1)
         (accumulate [result false _ child (ipairs children)]
           (or result
               (and (= child.kind :sequence)
                    (offending-units? (core.assoc child :kind :table) policy)))))))

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

(defn- escaped-newline-child?
  [child]
  (and (= child.kind :symbol)
       (string.find child.text "\\n" 1 true)))

(defn- escaped-newline?
  [node]
  (accumulate [result false _ child (ipairs (or node.children []))]
    (or result (escaped-newline-child? child))))

(defn- delayed-list-argument?
  [node head]
  (let [children (meaningful-children node)
        argument (. children 2)]
    (and (= node.kind :list)
         (not= head "do")
         argument
         (> node.close.line node.open.line)
         (not= (child-line argument) node.open.line))))

(defn- layout-body-result
  [node head policy]
  (let [binding-forms (. (registry.rule-options policy "multiline-layout") :bindings)]
    (if (and (= node.kind :list) (contains? binding-forms head 1))
      (binding-layout? node policy)
      (offending-units? node policy))))

(defn- escaped-layout?
  [node head policy]
  (let [options (. (registry.rule-options policy "multiline-layout"))]
    (and (escaped-newline? node)
         (or (contains? options.clauses head 1)
             (contains? options.bindings head 1)))))

(defn- layout-result
  [node head policy]
  (or (escaped-layout? node head policy)
      (delayed-list-argument? node head)
      (layout-body-result node head policy)))

(defn- layout-node?
  [node policy]
  (let [head (list-head node)]
    (and (layout-container? node)
         (not (layout-excluded? node head))
         (layout-result node head policy))))

(defn- finding-form
  [path forms node ordinals]
  (let [existing (form-for-node forms node nil)
        base     (or existing (nearest-form forms node) {:form path})
        ordinal  (+ (or (. ordinals base.form) 0) 1)]
    (values (or existing
                {:line node.open.line :col node.open.col :end-line node.close.line :end-col (+ node.close.col 1) :form (.. base.form " > multiline-layout#" ordinal) :node node})
            (core.assoc ordinals base.form ordinal))))

(defn- insert-finding
  [findings path forms policy node ordinals key]
  (let [(form next-ordinals) (finding-form path forms node ordinals)]
    (table.insert findings
                  (finding path form (rule-severity policy "multiline-layout") "multiline-layout" "multi-line form: put each item on its own line" node))
    (core.assoc next-ordinals key true)))

(defn- append-finding
  [findings path forms policy node ordinals]
  (let [base (or (form-for-node forms node nil) (nearest-form forms node) {:form path})
        key  (.. base.form ":" node.open.line)]
    (if (. ordinals key)
      ordinals
      (insert-finding findings path forms policy node ordinals key))))

(defn- layout-nodes
  [source policy]
  (mutation.executable-nodes source (fn [node] (layout-node? node policy))))

(defn- append-layout-findings
  [findings path forms policy source]
  (accumulate [ordinals {} _ node (ipairs (layout-nodes source policy))]
    (append-finding findings path forms policy node ordinals)))

(defn findings
  [findings path forms policy source]
  (when (enabled? policy "multiline-layout")
    (append-layout-findings findings path forms policy source))
  findings)
