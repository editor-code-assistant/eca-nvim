(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.mutation)

(local core (require :eca.nfnl.core))
(local ast (require :fennel-extras.lint.rules.ast))
(local registry (require :fennel-extras.lint.rules.registry))
(local root-forms ast.root-forms)
(local previous-meaningful-index ast.previous-meaningful-index)
(local list-head ast.list-head)
(local spec-file? ast.spec-file?)
(local form-for-node ast.form-for-node)
(local nearest-form ast.nearest-form)
(local finding registry.finding)
(local enabled? registry.enabled?)
(local rule-severity registry.rule-severity)

(defn- mutation-head? [head]
  (or (= head "var") (= head "set") (= head "while")))

(defn- mutation-mode-for-prefix [prefix mode]
  (or (and (= prefix "'") :quoted)
      (and (= mode :quoted) :quoted)
      (and (= prefix "`") (+ mode 1))
      (and (= prefix ",") (math.max 0 (- mode 1)))
      mode))

(defn- mutation-mode-for-child [node index mode]
  (let [previous-index (previous-meaningful-index node.children index)
        previous       (and previous-index (. node.children previous-index))]
    (if (and previous (= previous.kind :prefix))
        (mutation-mode-for-prefix previous.text
                                  (mutation-mode-for-child node previous-index mode))
        mode)))

(defn- append-mutation-child [node result index child mode recurse]
  (let [child-mode (mutation-mode-for-child node index mode)]
    (if (and (or (= child.kind :list) (= child.kind :sequence) (= child.kind :table))
             (not= child-mode :quoted))
        (recurse child result child-mode)
        result)))

(defn- collect-mutation-children [node result mode recurse]
  (accumulate [state result index child (ipairs (or node.children []))]
    (append-mutation-child node state index child mode recurse)))

(defn- mutation-node-result [node result mode]
  (if (and (= mode 0) (= node.kind :list) (mutation-head? (list-head node)))
      (core.concat result [node])
      result))

(defn- collect-mutation-nodes [node result mode]
  (collect-mutation-children node (mutation-node-result node result mode) mode collect-mutation-nodes))

(defn- mutation-nodes [source]
  (accumulate [result [] _ root (ipairs (root-forms source))]
    (collect-mutation-nodes root result 0)))

(defn- mutation-form [path node base ordinal]
  {:line node.open.line :col node.open.col
   :end-line node.close.line :end-col (+ node.close.col 1)
   :form (.. base.form " > no-mutation#" ordinal) :node node})

(defn- append-mutation-finding [findings path forms policy node ordinals]
  (let [existing (form-for-node forms node nil)
        base     (or existing (nearest-form forms node) {:form path})
        ordinal  (+ (or (. ordinals base.form) 0) 1)
        form     (or existing (mutation-form path node base ordinal))]
    (table.insert findings (finding path form (rule-severity policy "no-mutation")
                                    "no-mutation"
                                    "avoid mutation (var/set/while); prefer a functional form"
                                    node))
    (core.assoc ordinals base.form ordinal)))

(defn- add-mutation-finding [findings path forms policy node ordinals]
  (if (and (not (spec-file? path)) (enabled? policy "no-mutation"))
      (append-mutation-finding findings path forms policy node ordinals)
      ordinals))

(defn findings [findings path forms policy source]
  (accumulate [ordinals {}
               _ node (ipairs (mutation-nodes source))]
    (add-mutation-finding findings path forms policy node ordinals))
  findings)
