(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.shape)

(local core (require :eca.nfnl.core))
(local ast (require :fennel-extras.lint.rules.ast))
(local registry (require :fennel-extras.lint.rules.registry))
(local leaf (require :fennel-extras.lint.rules.shape.leaf))
(local branch (require :fennel-extras.lint.rules.shape.branch))
(local meaningful-children ast.meaningful-children)
(local list-head ast.list-head)
(local quoted-child? ast.quoted-child?)
(local root-forms ast.root-forms)
(local form-for-node ast.form-for-node)
(local function-info leaf.function-info)
(local validate-function-body branch.validate-function-body)
(local function-head? leaf.function-head?)
(local finding registry.finding)
(local rule-severity registry.rule-severity)
(local enabled? registry.enabled?)

(defn function-violations
  [node]
  (let [info (function-info node) body (or (and info info.body) [])]
    (validate-function-body body [])))

(defn- function-target
  [base offending]
  (if
    (and (= (list-head offending) "if")
         (or (string.match base.form " > then$")
             (string.match base.form " > else$")))
    (core.assoc base :form (.. base.form " > if#1"))
    base))

(defn- add-function-finding
  [findings path form forms policy offending]
  (let [base   (form-for-node forms offending form) target (function-target base offending)]
    (table.insert findings
                  (finding path
                           target
                           (rule-severity policy "function-shape")
                           "function-shape"
                           "function body is too deep; move this into a named private function"
                           offending))))

(defn- add-function-findings-for-node
  [findings path form forms policy node]
  (each [_ offending (ipairs (function-violations node))]
    (add-function-finding findings path form forms policy offending)))

(defn add-function-findings
  [findings path form forms policy node]
  (when (enabled? policy "function-shape")
    (add-function-findings-for-node findings path form forms policy node)))
(defn- collect-function-children
  [node result walker]
  (each [index child (ipairs (or node.children []))]
    (and (or (= child.kind :list) (= child.kind :sequence) (= child.kind :table))
         (not (quoted-child? node.children index))
         (walker child result)))
  result)

(defn- collect-function-nodes
  [node result]
  (when (and node
             (= node.kind :list)
             (or (= (list-head node) "fn") (= (list-head node) "lambda") (= (list-head node) "λ")))
    (table.insert result node))
  (and
   node
   (collect-function-children node result collect-function-nodes))
  result)

(defn- synthetic-form
  [path node]
  {:line     node.open.line :col      node.open.col :end-line node.close.line :end-col  (+ node.close.col 1) :form     (.. path " > function-shape") :node     node})
(defn- function-nodes
  [source]
  (let [functions []]
    (each [_ root (ipairs (root-forms source))]
      (collect-function-nodes root functions))
    functions))

(defn- append-synthetic-node
  [all path forms policy node]
  (and (not (form-for-node forms node nil))
       (add-function-findings all path (synthetic-form path node) forms policy node)))

(defn- append-synthetic-nodes
  [all path forms policy source]
  (each [_ node (ipairs (function-nodes source))]
    (append-synthetic-node all path forms policy node))
  all)

(defn- append-synthetic-findings
  [all path forms policy source]
  (append-synthetic-nodes all path forms policy source))
(defn- position-before-or-equal?
  [left right]
  (or (< left.line right.line)
      (and (= left.line right.line) (<= left.col right.col))))

(defn- position-after-or-equal?
  [left right]
  (or (> left.line right.line)
      (and (= left.line right.line) (>= left.col right.col))))

(defn- node-contains?
  [outer inner]
  (and outer
       inner
       outer.open
       outer.close
       inner.open
       inner.close
       (position-before-or-equal? outer.open inner.open)
       (position-after-or-equal? outer.close inner.close)
       (or (< outer.open.line inner.open.line)
           (< outer.open.col inner.open.col)
           (> outer.close.line inner.close.line)
           (> outer.close.col inner.close.col))))

(defn- contained-function-finding?
  [finding candidate]
  (and (= candidate.rule "function-shape")
       (not= finding candidate)
       (node-contains? candidate.node finding.node)))

(defn- function-finding-contained?
  [finding findings]
  (accumulate [contained? false _ candidate (ipairs findings)]
    (or
     contained?
     (contained-function-finding? finding candidate))))

(defn- keep-function-finding
  [finding findings]
  (when (not (and (= finding.rule "function-shape")
                  (function-finding-contained? finding findings)))
    finding))

(defn remove-contained-function-findings
  [findings]
  (icollect [_ finding (ipairs findings)]
    (keep-function-finding finding findings)))

(defn synthetic-findings
  [all path forms policy source]
  (append-synthetic-findings all path forms policy source))
