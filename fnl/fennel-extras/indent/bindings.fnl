(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.indent.bindings)

(defn- trivia?
  [child]
  (and child
       (or (= child.kind :comment)
           (= child.kind :whitespace)
           (= child.kind :newline))))

(defn- append-child
  [result child]
  (table.insert result child)
  result)

(defn- meaningful-child-result
  [result child]
  (if (trivia? child)
    result
    (append-child result child)))

(defn meaningful-children
  [node]
  (accumulate [result [] _ child (ipairs (or node.children []))]
    (meaningful-child-result result child)))

(defn- append-pair
  [result pair]
  (table.insert result pair)
  result)

(defn- pair-record
  [name value-end previous-end]
  {:name name :value-end value-end :previous-end previous-end})

(defn- previous-end
  [pair]
  (and pair pair.value-end))

(defn- prefix-offset
  [value]
  (if (= value.kind :prefix)
    1
    0))

(defn- binding-value-end
  [value-index value]
  (+ value-index (prefix-offset value)))

(defn- pair-records-present-step
  [recur items index result]
  (let [value-index   (+ index 1)
        value         (. items value-index)
        value-end     (binding-value-end value-index value)
        name          (. items index)
        previous-pair (. result (length result))
        pair          (pair-record name (. items value-end) (previous-end previous-pair))
        next-result   (append-pair result pair)]
    (if name
      (recur items (+ value-end 1) next-result)
      [])))

(defn- pair-records-step
  [recur items index result]
  (if (. items (+ index 1))
    (pair-records-present-step recur items index result)
    []))

(defn- pair-records
  [items index result]
  (if (> index (length items))
    result
    (pair-records-step pair-records items index result)))

(defn pairs
  [node]
  (pair-records (meaningful-children node) 1 []))
