(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(defn- load-format []
  (let [(ok result) (pcall require :fennel-extras.format)]
    (if ok
        result
        {:error "module missing"})))

(defn- load-parser []
  (let [(ok result) (pcall require :eca.nfnl.fennel)]
    (if ok
        result
        {:error "parser module missing"})))

(defn- verifier-scenario []
  (let [format    (load-format)
        parser    (load-parser)
        same-a    "(when x\ny)"
        same-b    "(when x\n  y)"
        symbol-a  "(when x\ny)"
        symbol-b  "(when z\ny)"
        comment-a ";; one\n(foo)"
        comment-b ";; two\n(foo)"
        second-a  "(a)\n(b)"
        second-b  "(a)\n(c)"]
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

(defn- format-summary [source config]
  (let [format (load-format)]
    (if (. format :error)
        format
        (let [(ok value err) (pcall (fn [] (format.format-string source {:config config})))]
          {:value?      (and ok (not= nil value))
           :has-message (and ok (= nil value) err (= :string (type (. err :message))))
           :value       value}))))

(defn- file-paths []
  (let [paths      []
        fnl-files  (vim.fn.globpath "fnl" "**/*.fnl" false true)
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
        (let [_ (if (or (not (pcall (fn [] (format.format-string formatted {:config config :parser parser}))))
                        (not= formatted (format.format-string formatted {:config config :parser parser})))
                    (table.insert idempotence-failures path))
              _ (if (not (format.indent-only? source formatted))
                    (table.insert indent-failures path))
              _ (if (not (format.ast-equal? parser source formatted))
                    (table.insert ast-failures path))]
          nil))))

(defn- repo-scenario []
  (let [format               (load-format)
        parser               (load-parser)
        config               {:indents {"deftest" [[:block 1]] "testing" [[:block 1]]}}
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
              (if (or (not ok) (not= source formatted))
                  (table.insert fixed-point-failures path))))))
    {:format      format-failures
     :idempotence idempotence-failures
     :indent      indent-failures
     :ast         ast-failures
     :fixed-point fixed-point-failures}))

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
              :has-message (. result :has-message)})))))

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
                              {:builtins {"when" [[:block 1]]}}) :value))))
  (testing "a custom builtins table supplies its replacement rule"
    (is (= "(when x\n  y)"
           (. (format-summary "(when x\ny)"
                              {:builtins {"when" [[:block 1]]}}) :value))))
  (testing "prefix fallbacks false disables the def fallback"
    (is (= "(defn x\n      y)"
           (. (format-summary "(defn x\ny)" {:prefix-fallbacks false}) :value))))
  (testing "a custom prefix fallback table replaces the defaults"
    (is (= "(defn x\n      y)"
           (. (format-summary "(defn x\ny)"
                              {:prefix-fallbacks {"with-" [[:block 1]]}}) :value))))
  (testing "a custom prefix fallback table supplies its replacement rule"
    (is (= "(foo x\n  y)"
           (. (format-summary "(foo x\ny)"
                              {:prefix-fallbacks {"foo-" [[:block 1]]}}) :value))))
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

(defn- format-summary-with-parser [source config]
  (let [format (load-format)
        parser (load-parser)]
    (if (or (. format :error) (. parser :error))
        {:value? false :value nil}
        (let [(ok value err) (pcall (fn [] (format.format-string source {:config config :parser parser})))]
          {:value?      (and ok (not= nil value))
           :has-message (and ok (= nil value) err (= :string (type (. err :message))))
           :value       value}))))

(defn- symbol-key-safety-scenario []
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
    (is (= "(when-let [a         1\n          long-name 2]\n  a)"
           (. (format-summary "(when-let [a 1\n          long-name 2]\n  a)" {:align-bindings true}) :value))))
  (testing "aligns if-let bindings"
    (is (= "(if-let [a         1\n        long-name 2]\n  a\n  b)"
           (. (format-summary "(if-let [a 1\n        long-name 2]\n  a\n  b)" {:align-bindings true}) :value))))
  (testing "aligns with-open bindings"
    (is (= "(with-open [a         1\n          long-name 2]\n  a)"
           (. (format-summary "(with-open [a 1\n          long-name 2]\n  a)" {:align-bindings true}) :value))))
  (testing "does not align loop bindings"
    (is (= "(each [k v\n      long-name 3]\n  k)"
           (. (format-summary "(each [k v\n      long-name 3]\n  k)" {:align-bindings true}) :value))))
  (testing "does not align sequential tables"
    (is (= "[1\n 2]"
           (. (format-summary "[1\n 2]" {:align-bindings true}) :value))))
  (testing "normalizes extra spaces to the aligned column"
    (is (= "(let [a  1\n      bb 1]\n  a)"
           (. (format-summary "(let [a     1\n      bb 1]\n  a)" {:align-bindings true}) :value))))
  (testing "aligns a multiline value and reindents its continuation"
    (is (= "(let [a         (foo\n                    bar)\n      long-name 2] a)"
           (. (format-summary "(let [a (foo\n         bar)\n      long-name 2] a)" {:align-bindings true}) :value))))
  (testing "formatting aligned mixed bindings is idempotent"
    (let [source "(let [a 1 b 2\n      long-name 3\n      c 4]\n  a)"
          once   (. (format-summary source {:align-bindings true}) :value)
          twice  (. (format-summary once {:align-bindings true}) :value)]
      (is (and once twice (= once twice)))))
  (testing "aligns a destructuring map name by its full source width"
    (is (= "(let [{: x}     (f)\n      long-name 2]\n  x)"
           (. (format-summary "(let [{: x} (f)\n      long-name 2]\n  x)"
                              {:align-bindings true}) :value))))
  (testing "aligns a destructuring vector name by its full source width"
    (is (= "(let [[a b]     (g)\n      long-name 2]\n  a)"
           (. (format-summary "(let [[a b] (g)\n      long-name 2]\n  a)"
                              {:align-bindings true}) :value))))
  (testing "aligns an expression map key by its full source width"
    (is (= "{(foo a)  1\n :long-key 2}"
           (. (format-summary "{(foo a) 1\n :long-key 2}" {:align-bindings true}) :value))))
  (testing "ignores a multiline composite binding name while aligning single-line bindings"
    (is (= "(let [{: x\n       : y} (f)\n      a  1\n      bb 2] x)"
           (. (format-summary "(let [{: x\n       : y} (f)\n      a 1\n      bb 2] x)"
                              {:align-bindings true}) :value))))
  (testing "align-bindings absent preserves the existing output byte-for-byte"
    (let [source "(let [a 1\n      long-name 2]\n  a)"
          result (format-summary source {})]
      (is (= source (. result :value))))))
