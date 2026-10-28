(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.spec)

(local ast (require :fennel-extras.lint.rules.ast))
(local registry (require :fennel-extras.lint.rules.registry))
(local meaningful-children ast.meaningful-children)
(local literal-text ast.literal-text)
(local list-head ast.list-head)
(local rule-options registry.rule-options)
(local enabled? registry.enabled?)
(local rule-severity registry.rule-severity)
(local finding registry.finding)
(local count-is ast.count-is)

(defn- contains?
  [items target index]
  (if (> index (length items))
    false
    (or (= (. items index) target)
        (contains? items target (+ index 1)))))



(defn- exempt-file?
  [path policy rule]
  (let [patterns (. (rule-options policy rule) :exempt-files)]
    (and patterns
         (> (length patterns) 0)
         (or (and policy.matcher (policy.matcher (. patterns 1) path))
             (= (string.sub path 1 (- (string.len (. patterns 1)) 1))
                (string.sub (. patterns 1) 2))))))



(defn spec-import-finding
  [path forms policy valid]
  (if (and (not (exempt-file? path policy "macro-import"))
           (enabled? policy "macro-import")
           (not valid))
    [{:kind "finding" :path path :line 1 :col 1 :end-line 1 :end-col 1 :severity (rule-severity policy "macro-import") :rule "macro-import" :form (.. path " > spec") :message "specs must import deftest, testing, and is from spec.eca.macros" :node nil}]
    []))



(defn direct-require?
  [path]
  (= path "fnl/spec/eca/macros.fnlm"))


(defn direct-require-finding
  [findings path form policy node]
  (let [children (meaningful-children node)
        target   (literal-text (. children 2))
        options  (rule-options policy "direct-require")
        modules  (or (. options :modules) [])]
    (when (and (= options.mode "forbid")
               (not (exempt-file? path policy "direct-require"))
               (enabled? policy "direct-require")
               (contains? modules target 1))
      (table.insert findings
                    (finding path form (rule-severity policy "direct-require") "direct-require" "specs must use the shared macro import" node)))))



(defn- count-child-forms
  [node children index result]
  (if (> index (length children))
    result
    (count-child-forms node children (+ index 1)
                       (+ result (count-is node 1 0 (list-head node) (. children index))))))



(defn form-child-count-finding
  [findings path form policy node]
  (let [options (rule-options policy "form-child-count")
        count   (count-child-forms node options.children 1 0)]
    (when (and (enabled? policy "form-child-count")
               (not= count options.max-count))
      (table.insert findings
                    (finding path form (rule-severity policy "form-child-count") "form-child-count" "each testing form must contain exactly one is" node)))))
