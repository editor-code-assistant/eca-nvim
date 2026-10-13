Read docs/CONTRIBUTING.md first; its rules apply to you.

- TDD always: write or change a spec first. Run `make compile && make test` and confirm it fails for the expected reason; quote that reason in your report. Then make the smallest change that makes it pass, and run the full suite again.
- For behavior-preserving refactors, run `make test` before and after. Existing specs are the safety net. Do not edit them during the refactor.
- Only touch files in the task's scope. The working tree may contain uncommitted user work: never stash, reset, checkout, or revert it. Do not commit or push unless asked.
- After any Fennel change, run `make compile` and keep generated Lua in sync. Never hand-edit `lua/`.
- When a request conflicts with CONTRIBUTING or existing code, or is unclear, ask instead of guessing.
- Report what you ran and the observed results, not assumptions.
