(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.spec)

(local ast (require :fennel-extras.lint.rules.ast))
(local registry (require :fennel-extras.lint.rules.registry))
(local meaningful-children ast.meaningful-children)
(local list-head ast.list-head)
(local rule-options registry.rule-options)
(local enabled? registry.enabled?)
(local rule-severity registry.rule-severity)
(local finding registry.finding)
(local count-is ast.count-is)

(defn- count-child-forms
  [node children index result]
  (if (> index (length children))
    result
    (count-child-forms node children (+ index 1)
      (+ result (count-is node 1 0 (list-head node) (. children index))))))

(defn form-child-count-finding
  [findings path form policy node]
  (let [options (rule-options policy "form-child-count")
        count   (count-child-forms node options.children 1 0)]
    (when (and (enabled? policy "form-child-count")
               (not= count options.max-count))
      (table.insert findings
        (finding path form (rule-severity policy "form-child-count") "form-child-count" "each testing form must contain exactly one is" node)))))

(defn- nil-literal?
  [node]
  (and node (= node.kind :symbol) (= node.text "nil")))

(defn- contains?
  [items target index]
  (and (<= index (length items))
       (or (= (. items index) target)
           (contains? items target (+ index 1)))))

(defn- not-counted-literal?
  [node options]
  (and node
       (= node.kind :symbol)
       (contains? (or options.not-counted []) node.text 1)))

(defn- direct-count-step
  [children options index result]
  (if (> index (length children))
    result
    (direct-count-step children options (+ index 1)
      (if (not (not-counted-literal? (. children index) options))
        (+ result 1)
        result))))

(defn- direct-count
  [node options]
  (let [children (meaningful-children node)
        start    (if (= (list-head node) "if") 3 2)]
    (direct-count-step children options start 0)))

(defn- direct-child-valid?
  [node options]
  (let [children     (meaningful-children node)
        head         (list-head node)
        missing      (and (= head "if") (= (length children) 3))
        multi-clause (and (= head "if") (> (length children) 4))
        nil-else     (and (= head "if")
                          (= (length children) 4)
                          (nil-literal? (. children 4)))
        count        (direct-count node options)
        min          (or options.min-count 0)
        max          (or options.max-count count)]
    (and (not missing)
         (not multi-clause)
         (or (not nil-else)
             options.nil-count
             (contains? (or options.not-counted []) "nil" 1)
             (and (= options.nil-count nil)
                  (= options.not-counted nil)))
         (>= count min)
         (<= count max))))

(defn- named-child-count-direct
  [node options index result]
  (let [children (meaningful-children node)]
    (if (> index (length children))
      result
      (named-child-count-direct node options (+ index 1)
        (+ result
          (if (and (= (. (. children index) :kind) :list)
                   (contains? options.children (list-head (. children index)) 1))
                                      1
                                      0))))))

(defn- named-child-count-invalid?
  [node options]
  (let [count (if options.direct
                (named-child-count-direct node options 1 0)
                (count-child-forms node options.children 1 0))]
    (or (and options.min-count (< count options.min-count))
        (and options.max-count (> count options.max-count)))))

(defn- child-count-invalid?
  [node options]
  (if options.children
    (named-child-count-invalid? node options)
    (not (direct-child-valid? node options))))

(defn child-count-finding
  [findings path form policy node]
  (let [options      (rule-options policy "child-count")
        form-name    (list-head node)
        form-applies (or (= (length (or options.forms [])) 0)
                         (contains? options.forms form-name 1))]
    (when (and form-applies
               (enabled? policy "child-count")
               (child-count-invalid? node options))
      (table.insert findings
        (finding path form (rule-severity policy "child-count") "child-count" (.. form-name " has an invalid child count") node)))))