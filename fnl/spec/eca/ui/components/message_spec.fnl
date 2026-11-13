(import-macros {: deftest : testing : is} :fennel-extras.macros.test)
(local message (require :eca.ui.components.message))

(deftest render
  (testing "prefixes the first line and highlights each rendered line"
    (is (= ["> hello" "world" "" ""]
           (. (message.render {:content "hello\nworld" :prefix "> "}) :lines))))

  (testing "renders collapsed content with its label range"
    (let [result (message.render {:content "hello" :collapsed? true})]
      (is (= {:lines     ["▸ hello" ""]
              :highlight (. (. result :highlights) 1)}
             {:lines     (. result :lines)
              :highlight {:line-idx 0 :hl-group :EcaExpandableLabel
                          :col-start 0 :col-end 4}})))))
