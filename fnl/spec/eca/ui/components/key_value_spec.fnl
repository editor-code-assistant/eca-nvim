(import-macros {: deftest : testing : is} :fennel-extras.macros.test)
(local key-value (require :eca.ui.components.key-value))

(deftest render
  (testing "renders the line and zero-based end-exclusive ranges"
    (is (= {:line       "model:Claude"
            :highlights [{:hl-group :EcaHeaderKey :col-start 0 :col-end 5}
                         {:hl-group :EcaHeaderValue :col-start 6 :col-end 12}]}
           (key-value.render {:title "model" :value "Claude"})))))
