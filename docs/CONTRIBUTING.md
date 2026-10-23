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
```

The formatter's indentation rules are selected in this order: exact `:indents` > `:format-as` > `:indent-patterns` > `:builtins` > `:prefix-fallbacks` > no special rule. `:indents` maps exact form names to rules such as `[:block n]` or `[:inner 0 i]`; `:format-as` maps one form name to another; and `:indent-patterns` contains `[lua-pattern rule-list]` entries. `:paths`, `:exclude`, `:extensions`, `:skip-dotfiles`, and `:follow-symlinks` control discovery. `:indent-width`, `:builtins`, `:prefix-fallbacks`, and `:parser` are required configuration values. Use `--parser` to override the configured parser.

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

Lint rules are opt-in under `:lint :rules`. A rule can use a severity shorthand (`:warning`, `:error`, or `:off`) or a map with explicit `:severity`, `:options`, and optional `:exclusions`. Enabled rules require explicit option values, including `:applies-to`; disabled rules do not require options. The `:lint :spec-files` list is also required. There are no hidden lint defaults.

The seventeen rules are:

| Rule | Options |
| --- | --- |
| `module-style` | `:macro-module`, `:required-macros` |
| `spec-macro-import` | `:macro-module`, `:required-macros`, `:exempt-files` |
| `spec-no-module` | `:module-form` |
| `spec-direct-require` | `:forbidden-modules`, `:exempt-files` |
| `one-is-per-testing` | `:testing-form`, `:assertion-form`, `:count` |
| `if-branch-call` | `:if-forms` |
| `if-without-else` | `:if-forms`, `:flag-nil-else` |
| `control-layout` | `:control-forms` |
| `unused-and-or` | `:forms` |
| `defn-args-newline` | `:forms` |
| `function-shape` | `:function-forms` |
| `no-mutation` | `:forms` |
| `multiline-layout` | `:clause-forms`, `:binding-forms` |
| `file-size` | `:max-code-lines` |
| `core-require` | `:module`, `:binding` |
| `binding-per-line` | `:forms` |
| `call-data-arg` | `:ignore-forms` |

#### Rule options

Put options inside the rule entry. Values are required; for example:

```fennel
:rules {"file-size" {:severity :warning
                      :options {:applies-to "source"
                                :max-code-lines 300}}}
```

`:max-code-lines` is only the `file-size` rule option. Top-level `:lint :max-code-lines` is not accepted.

#### Exclusions

Exclusions can be per-rule, inside that rule's entry, or general under `:lint :exclusions`. A general exclusion with no `:rule` or `:rules` selects all rules. `:rule` and `:rules` are mutually exclusive. Selectors combine with AND. An exclusion must match at least one finding; otherwise it is stale and the command fails in the applicable scope. An exclusion for a disabled rule is also an error.

```fennel
:lint {:rules {"function-shape" {:severity :warning
                                  :options {:applies-to "all"
                                            :function-forms ["defn" "defn-" "fn" "lambda" "λ"]}
                                  :exclusions [{:pattern "^fnl/legacy/"
                                                :reason "migration in progress"}]}}
       :exclusions [{:rule :file-size
                     :pattern "^fnl/generated/"
                     :reason "generated source"}]}
```

#### `:pattern` matching

`:pattern` is a Vim regular expression searched against the repository-relative path; it is not full-string matching. `:code` uses the same Vim regex semantics against the flagged form's source and is not valid for file-level findings. In Fennel config strings, double backslashes, for example `"\\d\\+"` for Vim's digit-plus pattern.

```fennel
{:pattern "^fnl/spec/"}
```

#### `:spec-files`

`:lint :spec-files` is a required list of strings. Each entry is a Vim regular expression used to classify spec files.

```fennel
:lint {:spec-files ["^fnl/spec/"]}
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
