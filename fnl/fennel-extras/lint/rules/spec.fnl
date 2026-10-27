(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.spec)

(local ast (require :fennel-extras.lint.rules.ast))
(local registry (require :fennel-extras.lint.rules.registry))
(local meaningful-children ast.meaningful-children)
(local literal-text ast.literal-text)
(local list-head ast.list-head)
(local count-is ast.count-is)
(local rule-options registry.rule-options)
(local enabled? registry.enabled?)
(local rule-severity registry.rule-severity)
(local finding registry.finding)

(defn- contains?
  [items target index]
  (if (> index (length items))
    false
    (or (= (. items index) target)
        (contains? items target (+ index 1)))))

(defn- exempt-file?
  [path policy rule]
  (let [patterns (. (rule-options policy rule) :exempt-files)]
    (or (and (= path "fnl/spec/eca/macros.fnlm")
             (or (= rule "spec-macro-import") (= rule "spec-direct-require")))
        (and patterns
             (> (length patterns) 0)
             (or (and policy.matcher (policy.matcher (. patterns 1) path))
                 (= (string.sub path 1 (- (string.len (. patterns 1)) 1))
                    (string.sub (. patterns 1) 2)))))))

(defn spec-import-finding
  [path forms policy valid]
  (if (and (not (exempt-file? path policy "spec-macro-import"))
           (enabled? policy "spec-macro-import")
           (not valid))
    [{:kind "finding" :path path :line 1 :col 1 :end-line 1 :end-col 1 :severity (rule-severity policy "spec-macro-import") :rule "spec-macro-import" :form (.. path " > spec") :message "specs must import deftest, testing, and is from spec.eca.macros" :node nil}]
    []))

(defn direct-require?
  [path]
  (= path "fnl/spec/eca/macros.fnlm"))
(defn spec-direct-require-finding
  [findings path form policy node]
  (let [children (meaningful-children node)
        target   (literal-text (. children 2))
        modules  (. (rule-options policy "spec-direct-require") :modules)]
    (when (and (not (exempt-file? path policy "spec-direct-require"))
               (enabled? policy "spec-direct-require")
               (contains? modules target 1))
      (table.insert findings
                    (finding path form (rule-severity policy "spec-direct-require") "spec-direct-require" "specs must use the shared macro import" node)))))

(defn testing-finding
  [findings path form policy node]
  (let [options        (rule-options policy "one-is-per-testing")
        count          (count-is node 1 0 options.testing options.assertion)
        expected-count options.count]
    (when (and (not= count expected-count) (enabled? policy "one-is-per-testing"))
      (table.insert findings
                    (finding path form (rule-severity policy "one-is-per-testing") "one-is-per-testing" "each testing form must contain exactly one is" node)))))
