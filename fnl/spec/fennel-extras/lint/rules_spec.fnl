(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(local identity (require :fennel-extras.lint.identity))

(defn- load-rules
  []
  (let [(ok result) (pcall require :fennel-extras.lint.rules)]
    (if ok
      result
      {:module-missing true})))



(defn- sort-severities
  [entries]
  (table.sort entries (fn [a b] (< (. a 1) (. b 1))))


  entries)



(defn- default-severities
  []
  (let [rules (load-rules)]
    (if (. rules :module-missing)
      rules
      (let [defaults (rules.defaults)
            entries  (icollect [rule severity (pairs defaults)]
                       [rule severity])]
        (sort-severities entries)))))



(deftest defaults



  (testing "all sixteen lint rules are off by default"
    (is (= [["binding-per-line" "off"]
            ["call-data-arg" "off"]
            ["control-layout" "off"]
            ["direct-require" "off"]
            ["file-size" "off"]
            ["forbidden-form" "off"]
            ["form-child-count" "off"]
            ["function-shape" "off"]
            ["if-branch-call" "off"]
            ["if-without-else" "off"]
            ["macro-import" "off"]
            ["module-style" "off"]
            ["multiline-layout" "off"]
            ["no-module" "off"]
            ["no-mutation" "off"]
            ["unused-and-or" "off"]]
           (let [entries (default-severities)]
             (if (. entries :module-missing)
               entries
               (sort-severities entries)))))))

(defn- all-enabled-policy
  []
  {:direct-require [{:severity   "error"
                     :applies-to {}
                     :options    {:mode    "require"
                                  :module  "eca.nfnl.core"
                                  :binding "core"}
                     :exclusions []}]})



(defn- direct-require-scenario
  []
  (let [source        "(local c (require :eca.nfnl.core))"
        path          "fnl/app.fnl"
        policy        (all-enabled-policy)
        (forms error) (identity.forms source path)]
    (if error
      {:error error}
      (let [before   (icollect [_ form (ipairs forms)] form.form)
            rules    (load-rules)
            findings (rules.check path forms policy source)
            after    (icollect [_ form (ipairs forms)] form.form)]
        {:before before :after after :findings findings}))))



(defn- direct-require-identities
  [scenario]
  (icollect [_ finding (ipairs scenario.findings)]
    (when (= finding.rule "direct-require")
      [finding.rule finding.form finding.severity])))



(defn- forbidden-form-scenario
  []
  (let [source        "(require :plenary.busted)\n(local value 1)"
        path          "fnl/spec/one.fnl"
        policy        {:forbidden-form [{:severity   "warning"
                                         :applies-to {:files ["fnl/spec/one.fnl"]
                                                      :forms ["require"]}
                                         :options    {:module "plenary.busted"}
                                         :exclusions []}]}
        (forms error) (identity.forms source path)]
    (if error
      {:error error}
      (let [rules (load-rules)]
        {:findings (rules.check path forms policy source)}))))



(defn- forbidden-form-identities
  [scenario]
  (icollect [_ finding (ipairs scenario.findings)]
    [finding.rule finding.form finding.severity]))



(deftest forbidden-form



  (testing "reports the selected form head with the generic rule identity"
    (is (= [["forbidden-form" "fnl/spec/one.fnl > top#1" "warning"]]
           (forbidden-form-identities (forbidden-form-scenario)))))



  (testing "filters require, import, and module targets by canonical modules"
    (let [source        "(require :plenary.busted)\\n(import :plenary.busted)\\n(module plenary.busted)\\n(require :luassert)"
          path          "fnl/spec/one.fnl"
          policy        {:forbidden-form [{:severity   "warning"
                                           :applies-to {:files ["fnl/spec/one.fnl"]
                                                        :forms ["require" "import" "module"]
                                                        :mode "forbid" :mode "forbid" :modules ["plenary.busted"]}
                                           :options    {}
                                           :exclusions []}]}
          (forms error) (identity.forms source path)
          rules         (load-rules)]
      (is (= [["forbidden-form" "fnl/spec/one.fnl > top#1" "warning"]
              ["forbidden-form" "fnl/spec/one.fnl > top#2" "warning"]
              ["forbidden-form" "fnl/spec/one.fnl > module:plenary.busted" "warning"]]
             (forbidden-form-identities
              {:findings (if error
                           []
                           (rules.check path forms policy source))}))))))

(deftest lint-rules-check



  (testing "does not mutate identity forms"
    (let [scenario (direct-require-scenario)]
      (is (= scenario.before scenario.after))))



  (testing "reports the direct-require finding with its established identity"
    (is (= [["direct-require" "fnl/app.fnl > local:c" "error"]]
           (direct-require-identities (direct-require-scenario))))))
