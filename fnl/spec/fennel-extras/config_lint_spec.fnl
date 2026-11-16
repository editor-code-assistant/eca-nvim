(import-macros {: deftest : testing : is} :fennel-extras.macros.test)

(deftest canonical-config-lint-diagnostics
  (testing "returns no diagnostics for the canonical config"
    (let [lines (vim.fn.systemlist "scripts/fennel-extras lint fnl/fennel-extras/config.fnl")]
      (is (and (= 0
                  vim.v.shell_error)
               (= 0
                  (length lines)))))))
