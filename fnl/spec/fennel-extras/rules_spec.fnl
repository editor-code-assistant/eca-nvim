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
  [indent source config]
  (indent.reindent source config))

(defn- reindent-call
  [indent source config]
  (let [(ok result err) (pcall reindent-call-body indent source config)]
    {:ok ok :value result :error err}))

(defn- reindent-result
  [result]
  (if (. result :ok)
    {:value (. result :value) :error (. result :error)}
    {:call-error true :error (. result :error)}))

(defn- explicit-indent-config-for
  [config]
  (when config
    (vim.tbl_deep_extend "force" explicit-indent-config config)))

(defn- reindent-with-config
  [indent source config]
  (let [config (explicit-indent-config-for config)
        result (reindent-call indent source config)]
    (reindent-result result)))

(defn- reindent-scenario
  [source config]
  (let [indent (load-indent)]
    (if (. indent :error)
      indent
      (reindent-with-config indent source config))))

(defn- output-for
  [source config]
  (let [result (reindent-scenario source config)]
    (if (. result :error)
      result
      (. result :value))))

(defn- error-summary
  [source config]
  (let [indent (load-indent)]
    (if (. indent :error)
      indent
      (let [(ok value err) (pcall (fn [] (indent.reindent source config)))]
        {:value?         (and ok (not= nil value))
         :has-message    (and ok (= nil value) (not= nil err) (= :string (type (. err :message))))
         :returned-error (and ok value (= nil value) err)}))))

(deftest rule-semantics
  (testing "applies inner zero to every continuation line"
    (is (= "(defn f\n  [x]\n  x)"
           (output-for "(defn f\n[x]\nx)" {:indents {"defn" [[:inner 0]]}}))))
  (testing "applies block one to arguments after the first"
    (is (= "(testing \"d\"\n  body)"
           (output-for "(testing \"d\"\nbody)" {:indents {"testing" [[:block 1]]}}))))
  (testing "applies block rules through nested forms and keeps default inner alignment"
    (is (= "(deftest t\n  (testing \"d\"\n    (is (= 1\n           1))))"
           (output-for "(deftest t\n(testing \"d\"\n(is (= 1\n1))))"
                       {:indents {"deftest" [[:block 1]]
                                  "testing" [[:block 1]]}}))))
  (testing "uses body indentation when the first block argument starts on a new line"
    (is (= "(testing\n  \"d\"\n  body)"
           (output-for "(testing\n\"d\"\nbody)" {:indents {"testing" [[:block 1]]}}))))
  (testing "applies inner rules to only the selected argument"
    (is (= "(foo a\n  b\n     c)"
           (output-for "(foo a\nb\nc)" {:indents {"foo" [[:inner 0 1]]}})))))

(deftest built-in-rules
  (testing "uses the inner built-in for fn"
    (is (= "(fn [x]\n  x)"
           (output-for "(fn [x]\nx)" {}))))
  (testing "uses the block built-in for let"
    (is (= "(let [a 1]\n  a)"
           (output-for "(let [a 1]\na)" {}))))
  (testing "uses the block built-in for when"
    (is (= "(when x\n  y)"
           (output-for "(when x\ny)" {}))))
  (testing "uses the block zero built-in for do"
    (is (= "(do\n  a\n  b)"
           (output-for "(do\na\nb)" {}))))
  (testing "keeps if at default alignment"
    (is (= "(if c\n    a\n    b)"
           (output-for "(if c\na\nb)" {}))))
  (testing "uses the def prefix fallback"
    (is (= "(defn- g\n  [x]\n  x)"
           (output-for "(defn- g\n[x]\nx)" {}))))
  (testing "uses the with prefix fallback"
    (is (= "(with-foo x\n  y)"
           (output-for "(with-foo x\ny)" {}))))
  (testing "does not apply an unqualified fallback to a dotted head"
    (is (= "(a.let x\n       y)"
           (output-for "(a.let x\ny)" {})))))

(deftest format-as-and-config-errors
  (testing "resolves format-as aliases"
    (is (= "(my-let [a 1]\n  a)"
           (output-for "(my-let [a 1]\na)" {:format-as {"my-let" "let"}}))))
  (testing "exact indents take precedence over patterns"
    (is (= "(when x\n  y\n  z)"
           (output-for "(when x\ny\nz)"
                       {:indents         {"when" [[:inner 0]]}
                        :indent-patterns [["^when" [[:block 2]]]]}))))
  (testing "patterns take precedence over built-ins"
    (is (= "(when x\n      y\n  z)"
           (output-for "(when x\ny\nz)"
                       {:indent-patterns [["^when" [[:block 2]]]]}))))
  (testing "rejects a name present in indents and format-as"
    (is (= {:value? false :has-message true}
           (let [result (error-summary "(when x\ny)"
                                       {:indents   {"when" [[:block 1]]}
                                        :format-as {"when" "let"}})]
             {:value?      (. result :value?)
              :has-message (. result :has-message)}))))
  (testing "rejects alias cycles"
    (is (= {:value? false :has-message true}
           (let [result (error-summary "(a x\ny)"
                                       {:format-as {"a" "b" "b" "a"}})]
             {:value?      (. result :value?)
              :has-message (. result :has-message)}))))
  (testing "rejects aliases to unknown targets"
    (is (= {:value? false :has-message true}
           (let [result (error-summary "(a x\ny)"
                                       {:format-as {"a" "unknown"}})]
             {:value?      (. result :value?)
              :has-message (. result :has-message)}))))
  (testing "rejects unsupported positive inner depth"
    (is (= {:value? false :has-message true}
           (let [result (error-summary "(foo x\ny)"
                                       {:indents {"foo" [[:inner 1]]}})]
             {:value?      (. result :value?)
              :has-message (. result :has-message)})))))
