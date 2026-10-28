(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.traverse)

(local core (require :eca.nfnl.core))
(local ast (require :fennel-extras.lint.rules.ast))
(local reader (require :fennel-extras.reader))
(local previous-meaningful-index ast.previous-meaningful-index)

(defn- mutation-mode-for-prefix
  [prefix mode]
  (or (and (= prefix "'") :quoted)
      (and (= mode :quoted) :quoted)
      (and (= prefix "`") (+ mode 1))
      (and (= prefix ",") (math.max 0 (- mode 1)))
      mode))

(defn- mutation-mode-for-child
  [node index mode]
  (let [previous-index (previous-meaningful-index node.children index)
        previous       (and previous-index (. node.children previous-index))]
    (if (and previous (= previous.kind :prefix))
      (mutation-mode-for-prefix previous.text (mutation-mode-for-child node previous-index mode))
      mode)))

(defn- append-executable-child
  [node result index child mode recurse predicate]
  (let [child-mode (mutation-mode-for-child node index mode)]
    (if (and (or (= child.kind :list) (= child.kind :sequence) (= child.kind :table))
             (not= child-mode :quoted))
      (recurse child result child-mode predicate)
      result)))

(defn- collect-executable-children
  [node result mode recurse predicate]
  (accumulate [state result index child (ipairs (or node.children []))]
    (append-executable-child node state index child mode recurse predicate)))

(defn- executable-node-result
  [node result mode predicate]
  (if (and (= mode 0) (predicate node))
    (core.concat result [node])
    result))

(defn- collect-executable-nodes
  [node result mode predicate]
  (collect-executable-children node (executable-node-result node result mode predicate) mode collect-executable-nodes predicate))

(defn executable-nodes
  [source predicate]
  (let [root (reader.parse source)]
    (if root
      (collect-executable-nodes root [] 0 predicate)
      [])))