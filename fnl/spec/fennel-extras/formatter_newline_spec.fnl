(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(local format (require :fennel-extras.format))

(local base-config
       {:indent-width     2
        :builtins         false
        :prefix-fallbacks false
        :parser           false
        :indents          {"defn"    [[:block 1]]
                           "defn-"   [[:block 1]]
                           "fn"      [[:block 1]]
                           "testing" [[:block 1]]}
        :newline          [{:applies-to {:forms ["fn" "defn" "defn-"]}
                            :options    {:after 1}}
                           {:applies-to {:forms ["testing"]}
                            :options    {:before 1}}]})

(defn- formatted-body
  [format source]
  (format.format-string source {:config base-config}))



(defn- formatted
  [source]
  (let [(ok value) (pcall formatted-body format source)]
    (if ok value nil)))



(deftest formatter-newline-contract





  (testing "newline after applies to function forms"
    (is (= "(defn run []\n  true)\n\n(foo)"
           (formatted "(defn run []\ntrue)\n(foo)"))))





  (testing "newline before applies to testing forms"
    (is (= "(foo)\n\n(testing \"works\"\n  (is true))"
           (formatted "(foo)\n(testing \"works\"\n(is true))")))))
