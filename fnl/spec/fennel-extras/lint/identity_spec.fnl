(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(defn- load-identity []
  (let [(ok result) (pcall require :fennel-extras.lint.identity)]
    (if ok
        result
        {:module-missing true})))

(defn- identity-forms [source path]
  (let [identity (load-identity)]
    (if (. identity :module-missing)
        identity
        (let [(forms err) (identity.forms source path)]
          (if forms
              forms
              {:reader-error err})))))

(defn- form-ids [source path]
  (let [forms (identity-forms source path)]
    (if (or (. forms :module-missing) (. forms :reader-error))
        forms
        (icollect [_ form (ipairs forms)]
          (. form :form)))))

(defn- find-form-id [forms form-id]
  (var result nil)
  (each [_ form (ipairs forms)]
    (if (= form-id (. form :form))
        (set result form)))
  result)

(defn- form-by-id [source path form-id]
  (let [forms (identity-forms source path)]
    (if (or (. forms :module-missing) (. forms :reader-error))
        forms
        (find-form-id forms form-id))))

(defn- span-summary [source path form-id]
  (let [form (form-by-id source path form-id)]
    (if (or (. form :module-missing) (. form :reader-error))
        form
        {:line (. form :line)
         :col (. form :col)
         :end-line (. form :end-line)
         :end-col (. form :end-col)})))

(defn- location-summary [source path form-id]
  (let [form (form-by-id source path form-id)]
    (if form
        {:line (. form :line)
         :col (. form :col)}
        nil)))

(defn- reader-end-summary [source]
  (let [reader (require :fennel-extras.reader)
        tokens (reader.tokenize source)
        closing (. tokens (length tokens))]
    {:line 1
     :col 1
     :end-line (. closing :line)
     :end-col (+ (. closing :col) 1)}))

(defn- failure-summary [source path]
  (let [identity (load-identity)]
    (if (. identity :module-missing)
        identity
        (let [(value err) (identity.forms source path)]
          {:value-nil? (= nil value)
           :message (and err (. err :message))
           :line (and err (. err :line))
           :col (and err (. err :col))}))))

(deftest named-identities
  (testing "module and named declarations form stable ancestor identities"
    (is (= ["fnl/app.fnl > module:app"
            "fnl/app.fnl > module:app > defn:run"
            "fnl/app.fnl > module:app > defn:run > if#1"]
           (form-ids "(module app)\n(defn run [] (if a b c))" "fnl/app.fnl"))))
  (testing "def, private defn, and deftest declarations use named segments"
    (is (= ["fnl/names.fnl > module:names"
            "fnl/names.fnl > module:names > def:value"
            "fnl/names.fnl > module:names > defn-:hidden"
            "fnl/names.fnl > module:names > deftest:works"]
           (form-ids "(module names)\n(def value 1)\n(defn- hidden [] 1)\n(deftest works (is true))" "fnl/names.fnl")))))

(deftest legacy-identities
  (testing "legacy named fn ancestors are preserved"
    (is (= ["fnl/legacy.fnl > fn:run"
            "fnl/legacy.fnl > fn:run > if#1"]
           (form-ids "(fn run [] (if a b c))" "fnl/legacy.fnl"))))
  (testing "local fn bindings name the ancestor without an anonymous fn segment"
    (is (= ["fnl/legacy.fnl > local:run"
            "fnl/legacy.fnl > local:run > if#1"]
           (form-ids "(local run (fn [] (if a b c)))" "fnl/legacy.fnl")))))

(deftest unnamed-identities
  (testing "unnamed top-level forms use trivia-independent ordinals"
    (is (= ["fnl/unnamed.fnl > top#1" "fnl/unnamed.fnl > top#2"]
           (form-ids ";; ignored\n(foo)\n\n(bar)" "fnl/unnamed.fnl"))))
  (testing "unnamed nested siblings count only the same node kind"
    (is (= ["fnl/nested.fnl > defn:run"
            "fnl/nested.fnl > defn:run > if#1"
            "fnl/nested.fnl > defn:run > if#2"]
           (form-ids "(defn run [] (if a b c) (vector 1) (if d e f))" "fnl/nested.fnl")))))

(deftest collection-identities
  (testing "sequence and table nodes expose identities and nested if identities"
    (is (= ["fnl/collections.fnl > defn:run"
            "fnl/collections.fnl > defn:run > sequence#1"
            "fnl/collections.fnl > defn:run > sequence#1 > if#1"
            "fnl/collections.fnl > defn:run > table#1"
            "fnl/collections.fnl > defn:run > table#1 > if#1"]
           (form-ids "(defn run [] [1 (if a b c)] {:x (if d e f)})" "fnl/collections.fnl"))))
  (testing "top-level sequences and tables use top-level ordinals"
    (is (= ["fnl/collections.fnl > top#1"
            "fnl/collections.fnl > top#1 > if#1"
            "fnl/collections.fnl > top#2"
            "fnl/collections.fnl > top#2 > if#1"]
           (form-ids "[1 (if a b c)] {:x (if d e f)}" "fnl/collections.fnl")))))

(deftest branch-identities
  (testing "if branch child forms expose then and else identity segments"
    (is (= ["fnl/branches.fnl > defn:run"
            "fnl/branches.fnl > defn:run > if#1"
            "fnl/branches.fnl > defn:run > if#1 > then"
            "fnl/branches.fnl > defn:run > if#1 > else"]
           (form-ids "(defn run [] (if a (do b c) (do d e)))" "fnl/branches.fnl"))))
  (testing "multi-clause if bodies use numbered then segments and final else"
    (is (= ["fnl/branches.fnl > defn:run"
            "fnl/branches.fnl > defn:run > if#1"
            "fnl/branches.fnl > defn:run > if#1 > then"
            "fnl/branches.fnl > defn:run > if#1 > then#2"
            "fnl/branches.fnl > defn:run > if#1 > else"]
           (form-ids "(defn run [] (if a (do b) c (do d) (do e)))" "fnl/branches.fnl"))))
  (testing "if with only a condition has only a then branch"
    (is (= ["fnl/branches.fnl > defn:run"
            "fnl/branches.fnl > defn:run > if#1"
            "fnl/branches.fnl > defn:run > if#1 > then"]
           (form-ids "(defn run [] (if a (do b)))" "fnl/branches.fnl")))))

(deftest stability
  (testing "unrelated named top-level insertion does not change named identities"
    (let [before (form-by-id "(module app)\n(defn run [] (if a b c))" "fnl/app.fnl" "fnl/app.fnl > module:app > defn:run > if#1")
          after (form-by-id "(defn other [] 1)\n(module app)\n(defn run [] (if a b c))" "fnl/app.fnl" "fnl/app.fnl > module:app > defn:run > if#1")]
      (is (and (not (. before :module-missing))
               (= (. before :form) (. after :form)))))))

(deftest reader-boundaries
  (testing "comments and strings containing delimiters do not create forms"
    (is (= ["fnl/comments.fnl > top#1"]
           (form-ids ";; (if a b c)\n(print \"(if a b c)\")" "fnl/comments.fnl"))))
  (testing "quote prefix preserves the quoted list as a form"
    (is (= ["fnl/quote.fnl > top#1"]
           (form-ids "'(if a b)" "fnl/quote.fnl"))))
  (testing "reader failures return nil plus a structured message and location"
    (is (= {:value-nil? true
            :message "missing closing delimiter"
            :line 1
            :col 1}
           (failure-summary "(unclosed" "fnl/bad.fnl")))))

(deftest spans
  (testing "single-line spans end at the column after the closing delimiter"
    (is (= {:line 1 :col 1 :end-line 1 :end-col 9}
           (span-summary "(if a b)" "fnl/span.fnl" "fnl/span.fnl > top#1"))))
  (testing "multi-line spans use end-exclusive line and column positions"
    (is (= {:line 1 :col 1 :end-line 3 :end-col 5}
           (span-summary "(if\n  a\n  b)" "fnl/span.fnl" "fnl/span.fnl > top#1"))))
  (testing "columns follow the reader's one-based UTF-8 character convention"
    (is (= {:line 1 :col 1 :end-line 1 :end-col 9}
           (span-summary "(foo é)" "fnl/utf8.fnl" "fnl/utf8.fnl > top#1"))))
  (testing "three-byte UTF-8 end columns follow the reader closing delimiter"
    (is (= (reader-end-summary "(foo €)")
           (span-summary "(foo €)" "fnl/utf8.fnl" "fnl/utf8.fnl > top#1"))))
  (testing "four-byte UTF-8 end columns follow the reader closing delimiter"
    (is (= (reader-end-summary "(foo 😀)")
           (span-summary "(foo 😀)" "fnl/utf8.fnl" "fnl/utf8.fnl > top#1"))))
  (testing "multi-line UTF-8 end columns follow the reader closing delimiter"
    (is (= (reader-end-summary "(foo\n  €😀)")
           (span-summary "(foo\n  €😀)" "fnl/utf8.fnl" "fnl/utf8.fnl > top#1")))))

(defn- file-paths []
  (let [paths []
        fnl-files (vim.fn.globpath "fnl" "**/*.fnl" false true)
        fnlm-files (vim.fn.globpath "fnl" "**/*.fnlm" false true)]
    (each [_ path (ipairs fnl-files)]
      (if (not (string.find path "^fnl/eca/nfnl/"))
          (table.insert paths path)))
    (each [_ path (ipairs fnlm-files)]
      (if (not (string.find path "^fnl/eca/nfnl/"))
          (table.insert paths path)))
    paths))

(defn- read-source [path]
  (let [(ok result) (pcall (fn []
                             (let [file (assert (io.open path :r))
                                   source (file:read "*a")]
                               (file:close)
                               source)))]
    (if ok
        result
        nil)))

(defn- report-duplicate [duplicates reported form-id]
  (table.insert duplicates form-id)
  (tset reported form-id true))

(defn- duplicate-form-ids [forms]
  (let [seen {}
        reported {}
        duplicates []]
    (each [_ form (ipairs forms)]
      (let [form-id (. form :form)]
        (if (. seen form-id)
            (if (not (. reported form-id))
                (report-duplicate duplicates reported form-id))
            (tset seen form-id true))))
    duplicates))

(defn- repo-duplicates []
  (let [duplicates []]
    (each [_ path (ipairs (file-paths))]
      (let [source (read-source path)
            forms (if source (identity-forms source path) nil)]
        (if (and forms (not (. forms :module-missing)) (not (. forms :reader-error)))
            (let [form-duplicates (duplicate-form-ids forms)]
              (if (> (length form-duplicates) 0)
                  (table.insert duplicates path)))
            (table.insert duplicates path))))
    duplicates))

(deftest paths
  (testing "paths use slash separators and are passed through verbatim"
    (is (= ["src/foo/bar.fnl > top#1"]
           (form-ids "(value)" "src/foo/bar.fnl")))))

(deftest segmented-ancestor-ordinals
  (testing "same-kind forms count through plain wrapper lists"
    (is (= ["fnl/wrappers.fnl > fn:f"
            "fnl/wrappers.fnl > fn:f > sequence#1"
            "fnl/wrappers.fnl > fn:f > sequence#2"]
           (form-ids "(fn f [] (foo (bar [1]) (baz [2])))" "fnl/wrappers.fnl"))))
  (testing "if forms count through plain wrapper lists"
    (is (= ["fnl/wrappers.fnl > defn:g"
            "fnl/wrappers.fnl > defn:g > if#1"
            "fnl/wrappers.fnl > defn:g > if#2"]
           (form-ids "(defn g [] (do (when x (if a b c)) (if d e f)))" "fnl/wrappers.fnl")))))

(deftest nested-branch-roots
  (testing "nested if branch roots expose separate branch and inner-if forms"
    (is (= ["fnl/nested-branches.fnl > top#1"
            "fnl/nested-branches.fnl > top#1 > then"
            "fnl/nested-branches.fnl > top#1 > then > if#1"
            "fnl/nested-branches.fnl > top#1 > else"
            "fnl/nested-branches.fnl > top#1 > else > if#1"]
           (form-ids "(if a (if b c d) (if e f g))" "fnl/nested-branches.fnl")))))

(deftest testing-identities
  (testing "sibling testing forms expose numbered identities"
    (is (= ["fnl/testing.fnl > deftest:run"
            "fnl/testing.fnl > deftest:run > testing#1"
            "fnl/testing.fnl > deftest:run > testing#2"]
           (form-ids "(deftest run (testing \"one\" (is true)) (testing \"two\" (is true)))" "fnl/testing.fnl"))))
  (testing "sibling testing forms keep their source locations"
    (is (= {:first {:line 1 :col 14}
            :second {:line 1 :col 40}}
           {:first (location-summary "(deftest run (testing \"one\" (is true)) (testing \"two\" (is true)))"
                                     "fnl/testing.fnl"
                                     "fnl/testing.fnl > deftest:run > testing#1")
            :second (location-summary "(deftest run (testing \"one\" (is true)) (testing \"two\" (is true)))"
                                      "fnl/testing.fnl"
                                      "fnl/testing.fnl > deftest:run > testing#2")})))
  (testing "testing ordinals count through plain wrapper lists"
    (is (= ["fnl/testing.fnl > deftest:run"
            "fnl/testing.fnl > deftest:run > testing#1"
            "fnl/testing.fnl > deftest:run > testing#2"]
           (form-ids "(deftest run (let [x 1] (testing \"a\" (is x))) (testing \"b\" (is true)))"
                     "fnl/testing.fnl"))))
  (testing "nested testing forms restart ordinals under each testing parent"
    (is (= ["fnl/testing.fnl > deftest:run"
            "fnl/testing.fnl > deftest:run > testing#1"
            "fnl/testing.fnl > deftest:run > testing#1 > testing#1"]
           (form-ids "(deftest run (testing \"outer\" (testing \"inner\" (is true))))"
                     "fnl/testing.fnl"))))
  (testing "testing and if ordinals are tracked independently"
    (is (= ["fnl/testing.fnl > deftest:run"
            "fnl/testing.fnl > deftest:run > testing#1"
            "fnl/testing.fnl > deftest:run > testing#1 > if#1"]
           (form-ids "(deftest run (testing \"outer\" (if true (is true) (is false))))"
                     "fnl/testing.fnl")))))

(defn- binding-vector-identities []
  {:let (form-ids "(defn run [] (let [x xs] [1 2]))" "fnl/bindings.fnl")
   :when-let (form-ids "(defn run [] (when-let [x xs] [1 2]))" "fnl/bindings.fnl")
   :if-let (form-ids "(defn run [] (if-let [x xs] [1 2]))" "fnl/bindings.fnl")
   :each (form-ids "(defn run [] (each [x (ipairs xs)] [1 2]))" "fnl/bindings.fnl")
   :for (form-ids "(defn run [] (for [x (ipairs xs)] [1 2]))" "fnl/bindings.fnl")
   :icollect (form-ids "(defn run [] (icollect [i x (ipairs xs)] [1 2]))" "fnl/bindings.fnl")
   :collect (form-ids "(defn run [] (collect [x (ipairs xs)] [1 2]))" "fnl/bindings.fnl")
   :accumulate (form-ids "(defn run [] (accumulate [acc 0 _ x (ipairs xs)] [1 2]))" "fnl/bindings.fnl")
   :with-open (form-ids "(defn run [] (with-open [f (io.open p)] [1 2]))" "fnl/bindings.fnl")
   :fn (form-ids "(defn run [] (fn [x xs] [1 2]))" "fnl/bindings.fnl")
   :lambda (form-ids "(defn run [] (lambda [x xs] [1 2]))" "fnl/bindings.fnl")
   :lambda-symbol (form-ids "(defn run [] (λ [x xs] [1 2]))" "fnl/bindings.fnl")
   :defn (form-ids "(defn inner [x xs] [1 2])" "fnl/bindings.fnl")
   :defn- (form-ids "(defn- inner [x xs] [1 2])" "fnl/bindings.fnl")
   :macro (form-ids "(macro inner [x xs] [1 2])" "fnl/bindings.fnl")})

(deftest binding-vector-identities
  (testing "binding and parameter vectors do not get identities"
    (is (= {:let ["fnl/bindings.fnl > defn:run"
                  "fnl/bindings.fnl > defn:run > sequence#1"]
            :when-let ["fnl/bindings.fnl > defn:run"
                       "fnl/bindings.fnl > defn:run > sequence#1"]
            :if-let ["fnl/bindings.fnl > defn:run"
                     "fnl/bindings.fnl > defn:run > sequence#1"]
            :each ["fnl/bindings.fnl > defn:run"
                   "fnl/bindings.fnl > defn:run > sequence#1"]
            :for ["fnl/bindings.fnl > defn:run"
                  "fnl/bindings.fnl > defn:run > sequence#1"]
            :icollect ["fnl/bindings.fnl > defn:run"
                       "fnl/bindings.fnl > defn:run > sequence#1"]
            :collect ["fnl/bindings.fnl > defn:run"
                      "fnl/bindings.fnl > defn:run > sequence#1"]
            :accumulate ["fnl/bindings.fnl > defn:run"
                         "fnl/bindings.fnl > defn:run > sequence#1"]
            :with-open ["fnl/bindings.fnl > defn:run"
                        "fnl/bindings.fnl > defn:run > sequence#1"]
            :fn ["fnl/bindings.fnl > defn:run"
                 "fnl/bindings.fnl > defn:run > sequence#1"]
            :lambda ["fnl/bindings.fnl > defn:run"
                     "fnl/bindings.fnl > defn:run > sequence#1"]
            :lambda-symbol ["fnl/bindings.fnl > defn:run"
                            "fnl/bindings.fnl > defn:run > sequence#1"]
            :defn ["fnl/bindings.fnl > defn:inner"
                   "fnl/bindings.fnl > defn:inner > sequence#1"]
            :defn- ["fnl/bindings.fnl > defn-:inner"
                    "fnl/bindings.fnl > defn-:inner > sequence#1"]
            :macro ["fnl/bindings.fnl > top#1"
                    "fnl/bindings.fnl > top#1 > sequence#1"]}
           (binding-vector-identities))))
  (testing "forms nested in binding vectors keep identities in the enclosing namespace"
    (is (= ["fnl/nested-binding.fnl > defn:run"
            "fnl/nested-binding.fnl > defn:run > if#1"]
           (form-ids "(defn run [] (let [x (if a b c)] x))" "fnl/nested-binding.fnl")))))

(deftest anonymous-fn-parameter-vector
  (testing "anonymous fn parameter vectors are syntax and body sequences are forms"
    (is (= ["fnl/anonymous.fnl > top#1"
            "fnl/anonymous.fnl > top#1 > sequence#1"]
           (form-ids "(fn [x] [x])" "fnl/anonymous.fnl")))))

(deftest repo-properties
  (testing "identity form values are unique in every project Fennel source"
    (is (= [] (repo-duplicates)))))
