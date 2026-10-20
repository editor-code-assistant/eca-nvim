(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(defn- load-format
  []
  (let [(ok result) (pcall require :fennel-extras.format)]
    (if ok
      result
      {:error "module missing"})))

(defn- load-parser
  []
  (let [(ok result) (pcall require :eca.nfnl.fennel)]
    (if ok
      result
      {:error "parser module missing"})))

(defn- verifier-scenario
  []
  (let [format (load-format)
        parser (load-parser)
        same-a
        "(when x\ny)"
        same-b
        "(when x\n  y)"
        symbol-a
        "(when x\ny)"
        symbol-b
        "(when z\ny)"
        comment-a
        ";; one\n(foo)"
        comment-b
        ";; two\n(foo)"
        second-a
        "(a)\n(b)"
        second-b
        "(a)\n(c)"]
    {:indent-same     (if (. format :error)
                        false
                        (format.indent-only? same-a same-b))
     :indent-string   (if (. format :error)
                        true
                        (format.indent-only? "(foo \"a\")" "(foo \"b\")"))
     :indent-trailing (if (. format :error)
                        true
                        (format.indent-only? "(foo)" "(foo) "))
     :indent-lines    (if (. format :error)
                        true
                        (format.indent-only? "(foo)\n(bar)" "(foo)"))
     :indent-char     (if (. format :error)
                        true
                        (format.indent-only? "(foo)" "(bar)"))
     :binding-aligned (if (. format :error)
                        false
                        (format.indent-only? "(let [a 1\n      long-name 2])"
                                             "(let [a         1\n      long-name 2])"
                                             true))
     :binding-joined  (if (. format :error)
                        true
                        (format.indent-only? "(let [a 1\n      long-name 2])"
                                             "(let [a1\n      long-name 2])"
                                             true))
     :binding-string  (if (. format :error)
                        true
                        (format.indent-only? "(let [x \"a b\"])"
                                             "(let [x \"a  b\"])"
                                             true))
     :ast-same        (if (or (. format :error) (. parser :error))
                        false
                        (format.ast-equal? parser same-a same-b))
     :ast-symbol      (if (or (. format :error) (. parser :error))
                        true
                        (format.ast-equal? parser symbol-a symbol-b))
     :ast-comment     (if (or (. format :error) (. parser :error))
                        true
                        (format.ast-equal? parser comment-a comment-b))
     :ast-second      (if (or (. format :error) (. parser :error))
                        true
                        (format.ast-equal? parser second-a second-b))}))

(defn- format-summary
  [source config]
  (let [format (load-format)]
    (if (. format :error)
      format
      (let [(ok value err) (pcall (fn [] (format.format-string source {:config config})))]
        {:value?      (and ok (not= nil value))
         :has-message (and ok (= nil value) err (= :string (type (. err :message))))
         :value
         value}))))

(defn- alignment-safety-scenario
  []
  (let [source
        "(let [result {:code 0 \n:lines []}]\n  result)\n"
        format (load-format)]
    (if (. format :error)
      format
      (let [(ok value err) (pcall (fn [] (format.format-string source {:config {:align-bindings true}})))]
        {:value? (and ok (not= nil value))
         :value
         value
         :error
         err}))))

(defn- file-paths
  []
  (let [paths      []
        fnl-files  (vim.fn.globpath "fnl" "**/*.fnl" false true)
        fnlm-files (vim.fn.globpath "fnl" "**/*.fnlm" false true)]
    (each [_ path (ipairs fnl-files)]
      (when (not (string.find path "^fnl/eca/nfnl/"))
        (table.insert paths path)))
    (each [_ path (ipairs fnlm-files)]
      (when (not (string.find path "^fnl/eca/nfnl/"))
        (table.insert paths path)))
    paths))

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

(defn- format-file-scenario
  [format parser config path source format-failures idempotence-failures indent-failures ast-failures]
  (let [(ok formatted err) (pcall (fn [] (format.format-string source {:config config :parser parser})))]
    (if (or (not ok) (= nil formatted) err)
      (table.insert format-failures path)
      (let [_ (when (or (not (pcall (fn [] (format.format-string formatted {:config config :parser parser}))))
                        (not= formatted (format.format-string formatted {:config config :parser parser})))
                (table.insert idempotence-failures path))
            _ (when (not (format.indent-only? source formatted))
                (table.insert indent-failures path))
            _ (when (not (format.ast-equal? parser source formatted))
                (table.insert ast-failures path))]
        nil))))

(defn- repo-scenario
  []
  (let [format               (load-format)
        parser               (load-parser)
        config               {:indents {"deftest" [[:block 1]]
                                        "testing" [[:block 1]]
                                        "if"      [[:block 1]]}}
        format-failures      (if (. format :error) ["module missing"] [])
        idempotence-failures (if (. format :error) ["module missing"] [])
        indent-failures      (if (. format :error) ["module missing"] [])
        ast-failures         (if (. format :error) ["module missing"] [])
        fixed-point-failures []]
    (each [_ path (ipairs (file-paths))]
      (let [source (read-source path)]
        (if (. source :error)
          (each [_ failures (ipairs [format-failures idempotence-failures indent-failures ast-failures])]
            (table.insert failures (.. "read failed: " path)))
          (format-file-scenario format parser config path source format-failures idempotence-failures indent-failures ast-failures))))
    (each [_ path (ipairs ["fnl/eca/ui/widgets/footer-bar.fnl" "fnl/eca/ui/components/lualine.fnl"])]
      (let [source (read-source path)]
        (if (or (. source :error) (. format :error))
          (table.insert fixed-point-failures path)
          (let [(ok formatted) (pcall (fn [] (format.format-string source {:config config :parser parser})))]
            (when (or (not ok) (not= source formatted))
              (table.insert fixed-point-failures path))))))
    {:format
     format-failures
     :idempotence
     idempotence-failures
     :indent
     indent-failures
     :ast
     ast-failures
     :fixed-point
     fixed-point-failures}))

(deftest verifier
  (testing "indent-only accepts pure reindent"
    (is (. (verifier-scenario) :indent-same)))
  (testing "indent-only rejects changed string contents"
    (is (not (. (verifier-scenario) :indent-string))))
  (testing "indent-only rejects changed trailing whitespace"
    (is (not (. (verifier-scenario) :indent-trailing))))
  (testing "indent-only rejects changed line count"
    (is (not (. (verifier-scenario) :indent-lines))))
  (testing "indent-only rejects changed non-whitespace characters"
    (is (not (. (verifier-scenario) :indent-char))))
  (testing "binding whitespace accepts alignment between a name and value"
    (is (. (verifier-scenario) :binding-aligned)))
  (testing "binding whitespace rejects joined name and value tokens"
    (is (not (. (verifier-scenario) :binding-joined))))
  (testing "binding whitespace rejects changed spaces inside string literals"
    (is (not (. (verifier-scenario) :binding-string))))
  (testing "ast-equal accepts differently indented equivalent forms"
    (is (. (verifier-scenario) :ast-same)))
  (testing "ast-equal rejects changed symbols"
    (is (not (. (verifier-scenario) :ast-symbol))))
  (testing "ast-equal rejects changed comment text"
    (is (not (. (verifier-scenario) :ast-comment))))
  (testing "ast-equal compares every top-level form"
    (is (not (. (verifier-scenario) :ast-second)))))

(deftest format-string
  (testing "formats a simple conditional golden"
    (is (= "(when x\n  y)"
           (. (format-summary "(when x\ny)" {:indents {}}) :value))))
  (testing "returns a structured error for unbalanced input"
    (let [result (format-summary "(missing" {:indents {}})]
      (is (= {:value? false :has-message true}
             {:value?      (. result :value?)
              :has-message (. result :has-message)}))))
  (testing "returns a structured error for an invalid config"
    (let [result (format-summary "(x\ny)" {:indents {"x" [[:inner 1]]}})]
      (is (= {:value? false :has-message true}
             {:value?      (. result :value?)
              :has-message (. result :has-message)}))))
  (testing "rejects a string align-bindings option"
    (let [result (format-summary "(x\ny)" {:align-bindings "yes"})]
      (is (= {:value? false :has-message true}
             {:value?      (. result :value?)
              :has-message (. result :has-message)}))))
  (testing "rejects a numeric align-bindings option"
    (let [result (format-summary "(x\ny)" {:align-bindings 1})]
      (is (= {:value? false :has-message true}
             {:value?      (. result :value?)
              :has-message (. result :has-message)}))))
  (testing "rejects a table align-bindings option"
    (let [result (format-summary "(x\ny)" {:align-bindings {}})]
      (is (= {:value? false :has-message true}
             {:value?      (. result :value?)
              :has-message (. result :has-message)}))))
  (testing "align-bindings formats a multiline map with trailing value whitespace"
    (is (= {:value?
            true
            :value
            "(let [result {:code  0 \n              :lines []}]\n  result)\n"}
           (let [result (alignment-safety-scenario)]
             {:value? (. result :value?)
              :value  (. result :value)})))))

(deftest repo-properties
  (testing "format-string succeeds for every project Fennel source"
    (is (= [] (. (repo-scenario) :format))))
  (testing "format-string is idempotent for every project Fennel source"
    (is (= [] (. (repo-scenario) :idempotence))))
  (testing "formatted output passes indent-only verification for every project source"
    (is (= [] (. (repo-scenario) :indent))))
  (testing "formatted output preserves ASTs for every project source"
    (is (= [] (. (repo-scenario) :ast))))
  (testing "hand-styled files remain fixed points"
    (is (= [] (. (repo-scenario) :fixed-point)))))

(deftest configuration-formatting
  (testing "indent width four changes block indentation"
    (is (= "(let [x 1]\n    x)"
           (. (format-summary "(let [x 1]\nx)" {:indent-width 4}) :value))))
  (testing "indent width four changes inner indentation"
    (is (= "(fn [x]\n    x)"
           (. (format-summary "(fn [x]\nx)" {:indent-width 4}) :value))))
  (testing "the default indent width preserves today's output"
    (is (= "(let [x 1]\n  x)"
           (. (format-summary "(let [x 1]\nx)" {}) :value))))
  (testing "builtins false disables the let block rule"
    (is (= "(let [x 1]\n     x)"
           (. (format-summary "(let [x 1]\nx)" {:builtins false}) :value))))
  (testing "a custom builtins table replaces the built-in table"
    (is (= "(let [x 1]\n     x)"
           (. (format-summary "(let [x 1]\nx)"
                              {:builtins {"when" [[:block 1]]}})
              :value))))
  (testing "a custom builtins table supplies its replacement rule"
    (is (= "(when x\n  y)"
           (. (format-summary "(when x\ny)"
                              {:builtins {"when" [[:block 1]]}})
              :value))))
  (testing "prefix fallbacks false disables the def fallback"
    (is (= "(defn x\n      y)"
           (. (format-summary "(defn x\ny)" {:prefix-fallbacks false}) :value))))
  (testing "repo-style formatting indents defn args and body at two spaces"
    (is (= "(defn- git-root\n  [start]\n  (foo start))"
           (. (format-summary "(defn- git-root\n[start]\n(foo start))"
                              {:indents        {"if" [[:block 1]]}
                               :align-bindings
                               true})
              :value))))
  (testing "a custom prefix fallback table replaces the defaults"
    (is (= "(defn x\n      y)"
           (. (format-summary "(defn x\ny)"
                              {:prefix-fallbacks {"with-" [[:block 1]]}})
              :value))))
  (testing "a custom prefix fallback table supplies its replacement rule"
    (is (= "(foo x\n  y)"
           (. (format-summary "(foo x\ny)"
                              {:prefix-fallbacks {"foo-" [[:block 1]]}})
              :value))))
  (testing "a long one-line form stays exactly one line"
    (is (= "(when x (print :a) (print :b) (let [y 1] y))"
           (. (format-summary "(when x (print :a) (print :b) (let [y 1] y))" {}) :value))))
  (testing "a nested one-line fn stays exactly one line"
    (is (= "(fn [x] (fn [y] (+ x y)))"
           (. (format-summary "(fn [x] (fn [y] (+ x y)))" {}) :value))))
  (testing "a multi-line form keeps its line count"
    (is (= 3
           (let [value     (. (format-summary "(when x\n(print :a)\n(print :b))" {}) :value)
                 (_ count) (string.gsub value "\n" "")]
             (+ count 1))))))

(defn- format-summary-with-parser
  [source config]
  (let [format (load-format)
        parser (load-parser)]
    (if (or (. format :error) (. parser :error))
      {:value? false :value nil}
      (let [(ok value err) (pcall (fn [] (format.format-string source {:config config :parser parser})))]
        {:value?      (and ok (not= nil value))
         :has-message (and ok (= nil value) err (= :string (type (. err :message))))
         :value
         value}))))

(defn- symbol-key-safety-scenario
  []
  (let [parser (load-parser)
        format (load-format)]
    {:same            (if (or (. parser :error) (. format :error))
                        false
                        (format.ast-equal? parser "{a 1}" "{a 1}"))
     :different-value (if (or (. parser :error) (. format :error))
                        false
                        (format.ast-equal? parser "{a 1}" "{a 2}"))
     :different-key   (if (or (. parser :error) (. format :error))
                        false
                        (format.ast-equal? parser "{a 1}" "{b 1}"))}))

(deftest symbol-keyed-tables
  (testing "format-string preserves an unchanged symbol-keyed table"
    (let [result (format-summary-with-parser "{target true}" {})]
      (is (= {:value? true :value "{target true}"}
             {:value? (. result :value?) :value (. result :value)}))))
  (testing "format-string reindents a let containing a symbol-keyed table"
    (let [result (format-summary-with-parser "(let [visited {target true}]\nvisited)" {})]
      (is (= {:value? true :value "(let [visited {target true}]\n  visited)"}
             {:value? (. result :value?) :value (. result :value)}))))
  (testing "ast-equal rejects a changed value with symbol keys"
    (is (not (. (symbol-key-safety-scenario) :different-value))))
  (testing "ast-equal rejects a changed key with symbol keys"
    (is (not (. (symbol-key-safety-scenario) :different-key)))))

(defn- alignment-regression-scenario
  []
  (let [simple-source
        "(defn f []\n(foo\nbar))"
        if-source
        "(if a\n    b\n    c)"
        mixed-source
        "(let [long-name 1\n x 2]\n(foo\nbar))"
        value-source
        "(let [a (foo\nbar)\n      long-name 2]\n baz)"
        if-config  {:indents {"if" [[:block 1]]}}
        simple-off (. (format-summary simple-source {}) :value)
        simple-on  (. (format-summary simple-source {:align-bindings true}) :value)
        if-off     (. (format-summary if-source if-config) :value)
        if-on      (. (format-summary if-source
                                      {:indents        {"if" [[:block 1]]}
                                       :align-bindings
                                       true})
                      :value)
        mixed-off  (. (format-summary mixed-source {}) :value)
        mixed-on   (. (format-summary mixed-source {:align-bindings true}) :value)
        value-off  (. (format-summary value-source {}) :value)
        value-on   (. (format-summary value-source {:align-bindings true}) :value)]
    {:simple-off
     simple-off
     :simple-on
     simple-on
     :if-off
     if-off
     :if-on
     if-on
     :mixed-off
     mixed-off
     :mixed-on
     mixed-on
     :value-off
     value-off
     :value-on
     value-on
     :mixed-idempotent (. (format-summary mixed-on {:align-bindings true}) :value)
     :value-idempotent (. (format-summary value-on {:align-bindings true}) :value)}))

(deftest alignment-regressions
  (testing "alignment preserves normal reindentation without binding vectors"
    (let [result (alignment-regression-scenario)]
      (is (= (. result :simple-off) (. result :simple-on)))))
  (testing "alignment preserves custom if indentation"
    (let [result (alignment-regression-scenario)]
      (is (= "(if a\n  b\n  c)" (. result :if-on)))))
  (testing "alignment applies binding alignment and unrelated reindentation"
    (let [result (alignment-regression-scenario)]
      (is (= "(let [long-name 1\n      x         2]\n  (foo\n   bar))"
             (. result :mixed-on)))))
  (testing "alignment shifts multiline value continuations with the moved value"
    (let [result (alignment-regression-scenario)]
      (is (= "(let [a         (foo\n                 bar)\n      long-name 2]\n  baz)"
             (. result :value-on)))))
  (testing "alignment output is idempotent for mixed reindentation"
    (let [result (alignment-regression-scenario)]
      (is (= (. result :mixed-on) (. result :mixed-idempotent)))))
  (testing "alignment output is idempotent for multiline moved values"
    (let [result (alignment-regression-scenario)]
      (is (= (. result :value-on) (. result :value-idempotent))))))

(defn- stale-leading-whitespace-scenario
  []
  (let [if-source
        "(defn f []\n  (if condition\n        (foo)\n        (bar)))"
        top-if-source
        "(if condition\n      (foo)\n      (bar))"
        when-source
        "(when condition\n          (foo))"
        mixed-source
        "(let [a 1\n      long-name 2]\n  (if condition\n        (foo)\n        (bar)))"
        no-pairs-source
        "(when condition\n          (foo)\n          (bar))"
        if-config    {:indents {"if" [[:block 1]]}}
        if-on        (. (format-summary if-source
                                        {:indents        {"if" [[:block 1]]}
                                         :align-bindings
                                         true})
                        :value)
        top-if-on    (. (format-summary top-if-source
                                        {:indents        {"if" [[:block 1]]}
                                         :align-bindings
                                         true})
                        :value)
        when-on      (. (format-summary when-source {:align-bindings true}) :value)
        mixed-config {:indents        {"if" [[:block 1]]}
                      :align-bindings
                      true}
        mixed-on     (. (format-summary mixed-source mixed-config) :value)
        no-pairs-off (. (format-summary no-pairs-source {}) :value)
        no-pairs-on  (. (format-summary no-pairs-source {:align-bindings true}) :value)]
    {:if-on
     if-on
     :top-if-on
     top-if-on
     :when-on
     when-on
     :mixed-on
     mixed-on
     :mixed-idempotent (. (format-summary mixed-on mixed-config) :value)
     :no-pairs-off
     no-pairs-off
     :no-pairs-on
     no-pairs-on}))

(defn- nested-if-source
  [branch-spaces]
  (.. "(defn outer []\n  (let [x 1]\n    (if condition\n"
      (string.rep " " branch-spaces)
      "(foo)\n"
      (string.rep " " branch-spaces)
      "(bar))))"))

(defn- nested-if-expected
  []
  "(defn outer []\n  (let [x 1]\n    (if condition\n      (foo)\n      (bar))))")

(defn- multiline-binding-source
  [name]
  (.. "(let [a (foo\n         bar)\n      " name " 2]\n  a)"))

(deftest stale-leading-whitespace
  (testing "alignment does not restore stale if branch indentation"
    (is (= "(defn f []\n  (if condition\n    (foo)\n    (bar)))"
           (. (stale-leading-whitespace-scenario) :if-on))))
  (testing "alignment reindents top-level if branches"
    (is (= "(if condition\n  (foo)\n  (bar))"
           (. (stale-leading-whitespace-scenario) :top-if-on))))
  (testing "alignment reindents over-indented when bodies"
    (is (= "(when condition\n  (foo))"
           (. (stale-leading-whitespace-scenario) :when-on))))
  (testing "alignment preserves binding alignment while reindenting if branches"
    (let [result (stale-leading-whitespace-scenario)]
      (is (= "(let [a         1\n      long-name 2]\n  (if condition\n    (foo)\n    (bar)))"
             (. result :mixed-on)))))
  (testing "alignment remains idempotent after correcting stale indentation"
    (let [result (stale-leading-whitespace-scenario)]
      (is (= (. result :mixed-on) (. result :mixed-idempotent)))))
  (testing "alignment matches normal formatting when no pairs are alignable"
    (let [result (stale-leading-whitespace-scenario)]
      (is (= (. result :no-pairs-off) (. result :no-pairs-on))))))

(defn- leading-space-count
  [line]
  (length (or (string.match line "^( *)") "")))

(defn- balanced-line?
  [line]
  (let [(open-text opens)   (string.gsub line "[(]" "")
        (close-text closes) (string.gsub line "[)]" "")]
    (and open-text
         close-text
         (= opens closes))))

(defn- multiline-if-branch-violations
  [source]
  (let [lines      (vim.split source "\n" true)
        violations []]
    (each [index line (ipairs lines)]
      (let [(leading rest) (string.match line "^( *)%(if%s+(.+)$")]
        (when (and leading
                   rest
                   (balanced-line? line)
                   (< (+ index 2) (+ (length lines) 1)))
          (let [expected (+ (length leading) 2)
                first    (. lines (+ index 1))
                second   (. lines (+ index 2))]
            (when (or (not= expected (leading-space-count first))
                      (not= expected (leading-space-count second)))
              (table.insert violations
                            {:line
                             index
                             :expected
                             expected
                             :first  (leading-space-count first)
                             :second (leading-space-count second)}))))))
    violations))

(deftest stale-leading-whitespace-remaining
  (testing "alignment uses normal indentation for one extra branch space"
    (is (= (nested-if-expected)
           (. (format-summary (nested-if-source 7)
                              {:indents        {"if" [[:block 1]]}
                               :align-bindings
                               true})
              :value))))
  (testing "alignment uses normal indentation for two extra branch spaces"
    (is (= (nested-if-expected)
           (. (format-summary (nested-if-source 8)
                              {:indents        {"if" [[:block 1]]}
                               :align-bindings
                               true})
              :value))))
  (testing "alignment uses normal indentation for three extra branch spaces"
    (is (= (nested-if-expected)
           (. (format-summary (nested-if-source 9)
                              {:indents        {"if" [[:block 1]]}
                               :align-bindings
                               true})
              :value))))
  (testing "alignment uses normal indentation for four extra branch spaces"
    (is (= (nested-if-expected)
           (. (format-summary (nested-if-source 10)
                              {:indents        {"if" [[:block 1]]}
                               :align-bindings
                               true})
              :value))))
  (testing "alignment uses normal indentation for five extra branch spaces"
    (is (= (nested-if-expected)
           (. (format-summary (nested-if-source 11)
                              {:indents        {"if" [[:block 1]]}
                               :align-bindings
                               true})
              :value))))
  (testing "alignment uses normal indentation for one under-indented branch space"
    (is (= (nested-if-expected)
           (. (format-summary (nested-if-source 5)
                              {:indents        {"if" [[:block 1]]}
                               :align-bindings
                               true})
              :value))))
  (testing "alignment uses normal indentation for two under-indented branch spaces"
    (is (= (nested-if-expected)
           (. (format-summary (nested-if-source 4)
                              {:indents        {"if" [[:block 1]]}
                               :align-bindings
                               true})
              :value))))
  (testing "alignment uses normal indentation for three under-indented branch spaces"
    (is (= (nested-if-expected)
           (. (format-summary (nested-if-source 3)
                              {:indents        {"if" [[:block 1]]}
                               :align-bindings
                               true})
              :value))))
  (testing "alignment does not move an unmoved multiline value continuation"
    (is (= "(let [a (foo\n         bar)]\n  a)"
           (. (format-summary "(let [a (foo\n         bar)]\n  a)"
                              {:align-bindings true})
              :value))))
  (testing "alignment shifts a multiline continuation by one column"
    (is (= "(let [a  (foo\n          bar)\n      bb 2]\n  a)"
           (. (format-summary (multiline-binding-source "bb")
                              {:align-bindings true})
              :value))))
  (testing "alignment shifts a multiline continuation by two columns"
    (is (= "(let [a   (foo\n           bar)\n      bbb 2]\n  a)"
           (. (format-summary (multiline-binding-source "bbb")
                              {:align-bindings true})
              :value))))
  (testing "alignment shifts a multiline continuation by three columns"
    (is (= "(let [a    (foo\n            bar)\n      bbbb 2]\n  a)"
           (. (format-summary (multiline-binding-source "bbbb")
                              {:align-bindings true})
              :value))))
  (testing "repo if branches use the configured two-column indentation"
    (let [config     {:indents        {"deftest" [[:block 1]]
                                       "testing" [[:block 1]]
                                       "if"      [[:block 1]]}
                      :align-bindings
                      true}
          violations []]
      (each [_ path (ipairs ["fnl/eca/api.fnl" "fnl/fennel-extras/lint.fnl"])]
        (let [source (read-source path)
              result (if (. source :error)
                       source
                       (format-summary source config))]
          (if (or (. source :error) (not (. result :value?)))
            (table.insert violations path)
            (each [_ violation (ipairs (multiline-if-branch-violations (. result :value)))]
              (table.insert violations (.. path ":" (tostring (. violation :line))))))))
      (is (= [] violations)))))

(deftest align-bindings
  (testing "aligns let bindings to the longest single-line name"
    (is (= "(let [a         1\n      long-name 2]\n  a)"
           (. (format-summary "(let [a 1\n      long-name 2]\n  a)" {:align-bindings true}) :value))))
  (testing "aligns a reader-prefix value"
    (is (= "(let [a         #(+ $1 1)\n      long-name 2]\n  a)"
           (. (format-summary "(let [a #(+ $1 1)\n      long-name 2]\n  a)" {:align-bindings true}) :value))))
  (testing "aligns a quoted value"
    (is (= "(let [a         '(foo bar)\n      long-name 2]\n  a)"
           (. (format-summary "(let [a '(foo bar)\n      long-name 2]\n  a)" {:align-bindings true}) :value))))
  (testing "aligns gensym names by their full text"
    (is (= "(let [start#     1\n      long-name# 2]\n  start#)"
           (. (format-summary "(let [start# 1\n      long-name# 2]\n  start#)" {:align-bindings true}) :value))))
  (testing "aligns map entries to the longest key"
    (is (= "{:a    1\n :long 2}"
           (. (format-summary "{:a 1\n :long 2}" {:align-bindings true}) :value))))
  (testing "aligns only single-pair lines in a mixed binding line"
    (is (= "(let [a 1 b 2\n      long-name 3\n      c         4]\n  a)"
           (. (format-summary "(let [a 1 b 2\n      long-name 3\n      c 4]\n  a)" {:align-bindings true}) :value))))
  (testing "aligns when-let bindings"
    (is (= "(when-let [a         1\n           long-name 2]\n  a)"
           (. (format-summary "(when-let [a 1\n          long-name 2]\n  a)" {:align-bindings true}) :value))))
  (testing "aligns if-let bindings"
    (is (= "(if-let [a         1\n         long-name 2]\n  a\n  b)"
           (. (format-summary "(if-let [a 1\n        long-name 2]\n  a\n  b)" {:align-bindings true}) :value))))
  (testing "aligns with-open bindings"
    (is (= "(with-open [a         1\n            long-name 2]\n  a)"
           (. (format-summary "(with-open [a 1\n          long-name 2]\n  a)" {:align-bindings true}) :value))))
  (testing "does not align loop bindings"
    (is (= "(each [k v\n       long-name 3]\n  k)"
           (. (format-summary "(each [k v\n      long-name 3]\n  k)" {:align-bindings true}) :value))))
  (testing "does not align sequential tables"
    (is (= "[1\n 2]"
           (. (format-summary "[1\n 2]" {:align-bindings true}) :value))))
  (testing "normalizes extra spaces to the aligned column"
    (is (= "(let [a  1\n      bb 1]\n  a)"
           (. (format-summary "(let [a     1\n      bb 1]\n  a)" {:align-bindings true}) :value))))
  (testing "aligns a multiline value and reindents its continuation"
    (is (= "(let [a         (foo\n                 bar)\n      long-name 2] a)"
           (. (format-summary "(let [a (foo\n         bar)\n      long-name 2] a)" {:align-bindings true}) :value))))
  (testing "formatting aligned mixed bindings is idempotent"
    (let [source
          "(let [a 1 b 2\n      long-name 3\n      c 4]\n  a)"
          once  (. (format-summary source {:align-bindings true}) :value)
          twice (. (format-summary once {:align-bindings true}) :value)]
      (is (and once twice (= once twice)))))
  (testing "aligns a destructuring map name by its full source width"
    (is (= "(let [{: x}     (f)\n      long-name 2]\n  x)"
           (. (format-summary "(let [{: x} (f)\n      long-name 2]\n  x)"
                              {:align-bindings true})
              :value))))
  (testing "aligns a destructuring vector name by its full source width"
    (is (= "(let [[a b]     (g)\n      long-name 2]\n  a)"
           (. (format-summary "(let [[a b] (g)\n      long-name 2]\n  a)"
                              {:align-bindings true})
              :value))))
  (testing "aligns an expression map key by its full source width"
    (is (= "{(foo a)  1\n :long-key 2}"
           (. (format-summary "{(foo a) 1\n :long-key 2}" {:align-bindings true}) :value))))
  (testing "ignores a multiline composite binding name while aligning single-line bindings"
    (is (= "(let [{: x\n       : y} (f)\n      a  1\n      bb 2] x)"
           (. (format-summary "(let [{: x\n       : y} (f)\n      a 1\n      bb 2] x)"
                              {:align-bindings true})
              :value))))
  (testing "align-bindings absent preserves the existing output byte-for-byte"
    (let [source
          "(let [a 1\n      long-name 2]\n  a)"
          result (format-summary source {})]
      (is (= source (. result :value))))))

(deftest align-binding-clauses
  (testing "aligns case clauses to the longest single-line pattern"
    (is (= "(case x\n  \"--all\"     (a)\n  \"--changed\" (b)\n  _           (c))"
           (. (format-summary "(case x\n  \"--all\" (a)\n  \"--changed\" (b)\n  _ (c))"
                              {:align-bindings true})
              :value))))
  (testing "aligns match clauses to the longest single-line pattern"
    (is (= "(match value\n  :short (a)\n  :long  (b))"
           (. (format-summary "(match value\n  :short (a)\n  :long (b))"
                              {:align-bindings true})
              :value))))
  (testing "aligns case-try clauses but leaves catch unchanged"
    (is (= "(case-try (f)\n  x      (g x)\n  long-y (h y)\n  (catch _ nil))"
           (. (format-summary "(case-try (f)\n  x (g x)\n  long-y (h y)\n  (catch _ nil))"
                              {:align-bindings true})
              :value))))
  (testing "aligns match-try clauses but leaves catch unchanged"
    (is (= "(match-try (f)\n  x      (g x)\n  long-y (h y)\n  (catch _ nil))"
           (. (format-summary "(match-try (f)\n  x (g x)\n  long-y (h y)\n  (catch _ nil))"
                              {:align-bindings true})
              :value))))
  (testing "aligns multi-clause if test and result children"
    (is (= "(if\n  (> i n)    false\n  (= path x) true\n  (rec))"
           (. (format-summary "(if\n  (> i n) false\n  (= path x) true\n  (rec))"
                              {:indents        {"if" [[:block 1]]}
                               :align-bindings
                               true})
              :value))))
  (testing "does not align a one-pair if with an else branch"
    (is (= "(if a\n  b\n  c)"
           (. (format-summary "(if a\n  b\n  c)"
                              {:indents        {"if" [[:block 1]]}
                               :align-bindings
                               true})
              :value))))
  (testing "does not align a clause pair sharing the case head line"
    (is (= "(case x 1 :a\n  22 :b)"
           (. (format-summary "(case x 1 :a\n  22 :b)"
                              {:align-bindings true})
              :value))))
  (testing "does not align and clauses"
    (is (= "(and\n a true\n long-name false)"
           (. (format-summary "(and\n  a true\n  long-name false)"
                              {:align-bindings true})
              :value))))
  (testing "does not align clause lines with comments or multiline patterns"
    (is (= "(case x\n  (foo\n   a) :one\n  long-pattern :two ;; keep\n  short :three)"
           (. (format-summary "(case x\n  (foo\n   a) :one\n  long-pattern :two ;; keep\n  short :three)"
                              {:align-bindings true})
              :value))))
  (testing "align-bindings false preserves the case sample byte-for-byte"
    (let [source "(case x\n  \"--all\" (a)\n  \"--changed\" (b)\n  _ (c))"]
      (is (= source (. (format-summary source {}) :value)))))
  (testing "clause alignment is idempotent on a mixed sample"
    (let [source
          "(case x\n  \"--all\" (a)\n  \"--changed\" (b)\n  _ (c))\n(if\n  (> i n) false\n  (= path x) true\n  (rec))"
          config {:indents        {"if" [[:block 1]]}
                  :align-bindings
                  true}
          once   (. (format-summary source config) :value)
          twice  (. (format-summary once config) :value)]
      (is (= once twice)))))

(deftest block-one-indentation
  (testing "configured block-one if indents every own-line argument by two spaces"
    (is (= "(if\n  a b\n  c d\n  e)"
           (. (format-summary "(if\n a b\n  c d\n  e)"
                              {:indents {"if" [[:block 1]]}})
              :value))))
  (testing "configured block-one if indents a simple form by two spaces"
    (is (= "(if\n  a\n  b)"
           (. (format-summary "(if\n   a\n   b)"
                              {:indents {"if" [[:block 1]]}})
              :value))))
  (testing "built-in when block indentation uses two spaces for every argument"
    (is (= "(when\n  a\n  b)"
           (. (format-summary "(when\n   a\n   b)" {}) :value)))))

(defn- comment-format-scenario
  [source align-bindings]
  (format-summary source
                  {:indents        {"deftest" [[:block 1]]
                                    "testing" [[:block 1]]
                                    "if"      [[:block 1]]}
                   :align-bindings align-bindings}))

(deftest comment-indentation
  (testing "align-bindings false indents a defn header comment like the following code"
    (is (= "(defn- rename-files\n  ;; comment\n  [temps]\n  (rename-loop temps 1 nil))"
           (. (comment-format-scenario "(defn- rename-files\n       ;; comment\n[temps]\n(rename-loop temps 1 nil))"
                                       false)
              :value))))
  (testing "align-bindings true indents a defn header comment like the following code"
    (is (= "(defn- rename-files\n  ;; comment\n  [temps]\n  (rename-loop temps 1 nil))"
           (. (comment-format-scenario "(defn- rename-files\n       ;; comment\n[temps]\n(rename-loop temps 1 nil))"
                                       true)
              :value))))
  (testing "align-bindings false indents a comment between defn body expressions"
    (is (= "(defn foo\n  [x]\n  ;; between\n  (bar)\n  (baz))"
           (. (comment-format-scenario "(defn foo\n[x]\n      ;; between\n(bar)\n(baz))"
                                       false)
              :value))))
  (testing "align-bindings true indents a comment between defn body expressions"
    (is (= "(defn foo\n  [x]\n  ;; between\n  (bar)\n  (baz))"
           (. (comment-format-scenario "(defn foo\n[x]\n      ;; between\n(bar)\n(baz))"
                                       true)
              :value))))
  (testing "align-bindings false indents a let comment like the following body"
    (is (= "(let [x 1]\n  ;; in let\n  x)"
           (. (comment-format-scenario "(let [x 1]\n     ;; in let\nx)"
                                       false)
              :value))))
  (testing "align-bindings true indents a let comment like the following body"
    (is (= "(let [x 1]\n  ;; in let\n  x)"
           (. (comment-format-scenario "(let [x 1]\n     ;; in let\nx)"
                                       true)
              :value))))
  (testing "align-bindings false indents a map comment like the following key"
    (is (= "(let [m {:a 1\n         ;; in map\n         :b 2}]\n  m)"
           (. (comment-format-scenario "(let [m {:a 1\n;; in map\n:b 2}]\nm)"
                                       false)
              :value))))
  (testing "align-bindings true indents a map comment like the following key"
    (is (= "(let [m {:a 1\n         ;; in map\n         :b 2}]\n  m)"
           (. (comment-format-scenario "(let [m {:a 1\n;; in map\n:b 2}]\nm)"
                                       true)
              :value))))
  (testing "a full-line comment block remains unchanged at top level"
    (is (= ";; first\n;; second\n(let [x 1]\n  x)"
           (. (comment-format-scenario ";; first\n;; second\n(let [x 1]\nx)"
                                       true)
              :value))))
  (testing "an end-of-line comment stays attached while following code is indented"
    (is (= "(foo ;; eol\n  bar)"
           (. (comment-format-scenario "(foo ;; eol\nbar)"
                                       true)
              :value)))))
