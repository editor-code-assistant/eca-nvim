;; commands — Vim user commands for ECA.
;; Users map keymaps to these commands in their own config.

(local api (require :eca.api))

(fn setup [chat-ui]
  "Register all :Eca* user commands."
  (api.create-user-command "EcaChat"
    (fn [] (chat-ui.toggle))
    {:desc "Toggle ECA Chat window"})

  (api.create-user-command "EcaChatOpen"
    (fn [] (chat-ui.open))
    {:desc "Open ECA Chat window"})

  (api.create-user-command "EcaChatClose"
    (fn [] (chat-ui.close))
    {:desc "Close ECA Chat window"})

  (api.create-user-command "EcaChatClear"
    (fn [] (chat-ui.clear-messages))
    {:desc "Clear ECA Chat messages"})

  (api.create-user-command "EcaChatNew"
    (fn [] (chat-ui.clear-messages))
    {:desc "Start a new ECA Chat"})

  (api.create-user-command "EcaChatSubmit"
    (fn [] (chat-ui.submit-prompt))
    {:desc "Submit current prompt"})

  (api.create-user-command "EcaChatStop"
    (fn [] (chat-ui.set-loading false))
    {:desc "Stop current ECA response"}))

{: setup}
