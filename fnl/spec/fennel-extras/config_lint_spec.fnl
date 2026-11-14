(import-macros {: deftest : testing : is} :fennel-extras.macros.test)

(deftest canonical-config-lint-diagnostics
  (testing "returns exit 0 with warning diagnostics for the canonical config"
    (let [lines (vim.fn.systemlist "scripts/fennel-extras lint fnl/fennel-extras/config.fnl")
          code  vim.v.shell_error]
      (is (and (= 0
                  code)
               (> (length lines) 0)
               (string.find (table.concat lines "\n") "Keep or operands simple; extract conditional logic into private functions."))))))
