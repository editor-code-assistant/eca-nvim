(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.spec)

(local ast (require :fennel-extras.lint.rules.ast))
(local registry (require :fennel-extras.lint.rules.registry))
(local meaningful-children ast.meaningful-children)
(local literal-text ast.literal-text)
(local list-head ast.list-head)
(local spec-file? ast.spec-file?)
(local count-is ast.count-is)
(local enabled? registry.enabled?)
(local rule-severity registry.rule-severity)
(local finding registry.finding)

(defn spec-import-finding [path forms policy valid]
  (if (and (spec-file? path) (not= path "fnl/spec/eca/macros.fnlm")
           (enabled? policy "spec-macro-import") (not valid))
      [{:kind "finding" :path path :line 1 :col 1 :end-line 1 :end-col 1
        :severity (rule-severity policy "spec-macro-import") :rule "spec-macro-import"
        :form    (.. path " > spec")
        :message "specs must import deftest, testing, and is from spec.eca.macros"
        :node    nil}]
      []))

(defn direct-require? [path]
  (= path "fnl/spec/eca/macros.fnlm"))
(defn spec-direct-require-finding [findings path form policy node]
  (let [children (meaningful-children node)
        target   (literal-text (. children 2))]
    (if (and (or (= target "plenary.busted") (= target "luassert"))
             (enabled? policy "spec-direct-require"))
        (table.insert findings (finding path form (rule-severity policy "spec-direct-require")
                                        "spec-direct-require"
                                        "specs must use the shared macro import" node)))))

(defn testing-finding [findings path form policy node]
  (let [count (count-is node 1 0)]
    (if (and (not= count 1) (enabled? policy "one-is-per-testing"))
        (table.insert findings (finding path form (rule-severity policy "one-is-per-testing")
                                        "one-is-per-testing"
                                        "each testing form must contain exactly one is"
                                        node)))))
