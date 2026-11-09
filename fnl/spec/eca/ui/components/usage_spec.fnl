(import-macros {: deftest : testing : is} :spec.eca.macros)
(local usage (require :eca.ui.components.usage))

(deftest render

         (testing "preserves formatted usage text and highlight"
                  (is (= {:text "31K/200K ($0.03)" :hl-group :EcaUsage}
                         (usage.render {:text "31K/200K ($0.03)" :hl-group :EcaUsage})))))
