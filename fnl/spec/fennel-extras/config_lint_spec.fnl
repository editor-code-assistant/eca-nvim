(import-macros {: deftest : testing : is} :spec.eca.macros)

(deftest canonical-config-lint-diagnostics
  (testing "reports warning findings for canonical form-chain violations with exit 0"
    (let [lines (vim.fn.systemlist "scripts/fennel-extras lint fnl/fennel-extras/config.fnl")
          code  vim.v.shell_error]
      (is (and (= 0
                  code)
               (> (length lines) 0)))))

  (testing "reports structured form-chain findings instead of crashing"
    (let [lines (vim.fn.systemlist "scripts/fennel-extras lint fnl/fennel-extras/config.fnl")]
      (is (string.match (or (. lines 1) "") "form%-chain: form is outside the allowed form chain")))))
