(import-macros {: deftest : testing : is} :spec.eca.macros)

(deftest canonical-config-lint-diagnostics
  (testing "returns exit 0 with no diagnostics for the canonical config"
    (let [lines (vim.fn.systemlist "scripts/fennel-extras lint fnl/fennel-extras/config.fnl")
          code  vim.v.shell_error]
      (is (and (= 0
                  code)
               (= 0
                  (length lines)))))))
