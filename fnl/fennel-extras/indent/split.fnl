(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.indent.split)

(local reader (require :fennel-extras.reader))
(local helpers (require :fennel-extras.indent.node))
(local bindings (require :fennel-extras.indent.bindings))
(local settings (require :fennel-extras.indent.settings))

(defn- prefixed?
  [child]
  (and child child.text (= child.kind :prefix)))

(defn- quoted-child?
  [previous]
  (prefixed? previous))

(defn- binding-head
  [node]
  (. (bindings.meaningful-children node) 1))

(defn- supported-form?
  [node alignment]
  (let [head (binding-head node)]
    (and (= node.kind :list)
         head
         (= head.kind :symbol)
         ((. settings "binding-form?") alignment head.text))))

(defn- same-line-edit
  [name-start value-end]
  (when (and name-start value-end (= name-start.line value-end.line))
    {:line name-start.line :column name-start.col}))

(defn- pair-edit
  [pair]
  (let [name-start (and pair.name (helpers.child-start pair.name))
        value-end  (and pair.previous-end (helpers.child-end pair.previous-end))]
    (same-line-edit name-start value-end)))

(defn- append-edit
  [edits edit]
  (table.insert edits edit)
  edits)

(defn- pair-edit-result
  [edits pair]
  (let [edit (pair-edit pair)]
    (if edit
      (append-edit edits edit)
      edits)))

(defn- pair-edits
  [vector]
  (accumulate [edits [] _ pair (ipairs (bindings.pairs vector))]
    (pair-edit-result edits pair)))

(defn- vector-edits
  [node]
  (let [vector (. (bindings.meaningful-children node) 2)]
    (if (and vector (= vector.kind :sequence))
      (pair-edits vector)
      [])))

(defn- append-edits-step
  [result edit]
  (table.insert result edit)
  result)

(defn- append-edits
  [left right]
  (accumulate [result left _ edit (ipairs right)]
    (append-edits-step result edit)))

(defn- walk-text-child
  [state child]
  {:edits state.edits :previous child})

(defn- walk-nested-child
  [recur state child quoted alignment]
  (let [child-quoted (or quoted (quoted-child? state.previous))
        nested       (recur child child-quoted alignment)
        edits        (append-edits state.edits nested)]
    {:edits edits :previous nil}))

(defn- walk-child
  [recur state child quoted alignment]
  (if child.text
    (walk-text-child state child)
    (walk-nested-child recur state child quoted alignment)))

(defn- walk-edits
  [node quoted alignment]
  (if (and (not quoted) (supported-form? node alignment))
    (vector-edits node)
    []))

(defn- walk-state
  [recur node edits quoted alignment]
  (accumulate [state
               {:edits edits :previous nil}
               _
               child
               (ipairs (or node.children []))]
    (walk-child recur state child quoted alignment)))

(defn- walk-node
  [node quoted alignment]
  (let [edits (walk-edits node quoted alignment)
        state (walk-state walk-node node edits quoted alignment)]
    state.edits))

(defn- whitespace?
  [line index]
  (let [character (string.sub line index index)]
    (or (= character " ") (= character "\t"))))

(defn- whitespace-start
  [line finish]
  (if (and (> finish 1) (whitespace? line (- finish 1)))
    (whitespace-start line (- finish 1))
    finish))

(defn- apply-edit
  [line edit]
  (let [finish edit.column
        start  (whitespace-start line finish)]
    (.. (string.sub line 1 (- start 1)) "\n" (string.sub line finish))))

(defn- prepend-line
  [lines line]
  (table.insert lines 1 line)
  lines)

(defn- split-lines-step
  [recur source at]
  (let [line  (string.sub source 1 (- at 1))
        lines (recur (string.sub source (+ at 1)))]
    (prepend-line lines line)))

(defn- split-lines
  [source]
  (let [at (string.find source "\n" 1 true)]
    (if at
      (split-lines-step split-lines source at)
      [source])))

(defn- apply-edit-step
  [recur lines edits edit]
  (let [line  (. lines edit.line)
        value (apply-edit line edit)]
    (tset lines edit.line value)
    (recur recur lines edits)))

(defn- apply-edits-step
  [recur lines edits]
  (if (= (length edits) 0)
    lines
    (apply-edit-step recur lines edits (table.remove edits 1))))

(defn- edit-before?
  [left right]
  (if (= left.line right.line)
    (> left.column right.column)
    (> left.line right.line)))

(defn- apply-edits
  [source edits]
  (let [lines (split-lines source)]
    (table.sort edits edit-before?)
    (table.concat (apply-edits-step apply-edits-step lines edits) "\n")))

(defn- split-tree
  [source tree alignment]
  (let [edits (walk-node tree false alignment)]
    (values (apply-edits source edits) nil edits)))

(defn- split-source
  [source alignment]
  (let [(tree error) (reader.parse source)]
    (if error
      (values nil error [])
      (split-tree source tree alignment))))

(defn split
  [source alignment]
  (if (not alignment.split-bindings)
    (values source nil [])
    (split-source source alignment)))
