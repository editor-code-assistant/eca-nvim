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
  (let [previous-index (ast.previous-meaningful-index node.children index)
        previous       (and previous-index (. node.children previous-index))]
    (if (and previous (= previous.kind :prefix))
      (prefix-mode previous.text (child-mode node previous-index mode))
      mode)))

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

(defn- contains?
  [items target index]
  (and (<= index (length (or items [])))
       (or (= (. items index) target)
           (contains? items target (+ index 1)))))

(defn- root-chain?
  [pattern]
  (contains? pattern "<root>" 1))

(defn- match-step
  [subject pattern between subject-index pattern-index matched-step?]
  (if (> pattern-index (length pattern))
    (> subject-index (length subject))
    (let [expected (. pattern pattern-index)
          actual   (. subject subject-index)]
      (or (and (= expected "<root>")
               (= subject-index 1)
               (match-step subject pattern between (+ subject-index 1) (+ pattern-index 1) true))
          (and (= expected "<form>")
               (= subject-index (length subject))
               (= actual "<form>")
               (match-step subject pattern between (+ subject-index 1) (+ pattern-index 1) true))
          (and (= expected actual)
               (match-step subject pattern between (+ subject-index 1) (+ pattern-index 1) true))
          (and matched-step?
               actual
               (contains? between actual 1)
               (match-step subject pattern between (+ subject-index 1) pattern-index true))))))

(defn- chain-matches?
  [chain pattern forms-between root-count]
  (if (root-chain? pattern)
    (or (and (= (length pattern) 2)
             (= (. pattern 1) "<root>")
             (= (. pattern 2) "<form>")
             (or (= (length chain) 1)
                 (and (= (length chain) 0)
                      (> (or root-count 0) 1))))
        (match-step (core.concat chain ["<form>"]) pattern (or forms-between []) 1 1 false))
    (match-step (core.concat chain ["<form>"]) pattern (or forms-between []) 1 1 false)))

(defn- any-chain?
  [chain chains forms-between root-count]
  (accumulate [found false _ pattern (ipairs (or chains []))]
              (or found (chain-matches? chain pattern forms-between root-count))))

(defn- forbidden-root-target?
  [chain target pattern root-count]
  (and (= root-count 1)
       (= (length chain) 1)
       (= (. pattern 1) "<root>")
       (= (. pattern 2) target)
       (= (. pattern 3) "<form>")))

(defn- forbidden-chain?
  [chain target pattern forms-between root-count]
  (or (chain-matches? chain pattern forms-between root-count)
      (forbidden-root-target? chain target pattern root-count)))

(defn- any-forbidden-chain?
  [chain target chains forms-between root-count]
  (accumulate [found false _ pattern (ipairs (or chains []))]
              (or found (forbidden-chain? chain target pattern forms-between root-count))))

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
                                    rule "form is outside the allowed form chain" node))
    result))

(defn- walk-first-body
  [node mode chain path forms policy rule result]
  (let [head       (ast.list-head node)
        next-chain (core.concat chain [head])
        target?    (= head (or policy.options.target))
        allowed?   (any-chain? chain policy.options.allowed-chains policy.options.forms-between policy.options.root-count)
        forbidden? (any-forbidden-chain? chain head policy.options.forbidden-chains policy.options.forms-between policy.options.root-count)]
    (when (and target? (or (not allowed?) forbidden?))
          (append-finding result path forms node policy rule))
    (each [_ child (ipairs (executable-children node mode))]
          (let [child-node  child.node
                first-child (first-body-child node mode)
                child-chain (if (= child-node first-child)
                              next-chain
                              [])]
            (walk-first-body child-node (child-mode node child.index mode) child-chain path forms policy rule result)))
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
