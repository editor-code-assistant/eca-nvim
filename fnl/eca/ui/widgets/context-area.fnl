;; context-area widget — renders a horizontal bar of context items.
;; Managed directly by the builder, sits between messages and the prompt.

(local nvim vim.api)

(fn create [buf-id]
  (local state {:items [] :ns-id nil :start-line 0 :end-line 0})

  (fn ensure-ns []
    (when (= nil state.ns-id)
      (set state.ns-id (nvim.nvim_create_namespace "eca-context-area")))
    state.ns-id)

  (fn build-line []
    "Build the display line and per-item highlights."
    (if (= 0 (length state.items))
      {:line nil :highlights []}
      (let [result (accumulate [acc {:parts [] :highlights [] :col 0}
                                _ item (ipairs state.items)]
                     (let [sep-col (if (> acc.col 0)
                                     (do (table.insert acc.parts " ")
                                         (+ acc.col 1))
                                     acc.col)]
                       (table.insert acc.parts item.text)
                       (table.insert acc.highlights
                         {:hl-group (or item.hl-group :Normal)
                          :col-start sep-col
                          :col-end (+ sep-col (length item.text))})
                       {:parts acc.parts
                        :highlights acc.highlights
                        :col (+ sep-col (length item.text))}))]
        {:line (table.concat result.parts "")
         :highlights result.highlights})))

  (fn has-items? []
    (> (length state.items) 0))

  (fn render [start-line]
    "Render the context bar at start-line.  Returns number of lines written (0 or 1)."
    (set state.start-line start-line)
    (let [ns (ensure-ns)]
      (nvim.nvim_buf_clear_namespace buf-id ns 0 -1)
      (if (not (has-items?))
        (do (set state.end-line start-line) 0)
        (let [{: line : highlights} (build-line)]
          (nvim.nvim_buf_set_lines buf-id start-line start-line false [line])
          (each [_ hl (ipairs highlights)]
            (nvim.nvim_buf_set_extmark buf-id ns start-line hl.col-start
              {:end_col hl.col-end :hl_group hl.hl-group}))
          (set state.end-line (+ start-line 1))
          1))))

  (fn add [item]
    (let [exists (accumulate [found false _ existing (ipairs state.items)]
                   (or found (= existing.text item.text)))]
      (when (not exists)
        (table.insert state.items item))))

  (fn remove [text]
    (set state.items
      (icollect [_ item (ipairs state.items)]
        (when (not= item.text text) item))))

  (fn render-highlights [line-num]
    "Apply highlights to a context line already written in the buffer."
    (when (has-items?)
      (let [ns (ensure-ns)
            {: highlights} (build-line)]
        (nvim.nvim_buf_clear_namespace buf-id ns 0 -1)
        (each [_ hl (ipairs highlights)]
          (nvim.nvim_buf_set_extmark buf-id ns line-num hl.col-start
            {:end_col hl.col-end :hl_group hl.hl-group})))))

  (fn clear [] (set state.items []))
  (fn get-state [] state)
  (fn get-end-line [] state.end-line)

  {: render : render-highlights : add : remove : clear : has-items? : get-state : get-end-line})

{: create}
