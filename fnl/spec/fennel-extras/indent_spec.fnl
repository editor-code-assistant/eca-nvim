(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(defn- load-indent
  []
  (let [(ok result) (pcall require :fennel-extras.indent)]
    (if ok
      result
      {:error "module missing"})))

(local explicit-indent-config
       {:indent-width     2
        :parser           "eca.nfnl.fennel"
        :builtins         {"fn" [[:inner 0]] "lambda" [[:inner 0]] "macro" [[:inner 0]] "let" [[:block 1]] "when" [[:block 1]] "when-let" [[:block 1]] "if-let" [[:block 1]] "each" [[:block 1]] "for" [[:block 1]] "icollect" [[:block 1]] "collect" [[:block 1]] "accumulate" [[:block 1]] "case" [[:block 1]] "match" [[:block 1]] "case-try" [[:block 1]] "match-try" [[:block 1]] "while" [[:block 1]] "with-open" [[:block 1]] "do" [[:block 0]]}
        :prefix-fallbacks {"def" [[:inner 0]] "with-" [[:block 1]]}
        :alignment        {:bindings         false
                           :maps             false
                           :clauses          false
                           :split-bindings   false
                           :collapse-padding false
                           :binding-forms    ["let" "when-let" "if-let" "with-open"]
                           :clause-forms     ["case" "match" "case-try" "match-try" "if"]}})

(defn- reindent-call-body
  [indent source]
  (indent.reindent source explicit-indent-config))

(defn- reindent-call
  [indent source]
  (let [(ok result err) (pcall reindent-call-body indent source)]
    {:ok ok :value result :error err}))

(defn- reindent-result
  [result]
  (if (. result :ok)
    {:value (. result :value) :error (. result :error)}
    {:call-error true :error (. result :error)}))

(defn- reindent-scenario
  [source]
  (let [indent (load-indent)]
    (if (. indent :error)
      indent
      (reindent-result (reindent-call indent source)))))

(defn- output-for
  [source]
  (let [result (reindent-scenario source)]
    (if (. result :error)
      result
      (. result :value))))

(defn- newline-count
  [source]
  (select 2 (string.gsub source "\\n" "")))

(defn- idempotent?
  [source]
  (let [once (output-for source)]
    (if (not= :string (type once))
      false
      (= once (output-for once)))))

(defn- error-summary-result
  [result]
  {:value?         (and (. result :ok) (not= nil (. result :value)))
   :has-message    (and (. result :ok)
                        (= nil (. result :value))
                        (not= nil (. result :error))
                        (= :string (type (. (. result :error) :message))))
   :returned-error (and (. result :ok)
                        (. result :value)
                        (= nil (. result :value))
                        (. result :error))})

(defn- error-summary
  [source]
  (let [indent (load-indent)]
    (if (. indent :error)
      indent
      (error-summary-result (reindent-call indent source)))))

(defn- alignment-error-call-body
  [indent alignment]
  (indent.reindent "(x\ny)"
                   (vim.tbl_deep_extend "force" explicit-indent-config {:alignment alignment})))

(defn- alignment-error-call
  [indent alignment]
  (let [(ok value err) (pcall alignment-error-call-body indent alignment)]
    {:ok ok :value value :error err}))

(defn- alignment-error-result
  [result]
  (let [ok    (. result :ok)
        value (. result :value)
        err   (. result :error)]
    {:ok?         ok
     :result-nil? (= nil value)
     :has-message (and ok (= nil value) err (= :table (type err)) (= :string (type (. err :message))))
     :message     (and ok (= nil value) err (. err :message))}))

(defn- alignment-error-summary
  [alignment]
  (let [indent (load-indent)]
    (if (. indent :error)
      indent
      (alignment-error-result (alignment-error-call indent alignment)))))

(deftest alignment-goldens
  (testing "aligns a call continuation to the first argument on the head line"
    (is (= "(foo a\n     b)"
           (output-for "(foo a\n b)"))))
  (testing "aligns a head-only call continuation to the head symbol"
    (is (= "(foo\n b)"
           (output-for "(foo\nb)"))))
  (testing "aligns a comment and closer to their opener"
    (is (= "(x\n ;; c\n)"
           (output-for "(x\n  ;; c\n)"))))
  (testing "aligns a no-final-newline continuation"
    (is (= "(a\n b)"
           (output-for "(a\nb)"))))
  (testing "preserves a one-character final line without a final newline"
    (is (= "a\nb"
           (output-for "a\nb"))))
  (testing "aligns nested call continuations from each call's own head"
    (is (= "(foo\n (bar x\n       y))"
           (output-for "(foo\n (bar x\n y))"))))
  (testing "aligns sequences to their first element"
    (is (= "[a\n b]"
           (output-for "[a\nb]"))))
  (testing "aligns tables to their first element"
    (is (= "{:a\n b}"
           (output-for "{:a\nb}"))))
  (testing "aligns a non-symbol head to its first element"
    (is (= "((f) x\n y)"
           (output-for "((f) x\n  y)"))))
  (testing "aligns a closer on its own line to its matching opener"
    (is (= "(foo a\n     b\n)"
           (output-for "(foo a\n b\n  )"))))
  (testing "indents a comment line like code at that position"
    (is (= "(foo\n ;; comment\n bar)"
           (output-for "(foo\n;; comment\nbar)"))))
  (testing "starts each top-level form at column zero"
    (is (= "(foo)\n(bar)"
           (output-for "(foo)\n  (bar)")))))

(deftest preservation
  (testing "preserves newline counts for final-line regression inputs"
    (is (and (= (newline-count "(x\n  ;; c\n)")
                (newline-count (output-for "(x\n  ;; c\n)")))
             (= (newline-count "(a\nb)")
                (newline-count (output-for "(a\nb)")))
             (= (newline-count "a\nb")
                (newline-count (output-for "a\nb"))))))
  (testing "keeps leading spaces inside multi-line strings unchanged"
    (is (= "(foo \"one\n  two\"\n     bar)"
           (output-for "(foo \"one\n  two\"\nbar)"))))
  (testing "turns whitespace-only lines into empty lines"
    (is (= "(foo\n\n bar)"
           (output-for "(foo\n   \nbar)"))))
  (testing "keeps trailing spaces after code"
    (is (= "(foo a\n     b   )"
           (output-for "(foo a\n b   )"))))
  (testing "counts Unicode codepoints for continuation columns"
    (is (= "(λ a\n   b)"
           (output-for "(λ a\nb)")))))

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
  (let [file   (assert (io.open path :r))
        source (file:read "*a")]
    (file:close)
    source))

(defn- reindent-config
  [config]
  (if config
    (vim.tbl_deep_extend "force" explicit-indent-config config)
    explicit-indent-config))

(defn- reindent-direct
  [source config]
  (let [indent (load-indent)
        config (reindent-config config)]
    (indent.reindent source config)))

(defn- repo-idempotence-failures
  []
  (let [config   {:indents {"deftest" [[:block 1]] "testing" [[:block 1]]}}
        failures []]
    (each [_ path (ipairs (file-paths))]
      (let [source (read-source path)
            once   (reindent-direct source config)]
        (if (= nil once)
          (table.insert failures (.. "error: " path))
          (let [twice (reindent-direct once config)]
            (when (not= once twice)
              (table.insert failures path))))))
    failures))

(deftest idempotence-and-errors
  (testing "alignment golden is idempotent"
    (is (idempotent? "(foo a\n b)")))
  (testing "preservation golden is idempotent"
    (is (idempotent? "(foo \"one\n  two\"\nbar)")))
  (testing "nested golden is idempotent"
    (is (idempotent? "(foo\n (bar x\n y))")))
  (testing "one direct reindent pass is idempotent for every project source"
    (is (= [] (repo-idempotence-failures))))
  (testing "unbalanced input returns a structured reader error"
    (is (= {:value? false :has-message true}
           (let [result (error-summary "(missing")]
             {:value?      (. result :value?)
              :has-message (. result :has-message)}))))
  (testing "a boolean alignment value returns the documented validation error"
    (is (= {:ok?         true
            :result-nil? true
            :has-message true
            :message     "alignment must be a table"}
           (alignment-error-summary true))))
  (testing "a string alignment value returns the documented validation error"
    (is (= {:ok?         true
            :result-nil? true
            :has-message true
            :message     "alignment must be a table"}
           (alignment-error-summary "yes")))))

(deftest hand-style-fixed-points
  (testing "footer-bar apply keeps the hand-written default if alignment"
    (is (= "(defn- apply\n  [items]\n  (if (lualine.plugin)\n      (lualine.setup items)\n      (set-native-statusline items)))"
           (reindent-direct "(defn- apply\n  [items]\n  (if (lualine.plugin)\n      (lualine.setup items)\n      (set-native-statusline items)))" nil))))
  (testing "lualine text keeps the hand-written let binding alignment"
    (is (= "(defn- text\n  [item]\n  (let [title (core.get item :title nil)\n        value (core.get item :value nil)\n        title-str (if title (core.str \"%#EcaHeaderKey#\" title \":\") \"\")\n        value-str (if value (core.str \"%#EcaHeaderValue#\" value) \"\")]\n    (core.str title-str value-str)))"
           (reindent-direct "(defn- text\n  [item]\n  (let [title (core.get item :title nil)\n        value (core.get item :value nil)\n        title-str (if title (core.str \"%#EcaHeaderKey#\" title \":\") \"\")\n        value-str (if value (core.str \"%#EcaHeaderValue#\" value) \"\")]\n    (core.str title-str value-str)))" nil)))))
