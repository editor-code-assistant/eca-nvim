(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(local config (require :fennel-extras.config))

(defn- validation
  [value]
  (let [(ok result error) (pcall config.validate value)]
    {:ok (and ok result) :value result :error error}))

(defn- error-message
  [result]
  (let [error (. result :error)]
    (if (= :table (type error))
      (. error :message)
      error)))

(local canonical-rule
       {:lint {:rules {:module-import [{:severity   "error"
                                        :applies-to {:files   ["^spec/"]
                                                     :forms   ["require"]
                                                     :modules ["plenary.busted"]}
                                        :options    {:mode         "forbid"
                                                     :exempt-files ["^spec/eca/macros[.]fnlm$"]}
                                        :exclusions []}]}}})

(deftest canonical-applies-to-contract

  (testing "rule instances with files, forms, and modules validate"
    (let [result (validation canonical-rule)]
      (is (and (. result :ok)
               (not= nil (. result :value))))))

  (testing "contexts is rejected as an unknown applies-to key"
    (let [result (validation {:lint {:rules {:module-import [{:severity   "error"
                                                              :applies-to {:contexts ["spec"]}
                                                              :options    {:mode         "forbid"
                                                                           :modules      ["plenary.busted"]
                                                                           :exempt-files ["^spec/eca/macros[.]fnlm$"]}
                                                              :exclusions []}]}}})]
      (is (and (not (. result :ok))
               (= nil (. result :value))
               (= "unknown applies-to key: contexts" (error-message result)))))))

(deftest canonical-spec-file-contract

  (testing "top-level lint spec-files is absent from the canonical contract"
    (let [result (validation {:lint {:spec-files ["^spec/"] :rules {}}})]
      (is (and (not (. result :ok))
               (= nil (. result :value))
               (= "unknown lint key: spec-files" (error-message result))))))

  (testing "spec-only behavior uses explicit file regexes"
    (let [result (validation canonical-rule)
          value  (. result :value)]
      (is (and (. result :ok)
               value
               (= nil (. value :lint :spec-files))
               (vim.deep_equal ["^spec/"]
                               (. value :lint :rules :module-import 1 :applies-to :files)))))))

(deftest generic-rule-contract

  (testing "generic rules and form-child-count validate"
    (let [result (validation {:lint {:rules {:forbidden-form   [{:severity   "error"
                                                                 :applies-to {:files ["^spec/"]}
                                                                 :options    {}
                                                                 :exclusions []}]
                                             :module-import    [{:severity   "error"
                                                                 :applies-to {:files   ["^spec/"]
                                                                              :modules ["plenary.busted" "luassert"]}
                                                                 :options    {:mode         "forbid"
                                                                              :exempt-files ["^spec/eca/macros[.]fnlm$"]}
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
               (= "require" (. result :value :lint :rules :module-import 1 :options :mode))
               (= "core" (. result :value :lint :rules :module-import 1 :options :binding)))))))
(deftest migrated-canonical-config-contract

  (testing "selector values live under applies-to and not under options"
    (let [result (validation {:lint {:rules {:module-import [{:severity   "error"
                                                              :applies-to {:forms   ["require"]
                                                                           :modules ["plenary.busted"]}
                                                              :options    {:mode         "forbid"
                                                                           :exempt-files ["^spec/"]}
                                                              :exclusions []}]}}})]
      (is (and (. result :ok)
               (vim.deep_equal ["require"] (. result :value :lint :rules :module-import 1 :applies-to :forms))
               (vim.deep_equal ["plenary.busted"] (. result :value :lint :rules :module-import 1 :applies-to :modules))
               (= nil (. result :value :lint :rules :module-import 1 :options :forms))
               (= nil (. result :value :lint :rules :module-import 1 :options :modules))))))

  (testing "the old selector option locations are rejected"
    (each [_ options (ipairs [{:forms ["if"]} {:module "module"} {:modules ["luassert"]}])]
      (let [result (validation {:lint {:rules {:forbidden-form [{:severity   "warning"
                                                                 :applies-to {}
                                                                 :options    options
                                                                 :exclusions []}]}}})]
        (is (not (. result :ok)))))))

(testing "the canonical source keeps rule vectors inline and has no empty forbidden-form placeholder"
  (let [file   (assert (io.open ".fnl-extras.fnl" :r))
        source (file:read "*a")]
    (file:close)
    (is (and (string.find source ":lint")
             (string.find source ":rules")
             (string.find source ":forbidden%-form%s+%[%{")
             (not (string.find source ":forbidden%-form%s+%[%{:%s*severity%s+:%s*off%s+%}%]"))))))
