(import-macros {: deftest : testing : is} :fennel-extras.macros.test)
(local prompt-prefix (require :eca.ui.components.prompt-prefix))

(deftest render
  (testing "renders the idle prompt"
    (is (= {:text "> " :hl-group :EcaPromptPrefix}
           (prompt-prefix.render {:loading? false}))))

  (testing "renders the loading prompt"
    (is (= {:text "⏳ " :hl-group :EcaPromptPrefixLoading}
           (prompt-prefix.render {:loading? true})))))
