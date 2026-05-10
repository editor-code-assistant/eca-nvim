;; expandable-block widget — collapsible blocks for tool calls, reasoning, etc.
;; Stateful: tracks expanded/collapsed state, renders via canvas.

(local icon-component (require :eca.ui.components.icon))

(fn format-elapsed [ms]
  "Format milliseconds to human readable: '3s', '1m 23s'."
  (if (= nil ms) ""
      (let [seconds (math.floor (/ ms 1000))]
        (if (>= seconds 60)
          (let [mins (math.floor (/ seconds 60))
                secs (% seconds 60)]
            (.. (tostring mins) "m " (tostring secs) "s"))
          (.. (tostring seconds) "s")))))

(fn build-label [state]
  "Build the label line for an expandable block."
  (let [{: expanded? : type : label : status : elapsed-ms} state
        toggle-icon (icon-component.render
                      {:name (if expanded? :expanded :collapsed)})
        status-icon (when status
                      (icon-component.render {:name status}))
        elapsed-str (format-elapsed elapsed-ms)
        parts [toggle-icon.text]]
    (table.insert parts (.. " " (or label (or type "block"))))
    (when status-icon
      (table.insert parts (.. " " status-icon.text)))
    (when (and elapsed-str (not= "" elapsed-str))
      (table.insert parts (.. " " elapsed-str)))
    (table.concat parts "")))

(fn create [canvas initial-state]
  "Create an expandable-block widget.
   initial-state: {: id : type : status : expanded? : label : content : elapsed-ms : children}
   Returns {: render : toggle : update-status : collapse : expand : get-state}."
  (var state (vim.tbl_extend :force
               {:id nil
                :type :tool-call
                :status nil
                :expanded? false
                :label ""
                :content []
                :elapsed-ms nil
                :children []
                :start-line 0
                :ns-id nil}
               (or initial-state {})))

  (fn ensure-ns []
    (when (= nil state.ns-id)
      (set state.ns-id (canvas:create-namespace
                         (.. "eca-expandable-" (or state.id "unknown")))))
    state.ns-id)

  (fn render [start-line]
    "Render the block at start-line. Returns number of lines used."
    (set state.start-line start-line)
    (let [ns (ensure-ns)
          label-line (build-label state)
          lines [label-line]]
      ;; Add content lines if expanded
      (when state.expanded?
        (each [_ line (ipairs state.content)]
          (table.insert lines (.. "  " line))))
      ;; Write to buffer
      (canvas:set-modifiable true)
      (canvas:set-lines start-line start-line lines)
      ;; Highlight the label line
      (canvas:add-extmark ns start-line 0
        {:end_col (length label-line)
         :hl_group :EcaExpandableLabel})
      (canvas:set-modifiable false)
      ;; Return line count
      (length lines)))

  (fn toggle []
    "Toggle expanded/collapsed state."
    (set state.expanded? (not state.expanded?)))

  (fn expand []
    (set state.expanded? true))

  (fn collapse []
    (set state.expanded? false))

  (fn update-status [new-status ?elapsed-ms]
    "Update the status and optionally the elapsed time."
    (set state.status new-status)
    (when ?elapsed-ms
      (set state.elapsed-ms ?elapsed-ms)))

  (fn get-state []
    state)

  {: render
   : toggle
   : expand
   : collapse
   : update-status
   : get-state})

{: create}
