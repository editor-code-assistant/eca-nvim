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
  (let [policy   {:child-count [{:severity   "info"
                                 :applies-to {:files ["^fennel-extras/"]
                                              :forms ["or"]}
                                 :options    {:children  ["="]
                                              :max-count 1
                                              :direct    true}
                                 :exclusions []}]}
        findings (fn [source]
                   (findings-for source "fennel-extras/app.fnl" policy))]
    (testing "canonical child-count reports or forms with two direct equality children"
      (is (= [["child-count" "fennel-extras/app.fnl > top#1"]]
            (identities (findings "(or (= a 1) (= b 2))")))))

    (testing "canonical child-count uses the form name in its message"
      (let [result (findings "(or (= a 1) (= b 2))")]
        (is (= "or has an invalid child count"
              (. (. result 1) :message)))))

    (testing "canonical child-count allows one direct equality child"
      (is (= []
            (identities (findings "(or (= a 1) predicate)")))))

    (testing "canonical direct child-count ignores nested equality inside another child form"
      (is (= []
            (identities (findings "(or (and (= a 1)) (= b 2))")))))))

(deftest child-count-mode-combinations
  (testing "counts named children recursively when direct is omitted"
    (let [policy {:child-count [{:severity   "warning"
                                 :applies-to {:forms ["target"]}
                                 :options    {:children  ["="]
                                              :max-count 1}
                                 :exclusions []}]}
          result (identities (findings-for "(target (wrapper (= a 1)) (= b 2))"
                               "fnl/app.fnl"
                               policy))]
      (is (= [["child-count" "fnl/app.fnl > top#1"]]
            result))))

  (testing "counts only immediate named children when direct is true"
    (let [policy {:child-count [{:severity   "warning"
                                 :applies-to {:forms ["target"]}
                                 :options    {:children  ["="]
                                              :max-count 1
                                              :direct    true}
                                 :exclusions []}]}
          result (identities (findings-for "(target (wrapper (= a 1)) (= b 2))"
                               "fnl/app.fnl"
                               policy))]
      (is (= []
            result))))

  (testing "uses direct arity bounds when children and direct are omitted"
    (let [policy {:child-count [{:severity   "warning"
                                 :applies-to {:forms ["if"]}
                                 :options    {:min-count 2
                                              :max-count 2
                                              :nil-count false}
                                 :exclusions []}]}
          result (identities (findings-for "(if ok value)"
                               "fnl/app.fnl"
                               policy))]
      (is (= [["child-count" "fnl/app.fnl > top#1"]]
            result))))

  (testing "uses the same direct arity bounds when direct is true"
    (let [policy {:child-count [{:severity   "warning"
                                 :applies-to {:forms ["if"]}
                                 :options    {:min-count 2
                                              :max-count 2
                                              :nil-count false
                                              :direct    true}
                                 :exclusions []}]}
          result (identities (findings-for "(if ok value)"
                               "fnl/app.fnl"
                               policy))]
      (is (= [["child-count" "fnl/app.fnl > top#1"]]
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

(deftest child-count-bound-combinations
  (testing "accepts a direct minimum-only bound"
    (let [policy {:child-count [{:severity   "warning"
                                 :applies-to {:forms ["target"]}
                                 :options    {:min-count 2}
                                 :exclusions []}]}
          result (identities (findings-for "(target one two three)" "fnl/app.fnl" policy))]
      (is (= []
            result))))

  (testing "accepts a direct maximum-only bound"
    (let [policy {:child-count [{:severity   "warning"
                                 :applies-to {:forms ["target"]}
                                 :options    {:max-count 2}
                                 :exclusions []}]}
          result (identities (findings-for "(target one two three)" "fnl/app.fnl" policy))]
      (is (= [["child-count" "fnl/app.fnl > top#1"]]
            result))))

  (testing "accepts named minimum-only bound"
    (let [policy {:child-count [{:severity   "warning"
                                 :applies-to {:forms ["target"]}
                                 :options    {:children ["item"] :min-count 2}
                                 :exclusions []}]}]
      (is (= []
            (identities (findings-for "(target (item) (item))" "fnl/app.fnl" policy))))))
  (testing "accepts named maximum-only bound"
    (let [policy {:child-count [{:severity   "warning"
                                 :applies-to {:forms ["target"]}
                                 :options    {:children ["item"] :max-count 1}
                                 :exclusions []}]}]
      (is (= [["child-count" "fnl/app.fnl > top#1"]]
            (identities (findings-for "(target (item) (item))" "fnl/app.fnl" policy))))))

)

(deftest nested-cond-identities
  (is (= ["fnl/app.fnl > top#1"
          "fnl/app.fnl > top#1 > cond#1"]
        (icollect [_ item (ipairs (identity.forms "(target (cond ok value))" "fnl/app.fnl"))]
          item.form))))
