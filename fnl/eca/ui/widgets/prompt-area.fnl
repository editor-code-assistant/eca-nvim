;; prompt-area widget — separator + context bar + prompt input.
;; Stateful: manages prompt text, history, contexts, loading state.

(local separator-component (require :eca.ui.components.separator))
(local prompt-prefix-component (require :eca.ui.components.prompt-prefix))
(local context-bar-widget (require :eca.ui.widgets.context-bar))

(fn create [canvas]
  "Create a prompt-area widget.
   Returns widget with full API."
  (var state {:loading? false
              :prompt-text ""
              :history []
              :history-idx 0
              :prompt-start-line 0
              :ns-id nil})

  (local ctx-bar (context-bar-widget.create canvas))

  (fn ensure-ns []
    (when (= nil state.ns-id)
      (set state.ns-id (canvas:create-namespace "eca-prompt-area")))
    state.ns-id)

  (fn render [start-line]
    "Render the prompt area starting at given line.
     Layout: separator → context bar (if any) → prompt line.
     Returns number of lines used."
    (set state.prompt-start-line start-line)
    (let [ns (ensure-ns)
          sep (separator-component.render {:width 50})
          prefix (prompt-prefix-component.render {:loading? state.loading?})
          ctx-state (ctx-bar.get-state)
          has-contexts? (> (length ctx-state.contexts) 0)
          lines [sep.line]]
      ;; Add context bar line if there are contexts
      (when has-contexts?
        (let [parts []]
          (var col 0)
          (each [i ctx (ipairs ctx-state.contexts)]
            (when (> i 1)
              (table.insert parts " "))
            (let [ci (require :eca.ui.components.context-item)
                  rendered (ci.render ctx)]
              (table.insert parts rendered.text)))
          (table.insert lines (table.concat parts ""))))
      ;; Add prompt line
      (table.insert lines (.. prefix.text state.prompt-text))

      ;; Write all lines
      (canvas:set-modifiable true)
      (canvas:set-lines start-line -1 lines)

      ;; Highlight separator
      (canvas:add-extmark ns start-line 0
        {:end_col (length sep.line)
         :hl_group :EcaSeparator})

      ;; Highlight prompt prefix
      (let [prompt-line-idx (- (+ start-line (length lines)) 1)]
        (canvas:add-extmark ns prompt-line-idx 0
          {:end_col (length prefix.text)
           :hl_group prefix.hl-group}))

      ;; Highlight context items if present
      (when has-contexts?
        (ctx-bar.render (+ start-line 1)))

      (canvas:set-modifiable false)

      ;; Position cursor at end of prompt
      (when (canvas:win-valid?)
        (let [prompt-line (+ start-line (length lines))
              col-pos (+ (length prefix.text) (length state.prompt-text))]
          (canvas:set-cursor prompt-line col-pos)))

      ;; Return lines used
      (length lines)))

  (fn get-text []
    "Get the current prompt text from the buffer."
    (let [total (canvas:line-count)
          last-line-idx (- total 1)
          lines (canvas:get-lines last-line-idx total)]
      (when (and lines (> (length lines) 0))
        (let [last-line (. lines 1)
              prefix (prompt-prefix-component.render {:loading? state.loading?})
              prefix-len (length prefix.text)]
          (if (>= (length last-line) prefix-len)
            (string.sub last-line (+ prefix-len 1))
            "")))))

  (fn set-text [text]
    "Set the prompt text."
    (set state.prompt-text (or text ""))
    (let [prefix (prompt-prefix-component.render {:loading? state.loading?})
          total (canvas:line-count)
          last-line-idx (- total 1)]
      (canvas:set-modifiable true)
      (canvas:set-lines last-line-idx total [(.. prefix.text state.prompt-text)])
      (canvas:set-modifiable false)))

  (fn clear []
    "Clear the prompt text."
    (set-text ""))

  (fn set-loading [bool]
    "Toggle loading state (changes prefix '> ' ↔ '⏳')."
    (set state.loading? bool)
    ;; Re-render just the prompt line with new prefix
    (let [prefix (prompt-prefix-component.render {:loading? bool})
          total (canvas:line-count)
          last-line-idx (- total 1)]
      (canvas:set-modifiable true)
      (canvas:set-lines last-line-idx total [(.. prefix.text state.prompt-text)])
      (canvas:set-modifiable false)))

  (fn add-to-history [text]
    "Save text to history."
    (when (and text (not= "" text))
      (table.insert state.history text)
      (set state.history-idx (+ (length state.history) 1))))

  (fn history-prev []
    "Navigate to previous history entry."
    (when (> state.history-idx 1)
      (set state.history-idx (- state.history-idx 1))
      (set-text (. state.history state.history-idx))))

  (fn history-next []
    "Navigate to next history entry."
    (if (< state.history-idx (length state.history))
      (do
        (set state.history-idx (+ state.history-idx 1))
        (set-text (. state.history state.history-idx)))
      (do
        (set state.history-idx (+ (length state.history) 1))
        (set-text ""))))

  (fn add-context [ctx]
    "Add a context item."
    (ctx-bar.add ctx))

  (fn remove-context [name]
    "Remove a context item by name."
    (ctx-bar.remove name))

  (fn get-state []
    state)

  {: render
   : get-text
   : set-text
   : clear
   : set-loading
   : add-to-history
   : history-prev
   : history-next
   : add-context
   : remove-context
   : get-state})

{: create}
