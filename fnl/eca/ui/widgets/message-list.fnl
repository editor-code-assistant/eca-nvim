;; message-list widget — renders text blocks in the buffer.

(local nvim vim.api)
(local message-component (require :eca.ui.components.message))

(fn create [buf-id]
  (local state {:messages [] :ns-id nil :end-line 0 :start-line 0 :welcome-lines nil})

  (fn ensure-ns []
    (when (= nil state.ns-id)
      (set state.ns-id (nvim.nvim_create_namespace "eca-messages")))
    state.ns-id)

  (fn apply-highlights [lines-offset highlights]
    (let [ns (ensure-ns)]
      (each [_ hl (ipairs highlights)]
        (nvim.nvim_buf_set_extmark buf-id ns
          (+ lines-offset hl.line-idx) hl.col-start
          {:end_col hl.col-end :hl_group hl.hl-group}))))

  (fn render-single-message [msg start-line]
    (let [rendered (message-component.render msg)]
      (nvim.nvim_buf_set_lines buf-id start-line start-line false rendered.lines)
      (apply-highlights start-line rendered.highlights)
      (length rendered.lines)))

  (fn set-start-line [line]
    (set state.start-line line)
    (when (= state.end-line 0)
      (set state.end-line line)))

  (fn set-welcome [data]
    (set state.welcome-lines data))

  (fn render []
    (let [ns (ensure-ns)]
      (nvim.nvim_buf_set_lines buf-id state.start-line state.end-line false [])
      (set state.end-line state.start-line)
      (if (= 0 (length state.messages))
        (when state.welcome-lines
          (nvim.nvim_buf_set_lines buf-id state.start-line state.start-line false
            state.welcome-lines.lines)
          (apply-highlights state.start-line (or state.welcome-lines.highlights []))
          (set state.end-line (+ state.start-line (length state.welcome-lines.lines))))
        (each [_ msg (ipairs state.messages)]
          (let [lines-written (render-single-message msg state.end-line)]
            (set state.end-line (+ state.end-line lines-written)))))))

  (fn append-message [msg]
    (table.insert state.messages msg)
    (if (= 1 (length state.messages))
      (render)
      (let [lines-written (render-single-message msg state.end-line)]
        (set state.end-line (+ state.end-line lines-written)))))

  (fn update-message [id new-content]
    (let [found (accumulate [f false _ msg (ipairs state.messages)]
                  (if (= msg.id id)
                    (do (tset msg :content new-content) true) f))]
      (when found (render))))

  (fn clear []
    (set state.messages [])
    (set state.end-line state.start-line)
    (render))

  (fn get-state [] state)
  (fn get-end-line [] state.end-line)

  {: render : append-message : update-message : clear
   : get-state : get-end-line : set-start-line : set-welcome})

{: create}
