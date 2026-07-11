;; steering-area widget — shows queued steering messages with a cancel button.
;; Only the "-" is real text (navigable by cursor).
;; "Steering: <text> [" and "]" are inline virtual text.

(local nvim vim.api)

(fn create [buf-id]
  (local state {:items []
                :ns-id nil
                :start-line 0
                :end-line 0})

  (fn ensure-ns []
    (when (= nil state.ns-id)
      (set state.ns-id (nvim.nvim_create_namespace "eca-steering-area")))
    state.ns-id)

  (fn has-items? []
    (> (length state.items) 0))

  (fn apply-virt-text [line-num]
    "Apply inline virtual text decoration around the '-' on the given line."
    (let [ns (ensure-ns)
          combined (table.concat state.items "\n")
          truncated (if (> (length combined) 60)
                      (.. (string.sub combined 1 60) "...")
                      combined)
          prefix (.. "Steering: " truncated " [")]
      ;; Inline virt text before "-"
      (nvim.nvim_buf_set_extmark buf-id ns line-num 0
        {:virt_text [[prefix :EcaSteeringLabel]]
         :virt_text_pos :inline})
      ;; Inline virt text after "-"
      (nvim.nvim_buf_set_extmark buf-id ns line-num 1
        {:virt_text [["]" :EcaStopLabel]]
         :virt_text_pos :inline})
      ;; Highlight the "-" itself
      (nvim.nvim_buf_set_extmark buf-id ns line-num 0
        {:end_col 1 :hl_group :EcaStopLabel})))

  (fn render [start-line]
    "Render steering at start-line. Returns number of lines written (0 or 1)."
    (set state.start-line start-line)
    (let [ns (ensure-ns)]
      (nvim.nvim_buf_clear_namespace buf-id ns 0 -1)
      (if (not (has-items?))
        (do (set state.end-line start-line) 0)
        (do
          (nvim.nvim_buf_set_lines buf-id start-line start-line false ["-"])
          (set state.end-line (+ start-line 1))
          (apply-virt-text start-line)
          1))))

  (fn render-highlights [line-num]
    "Apply highlights to a steering line already written in the buffer."
    (set state.start-line line-num)
    (set state.end-line (+ line-num 1))
    (when (has-items?)
      (let [ns (ensure-ns)]
        (nvim.nvim_buf_clear_namespace buf-id ns 0 -1)
        (apply-virt-text line-num))))

  (fn set-items [items]
    (set state.items (or items [])))

  (fn is-on-steering-line? []
    "Check if the cursor is currently on the steering line."
    (and (has-items?)
         (let [cursor (nvim.nvim_win_get_cursor 0)
               row (. cursor 1)]
           (= row (+ state.start-line 1)))))

  (fn clear []
    (set state.items []))

  (fn get-state [] state)
  (fn get-end-line [] state.end-line)

  {: render : render-highlights : set-items : has-items?
   : is-on-steering-line? : clear : get-state : get-end-line})

{: create}
