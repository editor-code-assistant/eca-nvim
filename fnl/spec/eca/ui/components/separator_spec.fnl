(import-macros {: deftest : testing : is} :spec.eca.macros)
(local separator (require :eca.ui.components.separator))

(deftest render

         (testing "uses the requested character and width"
                  (is (= {:line       "-----"
                          :highlights [{:hl-group :EcaSeparator :col-start 0 :col-end 5}]}
                         (separator.render {:char "-" :width 5})))))
