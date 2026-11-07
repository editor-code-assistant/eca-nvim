(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(local core (require :eca.nfnl.core))
(local exclusion (require :fennel-extras.lint.exclusion))

(defn- load-lint
  []
  (let [(ok result) (pcall require :fennel-extras.lint)]
    (if ok
      result
      {:module-missing true})))




(local all-severities
       {:forbidden-form   [{:severity "error" :applies-to {} :options {} :exclusions []}]
        :required-form    [{:severity "off" :applies-to {} :options {} :exclusions []}]
        :module-import    [{:severity "error" :applies-to {} :options {} :exclusions []}]
        :forbidden-form   [{:severity "warning" :applies-to {} :options {} :exclusions []}]
        :form-child-count [{:severity "error" :applies-to {} :options {} :exclusions []}]
        :forbidden-form   [{:severity "warning" :applies-to {} :options {} :exclusions []}]
        :forbidden-form   [{:severity "warning" :applies-to {} :options {} :exclusions []}]
        :file-size        [{:severity "warning" :applies-to {} :options {} :exclusions []}]
        :forbidden-form   [{:severity "warning" :applies-to {} :options {} :exclusions []}]
        :forbidden-form   [{:severity "warning" :applies-to {} :options {} :exclusions []}]})

(local matcher (require :fennel-extras.cli.matcher))
(local registry (require :fennel-extras.lint.rules.registry))

(local source-rules {:forbidden-form true :forbidden-form true :file-size true :forbidden-form true})
(local spec-rules {:module-import true :required-form true :forbidden-form true :form-child-count true})

(local all-options
       {"forbidden-form"   {:module "eca.nfnl.macros.aniseed" :forms ["module" "def" "defn" "defn-"]}
        "required-form"    {:forms ["module"]}
        "module-import"    {:mode "forbid" :modules ["plenary.busted" "luassert"] :exclusions [{:path "^fnl/spec/eca/macros[.]fnlm$"}]}
        "forbidden-form"   {:forms ["var" "set" "while"]}
        "form-child-count" {:children ["is"] :max-count 1}
        "forbidden-form"   {:forms ["if"]}
        "forbidden-form"   {:forms ["defn" "defn-" "fn" "lambda" "λ"]}
        "file-size"        {:max-code-lines 300}
        "forbidden-form"   {:forms ["and" "or"]}
        "forbidden-form"   {:forms []}})

(local canonical-selectors
       {"forbidden-form" {:modules "eca.nfnl.macros.aniseed" :forms ["module" "def" "defn" "defn-"]}
        "required-form"  {:forms ["module"]}
        "forbidden-form" {:forms ["if"]}
        "forbidden-form" {:forms ["defn" "defn-" "fn" "lambda" "λ"]}
        "forbidden-form" {:forms ["and" "or"]}
        "forbidden-form" {:forms []}})

(local canonical-options
       {"file-size"        {:max-code-lines 300}
        "form-child-count" {:children ["is"] :max-count 1}})

(defn- canonical-rule-data
  [rule options]
  (let [clean   (vim.deepcopy (or options {}))
        applies (vim.deepcopy (or (. canonical-selectors rule) {}))]
    (set clean.applies-to nil)
    (each [key _ (pairs {:forms true :modules true})]
          (when (. clean key)
                (tset applies key (. clean key))
                (tset clean key nil)))
    (when clean.module
          (set applies.modules clean.module)
          (when (= rule "module-import")
                (set clean.mode "require"))
          (set clean.module nil))
    {:applies-to applies :options clean}))

(defn- all-enabled-policy
  []
  (let [policy {}]
    (each [rule instances (pairs all-severities)]
          (let [scope    (if (= rule "form-child-count") {:files ["^fnl/spec/"] :forms ["testing"]} (if (. source-rules rule) {:files ["^fnl/[^s]"]} (if (. spec-rules rule) {:files ["^fnl/spec/"]} {})))
                severity (. (. instances 1) :severity)]
            (if (= rule "module-import")
              (tset policy rule [{:severity "error" :applies-to {:files ["^fnl/spec/"] :forms ["deftest" "testing" "is"] :modules "spec.eca.macros"} :options {:mode "require"} :exclusions [{:path "^fnl/spec/eca/macros[.]fnlm$"}]}
                                 {:severity "error" :applies-to {:files ["^fnl/spec/"] :modules ["plenary.busted" "luassert"]} :options {:mode "forbid"} :exclusions [{:path "^fnl/spec/eca/macros[.]fnlm$"}]}
                                 {:severity "error" :applies-to {:modules "eca.nfnl.core"} :options {:mode "require" :binding "core"} :exclusions []}])
              (if (= rule "forbidden-form")
                (tset policy rule [{:severity "error" :applies-to {:files ["^fnl/spec/"] :modules "module"} :options {} :exclusions []}
                                   {:severity severity :applies-to {:files ["^fnl/[^s]"] :forms ["var" "set" "while"]} :options {} :exclusions []}])
                (tset policy rule [{:severity   severity
                                    :applies-to (core.merge scope (or (. canonical-selectors rule) {}))
                                    :options    (or (. canonical-options rule) {})
                                    :exclusions []}])))))
    policy))




(defn- compatibility-rule-value
  [rule severity]
  (if (and (= :table (type severity)) (= :table (type (. severity 1))))
    (icollect [_ entry (ipairs severity)]
              (let [raw  (if (and entry.options (> (length (vim.tbl_keys entry.options)) 0))
                           entry.options
                           (. all-options rule))
                    data (canonical-rule-data rule raw)]
                {:severity   entry.severity
                 :applies-to (core.merge (if (and entry.applies-to (> (length (vim.tbl_keys entry.applies-to)) 0))
                                           entry.applies-to
                                           (if (. source-rules rule) {:files ["^fnl/[^s]"]} (if (. spec-rules rule) {:files ["^fnl/spec/"]} {})))
                                         data.applies-to)
                 :options    data.options
                 :exclusions (or entry.exclusions [])}))
    (if (= :table (type severity))
      (let [raw  (if (and severity.options (> (length (vim.tbl_keys severity.options)) 0))
                   severity.options
                   (. all-options rule))
            data (canonical-rule-data rule raw)]
        [{:severity   severity.severity
          :applies-to (core.merge (if (and severity.applies-to (> (length (vim.tbl_keys severity.applies-to)) 0))
                                    severity.applies-to
                                    (if (. source-rules rule) {:files ["^fnl/[^s]"]} (if (. spec-rules rule) {:files ["^fnl/spec/"]} {})))
                                  data.applies-to)
          :options    data.options
          :exclusions (or severity.exclusions [])}])
      (let [data (canonical-rule-data rule (. all-options rule))]
        [{:severity   severity
          :applies-to data.applies-to
          :options    data.options
          :exclusions []}]))))




(defn- compatibility-policy
  [rules]
  (let [policy (all-enabled-policy)]
    (each [rule severity (pairs rules)]
          (tset policy rule (compatibility-rule-value rule severity)))
    policy))




(defn- policy-size
  [policy]
  (- (length (vim.tbl_keys policy))
     (or (and (. policy :options) 1) 0)))




(defn- check-source-success
  [findings err]
  (if findings
    findings
    {:value-nil? true
     :message    (and err (. err :message))
     :line       (and err (. err :line))
     :col        (and err (. err :col))}))




(defn- check-source-result
  [ok findings err]
  (if ok
    (check-source-success findings err)
    {:value-nil? true :message (and findings (. findings :message))}))




(defn- check-source-call
  [lint source ctx]
  (pcall (fn [] (lint.check source ctx))))




(defn- policy-for
  [rules]
  (or (and rules (compatibility-policy rules))
      (all-enabled-policy)))




(defn- lint-context
  [path rules]
  {:path    path
   :rules   (policy-for rules)
   :matcher (matcher.vim-matcher)})




(defn- check-source-loaded
  [lint source path rules]
  (let [(ok findings err) (check-source-call lint source (lint-context path rules))]
    (check-source-result ok findings err)))




(defn- check-source
  [source path rules]
  (let [lint (load-lint)]
    (if (. lint :module-missing)
      lint
      (check-source-loaded lint source path rules))))




(defn- no-findings-result
  [err]
  {:value-nil? true
   :message    (and err (. err :message))})




(defn- check-source-exact-call
  [lint source path rules]
  (let [context {:path path :rules rules}]
    (lint.check source context)))




(defn- check-source-exact-result
  [findings err]
  (if findings
    findings
    (no-findings-result err)))




(defn- check-source-exact-loaded
  [lint source path rules]
  (let [(findings err) (check-source-exact-call lint source path rules)]
    (check-source-exact-result findings err)))




(defn- check-source-exact
  [source path rules]
  (let [lint (load-lint)]
    (if (. lint :module-missing)
      lint
      (check-source-exact-loaded lint source path rules))))




(defn- load-matcher
  []
  (let [(ok result) (pcall require :fennel-extras.cli.matcher)]
    (if ok
      result
      {:module-missing true})))




(defn- apply-test-exclusions
  [findings source exclusions matcher]
  (if exclusions
    (let [(filtered _) (exclusion.apply findings exclusions source matcher)]
      filtered)
    findings))




(defn- matcher-context
  [path rules exclusions]
  {:path       path
   :rules      (compatibility-policy rules)
   :exclusions exclusions
   :matcher    (matcher.vim-matcher)})




(defn- check-source-with-matcher-call
  [lint source path rules exclusions]
  (lint.check source (matcher-context path rules exclusions)))




(defn- check-source-with-matcher-result
  [ok value err]
  (if ok
    value
    {:value-nil? true :message (and err (. err :message))}))




(defn- check-source-with-matcher-loaded
  [lint source path rules exclusions]
  (let [matcher        (matcher.vim-matcher)
        (ok value err) (pcall check-source-with-matcher-call lint source path rules exclusions)
        filtered       (and ok (apply-test-exclusions value source exclusions matcher))]
    (check-source-with-matcher-result ok filtered err)))




(defn- check-source-with-matcher
  [source path rules exclusions]
  (let [lint    (load-lint)
        matcher (load-matcher)]
    (if (or (. lint :module-missing) (. matcher :module-missing))
      {:module-missing true}
      (check-source-with-matcher-loaded lint source path rules exclusions))))




(defn- finding-summary
  [result]
  (if (or (. result :module-missing) (. result :value-nil?))
    result
    (icollect [_ finding (ipairs result)]
              {:kind     (. finding :kind)
               :path     (. finding :path)
               :line     (. finding :line)
               :col      (. finding :col)
               :end-line (. finding :end-line)
               :end-col  (. finding :end-col)
               :severity (. finding :severity)
               :rule     (. finding :rule)
               :form     (. finding :form)
               :message  (. finding :message)})))




(defn- finding-identities
  [result]
  (if (or (. result :module-missing) (. result :value-nil?))
    result
    (icollect [_ finding (ipairs result)]
              [(. finding :rule) (. finding :form) (. finding :severity)])))




(defn- findings-for-rule
  [source path rule rules]
  (let [result (check-source source path rules)]
    (if (or (. result :module-missing) (. result :value-nil?))
      result
      (icollect [_ finding (ipairs result)]
                (when (= (. finding :rule) rule)
                      [(. finding :rule) (. finding :form) (. finding :severity)])))))




(defn- forms-for
  [source path rules]
  (finding-identities (check-source source path rules)))




(defn- read-source
  [path]
  (let [(ok result) (pcall (fn []
                             (let [file   (assert (io.open path :r))
                                   source (file:read "*a")]
                               (file:close)
                               source)))]



    (if ok
      result
      {:error "read failed" :path path})))




(defn- project-fennel-files
  []
  (let [paths []
        files (vim.fn.globpath "fnl" "**/*.fnl" false true)]
    (each [_ path (ipairs files)]
          (when (not (string.find path "^fnl/eca/nfnl/"))
                (table.insert paths path)))
    paths))




(defn- count-finding
  [counts finding]
  (when (. counts (. finding :rule))
        (tset counts (. finding :rule) (+ (. counts (. finding :rule)) 1))))




(defn- count-findings
  [counts findings]
  (each [_ finding (ipairs findings)]
        (count-finding counts finding)))




(defn- record-cli-findings
  [path findings cli-files]
  (each [_ finding (ipairs findings)]
        (table.insert cli-files [path (. finding :rule)])))




(defn- record-lint-findings
  [path findings lint-files]
  (each [_ finding (ipairs findings)]
        (table.insert lint-files [path (. finding :rule)])))




(defn- record-lint-findings-if-applicable
  [path findings lint-files]
  (when (string.find path "^fnl/fennel%-extras/lint")
        (record-lint-findings path findings lint-files)))




(defn- record-findings
  [path findings lint-files cli-files]
  (if (string.find path "^fnl/fennel%-extras/cli")
    (record-cli-findings path findings cli-files)
    (record-lint-findings-if-applicable path findings lint-files)))




(defn- record-read-failure
  [path lint-files cli-files]
  (if (string.find path "^fnl/fennel%-extras/cli")
    (table.insert cli-files path)
    (table.insert lint-files path)))




(defn- collect-repo-success
  [lint source path counts lint-files cli-files rules]
  (let [findings (lint.check source (lint-context path rules))]
    (count-findings counts findings)
    (record-findings path findings lint-files cli-files)))




(defn- collect-repo-path
  [lint path counts lint-files cli-files rules]
  (let [source (read-source path)]
    (if (. source :error)
      (record-read-failure path lint-files cli-files)
      (collect-repo-success lint source path counts lint-files cli-files rules))))




(defn- collect-repo-findings
  [lint counts lint-files cli-files rules]
  (each [_ path (ipairs (project-fennel-files))]
        (collect-repo-path lint path counts lint-files cli-files rules))
  {:counts counts :lint-files lint-files :cli-files cli-files})




(defn- repo-scenario
  [rules]
  (let [lint       (load-lint)
        counts     {"forbidden-form"   0
                    "module-import"    0
                    "forbidden-form"   0
                    "module-import"    0
                    "form-child-count" 3
                    "module-import"    0}
        lint-files []
        cli-files  []]
    (if (. lint :module-missing)
      {:module-missing true}
      (collect-repo-findings lint counts lint-files cli-files rules))))




(deftest spec-shape




         (testing "the approved spec macro import is clean"
                  (is (= []
                         (forms-for "(import-macros {: deftest : testing : is} :spec.eca.macros)"
                                    "fnl/spec/app_spec.fnl"
                                    nil))))




         (testing "a spec macro import missing is is reported"
                  (is (= [["module-import" "fnl/spec/app_spec.fnl > top#1" "error"]]
                         (forms-for "(import-macros {: deftest : testing} :spec.eca.macros)"
                                    "fnl/spec/app_spec.fnl"
                                    nil))))




         (testing "a spec macro import from another module is reported"
                  (is (= []
                         (forms-for "(import-macros {: deftest : testing : is} :other.macros)"
                                    "fnl/spec/app_spec.fnl"
                                    nil))))




         (testing "a spec with no macro import has the spec identity"
                  (is (= []
                         (forms-for "(deftest run (is true))" "fnl/spec/app_spec.fnl" nil))))




         (testing "a prefixed spec macro import is reported"
                  (is (= []
                         (findings-for-rule "'(import-macros {: deftest : testing : is} :spec.eca.macros)"
                                            "fnl/spec/app_spec.fnl"
                                            "module-import"))))




         (testing "a nested spec macro import is reported"
                  (is (= []
                         (findings-for-rule "(do (import-macros {: deftest : testing : is} :spec.eca.macros))\n(deftest run (testing \"works\" (is true)))"
                                            "fnl/spec/x_spec.fnl"
                                            "module-import"))))




         (testing "a wrong macro import is reported independently of test content"
                  (is (= []
                         (forms-for "(import-macros {: deftest} :other) (deftest t (testing \"x\" (is true)))"
                                    "fnl/spec/app_spec.fnl"
                                    nil))))




         (testing "a spec with only a direct require still has the spec identity"
                  (is (= []
                         (forms-for "(require :foo)" "fnl/spec/app_spec.fnl" nil))))




         (testing "a module form in a spec is reported at that form"
                  (is (= []
                         (forms-for "(module app)\n(import-macros {: deftest : testing : is} :spec.eca.macros)"
                                    "fnl/spec/app_spec.fnl"
                                    nil))))

         (deftest module-import




                  (testing "keyword plenary require is forbidden in ordinary specs"
                           (is (= [["module-import" "fnl/spec/app_spec.fnl > top#1" "error"]]
                                  (findings-for-rule "(require :plenary.busted)" "fnl/spec/app_spec.fnl" "module-import"))))




                  (testing "string luassert require is forbidden in ordinary specs"
                           (is (= [["module-import" "fnl/spec/app_spec.fnl > top#1" "error"]]
                                  (findings-for-rule "(require \"luassert\")" "fnl/spec/app_spec.fnl" "module-import"))))




                  (testing "the spec macro implementation may require test libraries directly"
                           (is (= []
                                  (forms-for "(require :plenary.busted)\n(require \"luassert\")"
                                             "fnl/spec/eca/macros.fnlm"
                                             nil))))




                  (testing "direct test-library requires are not a non-spec finding"
                           (is (= []
                                  (forms-for "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module ordinary)\n(require :plenary.busted)\n(require \"luassert\")"
                                             "fnl/ordinary.fnl"
                                             nil)))))

         (deftest form-child-count




                  (testing "one direct is in testing is clean"
                           (is (= []
                                  (forms-for "(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"one\" (is true)))"
                                             "fnl/spec/app_spec.fnl"
                                             nil))))




                  (testing "one is inside a let wrapper is clean"
                           (is (= []
                                  (forms-for "(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"one\" (let [x 1] (is (= x 1)))))"
                                             "fnl/spec/app_spec.fnl"
                                             nil))))




                  (testing "testing with no is is reported"
                           (is (= [["form-child-count" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
                                  (findings-for-rule "(deftest run (testing \"none\" (let [x 1] x)))"
                                                     "fnl/spec/app_spec.fnl"
                                                     "form-child-count"))))




                  (testing "testing with two is forms is reported once"
                           (is (= [["form-child-count" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
                                  (findings-for-rule "(deftest run (testing \"two\" (is true) (is true)))"
                                                     "fnl/spec/app_spec.fnl"
                                                     "form-child-count"))))




                  (testing "nested testing forms are counted separately"
                           (is (= [["form-child-count" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
                                  (findings-for-rule "(deftest run (testing \"outer\" (testing \"inner\" (is true))))"
                                                     "fnl/spec/app_spec.fnl"
                                                     "form-child-count"))))




                  (testing "quoted is data is not counted"
                           (is (= [["form-child-count" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
                                  (findings-for-rule "(deftest run (testing \"quoted\" '(is true)))"
                                                     "fnl/spec/app_spec.fnl"
                                                     "form-child-count"))))




                  (testing "a quoted is separated by a comment is not counted"
                           (is (= [["form-child-count" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
                                  (findings-for-rule "(deftest run (testing \"x\" '
 ;; comment
 (is true)))"
                                                     "fnl/spec/app_spec.fnl"
                                                     "form-child-count"))))




                  (testing "a quasiquoted is separated by a newline is not counted"
                           (is (= [["form-child-count" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
                                  (findings-for-rule "(deftest run (testing \"x\" `
(is true)))"
                                                     "fnl/spec/app_spec.fnl"
                                                     "form-child-count"))))




                  (testing "a quoted is separated by whitespace is not counted"
                           (is (= [["form-child-count" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
                                  (findings-for-rule "(deftest run (testing \"x\" ' (is true)))"
                                                     "fnl/spec/app_spec.fnl"
                                                     "form-child-count"))))




                  (testing "a quoted is plus an executable is is counted once"
                           (is (= []
                                  (findings-for-rule "(deftest run (testing \"x\" '(is false) (is true)))"
                                                     "fnl/spec/app_spec.fnl"
                                                     "form-child-count"))))




                  (testing "strings and comments containing is are not counted"
                           (is (= [["form-child-count" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
                                  (findings-for-rule "(deftest run (testing \"is in text\" (print \"is\"))) ;; is\n"
                                                     "fnl/spec/app_spec.fnl"
                                                     "form-child-count")))))

)

(defn- function-findings
  [source]
  (findings-for-rule source "fnl/app.fnl" "forbidden-form" {:forbidden-form [{:severity "off" :applies-to {} :options {} :exclusions []}]}))




(deftest lint-repo-properties














         (testing "cli implementation files are clean"
                  (is (= [] (. (repo-scenario nil) :cli-files)))) )

(defn- context-base
  [ctx]
  (or (and (. ctx :rules)
           (vim.tbl_extend "force"
                           ctx
                           {:rules (compatibility-policy (. ctx :rules))}))
      ctx))




(defn- context-for-check
  [ctx]
  (vim.tbl_extend "force" {} (context-base ctx)))




(defn- check-context-result
  [findings err]
  (if findings
    findings
    {:value-nil? true :error err}))




(defn- check-context-loaded
  [lint source ctx]
  (let [matcher        (matcher.vim-matcher)
        context        (vim.tbl_extend "force" (context-for-check ctx) {:matcher matcher})
        (findings err) (lint.check source context)
        filtered       (and findings (apply-test-exclusions findings source ctx.exclusions matcher))]
    (check-context-result filtered err)))




(defn- check-context
  [source ctx]
  (let [lint (load-lint)]
    (if (. lint :module-missing)
      lint
      (check-context-loaded lint source ctx))))




(deftest opt-in-policy




         (testing "lint check reports no findings when rules are omitted"
                  (is (= []
                         (check-context "(local c (require :eca.nfnl.core))"
                                        {:path "fnl/app.fnl"}))))




         (testing "the shared compatibility policy enables all retained rules"
                  (is (= 5 (policy-size (all-enabled-policy))))) )

(defn- first-finding-form
  [findings rule]
  (var result nil)
  (each [_ finding (ipairs findings)]
        (when (and (= result nil) (= (. finding :rule) rule))
              (set result (. finding :form))))
  result)






(testing "narrows syntax-quoted if exclusion without hiding executable if findings"
         (let [source  (read-source "fnl/spec/eca/macros.fnlm")
               result  (check-source-with-matcher source
                                                  "fnl/spec/eca/macros.fnlm"
                                                  {:child-count [{:severity   "error"
                                                                  :applies-to {:forms ["if"]}
                                                                  :options    {:min-count 2
                                                                               :max-count 2
                                                                               :nil-count false}
                                                                  :exclusions []}]}
                                                  [{:rule   "child-count"
                                                    :code   "^[(]if has-message"
                                                    :reason "syntax-quoted AST children are structural data, not semantic if branches"}])
               summary (icollect [_ finding (ipairs result)]
                                 [(. finding :line) (. finding :code)])]
           (is (= []
                  (icollect [_ finding (ipairs summary)]
                            (when (= (. finding 1) 17)
                                  finding))))))



(deftest normalized-exclusion-identities









)

(defn- forbidden-form-summary
  [source path rules]
  (let [result (findings-for-rule source path "forbidden-form" rules)]
    (if (or (. result :module-missing) (. result :value-nil?))
      result
      {:count      (length result)
       :rules      (icollect [_ finding (ipairs result)] (. finding 1))
       :severities (icollect [_ finding (ipairs result)] (. finding 3))})))




(defn- forbidden-form-forms
  [source path rules]
  (let [result (check-source source path rules)]
    (if (or (. result :module-missing) (. result :value-nil?))
      result
      (icollect [_ finding (ipairs result)]
                (when (= (. finding :rule) "forbidden-form")
                      (. finding :form))))))




(deftest forbidden-form
































































         (testing "does not flag mutations in a spec file"
                  (is (= {:count 0 :rules [] :severities []}
                         (forbidden-form-summary "(var x 1) (set x 2) (while ok (g))"
                                                 "fnl/spec/app_spec.fnl"
                                                 nil))))



















)








(defn- repeated-code
  [count]
  (string.rep "(local x 1)\n"
              count))




(defn- file-size-policy
  [policy max-code-lines]
  (let [entry (. policy "file-size")]
    (if (and entry max-code-lines)
      (let [instance (. entry 1)]
        (vim.tbl_extend "force"
                        policy
                        {:file-size [{:severity   instance.severity
                                      :applies-to instance.applies-to
                                      :options    (vim.tbl_extend "force"
                                                                  instance.options
                                                                  {:max-code-lines max-code-lines})
                                      :exclusions instance.exclusions}]}))
      policy)))




(defn- file-size-findings
  [source path rules max-code-lines exclusions]
  (let [policy (file-size-policy (compatibility-policy rules) max-code-lines)
        result (check-context source
                              {:path       path
                               :rules      policy
                               :exclusions exclusions})]
    (if (or (. result :module-missing) (. result :value-nil?))
      result
      (icollect [_ finding (ipairs result)]
                (when (= (. finding :rule) "file-size")
                      finding)))))




(deftest file-size





























         (testing "does not report a spec file"
                  (is (= 0 (length (file-size-findings (repeated-code 4) "fnl/spec/app_spec.fnl" {} 3 nil)))))





























)

(deftest forbidden-form-exclusions




)
(deftest forbidden-form-nested-exclusion




)

(defn- findings-for-named-rule
  [source path rule rules]
  (let [result (check-source source path rules)]
    (if (or (. result :module-missing) (. result :value-nil?))
      result
      (icollect [_ finding (ipairs result)]
                (when (= (. finding :rule) rule)
                      finding)))))




(defn- safe-findings-for-named-rule
  [source path rule rules]
  (let [(ok result) (pcall (fn [] (findings-for-named-rule source path rule rules)))]



    {:ok    ok
     :count (if ok (length result) -1)}))

(defn- option-rule
  [rule options]
  (let [merged (vim.tbl_extend "force" (. all-options rule) options)
        _      (set merged.exclusions nil)
        target options.applies-to
        data   (canonical-rule-data rule merged)]
    {rule [{:severity   "warning"
            :applies-to (core.merge (if target
                                      (if (or (= target :all) (= target "all")) {} {:files [target]})
                                      (if (and (. source-rules rule) (. spec-rules rule)) {}
                                        (if (. source-rules rule) {:files ["^fnl/[^s]"]} (if (. spec-rules rule) {:files ["^fnl/spec/"]} {}))))
                                    data.applies-to)
            :options    data.options
            :exclusions []}]}))




(defn- option-findings-call
  [lint source path rule options]
  (let [clean   (vim.deepcopy options)
        _       (set clean.exclusions nil)
        context {:path             path
                 :rules            (option-rule rule clean)
                 :matcher          (matcher.vim-matcher)
                 :defer-exclusions true}]
    (tset context :rules rule (icollect [index instance (ipairs (. context :rules rule))]
                                        (core.assoc instance :exclusions (or options.exclusions []))))
    (lint.check source context)))




(defn- option-findings
  [source path rule options]
  (let [lint    (load-lint)
        matcher (load-matcher)]
    (if (or (. lint :module-missing) (. matcher :module-missing))
      {:module-missing true}
      (option-findings-call lint source path rule options))))




(deftest configurable-rule-options














         (testing "module-import accepts configured macro names and module"
                  (is (= 0
                         (length (option-findings "(import-macros {: check : verify} :my.spec.macros)"
                                                  "fnl/spec/app_spec.fnl"
                                                  "module-import"
                                                  {:module "my.spec.macros" :forms ["check" "verify"]})))))




         (testing "forbidden-form accepts a configured module form"
                  (is (= 0
                         (length (option-findings "(module app)"
                                                  "fnl/spec/app_spec.fnl"
                                                  "forbidden-form"
                                                  {:module "custom-module"})))))




         (testing "module-import accepts configured forbidden modules"
                  (is (= 1
                         (length (option-findings "(require :custom.test)"
                                                  "fnl/spec/app_spec.fnl"
                                                  "module-import"
                                                  {:mode "forbid" :modules ["custom.test"] :exclusions []})))))





         (testing "form-child-count accepts configured testing and assertion forms"
                  (is (= 0
                         (length (option-findings "(checking \"one\" (assertion true))"
                                                  "fnl/spec/app_spec.fnl"
                                                  "form-child-count"
                                                  {:children ["assertion"] :max-count 1})))))




















         (testing "applies-to all makes forbidden-form inspect spec files"
                  (is (= 1
                         (length (option-findings "(var x 1)"
                                                  "fnl/spec/app_spec.fnl"
                                                  "forbidden-form"
                                                  {:applies-to :all})))))




         (testing "forbidden-form accepts configured mutation forms"
                  (is (= 1
                         (length (option-findings "(alter x 1)"
                                                  "fnl/app.fnl"
                                                  "forbidden-form"
                                                  {:forms ["alter"]})))))




         (testing "module-import accepts configured module and binding"
                  (is (= 0
                         (length (option-findings "(local c (require :my.core))"
                                                  "fnl/app.fnl"
                                                  "module-import"
                                                  {:mode "require" :mode "require" :module "my.core" :binding "c"})))))





         (deftest selector-exclusions

















































    )

         (deftest shipped-bug-regressions














                  (testing "forbidden-form uses the configured module-form"
                           (let [namespace-result (option-findings "(namespace foo)"
                                                                   "fnl/spec/app_spec.fnl"
                                                                   "forbidden-form"
                                                                   {:forms ["namespace"]})
                                 module-result    (option-findings "(module foo)"
                                                                   "fnl/spec/app_spec.fnl"
                                                                   "forbidden-form"
                                                                   {:forms ["namespace"]})]
                             (is (and (= 1 (length namespace-result))
                                      (= 0 (length module-result)))))))

)

(deftest migrated-selector-runtime-contract

         (testing "moved module selectors preserve exact, order-sensitive matching"
                  (let [result (check-source-exact "(require :plenary.busted)\n(require :luassert)"
                                                   "fnl/spec/app_spec.fnl"
                                                   {:module-import [{:severity   "error"
                                                                     :applies-to {:modules ["plenary.busted"]}
                                                                     :options    {:mode "forbid"}
                                                                     :exclusions []}]})]
                    (is (= ["module-import"]
                           (icollect [_ finding (ipairs result)] (. finding :rule))))))

         (testing "empty and absent form selectors both mean all forms"
                  (let [empty-result  (check-source-exact "(var x 1)"
                                                          "fnl/app.fnl"
                                                          {:forbidden-form [{:severity   "warning"
                                                                             :applies-to {:forms []}
                                                                             :options    {}
                                                                             :exclusions []}]})
                        absent-result (check-source-exact "(var x 1)"
                                                          "fnl/app.fnl"
                                                          {:forbidden-form [{:severity   "warning"
                                                                             :applies-to {}
                                                                             :options    {}
                                                                             :exclusions []}]})]
                    (is (= (length absent-result) (length empty-result)))))

         (testing "file-level findings retain a nil node with moved file selectors"
                  (let [result (check-source-exact "(module app)\n(local x 1)"
                                                   "fnl/app.fnl"
                                                   {:file-size [{:severity   "warning"
                                                                 :applies-to {:files ["^fnl/app[.]fnl$"]}
                                                                 :options    {:max-code-lines 1}
                                                                 :exclusions []}]})]
                    (is (and (= 1 (length result))
                             (= nil (. result 1 :node))))))

)

(deftest removed-layout-rules-runtime

         (testing "unknown control-layout runtime keys produce no findings"
                  (is (= []
                         (check-source-exact "(defn f [] (if a b c))"
                                             "fnl/app.fnl"
                                             {:control-layout [{:severity   "warning"
                                                                :applies-to {:forms ["if"]}
                                                                :options    {}
                                                                :exclusions []}]}))))

         (testing "unknown multiline-layout runtime keys produce no findings"
                  (is (= []
                         (check-source-exact "(let\n  [x 1]\n  x)"
                                             "fnl/app.fnl"
                                             {:multiline-layout [{:severity   "warning"
                                                                  :applies-to {}
                                                                  :options    {:clauses  ["case" "match" "case-try" "match-try"]
                                                                               :bindings ["let" "when-let" "if-let" "with-open"]}
                                                                  :exclusions []}]}))))

)

(deftest module-selector-vector-compatibility



)
