;; context-bar widget — horizontal bar of tagged items.

(local nvim vim.api)

(fn create [buf-id]
  (local state {:items [] :ns-id nil})

  (fn ensure-ns []
    (when (= nil state.ns-id)
      (set state.ns-id (nvim.nvim_create_namespace "eca-context-bar")))
    state.ns-id)

  (fn build-line []
    (if (= 0 (length state.items))
      {:line "" :highlights []}
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

  (fn render [line-num]
    (let [ns (ensure-ns)
          {: line : highlights} (build-line)]
      (when (and line (not= "" line))
        (nvim.nvim_buf_set_lines buf-id line-num (+ line-num 1) false [line])
        (each [_ hl (ipairs (or highlights []))]
          (nvim.nvim_buf_set_extmark buf-id ns line-num hl.col-start
            {:end_col hl.col-end :hl_group hl.hl-group})))))

  (fn add [item]
    (let [exists (accumulate [found false _ existing (ipairs state.items)]
                   (or found (= existing.text item.text)))]
      (when (not exists)
        (table.insert state.items item))))

  (fn remove [text]
    (set state.items
      (icollect [_ item (ipairs state.items)]
        (when (not= item.text text) item))))

  (fn clear [] (set state.items []))
  (fn get-state [] state)

  {: render : add : remove : clear : get-state})

{: create}
