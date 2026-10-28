{:workspace
 {
   :extensions       [".fnl" ".fnlm"]
   :dotfiles         false
   :symlinks         false
   :paths            ["fnl"]
   :exclude          ["fnl/eca/nfnl"]}
 :format
 {
  :indent-width     2
   ;; Explicit indentation rules for formatter operation.
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
   ;; Explicit prefix fallbacks.
   :prefix-fallbacks {"def"   [[:inner 0]]
                      "with-" [[:block 1]]}
   ;; Parser used for AST-preserving formatter checks.
   :parser           "eca.nfnl.fennel"
   ;; Files discovered by scan.
   :indents          {"deftest" [[:block 1]]
                      "testing" [[:block 1]]
                      "if"      [[:block 1]]}
   :format-as        {}
   :indent-patterns  []
   ;; All formatter alignment modes are explicit.
   :alignment        {:bindings         true
                      :maps             true
                      :clauses          true
                      :split-bindings   true
                      :collapse-padding true
                      :binding-forms    ["let" "when-let" "if-let" "with-open"]
                      :clause-forms     ["case" "match" "case-try" "match-try" "if"]}
 }
 :lint
 {:rules      {:forbidden-form      [{:severity   :off
                                                         :applies-to {}
                                                         :options    {:module "require"}
                                                         :exclusions []}]
                                  :binding-per-line    [{:severity   :warning
                                                         :applies-to {}
                                                         :options    {:forms ["let" "when-let" "if-let" "with-open"]}
                                                         :exclusions []}]
                                  :call-data-arg       [{:severity   :warning
                                                         :applies-to {:files ["^fennel-extras/"]}
                                                         :options    {:forms []}
                                                         :exclusions []}]
                                  :control-layout      [{:severity   :warning
                                                         :applies-to {}
                                                         :options    {:forms ["if" "when" "and" "or" "case" "match"]}
                                                         :exclusions []}]
                                  :core-require        [{:severity   :error
                                                         :applies-to {}
                                                         :options    {:module  "eca.nfnl.core"
                                                                      :binding "core"}
                                                         :exclusions []}]
                                  :defn-args-newline   [{:severity   :warning
                                                         :applies-to {}
                                                         :options    {:forms ["defn" "defn-"]}
                                                         :exclusions []}]
                                  :file-size           [{:severity   :warning
                                                         :applies-to {:files ["^fennel-extras/"]}
                                                         :options    {:max-code-lines 300}
                                                         :exclusions []}]
                                  :function-shape      [{:severity   :warning
                                                         :applies-to {}
                                                         :options    {:forms ["defn" "defn-" "fn" "lambda" "λ"]}
                                                         :exclusions []}]
                                  :if-branch-call      [{:severity   :warning
                                                         :applies-to {}
                                                         :options    {:forms ["if"]}
                                                         :exclusions []}]
                                  :if-without-else     [{:severity   :warning
                                                         :applies-to {}
                                                         :options    {:forms    ["if"]
                                                                      :nil-else true}
                                                         :exclusions []}]
                                  :module-style        [{:severity   :error
                                                         :applies-to {:files ["^fennel-extras/"]}
                                                         :options    {:module "eca.nfnl.macros.aniseed"
                                                                      :forms  ["module" "def" "defn" "defn-"]}
                                                         :exclusions []}]
                                  :multiline-layout    [{:severity   :warning
                                                         :applies-to {}
                                                         :options    {:clauses  ["case" "match" "case-try" "match-try"]
                                                                      :bindings ["let" "when-let" "if-let" "with-open"]}
                                                         :exclusions []}]
                                  :no-mutation         [{:severity   :warning
                                                         :applies-to {:files ["^fennel-extras/"]}
                                                         :options    {:forms ["var" "set" "while"]}
                                                         :exclusions []}]
                                  :one-is-per-testing  [{:severity   :error
                                                         :applies-to {}
                                                         :options    {:testing   "testing"
                                                                      :assertion "is"
                                                                      :count     1}
                                                         :exclusions []}]
                                  :spec-direct-require [{:severity   :error
                                                         :applies-to {:files ["^spec/"]}
                                                         :options    {:modules      ["plenary.busted" "luassert"]
                                                                      :exempt-files ["^spec/eca/macros[.]fnlm$"]}
                                                         :exclusions []}]
                                  :spec-macro-import   [{:severity   :error
                                                         :applies-to {:files ["^spec/"]}
                                                         :options    {:module       "spec.eca.macros"
                                                                      :forms        ["deftest" "testing" "is"]
                                                                      :exempt-files ["^spec/eca/macros[.]fnlm$"]}
                                                         :exclusions []}]
                                  :spec-no-module      [{:severity   :error
                                                         :applies-to {:files ["^spec/"]}
                                                         :options    {:module "module"}
                                                         :exclusions []}]
                                  :unused-and-or       [{:severity   :warning
                                                         :applies-to {}
                                                         :options    {:forms ["and" "or"]}
                                                         :exclusions []}]}}}
