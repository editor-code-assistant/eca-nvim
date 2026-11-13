(import-macros {: deftest : testing : is} :fennel-extras.macros.test)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(local config (require :fennel-extras.config))
(local format (require :fennel-extras.format))
(local rules (require :fennel-extras.rules))

(local aliases {"def" "fn" "def-" "fn" "defn" "fn" "defn-" "fn"})
(local fn-config {:indent-width 2
                  :parser       "eca.nfnl.fennel"
                  :indents      {"fn" [[:inner 0]]}
                  :format-as    aliases})

(defn- repository-format
  []
  (. (assert (config.load ".fnl-extras.fnl")) :format))

(defn- format-with
  [source settings]
  (let [format-string (. format "format-string")
        (value error) (format-string source {:config settings})]
    (assert value error)
    value))

(deftest canonical-configuration
  (testing "matches the current declaration, alignment, and newline rules"
    (let [format-config (repository-format)]
      (is (= {:indents   {"fn"      [[:inner 0]]
                          "deftest" [[:block 1]]}
              :format-as {"def"     "fn"
                          "def-"    "fn"
                          "defn"    "fn"
                          "defn-"   "fn"
                          "testing" "deftest"}
              :alignment {:bindings         true
                          :maps             true
                          :clauses          true
                          :split-bindings   true
                          :collapse-padding true
                          :binding-forms    ["let" "when-let" "if-let" "with-open"]
                          :clause-forms     ["case" "match" "case-try" "match-try" "if"]}
              :newline   [{:applies-to {:files ["^fennel-extras/"]
                                        :forms ["fn" "defn" "defn-"]}
                           :options    {:after-header       0
                                        :between-same-level 1
                                        :break-after-n-args [[1 1] [2 1]]}}
                          {:applies-to {:forms ["testing"]}
                           :options    {:before 0}}
                          {:applies-to {:files ["^spec/"]
                                        :forms ["deftest"]}
                           :options    {:after-header 0}}
                          {:applies-to {:files ["^spec/"]
                                        :forms ["testing"]}
                           :options    {:between-same-level 1}}
                          {:applies-to {:files ["^spec/"]
                                        :forms ["="]}
                           :options    {:break-after-args 1}}]}
             {:indents   (. format-config :indents)
              :format-as (. format-config :format-as)
              :alignment (. format-config :alignment)
              :newline   (. format-config :newline)})))))

(deftest root-declarations
  (testing "def indents its value"
    (is (= "(def value\n  1)"
           (format-with "(def value\n1)" fn-config))))

  (testing "def- indents its value"
    (is (= "(def- value\n  1)"
           (format-with "(def- value\n1)" fn-config))))

  (testing "defn indents arguments and body"
    (is (= "(defn value\n  [x]\n  body)"
           (format-with "(defn value\n[x]\nbody)" fn-config))))

  (testing "defn- indents arguments and body"
    (is (= "(defn- value\n  [x]\n  body)"
           (format-with "(defn- value\n[x]\nbody)" fn-config)))))

(deftest nested-declarations
  (testing "nested declarations use parent indentation while preserving declaration shape"
    (is (= "(def outer\n  (defn inner\n    [x]\n    body)\n  (def value\n    1))"
           (format-with "(def outer\n(defn inner\n[x]\nbody)\n(def value\n1))" fn-config)))))

(deftest target-propagation
  (testing "changing the fn target changes every aliased definition"
    (let [first  {:indents   {"fn" [[:inner 0]]}
                  :format-as aliases}
          second {:indents   {"other" [[:block 1]]}
                  :format-as {"def"   "other"
                              "def-"  "other"
                              "defn"  "other"
                              "defn-" "other"}}]
      (is (= {"def"   [[:block 1]]
              "def-"  [[:block 1]]
              "defn"  [[:block 1]]
              "defn-" [[:block 1]]}
             {"def"   (rules.resolve second "def")
              "def-"  (rules.resolve second "def-")
              "defn"  (rules.resolve second "defn")
              "defn-" (rules.resolve second "defn-")})))))
