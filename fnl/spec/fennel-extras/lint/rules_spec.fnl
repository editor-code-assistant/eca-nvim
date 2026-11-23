(import-macros {: deftest : testing : is} :fennel-extras.macros.test)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(local identity (require :fennel-extras.lint.identity))
(local rules (require :fennel-extras.lint.rules))

(defn- findings-for
  [source path policy]
  (let [(forms error) (identity.forms source path)]
    (if error
      []
      (rules.check path forms policy source))))

(defn- identities
  [findings]
  (icollect [_ finding (ipairs findings)]
    [finding.rule finding.form]))

(deftest defaults
  (testing "all retained lint rules are off by default"
    (is (= 5
          (length (vim.tbl_keys (rules.defaults)))))))

(deftest rule-instance-description
  (testing "propagates description without changing rule form or instance identity"
    (let [policy  {:form-chain [{:severity    "warning"
                                 :description "explain this rule"
                                 :applies-to  {:forms ["var"]}
                                 :options     {:allowed-chains []}
                                 :exclusions  []}]}
          result  (findings-for "(var x 1)" "fnl/app.fnl" policy)
          finding (. result 1)]
      (is (= {:description "explain this rule"
              :rule        "form-chain"
              :form        "fnl/app.fnl > top#1"
              :instance    1}
            {:description finding.description
             :rule        finding.rule
             :form        finding.form
             :instance    finding.instance})))))

(deftest module-import
  (testing "requires the canonical core binding"
    (let [policy {:module-import [{:severity   "error"
                                   :applies-to {:modules "eca.nfnl.core"}
                                   :options    {:mode    "require"
                                                :binding "core"}
                                   :exclusions []}]}
          result (identities (findings-for "(local c (require :eca.nfnl.core))"
                               "fnl/app.fnl"
                               policy))]
      (is (= [["module-import" "fnl/app.fnl > local:c"]]
            result))))

  (testing "forbids direct test-library requires"
    (let [policy {:module-import [{:severity   "error"
                                   :applies-to {:modules ["plenary.busted"]}
                                   :options    {:mode "forbid"}
                                   :exclusions [{:path "^fnl/spec/"}]}]}
          result (identities (findings-for "(require :plenary.busted)"
                               "fnl/spec/app_spec.fnl"
                               policy))]
      (is (= [["module-import" "fnl/spec/app_spec.fnl > top#1"]]
            result)))))

(deftest required-form
  (testing "reports a missing top-level form"
    (let [policy {:required-form [{:severity   "error"
                                   :applies-to {:forms ["module"]}
                                   :options    {}
                                   :exclusions []}]}
          result (identities (findings-for "(local value 1)" "fnl/app.fnl" policy))]
      (is (= [["required-form" "fnl/app.fnl > file"]]
            result))))

  (testing "accepts a compliant top-level form"
    (let [policy {:required-form [{:severity   "error"
                                   :applies-to {:forms ["module"]}
                                   :options    {}
                                   :exclusions []}]}
          result (identities (findings-for "(module app)" "fnl/app.fnl" policy))]
      (is (= []
            result)))))

(deftest migrated-child-count
  (testing "canonical child-count preserves named testing child checks"
    (let [policy {:child-count [{:severity   "error"
                                 :applies-to {:forms ["testing"]}
                                 :options    {:children  ["is"]
                                              :max-count 1}
                                 :exclusions []}]}
          result (identities (findings-for "(deftest run (testing \"x\" (is a) (is b)))"
                               "fnl/spec/app_spec.fnl"
                               policy))]
      (is (= [["child-count" "fnl/spec/app_spec.fnl > deftest:run > testing#1"]]
            result)))))

(deftest canonical-or-child-count
  (testing "canonical child-count reports or forms with more than one equality child"
    (let [policy {:child-count [{:severity   "info"
                                 :applies-to {:files ["^fennel-extras/"]
                                              :forms ["or"]}
                                 :options    {:children  ["="]
                                              :max-count 1}
                                 :exclusions []}]}
          result (identities (findings-for "(or (= a 1) (= b 2))"
                               "fennel-extras/app.fnl"
                               policy))]
      (is (= [["child-count" "fennel-extras/app.fnl > top#1"]]
            result))))

  (testing "canonical child-count allows one equality child"
    (let [policy {:child-count [{:severity   "info"
                                 :applies-to {:files ["^fennel-extras/"]
                                              :forms ["or"]}
                                 :options    {:children  ["="]
                                              :max-count 1}
                                 :exclusions []}]}
          result (identities (findings-for "(or (= a 1) predicate)"
                               "fennel-extras/app.fnl"
                               policy))]
      (is (= []
             result)))))

(deftest direct-child-arity
  (let [policy  {:child-count [{:severity   "warning"
                                :applies-to {:forms ["if"]}
                                :options    {:min-count 2
                                             :max-count 2
                                             :nil-count false}
                                :exclusions []}]}
        finding (fn [source]
                  (identities (findings-for source "fnl/app.fnl" policy)))]

    (testing "rejects an if with no else"
      (is (= [["child-count" "fnl/app.fnl > defn:run > if#1"]]
            (finding "(defn run [] (if ok value))"))))

    (testing "rejects an if with a literal nil else"
      (is (= [["child-count" "fnl/app.fnl > defn:run > if#1"]]
            (finding "(defn run [] (if ok value nil))"))))

    (testing "rejects an if with multiple clauses"
      (is (= [["child-count" "fnl/app.fnl > defn:run > if#1"]]
            (finding "(defn run [] (if ok a b c d))"))))

    (testing "rejects a multi-clause if with broad direct bounds"
      (let [broad-policy  {:child-count [{:severity   "warning"
                                          :applies-to {:forms ["if"]}
                                          :options    {:min-count 0
                                                       :max-count 10
                                                       :nil-count true}
                                          :exclusions []}]}
            broad-finding (fn [source]
                            (identities (findings-for source "fnl/app.fnl" broad-policy)))]
        (is (= [["child-count" "fnl/app.fnl > defn:run > if#1"]]
              (broad-finding "(defn run [] (if ok a b c d))")))))

    (testing "allows a normal two-branch if"
      (is (= []
            (finding "(defn run [] (if ok value fallback))"))))))

(deftest direct-child-arity-not-counted
  (let [policy  {:child-count [{:severity   "warning"
                                :applies-to {:forms ["if"]}
                                :options    {:min-count   2
                                             :max-count   2
                                             :not-counted ["nil" "true" "false"]}
                                :exclusions []}]}
        finding (fn [source]
                  (identities (findings-for source "fnl/app.fnl" policy)))]
    (testing "excludes literal true from the direct count"
      (is (= [["child-count" "fnl/app.fnl > defn:run > if#1"]]
            (finding "(defn run [] (if ok true fallback))"))))

    (testing "excludes literal false from the direct count"
      (is (= [["child-count" "fnl/app.fnl > defn:run > if#1"]]
            (finding "(defn run [] (if ok false fallback))"))))

    (testing "excludes literal nil from the direct count"
      (is (= [["child-count" "fnl/app.fnl > defn:run > if#1"]]
            (finding "(defn run [] (if ok value nil))"))))

    (testing "preserves two counted branches"
      (is (= []
            (finding "(defn run [] (if ok value fallback))"))))

    (testing "enforces the maximum of two counted branches"
      (is (= [["child-count" "fnl/app.fnl > defn:run > if#1"]]
            (finding "(defn run [] (if ok value fallback extra))"))))))

(deftest generic-binding
  (let [policy  {:binding [{:severity   "warning"
                            :applies-to {:forms ["let"]}
                            :options    {}
                            :exclusions []}]}
        finding (fn [source]
                  (let [result (findings-for source "fnl/app.fnl" policy)]
                    (icollect [_ item (ipairs result)]
                      {:rule    item.rule
                       :form    item.form
                       :message item.message})))]
    (testing "reports a let with one binding pair and one body expression"
      (is (= [{:rule    "binding"
               :form    "fnl/app.fnl > let#1"
               :message "avoid introducing a local binding for a single body expression"}]
            (finding "(let [value 1] value)"))))

    (testing "allows a let with multiple bindings"
      (is (= []
            (finding "(let [first 1 second 2] first)"))))

    (testing "allows a let with multiple body expressions"
      (is (= []
            (finding "(let [value 1] value (+ value 1))"))))

    (testing "ignores a let inside an explicit quote form"
      (is (= []
            (finding "(quote (let [value 1] value))"))))))
