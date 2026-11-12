(import-macros {: deftest : testing : is} :spec.eca.macros)
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
            [finding.rule finding.form finding.severity]))

(deftest defaults
  (testing "all retained lint rules are off by default"
    (is (= 6
           (length (vim.tbl_keys (rules.defaults)))))))

(deftest forbidden-form
  (testing "forbids a selected module target"
    (let [policy {:forbidden-form [{:severity   "warning"
                                    :applies-to {:modules "plenary.busted"}
                                    :options    {}
                                    :exclusions []}]}
          result (identities (findings-for "(require :plenary.busted)\n(local value 1)"
                                           "fnl/spec/one.fnl"
                                           policy))]
      (is (= [["forbidden-form" "fnl/spec/one.fnl > top#1" "warning"]]
             result))))

  (testing "forbids selected executable forms"
    (let [policy {:forbidden-form [{:severity   "warning"
                                    :applies-to {:forms ["var" "set" "while"]}
                                    :options    {}
                                    :exclusions []}]}
          result (identities (findings-for "(var x 1)" "fnl/app.fnl" policy))]
      (is (= [["forbidden-form" "fnl/app.fnl > top#1" "warning"]]
             result)))))

(deftest rule-instance-description
  (testing "propagates description without changing rule form or instance identity"
    (let [policy  {:forbidden-form [{:severity    "warning"
                                     :description "explain this rule"
                                     :applies-to  {:forms ["var"]}
                                     :options     {}
                                     :exclusions  []}]}
          result  (findings-for "(var x 1)" "fnl/app.fnl" policy)
          finding (. result 1)]
      (is (= {:description "explain this rule"
              :rule        "forbidden-form"
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
      (is (= [["module-import" "fnl/app.fnl > local:c" "error"]]
             result))))

  (testing "forbids direct test-library requires"
    (let [policy {:module-import [{:severity   "error"
                                   :applies-to {:modules ["plenary.busted"]}
                                   :options    {:mode "forbid"}
                                   :exclusions [{:path "^fnl/spec/"}]}]}
          result (identities (findings-for "(require :plenary.busted)"
                                           "fnl/spec/app_spec.fnl"
                                           policy))]
      (is (= [["module-import" "fnl/spec/app_spec.fnl > top#1" "error"]]
             result)))))

(deftest required-form
  (testing "reports a missing top-level form"
    (let [policy {:required-form [{:severity   "error"
                                   :applies-to {:forms ["module"]}
                                   :options    {}
                                   :exclusions []}]}
          result (identities (findings-for "(local value 1)" "fnl/app.fnl" policy))]
      (is (= [["required-form" "fnl/app.fnl > file" "error"]]
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
      (is (= [["child-count" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
             result)))))

(deftest recursive-child-count
  (testing "named child-count traverses nested fn forms"
    (let [policy {:child-count [{:severity   "error"
                                 :applies-to {:forms ["or"]}
                                 :options    {:children  ["when"]
                                              :max-count 0}
                                 :exclusions []}]}
          result (identities (findings-for "(defn run [] (or (fn [] (when condition result))))"
                                           "fnl/app.fnl"
                                           policy))]
      (is (= [["child-count" "fnl/app.fnl > defn:run > or#1" "error"]]
             result))))

  (testing "not-counted filtering happens after recursive collection"
    (let [policy {:child-count [{:severity   "warning"
                                 :applies-to {:forms ["if"]}
                                 :options    {:min-count   3
                                              :max-count   3
                                              :not-counted ["true"]}
                                 :exclusions []}]}
          result (identities (findings-for "(defn run [] (if condition (fn [] true) fallback))"
                                           "fnl/app.fnl"
                                           policy))]
      (is (= []
             result))))

  (testing "named child-count ignores quoted nested forms"
    (let [policy {:child-count [{:severity   "error"
                                 :applies-to {:forms ["or"]}
                                 :options    {:children  ["when"]
                                              :max-count 0}
                                 :exclusions []}]}
          result (identities (findings-for "(defn run [] (or '(when condition result)))"
                                           "fnl/app.fnl"
                                           policy))]
      (is (= []
             result))))

  (testing "a private function call inside or remains a clean child-count case"
    (let [policy {:child-count [{:severity   "error"
                                 :applies-to {:forms ["or"]}
                                 :options    {:children  ["when"]
                                              :max-count 0}
                                 :exclusions []}]}
          result (identities (findings-for "(defn- some-fn [] value)\n(defn run [] (or (some-fn)))"
                                           "fnl/app.fnl"
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
      (is (= [["child-count" "fnl/app.fnl > defn:run > if#1" "warning"]]
             (finding "(defn run [] (if ok value))"))))

    (testing "rejects an if with a literal nil else"
      (is (= [["child-count" "fnl/app.fnl > defn:run > if#1" "warning"]]
             (finding "(defn run [] (if ok value nil))"))))

    (testing "rejects an if with multiple clauses"
      (is (= [["child-count" "fnl/app.fnl > defn:run > if#1" "warning"]]
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
        (is (= [["child-count" "fnl/app.fnl > defn:run > if#1" "warning"]]
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
      (is (= [["child-count" "fnl/app.fnl > defn:run > if#1" "warning"]]
             (finding "(defn run [] (if ok true fallback))"))))

    (testing "excludes literal false from the direct count"
      (is (= [["child-count" "fnl/app.fnl > defn:run > if#1" "warning"]]
             (finding "(defn run [] (if ok false fallback))"))))

    (testing "excludes literal nil from the direct count"
      (is (= [["child-count" "fnl/app.fnl > defn:run > if#1" "warning"]]
             (finding "(defn run [] (if ok value nil))"))))

    (testing "preserves two counted branches"
      (is (= []
             (finding "(defn run [] (if ok value fallback))"))))

    (testing "enforces the maximum of two counted branches"
      (is (= [["child-count" "fnl/app.fnl > defn:run > if#1" "warning"]]
             (finding "(defn run [] (if ok value fallback extra))"))))))
