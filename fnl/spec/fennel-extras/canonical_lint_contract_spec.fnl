(import-macros {: deftest : testing : is} :fennel-extras.macros.test)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(local config (require :fennel-extras.config))
(local registry (require :fennel-extras.lint.rules.registry))

(defn- validation
  [value]
  (let [(ok result error) (pcall config.validate value)]
    {:ok (and ok result) :value result :error error}))

(defn- error-message
  [result]
  (let [error (. result :error)]
    (if (= :table
           (type error))
      (. error :message)
      error)))

(local canonical-rule
       {:lint {:rules {:module-import [{:severity   "error"
                                        :applies-to {:files   ["^spec/"]
                                                     :forms   ["require"]
                                                     :modules ["plenary.busted"]}
                                        :options    {:mode "forbid"}
                                        :exclusions [{:path "^fennel-extras/macros/test[.]fnlm$"}]}]}}})

(deftest canonical-applies-to-contract
  (testing "rule instances with files, forms, and modules validate"
    (let [result (validation canonical-rule)]
      (is (and (. result :ok)
               (not= nil (. result :value))))))

  (testing "contexts is rejected as an unknown applies-to key"
    (let [result (validation {:lint {:rules {:module-import [{:severity   "error"
                                                              :applies-to {:contexts ["spec"]}
                                                              :options    {:mode    "forbid"
                                                                           :modules ["plenary.busted"]}
                                                              :exclusions [{:path "^fennel-extras/macros/test[.]fnlm$"}]}]}}})]
      (is (and (not (. result :ok))
               (= nil
                  (. result :value))
               (= "unknown applies-to key: contexts"
                  (error-message result)))))))

(deftest canonical-spec-file-contract
  (testing "top-level lint spec-files is absent from the canonical contract"
    (let [result (validation {:lint {:spec-files ["^spec/"] :rules {}}})]
      (is (and (not (. result :ok))
               (= nil
                  (. result :value))
               (= "unknown lint key: spec-files"
                  (error-message result))))))

  (testing "spec-only behavior uses explicit file regexes"
    (let [result (validation canonical-rule)
          value  (. result :value)]
      (is (and (. result :ok)
               value
               (= nil
                  (. value :lint :spec-files))
               (vim.deep_equal ["^spec/"]
                               (. value :lint :rules :module-import 1 :applies-to :files)))))))

(deftest generic-rule-contract
  (testing "generic rules and form-child-count validate"
    (let [result (validation {:lint {:rules {:module-import    [{:severity   "error"
                                                                 :applies-to {:files   ["^spec/"]
                                                                              :modules ["plenary.busted" "luassert"]}
                                                                 :options    {:mode         "forbid"
                                                                              }
                                                                 :exclusions []}
                                                                {:severity   "error"
                                                                 :applies-to {:modules "eca.nfnl.core"}
                                                                 :options    {:mode    "require"
                                                                              :binding "core"}
                                                                 :exclusions []}]
                                             :required-form    [{:severity   "error"
                                                                 :applies-to {:files ["^spec/"] :forms ["module"]}
                                                                 :options    {}
                                                                 :exclusions []}]
                                             :form-child-count [{:severity   "error"
                                                                 :applies-to {:forms ["testing"]}
                                                                 :options    {:children  ["is"]
                                                                              :max-count 1}
                                                                 :exclusions []}]}}})]
      (is (and (. result :ok)
               (. result :value)))))

  (testing "the module-import require instance preserves mode and binding"
    (let [result (validation {:lint {:rules {:module-import [{:severity   "error"
                                                              :applies-to {:modules "eca.nfnl.core"}
                                                              :options    {:mode    "require"
                                                                           :binding "core"}
                                                              :exclusions []}]}}})]
      (is (and (. result :ok)
               (= "require"
                  (. result :value :lint :rules :module-import 1 :options :mode))
               (= "core"
                  (. result :value :lint :rules :module-import 1 :options :binding)))))))
(deftest migrated-canonical-config-contract
  (testing "selector values live under applies-to and not under options"
    (let [result (validation {:lint {:rules {:module-import [{:severity   "error"
                                                              :applies-to {:forms   ["require"]
                                                                           :modules ["plenary.busted"]}
                                                              :options    {:mode "forbid"}
                                                              :exclusions [{:path "^spec/"}]}]}}})]
      (is (and (. result :ok)
               (vim.deep_equal ["require"] (. result :value :lint :rules :module-import 1 :applies-to :forms))
               (vim.deep_equal ["plenary.busted"] (. result :value :lint :rules :module-import 1 :applies-to :modules))
               (= nil
                  (. result :value :lint :rules :module-import 1 :options :forms))
               (= nil
                  (. result :value :lint :rules :module-import 1 :options :modules))))))

  (testing "the old selector option locations are rejected"
    (each [_ options (ipairs [{:forms ["if"]} {:module "module"} {:modules ["luassert"]}])]
          (let [result (validation {:lint {:rules {:module-import [{:severity   "warning"
                                                                    :applies-to {:modules ["module"]}
                                                                    :options    (vim.tbl_extend "force" {:mode "forbid"} options)
                                                                    :exclusions []}]}}})]
            (is (not (. result :ok)))))))

(deftest canonical-source-keeps-rule-vectors-inline
  (testing "the canonical source keeps rule vectors inline and has no empty forbidden-form placeholder"
    (let [file   (assert (io.open ".fnl-extras.fnl" :r))
          source (file:read "*a")]
      (file:close)
      (is (and (string.find source ":lint")
               (string.find source ":rules")
               (not (string.find source "forbidden%-form"))
             ))))
)

(deftest canonical-source-has-no-trailing-blank-lines
  (testing "the canonical source has no trailing blank lines"
    (let [file   (assert (io.open ".fnl-extras.fnl" :r))
          source (file:read "*a")]
      (file:close)
      (is (not (string.find source "\n\n$")))))
)

(deftest canonical-module-selectors-are-vectors
  (let [loaded (config.load ".fnl-extras.fnl")
        rules  (. loaded :lint :rules)]
    (testing "canonical module selectors are vectors"
      (is (and (vim.deep_equal ["eca.nfnl.core"]
                               (. rules :module-import 1 :applies-to :modules))
               (vim.deep_equal ["fennel-extras.macros.test"]
                               (. rules :module-import 2 :applies-to :modules))
               (vim.deep_equal ["plenary.busted" "luassert"]
                               (. rules :module-import 3 :applies-to :modules))
               true)))))

(deftest canonical-module-selector-cardinality
  (testing "module-import require rejects multiple semantic singleton modules"
    (let [result (validation {:lint {:rules {:module-import [{:severity   "error"
                                                              :applies-to {:modules ["one" "two"]}
                                                              :options    {:mode    "require"
                                                                           :binding "one"}
                                                              :exclusions []}]}}})]
      (is (= "lint.rules.module-import[1].applies-to.modules must contain at most one module"
             (error-message result)))))

  (testing "module-import forbid accepts multiple module selectors"
    (let [result (validation {:lint {:rules {:module-import [{:severity   "error"
                                                              :applies-to {:modules ["one" "two"]}
                                                              :options    {:mode "forbid"}
                                                              :exclusions []}]}}})]
      (is (. result :ok))))

  (testing "module-import missing options returns a structured validation error"
    (let [result (validation {:lint {:rules {:module-import [{:severity   "error"
                                                              :applies-to {:modules ["one" "two"]}
                                                              :exclusions []}]}}})]
      (is (= "lint.rules.module-import[1].options must be a table"
             (error-message result)))))

  (testing "module-import non-map options returns a structured validation error"
    (let [result (validation {:lint {:rules {:module-import [{:severity   "error"
                                                              :applies-to {:modules ["one" "two"]}
                                                              :options    "require"
                                                              :exclusions []}]}}})]
      (is (= "lint.rules.module-import[1].options must be a table"
             (error-message result))))))

(deftest migrated-rule-names
  (testing "child-count is canonical and form-child-count remains an accepted alias"
    (each [_ rule (ipairs ["child-count" "form-child-count"])]
          (let [rules  {}
                _      (tset rules rule [{:severity   "error"
                                          :applies-to {:forms ["testing"]}
                                          :options    {:children  ["is"]
                                                       :max-count 1}
                                          :exclusions []}])
                result (validation {:lint {:rules rules}})]
            (is (. result :ok)))))

)

(deftest canonical-config-uses-direct-child-count
  (testing "canonical config uses direct child-count for if arity"
    (let [loaded   (config.load ".fnl-extras.fnl")
          rules    (. loaded :lint :rules)
          instance (. rules :child-count 2)]
      (is (and instance
               (vim.deep_equal {:forms ["if"]} (. instance :applies-to))
               (= 2
                  (. instance :options :min-count))
               (= 2
                  (. instance :options :max-count))
               (vim.deep_equal ["nil" "true" "false"] (. instance :options :not-counted))))))
)

(local removed-rules ["call-data-arg"
                      "module-style"
                      "unused-and-or"
                      "function-shape"
                      "if-branch-call"
                      "nested-forms"
                      "leading-bindings"
                      "no-mutation"
                      "forbidden-form"])

(local retained-rules ["child-count"
                       "module-import"
                       "required-form"
                       "file-size"
                       "form-chain"])

(defn- removed-rule-instance
  []
  {:severity   "warning"
   :applies-to {}
   :options    {}
   :exclusions []})

(deftest canonical-config-removed-rules
  (testing "canonical config omits every removed rule"
    (let [rules (. (config.load ".fnl-extras.fnl") :lint :rules)]
      (is (accumulate [absent true _ rule (ipairs removed-rules)]
                      (and absent (= nil
                                     (. rules rule))))))))

(deftest lint-validation-removed-rules
  (testing "canonical lint config rejects every removed rule name"
    (is (accumulate [valid true _ rule (ipairs removed-rules)]
                    (let [rules  {}
                          _      (tset rules rule [(removed-rule-instance)])
                          result (validation {:lint {:rules rules}})]
                      (and valid
                           (not (. result :ok))
                           (= (.. "unknown lint rule: " rule)
                              (error-message result))))))))

(deftest design-validation-removed-rules
  (testing "canonical design config rejects every removed rule name"
    (is (accumulate [valid true _ rule (ipairs removed-rules)]
                    (let [rules  {}
                          _      (tset rules rule [(removed-rule-instance)])
                          result (validation {:design {:rules rules}})]
                      (and valid
                           (not (. result :ok))
                           (= (.. "unknown design rule: " rule)
                              (error-message result))))))))

(deftest runtime-registry-removed-rules
  (testing "the runtime registry omits removed rules and retains supported rules"
    (let [names    (registry.rule-names)
          defaults (registry.defaults)]
      (is (and (accumulate [absent true _ rule (ipairs removed-rules)]
                           (and absent
                                (= nil
                                   (. defaults rule))
                                (not (vim.tbl_contains names rule))))
               (accumulate [present true _ rule (ipairs retained-rules)]
                           (and present (vim.tbl_contains names rule))))))))
