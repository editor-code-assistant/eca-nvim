(import-macros {: deftest : testing : is} :fennel-extras.macros.test)
(local button (require :eca.ui.components.button))

(deftest render
  (testing "includes a keybind when supplied"
    (is (= {:text "Accept (a)" :hl-group :EcaButtonAccept}
           (button.render {:label "Accept" :keybind "a"}))))

  (testing "uses the requested highlight"
    (is (= :EcaButtonReject
           (. (button.render {:label "Reject" :hl-group :EcaButtonReject}) :hl-group)))))
