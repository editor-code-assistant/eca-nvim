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
       {:lint {:rules {:spec-direct-require [{:severity   "error"
                                              :applies-to {:files   ["^spec/"]
                                                           :forms   ["require"]
                                                           :modules ["plenary.busted"]}
                                              :options    {:modules      ["plenary.busted"]
                                                           :exempt-files ["^spec/eca/macros[.]fnlm$"]}
                                              :exclusions []}]}}})

(deftest canonical-applies-to-contract
  (testing "rule instances with files, forms, and modules validate"
    (let [result (validation canonical-rule)]
      (is (and (. result :ok)
               (not= nil (. result :value)) ))))
  (testing "contexts is rejected as an unknown applies-to key"
    (let [result (validation {:lint {:rules {:spec-direct-require [{:severity   "error"
                                                                    :applies-to {:contexts ["spec"]}
                                                                    :options    {:modules      ["plenary.busted"]
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
                               (. value :lint :rules :spec-direct-require 1 :applies-to :files)))))))