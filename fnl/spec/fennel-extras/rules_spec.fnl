(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(defn- load-indent []
  (let [(ok result) (pcall require :fennel-extras.indent)]
    (if ok
        result
        {:error "module missing"})))

(defn- reindent-scenario [source config]
  (let [indent (load-indent)]
    (if (. indent :error)
        indent
        (let [(ok result err) (pcall (fn [] (indent.reindent source config)))]
          (if ok
              {:value result :error err}
              {:call-error true :error err})))))

(defn- output-for [source config]
  (let [result (reindent-scenario source config)]
    (if (. result :error)
        result
        (. result :value))))

(defn- error-summary [source config]
  (let [indent (load-indent)]
    (if (. indent :error)
        indent
        (let [(ok value err) (pcall (fn [] (indent.reindent source config)))]
          {:value? (and ok (not= nil value))
           :has-message (and ok (= nil value) (not= nil err) (= :string (type (. err :message))))
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
  (testing "uses default alignment when the first block argument starts on a new line"
           (is (= "(testing\n \"d\"\n  body)"
                  (output-for "(testing\n\"d\"\nbody)" {:indents {"testing" [[:block 1]]}}))))
  (testing "applies inner rules to only the selected argument"
           (is (= "(foo a\n  b\n     c)"
                  (output-for "(foo a\nb\nc)" {:indents {"foo" [[:inner 0 1]]}})))))

(deftest built-in-rules
  (testing "uses the inner built-in for fn"
           (is (= "(fn [x]\n  x)"
                  (output-for "(fn [x]\nx)" nil))))
  (testing "uses the block built-in for let"
           (is (= "(let [a 1]\n  a)"
                  (output-for "(let [a 1]\na)" nil))))
  (testing "uses the block built-in for when"
           (is (= "(when x\n  y)"
                  (output-for "(when x\ny)" nil))))
  (testing "uses the block zero built-in for do"
           (is (= "(do\n  a\n  b)"
                  (output-for "(do\na\nb)" nil))))
  (testing "keeps if at default alignment"
           (is (= "(if c\n    a\n    b)"
                  (output-for "(if c\na\nb)" nil))))
  (testing "uses the def prefix fallback"
           (is (= "(defn- g\n  [x]\n  x)"
                  (output-for "(defn- g\n[x]\nx)" nil))))
  (testing "uses the with prefix fallback"
           (is (= "(with-foo x\n  y)"
                  (output-for "(with-foo x\ny)" nil))))
  (testing "does not apply an unqualified fallback to a dotted head"
           (is (= "(a.let x\n       y)"
                  (output-for "(a.let x\ny)" nil)))))

(deftest format-as-and-config-errors
  (testing "resolves format-as aliases"
           (is (= "(my-let [a 1]\n  a)"
                  (output-for "(my-let [a 1]\na)" {:format-as {"my-let" "let"}}))))
  (testing "exact indents take precedence over patterns"
           (is (= "(when x\n  y\n  z)"
                  (output-for "(when x\ny\nz)"
                              {:indents {"when" [[:inner 0]]}
                               :indent-patterns [["^when" [[:block 2]]]]}))))
  (testing "patterns take precedence over built-ins"
           (is (= "(when x\n      y\n  z)"
                  (output-for "(when x\ny\nz)"
                              {:indent-patterns [["^when" [[:block 2]]]]}))))
  (testing "rejects a name present in indents and format-as"
           (is (= {:value? false :has-message true}
                  (let [result (error-summary "(when x\ny)"
                                              {:indents {"when" [[:block 1]]}
                                               :format-as {"when" "let"}})]
                    {:value? (. result :value?)
                     :has-message (. result :has-message)}))))
  (testing "rejects alias cycles"
           (is (= {:value? false :has-message true}
                  (let [result (error-summary "(a x\ny)"
                                              {:format-as {"a" "b" "b" "a"}})]
                    {:value? (. result :value?)
                     :has-message (. result :has-message)}))))
  (testing "rejects aliases to unknown targets"
           (is (= {:value? false :has-message true}
                  (let [result (error-summary "(a x\ny)"
                                              {:format-as {"a" "unknown"}})]
                    {:value? (. result :value?)
                     :has-message (. result :has-message)}))))
  (testing "rejects unsupported positive inner depth"
           (is (= {:value? false :has-message true}
                  (let [result (error-summary "(foo x\ny)"
                                              {:indents {"foo" [[:inner 1]]}})]
                    {:value? (. result :value?)
                     :has-message (. result :has-message)})))))
