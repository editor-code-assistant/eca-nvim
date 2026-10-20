(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.indent.align)

(local helpers (require :fennel-extras.indent.node))

(defn- alignment-form-name?
  [head]
  (and
   head
   (= head.kind :symbol)
   (or
    (= head.text "let")
    (= head.text "when-let")
    (= head.text "if-let")
    (= head.text "with-open"))))

(defn- alignment-form?
  [node parent]
  (and
   parent
   (= node.kind :sequence)
   (= parent.kind :list)
   (alignment-form-name? (. (helpers.nontrivia-children parent) 1))))

(defn- clause-form-name?
  [head]
  (and
   head
   (= head.kind :symbol)
   (or
    (= head.text "case")
    (= head.text "match")
    (= head.text "case-try")
    (= head.text "match-try")
    (= head.text "if"))))

(defn- clause-form?
  [node]
  (and (= node.kind :list)
       (clause-form-name? (. (helpers.nontrivia-children node) 1))))

(defn- alignment-node?
  [node parent]
  (
   or
   (= node.kind :table)
   (alignment-form? node parent)
   (clause-form? node)))

(defn- append-alignment-node
  [result node]
  (table.insert result node)
  result)

(defn- alignment-node-result
  [result node parent]
  (if (alignment-node? node parent)
    (append-alignment-node result node)
    result))

(defn- collect-alignment-nodes
  [node parent result]
  (let [next-result (alignment-node-result result node parent)]
    (accumulate [state next-result _ child (ipairs (or node.children []))]
      (or (and child.text state)
          (and child.children (collect-alignment-nodes child node state))
          state))))

(defn- single-line-name?
  [name-start name-end]
  (
   and
   name-end
   (= name-start.line name-end.line)))

(defn- append-pair-candidate
  [result pair]
  (table.insert result pair)
  result)

(defn- adjacent-token?
  [left right]
  (= (+ left.out-col (helpers.codepoint-width left.text)) right.out-col))

(defn- name-end-index
  [children index]
  (let [name      (. children index)
        candidate (. children (+ index 1))]
    (if (and
         candidate
         (= candidate.kind :prefix)
         (adjacent-token? (helpers.child-end name) candidate))
      (name-end-index children (+ index 1))
      index)))

(defn- value-index
  [children index]
  (let [candidate (. children index)]
    (if (and candidate (= candidate.kind :prefix))
      (value-index children (+ index 1))
      index)))

(defn- pair-candidate
  [children index result parent-kind]
  (let [name-end-position (name-end-index children index)
        name              (. children index)
        name-end          (helpers.child-end (. children name-end-position))
        value-start-child (. children (+ name-end-position 1))
        value-position    (value-index children (+ name-end-position 1))
        value             (. children value-position)
        name-start        (helpers.child-start name)
        value-start       (and value-start-child (helpers.child-start value-start-child))]
    (if (and
         value
         value-start
         (= name-start.line value-start.line)
         (single-line-name? name-start name-end))
      (append-pair-candidate
       result
       {:name        name-start
        :name-end    name-end
        :value       value-start
        :value-node  value
        :parent-kind parent-kind
        :line        name-start.line})
      result)))

(defn- pair-candidates
  [children index result parent-kind]
  (let [done              (> index (length children))
        name-end-position (and (not done) (name-end-index children index))
        next-index        (and name-end-position
                               (+ (value-index children (+ name-end-position 1)) 1))
        next-result       (and next-index (pair-candidate children index result parent-kind))]
    (if done
      result
      (pair-candidates children next-index next-result parent-kind))))

(defn- pair-count-step
  [count pair line]
  (
   if
    (= pair.line line)
    (+ count 1)
    count))

(defn- pair-count
  [pairs line]
  (accumulate [count 0 _ pair (ipairs pairs)]
    (pair-count-step count pair line)))

(defn- single-pair
  [pairs pair]
  (
   when
    (= (pair-count pairs pair.line) 1)
    pair))

(defn- single-pairs
  [pairs]
  (icollect [_ pair (ipairs pairs)]
    (single-pair pairs pair)))

(defn- pair-name-width
  [pair]
  (- (+ pair.name-end.out-col (helpers.codepoint-width pair.name-end.text))
     pair.name.out-col))

(defn- pair-target
  [pair width]
  (if (and (= pair.parent-kind :table) (= pair.name.text "("))
    (+ pair.name.out-col width)
    (+ pair.name.out-col width 1)))

(defn- alignment-width
  [pairs]
  (accumulate [width 0 _ pair (ipairs pairs)]
    (math.max width (pair-name-width pair))))

(defn- clause-start-index
  [node]
  (let [head (. (helpers.nontrivia-children node) 1)]
    (
     if (= head.text "if") 2
      3)))

(defn- clause-pair?
  [node pair]
  (
   or
   (not (clause-form? node))
   (> pair.line node.open.line)))

(defn- comment-on-line?
  [node line]
  (accumulate [found false _ child (ipairs node.children)]
    (
     or
     found
     (and child.text (= child.kind :comment) (= child.line line)))))

(defn- usable-pair?
  [node pair]
  (and (clause-pair? node pair)
       (not (comment-on-line? node pair.line))))

(defn- usable-pair-result
  [node pair]
  (
   when
    (usable-pair? node pair)
    pair))

(defn- usable-pairs
  [node pairs]
  (icollect [_ pair (ipairs pairs)]
    (usable-pair-result node pair)))

(defn- alignment-plan-result
  [pairs]
  (when (> (length pairs) 1)
    {:pairs pairs :width (alignment-width pairs)}))

(defn- alignment-start
  [node]
  (
   if
    (clause-form? node)
    (clause-start-index node)
    1))

(defn- alignment-plan
  [node]
  (let [children (helpers.nontrivia-children node)
        start    (alignment-start node)
        pairs    (single-pairs (pair-candidates children start [] node.kind))
        usable   (usable-pairs node pairs)]
    (alignment-plan-result usable)))

(defn- alignment-plans
  [nodes]
  (icollect [_ node (ipairs nodes)]
    (alignment-plan node)))

(defn- append-alignment-edit
  [edits plan pair]
  (let [name-width      (pair-name-width pair)
        name-end-column (+ pair.name.out-col name-width)
        target          (pair-target pair plan.width)]
    (table.insert
     edits
     {:line   pair.line
      :start  (+ name-end-column 1)
      :finish (+ pair.value.out-col 1)
      :spaces (- target name-end-column)})))

(defn- append-plan-pairs
  [edits plan]
  (each [_ pair (ipairs plan.pairs)]
    (append-alignment-edit edits plan pair))
  edits)

(defn- append-plan-edits
  [edits plan]
  (if plan
    (append-plan-pairs edits plan)
    edits))

(defn- alignment-edits
  [plans]
  (accumulate [edits [] _ plan (ipairs plans)]
    (append-plan-edits edits plan)))

(defn- apply-edit
  [line edit]
  (.. (string.sub line 1 (- edit.start 1))
      (string.rep " " edit.spaces)
      (string.sub line edit.finish)))

(defn- line-edit
  [line-number edit]
  (
   when
    (= edit.line line-number)
    edit))

(defn- line-edits
  [edits line-number]
  (icollect [_ edit (ipairs edits)]
    (line-edit line-number edit)))

(defn- apply-edits
  [line edits]
  (table.sort edits (fn [left right] (> left.start right.start)))
  (accumulate [result line _ edit (ipairs edits)]
    (apply-edit result edit)))

(defn- apply-alignment
  [lines plans]
  (let [edits (alignment-edits plans)]
    (icollect [line-number line (ipairs lines)]
      (apply-edits line (line-edits edits line-number)))))

(defn apply
  [output tree]
  (let [nodes (collect-alignment-nodes tree nil [])]
    (apply-alignment output (alignment-plans nodes))))
