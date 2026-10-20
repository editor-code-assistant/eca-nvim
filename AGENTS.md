Read docs/CONTRIBUTING.md first; its rules apply to you.

- TDD always: write or change a spec first. Run `make compile && make test` and confirm it fails for the expected reason; quote that reason in your report. Then make the smallest change that makes it pass, and run the full suite again.
- For behavior-preserving refactors, run `make test` before and after. Existing specs are the safety net. Do not edit them during the refactor.
- Only touch files in the task's scope. The working tree may contain uncommitted user work: never stash, reset, checkout, or revert it. Do not commit or push unless asked.
- After any Fennel change, run `make compile`, `make test`, `make lint`, and `make style`; run `make fmt` (or check with `make fmt-check`) too. Keep generated Lua in sync and report lint findings. Never hand-edit `lua/`. Pre-existing findings in untouched files are not your task unless asked, but do not add new ones.
- The `if-without-else` rule (warning) flags `(if test then)` and `(if test then nil)`; use `when` instead.
- The `control-layout` rule (warning) requires control forms to span several lines only when they are the sole expression of a body.
- The `unused-and-or` rule (warning) requires discarded `and`/`or` results in statement bodies to use `when`.
- The `multiline-layout` rule (warning) requires list heads and first arguments on the head line; `do` forms are exempt, and `defn`/`defn-` names remain on the head line.
- The `defn-args-newline` rule (warning) requires `defn` and `defn-` argument vectors to start on the line below the function name; a docstring may appear between them.
- The `no-mutation` rule (warning, source files only) flags `var`, `set`, and `while`; prefer returning new values instead.
- The `function-shape` rule (warning) applies to `defn`, `defn-`, `fn`, `lambda`, and `λ` bodies: use an optional first `let` with leaf values, then leaf or one-layer expressions; move deeper code into named private functions.
- The `file-size` rule (warning) limits source files to `:max-code-lines` code lines; the default is 300 and the value must be a positive integer.
- Lint rule implementation is split between `fnl/fennel-extras/lint/rules.fnl` and cohesive modules under `fnl/fennel-extras/lint/rules/`; keep generated Lua in the matching `lua/` paths.
- Formatter option `:align-bindings` defaults to `false`; when enabled it aligns supported binding/key pairs and one pattern/test → result clause pair per line in `case`, `match`, `case-try`, `match-try`, and multi-clause `if`; enable it only in task-specific or temporary configs unless explicitly requested.
- In this repository, `.fnl-extras.fnl` configures `if` with `[[:block 1]]`, so `if` bodies use regular 2-space indentation while multiline `and`/`or` forms keep their existing alignment.
- `scripts/fennel-extras lint` checks all configured files by default and with `--all`; use `--changed` or `--base REF` for Git-based selection. The default/all modes do not require Git, while changed/base modes do. `--changed --all` and `--all --base REF` are usage errors (exit 2).
- When a request conflicts with CONTRIBUTING or existing code, or is unclear, ask instead of guessing.
- Report what you ran and the observed results, not assumptions.
