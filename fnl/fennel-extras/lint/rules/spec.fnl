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

(defn- executable-child?
  [node]
  (and node
       (not= node.kind :prefix)))

(defn- append-executable-child
  [result child depth]
  (when (executable-child? child)
        (table.insert result {:node child :depth depth})))

(defn- function-form?
  [node]
  (and (= node.kind :list)
       (or (= (list-head node) "fn")
           (= (list-head node) "defn")
           (= (list-head node) "defn-"))))

(defn- collect-executable-children-step
  [children index result depth recursive? recurse]
  (if (> index (length children))
    result
    (let [child (. children index)]
      (if (ast.quoted-child? children index)
        (recurse children (+ index 1) result depth recursive? recurse)
        (do
         (append-executable-child result child depth)
         (if (and (= child.kind :list)
                  (or recursive? (function-form? child)))
           (let [nested (recurse (meaningful-children child) 2 result (+ depth 1) recursive? recurse)]
             (recurse children (+ index 1) nested depth recursive? recurse))
           (recurse children (+ index 1) result depth recursive? recurse)))))))

(defn- collect-executable-children
  [node start recursive?]
  (collect-executable-children-step (meaningful-children node) start [] 0 recursive? collect-executable-children-step))

(defn- name-in?
  [names target index]
  (and (<= index (length names))
       (or (= (. names index) target)
           (name-in? names target (+ index 1)))))

(defn- named-child-count-step
  [children names index result recurse]
  (if (> index (length children))
    result
    (if (ast.quoted-child? children index)
      (recurse children names (+ index 1) result recurse)
      (let [node   (. children index)
            nested (if (= node.kind :list)
                     (recurse (meaningful-children node) names 2 result recurse)
                     result)]
        (recurse children names (+ index 1)
                 (if (and (= node.kind :list)
                          (name-in? names (list-head node) 1))
                   (+ nested 1)
                   nested)
                 recurse)))))

(defn- named-child-count
  [node names]
  (named-child-count-step (meaningful-children node) names 2 0 named-child-count-step))

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

(defn- executable-count-step
  [children options index result]
  (if (> index (length children))
    result
    (let [child (. children index)]
      (executable-count-step children options (+ index 1)
                              (if (not (not-counted-literal? child.node options))
                                (+ result 1)
                                result)))))

(defn- direct-count
  [node options]
  (let [start (if (= (list-head node) "if") 3 2)]
    (executable-count-step (collect-executable-children node start false)
                           options
                           1
                           0)))

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
        min          options.min-count
        max          options.max-count]
    (and (not missing)
         (not multi-clause)
         (or (not nil-else)
             options.nil-count
             (contains? (or options.not-counted []) "nil" 1))
         (>= count min)
         (<= count max))))

(defn- child-count-invalid?
  [node options]
  (if options.children
    (not= (named-child-count node options.children) options.max-count)
    (not (direct-child-valid? node options))))

(defn child-count-finding
  [findings path form policy node]
  (let [options      (rule-options policy "child-count")
        form-applies (or (= (length (or options.forms [])) 0)
                         (contains? options.forms (list-head node) 1))]
    (when (and form-applies
               (enabled? policy "child-count")
               (child-count-invalid? node options))
          (table.insert findings
                        (finding path form (rule-severity policy "child-count") "child-count" "form has an invalid child count" node)))))