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
                       :on-stop (or plugin-opts.on-stop self.default-on-stop)
                       :opts {:ui (or plugin-opts.ui {})
                              :keymaps (or plugin-opts.keymaps
                                           [{:mode :i :lhs "<C-s>" :rhs "<cmd>EcaChatSubmit<CR>"}
                                            {:mode :n :lhs "<CR>" :rhs "<cmd>EcaChatSubmit<CR>"}])}})]
        (chat-ui.open)
        (self.register-chat chat-ui)
        ;; Mock server data
        (chat-ui.set-welcome "Welcome to ECA Chat")
        (chat-ui.update-header [{:title "model" :value "claude/opus-4.6"}
                                {:title "agent" :value "code"}
                                {:title "variant" :value "-"}
                                {:title "mcps" :value "1"}])
        (chat-ui.update-footer [{:value "~/dev/eca-nvim"}
                                {:value "⏱ 0s"}
                                {:value "0/200K ($0.00)"}])
        ;; Mock context
        (chat-ui.add-context {:text "@cursor(README.md 3:1)" :hl-group :EcaContextCursor})))))

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

(fn self.chat-stop []
  "Stop everything: streaming, loading, status, steering."
  (let [chat (self.resolve-chat)]
    (when chat (chat.stop))))

(fn self.chat-cancel-steering []
  "Cancel queued steering only."
  (let [chat (self.resolve-chat)]
    (when chat (chat.cancel-steering))))

(fn self.chat-set-status [text]
  "Set status indicator. nil to hide."
  (let [chat (self.resolve-chat)]
    (when chat (chat.set-status text))))

(fn self.default-on-submit [text]
  (let [chat (self.resolve-chat)]
    (when chat
      ;; Show user message
      (chat.append-message
        {:id (tostring (os.time))
         :content text
         :collapsed? true
         :collapse-prefix "▸ "})
      ;; Set loading + status
      (chat.set-loading true)
      (chat.set-status "Generating")
      ;; Simulate streaming
      (let [reply-id (.. "reply-" (tostring (os.time)))
            full-text (.. "You said: " text "\n\n(This is a mock streaming response)")
            chunks []
            chunk-size 3]
        (var i 1)
        (while (<= i (length full-text))
          (let [end-idx (math.min (+ i chunk-size -1) (length full-text))]
            (table.insert chunks (string.sub full-text i end-idx))
            (set i (+ end-idx 1))))
        (vim.defer_fn
          (fn []
            (when (chat.is-open?)
              (chat.append-message
                {:id reply-id :content "" :streaming? true})
              (var accumulated "")
              (var delay 0)
              (each [_ chunk (ipairs chunks)]
                (set delay (+ delay 50))
                (let [content-at-send (.. accumulated chunk)]
                  (set accumulated content-at-send)
                  (vim.defer_fn
                    (fn []
                      (when (chat.is-open?)
                        (chat.update-message reply-id content-at-send)))
                    delay)))
              (vim.defer_fn
                (fn []
                  (when (chat.is-open?)
                    (chat.finish-streaming reply-id)
                    (chat.set-loading false)
                    (chat.set-status nil)))
                (+ delay 100))))
          300)))))

(fn self.default-on-stop []
  "Default stop handler — stops streaming and clears loading state."
  (let [chat (self.resolve-chat)]
    (when chat
      (chat.set-loading false)
      (chat.set-status nil))))

(fn self.set-plugin-opts [opts]
  (set plugin-opts (or opts {})))

self
