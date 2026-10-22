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
- Formatter configuration is data only in `.fnl-extras.fnl` at the repository root; never run this file. Dotfiles are skipped by default, and `.git` is always skipped. The keys are:
  - `:indents` (default `{}`): exact form-name to rule-list map. Rules are `[:block n]` or `[:inner 0 i]`; argument indexes start at 0.
  - `:format-as` (default `{}`): exact form-name to form-name map. The source form uses the target form's rule.
  - `:indent-patterns` (default `[]`): list of `[lua-pattern rule-list]` entries.
  - `:paths` (default `["."]`): list of file or directory paths to scan.
  - `:exclude` (default `[]`): list of path prefixes to skip. `.git` is skipped even when it is not listed.
  - `:indent-width` (default `2`): positive integer used for continuation indentation.
  - `:align-bindings` (default `false`): boolean. When true, split multi-pair `let`/`when-let`/`if-let`/`with-open` binding vectors one pair per line before aligning supported binding/key pairs and clauses.
  - `:builtins` (default `true`): `true`, `false`, or a map of form names to rule lists. Built-ins include rules for forms such as `fn`, `let`, `when`, and `do`.
  - `:prefix-fallbacks` (default `{"def" [[:inner 0]] "with-" [[:block 1]]}`): `false` or a map of prefixes to rule lists. The built-in prefixes are `def` and `with-`.
  - `:extensions` (default `[".fnl" ".fnlm"]`): non-empty list of strings, each starting with `.`.
  - `:skip-dotfiles` (default `true`): boolean. When true, skip dotfiles and dot-directories during scans. The discovered `.fnl-extras.fnl` config file is never formatted, even when this is `false`.
  - `:follow-symlinks` (default `false`): boolean. When true, follow links, write to the real target, and process each real path once.
  - `:parser` (default none): string module name for the parser. The `--parser` flag overrides this setting.

Indentation rules are selected in this order: exact `:indents` > `:format-as` > `:indent-patterns` > built-ins > prefix fallbacks > default. The default is no special rule. By default, the formatter only changes leading indentation; with `:align-bindings true`, it also normalizes whitespace between names or keys and values and splits supported multi-pair binding vectors across lines.

For example, the repository configuration contains:

```fennel
{:indents {"deftest" [[:block 1]]
           "testing" [[:block 1]]
           "if" [[:block 1]]}
 :parser "eca.nfnl.fennel"
 :paths ["fnl"]
 :exclude ["fnl/eca/nfnl"]}
```

To add a rule for a new macro, add one line such as `"deftest" [[:block 1]]` under `:indents`. In this repository, the `if` rule gives bodies regular 2-space indentation; multiline `and`/`or` forms remain aligned under their first argument.

For editor use, run `make fmt` or `scripts/fennel-extras format --write <file>`. An LSP integration will come later.

Function declarations use one item per line for the declaration header and body:

```fennel
(defn- git-root
  [start]
  body...)
```

The argument vector must start below the name, with a docstring allowed between them. Keep the body on its own line as well.

### Project style lint

`make style` runs `scripts/fennel-extras lint` with no selection flag by default, checking all configured files without requiring Git. Set `STYLE_FLAGS=--changed` to check changed forms and files against `HEAD`, or `STYLE_FLAGS="--base <ref>"` to use another Git base. `--all` is an explicit alias for the no-selection mode; `--changed` and `--all` cannot be combined; `--all` and `--base` cannot be combined. Explicit paths restrict discovery in any mode. Add `--format json` for JSON Lines output.

Lint rules are off by default. Enable them under `:lint :rules`. A rule can use a severity shorthand (`:warning`, `:error`, or `:off`) or a map with `:severity`, `:options`, and `:exclusions`. If any rule override is present, unspecified rules use the compatibility severities; set them to `:off` when needed.

The seventeen rules are:

| Rule | Default `:applies-to` | Options (type; default) |
| --- | --- | --- |
| `module-style` | `source` | `:macro-module` (string; `"eca.nfnl.macros.aniseed"`), `:required-macros` (strings; `["module" "def" "defn" "defn-"]`) |
| `spec-macro-import` | `spec` | `:macro-module` (string; `"spec.eca.macros"`), `:required-macros` (strings; `["deftest" "testing" "is"]`), `:exempt-files` (strings; `["^fnl/spec/eca/macros[.]fnlm$"]`) |
| `spec-no-module` | `spec` | `:module-form` (string; `"module"`) |
| `spec-direct-require` | `spec` | `:forbidden-modules` (strings; `["plenary.busted" "luassert"]`), `:exempt-files` (strings; `["^fnl/spec/eca/macros[.]fnlm$"]`) |
| `one-is-per-testing` | `all` | `:testing-form` (string; `"testing"`), `:assertion-form` (string; `"is"`), `:count` (positive integer; `1`) |
| `if-branch-call` | `all` | `:if-forms` (strings; `["if"]`) |
| `if-without-else` | `all` | `:if-forms` (strings; `["if"]`), `:flag-nil-else` (boolean; `true`) |
| `control-layout` | `all` | `:control-forms` (strings; `["if" "when" "and" "or" "case" "match"]`) |
| `unused-and-or` | `all` | `:forms` (strings; `["and" "or"]`) |
| `defn-args-newline` | `all` | `:forms` (strings; `["defn" "defn-"]`) |
| `function-shape` | `all` | `:function-forms` (strings; `["defn" "defn-" "fn" "lambda" "λ"]`) |
| `no-mutation` | `source` | `:forms` (strings; `["var" "set" "while"]`) |
| `multiline-layout` | `all` | `:clause-forms` (strings; `["case" "match" "case-try" "match-try"]`), `:binding-forms` (strings; `["let" "when-let" "if-let" "with-open"]`) |
| `file-size` | `source` | `:max-code-lines` (positive integer; `300`) |
| `core-require` | `all` | `:module` (string; `"eca.nfnl.core"`), `:binding` (string; `"core"`) |
| `binding-per-line` | `all` | `:forms` (strings; `["let" "when-let" "if-let" "with-open"]`) |
| `call-data-arg` | `source` | `:ignore-forms` (strings; `[]`) |

`module-style` is a convert-on-touch rule. `--all` reports remaining legacy files. `:max-code-lines` is an alias for the `file-size` option. The top-level `:lint :max-code-lines` defaults to `300`; it conflicts with a different `file-size` `:max-code-lines`. `:lint :spec-files` defaults to `["^fnl/spec/"]` and is a list of strings.

Exclusions can be per-rule, inside that rule's entry, or general under `:lint :exclusions`. A general exclusion with no `:rule` or `:rules` selects all rules. Selectors are `:pattern` (Vim regex on the repository-relative path), `:line`, `:lines {:from :to}`, `:code` (Vim regex on the flagged form's source; not for file-level findings), or legacy exact `:form`. Add optional `:reason`; it is not required. Selectors combine with AND. `:rule` and `:rules` are mutually exclusive. A stale exclusion is an error when its file is in scope; `--changed` and `--base` only check exclusions in their scope. An exclusion for a disabled rule reports that the rule is disabled.

Exclusion patterns use Vim regex search semantics, not full-string matching. In Fennel config strings, double the backslashes, for example `"\\d\\+"` for Vim's digit-plus pattern.

Formatter alignment is configured by `:alignment`:

| Key | Type | Default |
| --- | --- | --- |
| `:bindings` | boolean | `false` |
| `:maps` | boolean | `false` |
| `:clauses` | boolean | `false` |
| `:split-bindings` | boolean | `false` |
| `:collapse-padding` | boolean | `false` |
| `:binding-forms` | list of strings | `["let" "when-let" "if-let" "with-open"]` |
| `:clause-forms` | list of strings | `["case" "match" "case-try" "match-try" "if"]` |

The legacy `:align-bindings true` shorthand enables all five boolean switches. Explicit `:alignment` keys override the shorthand. `:align-bindings` defaults to `false`.

Complete example (the `:lint` and `:alignment` additions marked illustrative are examples):

```fennel
{:indents {"deftest" [[:block 1]]
           "testing" [[:block 1]]
           "if" [[:block 1]]}
 :parser "eca.nfnl.fennel"
 :paths ["fnl"]
 :exclude ["fnl/eca/nfnl"]
 ;; illustrative lint configuration
 :lint {:rules {:module-style :error
                :file-size {:severity :warning
                            :options {:max-code-lines 350}
                            :exclusions [{:pattern "^fnl/generated/"
                                          :reason "generated source"}]}}
        :exclusions [{:rule :function-shape
                      :pattern "^fnl/legacy/"
                      :reason "migration in progress"}]
        :spec-files ["^fnl/spec/"]}
 ;; illustrative formatter options
 :alignment {:maps true
             :split-bindings true}}
```

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
