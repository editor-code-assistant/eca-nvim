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

  (testing "all thirteen lint rules are off by default"
    (is (= 13 (length (vim.tbl_keys (rules.defaults)))))))

(deftest forbidden-form

  (testing "forbids a selected module target"
    (let [policy {:forbidden-form [{:severity   "warning"
                                    :applies-to {:modules "plenary.busted"}
                                    :options    {}
                                    :exclusions []}]}
          result (identities (findings-for "(require :plenary.busted)\n(local value 1)"
                                           "fnl/spec/one.fnl"
                                           policy))]
      (is (= [["forbidden-form" "fnl/spec/one.fnl > top#1" "warning"]] result))))

  (testing "forbids selected executable forms"
    (let [policy {:forbidden-form [{:severity   "warning"
                                    :applies-to {:forms ["var" "set" "while"]}
                                    :options    {}
                                    :exclusions []}]}
          result (identities (findings-for "(var x 1)" "fnl/app.fnl" policy))]
      (is (= [["forbidden-form" "fnl/app.fnl > top#1" "warning"]] result)))))

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
      (is (= [["module-import" "fnl/app.fnl > local:c" "error"]] result))))

  (testing "forbids direct test-library requires"
    (let [policy {:module-import [{:severity   "error"
                                   :applies-to {:modules ["plenary.busted"]}
                                   :options    {:mode         "forbid"
                                                :exempt-files []}
                                   :exclusions []}]}
          result (identities (findings-for "(require :plenary.busted)"
                                           "fnl/spec/app_spec.fnl"
                                           policy))]
      (is (= [["module-import" "fnl/spec/app_spec.fnl > top#1" "error"]] result)))))

(deftest required-form

  (testing "reports a missing top-level form"
    (let [policy {:required-form [{:severity   "error"
                                   :applies-to {:forms ["module"]}
                                   :options    {}
                                   :exclusions []}]}
          result (identities (findings-for "(local value 1)" "fnl/app.fnl" policy))]
      (is (= [["required-form" "fnl/app.fnl > file" "error"]] result))))

  (testing "accepts a compliant top-level form"
    (let [policy {:required-form [{:severity   "error"
                                   :applies-to {:forms ["module"]}
                                   :options    {}
                                   :exclusions []}]}
          result (identities (findings-for "(module app)" "fnl/app.fnl" policy))]
      (is (= [] result)))))
