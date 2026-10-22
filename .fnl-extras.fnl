{:indents {"deftest" [[:block 1]]
           "testing" [[:block 1]]
           "if" [[:block 1]]}
 :align-bindings true
 :parser "eca.nfnl.fennel"
 :paths ["fnl"]
 :exclude ["fnl/eca/nfnl"]
 :lint {:rules {"module-style"        :error
                "spec-macro-import"   :error
                "spec-no-module"      :error
                "spec-direct-require" :error
                "one-is-per-testing"  :error
                "if-branch-call"     :warning
                "if-without-else"    :warning
                "control-layout"     :warning
                "unused-and-or"      :warning
                "defn-args-newline"  :warning
                "function-shape"     :warning
                "no-mutation"        :warning
                "multiline-layout"  :warning
                "file-size"          :warning
                "core-require"       :error
                "binding-per-line"   :warning
                "call-data-arg"      :warning}}}
