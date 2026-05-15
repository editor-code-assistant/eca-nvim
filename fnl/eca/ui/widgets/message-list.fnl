;; message-list widget — renders text blocks in the buffer.
;; Supports streaming via nvim_buf_set_text (no line shifting).

(local nvim vim.api)
(local message-component (require :eca.ui.components.message))

(fn create [buf-id ?opts]
  (local wrap-write (or (?. ?opts :wrap-write) (fn [f] (f))))
  ;; Called when streaming inserts a new line (so prompt can adjust)
  (local on-line-inserted (or (?. ?opts :on-line-inserted) (fn [] nil)))

  (local state {:messages []
                :ns-id nil
                :end-line 0
                :start-line 0
                :welcome-lines nil
                ;; Streaming state
                :streaming-id nil
                :streaming-queue ""
                :streaming-displayed ""
                :streaming-timer nil
                :streaming-line nil       ;; current line index being streamed to
                :streaming-col nil        ;; current col in that line
                :streaming-chars-per-tick 2
                :streaming-tick-ms 20})

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

  (fn find-message [id]
    (var found nil)
    (each [_ msg (ipairs state.messages)]
      (when (and (not found) (= msg.id id))
        (set found msg)))
    found)

  ;; ── Streaming ─────────────────────────────────────────

  (fn stream-append-char [char]
    "Append a single character to the streaming position using set_text.
     Handles newlines by inserting a new line."
    (when (and state.streaming-line state.streaming-col)
      (if (= char "\n")
        ;; Newline: insert new line, prompt shifts down naturally
        (do
          (wrap-write
            (fn []
              (let [next-line (+ state.streaming-line 1)]
                (nvim.nvim_buf_set_lines buf-id next-line next-line false [""])
                (set state.end-line (+ state.end-line 1))
                (on-line-inserted))))
          (set state.streaming-line (+ state.streaming-line 1))
          (set state.streaming-col 0))
        ;; Regular char: append at current position
        (do
          (nvim.nvim_buf_set_text buf-id
            state.streaming-line state.streaming-col
            state.streaming-line state.streaming-col
            [char])
          (set state.streaming-col (+ state.streaming-col (length char)))))))

  (fn stream-tick []
    "Process one tick: move chars from queue to buffer."
    (when (> (length state.streaming-queue) 0)
      (let [take (math.min state.streaming-chars-per-tick
                           (length state.streaming-queue))]
        (for [i 1 take]
          (let [char (string.sub state.streaming-queue i i)]
            (stream-append-char char)
            (set state.streaming-displayed
              (.. state.streaming-displayed char))))
        (set state.streaming-queue
          (string.sub state.streaming-queue (+ take 1)))))
    ;; Continue or stop
    (if (> (length state.streaming-queue) 0)
      (set state.streaming-timer
        (vim.defer_fn stream-tick state.streaming-tick-ms))
      (set state.streaming-timer nil)))

  (fn start-streaming-timer []
    (when (and (not state.streaming-timer)
               (> (length state.streaming-queue) 0))
      (set state.streaming-timer
        (vim.defer_fn stream-tick state.streaming-tick-ms))))

  ;; ── Public API ────────────────────────────────────────

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
          (let [;; For streaming msg, render with displayed content
                render-msg (if (= msg.id state.streaming-id)
                             (vim.tbl_extend :force msg {:content state.streaming-displayed})
                             msg)
                lines-written (render-single-message render-msg state.end-line)]
            (set state.end-line (+ state.end-line lines-written)))))))

  (fn append-message [msg]
    (table.insert state.messages msg)
    (if msg.streaming?
      ;; Streaming: create an empty line, stream chars into it
      (do
        (set state.streaming-id msg.id)
        (set state.streaming-displayed "")
        (set state.streaming-queue (or msg.content ""))
        ;; Insert one empty line for the streaming message + trailing blank
        (wrap-write
          (fn []
            (nvim.nvim_buf_set_lines buf-id state.end-line state.end-line false ["" ""])
            (set state.streaming-line state.end-line)
            (set state.streaming-col 0)
            (set state.end-line (+ state.end-line 2))))
        (start-streaming-timer))
      ;; Non-streaming: render immediately
      (if (= 1 (length state.messages))
        (render)
        (let [lines-written (render-single-message msg state.end-line)]
          (set state.end-line (+ state.end-line lines-written))))))

  (fn update-message [id new-content]
    (let [msg (find-message id)]
      (when msg
        (tset msg :content new-content)
        (if (= id state.streaming-id)
          ;; Queue only NEW characters
          (let [already (+ (length state.streaming-displayed)
                           (length state.streaming-queue))
                new-chars (when (> (length new-content) already)
                            (string.sub new-content (+ already 1)))]
            (when (and new-chars (> (length new-chars) 0))
              (set state.streaming-queue (.. state.streaming-queue new-chars))
              (start-streaming-timer)))
          ;; Non-streaming: re-render
          (render)))))

  (fn finish-streaming [id]
    (when (= id state.streaming-id)
      ;; Stop timer
      (when state.streaming-timer
        (set state.streaming-timer nil))
      ;; Flush remaining queue char by char (fast, no timer)
      (when (> (length state.streaming-queue) 0)
        (for [i 1 (length state.streaming-queue)]
          (let [char (string.sub state.streaming-queue i i)]
            (stream-append-char char)))
        (set state.streaming-displayed
          (.. state.streaming-displayed state.streaming-queue))
        (set state.streaming-queue ""))
      ;; Clear streaming state
      (set state.streaming-id nil)
      (set state.streaming-line nil)
      (set state.streaming-col nil)))

  (fn clear []
    (set state.messages [])
    (set state.end-line state.start-line)
    (when state.streaming-timer
      (set state.streaming-timer nil))
    (set state.streaming-id nil)
    (set state.streaming-queue "")
    (set state.streaming-displayed "")
    (set state.streaming-line nil)
    (set state.streaming-col nil)
    (render))

  (fn get-state [] state)
  (fn get-end-line [] state.end-line)

  {: render : append-message : update-message : finish-streaming
   : clear : get-state : get-end-line : set-start-line : set-welcome})

{: create}
