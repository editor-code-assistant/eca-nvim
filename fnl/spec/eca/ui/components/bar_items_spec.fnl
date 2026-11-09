(import-macros {: deftest : testing : is} :spec.eca.macros)
(local bar-items (require :eca.ui.components.bar-items))

(deftest render
  (testing "renders a single titled item"
    (is (= " %#EcaHeaderKey#Model%#EcaHeaderValue#:Claude"
           (bar-items.render {:items [{:title "Model" :value "Claude"}]}))))

  (testing "renders an empty list as an empty string"
    (is (= ""
           (bar-items.render {:items []})))))
