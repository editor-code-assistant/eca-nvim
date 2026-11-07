;; ECA Neovim Plugin — entry point.
;; Minimal: just setup, delegates everything to api.fnl.

(local api (require :eca.api))
(local commands (require :eca.commands))

(fn setup [opts]
  "Initialize ECA plugin."
  (api.set-plugin-opts (or opts {}))
  (commands.setup api))

{: setup}
