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
                            :split-bindings   true
                            :collapse-padding true
                            :binding-forms    ["let" "when-let" "if-let" "with-open"]
                            :align-args       ["and" "or"]
                            :align-pairs      ["case" "cond" "match" "case-try" "match-try"]}
             :newline      [{:applies-to {:files ["^fennel-extras/"]
                                          :forms ["fn" "defn" "defn-"]}
                             :options    {:after-header       0
                                          :between-same-level 1}}
                            {:applies-to {:files ["^fennel-extras/"]
                                          :forms ["defn" "defn-"]}
                             :options    {:break-after-n-args [[1 1] [2 1]]}}
                            {:applies-to {:files ["^fennel-extras/"]
                                          :forms ["cond"]}
                             :options    {:group-size 2
                                          :group-gap  1}}
                            {:applies-to {:forms ["testing"]}
                             :options    {:before 0}}
                            {:applies-to {:files ["^spec/"]
                                          :forms ["deftest"]}
                             :options    {:after-header 0}}
                            {:applies-to {:files ["^spec/"]
                                          :forms ["testing"]}
                             :options    {:between-same-level 1}}
                            {:applies-to {:files ["^spec/"]
                                          :forms ["="]}
                             :options    {:break-after-args 1}}]}
 :lint
 {:rules {:file-size     [{:severity    :error
                           :description "keep source modules focused and reviewable by splitting oversized files"
                           :applies-to  {:files ["^fennel-extras/"]}
                           :options     {:max-code-lines 300}
                           :exclusions  []}]
          :child-count   [{:severity    :error
                           :description "keep each test focused on one assertion"
                           :applies-to  {:files ["^spec/"]
                                         :forms ["testing"]}
                           :options     {:children  ["is"]
                                         :max-count 1}
                           :exclusions  []}
                          {:severity    :error
                           :description "keep multi-branch if forms simple by extracting complex logic into private functions"
                           :applies-to  {:forms ["if"]}
                           :options     {:min-count   2
                                         :max-count   2
                                         :not-counted ["nil" "true" "false"]}
                           :exclusions  [{:path "^fennel-extras/macros"}]}
                          {:severity    :info
                           :description "Prefer `case` for fixed-value dispatch; use `or` only when `case` cannot express the predicates."
                           :applies-to  {:files ["^fennel-extras/"]
                                         :forms ["or"]}
                           :options     {:children  ["="]
                                         :max-count 1
                                         :direct    true}
                           :exclusions  []}
                          {:severity    :info
                           :description "prefer an else branch for cond forms."
                           :applies-to  {:files ["^fennel-extras/"]
                                         :forms ["cond"]}
                           :options     {:children  ["else"]
                                         :min-count 1
                                         :direct     true}
                           :exclusions  []}
                          ;; three predicate/body clauses, two children each
                          {:severity    :info
                           :description "prefer if over cond with fewer than three predicate/body clauses."
                           :applies-to  {:files ["^fennel-extras/"]
                                         :forms ["cond"]}
                           :options     {:min-count 6
                                         :direct    true}
                           :exclusions  []}]
          :module-import [{:severity    :error
                           :description "standardize shared core access through the conventional core binding"
                           :applies-to  {:modules ["eca.nfnl.core"]}
                           :options     {:mode "require" :binding "core"}
                           :exclusions  []}
                          {:severity    :error
                           :description "keep test declarations and assertions on the project macro layer for a consistent test DSL"
                           :applies-to  {:files   ["^spec/"]
                                         :forms   ["deftest" "testing" "is"]
                                         :modules ["fennel-extras.macros.test"]}
                           :options     {:mode "require"}
                           :exclusions  []}
                          {:severity    :error
                           :description "avoid direct test-library coupling in specs by routing tests through project macros"
                           :applies-to  {:files   ["^spec/"]
                                         :modules ["plenary.busted"
                                                   "luassert"]}
                           :options     {:mode "forbid"}
                           :exclusions  []}]
          :form-chain    [{:severity    :error
                           :description "keep source data flow explicit by avoiding mutable bindings and open-ended loops"
                           :applies-to  {:files ["^fennel-extras/"]
                                         :forms ["var" "set" "while"]}
                           :options     {:allowed-chains []}
                           :exclusions  []}
                          {:severity    :error
                           :description "keep `or` operands simple; prefer `cond` or extract conditional logic into private functions."
                           :applies-to  {:files ["^fennel-extras/"]
                                         :forms ["and" "when" "when-let" "if" "if-let" "cond" "case"]}
                           :options     {:forbidden-chains [["or" :form]
                                                            ["or" :forms-between :form]]}
                           :exclusions  []}
                          {:severity    :error
                           :description "Avoid nested `if` forms; they make control flow harder to read."
                           :applies-to  {:files ["^fennel-extras/"]
                                         :forms ["if"]}
                           :options     {:forbidden-chains [["if" :form]]}
                           :exclusions  []}
                          {:severity    :error
                           :description "Avoid nested `when` forms; they make control flow harder to read."
                           :applies-to  {:files ["^fennel-extras/"]
                                         :forms ["when"]}
                           :options     {:forbidden-chains [["when" :form]]}
                           :exclusions  []}
                          {:severity    :error
                           :description "keep `and` operands simple; extract conditional logic into private functions."
                           :applies-to  {:files ["^fennel-extras/"]
                                         :forms ["or" "when" "when-let" "if" "if-let" "cond" "case"]}
                           :options     {:forbidden-chains [["and" :form]
                                                            ["and" :forms-between :form]]}
                           :exclusions  []}
                          {:severity    :error
                           :description "keep bindings at the start of the body so functions gather required data before executing logic."
                           :applies-to  {:files ["^fennel-extras/"] :forms ["let"]}
                           :options     {:allowed-chains [["def" :form]
                                                          ["defn" :form]
                                                          ["defn-" :form]
                                                          ["defn" "when" :form]
                                                          ["defn" "fn" :form]]}
                           :exclusions  []}
                          {:severity    :error
                           :description "keep top-level locals limited to explicit require/import dependencies"
                           :applies-to  {:files ["^fennel-extras/"]
                                         :forms ["local"]}
                           :options     {:allowed-chains [[:root :form "require"]
                                                          [:root :form "import"]]}
                           :exclusions  []}
                          {:severity    :info
                           :description "prefer core.assoc, core.assoc-in, or core.merge over tset for immutable data updates"
                           :applies-to  {:files ["^fennel-extras/"]
                                         :forms ["tset"]}
                           :options     {:forbidden-chains [[:form]]}
                           :exclusions  []}
                          {:severity    :info
                           :description "prefer core.map, core.mapcat, or core.reduce over each for collection transformations"
                           :applies-to  {:files ["^fennel-extras/"]
                                         :forms ["each"]}
                           :options     {:forbidden-chains [[:form]]}
                           :exclusions  []}
                          {:severity    :info
                           :description "prefer core.map, core.mapcat, or core.reduce over icollect for collection transformations"
                           :applies-to  {:files ["^fennel-extras/"]
                                         :forms ["icollect"]}
                           :options     {:forbidden-chains [[:form]]}
                           :exclusions  []}
                          {:severity    :info
                           :description "prefer core.assoc, core.assoc-in, or core.merge over table.insert for immutable data updates"
                           :applies-to  {:files ["^fennel-extras/"]
                                         :forms ["table.insert"]}
                           :options     {:forbidden-chains [[:form]]}
                           :exclusions  []}
                          {:severity    :info
                           :description "prefer core.map, core.mapcat, or core.reduce over ipairs for collection transformations"
                           :applies-to  {:files ["^fennel-extras/"]
                                         :forms ["ipairs"]}
                           :options     {:forbidden-chains [[:form]]}
                           :exclusions  []}]
          :required-form [{:severity    :error
                           :description "give each source file a stable module identity for imports and diagnostics"
                           :applies-to  {:files ["^fennel-extras/"]
                                         :forms ["module"]}
                           :options     {}
                           :exclusions  [{:path "^fennel-extras/macros"}]}]}}}
