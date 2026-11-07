(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(local config (require :fennel-extras.config))
(local format (require :fennel-extras.format))
(local rules (require :fennel-extras.rules))

(local aliases {"def" "fn" "def-" "fn" "defn" "fn" "defn-" "fn"})
(local fn-config {:indent-width 2
                  :parser       "eca.nfnl.fennel"
                  :indents      {"fn" [[:inner 0]]}
                  :format-as    aliases})
(local default-config {:indent-width 2
                       :parser       "eca.nfnl.fennel"})

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

         (testing "keeps only fn as the explicit declaration indentation base"
                  (let [format-config (repository-format)]
                    (is (= {:indents   {"fn" [[:inner 0]]}
                            :format-as nil}
                           {:indents   (. format-config :indents)
                            :format-as (. format-config :format-as)})))))

(deftest canonical-defaults

         (testing "the canonical config does not require definition aliases in format-as"
                  (let [format-config (repository-format)
                        format-as     (. format-config :format-as)]
                    (is (= nil
                           (and format-as
                                (or (. format-as "def")
                                    (. format-as "def-")
                                    (. format-as "defn")
                                    (. format-as "defn-"))))))))

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

(deftest root-declarations-with-defaults

         (testing "def uses formatter defaults for its continuation indentation"
                  (is (= "(def value\n  1)"
                         (format-with "(def value\n1)" default-config))))

         (testing "def- uses formatter defaults for its continuation indentation"
                  (is (= "(def- value\n  1)"
                         (format-with "(def- value\n1)" default-config))))

         (testing "defn uses formatter defaults for its arguments and body"
                  (is (= "(defn value\n  [x]\n  body)"
                         (format-with "(defn value\n[x]\nbody)" default-config))))

         (testing "defn- uses formatter defaults for its arguments and body"
                  (is (= "(defn- value\n  [x]\n  body)"
                         (format-with "(defn- value\n[x]\nbody)" default-config)))))

(deftest nested-declarations

         (testing "nested declarations use parent indentation while preserving declaration shape"
                  (is (= "(def outer\n  (defn inner\n    [x]\n    body)\n  (def value\n    1))"
                         (format-with "(def outer\n(defn inner\n[x]\nbody)\n(def value\n1))" fn-config)))))

(deftest nested-declarations-with-defaults

         (testing "nested declarations preserve shape and generic parent indentation with formatter defaults"
                  (is (= "(def outer\n  (defn inner\n    [x]\n    body)\n  (def value\n    1))"
                         (format-with "(def outer\n(defn inner\n[x]\nbody)\n(def value\n1))" default-config)))))

(deftest one-line-declarations

         (testing "one-line declarations remain unchanged without automatic splitting"
                  (let [source "(def value 1)\n(def- value 2)\n(defn value [x] body)\n(defn- value [x] body)"]
                    (is (= source
                           (format-with source default-config))))))

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
