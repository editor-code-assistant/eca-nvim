{:workspace {:paths      ["fnl"]
             :exclude    ["fnl/eca/nfnl"]
             :extensions [".fnl" ".fnlm"]
             :dotfiles   false
             :symlinks   false
             :config     true}
 :format    {:indent-width 2
             :parser       :eca.nfnl.fennel
             :indents      {"fn"      [[:inner 0]]
                            "deftest" [[:block 1]]}
             :format-as    {"def"     "fn"
                            "def-"    "fn"
                            "defn"    "fn"
                            "defn-"   "fn"
                            "testing" "deftest"}
             :alignment    {:bindings         true
                            :maps             true
                            :clauses          true
                            :split-bindings   true
                            :collapse-padding true
                            :binding-forms    ["let" "when-let" "if-let" "with-open"]
                            :clause-forms     ["case" "match" "case-try" "match-try" "if"]}
             :newline      [{:applies-to {:files [:^fennel-extras/]
                                          :forms [:fn :defn :defn-]}
                             :options    {:after-header       0
                                          :between-same-level 1
                                          :break-after-n-args [[1 1] [2 1]]}}
                            {:applies-to {:forms [:testing]}
                             :options    {:before 0}}
                            {:applies-to {:files [:^spec/]
                                          :forms [:deftest]}
                             :options    {:after-header 0}}
                            {:applies-to {:files [:^spec/]
                                          :forms [:testing]}
                             :options    {:between-same-level 1}}
                            {:applies-to {:files ["^spec/"]
                                          :forms ["="]}
                             :options    {:break-after-args 1}}]}
 :lint
 {:rules {:forbidden-form [{:severity    :error
                            :description "catch accidental use of the literal module target in spec code"
                            :applies-to  {:files   [:^spec/]
                                          :modules [:module]}
                            :options     {}
                            :exclusions  []}
                           {:severity    :warning
                            :applies-to  {:files ["^fennel-extras/"]
                                          :forms ["local"]}
                            :options     {:exception [:top-level]}
                            :exclusions  []}
                           {:severity    :warning
                            :description "keep source data flow explicit by avoiding mutable bindings and open-ended loops"
                            :applies-to  {:files [:^fennel-extras/]
                                          :forms [:var :set :while]}
                            :options     {}
                            :exclusions  []}]
          :file-size      [{:severity    :warning
                            :description "keep source modules focused and reviewable by splitting oversized files"
                            :applies-to  {:files [:^fennel-extras/]}
                            :options     {:max-code-lines 300}
                            :exclusions  []}]
          :child-count    [{:severity    :error
                            :description "keep each test focused on one assertion"
                            :applies-to  {:files [:^spec/] :forms [:testing]}
                            :options     {:children [:is] :max-count 1}
                            :exclusions  []}
                           {:severity    :error
                            :description "keep multi-branch if forms simple by extracting complex logic into private functions"
                            :applies-to  {:forms [:if]}
                            :options     {:min-count   2
                                          :max-count   2
                                          :not-counted ["nil" "true" "false"]}
                            :exclusions  [{:path "^spec/eca/macros[.]fnlm$"}]}
                           {:severity    :error
                            :description "keep or expressions free of nested when forms by extracting complex logic into private functions"
                            :applies-to  {:files ["^spec/"] :forms [:or]}
                            :options     {:children [:when]
                                          :max-count 0}
                            :exclusions  []}]
          :module-import  [{:severity    :error
                            :description "standardize shared core access through the conventional core binding"
                            :applies-to  {:modules [:eca.nfnl.core]}
                            :options     {:mode :require :binding :core}
                            :exclusions  []}
                           {:severity    :error
                            :description "keep test declarations and assertions on the project macro layer for a consistent test DSL"
                            :applies-to  {:files   [:^spec/]
                                          :forms   [:deftest :testing :is]
                                          :modules [:spec.eca.macros]}
                            :options     {:mode :require}
                            :exclusions  []}
                           {:severity    :error
                            :description "avoid direct test-library coupling in specs by routing tests through project macros"
                            :applies-to  {:files   [:^spec/]
                                          :modules [:plenary.busted
                                                    :luassert]}
                            :options     {:mode :forbid}
                            :exclusions  []}]
          :form-chain     [{:severity    :warning
                            :description "Keep bindings at the start of the body so functions gather required data before executing logic."
                            :applies-to  {:files ["^fennel-extras/"] :forms ["let"]}
                            :options     {:allowed-chains [["def" "<form>"]
                                                           ["defn" "<form>"]
                                                           ["defn-" "<form>"]
                                                           ["defn" "when" "<form>"]
                                                           ["defn" "fn" "<form>"]]}
                            :exclusions  []}
                           {:severity    :warning
                            :applies-to {:files ["^fennel-extras/"] :forms ["local"]}
                            :options     {:allowed-chains [["<form>"]]}
                            :exclusions  []}]
          :required-form  [{:severity    :error
                            :description "give each source file a stable module identity for imports and diagnostics"
                            :applies-to  {:files [:^fennel-extras/]
                                          :forms [:module]}
                            :options     {}
                            :exclusions  []}]}}}
