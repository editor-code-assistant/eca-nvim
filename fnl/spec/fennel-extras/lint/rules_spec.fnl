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
  (testing "all thirteen lint rules have the approved default severities"
    (is (= [["core-require" "error"]
            ["defn-args-newline" "warning"]
            ["file-size" "warning"]
            ["function-shape" "warning"]
            ["if-branch-call" "warning"]
            ["if-without-else" "warning"]
            ["module-style" "error"]
            ["multiline-layout" "warning"]
            ["no-mutation" "warning"]
            ["one-is-per-testing" "error"]
            ["spec-direct-require" "error"]
            ["spec-macro-import" "error"]
            ["spec-no-module" "error"]]
           (let [entries (default-severities)]
             (if (. entries :module-missing)
               entries
               (sort-severities entries)))))))

(defn- core-require-scenario
  []
  (let [source        "(local c (require :eca.nfnl.core))"
        path          "fnl/app.fnl"
        policy        {}
        (forms error) (identity.forms source path)]
    (if error
      {:error error}
      (let [before   (icollect [_ form (ipairs forms)] form.form)
            rules    (load-rules)
            findings (rules.check path forms policy source)
            after    (icollect [_ form (ipairs forms)] form.form)]
        {:before before :after after :findings findings}))))

(defn- core-require-identities
  [scenario]
  (icollect [_ finding (ipairs scenario.findings)]
    (when (= finding.rule "core-require")
      [finding.rule finding.form finding.severity])))

(deftest check
  (testing "does not mutate identity forms"
    (let [scenario (core-require-scenario)]
      (is (= scenario.before scenario.after))))
  (testing "reports the core-require finding with its established identity"
    (is (= [["core-require" "fnl/app.fnl > local:c" "error"]]
           (core-require-identities (core-require-scenario))))))
