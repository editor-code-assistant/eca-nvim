(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(defn- load-lint []
  (let [(ok result) (pcall require :fennel-extras.lint)]
    (if ok
        result
        {:module-missing true})))

(defn- check-source [source path rules]
  (let [lint (load-lint)]
    (if (. lint :module-missing)
        lint
        (let [ctx (if rules
                      {:path path :rules rules}
                      {:path path})
              (findings err) (lint.check source ctx)]
          (if findings
              findings
              {:value-nil? true
               :message (and err (. err :message))
               :line (and err (. err :line))
               :col (and err (. err :col))})))))

(defn- finding-summary [result]
  (if (or (. result :module-missing) (. result :value-nil?))
      result
      (icollect [_ finding (ipairs result)]
        {:kind (. finding :kind)
         :path (. finding :path)
         :line (. finding :line)
         :col (. finding :col)
         :end-line (. finding :end-line)
         :end-col (. finding :end-col)
         :severity (. finding :severity)
         :rule (. finding :rule)
         :form (. finding :form)
         :message (. finding :message)})))

(defn- finding-identities [result]
  (if (or (. result :module-missing) (. result :value-nil?))
      result
      (icollect [_ finding (ipairs result)]
        [(. finding :rule) (. finding :form) (. finding :severity)])))

(defn- findings-for-rule [source path rule rules]
  (let [result (check-source source path rules)]
    (if (or (. result :module-missing) (. result :value-nil?))
        result
        (icollect [_ finding (ipairs result)]
          (if (= (. finding :rule) rule)
              [(. finding :rule) (. finding :form) (. finding :severity)])))))

(defn- forms-for [source path rules]
  (finding-identities (check-source source path rules)))

(defn- read-source [path]
  (let [(ok result) (pcall (fn []
                             (let [file (assert (io.open path :r))
                                   source (file:read "*a")]
                               (file:close)
                               source)))]
    (if ok
        result
        {:error "read failed" :path path})))

(defn- project-fennel-files []
  (let [paths []
        files (vim.fn.globpath "fnl" "**/*.fnl" false true)]
    (each [_ path (ipairs files)]
      (if (not (string.find path "^fnl/eca/nfnl/"))
          (table.insert paths path)))
    paths))

(defn- collect-repo-findings [lint counts lint-files]
  (each [_ path (ipairs (project-fennel-files))]
    (let [source (read-source path)]
      (if (. source :error)
          (table.insert lint-files path)
          (let [findings (lint.check source {:path path})]
            (each [_ finding (ipairs findings)]
              (if (. counts (. finding :rule))
                  (tset counts (. finding :rule) (+ (. counts (. finding :rule)) 1))))
            (if (string.find path "^fnl/fennel%-extras/lint")
                (each [_ finding (ipairs findings)]
                  (table.insert lint-files [path (. finding :rule)])))))))
  {:counts counts :lint-files lint-files})

(defn- repo-scenario []
  (let [lint (load-lint)
        counts {"module-style" 0
                "spec-macro-import" 0
                "spec-no-module" 0
                "spec-direct-require" 0
                "one-is-per-testing" 0
                "core-require" 0}
        lint-files []]
    (if (. lint :module-missing)
        {:module-missing true}
        (collect-repo-findings lint counts lint-files))))

(deftest module-style
  (testing "a compliant non-spec module is clean"
    (is (= []
           (forms-for "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)"
                      "fnl/app.fnl" nil))))
  (testing "a non-spec file without a module form has one file finding"
    (is (= [["module-style" "fnl/legacy.fnl > file" "error"]]
           (forms-for "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(defn run [] 1)"
                      "fnl/legacy.fnl" nil))))
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
                      "fnl/app.fnl" nil))))
  (testing "a nested module form is reported in a non-spec file"
    (is (= [["module-style" "fnl/app.fnl > file" "error"]]
           (findings-for-rule "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(if ok (module app) x)"
                              "fnl/app.fnl" "module-style"))))
  (testing "a nested aniseed import is reported in a non-spec file"
    (is (= [["module-style" "fnl/app.fnl > file" "error"]]
           (findings-for-rule "(if ok (import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed) x)\n(module app)"
                              "fnl/app.fnl" "module-style"))))
  (testing "a quoted top-level module form is reported as non-module style"
    (is (= [["module-style" "fnl/app.fnl > file" "error"]]
           (findings-for-rule "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n'(module app)"
                              "fnl/app.fnl" "module-style"))))
  (testing "a quasiquoted top-level module form is reported as non-module style"
    (is (= [["module-style" "fnl/app.fnl > file" "error"]]
           (findings-for-rule "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n`(module app)"
                              "fnl/app.fnl" "module-style"))))
  (testing "an unquoted top-level module form is reported as non-module style"
    (is (= [["module-style" "fnl/app.fnl > file" "error"]]
           (findings-for-rule "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n,(module app)"
                              "fnl/app.fnl" "module-style"))))
  (testing "a hashfn top-level module form is reported as non-module style"
    (is (= [["module-style" "fnl/app.fnl > file" "error"]]
           (findings-for-rule "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n#(module app)"
                              "fnl/app.fnl" "module-style"))))
  (testing "a prefixed aniseed import with a real module is reported as non-module style"
    (is (= [["module-style" "fnl/app.fnl > file" "error"]]
           (findings-for-rule "'(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)"
                              "fnl/app.fnl" "module-style"))))
  (testing "top-level module and import forms stay clean in either order with comments"
    (is (= []
           (forms-for "(module app)\n;; between top-level forms\n(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)"
                      "fnl/app.fnl" nil))))
  (testing "a legacy fn and final table are reported as non-module style"
    (is (= [["module-style" "fnl/legacy.fnl > file" "error"]]
           (forms-for "(fn run [] 1)\n{:run run}" "fnl/legacy.fnl" nil))))
  (testing "module-style never applies to spec files"
    (is (= []
           (forms-for "(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"works\" (is true)))"
                      "fnl/spec/app_spec.fnl" nil)))))

(deftest spec-shape
  (testing "the approved spec macro import is clean"
    (is (= []
           (forms-for "(import-macros {: deftest : testing : is} :spec.eca.macros)"
                      "fnl/spec/app_spec.fnl" nil))))
  (testing "a spec macro import missing is is reported"
    (is (= [["spec-macro-import" "fnl/spec/app_spec.fnl > spec" "error"]]
           (forms-for "(import-macros {: deftest : testing} :spec.eca.macros)"
                      "fnl/spec/app_spec.fnl" nil))))
  (testing "a spec macro import from another module is reported"
    (is (= [["spec-macro-import" "fnl/spec/app_spec.fnl > spec" "error"]]
           (forms-for "(import-macros {: deftest : testing : is} :other.macros)"
                      "fnl/spec/app_spec.fnl" nil))))
  (testing "a spec with no macro import has the spec identity"
    (is (= [["spec-macro-import" "fnl/spec/app_spec.fnl > spec" "error"]]
           (forms-for "(deftest run (is true))" "fnl/spec/app_spec.fnl" nil))))
  (testing "a prefixed spec macro import is reported"
    (is (= [["spec-macro-import" "fnl/spec/app_spec.fnl > spec" "error"]]
           (findings-for-rule "'(import-macros {: deftest : testing : is} :spec.eca.macros)"
                              "fnl/spec/app_spec.fnl" "spec-macro-import"))))
  (testing "a nested spec macro import is reported"
    (is (= [["spec-macro-import" "fnl/spec/x_spec.fnl > spec" "error"]]
           (findings-for-rule "(do (import-macros {: deftest : testing : is} :spec.eca.macros))\n(deftest run (testing \"works\" (is true)))"
                              "fnl/spec/x_spec.fnl" "spec-macro-import"))))
  (testing "a wrong macro import is reported independently of test content"
    (is (= [["spec-macro-import" "fnl/spec/app_spec.fnl > spec" "error"]]
           (forms-for "(import-macros {: deftest} :other) (deftest t (testing \"x\" (is true)))"
                      "fnl/spec/app_spec.fnl" nil))))
  (testing "a spec with only a direct require still has the spec identity"
    (is (= [["spec-macro-import" "fnl/spec/app_spec.fnl > spec" "error"]]
           (forms-for "(require :foo)" "fnl/spec/app_spec.fnl" nil))))
  (testing "a module form in a spec is reported at that form"
    (is (= [["spec-no-module" "fnl/spec/app_spec.fnl > module:app" "error"]]
           (forms-for "(module app)\n(import-macros {: deftest : testing : is} :spec.eca.macros)"
                      "fnl/spec/app_spec.fnl" nil))))

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
                        "fnl/spec/eca/macros.fnlm" nil))))
    (testing "direct test-library requires are not a non-spec finding"
      (is (= []
             (forms-for "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module ordinary)\n(require :plenary.busted)\n(require \"luassert\")"
                        "fnl/ordinary.fnl" nil)))))

  (deftest one-is-per-testing
    (testing "one direct is in testing is clean"
      (is (= []
             (forms-for "(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"one\" (is true)))"
                        "fnl/spec/app_spec.fnl" nil))))
    (testing "one is inside a let wrapper is clean"
      (is (= []
             (forms-for "(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"one\" (let [x 1] (is (= x 1)))))"
                        "fnl/spec/app_spec.fnl" nil))))
    (testing "testing with no is is reported"
      (is (= [["one-is-per-testing" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
             (findings-for-rule "(deftest run (testing \"none\" (let [x 1] x)))"
                                "fnl/spec/app_spec.fnl" "one-is-per-testing"))))
    (testing "testing with two is forms is reported once"
      (is (= [["one-is-per-testing" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
             (findings-for-rule "(deftest run (testing \"two\" (is true) (is true)))"
                                "fnl/spec/app_spec.fnl" "one-is-per-testing"))))
    (testing "nested testing forms are counted separately"
      (is (= [["one-is-per-testing" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
             (findings-for-rule "(deftest run (testing \"outer\" (testing \"inner\" (is true))))"
                                "fnl/spec/app_spec.fnl" "one-is-per-testing"))))
    (testing "quoted is data is not counted"
      (is (= [["one-is-per-testing" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
             (findings-for-rule "(deftest run (testing \"quoted\" '(is true)))"
                                "fnl/spec/app_spec.fnl" "one-is-per-testing"))))
    (testing "a quoted is separated by a comment is not counted"
      (is (= [["one-is-per-testing" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
             (findings-for-rule "(deftest run (testing \"x\" '
 ;; comment
 (is true)))"
                                "fnl/spec/app_spec.fnl" "one-is-per-testing"))))
    (testing "a quasiquoted is separated by a newline is not counted"
      (is (= [["one-is-per-testing" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
             (findings-for-rule "(deftest run (testing \"x\" `
(is true)))"
                                "fnl/spec/app_spec.fnl" "one-is-per-testing"))))
    (testing "a quoted is separated by whitespace is not counted"
      (is (= [["one-is-per-testing" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
             (findings-for-rule "(deftest run (testing \"x\" ' (is true)))"
                                "fnl/spec/app_spec.fnl" "one-is-per-testing"))))
    (testing "a quoted is plus an executable is is counted once"
      (is (= []
             (findings-for-rule "(deftest run (testing \"x\" '(is false) (is true)))"
                                "fnl/spec/app_spec.fnl" "one-is-per-testing"))))
    (testing "strings and comments containing is are not counted"
      (is (= [["one-is-per-testing" "fnl/spec/app_spec.fnl > deftest:run > testing#1" "error"]]
             (findings-for-rule "(deftest run (testing \"is in text\" (print \"is\"))) ;; is\n"
                                "fnl/spec/app_spec.fnl" "one-is-per-testing")))))

  (deftest if-branch-call
    (testing "a multi-expression then do is a warning"
      (is (= [["if-branch-call" "fnl/app.fnl > defn:run > if#1 > then" "warning"]]
             (findings-for-rule "(defn run [] (if ok (do a b) c))" "fnl/app.fnl" "if-branch-call"))))
    (testing "a one-expression do is clean"
      (is (= []
             (forms-for "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(defn run [] (if ok (do a) c))" "fnl/app.fnl" nil))))
    (testing "let and set branches are clean"
      (is (= []
             (forms-for "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(defn run [] (if ok (let [x 1] x) (set x 1)))"
                        "fnl/app.fnl" nil))))
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
             (forms-for "(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(defn run [] (if ok (let [x 1] (do a b)) c))" "fnl/app.fnl" nil))))
    (testing "if branch severity can be overridden to error"
      (is (= [["if-branch-call" "fnl/app.fnl > defn:run > if#1 > then" "error"]]
             (findings-for-rule "(defn run [] (if ok (do a b) c))" "fnl/app.fnl"
                                "if-branch-call" {"if-branch-call" :error}))))
    (testing "if branch rule can be disabled"
      (is (= []
             (findings-for-rule "(defn run [] (if ok (do a b) c))" "fnl/app.fnl"
                                "if-branch-call" {"if-branch-call" :off}))))

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
               (finding-identities (check-source "(defn run [] (if ok (do a b) (do c d)))" "fnl/app.fnl" {"module-style" :off})))))
      (testing "no two findings share path rule and form"
        (is (= {:findings [["if-branch-call" "fnl/app.fnl > defn:run > if#1 > then" "warning"]
                           ["if-branch-call" "fnl/app.fnl > defn:run > if#1 > else" "warning"]]
                :duplicates []}
               (let [findings (finding-identities (check-source "(defn run [] (if ok (do a b) (do c d)))" "fnl/app.fnl" {"module-style" :off}))
                     seen {}
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
                                  "fnl/app.fnl" "core-require"))))
      (testing "reader failure returns nil and a structured error table"
        (is (= {:value-nil? true :message "missing closing delimiter" :line 1 :col 1}
               (check-source "(unclosed" "fnl/bad.fnl" nil)))))
  ))

(defn- function-findings [source]
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
           (function-findings "(defn- join [xs]
  (if (= xs [])
      nil
      (let [parts (icollect [_ x (ipairs xs)] x)]
        (table.concat parts \" \"))))"))))
  (testing "a first let with leaf bindings and body is clean"
    (is (= []
           (function-findings "(defn run [x]
  (let [a x b 1]
    (+ a b)))"))))
  (testing "an if in a let binding value is reported"
    (is (= 1 (length (function-findings "(defn run [x]
  (let [a (if x 1 2)] a))")))))
  (testing "a let after the first body expression is reported"
    (is (= 1 (length (function-findings "(defn run [x]
  x
  (let [a 1] a))")))))
  (testing "a second nested let is reported"
    (is (= 1 (length (function-findings "(defn run [x]
  (let [a x]
    (let [b a] b)))")))))
  (testing "a multi-clause flat if is clean"
    (is (= []
           (function-findings "(defn run [x]
  (if x 1 y 2 3))"))))
  (testing "a case with leaf clauses is clean"
    (is (= []
           (function-findings "(defn run [x]
  (case x 1 :one 2 :two :other))"))))
  (testing "a nested if in a case clause is reported"
    (is (= 1 (length (function-findings "(defn run [x]
  (case x 1 (if x :one :other) :other))")))))
  (testing "a match with leaf clauses is clean"
    (is (= []
           (function-findings "(defn run [x]
  (match x 1 :one 2 :two :other))"))))
  (testing "a nested if in a match clause is reported"
    (is (= 1 (length (function-findings "(defn run [x]
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
    (is (= 1 (length (function-findings "(defn run [xs]
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
  (if x (if y a b) (if z c d)))"))))

)

(deftest repo-properties
  (testing "project Fennel files have the approved rule counts"
    (is (= {"module-style" 24
            "spec-macro-import" 0
            "spec-no-module" 0
            "spec-direct-require" 0
            "one-is-per-testing" 0
            "core-require" 0}
           (. (repo-scenario) :counts))))
  (testing "lint implementation files are clean"
    (is (= [] (. (repo-scenario) :lint-files)))) )

(defn- check-context
  [source ctx]
  (let [lint (load-lint)]
    (if (. lint :module-missing)
        lint
        (let [(findings err) (lint.check source ctx)]
          (if findings
              findings
              {:value-nil? true :error err})))))

(defn- first-finding-form
  [findings rule]
  (var result nil)
  (each [_ finding (ipairs findings)]
    (if (and (= result nil) (= (. finding :rule) rule))
        (set result (. finding :form))))
  result)

(deftest exclusions
  (let [source "(defn run [] (if ok (do a b) c))"
        path "fnl/app.fnl"
        rules {"module-style" :off}
        baseline (check-context source {:path path :rules rules})
        form (first-finding-form baseline "if-branch-call")]
    (testing "an exclusion suppresses only an exact rule and form match"
      (is (= []
             (check-context source {:path path
                                    :rules rules
                                    :exclusions [{:rule "if-branch-call"
                                                  :form form
                                                  :reason "intentional"}]}))))
    (testing "an exclusion with the same form but a different rule does not suppress"
      (is (= ["if-branch-call"]
             (icollect [_ finding (ipairs (check-context source {:path path
                                                                 :rules rules
                                                                 :exclusions [{:rule "core-require"
                                                                               :form form
                                                                               :reason "intentional"}]}))]
               (. finding :rule)))))
    (testing "an exclusion with the same rule but a different form does not suppress"
      (is (= ["if-branch-call"]
             (icollect [_ finding (ipairs (check-context source {:path path
                                                                 :rules rules
                                                                 :exclusions [{:rule "if-branch-call"
                                                                               :form (.. form " > other")
                                                                               :reason "intentional"}]}))]
               (. finding :rule)))))))
