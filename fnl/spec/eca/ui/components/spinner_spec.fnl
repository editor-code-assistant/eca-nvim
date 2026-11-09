(import-macros {: deftest : testing : is} :spec.eca.macros)
(local spinner (require :eca.ui.components.spinner))

(deftest render
  (testing "exposes the number of frames"
    (is (= 10 (spinner.frame-count))))

  (testing "wraps the zero-based frame index"
    (is (= ["⠋" "⠋"]
           [(. (spinner.render {:frame 0}) :text)
            (. (spinner.render {:frame 10}) :text)]))))
