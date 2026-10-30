(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.module)

(local core (require :eca.nfnl.core))
(local ast (require :fennel-extras.lint.rules.ast))
(local root-forms ast.root-forms)
(local registry (require :fennel-extras.lint.rules.registry))
(local meaningful-children ast.meaningful-children)
(local symbol-text ast.symbol-text)
(local list-head ast.list-head)
(local literal-text ast.literal-text)
(local import-macros? ast.import-macros?)
(local has-all? ast.has-all?)
(local enabled? registry.enabled?)
(local rule-severity registry.rule-severity)
(local finding registry.finding)

(defn required-form-finding
  [path source policy]
  (if (enabled? policy "required-form")
    (let [options (registry.rule-options policy "required-form")
          found   (accumulate [result false _ form (ipairs (root-forms source))]
                    (or result (= (list-head (or form.node form)) (. options.forms 1))))]
      (if (not found)
        [{:kind "finding" :path path :line 1 :col 1 :end-line 1 :end-col 1 :severity (rule-severity policy "required-form") :rule "required-form" :form (.. path " > file") :message "file must contain a required top-level form" :node nil}]
        []))
    []))

(defn module-finding
  [path forms policy module-ok]
  (if (and (enabled? policy "module-style")
           (not module-ok))
    [{:kind "finding" :path path :line 1 :col 1 :end-line 1 :end-col 1 :severity (rule-severity policy "module-style") :rule "module-style" :form (.. path " > file") :message "file must use the module style" :node nil}]
    []))


(defn- contains?
  [items target index]
  (if (> index (length items))
    false
    (or (= (. items index) target)
        (contains? items target (+ index 1)))))

(defn- module-target
  [node]
  (let [head     (list-head node)
        children (meaningful-children node)
        index    (if (= head "import-macros") 3 2)]
    (when (or (= head "require")
              (= head "import")
              (= head "import-macros")
              (= head "module"))
      (literal-text (. children index)))))

(defn- finding-form
  [path form head children]
  (if (= head "local")
    {:line form.line :col form.col :end-line form.end-line :end-col form.end-col :form (.. path " > local:" (symbol-text (. children 2)))}
    form))

(defn- canonical-require?
  [head children require-children binding]
  (or (and (= head "local")
           (= (length children) 3)
           (= (symbol-text (. children 2)) binding)
           (= (length require-children) 2))
      (and (= head "require") (= (length children) 2))))

(defn- exempt-file?
  [path policy options]
  (let [patterns (or options.exempt-files [])]
    (accumulate [result false _ pattern (ipairs patterns)]
      (or result
          (and policy.matcher (policy.matcher pattern path))))))

(defn module-import-finding
  [findings path form head node policy]
  (let [children     (meaningful-children node)
        require      (and (= head "local") (. children 3))
        req-children (if require (meaningful-children require) [])
        options      (registry.rule-options policy "module-import")
        target       (module-target (or require node))
        import-info  (import-macros? node)
        modules      (or options.modules [])
        binding      (or options.binding "core")
        forbidden    (and (= options.mode "forbid")
                          (not (= target options.module))
                          (not (exempt-file? path policy options))
                          target
                          (contains? modules target 1))
        required     (and (= options.mode "require")
                          (not (exempt-file? path policy options))
                          (= target options.module)
                          (if import-info
                            (not (has-all? import-info.names (or options.forms [])))
                            (not (canonical-require? head children req-children binding))))]
    (when (and (enabled? policy "module-import") (or forbidden required))
      (table.insert findings
                    (finding path (finding-form path form head children)
                             (rule-severity policy "module-import") "module-import"
                             (if forbidden "forbidden module import" "bind the required module canonically")
                             node)))))
