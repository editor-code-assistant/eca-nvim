;; commands — Vim user commands for ECA.
;; Uses the public chat API from api.fnl.

(local nvim vim.api)

(fn setup [api]
  "Register all :Eca* user commands."
  (nvim.nvim_create_user_command "EcaChat"
    (fn [] (api.chat-toggle))
    {:desc "Toggle ECA Chat window"})

  (nvim.nvim_create_user_command "EcaChatOpen"
    (fn [] (api.chat-open))
    {:desc "Open ECA Chat window"})

  (nvim.nvim_create_user_command "EcaChatClose"
    (fn [] (api.chat-close))
    {:desc "Close ECA Chat window"})

  (nvim.nvim_create_user_command "EcaChatClear"
    (fn [] (api.chat-clear))
    {:desc "Clear current chat messages"})

  (nvim.nvim_create_user_command "EcaChatNew"
    (fn [] (api.chat-open))
    {:desc "Open a new ECA Chat"})

  (nvim.nvim_create_user_command "EcaChatSubmit"
    (fn [] (api.chat-submit))
    {:desc "Submit current prompt"})

  (nvim.nvim_create_user_command "EcaChatStop"
    (fn [] (api.chat-set-status nil))
    {:desc "Stop current ECA response"})

  (nvim.nvim_create_user_command "EcaChatSetModel"
    (fn [cmd]
      (when (and cmd.args (not= "" cmd.args))
        (api.chat-set-model cmd.args)))
    {:desc "Set the model" :nargs 1}))

{: setup}
