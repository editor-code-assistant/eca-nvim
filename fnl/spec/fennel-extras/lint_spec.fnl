(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(defn- load-lint
  []
  (let [(ok result) (pcall require :fennel-extras.lint)]
    (if ok
      result
      {:module-missing true})))

(defn- all-enabled-policy
  []
  {"module-style"        :error
   "spec-macro-import"   :error
   "spec-no-module"      :error
   "spec-direct-require" :error
   "one-is-per-testing"  :error
   "if-branch-call"      :warning
   "if-without-else"     :warning
   "control-layout"      :warning
   "defn-args-newline"   :warning
   "multiline-layout"    :warning
   "function-shape"      :warning
   "no-mutation"         :warning
   "file-size"           :warning
   "core-require"        :error
   "unused-and-or"       :warning
   "binding-per-line"    :warning
   "call-data-arg"       :warning})

(defn- policy-size
  [policy]
  (var count 0)
  (each [_ _ (pairs policy)]
    (set count (+ count 1)))
  count)

(defn- check-source
  [source path rules]
  (let [lint (load-lint)]
    (if (. lint :module-missing)
      lint
      (let [ctx            {:path path :rules (or rules (all-enabled-policy))}
            (findings err) (lint.check source ctx)]
        (if findings
          findings
          {:value-nil? true
           :message    (and err (. err :message))
           :line       (and err (. err :line))
           :col        (and err (. err :col))})))))

(defn- load-matcher
  []
  (let [(ok result) (pcall require :fennel-extras.cli.matcher)]
    (if ok
      result
      {:module-missing true})))

(defn- check-source-with-matcher
  [source path rules exclusions]
  (let [lint    (load-lint)
        matcher (load-matcher)]
    (if (or (. lint :module-missing) (. matcher :module-missing))
      {:module-missing true}
      (let [(ok value err) (pcall (fn []
                                    (let [ctx {:path       path
                                               :rules      (or rules (all-enabled-policy))
                                               :exclusions exclusions
                                               :matcher    (matcher.vim-matcher)}]
                                      (lint.check source ctx))))]
        (if ok
          value
          {:value-nil? true :message (and err (. err :message))})))))

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

(defn- collect-repo-findings
  [lint counts lint-files cli-files rules]
  (each [_ path (ipairs (project-fennel-files))]
    (let [source (read-source path)]
      (if (. source :error)
        (if (string.find path "^fnl/fennel%-extras/cli")
          (table.insert cli-files path)
          (table.insert lint-files path))
        (let [context  {:path path :rules (or rules (all-enabled-policy))}
              findings (lint.check source context)]
          (each [_ finding (ipairs findings)]
            (when (. counts (. finding :rule))
              (tset counts (. finding :rule) (+ (. counts (. finding :rule)) 1))))
          (if (string.find path "^fnl/fennel%-extras/cli")
            (each [_ finding (ipairs findings)]
              (table.insert cli-files [path (. finding :rule)]))
            (when (string.find path "^fnl/fennel%-extras/lint")
              (each [_ finding (ipairs findings)]
                (table.insert lint-files [path (. finding :rule)]))))))))
  {:counts counts :lint-files lint-files :cli-files cli-files})

(defn- repo-scenario
  [rules]
  (let [lint       (load-lint)
        counts     {"module-style"        0
                    "spec-macro-import"   0
                    "spec-no-module"      0
                    "spec-direct-require" 0
                    "one-is-per-testing"  0
                    "core-require"        0}
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
                      {"defn-args-newline" :off}))))
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
    (is (= [["spec-macro-import" "fnl/spec/app_spec.fnl > spec" "error"]]
           (forms-for "(import-macros {: deftest : testing} :spec.eca.macros)"
                      "fnl/spec/app_spec.fnl"
                      nil))))
  (testing "a spec macro import from another module is reported"
    (is (= [["spec-macro-import" "fnl/spec/app_spec.fnl > spec" "error"]]
           (forms-for "(import-macros {: deftest : testing : is} :other.macros)"
                      "fnl/spec/app_spec.fnl"
                      nil))))
  (testing "a spec with no macro import has the spec identity"
    (is (= [["spec-macro-import" "fnl/spec/app_spec.fnl > spec" "error"]]
           (forms-for "(deftest run (is true))" "fnl/spec/app_spec.fnl" nil))))
  (testing "a prefixed spec macro import is reported"
    (is (= [["spec-macro-import" "fnl/spec/app_spec.fnl > spec" "error"]]
           (findings-for-rule "'(import-macros {: deftest : testing : is} :spec.eca.macros)"
                              "fnl/spec/app_spec.fnl"
                              "spec-macro-import"))))
  (testing "a nested spec macro import is reported"
    (is (= [["spec-macro-import" "fnl/spec/x_spec.fnl > spec" "error"]]
           (findings-for-rule "(do (import-macros {: deftest : testing : is} :spec.eca.macros))\n(deftest run (testing \"works\" (is true)))"
                              "fnl/spec/x_spec.fnl"
                              "spec-macro-import"))))
  (testing "a wrong macro import is reported independently of test content"
    (is (= [["spec-macro-import" "fnl/spec/app_spec.fnl > spec" "error"]]
           (forms-for "(import-macros {: deftest} :other) (deftest t (testing \"x\" (is true)))"
                      "fnl/spec/app_spec.fnl"
                      nil))))
  (testing "a spec with only a direct require still has the spec identity"
    (is (= [["spec-macro-import" "fnl/spec/app_spec.fnl > spec" "error"]]
           (forms-for "(require :foo)" "fnl/spec/app_spec.fnl" nil))))
  (testing "a module form in a spec is reported at that form"
    (is (= [["spec-no-module" "fnl/spec/app_spec.fnl > module:app" "error"]]
           (forms-for "(module app)\n(import-macros {: deftest : testing : is} :spec.eca.macros)"
                      "fnl/spec/app_spec.fnl"
                      nil))))

  (deftest spec-direct-require
    (testing "keyword plenary require is forbidden in ordinary specs"
      (is (= [["spec-direct-require" "fnl/spec/app_spec.fnl > top#1" "error"]]
             (findings-for-rule "(require :plenary.busted)" "fnl/spec/app_spec.fnl" "spec-direct-require"))))
    (testing "string luassert require is forbidden in ordinary specs"
      (is (= [["spec-direct-require" "fnl/spec/app_spec.fnl > top#1" "error"]]
             (findings-for-rule "(require \"luassert\")" "fnl/spec/app_spec.fnl" "spec-direct-require"))))
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

  (deftest one-is-per-testing
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
      (is (= [["one-is-per-testing" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
             (findings-for-rule "(deftest run (testing \"none\" (let [x 1] x)))"
                                "fnl/spec/app_spec.fnl"
                                "one-is-per-testing"))))
    (testing "testing with two is forms is reported once"
      (is (= [["one-is-per-testing" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
             (findings-for-rule "(deftest run (testing \"two\" (is true) (is true)))"
                                "fnl/spec/app_spec.fnl"
                                "one-is-per-testing"))))
    (testing "nested testing forms are counted separately"
      (is (= [["one-is-per-testing" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
             (findings-for-rule "(deftest run (testing \"outer\" (testing \"inner\" (is true))))"
                                "fnl/spec/app_spec.fnl"
                                "one-is-per-testing"))))
    (testing "quoted is data is not counted"
      (is (= [["one-is-per-testing" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
             (findings-for-rule "(deftest run (testing \"quoted\" '(is true)))"
                                "fnl/spec/app_spec.fnl"
                                "one-is-per-testing"))))
    (testing "a quoted is separated by a comment is not counted"
      (is (= [["one-is-per-testing" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
             (findings-for-rule "(deftest run (testing \"x\" '
 ;; comment
 (is true)))"
                                "fnl/spec/app_spec.fnl"
                                "one-is-per-testing"))))
    (testing "a quasiquoted is separated by a newline is not counted"
      (is (= [["one-is-per-testing" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
             (findings-for-rule "(deftest run (testing \"x\" `
(is true)))"
                                "fnl/spec/app_spec.fnl"
                                "one-is-per-testing"))))
    (testing "a quoted is separated by whitespace is not counted"
      (is (= [["one-is-per-testing" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
             (findings-for-rule "(deftest run (testing \"x\" ' (is true)))"
                                "fnl/spec/app_spec.fnl"
                                "one-is-per-testing"))))
    (testing "a quoted is plus an executable is is counted once"
      (is (= []
             (findings-for-rule "(deftest run (testing \"x\" '(is false) (is true)))"
                                "fnl/spec/app_spec.fnl"
                                "one-is-per-testing"))))
    (testing "strings and comments containing is are not counted"
      (is (= [["one-is-per-testing" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
             (findings-for-rule "(deftest run (testing \"is in text\" (print \"is\"))) ;; is\n"
                                "fnl/spec/app_spec.fnl"
                                "one-is-per-testing")))))

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
                                {"if-branch-call" :error}))))
    (testing "if branch rule can be disabled"
      (is (= []
             (findings-for-rule "(defn run [] (if ok (do a b) c))"
                                "fnl/app.fnl"
                                "if-branch-call"
                                {"if-branch-call" :off}))))

    (deftest core-require
      (testing "the core local binding uses the canonical name"
        (is (= []
               (forms-for "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(local core (require :eca.nfnl.core))" "fnl/app.fnl" nil))))
      (testing "a core local with extra expressions is reported"
        (is (= [["core-require" "fnl/app.fnl > local:core" "error"]]
               (findings-for-rule "(local core (require :eca.nfnl.core) other)" "fnl/app.fnl" "core-require"))))
      (testing "a string core local binding uses the canonical shape"
        (is (= []
               (forms-for "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(local core (require \"eca.nfnl.core\"))" "fnl/app.fnl" nil))))
      (testing "a non-core local binding is reported"
        (is (= [["core-require" "fnl/app.fnl > local:c" "error"]]
               (findings-for-rule "(local c (require :eca.nfnl.core))" "fnl/app.fnl" "core-require"))))
      (testing "a keyword core require with extra expressions is reported"
        (is (= [["core-require" "fnl/app.fnl > top#1" "error"]]
               (findings-for-rule "(require :eca.nfnl.core extra)" "fnl/app.fnl" "core-require"))))
      (testing "a string core require with extra expressions is reported"
        (is (= [["core-require" "fnl/app.fnl > top#1" "error"]]
               (findings-for-rule "(require \"eca.nfnl.core\" extra)" "fnl/app.fnl" "core-require")))))

    (deftest determinism-and-boundary
      (testing "the same source produces identical sorted findings"
        (is (= [["if-branch-call" "fnl/app.fnl > defn:run > if#1 > then" "warning"]
                ["if-branch-call" "fnl/app.fnl > defn:run > if#1 > else" "warning"]]
               (findings-for-rule "(defn run [] (if ok (do a b) (do c d)))" "fnl/app.fnl" "if-branch-call" {"module-style" :off}))))
      (testing "no two findings share path rule and form"
        (is (= {:findings   [["if-branch-call" "fnl/app.fnl > defn:run > if#1 > then" "warning"]
                             ["if-branch-call" "fnl/app.fnl > defn:run > if#1 > else" "warning"]]
                :duplicates []}
               (let [findings   (findings-for-rule "(defn run [] (if ok (do a b) (do c d)))" "fnl/app.fnl" "if-branch-call" {"module-style" :off})
                     seen       {}
                     duplicates []]
                 (each [_ value (ipairs findings)]
                   (let [key (.. (. value 1) "|" (. value 2))]
                     (if (. seen key)
                       (table.insert duplicates key)
                       (tset seen key true))))
                 {:findings findings :duplicates duplicates}))))
      (testing "the pure core returns findings without executing vim api text"
        (is (= [["core-require" "fnl/app.fnl > top#1" "error"]]
               (findings-for-rule "(require :eca.nfnl.core extra)\n(vim.api.nvim_set_option_value :x 1 {})"
                                  "fnl/app.fnl"
                                  "core-require"))))
      (testing "reader failure returns nil and a structured error table"
        (is (= {:value-nil? true :message "missing closing delimiter" :line 1 :col 1}
               (check-source "(unclosed" "fnl/bad.fnl" nil)))))))

(defn- function-findings
  [source]
  (findings-for-rule source "fnl/app.fnl" "function-shape" {"module-style" :off}))

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
           (. (finding-summary (check-source "(defn run [] (if x (if y a b) c))" "fnl/app.fnl" {"module-style" :off})) 1 :message))))
  (testing "function-shape severity can be overridden to error"
    (is (= [["function-shape" "fnl/app.fnl > defn:run > if#1 > then > if#1" "error"]]
           (findings-for-rule "(defn run [] (if x (if y a b) c))" "fnl/app.fnl" "function-shape" {"module-style" :off "function-shape" :error}))))
  (testing "function-shape can be disabled"
    (is (= []
           (findings-for-rule "(defn run [] (if x (if y a b) c))" "fnl/app.fnl" "function-shape" {"module-style" :off "function-shape" :off}))))
  (testing "function-shape findings are unique and deterministic"
    (is (= [["function-shape" "fnl/app.fnl > defn:run > if#1 > then > if#1" "warning"]
            ["function-shape" "fnl/app.fnl > defn:run > if#1 > else > if#1" "warning"]]
           (function-findings "(defn run []
  (if x (if y a b) (if z c d)))")))))

(deftest repo-properties
  (testing "project Fennel files have the approved rule counts"
    (is (= {"module-style"        24
            "spec-macro-import"   0
            "spec-no-module"      0
            "spec-direct-require" 0
            "one-is-per-testing"  0
            "core-require"        0}
           (. (repo-scenario {"file-size" :off}) :counts))))
  (testing "lint implementation files are clean"
    (is (= [] (. (repo-scenario nil) :lint-files))))
  (testing "cli implementation files are clean"
    (is (= [] (. (repo-scenario nil) :cli-files)))) )

(defn- check-context
  [source ctx]
  (let [lint (load-lint)]
    (if (. lint :module-missing)
      lint
      (let [(findings err) (lint.check source ctx)]
        (if findings
          findings
          {:value-nil? true :error err})))))

(deftest opt-in-policy
  (testing "lint check reports no findings when rules are omitted"
    (is (= []
           (check-context "(local c (require :eca.nfnl.core))"
                          {:path "fnl/app.fnl"}))))
  (testing "the shared compatibility policy enables all approved rules"
    (is (= 17 (policy-size (all-enabled-policy))))) )

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
        rules    {"module-style" :off "function-shape" :off "defn-args-newline" :off "control-layout" :off}
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
                                                :exclusions [{:rule   "core-require"
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
                                          {"module-style"      :off
                                           "function-shape"    :off
                                           "defn-args-newline" :off
                                           "control-layout"    :off}
                                          [{:rule   "if-branch-call"
                                            :code   "foo"
                                            :reason "intentional"}])]
    (is (= [] (finding-identities result)))))

(deftest normalized-exclusion-identities
  (testing "direct lint check suppresses a top-level branch using the printed normalized identity"
    (is (= []
           (check-context "(if ok (do a b) c)"
                          {:path       "fnl/app.fnl"
                           :rules      {"module-style" :off}
                           :exclusions [{:rule   "if-branch-call"
                                         :form   "fnl/app.fnl > top#1 > if#1 > then"
                                         :reason "intentional"}]}))))
  (testing "direct lint check suppresses top-level testing using the printed normalized identity"
    (is (= []
           (check-context "(testing \"two\" (is true) (is true))"
                          {:path       "fnl/spec/app_spec.fnl"
                           :rules      {"module-style" :off "spec-macro-import" :off}
                           :exclusions [{:rule   "one-is-per-testing"
                                         :form   "fnl/spec/app_spec.fnl > top#1 > testing#1"
                                         :reason "intentional"}]})))))

(defn- no-mutation-summary
  [source path rules]
  (let [result (findings-for-rule source path "no-mutation" rules)]
    (if (or (. result :module-missing) (. result :value-nil?))
      result
      {:count      (length result)
       :rules      (icollect [_ finding (ipairs result)] (. finding 1))
       :severities (icollect [_ finding (ipairs result)] (. finding 3))})))

(defn- no-mutation-forms
  [source path rules]
  (let [result (check-source source path rules)]
    (if (or (. result :module-missing) (. result :value-nil?))
      result
      (icollect [_ finding (ipairs result)]
        (when (= (. finding :rule) "no-mutation")
          (. finding :form))))))

(deftest no-mutation
  (testing "flags var in a source file as one warning"
    (is (= {:count 1 :rules ["no-mutation"] :severities ["warning"]}
           (no-mutation-summary "(var x 1)" "fnl/app.fnl" {"module-style" :off}))))
  (testing "flags set in a source file as one warning"
    (is (= {:count 1 :rules ["no-mutation"] :severities ["warning"]}
           (no-mutation-summary "(set x 2)" "fnl/app.fnl" {"module-style" :off}))))
  (testing "flags a field set in a source file as one warning"
    (is (= {:count 1 :rules ["no-mutation"] :severities ["warning"]}
           (no-mutation-summary "(set state.x 2)" "fnl/app.fnl" {"module-style" :off}))))
  (testing "flags while in a source file as one warning"
    (is (= {:count 1 :rules ["no-mutation"] :severities ["warning"]}
           (no-mutation-summary "(while ok (g))" "fnl/app.fnl" {"module-style" :off}))))
  (testing "flags every mutation form in a nested while and set"
    (is (= {:count 2 :rules ["no-mutation" "no-mutation"] :severities ["warning" "warning"]}
           (no-mutation-summary "(while ok (set x 1))" "fnl/app.fnl" {"module-style" :off}))))
  (testing "gives nested mutation findings distinct form identities"
    (let [forms (no-mutation-forms "(defn f [] (let [a (set x 1)] (set y 2)))"
                                   "fnl/app.fnl"
                                   {"module-style" :off})]
      (is (and (= 2 (length forms))
               (not= (. forms 1) (. forms 2))))))
  (testing "keeps nested mutation form identities stable across repeated linting"
    (let [source       "(defn f [] (let [a (set x 1)] (set y 2)))"
          first-forms  (no-mutation-forms source "fnl/app.fnl" {"module-style" :off})
          second-forms (no-mutation-forms source "fnl/app.fnl" {"module-style" :off})]
      (is (= first-forms second-forms))))
  (testing "lints mutation in unquoted quasiquote code"
    (is (= 1
           (length (no-mutation-forms "(macro m [] `(foo ,(set x 1)))"
                                      "fnl/app.fnl"
                                      {"module-style" :off})))))
  (testing "does not lint mutation in quasiquoted data"
    (is (= 0
           (length (no-mutation-forms "`(set x ,y)"
                                      "fnl/app.fnl"
                                      {"module-style" :off})))))
  (testing "lints only the outer unquote in nested quasiquote data"
    (is (= 1
           (. (no-mutation-summary "(defn f [] `(outer ,(set x 1) `(set y ,(set z 2))))"
                                   "fnl/app.fnl"
                                   {"module-style" :off})
              :count))))
  (testing "lints a double-unquoted mutation at executable depth"
    (is (= 1
           (. (no-mutation-summary "(defn f [] `(a `(b ,,(set x 1))))"
                                   "fnl/app.fnl"
                                   {"module-style" :off})
              :count))))
  (testing "does not lint mutation inside plain quote"
    (is (= 0
           (. (no-mutation-summary "(defn f [] '(foo ,(set x 1)))"
                                   "fnl/app.fnl"
                                   {"module-style" :off})
              :count))))
  (testing "does not flag mutations in a spec file"
    (is (= {:count 0 :rules [] :severities []}
           (no-mutation-summary "(var x 1) (set x 2) (while ok (g))"
                                "fnl/spec/app_spec.fnl"
                                nil))))
  (testing "does not flag non-mutation forms or quoted mutation data"
    (is (= {:count 0 :rules [] :severities []}
           (no-mutation-summary "(local x 1) (tset t :k v) (table.insert xs 1) '(set x 1) (set-foo 1)"
                                "fnl/app.fnl"
                                {"module-style" :off}))))
  (testing "uses error severity when configured"
    (is (= {:count 1 :rules ["no-mutation"] :severities ["error"]}
           (no-mutation-summary "(var x 1)"
                                "fnl/app.fnl"
                                {"module-style" :off "no-mutation" :error}))))
  (testing "does not report when disabled"
    (is (= {:count 0 :rules [] :severities []}
           (no-mutation-summary "(var x 1)"
                                "fnl/app.fnl"
                                {"module-style" :off "no-mutation" :off}))))
  (testing "uses the suggested message"
    (is (= "avoid mutation (var/set/while); prefer a functional form"
           (. (finding-summary (check-source "(var x 1)"
                                             "fnl/app.fnl"
                                             {"module-style" :off}))
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
    (let [findings (if-without-else-findings "(defn f [] (if a b))" "fnl/app.fnl" {"module-style" :off})]
      (is (= {:rule "if-without-else" :severity "warning" :message "if without else; use when"}
             {:rule     (. findings 1 :rule)
              :severity (. findings 1 :severity)
              :message  (. findings 1 :message)}))))
  (testing "does not flag complete or multi-clause if forms or when"
    (is (= 0
           (length (if-without-else-findings "(if a b c) (if a b c d e) (when a b)"
                                             "fnl/app.fnl"
                                             {"module-style" :off})))))
  (testing "flags a single-clause if whose else branch is literal nil"
    (let [finding (. (if-without-else-findings "(defn f\n  [ok resolved]\n  (if ok\n    resolved\n    nil))"
                                               "fnl/app.fnl"
                                               {"module-style" :off})
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
                                             {"module-style" :off})))))
  (testing "does not flag a multi-clause if ending in literal nil"
    (is (= 0
           (length (if-without-else-findings "(if a b c nil)"
                                             "fnl/app.fnl"
                                             {"module-style" :off})))))
  (testing "does not flag an if with a literal nil then branch"
    (is (= 0
           (length (if-without-else-findings "(if a nil b)"
                                             "fnl/app.fnl"
                                             {"module-style" :off})))))
  (testing "flags two nested if forms with distinct stable identities"
    (let [source "(defn f [] (do (if x y) (if x y)))"
          rules  {"module-style" :off}
          first  (if-without-else-findings source "fnl/app.fnl" rules)
          second (if-without-else-findings source "fnl/app.fnl" rules)]
      (is (and (= 2 (length first))
               (not= (. first 1 :form) (. first 2 :form))
               (vim.deep_equal (icollect [_ finding (ipairs first)] (. finding :form))
                               (icollect [_ finding (ipairs second)] (. finding :form)))))))
  (testing "an exclusion for one nested if leaves the other finding"
    (let [source   "(defn f [] (do (if x y) (if x y)))"
          path     "fnl/app.fnl"
          rules    {"module-style" :off}
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
                                             {"module-style" :off})))))
  (testing "uses error severity when configured"
    (is (= "error"
           (. (if-without-else-findings "(if a b)"
                                        "fnl/app.fnl"
                                        {"module-style" :off "if-without-else" :error})
              1
              :severity))))
  (testing "does not report when disabled"
    (is (= 0
           (length (if-without-else-findings "(if a b)"
                                             "fnl/app.fnl"
                                             {"module-style" :off "if-without-else" :off}))))))

(defn- defn-args-newline-findings
  [source path rules]
  (let [result (check-source source path rules)]
    (if (or (. result :module-missing) (. result :value-nil?))
      result
      (icollect [_ finding (ipairs result)]
        (when (= (. finding :rule) "defn-args-newline")
          finding)))))

(deftest defn-args-newline
  (testing "flags a defn whose argument vector starts on the name line"
    (is (= 1 (length (defn-args-newline-findings "(defn f [a]\n  a)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "flags a defn- whose argument vector starts on the name line"
    (is (= 1 (length (defn-args-newline-findings "(defn- f [a] a)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "accepts a defn with the argument vector on the line below the name"
    (is (= 0 (length (defn-args-newline-findings "(defn f\n  [a]\n  a)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "accepts a defn- with the argument vector on the line below the name"
    (is (= 0 (length (defn-args-newline-findings "(defn- f\n  [a]\n  a)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "flags a one-line defn because the layout is always required"
    (is (= 1 (length (defn-args-newline-findings "(defn f [] 1)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "requires a docstring followed by arguments to start on a later line"
    (is (= 1 (length (defn-args-newline-findings "(defn f \"doc\" [a]\n  a)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "accepts a docstring on the name line when arguments start below it"
    (is (= 0 (length (defn-args-newline-findings "(defn f \"doc\"\n  [a]\n  a)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "accepts a docstring on its own line before arguments"
    (is (= 0 (length (defn-args-newline-findings "(defn f\n  \"doc\"\n  [a]\n  a)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "does not flag fn lambda macro or def forms"
    (is (= 0 (length (defn-args-newline-findings "(fn f [a] a) (lambda f [a] a) (macro f [a] a) (def f [a])" "fnl/app.fnl" {"module-style" :off})))))
  (testing "applies to spec files and ignores quoted data"
    (is (= 1 (length (defn-args-newline-findings "(defn f [a] a) '(defn f [a] a)" "fnl/spec/app_spec.fnl" nil)))))
  (testing "uses the stable defn identity and prescribed warning message"
    (let [finding (. (defn-args-newline-findings "(defn f [a]\n  a)" "fnl/app.fnl" {"module-style" :off}) 1)]
      (is (= {:form     "fnl/app.fnl > defn:f"
              :severity "warning"
              :message  "put the defn argument vector on the line below the name"}
             {:form     (. finding :form)
              :severity (. finding :severity)
              :message  (. finding :message)}))))
  (testing "uses error severity when configured"
    (is (= "error" (. (defn-args-newline-findings "(defn f [a] 1)" "fnl/app.fnl" {"module-style" :off "defn-args-newline" :error}) 1 :severity))))
  (testing "does not report when disabled"
    (is (= 0 (length (defn-args-newline-findings "(defn f [a] 1)" "fnl/app.fnl" {"module-style" :off "defn-args-newline" :off})))))
  (testing "an exclusion removes only the selected defn finding"
    (let [source   "(defn f [a] a)\n(defn g [b] b)"
          path     "fnl/app.fnl"
          rules    {"module-style" :off}
          baseline (defn-args-newline-findings source path rules)
          result   (check-context source {:path path :rules rules :exclusions [{:rule "defn-args-newline" :form (. baseline 1 :form) :reason "intentional"}]})]
      (is (= 1
             (length (icollect [_ finding (ipairs result)]
                       (when (= (. finding :rule) "defn-args-newline")
                         finding)))))))
  (testing "reports one finding across defn args and multiline layout"
    (let [result (check-source "(defn f [a]\n  (foo a b\n    c))" "fnl/app.fnl" {"module-style" :off})
          rules  (icollect [_ finding (ipairs result)] (. finding :rule))]
      (is (and (= 2 (length rules))
               (vim.deep_equal [true true]
                               [(vim.tbl_contains rules "defn-args-newline")
                                (vim.tbl_contains rules "multiline-layout")]))))))

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
                                              {"module-style" :off})))))
  (testing "accepts an if test on the head line"
    (is (= 0
           (length (multiline-layout-findings "(defn f\n  [file]\n  (if file\n    (read file)\n    \"\"))"
                                              "fnl/app.fnl"
                                              {"module-style" :off})))))
  (testing "requires an and argument on the head line"
    (is (= 1
           (length (multiline-layout-findings "(defn f\n  [file]\n  (and\n    file\n    (close file)))"
                                              "fnl/app.fnl"
                                              {"module-style" :off})))))
  (testing "accepts an and argument on the head line"
    (is (= 0
           (length (multiline-layout-findings "(defn f\n  [file]\n  (and file\n    (close file)))"
                                              "fnl/app.fnl"
                                              {"module-style" :off})))))
  (testing "requires a plain call argument on the head line"
    (is (= 1 (length (multiline-layout-findings "(foo\n  a\n  b)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "accepts a plain call argument on the head line"
    (is (= 0 (length (multiline-layout-findings "(foo a\n     b)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "requires a let binding vector on the head line"
    (is (= 1 (length (multiline-layout-findings "(let\n  [x 1]\n  x)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "does not require a do body on the head line"
    (is (= 0 (length (multiline-layout-findings "(do\n  (a)\n  (b))" "fnl/app.fnl" {"module-style" :off})))))
  (testing "does not require a defn name on the next line"
    (is (= 0 (length (multiline-layout-findings "(defn f\n  [a]\n  a)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "requires a multi-clause if test on the head line"
    (is (= 1
           (length (multiline-layout-findings "(if\n  (> i n) false\n  (= p x) true\n  (rec))"
                                              "fnl/app.fnl"
                                              {"module-style" :off})))))
  (testing "flags a list with two items starting on one line"
    (is (= 1 (length (multiline-layout-findings "(foo a b\n  c)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "accepts a list with one item starting on each line"
    (is (= 0 (length (multiline-layout-findings "(foo a\n  b\n  c)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "accepts a one-line list"
    (is (= 0 (length (multiline-layout-findings "(foo a b c)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "flags a list whose head starts below its opening paren"
    (is (= 1
           (length (multiline-layout-findings "(\n foo a b)"
                                              "fnl/app.fnl"
                                              {"module-style" :off})))))
  (testing "flags a list with a delayed head inside a defn"
    (is (= 1
           (length (multiline-layout-findings "(defn f\n  []\n  (\n   foo a b))"
                                              "fnl/app.fnl"
                                              {"module-style" :off})))))
  (testing "does not flag vectors or maps whose first item starts below the opener"
    (is (= 0
           (+ (length (multiline-layout-findings "[\n 1\n 2]" "fnl/app.fnl" {"module-style" :off}))
              (length (multiline-layout-findings "{\n :a 1}" "fnl/app.fnl" {"module-style" :off}))))))
  (testing "flags a single-clause if whose then branch shares the head line"
    (is (= 1
           (length (multiline-layout-findings "(defn f\n  [n]\n  (if (> n 0) 1\n    0))"
                                              "fnl/app.fnl"
                                              {"module-style" :off})))))
  (testing "accepts a single-clause if with each branch on its own line"
    (is (= 0
           (length (multiline-layout-findings "(defn f\n  [n]\n  (if (> n 0)\n    1\n    0))"
                                              "fnl/app.fnl"
                                              {"module-style" :off})))))
  (testing "reports only multiline-layout for a malformed multi-line control form"
    (let [findings (check-source "(defn f\n  [n]\n  (if (> n 0) 1\n    0))" "fnl/app.fnl" {"module-style" :off})]
      (is (= ["multiline-layout"]
             (icollect [_ finding (ipairs findings)] (. finding :rule))))))
  (testing "flags a multi-line map with two pairs on one line"
    (is (= 1 (length (multiline-layout-findings "{:a 1 :b 2\n :c 3}" "fnl/app.fnl" {"module-style" :off})))))
  (testing "accepts a map with one pair starting on each line"
    (is (= 0 (length (multiline-layout-findings "{:a 1\n :b 2\n :c 3}" "fnl/app.fnl" {"module-style" :off})))))
  (testing "accepts a map whose value starts on the next line"
    (is (= 0 (length (multiline-layout-findings "{:a\n  (long-value)\n :b 2}" "fnl/app.fnl" {"module-style" :off})))))
  (testing "flags a vector with two elements starting on one line"
    (is (= 1 (length (multiline-layout-findings "[a b\n c]" "fnl/app.fnl" {"module-style" :off})))))
  (testing "accepts comments and multi-line strings between items"
    (is (= 0 (length (multiline-layout-findings "(foo a ; b\n  \"c\nd\"\n  e)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "flags a let binding vector with two bindings on one line"
    (is (= 1 (length (multiline-layout-findings "(let [a 1 b 2\n      c 3]\n  a)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "accepts a let binding vector with one binding on each line"
    (is (= 0 (length (multiline-layout-findings "(let [a 1\n      b 2]\n  a)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "flags a case with two clauses starting on one line"
    (is (= 1 (length (multiline-layout-findings "(case x\n  1 :a 2 :b\n  _ :c)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "accepts a multi-clause if with one pair on each line"
    (is (= 0 (length (multiline-layout-findings "(if (> i n) false\n  (= p x) true\n  (rec))" "fnl/app.fnl" {"module-style" :off})))))
  (testing "flags a unit that starts where the previous unit ends"
    (is (= 1 (length (multiline-layout-findings "(foo (bar\n       x) y)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "reports one finding for the inner call in a defn body"
    (let [findings (multiline-layout-findings "(defn f [a] (foo a b\n  c))" "fnl/app.fnl" {"module-style" :off})]
      (is (= 1 (length findings)))))
  (testing "reports one finding per nested offending form with distinct identities"
    (let [findings (multiline-layout-findings "(defn f [] (foo a b\n  (bar x y\n    z)))" "fnl/app.fnl" {"module-style" :off})]
      (is (and (= 2 (length findings))
               (not= (. findings 1 :form) (. findings 2 :form))))))
  (testing "an exclusion for one nested form leaves the other finding"
    (let [source   "(defn f [] (foo a b\n  (bar x y\n    z)))"
          path     "fnl/app.fnl"
          rules    {"module-style" :off}
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
    (is (= 0 (length (multiline-layout-findings "'(a b\n c)" "fnl/app.fnl" {"module-style" :off})))))
  (testing "uses the default warning and prescribed message"
    (let [finding (. (multiline-layout-findings "(foo a b\n  c)" "fnl/app.fnl" {"module-style" :off}) 1)]
      (is (= {:severity "warning"
              :message  "multi-line form: put each item on its own line"}
             {:severity (. finding :severity)
              :message  (. finding :message)}))))
  (testing "uses error severity when configured"
    (is (= "error"
           (. (multiline-layout-findings "(foo a b\n  c)"
                                         "fnl/app.fnl"
                                         {"module-style" :off "multiline-layout" :error})
              1
              :severity))))
  (testing "does not report when disabled"
    (is (= 0
           (length (multiline-layout-findings "(foo a b\n  c)"
                                              "fnl/app.fnl"
                                              {"module-style" :off "multiline-layout" :off}))))))

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
                                            {"module-style" :off})))))
  (testing "accepts a broken-out if in direct function statement position"
    (is (= 0
           (length (control-layout-findings "(defn f\n  [ok resolved]\n  (if ok\n    resolved\n    nil))"
                                            "fnl/app.fnl"
                                            {"module-style" :off})))))
  (testing "flags a one-line when in direct function statement position"
    (is (= 1
           (length (control-layout-findings "(defn f\n  [file]\n  (when (kept? file) file))"
                                            "fnl/app.fnl"
                                            {"module-style" :off})))))
  (testing "does not flag a one-line or as the last expression of a value-returning loop body"
    (is (= 0
           (length (control-layout-findings "(defn f\n  [es]\n  (accumulate [r false _ e (ipairs es)]\n    (or r (m? e))))"
                                            "fnl/app.fnl"
                                            {"module-style" :off})))))
  (testing "does not flag a one-line and as the returned function expression"
    (is (= 0
           (length (control-layout-findings "(defn f\n  [a b]\n  (and a b))"
                                            "fnl/app.fnl"
                                            {"module-style" :off})))))
  (testing "flags a one-line control form as the sole when body expression"
    (is (= 1
           (length (control-layout-findings "(defn f\n  [a b c]\n  (when a\n    (if b c a)))"
                                            "fnl/app.fnl"
                                            {"module-style" :off})))))
  (testing "accepts a broken-out or in a loop body"
    (is (= 0
           (length (control-layout-findings "(defn f\n  [es]\n  (accumulate [r false _ e (ipairs es)]\n    (or r\n      (m? e))))"
                                            "fnl/app.fnl"
                                            {"module-style" :off})))))
  (testing "does not flag controls when a do body has other expressions"
    (is (= 0
           (length (control-layout-findings "(defn f\n  [x]\n  (do (case x 1 :one _ :other)\n      (match x 1 :one _ :other)))"
                                            "fnl/app.fnl"
                                            {"module-style" :off})))))
  (testing "flags a one-line control form as the sole let body expression"
    (is (= 1
           (length (control-layout-findings "(defn f\n  [ok]\n  (let [x 1]\n    (if ok x 0)))"
                                            "fnl/app.fnl"
                                            {"module-style" :off})))))
  (testing "flags a one-line control form as the sole each body expression"
    (is (= 1
           (length (control-layout-findings "(defn f\n  [xs]\n  (each [_ x (ipairs xs)]\n    (if x x 0)))"
                                            "fnl/app.fnl"
                                            {"module-style" :off})))))
  (testing "does not require control forms in value, call, vector, map, or branch positions"
    (is (= 0
           (length (control-layout-findings "(defn f\n  [a b c]\n  (let [x (or a b)]\n    {:p (if a b c)\n     :q [(when a b)]}\n    (foo (if a b c))\n    (if a\n      (or b c)\n      c)))"
                                            "fnl/app.fnl"
                                            {"module-style" :off})))))
  (testing "does not flag nested controls when a do body has other expressions"
    (is (= 0
           (length (control-layout-findings "(defn f\n  []\n  (do (if a b c)\n      (when a b)))"
                                            "fnl/app.fnl"
                                            {"module-style" :off})))))
  (testing "applies to spec files"
    (is (= 1
           (length (control-layout-findings "(defn f [] (if a b c))"
                                            "fnl/spec/app_spec.fnl"
                                            nil)))))
  (testing "ignores quoted control-form data"
    (is (= 0
           (length (control-layout-findings "'(if a b c)"
                                            "fnl/app.fnl"
                                            {"module-style" :off})))))
  (testing "uses the stable identity, warning severity, and prescribed message"
    (let [finding (. (control-layout-findings "(defn f [] (if a b c))"
                                              "fnl/app.fnl"
                                              {"module-style" :off})
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
                                       {"module-style" :off "control-layout" :error})
              1
              :severity))))
  (testing "does not report when disabled"
    (is (= 0
           (length (control-layout-findings "(defn f [] (if a b c))"
                                            "fnl/app.fnl"
                                            {"module-style" :off "control-layout" :off})))))
  (testing "an exclusion removes only the selected control-layout finding"
    (let [source   "(defn f [] (if a b c))\n(defn g [] (when a b))"
          path     "fnl/app.fnl"
          rules    {"module-style" :off}
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
                                           {"module-style" :off "control-layout" :off})))))
  (testing "does not flag the last and expression of a value-returning body"
    (is (= 0
           (length (unused-and-or-findings "(defn f\n  [a b]\n  (and a b))"
                                           "fnl/app.fnl"
                                           {"module-style" :off "control-layout" :off})))))
  (testing "flags or in an each body"
    (is (= 1
           (length (unused-and-or-findings "(defn f\n  [xs]\n  (each [_ x (ipairs xs)]\n    (or x (warn))))"
                                           "fnl/app.fnl"
                                           {"module-style" :off "control-layout" :off})))))
  (testing "does not flag and as the last icollect body expression"
    (is (= 0
           (length (unused-and-or-findings "(defn f\n  [xs]\n  (icollect [_ x (ipairs xs)]\n    (and x (f x))))"
                                           "fnl/app.fnl"
                                           {"module-style" :off "control-layout" :off})))))
  (testing "flags or before the returned let expression"
    (is (= 1
           (length (unused-and-or-findings "(defn f []\n  (let [x 1]\n    (or x (warn))\n    x))"
                                           "fnl/app.fnl"
                                           {"module-style" :off "control-layout" :off})))))
  (testing "flags and before the returned when expression"
    (is (= 1
           (length (unused-and-or-findings "(defn f []\n  (when ok\n    (and a (b))\n    c))"
                                           "fnl/app.fnl"
                                           {"module-style" :off "control-layout" :off})))))
  (testing "flags and before the returned do expression"
    (is (= 1
           (length (unused-and-or-findings "(defn f []\n  (do (and a (b)) c))"
                                           "fnl/app.fnl"
                                           {"module-style" :off "control-layout" :off})))))
  (testing "does not flag and or in value positions"
    (is (= 0
           (length (unused-and-or-findings "(defn f []\n  (let [y (and a b)] y)\n  (foo (or a b)))"
                                           "fnl/app.fnl"
                                           {"module-style" :off "control-layout" :off})))))
  (testing "ignores quoted and-or data"
    (is (= 0
           (length (unused-and-or-findings "'(and a b) '(or a b)"
                                           "fnl/app.fnl"
                                           {"module-style" :off "control-layout" :off})))))
  (testing "ignores and-or data in a quasiquote"
    (is (= 0
           (length (unused-and-or-findings "(defn f\n  []\n  (do `(and a b) out))"
                                           "fnl/app.fnl"
                                           {"module-style" :off "control-layout" :off})))))
  (testing "checks only unquoted and-or code through nested quasiquotes"
    (is (= 1
           (length (unused-and-or-findings "(defn f\n  []\n  `(do ,(do (and a (b)) c) `(do (and x y) z)))"
                                           "fnl/app.fnl"
                                           {"module-style" :off "control-layout" :off})))))
  (testing "checks and-or code inside an unquote"
    (is (= 1
           (length (unused-and-or-findings "(defn f\n  []\n  `(foo ,(do (or a (warn)) b)))"
                                           "fnl/app.fnl"
                                           {"module-style" :off "control-layout" :off})))))
  (testing "ignores plain quoted and-or data in a do body"
    (is (= 0
           (length (unused-and-or-findings "(defn f\n  []\n  (do '(and a b) out))"
                                           "fnl/app.fnl"
                                           {"module-style" :off "control-layout" :off})))))
  (testing "applies to spec files"
    (is (= 1
           (length (unused-and-or-findings "(defn f []\n  (and a b)\n  c)"
                                           "fnl/spec/app_spec.fnl"
                                           {"control-layout" :off})))))
  (testing "gives nested discarded and-or forms distinct stable identities"
    (let [source "(defn f []\n  (do (and a b) (or c d) (out)))"
          rules  {"module-style" :off "control-layout" :off}
          first  (unused-and-or-findings source "fnl/app.fnl" rules)
          second (unused-and-or-findings source "fnl/app.fnl" rules)]
      (is (and (= 2 (length first))
               (not= (. first 1 :form) (. first 2 :form))
               (vim.deep_equal (icollect [_ finding (ipairs first)] (. finding :form))
                               (icollect [_ finding (ipairs second)] (. finding :form)))))))
  (testing "uses the stable identity warning severity and prescribed message"
    (let [finding (. (unused-and-or-findings "(defn f []\n  (and a b)\n  c)"
                                             "fnl/app.fnl"
                                             {"module-style" :off "control-layout" :off})
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
                                      {"module-style" :off "control-layout" :off "unused-and-or" :error})
              1
              :severity))))
  (testing "does not report when disabled"
    (is (= 0
           (length (unused-and-or-findings "(defn f []\n  (and a b)\n  c)"
                                           "fnl/app.fnl"
                                           {"module-style" :off "control-layout" :off "unused-and-or" :off})))))
  (testing "an exclusion removes only the selected unused-and-or finding"
    (let [source   "(defn f []\n  (do (and a b) (or c d) (out)))"
          path     "fnl/app.fnl"
          rules    {"module-style" :off "control-layout" :off}
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

(defn- file-size-findings
  [source path rules max-code-lines exclusions]
  (let [result (check-context source
                              {:path           path
                               :rules          rules
                               :max-code-lines max-code-lines
                               :exclusions     exclusions})]
    (if (or (. result :module-missing) (. result :value-nil?))
      result
      (icollect [_ finding (ipairs result)]
        (when (= (. finding :rule) "file-size")
          finding)))))

(deftest file-size
  (testing "reports one finding for 301 code lines at the default limit"
    (is (= 1 (length (file-size-findings (repeated-code 301) "fnl/app.fnl" {"module-style" :off} nil nil)))))
  (testing "accepts exactly the configured code-line limit"
    (is (= 0 (length (file-size-findings (repeated-code 3) "fnl/app.fnl" {"module-style" :off} 3 nil)))))
  (testing "reports the first line above the configured code-line limit"
    (is (= 1 (length (file-size-findings (repeated-code 4) "fnl/app.fnl" {"module-style" :off} 3 nil)))))
  (testing "does not count blank or comment-only lines"
    (is (= 0 (length (file-size-findings "(local a 1)\n\n; comment\n  ; indented comment\n(local b 2)\n;; another comment\n" "fnl/app.fnl" {"module-style" :off} 2 nil)))))
  (testing "counts lines inside a multiline string as code"
    (is (= 1 (length (file-size-findings "(local text [[first\nsecond]])" "fnl/app.fnl" {"module-style" :off} 1 nil)))))
  (testing "does not report a spec file"
    (is (= 0 (length (file-size-findings (repeated-code 4) "fnl/spec/app_spec.fnl" nil 3 nil)))))
  (testing "uses warning severity by default"
    (is (= "warning" (. (file-size-findings (repeated-code 4) "fnl/app.fnl" {"module-style" :off} 3 nil) 1 :severity))))
  (testing "uses error severity when configured"
    (is (= "error" (. (file-size-findings (repeated-code 4) "fnl/app.fnl" {"module-style" :off "file-size" :error} 3 nil) 1 :severity))))
  (testing "does not report when disabled"
    (is (= 0 (length (file-size-findings (repeated-code 4) "fnl/app.fnl" {"module-style" :off "file-size" :off} 3 nil)))))
  (testing "includes the count and limit in the message"
    (let [message (. (file-size-findings (repeated-code 4) "fnl/app.fnl" {"module-style" :off} 3 nil) 1 :message)]
      (is (and (string.find message "4")
               (string.find message "3")))))
  (testing "uses a stable file-level identity"
    (is (= "fnl/app.fnl > file"
           (. (file-size-findings (repeated-code 4) "fnl/app.fnl" {"module-style" :off} 3 nil) 1 :form))))
  (testing "an exact file-size exclusion suppresses the finding"
    (let [finding   (file-size-findings (repeated-code 4) "fnl/app.fnl" {"module-style" :off} 3 nil)
          exclusion [{:rule "file-size" :form (. finding 1 :form) :reason "intentional"}]]
      (is (= 0 (length (file-size-findings (repeated-code 4) "fnl/app.fnl" {"module-style" :off} 3 exclusion)))))))

(deftest no-mutation-exclusions
  (testing "an exact no-mutation rule and form exclusion suppresses the finding"
    (let [source   "(set x 2)"
          path     "fnl/app.fnl"
          rules    {"module-style" :off "defn-args-newline" :off}
          baseline (check-context source {:path path :rules rules})
          form     (first-finding-form baseline "no-mutation")]
      (is (= []
             (check-context source
                            {:path       path
                             :rules      rules
                             :exclusions [{:rule   "no-mutation"
                                           :form   form
                                           :reason "intentional"}]}))))))
(deftest no-mutation-nested-exclusion
  (testing "an exclusion for one nested mutation leaves the other finding"
    (let [source    "(defn f [] (let [a (set x 1)] (set y 2)))"
          path      "fnl/app.fnl"
          rules     {"module-style" :off "defn-args-newline" :off}
          baseline  (check-context source {:path path :rules rules})
          form      (first-finding-form baseline "no-mutation")
          remaining (check-context source
                                   {:path       path
                                    :rules      rules
                                    :exclusions [{:rule   "no-mutation"
                                                  :form   form
                                                  :reason "intentional"}]})]
      (is (= 1 (length remaining))))))

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

(deftest binding-per-line
  (testing "flags multiple let bindings sharing one line"
    (is (= 1
           (length (findings-for-named-rule "(defn f\n  []\n  (let [a 1 b 2]\n    a))"
                                            "fnl/app.fnl"
                                            "binding-per-line"
                                            {"module-style"     :off
                                             "multiline-layout" :off})))))
  (testing "accepts one binding pair per line"
    (is (= 0
           (length (findings-for-named-rule "(let [a 1\n      b 2]\n  a)"
                                            "fnl/app.fnl"
                                            "binding-per-line"
                                            {"module-style"     :off
                                             "multiline-layout" :off})))))
  (testing "accepts a single binding pair"
    (is (= 0
           (length (findings-for-named-rule "(let [a 1]\n  a)"
                                            "fnl/app.fnl"
                                            "binding-per-line"
                                            {"module-style" :off})))))
  (testing "does not apply to each bindings"
    (is (= 0
           (length (findings-for-named-rule "(each [k v (pairs t)]\n  k)"
                                            "fnl/app.fnl"
                                            "binding-per-line"
                                            {"module-style" :off})))))
  (testing "reports one binding-per-line finding for a mixed multiline vector"
    (is (= 1
           (length (findings-for-named-rule "(let [a 1 b 2\n      c 3]\n  a)"
                                            "fnl/app.fnl"
                                            "binding-per-line"
                                            {"module-style" :off})))))
  (testing "applies to when-let if-let and with-open"
    (is (= 3
           (length (findings-for-named-rule "(when-let [a 1 b 2] a)\n(if-let [a 1 b 2] a b)\n(with-open [a 1 b 2] a)"
                                            "fnl/app.fnl"
                                            "binding-per-line"
                                            {"module-style" :off})))))
  (testing "applies to spec files"
    (is (= 1
           (length (findings-for-named-rule "(let [a 1 b 2]\n  a)"
                                            "fnl/spec/app_spec.fnl"
                                            "binding-per-line"
                                            nil)))))
  (testing "ignores quoted binding data"
    (is (= 0
           (length (findings-for-named-rule "'(let [a 1 b 2]\n  a)"
                                            "fnl/app.fnl"
                                            "binding-per-line"
                                            {"module-style" :off})))))
  (testing "uses the prescribed warning and message"
    (let [finding (. (findings-for-named-rule "(let [a 1 b 2])"
                                              "fnl/app.fnl"
                                              "binding-per-line"
                                              {"module-style" :off})
                     1)]
      (is (= {:severity "warning"
              :message  "put each binding on its own line"}
             {:severity (. finding :severity)
              :message  (. finding :message)}))))
  (testing "supports error severity and disabling"
    (is (= ["error" 0]
           [(let [finding (. (findings-for-named-rule "(let [a 1 b 2])"
                                                      "fnl/app.fnl"
                                                      "binding-per-line"
                                                      {"module-style"     :off
                                                       "binding-per-line" :error})
                              1)]
              (. finding :severity))
            (length (findings-for-named-rule "(let [a 1 b 2])"
                                             "fnl/app.fnl"
                                             "binding-per-line"
                                             {"module-style"     :off
                                              "binding-per-line" :off}))]))))
(testing "skips an odd-length binding vector without crashing"
  (is (= {:ok true :count 0}
         (safe-findings-for-named-rule "(let [a nil b])"
                                       "fnl/app.fnl"
                                       "binding-per-line"
                                       {"module-style" :off}))))
(testing "skips a longer odd-length binding vector without crashing"
  (is (= {:ok true :count 0}
         (safe-findings-for-named-rule "(let [a 1 b 2 c])"
                                       "fnl/app.fnl"
                                       "binding-per-line"
                                       {"module-style" :off}))))
(testing "accepts a comment-only opening binding line"
  (is (= 0
         (length (findings-for-named-rule "(let [;; note\n      a 1\n      b 2]\n  a)"
                                          "fnl/app.fnl"
                                          "binding-per-line"
                                          {"module-style" :off})))))
(testing "flags bindings sharing a line after a comment-only opening line"
  (is (= 1
         (length (findings-for-named-rule "(let [;; note\n      a 1 b 2]\n  a)"
                                          "fnl/app.fnl"
                                          "binding-per-line"
                                          {"module-style" :off})))))
(testing "keeps distinct identities stable across repeated linting"
  (let [source "(let [a 1 b 2])"
        first  (findings-for-named-rule source "fnl/app.fnl" "binding-per-line" {"module-style" :off})
        second (findings-for-named-rule source "fnl/app.fnl" "binding-per-line" {"module-style" :off})]
    (is (and (not= nil (. first 1 :form))
             (= (. first 1 :form) (. second 1 :form))))))
(testing "an exact exclusion suppresses only the selected binding finding"
  (let [source   "(let [a 1 b 2])\n(let [c 3 d 4])"
        path     "fnl/app.fnl"
        rules    {"module-style" :off}
        baseline (findings-for-named-rule source path "binding-per-line" rules)
        context  {:path       path
                  :rules      rules
                  :exclusions [{:rule   "binding-per-line"
                                :form   (. baseline 1 :form)
                                :reason "intentional"}]}
        result   (check-context source context)]
    (is (= 1
           (length (icollect [_ finding (ipairs result)]
                     (when (= (. finding :rule) "binding-per-line")
                       finding)))))))

(deftest call-data-arg
  (testing "flags a multiline map literal passed to a plain call"
    (is (= 1
           (length (findings-for-named-rule "(foo a {:x 1\n         :y 2})"
                                            "fnl/app.fnl"
                                            "call-data-arg"
                                            {"module-style"     :off
                                             "multiline-layout" :off})))))
  (testing "accepts a one-line map literal call argument"
    (is (= 0
           (length (findings-for-named-rule "(foo a {:x 1 :y 2})"
                                            "fnl/app.fnl"
                                            "call-data-arg"
                                            {"module-style" :off})))))
  (testing "accepts a map bound in a let before the call"
    (is (= 0
           (length (findings-for-named-rule "(let [opts {:x 1\n            :y 2}]\n  (foo a opts))"
                                            "fnl/app.fnl"
                                            "call-data-arg"
                                            {"module-style"     :off
                                             "multiline-layout" :off})))))
  (testing "excludes fn arguments from plain call data findings"
    (is (= 0
           (length (findings-for-named-rule "(foo (fn []\n  1))"
                                            "fnl/app.fnl"
                                            "call-data-arg"
                                            {"module-style" :off})))))
  (testing "treats values as a plain call"
    (is (= 1
           (length (findings-for-named-rule "(values {:a 1\n         :b 2} nil)"
                                            "fnl/app.fnl"
                                            "call-data-arg"
                                            {"module-style"     :off
                                             "multiline-layout" :off})))))
  (testing "flags a multiline vector literal passed to a plain call"
    (is (= 1
           (length (findings-for-named-rule "(foo [1\n      2])"
                                            "fnl/app.fnl"
                                            "call-data-arg"
                                            {"module-style"     :off
                                             "multiline-layout" :off})))))
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
                                            {"module-style" :off})))))
  (testing "uses the prescribed warning and message"
    (let [finding (. (findings-for-named-rule "(foo {:x 1\n      :y 2})"
                                              "fnl/app.fnl"
                                              "call-data-arg"
                                              {"module-style"     :off
                                               "multiline-layout" :off})
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
                                                      {"module-style"     :off
                                                       "multiline-layout" :off
                                                       "call-data-arg"    :error})
                              1)]
              (. finding :severity))
            (length (findings-for-named-rule "(foo {:x 1\n      :y 2})"
                                             "fnl/app.fnl"
                                             "call-data-arg"
                                             {"module-style"     :off
                                              "multiline-layout" :off
                                              "call-data-arg"    :off}))]))))
(testing "keeps identities stable across repeated linting"
  (let [source "(foo {:x 1\n      :y 2})"
        rules  {"module-style"     :off
                "multiline-layout" :off}
        first  (findings-for-named-rule source "fnl/app.fnl" "call-data-arg" rules)
        second (findings-for-named-rule source "fnl/app.fnl" "call-data-arg" rules)]
    (is (and (not= nil (. first 1 :form))
             (= (. first 1 :form) (. second 1 :form))))))
(testing "an exact exclusion suppresses the selected call finding"
  (let [source   "(foo {:x 1\n      :y 2})\n(bar {:a 1\n      :b 2})"
        path     "fnl/app.fnl"
        rules    {"module-style"     :off
                  "multiline-layout" :off}
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

(defn- option-findings
  [source path rule options]
  (let [lint    (load-lint)
        matcher (load-matcher)]
    (if (or (. lint :module-missing) (. matcher :module-missing))
      {:module-missing true}
      (lint.check source {:path path :rules {rule {:severity "warning" :options options}} :matcher (matcher.vim-matcher)}))))

(deftest configurable-rule-options
  (testing "module-style accepts a configured macro module"
    (is (= 0
           (length (option-findings "(import-macros {: module : def : defn : defn-} :my.macros)\\n(module app)"
                                    "fnl/app.fnl"
                                    "module-style"
                                    {:macro-module "my.macros"})))))
  (testing "module-style still flags the default macro module when configured away"
    (is (= 1
           (length (option-findings "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\\n(module app)"
                                    "fnl/app.fnl"
                                    "module-style"
                                    {:macro-module "my.macros"})))))
  (testing "spec-macro-import accepts configured macro names and module"
    (is (= 0
           (length (option-findings "(import-macros {: check : verify} :my.spec.macros)"
                                    "fnl/spec/app_spec.fnl"
                                    "spec-macro-import"
                                    {:macro-module "my.spec.macros" :required-macros ["check" "verify"]})))))
  (testing "spec-macro-import accepts configured exempt files"
    (is (= 0
           (length (option-findings "(deftest run)"
                                    "fnl/spec/app_spec.fnl"
                                    "spec-macro-import"
                                    {:exempt-files ["^fnl/spec/app_spec[.]fnl$"]})))))
  (testing "spec-no-module accepts a configured module form"
    (is (= 0
           (length (option-findings "(custom-module app)"
                                    "fnl/spec/app_spec.fnl"
                                    "spec-no-module"
                                    {:module-form "custom-module"})))))
  (testing "spec-direct-require accepts configured forbidden modules"
    (is (= 1
           (length (option-findings "(require :custom.test)"
                                    "fnl/spec/app_spec.fnl"
                                    "spec-direct-require"
                                    {:forbidden-modules ["custom.test"] :exempt-files []})))))
  (testing "spec-direct-require accepts configured exempt files"
    (is (= 0
           (length (option-findings "(require :custom.test)"
                                    "fnl/spec/app_spec.fnl"
                                    "spec-direct-require"
                                    {:forbidden-modules ["custom.test"] :exempt-files ["^fnl/spec/app_spec[.]fnl$"]})))))
  (testing "one-is-per-testing accepts configured testing and assertion forms"
    (is (= 0
           (length (option-findings "(checking \"one\" (assertion true))"
                                    "fnl/spec/app_spec.fnl"
                                    "one-is-per-testing"
                                    {:testing-form "checking" :assertion-form "assertion" :count 1})))))
  (testing "if-branch-call accepts configured conditional forms"
    (is (= 1
           (length (option-findings "(unless ok (do a b) c)"
                                    "fnl/app.fnl"
                                    "if-branch-call"
                                    {:if-forms ["unless"]})))))
  (testing "if-without-else accepts configured conditional forms and nil policy"
    (is (= 0
           (length (option-findings "(unless ok value nil)"
                                    "fnl/app.fnl"
                                    "if-without-else"
                                    {:if-forms ["unless"] :flag-nil-else false})))))
  (testing "control-layout accepts configured control forms"
    (is (= 1
           (length (option-findings "(unless ok\\n  a\\n  b)"
                                    "fnl/app.fnl"
                                    "control-layout"
                                    {:control-forms ["unless"]})))))
  (testing "unused-and-or accepts configured forms"
    (is (= 1
           (length (option-findings "(xor a b)"
                                    "fnl/app.fnl"
                                    "unused-and-or"
                                    {:forms ["xor"]})))))
  (testing "defn-args-newline accepts configured function forms"
    (is (= 1
           (length (option-findings "(fnx f [a] a)"
                                    "fnl/app.fnl"
                                    "defn-args-newline"
                                    {:forms ["fnx"]})))))
  (testing "function-shape accepts configured function forms"
    (is (= 1
           (length (option-findings "(fnx f [] (if a (if b c d) e))"
                                    "fnl/app.fnl"
                                    "function-shape"
                                    {:function-forms ["fnx"]})))))
  (testing "applies-to all makes no-mutation inspect spec files"
    (is (= 1
           (length (option-findings "(var x 1)"
                                    "fnl/spec/app_spec.fnl"
                                    "no-mutation"
                                    {:applies-to :all})))))
  (testing "no-mutation accepts configured mutation forms"
    (is (= 1
           (length (option-findings "(alter x 1)"
                                    "fnl/app.fnl"
                                    "no-mutation"
                                    {:forms ["alter"]})))))
  (testing "multiline-layout accepts configured clause and binding forms"
    (is (= 1
           (length (option-findings "(branch x\\n  a b) (bind [a 1 b 2] a)"
                                    "fnl/app.fnl"
                                    "multiline-layout"
                                    {:clause-forms ["branch"] :binding-forms ["bind"]})))))
  (testing "core-require accepts configured module and binding"
    (is (= 0
           (length (option-findings "(local c (require :my.core))"
                                    "fnl/app.fnl"
                                    "core-require"
                                    {:module "my.core" :binding "c"})))))
  (testing "binding-per-line accepts configured forms"
    (is (= 0
           (length (option-findings "(when-let [a 1 b 2] a)"
                                    "fnl/app.fnl"
                                    "binding-per-line"
                                    {:forms ["let"]})))))
  (testing "call-data-arg ignores configured call heads"
    (is (= 0
           (length (option-findings "(special [1\\n  2])"
                                    "fnl/app.fnl"
                                    "call-data-arg"
                                    {:ignore-forms ["special"]})))))
  (testing "spec-files classifies a custom spec path"
    (let [lint    (load-lint)
          matcher (load-matcher)
          result  (lint.check "(var x 1)"
                              {:path       "test/x.fnl"
                               :spec-files ["^test/"]
                               :rules      {"no-mutation" {:severity "warning" :options {}}}
                               :matcher    (matcher.vim-matcher)})]
      (is (= 0 (length result)))))
  (testing "spec-files combines multiple patterns and keeps source rules scoped"
    (let [lint    (load-lint)
          matcher (load-matcher)
          result  (lint.check "(module app)\n(var x 1)"
                              {:path       "tests/a.fnl"
                               :spec-files ["^fnl/spec/" "^tests/"]
                               :rules      {"spec-no-module" :error
                                            "no-mutation"    :warning}
                               :matcher    (matcher.vim-matcher)})]
      (is (= ["spec-no-module"]
             (icollect [_ finding (ipairs result)] (. finding :rule))))))
  (testing "regex spec-files without a matcher returns an error"
    (let [lint            (load-lint)
          (ok result err) (pcall (fn []
                                   (lint.check "(var x 1)"
                                               {:path       "fnl/spec/x.fnl"
                                                :spec-files ["^fnl/spec/.*$"]
                                                :rules      {"no-mutation" :warning}})))]
      (is (and (not (. lint :module-missing))
               (not ok)
               result
               (. result :message)))))
  (testing "the default spec-files prefix works without a matcher"
    (let [lint   (load-lint)
          result (lint.check "(var x 1)"
                             {:path       "fnl/spec/x.fnl"
                              :spec-files ["^fnl/spec/"]
                              :rules      {"spec-macro-import"   :off
                                           "spec-no-module"      :off
                                           "spec-direct-require" :off
                                           "no-mutation"         :warning}})]
      (is (and (not (. lint :module-missing))
               (= 0 (length result)))))))

(deftest selector-exclusions
  (testing "matches an exclusion pattern against the repository-relative path"
    (is (= []
           (finding-summary (check-source-with-matcher "(if ok then)" "fnl/legacy/a.fnl" {"if-without-else" :warning} [{:rule "if-without-else" :pattern "^fnl/legacy/"}])))))
  (testing "matches a single finding line"
    (is (= 1
           (length (check-source-with-matcher "(if one then)\n\n(if two then)"
                                              "fnl/app.fnl"
                                              {"if-without-else" :warning}
                                              [{:rule "if-without-else" :line 1}])))))
  (testing "matches an intersecting line range"
    (is (= 1
           (length (check-source-with-matcher "(if one then)\n\n(if two then)"
                                              "fnl/app.fnl"
                                              {"if-without-else" :warning}
                                              [{:rule "if-without-else" :lines {:from 1 :to 2}}])))))
  (testing "matches code in the finding form"
    (is (= []
           (finding-summary (check-source-with-matcher "(if ok then)" "fnl/app.fnl" {"if-without-else" :warning} [{:rule "if-without-else" :code "if"}])))))
  (testing "matches code only against the selected finding source"
    (let [result (check-source-with-matcher "(var baz 1)\n(var foo 2)"
                                            "fnl/app.fnl"
                                            {"no-mutation" :warning}
                                            [{:rule "no-mutation" :code "baz"}])]
      (is (= [["no-mutation" "fnl/app.fnl > top#2" "warning"]]
             (finding-identities result)))))
  (testing "combines path and line selectors with AND semantics"
    (is (= []
           (finding-summary (check-source-with-matcher "(if ok then)" "fnl/app.fnl" {"if-without-else" :warning} [{:rule "if-without-else" :pattern "app[.]fnl" :line 1}] )))))
  (testing "a general exclusion without a rule applies to every rule"
    (is (= []
           (finding-summary (check-source-with-matcher "(if ok then)" "fnl/app.fnl" {"module-style" :error "if-without-else" :warning} [{:pattern "app[.]fnl" :line 1}])))))
  (testing "a per-rule exclusion applies only to its configured rule"
    (let [result (check-source-with-matcher "(if ok then)"
                                            "fnl/app.fnl"
                                            {"module-style"    :error
                                             "if-without-else" {:severity   :warning
                                                                :exclusions [{:line 1}]}}
                                            nil)]
      (is (= ["module-style"]
             (icollect [_ finding (ipairs result)] (. finding :rule))))))
  (testing "a code selector does not match a file-level finding"
    (is (= 1
           (length (check-source-with-matcher "(local value 1)"
                                              "fnl/app.fnl"
                                              {"module-style" :error}
                                              [{:rule "module-style" :code "local"}])))))
  (testing "a regex exclusion without a matcher returns an error"
    (let [lint            (load-lint)
          (ok result err) (pcall (fn []
                                   (lint.check "(if ok then)"
                                               {:path       "fnl/app.fnl"
                                                :rules      {"if-without-else" :warning}
                                                :exclusions [{:rule    "if-without-else"
                                                              :pattern "app[.]fnl"}]})))]
      (is (and (not (. lint :module-missing))
               (not ok)
               result
               (. result :message))))))
