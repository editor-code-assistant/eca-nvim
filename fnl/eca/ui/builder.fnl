;; builder — orchestrates widgets, manages chat UI lifecycle.

(local nvim vim.api)
(local highlights (require :eca.ui.highlights))
(local header-bar-widget (require :eca.ui.widgets.header-bar))
(local message-list-widget (require :eca.ui.widgets.message-list))
(local context-area-widget (require :eca.ui.widgets.context-area))
(local steering-area-widget (require :eca.ui.widgets.steering-area))
(local prompt-area-widget (require :eca.ui.widgets.prompt-area))
(local footer-bar-widget (require :eca.ui.widgets.footer-bar))

(fn setup-chat-buffer [buf]
  (nvim.nvim_buf_set_name buf "ECA Chat")
  (nvim.nvim_set_option_value :buftype :nofile {: buf})
  (nvim.nvim_set_option_value :bufhidden :hide {: buf})
  (nvim.nvim_set_option_value :swapfile false {: buf})
  (nvim.nvim_set_option_value :filetype :eca-chat {: buf}))

(fn setup-chat-window [win]
  (nvim.nvim_set_option_value :number false {: win})
  (nvim.nvim_set_option_value :relativenumber false {: win})
  (nvim.nvim_set_option_value :signcolumn :no {: win})
  (nvim.nvim_set_option_value :foldcolumn :0 {: win})
  (nvim.nvim_set_option_value :numberwidth 1 {: win})
  (nvim.nvim_set_option_value :statuscolumn "" {: win})
  (nvim.nvim_set_option_value :spell false {: win})
  (nvim.nvim_set_option_value :list false {: win})
  (nvim.nvim_set_option_value :wrap true {: win})
  (nvim.nvim_set_option_value :linebreak true {: win})
  (nvim.nvim_set_option_value :conceallevel 2 {: win}))

;; ── Edit guard ──────────────────────────────────────────

(fn setup-edit-guard [buf-id render-all-fn get-prompt-state focus-prompt-fn]
  (var internal-edit false)

  (fn salvage-user-text [buf prompt-line]
    "Read user text from the prompt line, stripping prefix.
     If the line no longer starts with '> ', the prompt was deleted — return empty."
    (let [current-count (nvim.nvim_buf_line_count buf)
          idx (math.min prompt-line (- current-count 1))
          lines (nvim.nvim_buf_get_lines buf idx (+ idx 1) false)
          last-line (or (. lines 1) "")]
      (if (vim.startswith last-line "> ")
          [(string.sub last-line 3)]
          [""])))

  (fn restore-with-user-text [buf user-lines]
    (set internal-edit true)
    (render-all-fn)
    (let [new-count (nvim.nvim_buf_line_count buf)
          new-last-idx (- new-count 1)
          restored (icollect [i line (ipairs user-lines)]
                     (if (= i 1) (.. "> " line) line))]
      (when (> (length restored) 0)
        (nvim.nvim_buf_set_lines buf new-last-idx new-count false restored)
        ;; Re-apply prefix highlight
        (let [ns (nvim.nvim_create_namespace :eca-prompt-restore)]
          (nvim.nvim_buf_set_extmark buf ns new-last-idx 0
                                     {:end_col 2 :hl_group :EcaPromptPrefix}))))
    (set internal-edit false)
    (when focus-prompt-fn (focus-prompt-fn)))

  (fn on-lines-handler [_ buf changedtick first-line last-line new-last-line]
    (when (not internal-edit)
      (let [prompt-state (get-prompt-state)
            prompt-line (or prompt-state.prompt-start-line 0)
            lines-deleted? (> last-line new-last-line) ;; Damaged if:
            ;; 1. edit is before the prompt (chat history touched), OR
            ;; 2. edit touches the prompt area AND lines were deleted (e.g. dd)
            damaged? (or (< first-line prompt-line)
                         (and (<= first-line prompt-line) lines-deleted?))]
        (when damaged?
          (vim.schedule (fn []
                          (when (nvim.nvim_buf_is_valid buf)
                            (let [user-lines (salvage-user-text buf prompt-line)]
                              (restore-with-user-text buf user-lines)))))))))

  (nvim.nvim_buf_attach buf-id false {:on_lines on-lines-handler})

  (fn set-internal [bool] (set internal-edit bool))

  (fn update-expected-count [] nil)

  {: set-internal : update-expected-count})

;; ── Main entry ──────────────────────────────────────────

(fn create-chat-ui [{: on-submit : on-stop : opts}]
  (let [ui-config (or opts.ui {})
        config {:width (or ui-config.width 0.4)
                :position (or ui-config.position :right)
                :keymaps (or opts.keymaps [])}]
    ;; Mutable state
    (local state {:header-items []
                  :footer-items []
                  :welcome nil
                  :steering-queue []
                  :stop-line nil
                  :stopped-msg-id nil})
    (var buf-id nil)
    (var win-id nil)
    (var guard nil)
    (local widgets {:header nil
                    :messages nil
                    :context nil
                    :steering nil
                    :prompt nil
                    :footer nil})

    (fn is-open? []
      (and (not= nil buf-id) (nvim.nvim_buf_is_valid buf-id) (not= nil win-id)
           (nvim.nvim_win_is_valid win-id)))

    (var internal-edit-depth 0)

    (fn with-internal-edit [f]
      (set internal-edit-depth (+ internal-edit-depth 1))
      (when (and guard (= internal-edit-depth 1))
        (guard.set-internal true))
      (f)
      (set internal-edit-depth (- internal-edit-depth 1))
      (when (and guard (= internal-edit-depth 0))
        (guard.set-internal false)
        (guard.update-expected-count)))

    (fn focus-prompt []
      (when (and win-id (nvim.nvim_win_is_valid win-id))
        (let [total (nvim.nvim_buf_line_count buf-id)
              prompt-state (widgets.prompt.get-state)
              prompt-line (or prompt-state.prompt-start-line (- total 1))
              ;; Position cursor at end of the prompt line, not at col 2
              line-text (or (. (nvim.nvim_buf_get_lines buf-id prompt-line
                                                        (+ prompt-line 1) false)
                               1) "> ")
              col (length line-text)]
          (nvim.nvim_win_set_cursor win-id [(+ prompt-line 1) col]))))

    (fn make-separator []
      (let [win (vim.fn.bufwinid buf-id)
            width (if (and win (not= win -1))
                      (nvim.nvim_win_get_width win)
                      40)]
        (string.rep "─" width)))

    (fn render-prompt-area []
      "Re-render separator + context-area + prompt from current message end-line.
       Clears everything after messages first to avoid stale lines."
      (let [msg-end (widgets.messages.get-end-line)
            ;; Save prompt text before clearing the buffer (safe on first render)
            live-text (widgets.prompt.save-live-text)
            ;; Build all lines: separator + context + steering + stop + prompt
            sep (make-separator)
            has-ctx? (widgets.context.has-items?)
            has-steering? (widgets.steering.has-items?)
            is-loading? (. (widgets.prompt.get-state) :loading?)
            prompt-text-lines (vim.split (or live-text "") "\n" {:plain true})
            all-lines [sep]]
        ;; Context line
        (when has-ctx?
          (let [ctx-items (widgets.context.get-state)
                parts (icollect [_ item (ipairs ctx-items.items)] item.text)]
            (table.insert all-lines (table.concat parts " "))))
        ;; Steering line (just "-" as real text; rest is virtual)
        (when has-steering?
          (table.insert all-lines "-"))
        ;; Stop line (just "stop" as real text; ⏳ is virtual)
        (when is-loading?
          (table.insert all-lines :stop))
        ;; Prompt lines ("> " prefix on first line)
        (let [idle-prefix "> "]
          (table.insert all-lines
                        (.. idle-prefix (or (. prompt-text-lines 1) "")))
          (for [i 2 (length prompt-text-lines)]
            (table.insert all-lines (. prompt-text-lines i))))
        ;; Write everything in one shot
        (nvim.nvim_buf_set_lines buf-id msg-end -1 false all-lines)
        ;; Compute line positions
        (var offset 1)
        ;; 1 = after separator
        (let [ctx-line (when has-ctx?
                         (let [l (+ msg-end offset)]
                           (set offset (+ offset 1))
                           l))
              steering-line (when has-steering?
                              (let [l (+ msg-end offset)]
                                (set offset (+ offset 1))
                                l))
              stop-line-pos (when is-loading?
                              (let [l (+ msg-end offset)]
                                (set offset (+ offset 1))
                                l))
              prompt-start (+ msg-end offset)]
          (set state.stop-line stop-line-pos)
          (widgets.prompt.set-text-internal (or live-text ""))
          ;; Separator highlight
          (let [ns (nvim.nvim_create_namespace :eca-separator)]
            (nvim.nvim_buf_clear_namespace buf-id ns 0 -1)
            (pcall nvim.nvim_buf_set_extmark buf-id ns msg-end 0
                   {:end_col (length sep) :hl_group :EcaSeparator}))
          ;; Status anchors to separator
          (widgets.prompt.set-status-anchor-line msg-end)
          ;; Context highlight
          (when ctx-line
            (widgets.context.render-highlights ctx-line))
          ;; Steering highlight
          (when steering-line
            (widgets.steering.render-highlights steering-line))
          ;; Stop highlight (inline virtual text for ⏳ prefix)
          (when stop-line-pos
            (let [ns (nvim.nvim_create_namespace :eca-stop-line)]
              (nvim.nvim_buf_clear_namespace buf-id ns 0 -1)
              ;; ⏳ prefix as inline virtual text
              (nvim.nvim_buf_set_extmark buf-id ns stop-line-pos 0
                                         {:virt_text [["⏳ " :EcaSpinner]]
                                          :virt_text_pos :inline})
              ;; Highlight "stop" text
              (nvim.nvim_buf_set_extmark buf-id ns stop-line-pos 0
                                         {:end_col 4 :hl_group :EcaStopLabel})))
          ;; Prompt render (just highlights + virt lines, buffer already written)
          (widgets.prompt.render-highlights prompt-start))))

    (fn render-all []
      (with-internal-edit (fn []
                            (let [header-lines (widgets.header.render)]
                              (widgets.messages.set-start-line header-lines)
                              (widgets.messages.render)
                              (render-prompt-area))
                            (when widgets.footer
                              (widgets.footer.render)))))

    ;; Functions needed before open

    (fn close []
      (when (is-open?)
        (nvim.nvim_win_close win-id true)
        (set win-id nil)))

    (fn cancel-steering []
      "Cancel all queued steering messages but keep waiting for response."
      (when (> (length state.steering-queue) 0)
        (set state.steering-queue [])
        (when (is-open?)
          (with-internal-edit (fn []
                                (widgets.steering.clear)
                                (render-prompt-area))))))

    (fn stop []
      "Stop everything: streaming, loading, status, steering."
      (cancel-steering)
      ;; Abort any active streaming (don't flush remaining chars)
      (let [msg-state (widgets.messages.get-state)]
        (when msg-state.streaming-id
          (set state.stopped-msg-id msg-state.streaming-id)
          (with-internal-edit (fn []
                                (widgets.messages.abort-streaming msg-state.streaming-id)
                                (render-prompt-area)))))
      (when on-stop (on-stop)))

    (fn is-on-stop-line? []
      (and state.stop-line
           (let [cursor (nvim.nvim_win_get_cursor 0)
                 row (. cursor 1)]
             (= row (+ state.stop-line 1)))))

    (fn submit-prompt []
      (when (is-open?)
        (if ;; Cursor on steering [-] → cancel steering
            (widgets.steering.is-on-steering-line?)
            (do
              (cancel-steering) (focus-prompt))
            ;; Cursor on stop → stop everything
            (is-on-stop-line?)
            (stop)
            ;; Normal flow
            (let [prompt-state (widgets.prompt.get-state)
                  text (widgets.prompt.get-text)]
              (if prompt-state.loading?
                  ;; During loading: append to steering queue
                  (when (and text (not= "" text))
                    (table.insert state.steering-queue text)
                    (widgets.prompt.add-to-history text)
                    (with-internal-edit (fn []
                                          (widgets.prompt.clear)
                                          (widgets.steering.set-items state.steering-queue)
                                          (render-prompt-area)))
                    (focus-prompt))
                  ;; Normal: submit immediately
                  (when (and text (not= "" text))
                    (widgets.prompt.add-to-history text)
                    (with-internal-edit (fn [] (widgets.prompt.clear)))
                    (focus-prompt)
                    (when on-submit (on-submit text))))))))

    ;; Open

    (fn open []
      (when (not (is-open?))
        (set buf-id (nvim.nvim_create_buf false true))
        (let [width (math.floor (* (. vim.o :columns) config.width))]
          (set win-id (nvim.nvim_open_win buf-id true {:split :right : width})))
        (highlights.setup)
        (setup-chat-buffer buf-id)
        (setup-chat-window win-id)
        ;; Create widgets
        (set widgets.header
             (header-bar-widget.create buf-id win-id state.header-items))
        (set widgets.messages
             (message-list-widget.create buf-id
                                         {:wrap-write with-internal-edit
                                          :on-line-inserted (fn []
                                                              ;; Everything below the streaming area moved down
                                                              (let [s (widgets.prompt.get-state)
                                                                    st (widgets.steering.get-state)]
                                                                (set s.prompt-start-line
                                                                     (+ s.prompt-start-line
                                                                        1))
                                                                (set s.status-anchor-line
                                                                     (+ s.status-anchor-line
                                                                        1))
                                                                (when (> st.start-line
                                                                         0)
                                                                  (set st.start-line
                                                                       (+ st.start-line
                                                                          1))
                                                                  (set st.end-line
                                                                       (+ st.end-line
                                                                          1)))
                                                                (when state.stop-line
                                                                  (set state.stop-line
                                                                       (+ state.stop-line
                                                                          1)))))}))
        (when state.welcome
          (widgets.messages.set-welcome {:lines [state.welcome ""]
                                         :highlights [{:line-idx 0
                                                       :hl-group :EcaWelcome
                                                       :col-start 0
                                                       :col-end (length state.welcome)}]}))
        (set widgets.context (context-area-widget.create buf-id))
        (set widgets.steering (steering-area-widget.create buf-id))
        (set widgets.prompt
             (prompt-area-widget.create buf-id {:wrap-write with-internal-edit}))
        (set widgets.footer
             (footer-bar-widget.create buf-id win-id state.footer-items))
        ;; Keymaps
        (each [_ km (ipairs config.keymaps)]
          (vim.keymap.set km.mode km.lhs km.rhs
                          {:buffer buf-id :noremap true :silent true}))
        ;; Initial render
        (nvim.nvim_buf_set_lines buf-id 0 -1 false [""])
        (render-all)
        (focus-prompt)
        ;; Edit guard
        (set guard (setup-edit-guard buf-id render-all
                                     (fn []
                                       (let [s (widgets.prompt.get-state)]
                                         {:prompt-start-line (or s.prompt-start-line
                                                                 0)
                                          :loading? s.loading?}))
                                     focus-prompt))
        ;; Re-render on window resize so separator adjusts to new width
        (nvim.nvim_create_autocmd :WinResized
                                  {:callback (fn []
                                               (when (is-open?)
                                                 (with-internal-edit (fn []
                                                                       (render-prompt-area)))
                                                 (focus-prompt)))})))

    (fn toggle []
      (if (is-open?) (close) (open)))

    (fn get-buf-id [] buf-id)

    ;; Message API

    (fn append-message [msg]
      (when (is-open?)
        ;; Clear stopped ID when a new message cycle begins
        (when msg.streaming?
          (set state.stopped-msg-id nil))
        (with-internal-edit (fn []
                              (widgets.messages.append-message msg)
                              ;; Re-render prompt area after message is added.
                              ;; For streaming, this runs after the empty lines are inserted
                              ;; but before the timer starts writing chars, so it's safe.
                              (render-prompt-area)))
        (focus-prompt)))

    (fn update-message [id content]
      (when (and (is-open?) (not= id state.stopped-msg-id))
        (let [msg-state (widgets.messages.get-state)]
          (with-internal-edit (fn []
                                (widgets.messages.update-message id content)
                                ;; Don't re-render prompt during streaming updates —
                                ;; it would interfere with char-by-char buffer writes
                                (when (not= id msg-state.streaming-id)
                                  (render-prompt-area)))))))

    (fn finish-streaming [id]
      (when (and (is-open?) (not= id state.stopped-msg-id))
        (with-internal-edit (fn []
                              (widgets.messages.finish-streaming id)
                              (render-prompt-area)))))

    (fn clear-messages []
      (when (is-open?)
        (with-internal-edit (fn []
                              (widgets.messages.clear)
                              (render-prompt-area)))))

    ;; State updates

    (fn update-header [new-items]
      (set state.header-items new-items)
      (when (is-open?)
        (with-internal-edit (fn [] (widgets.header.update new-items)))))

    (fn update-header-item [title new-value]
      (var found false)
      (each [_ item (ipairs state.header-items)]
        (when (= item.title title)
          (tset item :value new-value)
          (set found true)))
      (when (not found)
        (table.insert state.header-items {: title :value new-value}))
      (when (is-open?)
        (with-internal-edit (fn [] (widgets.header.update state.header-items)))))

    (fn update-footer [new-items]
      (set state.footer-items new-items)
      (when (is-open?)
        (with-internal-edit (fn [] (widgets.footer.update new-items)))))

    (fn update-footer-item [title new-value]
      (var found false)
      (each [_ item (ipairs state.footer-items)]
        (when (= item.title title)
          (tset item :value new-value)
          (set found true)))
      (when (not found)
        (table.insert state.footer-items {: title :value new-value}))
      (when (is-open?)
        (with-internal-edit (fn [] (widgets.footer.update state.footer-items)))))

    (fn set-welcome [text]
      (set state.welcome text)
      (when (is-open?)
        (widgets.messages.set-welcome {:lines [text ""]
                                       :highlights [{:line-idx 0
                                                     :hl-group :EcaWelcome
                                                     :col-start 0
                                                     :col-end (length text)}]})
        (let [msg-state (widgets.messages.get-state)]
          (when (= 0 (length msg-state.messages))
            (with-internal-edit (fn [] (render-all)))))))

    (fn set-status [text]
      "Set status indicator (virtual text, no re-render needed)."
      (when (is-open?)
        (widgets.prompt.set-status text)))

    ;; === Context API ===

    (fn add-context [ctx]
      (when (is-open?)
        (with-internal-edit (fn []
                              (widgets.context.add ctx)
                              (render-prompt-area)))
        (focus-prompt)))

    (fn remove-context [name]
      (when (is-open?)
        (with-internal-edit (fn []
                              (widgets.context.remove name)
                              (render-prompt-area)))))

    (fn set-loading [bool]
      "Toggle loading state. When turning off, flush steering queue."
      (when (is-open?)
        (widgets.prompt.set-loading bool)
        ;; Re-render to add/remove the stop line
        (with-internal-edit (fn [] (render-prompt-area)))
        (focus-prompt)
        ;; When loading finishes, check for queued steering messages
        (when (and (not bool) (> (length state.steering-queue) 0))
          (let [combined (table.concat state.steering-queue "\n")]
            (set state.steering-queue [])
            (with-internal-edit (fn []
                                  (widgets.steering.clear)
                                  (render-prompt-area)))
            ;; Submit all queued messages as one combined message
            (when on-submit (on-submit combined))))))

    {: open
     : close
     : toggle
     : is-open?
     : get-buf-id
     : append-message
     : update-message
     : finish-streaming
     : clear-messages
     : update-header
     : update-header-item
     : update-footer
     : update-footer-item
     : set-welcome
     : submit-prompt
     : stop
     : cancel-steering
     : set-status
     : set-loading
     : add-context
     : remove-context}))

{: create-chat-ui}
