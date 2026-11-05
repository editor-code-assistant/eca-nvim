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

  (testing "path, code, form, and reason selectors are accepted as strings"
    (let [result (validation {:lint {:rules {:if-branch-call [{:severity   "warning"
                                                               :applies-to {:forms ["if"]}
                                                               :options    {}
                                                               :exclusions [{:path   "^spec/"
                                                                             :code   "^[(]if"
                                                                             :form   "spec/app.fnl > if#1"
                                                                             :reason "intentional"}]}]}}})]
      (is (and (. result :ok) (. result :value)))))

  (testing "exclusion selectors require string values"
    (let [result (validation {:lint {:rules {:if-branch-call [{:severity   "warning"
                                                               :applies-to {:forms ["if"]}
                                                               :options    {}
                                                               :exclusions [{:path   ["^spec/"]
                                                                             :code   true
                                                                             :form   1
                                                                             :reason "intentional"}]}]}}})]
      (is (and (not (. result :ok))
               (= "lint.rules.if-branch-call[1].exclusions[1] requires string path and reason; optional code and form must be strings"
                  (error-message result)))))))