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
       {:module-style     [{:severity "error" :applies-to {} :options {} :exclusions []}]
        :required-form    [{:severity "off" :applies-to {} :options {} :exclusions []}]
        :module-import    [{:severity "error" :applies-to {} :options {} :exclusions []}]
        :forbidden-form   [{:severity "warning" :applies-to {} :options {} :exclusions []}]
        :form-child-count [{:severity "error" :applies-to {} :options {} :exclusions []}]
        :if-branch-call   [{:severity "warning" :applies-to {} :options {} :exclusions []}]
        :if-without-else  [{:severity "warning" :applies-to {} :options {} :exclusions []}]
        :control-layout   [{:severity "warning" :applies-to {} :options {} :exclusions []}]
        :multiline-layout [{:severity "warning" :applies-to {} :options {} :exclusions []}]
        :function-shape   [{:severity "warning" :applies-to {} :options {} :exclusions []}]
        :file-size        [{:severity "warning" :applies-to {} :options {} :exclusions []}]
        :unused-and-or    [{:severity "warning" :applies-to {} :options {} :exclusions []}]
        :call-data-arg    [{:severity "warning" :applies-to {} :options {} :exclusions []}]})

(local matcher (require :fennel-extras.cli.matcher))
(local registry (require :fennel-extras.lint.rules.registry))

(local source-rules {:module-style true :forbidden-form true :file-size true :call-data-arg true})
(local spec-rules {:module-import true :required-form true :forbidden-form true :form-child-count true})

(local all-options
       {"module-style"     {:module "eca.nfnl.macros.aniseed" :forms ["module" "def" "defn" "defn-"]}
        "required-form"    {:forms ["module"]}
        "module-import"    {:mode "forbid" :modules ["plenary.busted" "luassert"] :exempt-files ["^fnl/spec/eca/macros[.]fnlm$"]}
        "forbidden-form"   {:forms ["var" "set" "while"]}
        "form-child-count" {:children ["is"] :max-count 1}
        "if-branch-call"   {:forms ["if"]}
        "if-without-else"  {:forms ["if"] :nil-else true}
        "control-layout"   {:forms ["if" "when" "and" "or" "case" "match"]}
        "multiline-layout" {:clauses ["case" "match" "case-try" "match-try"] :bindings ["let" "when-let" "if-let" "with-open"]}
        "function-shape"   {:forms ["defn" "defn-" "fn" "lambda" "λ"]}
        "file-size"        {:max-code-lines 300}
        "unused-and-or"    {:forms ["and" "or"]}
        "call-data-arg"    {:forms []}})

(local canonical-selectors
       {"module-style"    {:modules "eca.nfnl.macros.aniseed" :forms ["module" "def" "defn" "defn-"]}
        "required-form"   {:forms ["module"]}
        "if-branch-call"  {:forms ["if"]}
        "if-without-else" {:forms ["if"]}
        "control-layout"  {:forms ["if" "when" "and" "or" "case" "match"]}
        "function-shape"  {:forms ["defn" "defn-" "fn" "lambda" "λ"]}
        "unused-and-or"   {:forms ["and" "or"]}
        "call-data-arg"   {:forms []}})

(local canonical-options
       {"if-without-else"  {:nil-else true}
        "file-size"        {:max-code-lines 300}
        "form-child-count" {:children ["is"] :max-count 1}
        "multiline-layout" {:clauses ["case" "match" "case-try" "match-try"] :bindings ["let" "when-let" "if-let" "with-open"]}})

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
          (tset policy rule [{:severity "error" :applies-to {:files ["^fnl/spec/"] :forms ["deftest" "testing" "is"] :modules "spec.eca.macros"} :options {:mode "require" :exempt-files ["^fnl/spec/eca/macros[.]fnlm$"]} :exclusions []}
                             {:severity "error" :applies-to {:files ["^fnl/spec/"] :modules ["plenary.busted" "luassert"]} :options {:mode "forbid" :exempt-files ["^fnl/spec/eca/macros[.]fnlm$"]} :exclusions []}
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
        counts     {"module-style"     0
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




(deftest module-style




  (testing "a compliant non-spec module is clean"
    (is (= []
           (forms-for "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)"
                      "fnl/app.fnl"
                      nil))))




  (testing "a non-spec file without a module form has one file finding"
    (is (= [["module-style" "fnl/legacy.fnl > file" "error"]]
           (forms-for "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(defn run [] 1)"
                      "fnl/legacy.fnl"
                      {}))))




  (testing "a non-spec file containing only a local still has one file finding"
    (is (= [["module-style" "fnl/legacy.fnl > file" "error"]]
           (findings-for-rule "(local x 1)" "fnl/legacy.fnl" "module-style"))))




  (testing "a non-spec file containing only an if still has one file finding"
    (is (= [["module-style" "fnl/legacy.fnl > file" "error"]]
           (findings-for-rule "(if ok a b)" "fnl/legacy.fnl" "module-style"))))




  (testing "a module without the aniseed import has one file finding"
    (is (= [["module-style" "fnl/app.fnl > file" "error"]]
           (findings-for-rule "(module app)" "fnl/app.fnl" "module-style"))))




  (testing "a module-style file missing def in the macro import is reported"
    (is (= [["module-style" "fnl/app.fnl > file" "error"]]
           (forms-for "(import-macros {: module : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)"
                      "fnl/app.fnl"
                      nil))))




  (testing "a nested module form is reported in a non-spec file"
    (is (= [["module-style" "fnl/app.fnl > file" "error"]]
           (findings-for-rule "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(if ok (module app) x)"
                              "fnl/app.fnl"
                              "module-style"))))




  (testing "a nested aniseed import is reported in a non-spec file"
    (is (= [["module-style" "fnl/app.fnl > file" "error"]]
           (findings-for-rule "(if ok (import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed) x)\n(module app)"
                              "fnl/app.fnl"
                              "module-style"))))




  (testing "a quoted top-level module form is reported as non-module style"
    (is (= [["module-style" "fnl/app.fnl > file" "error"]]
           (findings-for-rule "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n'(module app)"
                              "fnl/app.fnl"
                              "module-style"))))




  (testing "a quasiquoted top-level module form is reported as non-module style"
    (is (= [["module-style" "fnl/app.fnl > file" "error"]]
           (findings-for-rule "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n`(module app)"
                              "fnl/app.fnl"
                              "module-style"))))




  (testing "an unquoted top-level module form is reported as non-module style"
    (is (= [["module-style" "fnl/app.fnl > file" "error"]]
           (findings-for-rule "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n,(module app)"
                              "fnl/app.fnl"
                              "module-style"))))




  (testing "a hashfn top-level module form is reported as non-module style"
    (is (= [["module-style" "fnl/app.fnl > file" "error"]]
           (findings-for-rule "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n#(module app)"
                              "fnl/app.fnl"
                              "module-style"))))




  (testing "a prefixed aniseed import with a real module is reported as non-module style"
    (is (= [["module-style" "fnl/app.fnl > file" "error"]]
           (findings-for-rule "'(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)"
                              "fnl/app.fnl"
                              "module-style"))))




  (testing "top-level module and import forms stay clean in either order with comments"
    (is (= []
           (forms-for "(module app)\n;; between top-level forms\n(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)"
                      "fnl/app.fnl"
                      nil))))




  (testing "a legacy fn and final table are reported as non-module style"
    (is (= [["module-style" "fnl/legacy.fnl > file" "error"]]
           (forms-for "(fn run [] 1)\n{:run run}" "fnl/legacy.fnl" nil))))




  (testing "module-style never applies to spec files"
    (is (= []
           (forms-for "(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"works\" (is true)))"
                      "fnl/spec/app_spec.fnl"
                      nil)))))

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

  (deftest if-branch-call




    (testing "a multi-expression then do is a warning"
      (is (= [["if-branch-call" "fnl/app.fnl > defn:run > if#1 > then" "warning"]]
             (findings-for-rule "(defn run [] (if ok (do a b) c))" "fnl/app.fnl" "if-branch-call"))))




    (testing "a one-expression do is clean"
      (is (= []
             (findings-for-rule "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(defn run [] (if ok (do a) c))"
                                "fnl/app.fnl"
                                "if-branch-call"))))




    (testing "let and set branches are clean"
      (is (= []
             (findings-for-rule "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(defn run [] (if ok (let [x 1] x) (set x 1)))"
                                "fnl/app.fnl"
                                "if-branch-call"))))




    (testing "both multi-expression branches have distinct identities"
      (is (= [["if-branch-call" "fnl/app.fnl > defn:run > if#1 > else" "warning"]
              ["if-branch-call" "fnl/app.fnl > defn:run > if#1 > then" "warning"]]
             (let [findings (findings-for-rule "(defn run [] (if ok (do a b) (do c d)))" "fnl/app.fnl" "if-branch-call")]
               (table.sort findings (fn [a b] (< (. a 2) (. b 2))))



               findings))))




    (testing "multi-clause then branches use both then identities"
      (is (= [["if-branch-call" "fnl/app.fnl > defn:run > if#1 > then" "warning"]
              ["if-branch-call" "fnl/app.fnl > defn:run > if#1 > then#2" "warning"]]
             (findings-for-rule "(defn run [] (if a (do x y) b (do c d) e))" "fnl/app.fnl" "if-branch-call"))))




    (testing "a do nested below a non-do branch root is clean"
      (is (= []
             (findings-for-rule "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(defn run [] (if ok (let [x 1] (do a b)) c))"
                                "fnl/app.fnl"
                                "if-branch-call"))))




    (testing "if branch severity can be overridden to error"
      (is (= [["if-branch-call" "fnl/app.fnl > defn:run > if#1 > then" "error"]]
             (findings-for-rule "(defn run [] (if ok (do a b) c))"
                                "fnl/app.fnl"
                                "if-branch-call"
                                {:if-branch-call [{:severity "error" :applies-to {} :options {} :exclusions []}]}))))




    (testing "if branch rule can be disabled"
      (is (= []
             (findings-for-rule "(defn run [] (if ok (do a b) c))"
                                "fnl/app.fnl"
                                "if-branch-call"
                                {:if-branch-call [{:severity "off" :applies-to {} :options {} :exclusions []}]}))))

    (deftest module-import




      (testing "the core local binding uses the canonical name"
        (is (= []
               (forms-for "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(local core (require :eca.nfnl.core))" "fnl/app.fnl" nil))))




      (testing "a core local with extra expressions is reported"
        (is (= [["module-import" "fnl/app.fnl > local:core" "error"]]
               (findings-for-rule "(local core (require :eca.nfnl.core) other)" "fnl/app.fnl" "module-import"))))




      (testing "a string core local binding uses the canonical shape"
        (is (= []
               (forms-for "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(local core (require \"eca.nfnl.core\"))" "fnl/app.fnl" nil))))




      (testing "a non-core local binding is reported"
        (is (= [["module-import" "fnl/app.fnl > local:c" "error"]]
               (findings-for-rule "(local c (require :eca.nfnl.core))" "fnl/app.fnl" "module-import"))))




      (testing "a keyword core require with extra expressions is reported"
        (is (= [["module-import" "fnl/app.fnl > top#1" "error"]]
               (findings-for-rule "(require :eca.nfnl.core extra)" "fnl/app.fnl" "module-import"))))




      (testing "a string core require with extra expressions is reported"
        (is (= [["module-import" "fnl/app.fnl > top#1" "error"]]
               (findings-for-rule "(require \"eca.nfnl.core\" extra)" "fnl/app.fnl" "module-import")))))

    (deftest determinism-and-boundary




      (testing "the same source produces identical sorted findings"
        (is (= [["if-branch-call" "fnl/app.fnl > defn:run > if#1 > then" "warning"]
                ["if-branch-call" "fnl/app.fnl > defn:run > if#1 > else" "warning"]]
               (findings-for-rule "(defn run [] (if ok (do a b) (do c d)))" "fnl/app.fnl" "if-branch-call" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}))))




      (testing "no two findings share path rule and form"
        (is (= {:findings   [["if-branch-call" "fnl/app.fnl > defn:run > if#1 > then" "warning"]
                             ["if-branch-call" "fnl/app.fnl > defn:run > if#1 > else" "warning"]]
                :duplicates []}
               (let [findings   (findings-for-rule "(defn run [] (if ok (do a b) (do c d)))" "fnl/app.fnl" "if-branch-call" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})
                     seen       {}
                     duplicates []]
                 (each [_ value (ipairs findings)]
                   (let [key (.. (. value 1) "|" (. value 2))]
                     (if (. seen key)
                       (table.insert duplicates key)
                       (tset seen key true))))
                 {:findings findings :duplicates duplicates}))))




      (testing "the pure core returns findings without executing vim api text"
        (is (= [["module-import" "fnl/app.fnl > top#1" "error"]]
               (findings-for-rule "(require :eca.nfnl.core extra)\n(vim.api.nvim_set_option_value :x 1 {})"
                                  "fnl/app.fnl"
                                  "module-import"))))




      (testing "reader failure returns nil and a structured error table"
        (is (= {:value-nil? true :message "missing closing delimiter" :line 1 :col 1}
               (check-source "(unclosed" "fnl/bad.fnl" nil)))))))

(defn- function-findings
  [source]
  (findings-for-rule source "fnl/app.fnl" "function-shape" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}))




(deftest function-shape




  (testing "a nested if in a set value reports the outer set form"
    (is (= 1 (length (function-findings "(defn f [x] (set x (if x 1 2)))")))))




  (testing "a multi-expression do body reports the outer do form"
    (is (= 1 (length (function-findings "(defn f [] (do a b))")))))




  (testing "nested function and do forms report one outer offending form"
    (is (= 1 (length (function-findings "(defn f [] (foo (fn [] a) (do a b)))")))))




  (testing "a nested if in a sequence reports the sequence form"
    (is (= [["function-shape" "fnl/app.fnl > defn:f > sequence#1" "warning"]]
           (function-findings "(defn f [] [1 (if a b c)])"))))




  (testing "a nested if in a table reports the table form"
    (is (= [["function-shape" "fnl/app.fnl > defn:f > table#1" "warning"]]
           (function-findings "(defn f [] {:k (if a b c)})"))))




  (testing "a nested let in a local value reports the outer local form"
    (is (= 1 (length (function-findings "(defn f [] (local y (let [z 1] z)))")))))




  (testing "a set with a leaf call value is clean"
    (is (= [] (function-findings "(defn f [x] (set x (g x)))"))))




  (testing "a sequence with a leaf call is clean"
    (is (= [] (function-findings "(defn f [] [1 (g a)])"))))




  (testing "a table with a leaf call is clean"
    (is (= [] (function-findings "(defn f [] {:k (g a)})"))))




  (testing "quoted control forms are clean"
    (is (= [] (function-findings "(defn f [] '(if a b c))"))))




  (testing "the user's nested inner if is the single function-shape finding"
    (is (= [["function-shape" "fnl/app.fnl > defn-:join > if#1 > else > if#1" "warning"]]
           (function-findings "(defn- join [xs]
  (if (= xs [])
      nil
      (if (= (length xs) 1)
          (first xs)
          (table.concat (icollect [_ x (ipairs xs)] x) \" \"))))"))))




  (testing "the fixed join form is clean"
    (is (= []
           (function-findings "(defn- join-parts [xs]
  (table.concat (icollect [_ x (ipairs xs)] x) \" \"))
(defn- join [xs]
  (if (= xs [])
      nil
      (join-parts xs)))"))))




  (testing "a comprehension in the first let binding is reported"
    (is (= 1
           (length (function-findings "(defn run [xs]
  (let [parts (icollect [_ x (ipairs xs)] x)]
    (table.concat parts \" \")))")))))




  (testing "a comprehension used as an if branch is reported"
    (is (= 1 (length (function-findings "(defn f [xs] (if ok (icollect [_ x (ipairs xs)] x) nil))")))))




  (testing "a comprehension used as a when body is reported"
    (is (= 1 (length (function-findings "(defn f [xs] (when ok (icollect [_ x (ipairs xs)] x)))")))))




  (testing "a direct comprehension body with a leaf body is clean"
    (is (= [] (function-findings "(defn f [xs] (icollect [_ x (ipairs xs)] x))"))))




  (testing "a function argument with an if body is reported"
    (is (= 1
           (length (function-findings "(defn run []
  (foo (fn [] (if a b c))))")))))




  (testing "a function argument with a do body is reported"
    (is (= 1
           (length (function-findings "(defn run []
  (foo (fn [] (do a b))))")))))




  (testing "a loop argument with a when body is reported"
    (is (= 1
           (length (function-findings "(defn run [xs]
  (foo (each [_ x (ipairs xs)] (when x (bar)))))")))))




  (testing "a function argument and comprehension argument with leaf bodies are clean"
    (is (= []
           (function-findings "(defn run [xs]
  (foo (fn [] a) (icollect [_ x (ipairs xs)] x)))"))))




  (testing "a first let with leaf bindings and body is clean"
    (is (= []
           (function-findings "(defn run [x]
  (let [a x b 1]
    (+ a b)))"))))




  (testing "an if in a let binding value is reported"
    (is (= 1
           (length (function-findings "(defn run [x]
  (let [a (if x 1 2)] a))")))))




  (testing "a let after the first body expression is reported"
    (is (= 1
           (length (function-findings "(defn run [x]
  x
  (let [a 1] a))")))))




  (testing "a second nested let is reported"
    (is (= 1
           (length (function-findings "(defn run [x]
  (let [a x]
    (let [b a] b)))")))))




  (testing "a nested if in a while binding is reported"
    (is (= 1 (length (function-findings "(defn- f [] (while true (let [x (if a b c)] x)))")))))




  (testing "a nested if in a while do body is reported"
    (is (= 1 (length (function-findings "(defn- f [] (while true (do (if a b c) x)))")))))




  (testing "a single-expression do body is reported"
    (is (= 1 (length (function-findings "(defn- f [] (do x))")))))




  (testing "a let inside an if branch is reported"
    (is (= 1 (length (function-findings "(defn- f [] (if a (let [y 1] y) b))")))))




  (testing "a nested when in a loop body is reported"
    (is (= 1 (length (function-findings "(defn- f [] (each [_ v (ipairs xs)] (when v (print v))))")))))




  (testing "sibling callback layers are clean"
    (is (= [] (function-findings "(defn- f [] (foo (fn [] a) (fn [] b)))"))))




  (testing "a function nested in a call argument is reported"
    (is (= 1 (length (function-findings "(defn f [] (foo (bar (fn [] a))))")))))




  (testing "a function nested in a let binding call is reported"
    (is (= 1 (length (function-findings "(defn f [] (let [x (foo (fn [] a))] x))")))))




  (testing "a comprehension nested in a call argument is reported"
    (is (= 1 (length (function-findings "(defn f [xs] (foo (bar (icollect [_ x (ipairs xs)] x))))")))))




  (testing "a call with a function in an if branch is reported"
    (is (= 1 (length (function-findings "(defn f [] (if ok (foo (fn [] a)) nil))")))))




  (testing "a multi-clause flat if is clean"
    (is (= []
           (function-findings "(defn run [x]
  (if x 1 y 2 3))"))))




  (testing "a case with leaf clauses is clean"
    (is (= []
           (function-findings "(defn run [x]
  (case x 1 :one 2 :two :other))"))))




  (testing "a nested if in a case clause is reported"
    (is (= 1
           (length (function-findings "(defn run [x]
  (case x 1 (if x :one :other) :other))")))))




  (testing "a match with leaf clauses is clean"
    (is (= []
           (function-findings "(defn run [x]
  (match x 1 :one 2 :two :other))"))))




  (testing "a nested if in a match clause is reported"
    (is (= 1
           (length (function-findings "(defn run [x]
  (match x 1 (if x :one :other) _ :other))")))))




  (testing "a when with several leaf steps is clean"
    (is (= []
           (function-findings "(defn run [x]
  (when x (print x) (print :done)))"))))




  (testing "a loop with a leaf body is clean"
    (is (= []
           (function-findings "(defn run [xs]
  (each [_ x (ipairs xs)] (print x)))"))))




  (testing "a loop with an if in its body is reported"
    (is (= 1
           (length (function-findings "(defn run [xs]
  (each [_ x (ipairs xs)] (if x (print x) (print :none))))")))))




  (testing "a function literal passed to pcall is clean"
    (is (= []
           (function-findings "(defn run [] (pcall (fn [] (leaf))))"))))




  (testing "an icollect passed to table.concat is clean"
    (is (= []
           (function-findings "(defn run [xs]
  (table.concat (icollect [_ x (ipairs xs)] (f x)) \" \"))"))))




  (testing "an anonymous function body is checked independently"
    (is (= 1 (length (function-findings "(defn run [] (fn [] (if ok (if nested a b) c)))")))))




  (testing "a lambda body is checked independently"
    (is (= 1 (length (function-findings "(defn run [] (lambda [] (if ok (if nested a b) c)))")))))




  (testing "a unicode lambda body is checked independently"
    (is (= 1 (length (function-findings "(defn run [] (λ [] (if ok (if nested a b) c)))")))))




  (testing "a body-level fn with a non-leaf if body is reported"
    (is (= 1 (length (function-findings "(defn f [] (fn [] (if a b c)))")))))




  (testing "a body-level lambda with a non-leaf if body is reported"
    (is (= 1 (length (function-findings "(defn f [] (lambda [] (if a b c)))")))))




  (testing "a body-level unicode lambda with a non-leaf if body is reported"
    (is (= 1 (length (function-findings "(defn f [] (λ [] (if a b c)))")))))




  (testing "a top-level fn body with a non-leaf if is reported"
    (is (= 1 (length (function-findings "(fn named [] (if a (let [x 1] x) b))")))))




  (testing "a local fn with a nested loop body is reported"
    (is (= 1 (length (function-findings "(local f (fn [] (each [_ x (ipairs xs)] (when x (g x)))))")))))




  (testing "a local lambda body with a non-leaf if is reported"
    (is (= 1 (length (function-findings "(local f (lambda [] (if a (let [x 1] x) b)))")))))




  (testing "a local unicode lambda body with a non-leaf if is reported"
    (is (= 1 (length (function-findings "(local f (λ [] (if a (let [x 1] x) b)))")))))




  (testing "a top-level callback fn body with a non-leaf if is reported"
    (is (= 1 (length (function-findings "(foo (fn [] (if a (let [x 1] x) b)))")))))




  (testing "a local fn with a single if and leaf branches is clean"
    (is (= [] (function-findings "(local f (fn [] (if a b c)))"))))




  (testing "a nested fn violation is deduplicated under its defn"
    (is (= 1 (length (function-findings "(defn g [] (fn h [] (if a (let [x 1] x) b)))")))))




  (testing "a valid nested fn still makes its defn body report once"
    (is (= 1 (length (function-findings "(defn g [] (fn h [] (if a b c)))")))))




  (testing "a body-level fn with a leaf call body is clean"
    (is (= [] (function-findings "(defn f [] (fn [] (g a)))"))))




  (testing "a while with a leaf body is clean"
    (is (= []
           (function-findings "(defn run [x]
  (while x (set x false)))"))))




  (testing "several leaf body expressions are clean"
    (is (= []
           (function-findings "(defn run [x]
  (print x)
  (+ x 1)
  x)"))))




  (testing "quoted data is never flagged"
    (is (= []
           (function-findings "(defn run [] '(if x (let [a 1] a) b))"))))




  (testing "function-shape defaults to warning"
    (is (= [["function-shape" "fnl/app.fnl > defn:run > if#1 > then > if#1" "warning"]]
           (function-findings "(defn run [] (if x (if y a b) c))"))))




  (testing "function-shape uses the approved move-to-private-function message"
    (is (= "function body is too deep; move this into a named private function"
           (. (finding-summary (check-source "(defn run [] (if x (if y a b) c))" "fnl/app.fnl" {:module-style   [{:severity "off" :applies-to {} :options {} :exclusions []}]
                                                                                                :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})) 1 :message))))




  (testing "function-shape severity can be overridden to error"
    (is (= [["function-shape" "fnl/app.fnl > defn:run > if#1 > then > if#1" "error"]]
           (findings-for-rule "(defn run [] (if x (if y a b) c))" "fnl/app.fnl" "function-shape" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :function-shape [{:severity "error" :applies-to {} :options {} :exclusions []}]}))))




  (testing "function-shape can be disabled"
    (is (= []
           (findings-for-rule "(defn run [] (if x (if y a b) c))" "fnl/app.fnl" "function-shape" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :function-shape [{:severity "off" :applies-to {} :options {} :exclusions []}]}))))




  (testing "function-shape findings are unique and deterministic"
    (is (= [["function-shape" "fnl/app.fnl > defn:run > if#1 > then > if#1" "warning"]
            ["function-shape" "fnl/app.fnl > defn:run > if#1 > else > if#1" "warning"]]
           (function-findings "(defn run []
  (if x (if y a b) (if z c d)))")))))

(deftest lint-repo-properties




  (testing "project Fennel files have the approved rule counts"
    (is (= {"module-style"     24
            "module-import"    0
            "forbidden-form"   33
            "form-child-count" 3}
           (. (repo-scenario {:file-size [{:severity "off" :applies-to {} :options {} :exclusions []}]}) :counts))))




  (testing "lint implementation files report only the approved canonical findings"
    (is (= [["fnl/fennel-extras/lint/exclusion.fnl" "function-shape"]
            ["fnl/fennel-extras/lint/rules/module.fnl" "multiline-layout"]
            ["fnl/fennel-extras/lint/rules/module.fnl" "function-shape"]
            ["fnl/fennel-extras/lint/rules/module.fnl" "function-shape"]
            ["fnl/fennel-extras/lint/rules/module.fnl" "function-shape"]
            ["fnl/fennel-extras/lint/rules/module.fnl" "function-shape"]
            ["fnl/fennel-extras/lint/rules/module.fnl" "function-shape"]
            ["fnl/fennel-extras/lint/rules/registry.fnl" "multiline-layout"]
            ["fnl/fennel-extras/lint/rules/registry.fnl" "function-shape"]
            ["fnl/fennel-extras/lint/rules/registry.fnl" "function-shape"]
            ["fnl/fennel-extras/lint/rules/registry.fnl" "function-shape"]
            ["fnl/fennel-extras/lint/rules/registry.fnl" "function-shape"]
            ["fnl/fennel-extras/lint/rules/registry.fnl" "function-shape"]
            ["fnl/fennel-extras/lint/rules/registry.fnl" "function-shape"]
            ["fnl/fennel-extras/lint/rules/registry.fnl" "function-shape"]
            ["fnl/fennel-extras/lint/rules/registry.fnl" "function-shape"]
            ["fnl/fennel-extras/lint/rules/registry.fnl" "function-shape"]
            ["fnl/fennel-extras/lint/rules/registry.fnl" "if-without-else"]
            ["fnl/fennel-extras/lint/rules/spec.fnl" "multiline-layout"]
            ["fnl/fennel-extras/lint/rules.fnl" "function-shape"]
            ["fnl/fennel-extras/lint/rules.fnl" "function-shape"]
            ["fnl/fennel-extras/lint.fnl" "function-shape"]
            ["fnl/fennel-extras/lint.fnl" "function-shape"]
            ["fnl/fennel-extras/lint.fnl" "function-shape"]]
           (. (repo-scenario nil) :lint-files))))




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




  (testing "the shared compatibility policy enables all approved rules"
    (is (= 13 (policy-size (all-enabled-policy))))) )

(defn- first-finding-form
  [findings rule]
  (var result nil)
  (each [_ finding (ipairs findings)]
    (when (and (= result nil) (= (. finding :rule) rule))
      (set result (. finding :form))))
  result)




(deftest exclusions
  (let [source   "(defn run [] (if ok (do a b) c))"
        path     "fnl/app.fnl"
        rules    {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :function-shape [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]}
        baseline (check-context source {:path path :rules rules})
        form     (first-finding-form baseline "if-branch-call")]




    (testing "an exclusion suppresses only an exact rule and form match"
      (is (= []
             (check-context source
                            {:path       path
                             :rules      rules
                             :exclusions [{:rule   "if-branch-call"
                                           :form   form
                                           :reason "intentional"}]}))))




    (testing "an exclusion with the same form but a different rule does not suppress"
      (is (= ["if-branch-call"]
             (icollect [_
                        finding
                        (ipairs (check-context source
                                               {:path       path
                                                :rules      rules
                                                :exclusions [{:rule   "module-import"
                                                              :form   form
                                                              :reason "intentional"}]}))]
               (. finding :rule)))))




    (testing "an exclusion with the same rule but a different form does not suppress"
      (is (= ["if-branch-call"]
             (icollect [_
                        finding
                        (ipairs (check-context source
                                               {:path       path
                                                :rules      rules
                                                :exclusions [{:rule   "if-branch-call"
                                                              :form   (.. form " > other")
                                                              :reason "intentional"}]}))]
               (. finding :rule)))))))




(testing "a code exclusion matches text on an interior line of a multiline flagged branch"
  (let [source "(defn run []\n  (if ok\n      (do\n        a\n        foo)\n      c))"
        result (check-source-with-matcher source
                                          "fnl/app.fnl"
                                          {:module-style   [{:severity "off" :applies-to {} :options {} :exclusions []}]
                                           :function-shape [{:severity "off" :applies-to {} :options {} :exclusions []}]
                                           :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]}
                                          [{:rule   "if-branch-call"
                                            :code   "foo"
                                            :reason "intentional"}])]
    (is (= [] (finding-identities result)))))

(deftest normalized-exclusion-identities




  (testing "direct lint check suppresses a top-level branch using the printed normalized identity"
    (is (= []
           (check-context "(if ok (do a b) c)"
                          {:path       "fnl/app.fnl"
                           :rules      {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}
                           :exclusions [{:rule   "if-branch-call"
                                         :form   "fnl/app.fnl > top#1 > if#1 > then"
                                         :reason "intentional"}]}))))




  (testing "direct lint check suppresses top-level testing using the printed normalized identity"
    (is (= []
           (check-context "(testing \"two\" (is true) (is true))"
                          {:path       "fnl/spec/app_spec.fnl"
                           :rules      {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :module-import [{:severity "off" :applies-to {} :options {} :exclusions []}]}
                           :exclusions [{:rule   "form-child-count"
                                         :form   "fnl/spec/app_spec.fnl > top#1 > testing#1"
                                         :reason "intentional"}]})))))

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




  (testing "flags var in a source file as one warning"
    (is (= {:count 1 :rules ["forbidden-form"] :severities ["warning"]}
           (forbidden-form-summary "(var x 1)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}))))




  (testing "flags set in a source file as one warning"
    (is (= {:count 1 :rules ["forbidden-form"] :severities ["warning"]}
           (forbidden-form-summary "(set x 2)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}))))




  (testing "flags a field set in a source file as one warning"
    (is (= {:count 1 :rules ["forbidden-form"] :severities ["warning"]}
           (forbidden-form-summary "(set state.x 2)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}))))




  (testing "flags while in a source file as one warning"
    (is (= {:count 1 :rules ["forbidden-form"] :severities ["warning"]}
           (forbidden-form-summary "(while ok (g))" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}))))




  (testing "flags every mutation form in a nested while and set"
    (is (= {:count 1 :rules ["forbidden-form"] :severities ["warning"]}
           (forbidden-form-summary "(while ok (set x 1))" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}))))




  (testing "gives nested mutation findings distinct form identities"
    (let [forms (forbidden-form-forms "(defn f [] (let [a (set x 1)] (set y 2)))"
                                      "fnl/app.fnl"
                                      {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})]
      (is (= 0 (length forms)))))




  (testing "keeps nested mutation form identities stable across repeated linting"
    (let [source       "(defn f [] (let [a (set x 1)] (set y 2)))"
          first-forms  (forbidden-form-forms source "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})
          second-forms (forbidden-form-forms source "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})]
      (is (= first-forms second-forms))))




  (testing "lints mutation in unquoted quasiquote code"
    (is (= 0
           (length (forbidden-form-forms "(macro m [] `(foo ,(set x 1)))"
                                         "fnl/app.fnl"
                                         {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "does not lint mutation in quasiquoted data"
    (is (= 1
           (length (forbidden-form-forms "`(set x ,y)"
                                         "fnl/app.fnl"
                                         {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "lints only the outer unquote in nested quasiquote data"
    (is (= 0
           (. (forbidden-form-summary "(defn f [] `(outer ,(set x 1) `(set y ,(set z 2))))"
                                      "fnl/app.fnl"
                                      {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})
              :count))))




  (testing "lints a double-unquoted mutation at executable depth"
    (is (= 0
           (. (forbidden-form-summary "(defn f [] `(a `(b ,,(set x 1))))"
                                      "fnl/app.fnl"
                                      {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})
              :count))))




  (testing "does not lint mutation inside plain quote"
    (is (= 0
           (. (forbidden-form-summary "(defn f [] '(foo ,(set x 1)))"
                                      "fnl/app.fnl"
                                      {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})
              :count))))




  (testing "does not flag mutations in a spec file"
    (is (= {:count 0 :rules [] :severities []}
           (forbidden-form-summary "(var x 1) (set x 2) (while ok (g))"
                                   "fnl/spec/app_spec.fnl"
                                   nil))))




  (testing "does not flag non-mutation forms or quoted mutation data"
    (is (= {:count 1 :rules ["forbidden-form"] :severities ["warning"]}
           (forbidden-form-summary "(local x 1) (tset t :k v) (table.insert xs 1) '(set x 1) (set-foo 1)"
                                   "fnl/app.fnl"
                                   {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}))))




  (testing "uses error severity when configured"
    (is (= {:count 1 :rules ["forbidden-form"] :severities ["error"]}
           (forbidden-form-summary "(var x 1)"
                                   "fnl/app.fnl"
                                   {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :forbidden-form [{:severity "error" :applies-to {} :options {} :exclusions []}]}))))




  (testing "does not report when disabled"
    (is (= {:count 0 :rules [] :severities []}
           (forbidden-form-summary "(var x 1)"
                                   "fnl/app.fnl"
                                   {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :forbidden-form [{:severity "off" :applies-to {} :options {} :exclusions []}]}))))




  (testing "uses the suggested message"
    (is (= "forbidden form"
           (. (finding-summary (check-source "(var x 1)"
                                             "fnl/app.fnl"
                                             {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}))
              1
              :message)))))

(defn- if-without-else-findings
  [source path rules]
  (let [result (check-source source path rules)]
    (if (or (. result :module-missing) (. result :value-nil?))
      result
      (icollect [_ finding (ipairs result)]
        (when (= (. finding :rule) "if-without-else")
          finding)))))




(deftest if-without-else




  (testing "flags a two-argument if with the default warning and message"
    (let [findings (if-without-else-findings "(defn f [] (if a b))" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})]
      (is (= {:rule "if-without-else" :severity "warning" :message "if without else; use when"}
             {:rule     (. findings 1 :rule)
              :severity (. findings 1 :severity)
              :message  (. findings 1 :message)}))))




  (testing "does not flag complete or multi-clause if forms or when"
    (is (= 0
           (length (if-without-else-findings "(if a b c) (if a b c d e) (when a b)"
                                             "fnl/app.fnl"
                                             {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags a single-clause if whose else branch is literal nil"
    (let [finding (. (if-without-else-findings "(defn f\n  [ok resolved]\n  (if ok\n    resolved\n    nil))"
                                               "fnl/app.fnl"
                                               {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})
                     1)]
      (is (= {:rule     "if-without-else"
              :severity "warning"
              :message  "if without else; use when"}
             {:rule     (. finding :rule)
              :severity (. finding :severity)
              :message  (. finding :message)}))))




  (testing "does not flag a single-clause if with a non-nil else branch"
    (is (= 0
           (length (if-without-else-findings "(if a b c)"
                                             "fnl/app.fnl"
                                             {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "does not flag a multi-clause if ending in literal nil"
    (is (= 0
           (length (if-without-else-findings "(if a b c nil)"
                                             "fnl/app.fnl"
                                             {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "does not flag an if with a literal nil then branch"
    (is (= 0
           (length (if-without-else-findings "(if a nil b)"
                                             "fnl/app.fnl"
                                             {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags two nested if forms with distinct stable identities"
    (let [source "(defn f [] (do (if x y) (if x y)))"
          rules  {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}
          first  (if-without-else-findings source "fnl/app.fnl" rules)
          second (if-without-else-findings source "fnl/app.fnl" rules)]
      (is (and (= 2 (length first))
               (not= (. first 1 :form) (. first 2 :form))
               (vim.deep_equal (icollect [_ finding (ipairs first)] (. finding :form))
                               (icollect [_ finding (ipairs second)] (. finding :form)))))))




  (testing "an exclusion for one nested if leaves the other finding"
    (let [source   "(defn f [] (do (if x y) (if x y)))"
          path     "fnl/app.fnl"
          rules    {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}
          baseline (if-without-else-findings source path rules)
          form     (. baseline 1 :form)
          result   (check-context source
                                  {:path       path
                                   :rules      rules
                                   :exclusions [{:rule   "if-without-else"
                                                 :form   form
                                                 :reason "intentional"}]})]
      (is (= 1
             (length (icollect [_ finding (ipairs result)]
                       (when (= (. finding :rule) "if-without-else")
                         finding)))))))




  (testing "applies to spec files"
    (is (= 1
           (length (if-without-else-findings "(if a b)"
                                             "fnl/spec/app_spec.fnl"
                                             nil)))))




  (testing "ignores quoted if data and flags only executable unquoted quasiquote code"
    (is (= 1
           (length (if-without-else-findings "'(if a b) `(if a ,(if b c))"
                                             "fnl/app.fnl"
                                             {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "uses error severity when configured"
    (is (= "error"
           (. (if-without-else-findings "(if a b)"
                                        "fnl/app.fnl"
                                        {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :if-without-else [{:severity "error" :applies-to {} :options {} :exclusions []}]})
              1
              :severity))))




  (testing "does not report when disabled"
    (is (= 0
           (length (if-without-else-findings "(if a b)"
                                             "fnl/app.fnl"
                                             {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :if-without-else [{:severity "off" :applies-to {} :options {} :exclusions []}]}))))))

(defn- multiline-layout-findings
  [source path rules]
  (let [result (check-source source path rules)]
    (if (or (. result :module-missing) (. result :value-nil?))
      result
      (icollect [_ finding (ipairs result)]
        (when (= (. finding :rule) "multiline-layout")
          finding)))))




(deftest multiline-layout




  (testing "requires an if test on the head line"
    (is (= 1
           (length (multiline-layout-findings "(defn f\n  [file]\n  (if\n    file\n    (read file)\n    \"\"))"
                                              "fnl/app.fnl"
                                              {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "accepts an if test on the head line"
    (is (= 0
           (length (multiline-layout-findings "(defn f\n  [file]\n  (if file\n    (read file)\n    \"\"))"
                                              "fnl/app.fnl"
                                              {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "requires an and argument on the head line"
    (is (= 1
           (length (multiline-layout-findings "(defn f\n  [file]\n  (and\n    file\n    (close file)))"
                                              "fnl/app.fnl"
                                              {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "accepts an and argument on the head line"
    (is (= 0
           (length (multiline-layout-findings "(defn f\n  [file]\n  (and file\n    (close file)))"
                                              "fnl/app.fnl"
                                              {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "requires a plain call argument on the head line"
    (is (= 1 (length (multiline-layout-findings "(foo\n  a\n  b)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "accepts a plain call argument on the head line"
    (is (= 0 (length (multiline-layout-findings "(foo a\n     b)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "requires a let binding vector on the head line"
    (is (= 1 (length (multiline-layout-findings "(let\n  [x 1]\n  x)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "does not require a do body on the head line"
    (is (= 0 (length (multiline-layout-findings "(do\n  (a)\n  (b))" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "does not require a defn name on the next line"
    (is (= 0 (length (multiline-layout-findings "(defn f\n  [a]\n  a)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "requires a multi-clause if test on the head line"
    (is (= 1
           (length (multiline-layout-findings "(if\n  (> i n) false\n  (= p x) true\n  (rec))"
                                              "fnl/app.fnl"
                                              {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags a list with two items starting on one line"
    (is (= 1 (length (multiline-layout-findings "(foo a b\n  c)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "accepts a list with one item starting on each line"
    (is (= 0 (length (multiline-layout-findings "(foo a\n  b\n  c)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "accepts a one-line list"
    (is (= 0 (length (multiline-layout-findings "(foo a b c)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags a list whose head starts below its opening paren"
    (is (= 1
           (length (multiline-layout-findings "(\n foo a b)"
                                              "fnl/app.fnl"
                                              {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags a list with a delayed head inside a defn"
    (is (= 1
           (length (multiline-layout-findings "(defn f\n  []\n  (\n   foo a b))"
                                              "fnl/app.fnl"
                                              {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "does not flag vectors or maps whose first item starts below the opener"
    (is (= 0
           (+ (length (multiline-layout-findings "[\n 1\n 2]" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}))
              (length (multiline-layout-findings "{\n :a 1}" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}))))))




  (testing "flags a single-clause if whose then branch shares the head line"
    (is (= 1
           (length (multiline-layout-findings "(defn f\n  [n]\n  (if (> n 0) 1\n    0))"
                                              "fnl/app.fnl"
                                              {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "accepts a single-clause if with each branch on its own line"
    (is (= 0
           (length (multiline-layout-findings "(defn f\n  [n]\n  (if (> n 0)\n    1\n    0))"
                                              "fnl/app.fnl"
                                              {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "reports only multiline-layout for a malformed multi-line control form"
    (let [findings (check-source "(defn f\n  [n]\n  (if (> n 0) 1\n    0))" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})]
      (is (= ["multiline-layout"]
             (icollect [_ finding (ipairs findings)] (. finding :rule))))))




  (testing "flags a multi-line map with two pairs on one line"
    (is (= 1 (length (multiline-layout-findings "{:a 1 :b 2\n :c 3}" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "accepts a map with one pair starting on each line"
    (is (= 0 (length (multiline-layout-findings "{:a 1\n :b 2\n :c 3}" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "accepts a map whose value starts on the next line"
    (is (= 0 (length (multiline-layout-findings "{:a\n  (long-value)\n :b 2}" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags a vector with two elements starting on one line"
    (is (= 1 (length (multiline-layout-findings "[a b\n c]" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "accepts comments and multi-line strings between items"
    (is (= 0 (length (multiline-layout-findings "(foo a ; b\n  \"c\nd\"\n  e)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags a let binding vector with two bindings on one line"
    (is (= 1 (length (multiline-layout-findings "(let [a 1 b 2\n      c 3]\n  a)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "accepts a let binding vector with one binding on each line"
    (is (= 0 (length (multiline-layout-findings "(let [a 1\n      b 2]\n  a)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags a case with two clauses starting on one line"
    (is (= 1 (length (multiline-layout-findings "(case x\n  1 :a 2 :b\n  _ :c)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "accepts a multi-clause if with one pair on each line"
    (is (= 0 (length (multiline-layout-findings "(if (> i n) false\n  (= p x) true\n  (rec))" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags a unit that starts where the previous unit ends"
    (is (= 1 (length (multiline-layout-findings "(foo (bar\n       x) y)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "reports one finding for the inner call in a defn body"
    (let [findings (multiline-layout-findings "(defn f [a] (foo a b\n  c))" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})]
      (is (= 1 (length findings)))))




  (testing "reports one finding per nested offending form with distinct identities"
    (let [findings (multiline-layout-findings "(defn f [] (foo a b\n  (bar x y\n    z)))" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})]
      (is (and (= 2 (length findings))
               (not= (. findings 1 :form) (. findings 2 :form))))))




  (testing "an exclusion for one nested form leaves the other finding"
    (let [source   "(defn f [] (foo a b\n  (bar x y\n    z)))"
          path     "fnl/app.fnl"
          rules    {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}
          baseline (multiline-layout-findings source path rules)
          excluded (. baseline 1 :form)
          result   (check-context source
                                  {:path       path
                                   :rules      rules
                                   :exclusions [{:rule   "multiline-layout"
                                                 :form   excluded
                                                 :reason "intentional"}]})]
      (is (= 1
             (length (icollect [_ finding (ipairs result)]
                       (when (= (. finding :rule) "multiline-layout")
                         finding)))))))




  (testing "applies to spec files"
    (is (= 1 (length (multiline-layout-findings "(foo a b\n  c)" "fnl/spec/app_spec.fnl" nil)))))




  (testing "ignores quoted multi-line lists"
    (is (= 0 (length (multiline-layout-findings "'(a b\n c)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "uses the default warning and prescribed message"
    (let [finding (. (multiline-layout-findings "(foo a b\n  c)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}) 1)]
      (is (= {:severity "warning"
              :message  "multi-line form: put each item on its own line"}
             {:severity (. finding :severity)
              :message  (. finding :message)}))))




  (testing "uses error severity when configured"
    (is (= "error"
           (. (multiline-layout-findings "(foo a b\n  c)"
                                         "fnl/app.fnl"
                                         {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :multiline-layout [{:severity "error" :applies-to {} :options {} :exclusions []}]})
              1
              :severity))))




  (testing "does not report when disabled"
    (is (= 0
           (length (multiline-layout-findings "(foo a b\n  c)"
                                              "fnl/app.fnl"
                                              {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :multiline-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]}))))))

(defn- control-layout-findings
  [source path rules]
  (let [result (check-source source path rules)]
    (if (or (. result :module-missing) (. result :value-nil?))
      result
      (icollect [_ finding (ipairs result)]
        (when (= (. finding :rule) "control-layout")
          finding)))))




(deftest control-layout




  (testing "flags a one-line if in direct function statement position"
    (is (= 1
           (length (control-layout-findings "(defn f\n  [ok resolved]\n  (if ok resolved nil))"
                                            "fnl/app.fnl"
                                            {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "accepts a broken-out if in direct function statement position"
    (is (= 0
           (length (control-layout-findings "(defn f\n  [ok resolved]\n  (if ok\n    resolved\n    nil))"
                                            "fnl/app.fnl"
                                            {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags a one-line when in direct function statement position"
    (is (= 1
           (length (control-layout-findings "(defn f\n  [file]\n  (when (kept? file) file))"
                                            "fnl/app.fnl"
                                            {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "does not flag a one-line or as the last expression of a value-returning loop body"
    (is (= 0
           (length (control-layout-findings "(defn f\n  [es]\n  (accumulate [r false _ e (ipairs es)]\n    (or r (m? e))))"
                                            "fnl/app.fnl"
                                            {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "does not flag a one-line and as the returned function expression"
    (is (= 0
           (length (control-layout-findings "(defn f\n  [a b]\n  (and a b))"
                                            "fnl/app.fnl"
                                            {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags a one-line control form as the sole when body expression"
    (is (= 1
           (length (control-layout-findings "(defn f\n  [a b c]\n  (when a\n    (if b c a)))"
                                            "fnl/app.fnl"
                                            {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "accepts a broken-out or in a loop body"
    (is (= 0
           (length (control-layout-findings "(defn f\n  [es]\n  (accumulate [r false _ e (ipairs es)]\n    (or r\n      (m? e))))"
                                            "fnl/app.fnl"
                                            {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "does not flag controls when a do body has other expressions"
    (is (= 0
           (length (control-layout-findings "(defn f\n  [x]\n  (do (case x 1 :one _ :other)\n      (match x 1 :one _ :other)))"
                                            "fnl/app.fnl"
                                            {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags a one-line control form as the sole let body expression"
    (is (= 1
           (length (control-layout-findings "(defn f\n  [ok]\n  (let [x 1]\n    (if ok x 0)))"
                                            "fnl/app.fnl"
                                            {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags a one-line control form as the sole each body expression"
    (is (= 1
           (length (control-layout-findings "(defn f\n  [xs]\n  (each [_ x (ipairs xs)]\n    (if x x 0)))"
                                            "fnl/app.fnl"
                                            {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "does not require control forms in value, call, vector, map, or branch positions"
    (is (= 0
           (length (control-layout-findings "(defn f\n  [a b c]\n  (let [x (or a b)]\n    {:p (if a b c)\n     :q [(when a b)]}\n    (foo (if a b c))\n    (if a\n      (or b c)\n      c)))"
                                            "fnl/app.fnl"
                                            {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "does not flag nested controls when a do body has other expressions"
    (is (= 0
           (length (control-layout-findings "(defn f\n  []\n  (do (if a b c)\n      (when a b)))"
                                            "fnl/app.fnl"
                                            {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "applies to spec files"
    (is (= 1
           (length (control-layout-findings "(defn f [] (if a b c))"
                                            "fnl/spec/app_spec.fnl"
                                            nil)))))




  (testing "ignores quoted control-form data"
    (is (= 0
           (length (control-layout-findings "'(if a b c)"
                                            "fnl/app.fnl"
                                            {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "uses the stable identity, warning severity, and prescribed message"
    (let [finding (. (control-layout-findings "(defn f [] (if a b c))"
                                              "fnl/app.fnl"
                                              {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})
                     1)]
      (is (= {:form     "fnl/app.fnl > defn:f > if#1"
              :severity "warning"
              :message  "put this control form on several lines"}
             {:form     (. finding :form)
              :severity (. finding :severity)
              :message  (. finding :message)}))))




  (testing "uses error severity when configured"
    (is (= "error"
           (. (control-layout-findings "(defn f [] (if a b c))"
                                       "fnl/app.fnl"
                                       {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "error" :applies-to {} :options {} :exclusions []}]})
              1
              :severity))))




  (testing "does not report when disabled"
    (is (= 0
           (length (control-layout-findings "(defn f [] (if a b c))"
                                            "fnl/app.fnl"
                                            {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "an exclusion removes only the selected control-layout finding"
    (let [source   "(defn f [] (if a b c))\n(defn g [] (when a b))"
          path     "fnl/app.fnl"
          rules    {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}
          baseline (control-layout-findings source path rules)
          result   (check-context source
                                  {:path       path
                                   :rules      rules
                                   :exclusions [{:rule   "control-layout"
                                                 :form   (. baseline 1 :form)
                                                 :reason "intentional"}]})]
      (is (= 1
             (length (icollect [_ finding (ipairs result)]
                       (when (= (. finding :rule) "control-layout")
                         finding))))))))

(defn- unused-and-or-findings
  [source path rules]
  (let [result (check-source source path rules)]
    (if (or (. result :module-missing) (. result :value-nil?))
      result
      (icollect [_ finding (ipairs result)]
        (when (= (. finding :rule) "unused-and-or")
          finding)))))




(deftest unused-and-or




  (testing "flags a discarded and before the returned function expression"
    (is (= 1
           (length (unused-and-or-findings "(defn f\n  [file]\n  (and file (close file))\n  (out file))"
                                           "fnl/app.fnl"
                                           {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "does not flag the last and expression of a value-returning body"
    (is (= 0
           (length (unused-and-or-findings "(defn f\n  [a b]\n  (and a b))"
                                           "fnl/app.fnl"
                                           {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags or in an each body"
    (is (= 1
           (length (unused-and-or-findings "(defn f\n  [xs]\n  (each [_ x (ipairs xs)]\n    (or x (warn))))"
                                           "fnl/app.fnl"
                                           {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "does not flag and as the last icollect body expression"
    (is (= 0
           (length (unused-and-or-findings "(defn f\n  [xs]\n  (icollect [_ x (ipairs xs)]\n    (and x (f x))))"
                                           "fnl/app.fnl"
                                           {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags or before the returned let expression"
    (is (= 1
           (length (unused-and-or-findings "(defn f []\n  (let [x 1]\n    (or x (warn))\n    x))"
                                           "fnl/app.fnl"
                                           {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags and before the returned when expression"
    (is (= 1
           (length (unused-and-or-findings "(defn f []\n  (when ok\n    (and a (b))\n    c))"
                                           "fnl/app.fnl"
                                           {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags and before the returned do expression"
    (is (= 1
           (length (unused-and-or-findings "(defn f []\n  (do (and a (b)) c))"
                                           "fnl/app.fnl"
                                           {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "does not flag and or in value positions"
    (is (= 0
           (length (unused-and-or-findings "(defn f []\n  (let [y (and a b)] y)\n  (foo (or a b)))"
                                           "fnl/app.fnl"
                                           {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "ignores quoted and-or data"
    (is (= 0
           (length (unused-and-or-findings "'(and a b) '(or a b)"
                                           "fnl/app.fnl"
                                           {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "ignores and-or data in a quasiquote"
    (is (= 0
           (length (unused-and-or-findings "(defn f\n  []\n  (do `(and a b) out))"
                                           "fnl/app.fnl"
                                           {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "checks only unquoted and-or code through nested quasiquotes"
    (is (= 1
           (length (unused-and-or-findings "(defn f\n  []\n  `(do ,(do (and a (b)) c) `(do (and x y) z)))"
                                           "fnl/app.fnl"
                                           {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "checks and-or code inside an unquote"
    (is (= 1
           (length (unused-and-or-findings "(defn f\n  []\n  `(foo ,(do (or a (warn)) b)))"
                                           "fnl/app.fnl"
                                           {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "ignores plain quoted and-or data in a do body"
    (is (= 0
           (length (unused-and-or-findings "(defn f\n  []\n  (do '(and a b) out))"
                                           "fnl/app.fnl"
                                           {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "applies to spec files"
    (is (= 1
           (length (unused-and-or-findings "(defn f []\n  (and a b)\n  c)"
                                           "fnl/spec/app_spec.fnl"
                                           {:control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "gives nested discarded and-or forms distinct stable identities"
    (let [source "(defn f []\n  (do (and a b) (or c d) (out)))"
          rules  {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]}
          first  (unused-and-or-findings source "fnl/app.fnl" rules)
          second (unused-and-or-findings source "fnl/app.fnl" rules)]
      (is (and (= 2 (length first))
               (not= (. first 1 :form) (. first 2 :form))
               (vim.deep_equal (icollect [_ finding (ipairs first)] (. finding :form))
                               (icollect [_ finding (ipairs second)] (. finding :form)))))))




  (testing "uses the stable identity warning severity and prescribed message"
    (let [finding (. (unused-and-or-findings "(defn f []\n  (and a b)\n  c)"
                                             "fnl/app.fnl"
                                             {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})
                      1)]
      (is (= {:form     "fnl/app.fnl > defn:f > and#1"
              :severity "warning"
              :message  "and/or result is unused; use when"}
             {:form     (. finding :form)
              :severity (. finding :severity)
              :message  (. finding :message)}))))




  (testing "uses error severity when configured"
    (is (= "error"
           (. (unused-and-or-findings "(defn f []\n  (and a b)\n  c)"
                                      "fnl/app.fnl"
                                      {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}] :unused-and-or [{:severity "error" :applies-to {} :options {} :exclusions []}]})
              1
              :severity))))




  (testing "does not report when disabled"
    (is (= 0
           (length (unused-and-or-findings "(defn f []\n  (and a b)\n  c)"
                                           "fnl/app.fnl"
                                           {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}] :unused-and-or [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "an exclusion removes only the selected unused-and-or finding"
    (let [source   "(defn f []\n  (do (and a b) (or c d) (out)))"
          path     "fnl/app.fnl"
          rules    {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :control-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]}
          baseline (unused-and-or-findings source path rules)
          result   (check-context source
                                  {:path       path
                                   :rules      rules
                                   :exclusions [{:rule   "unused-and-or"
                                                 :form   (. baseline 1 :form)
                                                 :reason "intentional"}]})]
      (is (= 1
             (length (icollect [_ finding (ipairs result)]
                       (when (= (. finding :rule) "unused-and-or")
                         finding))))))))

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




  (testing "reports one finding for 301 code lines at the default limit"
    (is (= 1 (length (file-size-findings (repeated-code 301) "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]} nil nil)))))




  (testing "accepts exactly the configured code-line limit"
    (is (= 0 (length (file-size-findings (repeated-code 3) "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]} 3 nil)))))




  (testing "reports the first line above the configured code-line limit"
    (is (= 1 (length (file-size-findings (repeated-code 4) "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]} 3 nil)))))




  (testing "does not count blank or comment-only lines"
    (is (= 0 (length (file-size-findings "(local a 1)\n\n; comment\n  ; indented comment\n(local b 2)\n;; another comment\n" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]} 2 nil)))))




  (testing "counts lines inside a multiline string as code"
    (is (= 1 (length (file-size-findings "(local text [[first\nsecond]])" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]} 1 nil)))))




  (testing "does not report a spec file"
    (is (= 0 (length (file-size-findings (repeated-code 4) "fnl/spec/app_spec.fnl" {} 3 nil)))))




  (testing "uses warning severity by default"
    (is (= "warning" (. (file-size-findings (repeated-code 4) "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]} 3 nil) 1 :severity))))




  (testing "uses error severity when configured"
    (is (= "error" (. (file-size-findings (repeated-code 4) "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :file-size [{:severity "error" :applies-to {} :options {} :exclusions []}]} 3 nil) 1 :severity))))




  (testing "does not report when disabled"
    (is (= 0 (length (file-size-findings (repeated-code 4) "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :file-size [{:severity "off" :applies-to {} :options {} :exclusions []}]} 3 nil)))))




  (testing "includes the count and limit in the message"
    (let [message (. (file-size-findings (repeated-code 4) "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]} 3 nil) 1 :message)]
      (is (and (string.find message "4")
               (string.find message "3")))))




  (testing "uses a stable file-level identity"
    (is (= "fnl/app.fnl > file"
           (. (file-size-findings (repeated-code 4) "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]} 3 nil) 1 :form))))




  (testing "an exact file-size exclusion suppresses the finding"
    (let [finding   (file-size-findings (repeated-code 4) "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]} 3 nil)
          exclusion [{:rule "file-size" :form (. finding 1 :form) :reason "intentional"}]]
      (is (= 0 (length (file-size-findings (repeated-code 4) "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]} 3 exclusion)))))))

(deftest forbidden-form-exclusions




  (testing "an exact forbidden-form rule and form exclusion suppresses the finding"
    (let [source   "(set x 2)"
          path     "fnl/app.fnl"
          rules    {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}
          baseline (check-context source {:path path :rules rules})
          form     (first-finding-form baseline "forbidden-form")]
      (is (= []
             (check-context source
                            {:path       path
                             :rules      rules
                             :exclusions [{:rule   "forbidden-form"
                                           :form   form
                                           :reason "intentional"}]}))))))
(deftest forbidden-form-nested-exclusion




  (testing "an exclusion for one nested mutation leaves the other finding"
    (let [source    "(defn f [] (let [a (set x 1)] (set y 2)))"
          path      "fnl/app.fnl"
          rules     {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]}
          baseline  (check-context source {:path path :rules rules})
          form      (first-finding-form baseline "forbidden-form")
          remaining (check-context source
                                   {:path       path
                                    :rules      rules
                                    :exclusions [{:rule   "forbidden-form"
                                                  :form   form
                                                  :reason "intentional"}]})]
      (is (= 0 (length remaining))))))

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




(deftest call-data-arg




  (testing "flags a multiline map literal passed to a plain call"
    (is (= 1
           (length (findings-for-named-rule "(foo a {:x 1\n         :y 2})"
                                            "fnl/app.fnl"
                                            "call-data-arg"
                                            {:module-style     [{:severity "off" :applies-to {} :options {} :exclusions []}]
                                             :multiline-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "accepts a one-line map literal call argument"
    (is (= 0
           (length (findings-for-named-rule "(foo a {:x 1 :y 2})"
                                            "fnl/app.fnl"
                                            "call-data-arg"
                                            {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "accepts a map bound in a let before the call"
    (is (= 0
           (length (findings-for-named-rule "(let [opts {:x 1\n            :y 2}]\n  (foo a opts))"
                                            "fnl/app.fnl"
                                            "call-data-arg"
                                            {:module-style     [{:severity "off" :applies-to {} :options {} :exclusions []}]
                                             :multiline-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "excludes fn arguments from plain call data findings"
    (is (= 0
           (length (findings-for-named-rule "(foo (fn []\n  1))"
                                            "fnl/app.fnl"
                                            "call-data-arg"
                                            {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "treats values as a plain call"
    (is (= 1
           (length (findings-for-named-rule "(values {:a 1\n         :b 2} nil)"
                                            "fnl/app.fnl"
                                            "call-data-arg"
                                            {:module-style     [{:severity "off" :applies-to {} :options {} :exclusions []}]
                                             :multiline-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "flags a multiline vector literal passed to a plain call"
    (is (= 1
           (length (findings-for-named-rule "(foo [1\n      2])"
                                            "fnl/app.fnl"
                                            "call-data-arg"
                                            {:module-style     [{:severity "off" :applies-to {} :options {} :exclusions []}]
                                             :multiline-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "does not report in spec files"
    (is (= 0
           (length (findings-for-named-rule "(foo {:x 1\n      :y 2})"
                                            "fnl/spec/app_spec.fnl"
                                            "call-data-arg"
                                            nil)))))




  (testing "ignores quoted call data"
    (is (= 0
           (length (findings-for-named-rule "'(foo {:x 1\n      :y 2})"
                                            "fnl/app.fnl"
                                            "call-data-arg"
                                            {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]})))))




  (testing "uses the prescribed warning and message"
    (let [finding (. (findings-for-named-rule "(foo {:x 1\n      :y 2})"
                                              "fnl/app.fnl"
                                              "call-data-arg"
                                              {:module-style     [{:severity "off" :applies-to {} :options {} :exclusions []}]
                                               :multiline-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]})
                     1)]
      (is (= {:severity "warning"
              :message  "move this multi-line map/vector into a let binding so the call fits on one line"}
             {:severity (. finding :severity)
              :message  (. finding :message)}))))




  (testing "supports error severity and disabling"
    (is (= ["error" 0]
           [(let [finding (. (findings-for-named-rule "(foo {:x 1\n      :y 2})"
                                                      "fnl/app.fnl"
                                                      "call-data-arg"
                                                      {:module-style     [{:severity "off" :applies-to {} :options {} :exclusions []}]
                                                       :multiline-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]
                                                       :call-data-arg    [{:severity "error" :applies-to {} :options {} :exclusions []}]})
                              1)]
              (. finding :severity))
            (length (findings-for-named-rule "(foo {:x 1\n      :y 2})"
                                             "fnl/app.fnl"
                                             "call-data-arg"
                                             {:module-style     [{:severity "off" :applies-to {} :options {} :exclusions []}]
                                              :multiline-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]
                                              :call-data-arg    [{:severity "off" :applies-to {} :options {} :exclusions []}]}))]))))




(testing "keeps identities stable across repeated linting"
  (let [source "(foo {:x 1\n      :y 2})"
        rules  {:module-style     [{:severity "off" :applies-to {} :options {} :exclusions []}]
                :multiline-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]}
        first  (findings-for-named-rule source "fnl/app.fnl" "call-data-arg" rules)
        second (findings-for-named-rule source "fnl/app.fnl" "call-data-arg" rules)]
    (is (and (not= nil (. first 1 :form))
             (= (. first 1 :form) (. second 1 :form))))))




(testing "an exact exclusion suppresses the selected call finding"
  (let [source   "(foo {:x 1\n      :y 2})\n(bar {:a 1\n      :b 2})"
        path     "fnl/app.fnl"
        rules    {:module-style     [{:severity "off" :applies-to {} :options {} :exclusions []}]
                  :multiline-layout [{:severity "off" :applies-to {} :options {} :exclusions []}]}
        baseline (findings-for-named-rule source path "call-data-arg" rules)
        context  {:path       path
                  :rules      rules
                  :exclusions [{:rule   "call-data-arg"
                                :form   (. baseline 1 :form)
                                :reason "intentional"}]}
        result   (check-context source context)]
    (is (= 1
           (length (icollect [_ finding (ipairs result)]
                     (when (= (. finding :rule) "call-data-arg")
                       finding)))))))

(defn- option-rule
  [rule options]
  (let [merged (vim.tbl_extend "force" (. all-options rule) options)
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
  (let [context {:path    path
                 :rules   (option-rule rule options)
                 :matcher (matcher.vim-matcher)}]
    (lint.check source context)))




(defn- option-findings
  [source path rule options]
  (let [lint    (load-lint)
        matcher (load-matcher)]
    (if (or (. lint :module-missing) (. matcher :module-missing))
      {:module-missing true}
      (option-findings-call lint source path rule options))))




(deftest configurable-rule-options




  (testing "module-style accepts a configured macro module"
    (is (= 0
           (length (option-findings "(import-macros {: module : def : defn : defn-} :my.macros)\\n(module app)"
                                    "fnl/app.fnl"
                                    "module-style"
                                    {:module "my.macros"})))))




  (testing "module-style still flags the default macro module when configured away"
    (is (= 1
           (length (option-findings "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\\n(module app)"
                                    "fnl/app.fnl"
                                    "module-style"
                                    {:module "my.macros"})))))




  (testing "module-import accepts configured macro names and module"
    (is (= 0
           (length (option-findings "(import-macros {: check : verify} :my.spec.macros)"
                                    "fnl/spec/app_spec.fnl"
                                    "module-import"
                                    {:module "my.spec.macros" :forms ["check" "verify"]})))))




  (testing "module-import accepts configured exempt files"
    (is (= 0
           (length (option-findings "(deftest run)"
                                    "fnl/spec/app_spec.fnl"
                                    "module-import"
                                    {:exempt-files ["^fnl/spec/app_spec[.]fnl$"]})))))




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
                                    {:mode "forbid" :modules ["custom.test"] :exempt-files []})))))




  (testing "module-import accepts configured exempt files"
    (is (= 0
           (length (option-findings "(require :custom.test)"
                                    "fnl/spec/app_spec.fnl"
                                    "module-import"
                                    {:mode "forbid" :modules ["custom.test"] :exempt-files ["^fnl/spec/app_spec[.]fnl$"]})))))




  (testing "form-child-count accepts configured testing and assertion forms"
    (is (= 0
           (length (option-findings "(checking \"one\" (assertion true))"
                                    "fnl/spec/app_spec.fnl"
                                    "form-child-count"
                                    {:children ["assertion"] :max-count 1})))))




  (testing "if-branch-call accepts configured conditional forms"
    (is (= 1
           (length (option-findings "(unless ok (do a b) c)"
                                    "fnl/app.fnl"
                                    "if-branch-call"
                                    {:forms ["unless"]})))))




  (testing "if-without-else accepts configured conditional forms and nil policy"
    (is (= 0
           (length (option-findings "(unless ok value nil)"
                                    "fnl/app.fnl"
                                    "if-without-else"
                                    {:forms ["unless"] :nil-else false})))))




  (testing "control-layout accepts configured control forms"
    (is (= 1
           (length (option-findings "(unless ok\\n  a\\n  b)"
                                    "fnl/app.fnl"
                                    "control-layout"
                                    {:forms ["unless"]})))))




  (testing "unused-and-or accepts configured forms"
    (is (= 1
           (length (option-findings "(xor a b)"
                                    "fnl/app.fnl"
                                    "unused-and-or"
                                    {:forms ["xor"]})))))




  (testing "function-shape accepts configured function forms"
    (is (= 1
           (length (option-findings "(fnx f [] (if a (if b c d) e))"
                                    "fnl/app.fnl"
                                    "function-shape"
                                    {:forms ["fnx"]})))))




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




  (testing "multiline-layout accepts configured clause and binding forms"
    (is (= 1
           (length (option-findings "(branch x\\n  a b) (bind [a 1 b 2] a)"
                                    "fnl/app.fnl"
                                    "multiline-layout"
                                    {:clauses ["branch"] :bindings ["bind"]})))))




  (testing "module-import accepts configured module and binding"
    (is (= 0
           (length (option-findings "(local c (require :my.core))"
                                    "fnl/app.fnl"
                                    "module-import"
                                    {:mode "require" :mode "require" :module "my.core" :binding "c"})))))




  (testing "call-data-arg ignores configured call heads"
    (is (= 0
           (length (option-findings "(special [1\\n  2])"
                                    "fnl/app.fnl"
                                    "call-data-arg"
                                    {:forms ["special"]})))))
  (deftest selector-exclusions




    (testing "matches an exclusion pattern against the repository-relative path"
      (is (= []
             (finding-summary (check-source-with-matcher "(if ok then)" "fnl/legacy/a.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :if-without-else [{:severity "warning" :applies-to {} :options {} :exclusions []}]} [{:rule "if-without-else" :pattern "^fnl/legacy/"}])))))




    (testing "matches a single finding line"
      (is (= 1
             (length (check-source-with-matcher "(if one then)\n\n(if two then)"
                                                "fnl/app.fnl"
                                                {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :if-without-else [{:severity "warning" :applies-to {} :options {} :exclusions []}]}
                                                [{:rule "if-without-else" :line 1}])))))




    (testing "matches an intersecting line range"
      (is (= 1
             (length (check-source-with-matcher "(if one then)\n\n(if two then)"
                                                "fnl/app.fnl"
                                                {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :if-without-else [{:severity "warning" :applies-to {} :options {} :exclusions []}]}
                                                [{:rule "if-without-else" :lines {:from 1 :to 2}}])))))




    (testing "matches code in the finding form"
      (is (= []
             (finding-summary (check-source-with-matcher "(if ok then)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :if-without-else [{:severity "warning" :applies-to {} :options {} :exclusions []}]} [{:rule "if-without-else" :code "if"}])))))




    (testing "matches code only against the selected finding source"
      (let [result (check-source-with-matcher "(var baz 1)\n(var foo 2)"
                                              "fnl/app.fnl"
                                              {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :forbidden-form [{:severity "warning" :applies-to {} :options {} :exclusions []}]}
                                              [{:rule "forbidden-form" :code "baz"}])]
        (is (= [["forbidden-form" "fnl/app.fnl > top#2" "warning"]]
               (finding-identities result)))))




    (testing "combines path and line selectors with AND semantics"
      (is (= []
             (finding-summary (check-source-with-matcher "(if ok then)" "fnl/app.fnl" {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :if-without-else [{:severity "warning" :applies-to {} :options {} :exclusions []}]} [{:rule "if-without-else" :pattern "app[.]fnl" :line 1}] )))))




    (testing "a general exclusion without a rule applies to every rule"
      (is (= []
             (finding-summary (check-source-with-matcher "(if ok then)" "fnl/app.fnl" {:module-style [{:severity "error" :applies-to {} :options {} :exclusions []}] :if-without-else [{:severity "warning" :applies-to {} :options {} :exclusions []}]} [{:pattern "app[.]fnl" :line 1}])))))




    (testing "a per-rule exclusion applies only to its configured rule"
      (let [result (check-source-with-matcher "(module a)\n(if ok then)"
                                              "fnl/app.fnl"
                                              {:module-style    [{:severity   "error"
                                                                  :applies-to {:files ["^fnl/[^s]"]}
                                                                  :options    (. all-options "module-style")
                                                                  :exclusions []}]
                                               :if-without-else [{:severity   "warning"
                                                                  :applies-to {}
                                                                  :options    (. all-options "if-without-else")
                                                                  :exclusions []}]}
                                              [{:rule   "module-style"
                                                :path   "fnl/app.fnl"
                                                :reason "intentional"}])]
        (is (= ["if-without-else"]
               (icollect [_ finding (ipairs result)] (. finding :rule))))))




    (testing "a code selector does not match a file-level finding"
      (is (= 1
             (length (check-source-with-matcher "(local value 1)"
                                                "fnl/app.fnl"
                                                {:module-style [{:severity "error" :applies-to {} :options {} :exclusions []}]}
                                                [{:rule "module-style" :code "local"}])))))




    (testing "a regex exclusion without a matcher returns an error"
      (let [lint            (load-lint)
            (ok result err) (pcall (fn []
                                     (lint.check "(if ok then)"
                                                 {:path       "fnl/app.fnl"
                                                  :rules      {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}] :if-without-else [{:severity "warning" :applies-to {} :options {} :exclusions []}]}
                                                  :exclusions [{:rule    "if-without-else"
                                                                :pattern "app[.]fnl"}]})))]



        (is (and (not (. lint :module-missing))
                 (not ok)
                 result
                 (. result :message))))))

  (deftest shipped-bug-regressions




    (testing "a listed rule leaves unlisted rules disabled"
      (let [result (check-source-exact "(if ok then)\n(var x 1)"
                                       "fnl/app.fnl"
                                       {:module-style    [{:severity "off" :applies-to {} :options {} :exclusions []}]
                                        :if-without-else [{:severity   "warning"
                                                           :applies-to {:forms ["if"]}
                                                           :options    {:nil-else true}
                                                           :exclusions []}]})]
        (is (= ["if-without-else"]
               (icollect [_ finding (ipairs result)] (. finding :rule))))))




    (testing "file-size honors a nested max-code-lines option"
      (let [source "(module a)\n(local a 1)\n(local b 2)\n(local c 3)\n(local d 4)"
            result (check-source source
                                 "fnl/app.fnl"
                                 {:module-style [{:severity "off" :applies-to {} :options {} :exclusions []}]
                                  "file-size"   [{:severity   "warning"
                                                  :applies-to {:files ["^fnl/[^s]"]}
                                                  :options    {:max-code-lines 3}
                                                  :exclusions []}]})]
        (is (= ["file-size"]
               (icollect [_ finding (ipairs result)] (. finding :rule))))))




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

  (testing "the no-mutation alias path reports the moved design rule"
    (let [result (check-source-exact "(set state.value 1)"
                                     "fnl/app.fnl"
                                     {:design {:rules {:no-mutation [{:severity   "warning"
                                                                      :applies-to {:forms ["set"]}
                                                                      :options    {}
                                                                      :exclusions []}]}}})]
      (is (= ["no-mutation"]
             (icollect [_ finding (ipairs result)] (. finding :rule)))))))

(deftest module-selector-vector-compatibility

  (testing "semantic singleton module vectors preserve scalar behavior"
    (let [forbidden-source "(module other)"
          forbidden-scalar (finding-identities
                            (check-source-exact forbidden-source
                                                "fnl/app.fnl"
                                                {:forbidden-form [{:severity   "warning"
                                                                   :applies-to {:modules "app"
                                                                                :forms   []}
                                                                   :options    {}
                                                                   :exclusions []}]}))
          forbidden-vector (finding-identities
                            (check-source-exact forbidden-source
                                                "fnl/app.fnl"
                                                {:forbidden-form [{:severity   "warning"
                                                                   :applies-to {:modules ["app"]
                                                                                :forms   []}
                                                                   :options    {}
                                                                   :exclusions []}]}))
          require-source   "(require :eca.nfnl.core extra)"
          require-scalar   (finding-identities
                            (check-source-exact require-source
                                                "fnl/app.fnl"
                                                {:module-import [{:severity   "error"
                                                                  :applies-to {:modules "eca.nfnl.core"}
                                                                  :options    {:mode    "require"
                                                                               :binding "core"}
                                                                  :exclusions []}]}))
          require-vector   (finding-identities
                            (check-source-exact require-source
                                                "fnl/app.fnl"
                                                {:module-import [{:severity   "error"
                                                                  :applies-to {:modules ["eca.nfnl.core"]}
                                                                  :options    {:mode    "require"
                                                                               :binding "core"}
                                                                  :exclusions []}]}))
          style-source     "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)"
          style-scalar     (finding-identities
                            (check-source-exact style-source
                                                "fnl/app.fnl"
                                                {:module-style [{:severity   "error"
                                                                 :applies-to {:modules "eca.nfnl.macros.aniseed"
                                                                              :forms   ["module" "def" "defn" "defn-"]}
                                                                 :options    {}
                                                                 :exclusions []}]}))
          style-vector     (finding-identities
                            (check-source-exact style-source
                                                "fnl/app.fnl"
                                                {:module-style [{:severity   "error"
                                                                 :applies-to {:modules ["eca.nfnl.macros.aniseed"]
                                                                              :forms   ["module" "def" "defn" "defn-"]}
                                                                 :options    {}
                                                                 :exclusions []}]}))]
      (is (and (vim.deep_equal [] forbidden-scalar)
               (vim.deep_equal forbidden-scalar forbidden-vector)
               (vim.deep_equal require-scalar require-vector)
               (vim.deep_equal style-scalar style-vector)))))

  (testing "scalar generic module selectors behave as one-item vectors"
    (let [finding     {:path "fnl/app.fnl" :node {:text "my.module"}}
          vim-matcher (matcher.vim-matcher)
          (scalar-ok scalar)
          (pcall (fn []
                   (registry.instance-applies-to? "control-layout"
                                                  {:applies-to {:modules "my.module"}}
                                                  finding
                                                  vim-matcher)))

          (vector-ok vector)
          (pcall (fn []
                   (registry.instance-applies-to? "control-layout"
                                                  {:applies-to {:modules ["my.module"]}}
                                                  finding
                                                  vim-matcher)))]

      (is (and scalar-ok
               vector-ok
               (= vector scalar))))))
