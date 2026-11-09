(import-macros {: deftest : testing : is} :spec.eca.macros)
(local tab-bar (require :eca.ui.widgets.tab-bar))

(deftest state
  (testing "selects tabs and falls back after removal"
    (let [canvas {:set-option (fn [_ _ _] nil)}
          widget (tab-bar.create canvas {})]
      (widget.add-tab {:id :chat :label "Chat"})
      (widget.add-tab {:id :logs :label "Logs"})
      (widget.select-tab :logs)
      (widget.remove-tab :logs)
      (is (= :chat (. (widget.get-state) :active-id))))))

(deftest render
  (testing "writes tabline options with active and inactive tab formatting"
    (let [options []
          canvas  {:set-option (fn [_ scope name value]
                                 (table.insert options [scope name value]))}
          widget  (tab-bar.create canvas {})]
      (widget.add-tab {:id :chat :label "Chat"})
      (widget.add-tab {:id :logs :label "Logs"})
      (widget.render)
      (is (= [[:global :tabline
               "%#EcaTabActive# Chat %#Normal#│%#EcaTabInactive# Logs "]
              [:global :showtabline 2]]
             options)))))
