{:indent-width 2
 ;; Explicit indentation rules for formatter operation.
 :builtins {"fn" [[:inner 0]]
            "lambda" [[:inner 0]]
            "macro" [[:inner 0]]
            "let" [[:block 1]]
            "when" [[:block 1]]
            "when-let" [[:block 1]]
            "if-let" [[:block 1]]
            "each" [[:block 1]]
            "for" [[:block 1]]
            "icollect" [[:block 1]]
            "collect" [[:block 1]]
            "accumulate" [[:block 1]]
            "case" [[:block 1]]
            "match" [[:block 1]]
            "case-try" [[:block 1]]
            "match-try" [[:block 1]]
            "while" [[:block 1]]
            "with-open" [[:block 1]]
            "do" [[:block 0]]}
 ;; Explicit prefix fallbacks.
 :prefix-fallbacks {"def" [[:inner 0]]
                    "with-" [[:block 1]]}
 ;; Parser used for AST-preserving formatter checks.
 :parser "eca.nfnl.fennel"
 ;; Files discovered by scan.
 :extensions [".fnl" ".fnlm"]
 :skip-dotfiles true
 :follow-symlinks false
 :paths ["fnl"]
 :exclude ["fnl/eca/nfnl"]
 :indents {"deftest" [[:block 1]]
            "testing" [[:block 1]]
            "if" [[:block 1]]}
 :format-as {}
 :indent-patterns []
 ;; All formatter alignment modes are explicit.
 :alignment {:bindings true
             :maps true
             :clauses true
             :split-bindings true
             :collapse-padding true
             :binding-forms ["let" "when-let" "if-let" "with-open"]
             :clause-forms ["case" "match" "case-try" "match-try" "if"]}
 :lint {:spec-files ["^fnl/spec/"]
        :rules {"binding-per-line" {:severity :warning
                                     :options {:applies-to "all"
                                               :forms ["let" "when-let" "if-let" "with-open"]}}
                "call-data-arg" {:severity :warning
                                  :options {:applies-to "source"
                                            :ignore-forms []}}
                "control-layout" {:severity :warning
                                   :options {:applies-to "all"
                                             :control-forms ["if" "when" "and" "or" "case" "match"]}}
                "core-require" {:severity :error
                                 :options {:applies-to "all"
                                           :module "eca.nfnl.core"
                                           :binding "core"}}
                "defn-args-newline" {:severity :warning
                                      :options {:applies-to "all"
                                                :forms ["defn" "defn-"]}}
                "file-size" {:severity :warning
                              :options {:applies-to "source"
                                        :max-code-lines 300}}
                "function-shape" {:severity :warning
                                   :options {:applies-to "all"
                                             :function-forms ["defn" "defn-" "fn" "lambda" "λ"]}}
                "if-branch-call" {:severity :warning
                                   :options {:applies-to "all"
                                             :if-forms ["if"]}}
                "if-without-else" {:severity :warning
                                    :options {:applies-to "all"
                                              :if-forms ["if"]
                                              :flag-nil-else true}}
                "module-style" {:severity :error
                                 :options {:applies-to "source"
                                           :macro-module "eca.nfnl.macros.aniseed"
                                           :required-macros ["module" "def" "defn" "defn-"]}}
                "multiline-layout" {:severity :warning
                                      :options {:applies-to "all"
                                                :clause-forms ["case" "match" "case-try" "match-try"]
                                                :binding-forms ["let" "when-let" "if-let" "with-open"]}}
                "no-mutation" {:severity :warning
                                :options {:applies-to "source"
                                          :forms ["var" "set" "while"]}}
                "one-is-per-testing" {:severity :error
                                       :options {:applies-to "all"
                                                 :testing-form "testing"
                                                 :assertion-form "is"
                                                 :count 1}}
                "spec-direct-require" {:severity :error
                                        :options {:applies-to "spec"
                                                  :forbidden-modules ["plenary.busted" "luassert"]
                                                  :exempt-files ["^fnl/spec/eca/macros[.]fnlm$"]}}
                "spec-macro-import" {:severity :error
                                      :options {:applies-to "spec"
                                                :macro-module "spec.eca.macros"
                                                :required-macros ["deftest" "testing" "is"]
                                                :exempt-files ["^fnl/spec/eca/macros[.]fnlm$"]}}
                "spec-no-module" {:severity :error
                                   :options {:applies-to "spec"
                                             :module-form "module"}}
                "unused-and-or" {:severity :warning
                                  :options {:applies-to "all"
                                            :forms ["and" "or"]}}}}}
