;; prompt-area widget — context bar + prompt input.

(local nvim vim.api)
(local prompt-prefix-component (require :eca.ui.components.prompt-prefix))
(local context-bar-widget (require :eca.ui.widgets.context-bar))

(fn create [buf-id]
  (local state {:loading? false :prompt-text "" :history [] :history-idx 0
                :prompt-start-line 0 :ns-id nil})
  (local ctx-bar (context-bar-widget.create buf-id))

  (fn ensure-ns []
    (when (= nil state.ns-id)
      (set state.ns-id (nvim.nvim_create_namespace "eca-prompt-area")))
    state.ns-id)

  (fn render [start-line]
    (set state.prompt-start-line start-line)
    (let [ns (ensure-ns)
          prefix (prompt-prefix-component.render {:loading? state.loading?})
          ctx-state (ctx-bar.get-state)
          has-contexts? (> (length ctx-state.items) 0)
          lines []]
      (when has-contexts?
        (let [parts (icollect [_ item (ipairs ctx-state.items)] item.text)]
          (table.insert lines (table.concat parts " "))))
      (table.insert lines (.. prefix.text state.prompt-text))
      (nvim.nvim_buf_set_lines buf-id start-line -1 false lines)
      (let [prompt-line-idx (- (+ start-line (length lines)) 1)]
        (nvim.nvim_buf_set_extmark buf-id ns prompt-line-idx 0
          {:end_col (length prefix.text) :hl_group prefix.hl-group}))
      (when has-contexts?
        (ctx-bar.render start-line))
      (length lines)))

  (fn get-text []
    (let [total (nvim.nvim_buf_line_count buf-id)
          prompt-lines (nvim.nvim_buf_get_lines buf-id state.prompt-start-line total false)
          prefix (prompt-prefix-component.render {:loading? state.loading?})]
      (when (and prompt-lines (> (length prompt-lines) 0))
        (let [first-line (. prompt-lines 1)
              stripped (if (vim.startswith first-line prefix.text)
                         (string.sub first-line (+ (length prefix.text) 1))
                         first-line)
              parts [stripped]]
          (for [i 2 (length prompt-lines)]
            (table.insert parts (. prompt-lines i)))
          (table.concat parts "\n")))))

  (fn set-text [text]
    (set state.prompt-text (or text ""))
    (let [prefix (prompt-prefix-component.render {:loading? state.loading?})
          total (nvim.nvim_buf_line_count buf-id)
          last-line-idx (- total 1)]
      (nvim.nvim_buf_set_lines buf-id last-line-idx total false
        [(.. prefix.text state.prompt-text)])))

  (fn clear [] (set-text ""))

  (fn set-loading [bool]
    (set state.loading? bool)
    (let [prefix (prompt-prefix-component.render {:loading? bool})
          total (nvim.nvim_buf_line_count buf-id)
          last-line-idx (- total 1)]
      (nvim.nvim_buf_set_lines buf-id last-line-idx total false
        [(.. prefix.text state.prompt-text)])))

  (fn add-to-history [text]
    (when (and text (not= "" text))
      (table.insert state.history text)
      (set state.history-idx (+ (length state.history) 1))))

  (fn history-prev []
    (when (> state.history-idx 1)
      (set state.history-idx (- state.history-idx 1))
      (set-text (. state.history state.history-idx))))

  (fn history-next []
    (if (< state.history-idx (length state.history))
      (do (set state.history-idx (+ state.history-idx 1))
          (set-text (. state.history state.history-idx)))
      (do (set state.history-idx (+ (length state.history) 1))
          (set-text ""))))

  (fn add-context [ctx] (ctx-bar.add ctx))
  (fn remove-context [name] (ctx-bar.remove name))
  (fn get-state [] state)

  {: render : get-text : set-text : clear : set-loading
   : add-to-history : history-prev : history-next
   : add-context : remove-context : get-state})

{: create}
