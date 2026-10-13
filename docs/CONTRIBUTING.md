# Contributing

## Setup and layout

- Fennel source lives in `fnl/`.
- Generated Lua lives in `lua/` and is committed. Files under `lua/**/*.lua` are marked `linguist-generated`.
- `lua/eca/nfnl/` is embedded nfnl. Update it with `scripts/nfnl`; do not edit it by hand.
- Specs live in `fnl/spec/` and compile to `lua/spec/`.
- Never edit generated Lua by hand.

## Commands

- `make deps` clones plenary into `deps/`.
- `make compile` compiles the Fennel sources.
- `make check-compiled` checks that generated Lua is current.
- `make test` runs the specs.
- `make lint` runs fennel-ls diagnostics; it needs fennel-ls. Override the executable with `FENNEL_LS=/path` or the files with `LINT_FILES="a.fnl b.fnl"`. It is not run in CI yet.
- `make clean` removes `deps/`.

CI runs `make check-compiled` and `make test`. The test job uses this Neovim matrix:

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
