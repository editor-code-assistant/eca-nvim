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
                                                     :modules      ["plenary.busted"]
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
                                                                 :options    {:module "module"}
                                                                 :exclusions []}]
                                             :module-import    [{:severity   "error"
                                                                 :applies-to {:files ["^spec/"]}
                                                                 :options    {:mode         "forbid"
                                                                              :modules      ["plenary.busted" "luassert"]
                                                                              :exempt-files ["^spec/eca/macros[.]fnlm$"]}
                                                                 :exclusions []}
                                                                {:severity   "error"
                                                                 :applies-to {}
                                                                 :options    {:mode    "require"
                                                                              :module  "eca.nfnl.core"
                                                                              :binding "core"}
                                                                 :exclusions []}]
                                             :required-form    [{:severity   "error"
                                                                 :applies-to {:files ["^spec/"]}
                                                                 :options    {:forms ["module"]}
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
                                                              :applies-to {}
                                                              :options    {:mode    "require"
                                                                           :module  "eca.nfn.core"
                                                                           :binding "core"}
                                                              :exclusions []}]}}})]
      (is (and (. result :ok)
               (= "require" (. result :value :lint :rules :module-import 1 :options :mode))
               (= "core" (. result :value :lint :rules :module-import 1 :options :binding)))))))