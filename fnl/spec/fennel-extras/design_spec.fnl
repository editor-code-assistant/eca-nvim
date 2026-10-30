(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(local config (require :fennel-extras.config))
(local identity (require :fennel-extras.lint.identity))
(local rules (require :fennel-extras.lint.rules))

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

(defn- findings-for
  [source policy]
  (let [(forms error) (identity.forms source "fnl/app.fnl")]
    (if error
      []
      (icollect [_ finding (ipairs (rules.check "fnl/app.fnl"
                                                forms
                                                policy
                                                source))]
        [finding.rule finding.form finding.severity]))))

(deftest design-configuration

  (testing "top-level design accepts the lint vector-instance rule schema"
    (let [result (validation {:design {:rules {:function-shape [{:severity   "warning"
                                                                 :applies-to {:files ["^fnl/"] :forms ["defn" "defn-" "fn" "lambda" "λ"]}
                                                                 :options    {}
                                                                 :exclusions []}]}}})]
      (is (and (. result :ok)
               (. result :value)
               (. (. result :value) :design :rules :function-shape 1 :applies-to :forms)))))

  (testing "design owns the structural rule keys"
    (let [instance {:severity   "warning"
                    :applies-to {:forms ["if"]}
                    :options    {}
                    :exclusions []}
          result   (validation {:design {:rules {:function-shape   [instance]
                                                 :if-branch-call   [instance]
                                                 :if-without-else  [instance]
                                                 :nested-forms     [instance]
                                                 :leading-bindings [instance]
                                                 :no-mutation      [instance]}}})]
      (is (and (. result :ok) (. result :value))))))

(deftest lint-design-separation

  (testing "structural rule keys are absent from lint rules"
    (each [name (ipairs ["function-shape" "if-branch-call" "if-without-else" "nested-forms" "leading-bindings" "no-mutation"])]
      (let [instance {:severity   "warning"
                      :applies-to {}
                      :options    {:forms ["if"]}
                      :exclusions []}
            rules    {}
            _        (tset rules name [instance])
            result   (validation {:lint {:rules rules}})]
        (is (and (not (. result :ok))
                 (= (.. "unknown lint rule: " name) (error-message result))))))))

(deftest design-finding-compatibility

  (testing "design findings preserve function-shape identity and severity"
    (is (= [["function-shape" "fnl/app.fnl > defn:run > if#1 > then > if#1" "warning"]]
           (findings-for "(defn run [] (if x (if y a b) c))"
                         {:function-shape [{:severity   "warning"
                                            :applies-to {:forms ["defn" "defn-" "fn" "lambda" "λ"]}
                                            :options    {}
                                            :exclusions []}]}))))

  (testing "design findings preserve if-branch-call identity and severity"
    (is (= [["if-branch-call" "fnl/app.fnl > defn:run > if#1 > then" "warning"]]
           (findings-for "(defn run [] (if ok (do a b) c))"
                         {:if-branch-call [{:severity   "warning"
                                            :applies-to {:forms ["if"]}
                                            :options    {}
                                            :exclusions []}]}))))

  (testing "design findings preserve if-without-else identity and severity"
    (is (= [["if-without-else" "fnl/app.fnl > defn:run > if#1" "warning"]]
           (findings-for "(defn run [] (if ok value))"
                         {:if-without-else [{:severity   "warning"
                                             :applies-to {:forms ["if"]}
                                             :options    {:nil-else true}
                                             :exclusions []}]})))))
