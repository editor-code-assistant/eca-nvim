;; expandable-block widget — generic collapsible block with label + content.
;; Zero business logic. Receives display data, not domain concepts.

(fn create [canvas initial-state]
  "Create an expandable-block widget.
   initial-state: {: id : label : icon-expanded : icon-collapsed : content : expanded?}
   Returns {: render : toggle : expand : collapse : update-label : get-state}."
  (local state (vim.tbl_extend :force
                 {:id nil
                  :label ""
                  :icon-expanded "⏷"
                  :icon-collapsed "⏵"
                  :content []
                  :expanded? false
                  :start-line 0
                  :ns-id nil}
                 (or initial-state {})))

  (fn ensure-ns []
    (when (= nil state.ns-id)
      (set state.ns-id (canvas:create-namespace
                         (.. "eca-expandable-" (or state.id "unknown")))))
    state.ns-id)

  (fn build-label []
    (let [icon (if state.expanded? state.icon-expanded state.icon-collapsed)]
      (.. icon " " state.label)))

  (fn render [start-line]
    "Render the block at start-line. Returns number of lines used."
    (set state.start-line start-line)
    (let [ns (ensure-ns)
          label-line (build-label)
          lines [label-line]]
      (when state.expanded?
        (each [_ line (ipairs state.content)]
          (table.insert lines (.. "  " line))))
      (canvas:set-lines start-line start-line lines)
      (canvas:add-extmark ns start-line 0
        {:end_col (length label-line)
         :hl_group :EcaExpandableLabel})
      (length lines)))

  (fn toggle []
    (set state.expanded? (not state.expanded?)))

  (fn expand []
    (set state.expanded? true))

  (fn collapse []
    (set state.expanded? false))

  (fn update-label [new-label]
    (set state.label new-label))

  (fn get-state []
    state)

  {: render
   : toggle
   : expand
   : collapse
   : update-label
   : get-state})

{: create}
