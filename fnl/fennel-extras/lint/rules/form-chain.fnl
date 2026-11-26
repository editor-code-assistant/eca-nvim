(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.form-chain)

(local core (require :eca.nfnl.core))
(local ast (require :fennel-extras.lint.rules.ast))
(local reader (require :fennel-extras.reader))
(local registry (require :fennel-extras.lint.rules.registry))

(defn- container?
  [node]
  (and node
       (or (= node.kind :list)
           (= node.kind :sequence)
           (= node.kind :table))))

(defn- prefix-mode
  [prefix mode]
  (if (= prefix "'")
    :quoted
    (if (= mode :quoted)
      :quoted
      (if (= prefix "`")
        (+ mode 1)
        (if (= prefix ",")
          (math.max 0 (- mode 1))
          mode)))))

(defn- child-mode
  [node index mode]
  (let [meaningful       (ast.meaningful-children node)
        first-meaningful (. meaningful 1)
        child            (. node.children index)
        previous-index   (ast.previous-meaningful-index node.children index)
        previous         (and previous-index (. node.children previous-index))]
    (if (and (= (ast.list-head node) "quote")
             (not= child first-meaningful))
      :quoted
      (if (and previous (= previous.kind :prefix))
        (prefix-mode previous.text (child-mode node previous-index mode))
        mode))))

(defn- meaningful-index
  [children target index]
  (and (<= index (length children))
       (or (and (= (. children index) target) index)
           (meaningful-index children target (+ index 1)))))

(local body-starts
  {"def" 3 "def-" 3
   "defn" 4 "defn-" 4
   "fn" 3 "lambda" 3 "λ" 3 "deftest" 3
   "when" 3 "when-let" 3 "if-let" 3 "with-open" 3 "testing" 3})

(defn- executable-children
  [node mode]
  (let [result []]
    (each [index child (ipairs (or node.children []))]
      (let [child-mode (child-mode node index mode)]
        (when (and (container? child) (not= child-mode :quoted))
          (table.insert result {:node child :index index}))))
    result))

(defn- first-body-child-step
  [node mode raw-index]
  (when (<= raw-index (length (or node.children [])))
    (let [child      (. node.children raw-index)
          child-mode (child-mode node raw-index mode)]
      (or (and (container? child) (not= child-mode :quoted) child)
          (first-body-child-step node mode (+ raw-index 1))))))

(defn- first-body-child
  [node mode]
  (let [head  (ast.list-head node)
        start (. body-starts head)]
    (when start
      (let [meaningful (ast.meaningful-children node)
            candidate  (. meaningful start)
            raw-index  (and candidate (meaningful-index node.children candidate 1))]
        (and raw-index (first-body-child-step node mode raw-index))))))

(defn- first-executable-head
  [node mode]
  (let [children (executable-children node mode)
        child    (. children 1)]
    (and child (ast.list-head child.node))))

(defn- contains?
  [items target index]
  (and (<= index (length (or items [])))
       (or (= (. items index) target)
           (contains? items target (+ index 1)))))

(defn- root-marker?
  [value]
  (or (= value :root)
      (= value "root")))

(defn- form-marker?
  [value]
  (or (= value :form)
      (= value "form")))

(defn- between-marker?
  [value]
  (or (= value :forms-between)
      (= value "forms-between")))

(defn- root-chain?
  [pattern]
  (and (> (length pattern) 0)
       (root-marker? (. pattern 1))))

(defn- pattern-match-step
  [subject pattern subject-index pattern-index]
  (if (> pattern-index (length pattern))
    (> subject-index (length subject))
    (let [expected (. pattern pattern-index)
          actual   (. subject subject-index)]
      (or (and (root-marker? expected)
               (= pattern-index 1)
               (= subject-index 1)
               (= actual :form)
               (pattern-match-step subject pattern subject-index (+ pattern-index 1)))
          (and (form-marker? expected)
               (= actual :form)
               (pattern-match-step subject pattern (+ subject-index 1) (+ pattern-index 1)))
          (and (between-marker? expected)
               actual
               (not= actual :form)
               (or (pattern-match-step subject pattern (+ subject-index 1) (+ pattern-index 1))
                   (pattern-match-step subject pattern (+ subject-index 1) pattern-index)))
          (and (= expected actual)
               (pattern-match-step subject pattern (+ subject-index 1) (+ pattern-index 1)))))))

(defn- unrooted-pattern-match?
  [subject pattern start]
  (and (<= start (length subject))
       (or (pattern-match-step subject pattern start 1)
           (unrooted-pattern-match? subject pattern (+ start 1)))))

(defn- pattern-match?
  [subject pattern]
  (if (root-chain? pattern)
    (pattern-match-step subject pattern 1 1)
    (unrooted-pattern-match? subject pattern 1)))

(defn- chain-matches?
  [chain pattern]
  (and (not (contains? chain :not-first 1))
       (pattern-match? (core.concat chain [:form]) pattern)))

(defn- subject-chain-matches?
  [subject pattern]
  (and (not (contains? subject :not-first 1))
       (pattern-match? subject pattern)))

(defn- any-chain?
  [chain chains]
  (accumulate [found false _ pattern (ipairs (or chains []))]
    (or found (chain-matches? chain pattern))))

(defn- any-subject-chain?
  [subject chains]
  (accumulate [found false _ pattern (ipairs (or chains []))]
    (or found (subject-chain-matches? subject pattern))))

(defn- forbidden-chain?
  [chain pattern]
  (chain-matches? chain pattern))

(defn- any-forbidden-chain?
  [chain chains]
  (accumulate [found false _ pattern (ipairs (or chains []))]
    (or found (forbidden-chain? chain pattern))))

(defn- node-form
  [forms node index]
  (when (<= index (length forms))
    (let [form (. forms index)]
      (or (and form.node
               (= form.node.kind node.kind)
               (= form.node.open.line node.open.line)
               (= form.node.open.col node.open.col)
               form)
          (node-form forms node (+ index 1))))))

(defn- append-finding
  [result path forms node policy rule]
  (let [existing (node-form forms node 1)
        form     (or existing
                     {:line     node.open.line
                      :col      node.open.col
                      :end-line node.close.line
                      :end-col  (+ node.close.col 1)
                      :form     (.. path " > " (or (ast.list-head node) "form"))
                      :node     node})]
    (table.insert result
      (registry.finding path form (registry.rule-severity policy rule)
        rule (.. (or (and (= node.kind :list)
                          (ast.list-head node))
                     "form")
               " is outside the allowed form chain")
        node))
    result))

(defn- walk-first-body
  [node mode chain path forms policy rule result]
  (let [head         (ast.list-head node)
        next-chain   (if head (core.concat chain [head]) chain)
        target?      (= head (or policy.options.target))
        nested-chain (let [child-head (first-executable-head node mode)]
                       (and target?
                            child-head
                            (core.concat chain [:form child-head])))
        allowed?     (or (= policy.options.allowed-chains nil)
                         (any-chain? chain policy.options.allowed-chains)
                         (and nested-chain
                              (any-subject-chain? nested-chain policy.options.allowed-chains)))
        forbidden?   (or (any-forbidden-chain? chain policy.options.forbidden-chains)
                         (and nested-chain
                              (any-subject-chain? nested-chain policy.options.forbidden-chains)))]
    (when (and target? (or (not allowed?) forbidden?))
      (append-finding result path forms node policy rule))
    (each [_ child (ipairs (executable-children node mode))]
      (let [first-child (first-body-child node mode)
            child-chain (if (or (and (or (= node.kind :sequence)
                                         (= node.kind :table))
                                     (not first-child))
                                (and first-child
                                     (not= child.node first-child)))
                          [:not-first]
                          next-chain)]
        (walk-first-body child.node
          (child-mode node child.index mode)
          child-chain
          path
          forms
          policy
          rule
          result)))
    result))

(defn findings
  [path forms policy source rule]
  (let [(root error) (reader.parse source)
        result       []]
    (when (and root (not error))
      (each [_ target (ipairs (or policy.options.forms []))]
        (let [target-policy (core.assoc policy
                              :options
                              (core.assoc (core.assoc policy.options :target target)
                                :root-count
                                (length (ast.root-forms source))))]
          (each [index child (ipairs (or root.children []))]
            (let [mode (child-mode root index 0)]
              (when (and (container? child) (not= mode :quoted))
                (walk-first-body child mode [] path forms target-policy rule result)))))))
    result))
