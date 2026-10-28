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



(deftest canonical-rule-shape



  (testing "rules use keyword keys and non-empty vectors of instances"
    (let [result (validation {:lint {:rules {:if-without-else [{:severity   "warning"
                                                                :applies-to {}
                                                                :options    {:forms ["if"] :nil-else true}
                                                                :exclusions []}]}}})]
      (is (and (. result :ok) (. result :value)))))



  (testing "a top-level spec-files key is rejected"
    (let [result (validation {:lint {:spec-files ["^spec/"] :rules {}}})]
      (is (and (not (. result :ok))
               (= "unknown lint key: spec-files" (error-message result)))))))

(deftest canonical-applies-to



  (testing "files, forms, and modules are accepted"
    (let [result (validation {:lint {:rules {:forbidden-form [{:severity   "warning"
                                                               :applies-to {:files   ["^fnl/"]
                                                                            :forms   ["require"]
                                                                            :modules ["plenary.busted"]}
                                                               :options    {:module "require"}
                                                               :exclusions []}]}}})]
      (is (and (. result :ok) (. result :value)))))



  (testing "contexts is rejected"
    (let [result (validation {:lint {:rules {:forbidden-form [{:severity   "warning"
                                                               :applies-to {:contexts ["all"]}
                                                               :options    {:module "require"}
                                                               :exclusions []}]}}})]
      (is (and (not (. result :ok))
               (= "unknown applies-to key: contexts"
                  (error-message result)))))))