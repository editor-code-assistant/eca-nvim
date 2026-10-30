# Contributing

## Setup and layout

- Fennel source lives in `fnl/`.
- Generated Lua lives in `lua/` and is committed. Files under `lua/**/*.lua` are marked `linguist-generated`.
- `lua/eca/nfnl/` is embedded nfnl. Update it with `scripts/nfnl`; do not edit it by hand.
- Specs live in `fnl/spec/` and compile to `lua/spec/`.
- The lint implementation entry point is `fnl/fennel-extras/lint.fnl`; its rule modules live under `fnl/fennel-extras/lint/rules/` and compile to the matching `lua/` paths.
- Never edit generated Lua by hand.

## Commands

- `make deps` clones plenary into `deps/`.
- `make compile` compiles the Fennel sources.
- `make check-compiled` checks that generated Lua is current.
- `make test` runs the specs.
- `make lint` runs fennel-ls diagnostics; it needs fennel-ls. Override the executable with `FENNEL_LS=/path` or the files with `LINT_FILES="a.fnl b.fnl"`. The unused-definition lint is disabled because fennel-ls cannot see exports registered by the aniseed `module`/`defn` macros.
- `make clean` removes `deps/`.

## Tooling setup

Install fennel-ls with Mason in Neovim or with `luarocks install fennel-ls 0.2.1-1`, the version used in CI. For a non-PATH install, set `FENNEL_LS=/path` (for example, Mason's `~/.local/share/nvim/mason/bin/fennel-ls`). `make lint` runs in CI and must pass.

Configure fennel-ls as the Fennel LSP through lspconfig; it reads project settings from `flsproject.fnl`.

### Formatting

- `make fmt` rewrites files. `make fmt-check` is used in CI: it exits 1 if a file would change and 2 on errors.
- Both commands run `scripts/fennel-extras` with `nvim --headless -l`; no extra formatter install is needed.
- Formatter configuration is data only in `.fnl-extras.fnl` at the repository root; never run this file. Dotfiles are skipped by default, and `.git` is always skipped.

The formatter uses an **explicit configuration contract**. There are no hidden defaults: omitted switches are off, and required values must be present. The repository's real configuration is the main example:

```fennel
{:workspace
 {:paths      ["fnl"]
  :exclude    ["fnl/eca/nfnl"]
  :extensions [".fnl" ".fnlm"]
  :dotfiles   false
  :symlinks   false}
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
  {:forbidden-form
   [{:severity   :off
     :applies-to {}
     :options    {}
     :exclusions []}
    {:severity   :error
     :applies-to {:files ["^spec/"]}
     :options    {:module "module"}
     :exclusions []}
    {:severity   :warning
     :applies-to {:files ["^fennel-extras/"]}
     :options    {:forms ["var" "set" "while"]}
     :exclusions []}]
   :call-data-arg
   [{:severity   :warning
     :applies-to {:files ["^fennel-extras/"]}
     :options    {:forms []}
     :exclusions []}]
   :control-layout
   [{:severity   :warning
     :applies-to {}
     :options    {:forms ["if" "when" "and" "or" "case" "match"]}
     :exclusions []}]
   :file-size
   [{:severity   :warning
     :applies-to {:files ["^fennel-extras/"]}
     :options    {:max-code-lines 300}
     :exclusions []}]
   :form-child-count
   [{:severity   :error
     :applies-to {:files ["^spec/"]
                  :forms ["testing"]}
     :options    {:children  ["is"]
                  :max-count 1}
     :exclusions []}]
   :module-import
   [{:severity   :error
     :applies-to {}
     :options    {:mode    :require
                  :module  "eca.nfnl.core"
                  :binding "core"}
     :exclusions []}
    {:severity   :error
     :applies-to {:files ["^spec/"]}
     :options    {:mode         :require
                  :module       "spec.eca.macros"
                  :forms        ["deftest" "testing" "is"]
                  :exempt-files ["^spec/eca/macros[.]fnlm$"]}
     :exclusions []}
    {:severity   :error
     :applies-to {:files ["^spec/"]}
     :options    {:mode         :forbid
                  :modules      ["plenary.busted" "luassert"]
                  :exempt-files ["^spec/eca/macros[.]fnlm$"]}
     :exclusions []}]
   :module-style
   [{:severity   :error
     :applies-to {:files ["^fennel-extras/"]}
     :options    {:module "eca.nfnl.macros.aniseed"
                  :forms  ["module" "def" "defn" "defn-"]}
     :exclusions []}]
   :multiline-layout
   [{:severity   :warning
     :applies-to {}
     :options    {:clauses  ["case" "match" "case-try" "match-try"]
                  :bindings ["let" "when-let" "if-let" "with-open"]}
     :exclusions []}]
   :required-form
   [{:severity   :error
     :applies-to {:files ["^fennel-extras/"]}
     :options    {:forms ["module"]}
     :exclusions []}]
   :unused-and-or
   [{:severity   :warning
     :applies-to {}
     :options    {:forms ["and" "or"]}
     :exclusions []}]}}}
```

The configuration has four root sections: `:workspace`, `:format`, `:lint`, and `:design`. Workspace scan settings belong under `:workspace`: `:paths`, `:exclude`, `:extensions`, `:dotfiles`, and `:symlinks`. `:lint` contains direct policy rules. Structural and idiomatic rules belong under `:design`, using the same rule-instance schema and finding/exclusion pipeline as lint. The moved design rules are `function-shape`, `if-branch-call`, `if-without-else`, and `no-mutation`; generic `nested-forms` and `leading-bindings` evaluators are also available there.

For example:

```fennel
:design {:rules {:function-shape [{:severity :warning
                                    :applies-to {}
                                    :options {:forms ["defn" "defn-" "fn" "lambda" "λ"]}
                                    :exclusions []}]}}
``` The old root-level `:skip-dotfiles` and `:follow-symlinks` aliases are not accepted. Paths in lint rule `:applies-to :files` selectors and exclusions are relative to the workspace path. The formatter's indentation rules are selected in this order: exact `:indents` > `:format-as` > `:indent-patterns` > `:builtins` > `:prefix-fallbacks` > no special rule. `:indents` maps exact form names to rules such as `[:block n]` or `[:inner 0 i]`; `:format-as` maps one form name to another; and `:indent-patterns` contains `[lua-pattern rule-list]` entries. `:indent-width`, `:builtins`, `:prefix-fallbacks`, and `:parser` are required configuration values under `:format`. Use `--parser` to override the configured parser.

By default, formatting changes leading indentation only. Alignment is separate and must be configured under `:alignment`; there is no legacy `:align-bindings` compatibility key. In this repository, the `if` rule gives bodies regular 2-space indentation; multiline `and`/`or` forms remain aligned under their first argument.

For editor use, run `make fmt` or `scripts/fennel-extras format --write <file>`.

Function declarations use one item per line for the declaration header and body:

```fennel
(defn- git-root
  [start]
  body...)
```

The argument vector must start below the name, with a docstring allowed between them. Keep the body on its own line as well.

### Project style lint

`make style` runs `scripts/fennel-extras lint` with no selection flag by default, checking all configured files without requiring Git. Set `STYLE_FLAGS=--changed` to check changed forms and files against `HEAD`, or `STYLE_FLAGS="--base <ref>"` to use another Git base. `--all` is an explicit alias for the no-selection mode; `--changed` and `--all` cannot be combined; `--all` and `--base` cannot be combined. Explicit paths restrict discovery in any mode. Add `--format json` for JSON Lines output.

Lint rules are configured under `:lint :rules`. The map is keyed by keyword identifiers such as `:file-size`; each value is a non-empty vector of rule instances. Every instance has the same four sibling keys: `:severity`, `:applies-to`, `:options`, and `:exclusions`. There is no severity shorthand. Enabled instances require their rule's typed options; disabled instances use `:severity :off` and still follow the instance shape. There are no hidden lint defaults.

The root `.fnl-extras.fnl` is the canonical configuration example. Its entries use the current shape:

```fennel
:lint {:rules {:file-size [{:severity :warning
                            :applies-to {:files ["^fennel-extras/"]}
                            :options {:max-code-lines 300}
                            :exclusions []}]}}
```

`:applies-to` is a positive selector map. It may contain only `:files`, `:forms`, and `:modules`; each selected collection narrows where that instance applies. Spec-only rules use explicit file selectors such as `{:files ["^spec/"]}`. Options are direct typed keys under `:options`. Do not add a nested `:flags` map or move option keys to the rule instance. Keep strings for paths, regular expressions, reasons, and module names; use the value types required by each option for other fields. Rule-specific `:forms`, `:module`, and `:modules` values belong under `:applies-to` and keep their original scalar, list, or empty value. These semantic selectors are matched literally and in list order; generic `:applies-to` selectors continue to use file/form/module matcher behavior. For example: `{:applies-to {:forms ["var" "set"] :modules "my.module"} :options {}}`. Old selector values under `:options` are rejected by configuration validation.

The lint rules are:

| Rule | Options |
| --- | --- |
| `forbidden-form` | `:module`, `:forms` |
| `required-form` | `:forms` |
| `module-style` | `:module`, `:forms` |
| `module-import` | `:mode` plus `:modules`, `:exempt-files` for `:forbid`, or `:module`, `:binding`, `:forms` for `:require` |
| `form-child-count` | `:children`, `:max-count` |
| `control-layout` | `:forms` |
| `unused-and-or` | `:forms` |
| `multiline-layout` | `:clauses`, `:bindings` |
| `file-size` | `:max-code-lines` |
| `call-data-arg` | `:forms` |

#### Design rule options

Design uses the same instance shape. Its structural rules are `function-shape` (`:forms`, optional `:max-depth`), `if-branch-call` (`:forms`), `if-without-else` (`:forms`, `:nil-else`), `no-mutation` (`:forms`), `nested-forms` (`:forms`, `:max-depth`), and `leading-bindings` (`:forms`).

#### Rule options

Put each rule's direct, typed options inside its instance. Required values are explicit; for example, the `file-size` instance in `.fnl-extras.fnl` uses `:max-code-lines 300`. `:max-code-lines` is not a top-level `:lint` option, and options must not be wrapped in `:flags`.

#### Exclusions

Exclusions are per instance, under that instance's `:exclusions` key. There is no top-level or global lint exclusion list. Each exclusion is a map with a string `:path` and string `:reason`; the path is matched against the workspace-relative path. An exclusion must match at least one finding in its instance's scope; otherwise it is stale and the command fails in that scope.

```fennel
:rules {:function-shape [{:severity :warning
                          :applies-to {:files ["^legacy/"]}
                          :options {:forms ["defn" "defn-" "fn" "lambda" "λ"]
                                    :max-depth 2}
                          :exclusions [{:path "^legacy/"
                                        :reason "migration in progress"}]}]}
```

#### `:path` matching

`:path` is a Vim regular expression searched against the workspace-relative path; it is not full-string matching. `:code` uses the same Vim regex semantics against the flagged form's source and is not valid for file-level findings. In Fennel config strings, double backslashes, for example `"\\d\\+"` for Vim's digit-plus pattern.

```fennel
{:path "^spec/"
 :reason "spec path"}
```

#### File selectors

Use `:applies-to :files` for path-specific rules. A file selector is a Vim regular expression matched against the workspace-relative path. There is no top-level `:lint :spec-files` setting.

```fennel
:applies-to {:files ["^spec/"]}
```

#### `:alignment`

`:alignment` is explicit. Omitted switches are off. When an alignment switch is enabled, its corresponding form list is required.

```fennel
:alignment {:bindings true
            :maps false
            :clauses true
            :split-bindings false
            :collapse-padding false
            :binding-forms ["let" "when-let" "if-let" "with-open"]
            :clause-forms ["case" "match" "case-try" "match-try" "if"]}
```

The boolean switches are `:bindings`, `:maps`, `:clauses`, `:split-bindings`, and `:collapse-padding`. `:binding-forms` and `:clause-forms` are required when their corresponding alignment modes are enabled. `:align-bindings` is not part of the configuration contract.

#### `:newline`

`:newline` is a list of formatter instances. Each instance has `:applies-to`, optionally selecting `:forms`, and `:options` with non-negative integer `:before`, `:after`, and/or `:after-header` counts. Omitted counts are zero. `:after-header` applies only to named `defn` and `defn-` forms and inserts blank lines after the declaration header line. Newline rules add blank lines without changing tokens or parsed forms.

```fennel
:newline [{:applies-to {:forms ["defn" "defn-"]}
           :options {:after 1}}
          {:applies-to {:forms ["testing"]}
           :options {:before 1}}]
```

`module-style` is a convert-on-touch rule. `--all` reports remaining legacy files.

Exit code 0 means no errors, 1 means an error or stale exclusion, and 2 means a command, configuration, Git, read, parse, or internal failure. The default and `--all` modes do not require Git; `--changed` and `--base` require a valid full Git clone and report Git errors with exit 2. Findings are written to stdout. CI runs `make style` on pull requests to `main`.

CI runs `make check-compiled`, `make fmt-check`, `make test`, and `make lint`. The test job uses this Neovim matrix:

- `v0.9.5`
- `v0.10.0`
- `v0.11.4`
- `v0.12.0`
- `nightly`

Always commit regenerated Lua together with the Fennel change.

## Module style

This is the **target style** for new modules. Use it for new modules, and move existing modules to it when you work on them. Most modules still use `fn` and a final export table. No big rewrite is needed.

```fennel
(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module eca.path.name)
```

Import `def` because `defn` needs it to compile.

Use `core` for nfnl core functions and plain `require` for other dependencies:

```fennel
(local core (require :eca.nfnl.core))
(local other (require :eca.path.other))
```

- Use `defn` for the public API.
- Use `defn-` for everything else.
- Export only what callers need.
- Prefer top-level functions that receive state explicitly. Avoid closures nested in a constructor that close over `var`s. The constructor, such as `create`, builds the state and returns thin wrappers.
- Use nfnl core functions such as `core.get` and `core.assoc` when they keep the same behavior. `(or x default)` is not the same as `core.get` with a default when the value can be `false`.
- Make each branch of an `if` one well-named function call. For example: `(if (lualine.plugin) (lualine.setup items) (set-native-statusline items))`. Move multi-step branch bodies into a named `defn-`.

The footer bar is a reference example:

```fennel
(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module eca.ui.widgets.footer-bar)

(local core (require :eca.nfnl.core))
(local bar-items (require :eca.ui.components.bar-items))
(local lualine (require :eca.ui.components.lualine))

(defn- set-native-statusline [items]
  (vim.api.nvim_set_option_value :statusline (bar-items.render {: items}) {}))

(defn- apply [items]
  (if (lualine.plugin)
      (lualine.setup items)
      (set-native-statusline items)))
```

## Tests

Specs use plenary busted and luassert through the project macros in `fnl/spec/eca/macros.fnlm`. It is the only file that references the test and assertion libraries, so they can be swapped later.

```fennel
(import-macros {: deftest : testing : is} :spec.eca.macros)
```

Specs do not require `plenary.busted` or `luassert` directly.

- `deftest` takes a symbol name and groups tests.
- `testing` is one test with a description.
- `is` asserts.

The `is` forms are:

- `(= expected actual)` checks deep equality.
- `(not= expected actual)` checks that values differ.
- `(identical? expected actual)` checks that values are the same object.
- `(nil? x)` checks that `x` is nil.
- Any other expression must be truthy.

An optional message can be the last argument. Operands are evaluated once.

Write one `testing` per `is`. Make the description say what the `is` checks.

- Write unit tests for function behavior. Don't test module shape, such as which names a module exports.
- Don't write tests that only check that a function exists when other tests already call it.
- A test may take the widget straight from a helper such as `with-footer-bar` when it only calls functions that read state (like `get-state`). When a test needs calls that use dependencies (lualine, vim.api, ...), make them inside a scenario helper and return plain data.

The preferred pattern for new specs is to use `defn-` scenario helpers. They set up mocks, run the scenario, clean up, and return plain data. The `is` then runs on that data. Wrapping helpers such as `with-footer-bar` directly inside `testing` is allowed, but prefer scenario helpers because they read better.

Helpers use `defn-`:

```fennel
(import-macros {: defn-} :eca.nfnl.macros.aniseed)
```

Do not use `(module ...)` in specs.

- Mock dependencies through `package.loaded` and reload the module under test.
- Restore global state in a helper that uses `pcall`, so cleanup runs even when a test fails.
- The spec path mirrors the source path and adds `_spec.fnl`. For example, `fnl/eca/ui/widgets/footer-bar.fnl` uses `fnl/spec/eca/ui/widgets/footer-bar_spec.fnl`.
- Test through the public API. Cover private functions through that API.
- Do not weaken or delete tests to make them pass. Remove a test only when the public behavior it covers was intentionally changed, or when it checks module shape rather than function behavior.

For example:

```fennel
(defn- lualine-render-scenario []
  (let [items [{:value :one}]
        captured {:value nil}]
    (with-footer-bar {:lualine {:plugin (fn [] true)
                                :setup (fn [new-items] (tset captured :value new-items))}
                      :bar-items {:render (fn [_] (error "bar-items.render should not be called"))}}
      (fn [footer-bar]
        (let [widget (footer-bar.create 1 2 items)]
          {:result (widget.render) :captured (. captured :value)})))))

(deftest render
  (testing "returns zero"
    (is (= 0 (. (lualine-render-scenario) :result))))
  (testing "passes the items to lualine.setup when lualine is available"
    (is (= [{:value :one}] (. (lualine-render-scenario) :captured))))
  (testing "sets the native statusline from bar-items when lualine is unavailable"
    (is (= {:rendered {:items [{:value :two}]}
            :option [:statusline :rendered {}]}
           (native-render-scenario)))))
```


## Commits and PRs

Use short, lowercase, verb-led subjects like the existing history:

- `add lualine component and spec`
- `fix stream tick`

Keep each change focused. Run `make check-compiled` and `make test` before opening a PR.
