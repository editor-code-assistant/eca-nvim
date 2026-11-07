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
                     :description "forbid module targets in spec files"
                     :applies-to  {:files   ["^spec/"]
                                   :modules ["module"]}
                     :options     {}
                     :exclusions  []}
                    {:severity    :warning
                     :description "forbid var, set, and while forms in fennel-extras files"
                     :applies-to  {:files ["^fennel-extras/"]
                                   :forms ["var" "set" "while"]}
                     :options     {}
                     :exclusions  []}]

   :file-size      [{:severity    :warning
                     :description "limit fennel-extras files to 300 code lines"
                     :applies-to  {:files ["^fennel-extras/"]}
                     :options     {:max-code-lines 300}
                     :exclusions  []}]
   :child-count    [{:severity    :error
                     :description "allow exactly one is child in testing forms"
                     :applies-to  {:files ["^spec/"]
                                   :forms ["testing"]}
                     :options     {:children  ["is"]
                                   :max-count 1}
                     :exclusions  []}
                    {:severity    :error
                     :description "require exactly two non-nil branches and no clauses in if forms"
                     :applies-to  {:forms ["if"]}
                     :options     {:min-count 2
                                   :max-count 2
                                   :nil-count false}
                     :exclusions  [{:path "^spec/eca/macros[.]fnlm$"}]}]
   :module-import  [{:severity    :error
                     :description "require eca.nfnl.core as core"
                     :applies-to  {:modules ["eca.nfnl.core"]}
                     :options     {:mode    :require
                                   :binding "core"}
                     :exclusions  []}
                    {:severity    :error
                     :description "require spec.eca.macros for deftest, testing, and is forms"
                     :applies-to  {:files   ["^spec/"]
                                   :forms   ["deftest" "testing" "is"]
                                   :modules ["spec.eca.macros"]}
                     :options     {:mode :require}
                     :exclusions  [{:path "^spec/eca/macros[.]fnlm$"}]}
                    {:severity    :error
                     :description "forbid plenary.busted and luassert in spec files"
                     :applies-to  {:files   ["^spec/"]
                                   :modules ["plenary.busted" "luassert"]}
                     :options     {:mode :forbid}
                     :exclusions  [{:path "^spec/eca/macros[.]fnlm$"}]}]

   :required-form  [{:severity    :error
                     :description "require a top-level module form in fennel-extras files"
                     :applies-to  {:files ["^fennel-extras/"]
                                   :forms ["module"]}
                     :options     {}
                     :exclusions  []}]
  }}}
