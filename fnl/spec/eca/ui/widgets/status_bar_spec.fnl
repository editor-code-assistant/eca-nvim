(import-macros {: deftest : testing : is} :fennel-extras.macros.test)
(local status-bar (require :eca.ui.widgets.status-bar))

(deftest state
  (testing "updates one status section without losing the initial one"
    (let [canvas {:set-option (fn [_ _ _] nil)}
          widget (status-bar.create canvas {:left [{:text "L" :hl-group "EcaHeaderKey"}]})]
      (widget.update {:right [{:text "R"}]})
      (is (= {:left 1 :right "R"}
             {:left  (length (. (widget.get-state) :left))
              :right (. (. (. (widget.get-state) :right) 1) :text)})))))

(deftest render
  (testing "writes the formatted sections to the window statusline"
    (let [options []
          canvas  {:set-option (fn [_ scope name value]
                                 (table.insert options [scope name value]))}
          widget  (status-bar.create canvas
                                     {:left  [{:text     "L"
                                               :hl-group "EcaHeaderKey"}]
                                      :right [{:text "R"}]})]
      (widget.render)
      (is (= [[:win :statusline
               "%#EcaHeaderKey# L %=%=%#Normal# R "]]
             options)))))
