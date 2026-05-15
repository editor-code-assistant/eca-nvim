;; builder — orchestrates widgets, manages chat UI lifecycle.

(local nvim vim.api)
(local highlights (require :eca.ui.highlights))
(local header-bar-widget (require :eca.ui.widgets.header-bar))
(local message-list-widget (require :eca.ui.widgets.message-list))
(local prompt-area-widget (require :eca.ui.widgets.prompt-area))
(local footer-bar-widget (require :eca.ui.widgets.footer-bar))

;; ── Buffer/window setup ─────────────────────────────────

(fn disable-statusline-plugins []
  "Try to disable known statusline plugins for eca-chat filetype."
  ;; Lualine
  (let [(ok lualine) (pcall require :lualine)]
    (when ok
      (let [config (lualine.get_config)
            disabled (or config.options.disabled_filetypes {})]
        (when (not disabled.statusline)
          (tset disabled :statusline []))
        (var found false)
        (each [_ ft (ipairs disabled.statusline)]
          (when (= ft "eca-chat") (set found true)))
        (when (not found)
          (table.insert disabled.statusline "eca-chat"))
        (tset config.options :disabled_filetypes disabled)
        (lualine.setup config)))))

(fn setup-chat-buffer [buf]
  (nvim.nvim_buf_set_name buf "ECA Chat")
  (nvim.nvim_set_option_value :buftype "nofile" {:buf buf})
  (nvim.nvim_set_option_value :bufhidden "hide" {:buf buf})
  (nvim.nvim_set_option_value :swapfile false {:buf buf})
  (nvim.nvim_set_option_value :filetype "eca-chat" {:buf buf})
  (disable-statusline-plugins))

(fn setup-chat-window [win]
  (nvim.nvim_set_option_value :number false {:win win})
  (nvim.nvim_set_option_value :relativenumber false {:win win})
  (nvim.nvim_set_option_value :signcolumn "no" {:win win})
  (nvim.nvim_set_option_value :foldcolumn "0" {:win win})
  (nvim.nvim_set_option_value :numberwidth 1 {:win win})
  (nvim.nvim_set_option_value :statuscolumn "" {:win win})
  (nvim.nvim_set_option_value :spell false {:win win})
  (nvim.nvim_set_option_value :list false {:win win})
  (nvim.nvim_set_option_value :wrap true {:win win})
  (nvim.nvim_set_option_value :linebreak true {:win win})
  (nvim.nvim_set_option_value :conceallevel 2 {:win win})
)

;; ── Edit guard ──────────────────────────────────────────

(fn setup-edit-guard [buf-id render-all-fn get-prompt-state focus-prompt-fn]
  (var internal-edit false)
  (var guard-ns nil)

  (fn ensure-guard-ns []
    (when (= nil guard-ns)
      (set guard-ns (nvim.nvim_create_namespace "eca-edit-guard")))
    guard-ns)

  (fn get-prefix [loading?]
    (let [prompt-prefix (require :eca.ui.components.prompt-prefix)]
      (. (prompt-prefix.render {:loading? loading?}) :text)))

  (fn salvage-user-text [buf prompt-start-line prefix]
    (let [current-count (nvim.nvim_buf_line_count buf)
          start (math.min prompt-start-line current-count)
          prompt-lines (nvim.nvim_buf_get_lines buf start current-count false)]
      (if (= 0 (length prompt-lines))
        [""]
        (icollect [i line (ipairs prompt-lines)]
          (if (= i 1)
            (if (vim.startswith line prefix)
              (string.sub line (+ (length prefix) 1))
              (line:gsub "^>%s*" ""))
            line)))))

  (fn restore-with-user-text [buf prefix user-lines]
    (set internal-edit true)
    (render-all-fn)
    (let [new-count (nvim.nvim_buf_line_count buf)
          new-last-idx (- new-count 1)
          restored-lines (icollect [i line (ipairs user-lines)]
                           (if (= i 1) (.. prefix line) line))]
      (when (> (length restored-lines) 0)
        (nvim.nvim_buf_set_lines buf new-last-idx new-count false restored-lines)
        (let [ns (ensure-guard-ns)]
          (nvim.nvim_buf_set_extmark buf ns new-last-idx 0
            {:end_col (length prefix)
             :hl_group :EcaPromptPrefix}))))
    (set internal-edit false)
    (when focus-prompt-fn
      (focus-prompt-fn)))

  (fn on-lines-handler [_ buf changedtick first-line last-line new-last-line]
    (when (not internal-edit)
      (let [{: prompt-start-line : loading?} (get-prompt-state)
            prefix (get-prefix loading?)]
        (vim.schedule
          (fn []
            (when (nvim.nvim_buf_is_valid buf)
              (let [current-count (nvim.nvim_buf_line_count buf)
                    prompt-idx (math.min prompt-start-line (- current-count 1))
                    prompt-lines (nvim.nvim_buf_get_lines buf prompt-idx (+ prompt-idx 1) false)
                    prompt-line-text (or (. prompt-lines 1) "")
                    damaged? (or (< first-line prompt-start-line)
                                 (not (vim.startswith prompt-line-text prefix)))]
                (when damaged?
                  (let [user-lines (salvage-user-text buf prompt-start-line prefix)]
                    (restore-with-user-text buf prefix user-lines))))))))))

  (nvim.nvim_buf_attach buf-id false {:on_lines on-lines-handler})

  (fn set-internal [bool]
    (set internal-edit bool))

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
                  :welcome nil})

    (var buf-id nil)
    (var win-id nil)
    (var guard nil)
    (local widgets {:header nil :messages nil :prompt nil :footer nil})

    (fn is-open? []
      (and (not= nil buf-id)
           (nvim.nvim_buf_is_valid buf-id)
           (not= nil win-id)
           (nvim.nvim_win_is_valid win-id)))

    (fn with-internal-edit [f]
      ;; Save cursor position, do the write, restore cursor
      (let [saved-cursor (when (and win-id (nvim.nvim_win_is_valid win-id))
                           (nvim.nvim_win_get_cursor win-id))]
        (when guard (guard.set-internal true))
        (f)
        (when guard
          (guard.set-internal false)
          (guard.update-expected-count))
        ;; Restore cursor if it was saved and window still valid
        (when (and saved-cursor win-id (nvim.nvim_win_is_valid win-id))
          (let [total (nvim.nvim_buf_line_count buf-id)
                ;; Clamp cursor to valid range
                line (math.min (. saved-cursor 1) total)
                col (. saved-cursor 2)]
            (pcall nvim.nvim_win_set_cursor win-id [line col])))))

    (fn focus-prompt []
      (when (and win-id (nvim.nvim_win_is_valid win-id))
        (let [total (nvim.nvim_buf_line_count buf-id)
              prompt-state (widgets.prompt.get-state)
              prompt-line (or prompt-state.prompt-start-line (- total 1))]
          (nvim.nvim_win_set_cursor win-id [(+ prompt-line 1) 2]))))

    (fn render-all []
      (with-internal-edit
        (fn []
          (let [header-lines (widgets.header.render)]
            (widgets.messages.set-start-line header-lines)
            (widgets.messages.render)
            (let [end-line (widgets.messages.get-end-line)]
              (widgets.prompt.render end-line)))
          (when widgets.footer
            (widgets.footer.render)))))

    ;; Functions needed before open

    (fn close []
      (when (is-open?)
        (nvim.nvim_win_close win-id true)
        (set win-id nil)))

    (fn submit-prompt []
      (when (is-open?)
        (let [prompt-state (widgets.prompt.get-state)]
          (if prompt-state.loading?
            ;; During loading, Enter/submit triggers stop
            (when on-stop (on-stop))
            ;; Normal: submit text
            (let [text (widgets.prompt.get-text)]
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
          (set win-id (nvim.nvim_open_win buf-id true {:split :right :width width})))

        (highlights.setup)
        (setup-chat-buffer buf-id)
        (setup-chat-window win-id)

        ;; Create widgets
        (set widgets.header (header-bar-widget.create buf-id win-id state.header-items))
        (set widgets.messages (message-list-widget.create buf-id
                                {:wrap-write with-internal-edit
                                 :on-line-inserted
                                 (fn []
                                   ;; Prompt physically moved down, update its tracked position
                                   (let [s (widgets.prompt.get-state)]
                                     (set s.prompt-start-line (+ s.prompt-start-line 1))))}))
        (when state.welcome
          (widgets.messages.set-welcome
            {:lines [state.welcome ""]
             :highlights [{:line-idx 0 :hl-group :EcaWelcome :col-start 0
                           :col-end (length state.welcome)}]}))
        (set widgets.prompt (prompt-area-widget.create buf-id
                              {:wrap-write with-internal-edit}))
        (set widgets.footer (footer-bar-widget.create buf-id win-id state.footer-items))

        ;; Keymaps
        (each [_ km (ipairs config.keymaps)]
          (vim.keymap.set km.mode km.lhs km.rhs
            {:buffer buf-id :noremap true :silent true}))

        ;; Initial render
        (nvim.nvim_buf_set_lines buf-id 0 -1 false [""])
        (render-all)
        (focus-prompt)

        ;; Edit guard
        (set guard
          (setup-edit-guard buf-id render-all
            (fn []
              (let [s (widgets.prompt.get-state)]
                {:prompt-start-line (or s.prompt-start-line 0)
                 :loading? s.loading?}))
            focus-prompt))))

    (fn toggle []
      (if (is-open?) (close) (open)))

    (fn get-buf-id [] buf-id)

    ;; Message API
    (fn append-message [msg]
      (when (is-open?)
        (with-internal-edit
          (fn []
            (widgets.messages.append-message msg)
            (let [end-line (widgets.messages.get-end-line)]
              (widgets.prompt.render end-line))))
        (focus-prompt)))

    (fn update-message [id content]
      (when (is-open?)
        (with-internal-edit
          (fn []
            (widgets.messages.update-message id content)
            (let [end-line (widgets.messages.get-end-line)]
              (widgets.prompt.render end-line))))))

    (fn finish-streaming [id]
      (when (is-open?)
        (with-internal-edit
          (fn []
            (widgets.messages.finish-streaming id)
            (let [end-line (widgets.messages.get-end-line)]
              (widgets.prompt.render end-line))))))

    (fn clear-messages []
      (when (is-open?)
        (with-internal-edit
          (fn []
            (widgets.messages.clear)
            (let [end-line (widgets.messages.get-end-line)]
              (widgets.prompt.render end-line))))))

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
        (table.insert state.header-items {:title title :value new-value}))
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
        (table.insert state.footer-items {:title title :value new-value}))
      (when (is-open?)
        (with-internal-edit (fn [] (widgets.footer.update state.footer-items)))))

    (fn set-welcome [text]
      (set state.welcome text)
      (when (is-open?)
        (widgets.messages.set-welcome
          {:lines [text ""]
           :highlights [{:line-idx 0 :hl-group :EcaWelcome :col-start 0
                         :col-end (length text)}]})
        (let [msg-state (widgets.messages.get-state)]
          (when (= 0 (length msg-state.messages))
            (with-internal-edit (fn [] (render-all)))))))

    (fn set-status [text]
      "Set status indicator. text=nil to hide."
      (when (is-open?)
        (with-internal-edit
          (fn []
            (widgets.prompt.set-status text)
            (let [end-line (widgets.messages.get-end-line)]
              (widgets.prompt.render end-line))))))

    (fn set-loading [bool]
      "Toggle loading state. Shows ⏳ stop when loading, > when idle."
      (when (is-open?)
        (with-internal-edit
          (fn []
            (widgets.prompt.set-loading bool)
            (let [end-line (widgets.messages.get-end-line)]
              (widgets.prompt.render end-line))))))

    {: open : close : toggle : is-open? : get-buf-id
     : append-message : update-message : finish-streaming : clear-messages
     : update-header : update-header-item
     : update-footer : update-footer-item
     : set-welcome
     : submit-prompt : set-status : set-loading}))

{: create-chat-ui}
