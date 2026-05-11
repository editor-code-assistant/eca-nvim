;; ECA API — chat registry + public functions.
;; Commands and external consumers use this module.

(local self {})
(local chats {})
(var plugin-opts {})

;; ── Chat registry ───────────────────────────────────────

(fn self.resolve-chat []
  "Find the chat for the current buffer, or any open chat."
  (let [current (. chats (vim.api.nvim_get_current_buf))]
    (or current
        (do (var found nil)
            (each [_ chat (pairs chats)]
              (when (and (not found) (chat.is-open?))
                (set found chat)))
            found))))

(fn self.register-chat [chat]
  (let [buf-id (chat.get-buf-id)]
    (when buf-id
      (tset chats buf-id chat))))

;; ── Chat public API ─────────────────────────────────────

(fn self.chat-open []
  (let [existing (self.resolve-chat)]
    (when (not (and existing (existing.is-open?)))
      (let [builder (require :eca.ui.builder)
            chat-ui (builder.create-chat-ui
                      {:on-submit (or plugin-opts.on-submit self.default-on-submit)
                       :opts {:ui (or plugin-opts.ui {})
                              :keymaps (or plugin-opts.keymaps
                                           [{:mode :i :lhs "<C-s>" :rhs "<cmd>EcaChatSubmit<CR>"}
                                            {:mode :n :lhs "<CR>" :rhs "<cmd>EcaChatSubmit<CR>"}])}})]
        (chat-ui.open)
        (self.register-chat chat-ui)
        ;; Mock server data
        (chat-ui.set-welcome "Welcome to ECA Chat")
        (chat-ui.update-header [{:title "model" :value "claude"}
                                {:title "behavior" :value "agent"}])
        (chat-ui.update-footer [{:value "ECA Chat"}
                                {:title "tokens" :value "0/200K"}])))))

(fn self.chat-close []
  (let [chat (self.resolve-chat)]
    (when chat (chat.close))))

(fn self.chat-toggle []
  (let [chat (self.resolve-chat)]
    (if (and chat (chat.is-open?))
      (chat.close)
      (self.chat-open))))

(fn self.chat-submit []
  (let [chat (self.resolve-chat)]
    (when chat (chat.submit-prompt))))

(fn self.chat-clear []
  (let [chat (self.resolve-chat)]
    (when chat (chat.clear-messages))))

(fn self.chat-set-model [model]
  (let [chat (self.resolve-chat)]
    (when chat (chat.update-header-item "model" model))))

(fn self.chat-set-loading [bool]
  (let [chat (self.resolve-chat)]
    (when chat (chat.set-loading bool))))

(fn self.default-on-submit [text]
  (let [chat (self.resolve-chat)]
    (when chat
      (chat.append-message
        {:id (tostring (os.time))
         :content text
         :prefix "> "})
      (chat.set-loading true)
      (vim.defer_fn
        (fn []
          (when (chat.is-open?)
            (chat.append-message
              {:id (.. "reply-" (tostring (os.time)))
               :content (.. "You said: " text "\n\n(This is a mock response)")})
            (chat.set-loading false)))
        500))))

(fn self.set-plugin-opts [opts]
  (set plugin-opts (or opts {})))

self
