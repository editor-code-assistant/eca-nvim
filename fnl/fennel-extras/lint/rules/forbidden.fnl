(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.forbidden)

(local core (require :eca.nfnl.core))
(local ast (require :fennel-extras.lint.rules.ast))
(local registry (require :fennel-extras.lint.rules.registry))
(local meaningful-children ast.meaningful-children)
(local literal-text ast.literal-text)
(local list-head ast.list-head)
(local finding registry.finding)
(local enabled? registry.enabled?)
(local rule-severity registry.rule-severity)

(defn- contains?
  [items target index]
  (if (> index (length items))
    false
    (or (= (. items index) target)
        (contains? items target (+ index 1)))))

(defn- module-target
  [node]
  (let [head     (list-head node)
        children (meaningful-children node)]
    (when (or (= head "require") (= head "import") (= head "module"))
      (literal-text (. children 2)))))

(defn- finding-node
  [node]
  (let [target (module-target node)]
    (if target
      (core.assoc node :text target)
      node)))

(defn- form-forbidden?
  [node options]
  (let [head   (list-head node)
        target (module-target node)]
    (and (or (= options.module nil)
             (= target options.module))
         (or (= options.forms nil)
             (contains? options.forms head 1)))))

(defn findings
  [result path form policy node]
  (when (and (enabled? policy "forbidden-form")
             node
             (= node.kind :list)
             (list-head node)
             (form-forbidden? node (registry.rule-options policy "forbidden-form")))
    (table.insert result
                  (finding path
                           form
                           (rule-severity policy "forbidden-form")
                           "forbidden-form"
                           "forbidden form"
                           (finding-node node))))
  result)
