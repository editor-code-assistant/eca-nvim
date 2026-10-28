(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.module)

(local core (require :eca.nfnl.core))
(local ast (require :fennel-extras.lint.rules.ast))
(local registry (require :fennel-extras.lint.rules.registry))
(local meaningful-children ast.meaningful-children)
(local symbol-text ast.symbol-text)
(local list-head ast.list-head)
(local literal-text ast.literal-text)
(local enabled? registry.enabled?)
(local rule-severity registry.rule-severity)
(local finding registry.finding)

(defn module-finding
  [path forms policy module-ok]
  (if (and (enabled? policy "module-style")
           (not module-ok))
    [{:kind "finding" :path path :line 1 :col 1 :end-line 1 :end-col 1 :severity (rule-severity policy "module-style") :rule "module-style" :form (.. path " > file") :message "file must use the module style" :node nil}]
    []))


(defn- core-finding-form
  [path form head children]
  (if (= head "local")
    {:line form.line :col form.col :end-line form.end-line :end-col form.end-col :form (.. path " > local:" (symbol-text (. children 2)))}
    form))



(defn- add-core-finding
  [findings path form head children node policy]
  (let [finding-form (core-finding-form path form head children)]
    (table.insert findings
                  (finding path finding-form (rule-severity policy "direct-require") "direct-require" "bind eca.nfnl.core as core" node)))
  nil)


(defn- direct-require-form
  [head children node]
  (or (and (= head "local") (. children 3))
      node))



(defn- direct-require-target
  [require-form require-children]
  (and (= (list-head require-form) "require")
       (literal-text (. require-children 2))))



(defn- canonical-direct-require?
  [head children require-children binding]
  (or (and (= head "local")
           (= (length children) 3)
           (= (symbol-text (. children 2)) binding)
           (= (length require-children) 2))
      (and (= head "require") (= (length children) 2))))



(defn- maybe-add-direct-require-finding
  [findings path form head children node policy target canonical options]
  (when (and options
             (= options.mode "require")
             (= target (. options :module))
             (not canonical))
    (add-core-finding findings path form head children node policy)))



(defn- direct-require-children
  [require-form]
  (if require-form
    (meaningful-children require-form)
    []))



(defn direct-require-finding
  [findings path form head node policy]
  (let [children         (meaningful-children node)
        require-form     (direct-require-form head children node)
        require-children (direct-require-children require-form)
        target           (direct-require-target require-form require-children)
        options          (registry.rule-options policy "direct-require")
        binding          (and options (. options :binding))
        canonical        (canonical-direct-require? head children require-children binding)]
    (maybe-add-direct-require-finding findings path form head children node policy target canonical options)))
