{:workspace
 {:paths      ["fnl"]
  :exclude    ["fnl/eca/nfnl"]
  :extensions [".fnl" ".fnlm"]
  :dotfiles   false
  :symlinks   false
  :config     true}
 :format
 {:indent-width 2
  :parser       "eca.nfnl.fennel"
  :indents      {"fn" [[:inner 0]]}
  :format-as    {"def"   "fn"
                 "def-"  "fn"
                 "defn"  "fn"
                 "defn-" "fn"}
  :alignment    {:bindings         true
                 :maps             true
                 :clauses          true
                 :split-bindings   true
                 :collapse-padding true
                 :binding-forms    ["let" "when-let" "if-let" "with-open"]
                 :clause-forms     ["case" "match" "case-try" "match-try" "if"]}
  :newline      [{:applies-to {:files ["^fennel-extras/"]
                               :forms ["fn" "defn" "defn-"]}
                  :options    {:after-header 1}}
                 {:applies-to {:forms ["testing"]}
                  :options    {:before 1}}]}
 :lint
 {:rules
  {:forbidden-form [{:severity    :error
                     :description "catch accidental use of the literal module target in spec code"
                     :applies-to  {:files   ["^spec/"]
                                   :modules ["module"]}
                     :options     {}
                     :exclusions  []}
                    {:severity    :warning
                     :description "keep source data flow explicit by avoiding mutable bindings and open-ended loops"
                     :applies-to  {:files ["^fennel-extras/"]
                                   :forms ["var" "set" "while"]}
                     :options     {}
                     :exclusions  []}]

   :file-size      [{:severity    :warning
                     :description "keep source modules focused and reviewable by splitting oversized files"
                     :applies-to  {:files ["^fennel-extras/"]}
                     :options     {:max-code-lines 300}
                     :exclusions  []}]
   :child-count    [{:severity    :error
                     :description "keep each test focused on one assertion"
                     :applies-to  {:files ["^spec/"]
                                   :forms ["testing"]}
                     :options     {:children  ["is"]
                                   :max-count 1}
                     :exclusions  []}
                    {:severity    :error
                     :description "keep conditionals explicit and predictable with two non-nil branches and no extra clauses"
                     :applies-to  {:forms ["if"]}
                     :options     {:min-count 2
                                   :max-count 2
                                   :nil-count false}
                     :exclusions  [{:path "^spec/eca/macros[.]fnlm$"}]}]
   :module-import  [{:severity    :error
                     :description "standardize shared core access through the conventional core binding"
                     :applies-to  {:modules ["eca.nfnl.core"]}
                     :options     {:mode    :require
                                   :binding "core"}
                     :exclusions  []}
                    {:severity    :error
                     :description "keep test declarations and assertions on the project macro layer for a consistent test DSL"
                     :applies-to  {:files   ["^spec/"]
                                   :forms   ["deftest" "testing" "is"]
                                   :modules ["spec.eca.macros"]}
                     :options     {:mode :require}
                     :exclusions  [{:path "^spec/eca/macros[.]fnlm$"}]}
                    {:severity    :error
                     :description "avoid direct test-library coupling in specs by routing tests through project macros"
                     :applies-to  {:files   ["^spec/"]
                                   :modules ["plenary.busted" "luassert"]}
                     :options     {:mode :forbid}
                     :exclusions  [{:path "^spec/eca/macros[.]fnlm$"}]}]

   :required-form  [{:severity    :error
                     :description "give each source file a stable module identity for imports and diagnostics"
                     :applies-to  {:files ["^fennel-extras/"]
                                   :forms ["module"]}
                     :options     {}
                     :exclusions  []}]
  }}}
