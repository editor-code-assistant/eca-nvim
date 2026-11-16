(import-macros {: deftest : testing : is} :fennel-extras.macros.test)

(deftest canonical-config-lint-diagnostics
  (testing "returns diagnostics for the canonical config"
    (let [lines (vim.fn.systemlist "scripts/fennel-extras lint fnl/fennel-extras/config.fnl")]
      (is (and (> (length lines) 0)
               (string.find (table.concat lines "\n") "Keep `or` operands simple; extract conditional logic into private functions. Use `cond` and `case` when possible."))))))
