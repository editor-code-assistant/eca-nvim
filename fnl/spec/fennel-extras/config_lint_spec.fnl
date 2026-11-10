(import-macros {: deftest : testing : is} :spec.eca.macros)

(deftest canonical-config-is-lint-clean
  (testing "returns zero exit status"
    (let [lines (vim.fn.systemlist "scripts/fennel-extras lint fnl/fennel-extras/config.fnl")
          code  vim.v.shell_error]
      (is (= 0 code))))

  (testing "reports no lint findings"
    (let [lines (vim.fn.systemlist "scripts/fennel-extras lint fnl/fennel-extras/config.fnl")]
      (is (= 0 (length lines))))))
