(import-macros {: deftest : testing : is} :spec.eca.macros)
(local context-item (require :eca.ui.components.context-item))

(deftest render

         (testing "returns text and its highlight"
                  (is (= {:text "@file.lua" :hl-group :EcaContextFile}
                         (context-item.render {:text "@file.lua" :hl-group :EcaContextFile}))))

         (testing "defaults missing text to an empty string"
                  (is (= "" (. (context-item.render {}) :text)))))
