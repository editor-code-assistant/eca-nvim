(import-macros {: deftest : testing : is} :fennel-extras.macros.test)
(local highlights (require :eca.ui.highlights))

(deftest groups
  (testing "exposes the public highlight names"
    (is (= ["WarningMsg" "DiagnosticOk"]
           [(. (. highlights.groups :EcaSpinner) :link)
            (. (. highlights.groups :EcaButtonAccept) :link)]))))
