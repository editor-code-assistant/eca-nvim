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
  (let [format (load-format)
        parser (load-parser)
        same-a "(when x\ny)"
        same-b "(when x\n  y)"
        symbol-a "(when x\ny)"
        symbol-b "(when z\ny)"
        comment-a ";; one\n(foo)"
        comment-b ";; two\n(foo)"
        second-a "(a)\n(b)"
        second-b "(a)\n(c)"]
    {:indent-same (if (. format :error)
                      false
                      (format.indent-only? same-a same-b))
     :indent-string (if (. format :error)
                        true
                        (format.indent-only? "(foo \"a\")" "(foo \"b\")"))
     :indent-trailing (if (. format :error)
                          true
                          (format.indent-only? "(foo)" "(foo) "))
     :indent-lines (if (. format :error)
                       true
                       (format.indent-only? "(foo)\n(bar)" "(foo)"))
     :indent-char (if (. format :error)
                      true
                      (format.indent-only? "(foo)" "(bar)"))
     :ast-same (if (or (. format :error) (. parser :error))
                   false
                   (format.ast-equal? parser same-a same-b))
     :ast-symbol (if (or (. format :error) (. parser :error))
                     true
                     (format.ast-equal? parser symbol-a symbol-b))
     :ast-comment (if (or (. format :error) (. parser :error))
                      true
                      (format.ast-equal? parser comment-a comment-b))
     :ast-second (if (or (. format :error) (. parser :error))
                     true
                     (format.ast-equal? parser second-a second-b))}))

(defn- format-summary [source config]
  (let [format (load-format)]
    (if (. format :error)
        format
        (let [(ok value err) (pcall (fn [] (format.format-string source {:config config})))]
          {:value? (and ok (not= nil value))
           :has-message (and ok (= nil value) err (= :string (type (. err :message))))
           :value value}))))

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
        {:error "read failed" :path path})))

(defn- repo-scenario []
  (let [format (load-format)
        parser (load-parser)
        config {:indents {"deftest" [[:block 1]] "testing" [[:block 1]]}}
        format-failures (if (. format :error) ["module missing"] [])
        idempotence-failures (if (. format :error) ["module missing"] [])
        indent-failures (if (. format :error) ["module missing"] [])
        ast-failures (if (. format :error) ["module missing"] [])
        fixed-point-failures []]
    (each [_ path (ipairs (file-paths))]
      (let [source (read-source path)]
        (if (. source :error)
            (each [_ failures (ipairs [format-failures idempotence-failures indent-failures ast-failures])]
              (table.insert failures (.. "read failed: " path)))
            (let [(ok formatted err) (pcall (fn [] (format.format-string source {:config config :parser parser})))]
              (if (or (not ok) (= nil formatted) err)
                  (table.insert format-failures path)
                  (do
                    (if (or (not (pcall (fn [] (format.format-string formatted {:config config :parser parser}))))
                            (not= formatted (format.format-string formatted {:config config :parser parser})))
                        (table.insert idempotence-failures path))
                    (if (not (format.indent-only? source formatted))
                        (table.insert indent-failures path))
                    (if (not (format.ast-equal? parser source formatted))
                        (table.insert ast-failures path))))))))
    (each [_ path (ipairs ["fnl/eca/ui/widgets/footer-bar.fnl" "fnl/eca/ui/components/lualine.fnl"])]
      (let [source (read-source path)]
        (if (or (. source :error) (. format :error))
            (table.insert fixed-point-failures path)
            (let [(ok formatted) (pcall (fn [] (format.format-string source {:config config :parser parser})))]
              (if (or (not ok) (not= source formatted))
                  (table.insert fixed-point-failures path))))))
    {:format format-failures
     :idempotence idempotence-failures
     :indent indent-failures
     :ast ast-failures
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
             {:value? (. result :value?)
              :has-message (. result :has-message)}))))
  (testing "returns a structured error for an invalid config"
    (let [result (format-summary "(x\ny)" {:indents {"x" [[:inner 1]]}})]
      (is (= {:value? false :has-message true}
             {:value? (. result :value?)
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

(defn- format-summary-with-parser [source config]
  (let [format (load-format)
        parser (load-parser)]
    (if (or (. format :error) (. parser :error))
        {:value? false :value nil}
        (let [(ok value err) (pcall (fn [] (format.format-string source {:config config :parser parser})))]
          {:value? (and ok (not= nil value))
           :has-message (and ok (= nil value) err (= :string (type (. err :message))))
           :value value}))))

(defn- symbol-key-safety-scenario []
  (let [parser (load-parser)
        format (load-format)]
    {:same (if (or (. parser :error) (. format :error))
               false
               (format.ast-equal? parser "{a 1}" "{a 1}"))
     :different-value (if (or (. parser :error) (. format :error))
                          false
                          (format.ast-equal? parser "{a 1}" "{a 2}"))
     :different-key (if (or (. parser :error) (. format :error))
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
