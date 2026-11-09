(import-macros {: deftest : testing : is} :spec.eca.macros)
(local icon (require :eca.ui.components.icon))

(deftest render
  (testing "renders a named icon"
    (is (= {:text "✅" :hl-group :Normal}
           (icon.render {:name :success}))))

  (testing "direct text overrides the named icon"
    (is (= "custom" (. (icon.render {:name :success :text "custom"}) :text)))))
