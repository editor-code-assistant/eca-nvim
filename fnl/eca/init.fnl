;; ECA Neovim Plugin — entry point.
;; setup(opts) initializes everything and registers :Eca* commands.

(local api (require :eca.api))
(local builder (require :eca.ui.builder))
(local commands (require :eca.commands))

(var chat-ui nil)

(fn default-on-submit [text]
  "Default submit handler — echoes prompt as user message + mock assistant reply."
  (when chat-ui
    (chat-ui.append-message
      {:id (tostring (os.time))
       :role :user
       :content text})
    (chat-ui.set-loading true)
    (api.defer
      (fn []
        (when chat-ui
          (chat-ui.append-message
            {:id (.. "reply-" (tostring (os.time)))
             :role :assistant
             :content (.. "You said: " text "\n\n(This is a mock response — connect ECA server for real responses)")})
          (chat-ui.set-loading false)))
      500)))

(fn setup [opts]
  "Initialize ECA plugin.
   opts: {: ui {: width : position} : on-submit}"
  (let [user-opts (or opts {})]

    ;; Create chat UI via builder with injected api
    (set chat-ui
      (builder.create-chat-ui
        {:api api
         :on-submit (or user-opts.on-submit default-on-submit)
         :opts {:ui (or user-opts.ui {})}}))

    ;; Register commands — users map their own keymaps to these
    (commands.setup chat-ui)))

{: setup}
