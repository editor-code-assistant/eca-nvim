;; message-list widget — renders chat messages in the buffer.
;; Stateful: maintains list of messages, renders via canvas.

(local message-component (require :eca.ui.components.message))
(local separator-component (require :eca.ui.components.separator))

(fn create [canvas]
  "Create a message-list widget.
   Returns {: render : append-message : update-message : clear : get-state}."
  (local state {:messages []
              :ns-id nil
              :end-line 0})

  (fn ensure-ns []
    (when (= nil state.ns-id)
      (set state.ns-id (canvas:create-namespace "eca-messages")))
    state.ns-id)

  (fn apply-highlights [lines-offset highlights]
    "Apply highlight extmarks for a rendered component."
    (let [ns (ensure-ns)]
      (each [_ hl (ipairs highlights)]
        (canvas:add-extmark ns
          (+ lines-offset hl.line-idx)
          hl.col-start
          {:end_col hl.col-end
           :hl_group hl.hl-group}))))

  (fn render-single-message [msg start-line]
    "Render a single message starting at given line. Returns number of lines written."
    (let [rendered (message-component.render msg)
          sep (separator-component.render {:width 50})]
      ;; Write message lines
      (canvas:set-lines start-line start-line rendered.lines)
      (apply-highlights start-line rendered.highlights)
      ;; Write separator after message
      (let [sep-line (+ start-line (length rendered.lines))]
        (canvas:set-lines sep-line sep-line [sep.line])
        (apply-highlights sep-line sep.highlights)
        ;; Return total lines written (message + separator)
        (+ (length rendered.lines) 1))))

  (fn render []
    "Full re-render of all messages."
    (let [ns (ensure-ns)]
      ;; Clear the messages area (leave room for prompt at the end)
      (canvas:set-lines 0 state.end-line [])
      (set state.end-line 0)
      (if (= 0 (length state.messages))
        ;; Show welcome message
        (let [welcome (message-component.render-welcome)]
          (canvas:set-lines 0 0 welcome.lines)
          (apply-highlights 0 welcome.highlights)
          (set state.end-line (length welcome.lines)))
        ;; Render all messages
        (each [_ msg (ipairs state.messages)]
          (let [lines-written (render-single-message msg state.end-line)]
            (set state.end-line (+ state.end-line lines-written)))))))

  (fn append-message [msg]
    "Append a new message and render it incrementally."
    (table.insert state.messages msg)
    ;; If this is the first message, clear welcome and re-render
    (if (= 1 (length state.messages))
      (render)
      ;; Otherwise render incrementally
      (let [lines-written (render-single-message msg state.end-line)]
        (set state.end-line (+ state.end-line lines-written))))
    ;; Auto-scroll to end
    (when (canvas:win-valid?)
      (let [total (canvas:line-count)]
        (canvas:set-cursor total 0))))

  (fn update-message [id new-content]
    "Update the content of an existing message (for streaming)."
    (let [found (accumulate [f false
                             _ msg (ipairs state.messages)]
                  (if (= msg.id id)
                    (do (tset msg :content new-content) true)
                    f))]
      (when found
        (render))))

  (fn clear []
    "Clear all messages."
    (set state.messages [])
    (set state.end-line 0)
    (render))

  (fn get-state []
    state)

  (fn get-end-line []
    state.end-line)

  {: render
   : append-message
   : update-message
   : clear
   : get-state
   : get-end-line})

{: create}
