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
                                                                             :options    {}
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

(deftest canonical-exclusions

         (testing "path-only exclusions are accepted"
                  (let [result (validation {:lint {:rules {:forbidden-form [{:severity   "warning"
                                                                             :applies-to {:forms ["if"]}
                                                                             :options    {}
                                                                             :exclusions [{:path "^spec/"}]}]}}})]
                    (is (and (. result :ok) (. result :value)))))

         (testing "old exclusion keys are rejected"
                  (let [base     {:severity   "warning"
                                  :applies-to {:forms ["if"]}
                                  :options    {}}
                        keys     [:reason :code :form]
                        rejected (icollect [_ key (ipairs keys)]
                                           (let [exclusion {:path "^spec/"}]
                                             (tset exclusion key "old contract")
                                             (let [result (validation {:lint {:rules {:forbidden-form
                                                                                      [{:severity   base.severity
                                                                                        :applies-to base.applies-to
                                                                                        :options    base.options
                                                                                        :exclusions [exclusion]}]}}})]
                                               (and (not (. result :ok)) (error-message result)))))]
                    (is (= 3 (length rejected)))))

         (testing "non-string path values are rejected"
                  (let [result (validation {:lint {:rules {:forbidden-form [{:severity   "warning"
                                                                             :applies-to {:forms ["if"]}
                                                                             :options    {}
                                                                             :exclusions [{:path ["^spec/"]}]}]}}})]
                    (is (not (. result :ok)))))

         (testing "module-import rejects exempt-files and accepts a path-only exclusion"
                  (let [old-result (validation {:lint {:rules {:module-import [{:severity   "error"
                                                                                :applies-to {:modules ["spec.eca.macros"]}
                                                                                :options    {:mode         "require"
                                                                                             :binding      "macros"
                                                                                             :exempt-files ["^spec/"]}
                                                                                :exclusions []}]}}})
                        new-result (validation {:lint {:rules {:module-import [{:severity   "error"
                                                                                :applies-to {:modules ["spec.eca.macros"]}
                                                                                :options    {:mode    "require"
                                                                                             :binding "macros"}
                                                                                :exclusions [{:path "^spec/eca/macros[.]fnlm$"}]}]}}})]
                    (is (and (not (. old-result :ok)) (. new-result :ok) (. new-result :value))))))