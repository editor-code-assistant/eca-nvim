{:workspace
 {:paths      ["fnl"]
  :exclude    ["fnl/eca/nfnl"]
  :extensions [".fnl" ".fnlm"]
  :dotfiles   false
  :symlinks   false
  :config     false}
 :format
 {:indent-width     2
  :builtins         {"fn"         [[:inner 0]]
                     "lambda"     [[:inner 0]]
                     "macro"      [[:inner 0]]
                     "let"        [[:block 1]]
                     "when"       [[:block 1]]
                     "when-let"   [[:block 1]]
                     "if-let"     [[:block 1]]
                     "each"       [[:block 1]]
                     "for"        [[:block 1]]
                     "icollect"   [[:block 1]]
                     "collect"    [[:block 1]]
                     "accumulate" [[:block 1]]
                     "case"       [[:block 1]]
                     "match"      [[:block 1]]
                     "case-try"   [[:block 1]]
                     "match-try"  [[:block 1]]
                     "while"      [[:block 1]]
                     "with-open"  [[:block 1]]
                     "do"         [[:block 0]]}
  :prefix-fallbacks {"def"   [[:inner 0]]
                     "with-" [[:block 1]]}
  :parser           "eca.nfnl.fennel"
  :indents          {"deftest" [[:block 1]]
                     "testing" [[:block 1]]
                     "if"      [[:block 1]]}
  :format-as        {}
  :indent-patterns  []
  :alignment        {:bindings         true
                     :maps             true
                     :clauses          true
                     :split-bindings   true
                     :collapse-padding true
                     :binding-forms    ["let" "when-let" "if-let" "with-open"]
                     :clause-forms     ["case" "match" "case-try" "match-try" "if"]}
  :newline          [{:applies-to {:forms ["fn" "defn" "defn-"]}
                      :options    {:after 1}}
                     {:applies-to {:forms ["testing"]}
                      :options    {:before 1}}]}
 :lint
 {:rules
  {:forbidden-form [{:severity   :error
     :applies-to {:files   ["^spec/"]
                  :modules "module"}
     :options    {}
     :exclusions []}
    {:severity   :warning
     :applies-to {:files ["^fennel-extras/"]
                  :forms ["var" "set" "while"]}
     :options    {}
     :exclusions []}]
   :call-data-arg [{:severity   :warning
     :applies-to {:files ["^fennel-extras/"]
                  :forms []}
     :options    {}
     :exclusions []}]
   :control-layout [{:severity   :warning
     :applies-to {:forms ["if" "when" "and" "or" "case" "match"]}
     :options    {}
     :exclusions []}]
   :file-size [{:severity   :warning
     :applies-to {:files ["^fennel-extras/"]}
     :options    {:max-code-lines 300}
     :exclusions []}]
   :form-child-count [{:severity   :error
     :applies-to {:files ["^spec/"]
                  :forms ["testing"]}
     :options    {:children  ["is"]
                  :max-count 1}
     :exclusions []}]
   :module-import [{:severity   :error
     :applies-to {:modules "eca.nfnl.core"}
     :options    {:mode    :require
                  :binding "core"}
     :exclusions []}
    {:severity   :error
     :applies-to {:files   ["^spec/"]
                  :forms   ["deftest" "testing" "is"]
                  :modules "spec.eca.macros"}
     :options    {:mode         :require
                  :exempt-files ["^spec/eca/macros[.]fnlm$"]}
     :exclusions []}
    {:severity   :error
     :applies-to {:files   ["^spec/"]
                  :modules ["plenary.busted" "luassert"]}
     :options    {:mode         :forbid
                  :exempt-files ["^spec/eca/macros[.]fnlm$"]}
     :exclusions []}]
   :module-style [{:severity   :error
     :applies-to {:files   ["^fennel-extras/"]
                  :forms   ["module" "def" "defn" "defn-"]
                  :modules "eca.nfnl.macros.aniseed"}
     :options    {}
     :exclusions []}]
   :multiline-layout [{:severity   :warning
     :applies-to {}
     :options    {:clauses  ["case" "match" "case-try" "match-try"]
                  :bindings ["let" "when-let" "if-let" "with-open"]}
     :exclusions []}]
   :required-form [{:severity   :error
     :applies-to {:files ["^fennel-extras/"]
                  :forms ["module"]}
     :options    {}
     :exclusions []}]
   :unused-and-or [{:severity   :warning
     :applies-to {:forms ["and" "or"]}
     :options    {}
     :exclusions []}]}}
 :design
 {:rules
  {:function-shape [{:severity   :warning
     :applies-to {:forms ["defn" "defn-" "fn" "lambda" "λ"]}
     :options    {}
     :exclusions []}]
   :if-branch-call [{:severity   :warning
     :applies-to {:forms ["if"]}
     :options    {}
     :exclusions []}]
   :if-without-else [{:severity   :warning
     :applies-to {:forms ["if"]}
     :options    {:nil-else true}
     :exclusions []}]
   :nested-forms [{:severity   :off
     :applies-to {:forms []}
     :options    {:max-depth 1}
     :exclusions []}]
   :leading-bindings [{:severity   :off
     :applies-to {:forms []}
     :options    {}
     :exclusions []}]
   :no-mutation [{:severity   :off
     :applies-to {:forms ["var" "set" "while"]}
     :options    {}
     :exclusions []}]}}}
