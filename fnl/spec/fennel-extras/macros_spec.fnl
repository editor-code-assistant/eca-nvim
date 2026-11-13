(import-macros {: cond} :fennel-extras.macros)
(import-macros {: deftest : testing : is} :fennel-extras.macros.test)

(deftest cond-macro
  (testing "selects the first matching branch in source order"
    (is (= :first
           (cond false :never
                 true :first
                 true :later))))

  (testing "uses the explicit fallback when no branch matches"
    (is (= :fallback
           (cond false :first
                 false :second
                 :else :fallback)))))
