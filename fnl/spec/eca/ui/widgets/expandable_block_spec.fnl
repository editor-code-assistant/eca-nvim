(import-macros {: deftest : testing : is} :spec.eca.macros)
(local expandable (require :eca.ui.widgets.expandable-block))

(deftest state
  (testing "supports expansion and label updates"
    (let [canvas {:create-namespace (fn [_] 1)
                  :set-lines        (fn [_ _ _] nil)
                  :add-extmark      (fn [_ _ _ _] nil)}
          widget (expandable.create canvas {:id :x :label "Details" :content ["one"]})]
      (widget.expand)
      (widget.update-label "More")
      (is (= {:expanded? true :label "More"}
             {:expanded? (. (widget.get-state) :expanded?)
              :label     (. (widget.get-state) :label)})))))

(deftest render
  (testing "writes the expanded label and content with a label extmark"
    (let [calls  {:namespace [] :lines [] :extmarks []}
          canvas {:create-namespace (fn [_ name]
                                      (table.insert (. calls :namespace) name)
                                                   4)
                  :set-lines        (fn [_ start end lines]
                                      (table.insert (. calls :lines)
                                                    [start end lines]))
                  :add-extmark      (fn [_ ns line col opts]
                                      (table.insert (. calls :extmarks)
                                                    [ns line col opts]))}
          widget (expandable.create canvas {:id      :x
                                            :label   "Details"
                                            :content ["one" "two"]})]
      (widget.expand)
      (is (= {:namespace  ["eca-expandable-x"]
              :lines      [[5 5 ["⏷ Details" "  one" "  two"]]]
              :extmarks   [[4 5 0 {:end_col  11
                                   :hl_group :EcaExpandableLabel}]]
              :line-count 3}
             {:namespace  (. calls :namespace)
              :lines      (. calls :lines)
              :extmarks   (. calls :extmarks)
              :line-count (widget.render 5)})))))
