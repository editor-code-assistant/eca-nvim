;; prompt-area widget — separator + status + stop + prompt.

(local nvim vim.api)
(local prompt-prefix-component (require :eca.ui.components.prompt-prefix))

(fn create [buf-id ?opts]
  (local wrap-write (or (?. ?opts :wrap-write) (fn [f] (f))))
  (local state {:prompt-text ""
                :loading? false
                :history []
                :history-idx 0
                :prompt-start-line 0
                :status-anchor-line 0
                :ns-id nil
                :status-text nil
                :status-timer nil
                :status-dots 0
                :status-extmark-id nil
                :stop-extmark-id nil
                :steering-text nil})

  (local idle-prefix (prompt-prefix-component.render {:loading? false}))
  (local loading-prefix (prompt-prefix-component.render {:loading? true}))

  (fn ensure-ns []
    (when (= nil state.ns-id)
      (set state.ns-id (nvim.nvim_create_namespace "eca-prompt-area")))
    state.ns-id)

  (fn update-status-virt []
    "Update status virtual text below the separator (before context-area)."
    (let [ns (ensure-ns)]
      (when state.status-extmark-id
        (pcall nvim.nvim_buf_del_extmark buf-id ns state.status-extmark-id)
        (set state.status-extmark-id nil))
      (when state.status-text
        (let [dots (string.rep "." (+ (% state.status-dots 3) 1))
              status-str (.. state.status-text dots)]
          (set state.status-extmark-id
            (nvim.nvim_buf_set_extmark buf-id ns state.status-anchor-line 0
              {:virt_lines [[[status-str :EcaSpinner]]]}))))))

  (fn update-stop-virt []
    "Update stop virtual text above the prompt line."
    (let [ns (ensure-ns)]
      (when state.stop-extmark-id
        (pcall nvim.nvim_buf_del_extmark buf-id ns state.stop-extmark-id)
        (set state.stop-extmark-id nil))
      (when state.loading?
        (set state.stop-extmark-id
          (nvim.nvim_buf_set_extmark buf-id ns state.prompt-start-line 0
            {:virt_lines_above true
             :virt_lines [[[loading-prefix.text loading-prefix.hl-group]
                           ["stop" :EcaStopLabel]]]})))))

  (fn update-virt-lines []
    "Update all virtual lines."
    (update-status-virt)
    (update-stop-virt))

  (fn read-live-prompt-text []
    "Read the user's current text from prompt-start-line to end of buffer.
     Supports multi-line input."
    (let [total (nvim.nvim_buf_line_count buf-id)
          start state.prompt-start-line]
      (when (and (> total 0) (<= start (- total 1)))
        (let [lines (nvim.nvim_buf_get_lines buf-id start total false)]
          (when (> (length lines) 0)
            (let [first-line (. lines 1)]
              (when (vim.startswith first-line idle-prefix.text)
                (tset lines 1 (string.sub first-line (+ (length idle-prefix.text) 1)))))
            (table.concat lines "\n"))))))

  (fn save-live-text []
    "Save user's live buffer text to state. Safe to call anytime —
     returns saved text, or empty string if prompt not yet rendered."
    (let [total (nvim.nvim_buf_line_count buf-id)
          start state.prompt-start-line]
      ;; Only read if prompt has been rendered at a valid position
      ;; and the line actually contains our prefix
      (when (and (> start 0) (<= start (- total 1)))
        (let [first-line (or (. (nvim.nvim_buf_get_lines buf-id start (+ start 1) false) 1) "")]
          (when (vim.startswith first-line idle-prefix.text)
            (let [live (or (read-live-prompt-text) "")]
              (set state.prompt-text live))))))
    state.prompt-text)

  (fn render [start-line ?skip-read]
    "Render: steering + stop (if loading) + prompt.
     Preserves user's live input text from buffer unless ?skip-read is true."
    ;; Read live text before overwriting (skip when called from builder re-render
    ;; because the buffer was already cleared and state.prompt-text is correct)
    (when (not ?skip-read)
      (let [live-text (or (read-live-prompt-text) state.prompt-text)]
        (set state.prompt-text live-text)))
    (set state.prompt-start-line start-line)
    (let [ns (ensure-ns)
          _ (nvim.nvim_buf_clear_namespace buf-id ns 0 -1)
          lines []]
      ;; 1. Steering line (queued message)
      (when state.steering-text
        (let [truncated (if (> (length state.steering-text) 50)
                          (.. (string.sub state.steering-text 1 50) "...")
                          state.steering-text)]
          (table.insert lines (.. "Steering: " truncated " [-]"))))
      ;; 2. Prompt (always "> " + preserved user text, may be multi-line)
      (let [text-lines (vim.split state.prompt-text "\n" {:plain true})]
        (table.insert lines (.. idle-prefix.text (or (. text-lines 1) "")))
        (for [i 2 (length text-lines)]
          (table.insert lines (. text-lines i))))

      ;; Write all lines
      (nvim.nvim_buf_set_lines buf-id start-line -1 false lines)

      ;; Compute prompt line index (always the last rendered line)
      (let [prompt-line-idx (- (+ start-line (length lines)) 1)]
        (set state.prompt-start-line prompt-line-idx)

        ;; Highlight steering line (one above prompt)
        (when state.steering-text
          (let [steering-line-idx (- prompt-line-idx 1)
                line-text (. lines (+ (- steering-line-idx start-line) 1))
                cancel-start (- (length line-text) 3)]
            (nvim.nvim_buf_set_extmark buf-id ns steering-line-idx 0
              {:end_col (math.min 10 (length line-text))
               :hl_group :EcaSteeringLabel})
            (nvim.nvim_buf_set_extmark buf-id ns steering-line-idx cancel-start
              {:end_col (length line-text)
               :hl_group :EcaStopLabel})))

        ;; Highlight prompt prefix "> "
        (let [buf-line (or (. (nvim.nvim_buf_get_lines buf-id prompt-line-idx (+ prompt-line-idx 1) false) 1) "")]
          (when (>= (length buf-line) (length idle-prefix.text))
            (nvim.nvim_buf_set_extmark buf-id ns prompt-line-idx 0
              {:end_col (length idle-prefix.text)
               :hl_group idle-prefix.hl-group}))))

      ;; Virtual lines above prompt: status + stop
      (update-virt-lines)

      (length lines)))

  (fn render-highlights [prompt-line]
    "Apply highlights and virtual text to a prompt already written in the buffer.
     Used by the builder when it writes all lines in one shot."
    (set state.prompt-start-line prompt-line)
    (let [ns (ensure-ns)]
      (nvim.nvim_buf_clear_namespace buf-id ns 0 -1)
      ;; Highlight prompt prefix "> "
      (let [buf-line (or (. (nvim.nvim_buf_get_lines buf-id prompt-line (+ prompt-line 1) false) 1) "")]
        (when (>= (length buf-line) (length idle-prefix.text))
          (nvim.nvim_buf_set_extmark buf-id ns prompt-line 0
            {:end_col (length idle-prefix.text)
             :hl_group idle-prefix.hl-group})))
      ;; Virtual lines: status + stop
      (update-virt-lines)))

  ;; ── Status indicator ──────────────────────────────────

  (fn animate-dots []
    (set state.status-dots (+ state.status-dots 1))
    (when (and state.status-text (nvim.nvim_buf_is_valid buf-id))
      (update-virt-lines)))

  (fn set-status [text]
    (if text
      (do
        (set state.status-text text)
        (set state.status-dots 0)
        (when (not state.status-timer)
          (fn tick []
            (when state.status-text
              (animate-dots)
              (set state.status-timer
                (vim.defer_fn tick 400))))
          (set state.status-timer (vim.defer_fn tick 400))))
      (do
        (set state.status-text nil)
        (set state.status-timer nil)
        (update-virt-lines))))

  ;; ── Loading ───────────────────────────────────────────

  (fn set-loading [bool]
    (set state.loading? bool)
    (update-virt-lines))

  (fn set-status-anchor-line [line]
    "Set the buffer line where status virtual text should be anchored."
    (set state.status-anchor-line line))

  (fn set-steering [text]
    "Set steering/queued message text. nil to clear."
    (set state.steering-text text))

  ;; ── Text management ───────────────────────────────────

  (fn get-text []
    "Read prompt text from prompt-start-line to end of buffer.
     Supports multi-line input (user pressed Enter)."
    (let [total (nvim.nvim_buf_line_count buf-id)
          start state.prompt-start-line
          lines (nvim.nvim_buf_get_lines buf-id start total false)]
      ;; Strip the "> " prefix from the first line
      (when (> (length lines) 0)
        (let [first-line (. lines 1)]
          (when (vim.startswith first-line idle-prefix.text)
            (tset lines 1 (string.sub first-line (+ (length idle-prefix.text) 1))))))
      (table.concat lines "\n")))

  (fn set-text [text]
    (set state.prompt-text (or text ""))
    (when (not state.loading?)
      (let [start state.prompt-start-line
            total (nvim.nvim_buf_line_count buf-id)
            text-lines (vim.split state.prompt-text "\n" {:plain true})
            buf-lines []]
        ;; First line gets the "> " prefix
        (table.insert buf-lines (.. idle-prefix.text (or (. text-lines 1) "")))
        ;; Remaining lines go as-is
        (for [i 2 (length text-lines)]
          (table.insert buf-lines (. text-lines i)))
        (nvim.nvim_buf_set_lines buf-id start total false buf-lines))))

  (fn set-text-internal [text]
    "Update internal prompt-text state without writing to the buffer."
    (set state.prompt-text (or text "")))

  (fn clear [] (set-text ""))

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

  ;; Strip "> " prefix from yanked text on the prompt line.
  (nvim.nvim_create_autocmd :TextYankPost
    {:buffer buf-id
     :callback (fn []
                 (let [event vim.v.event
                       lines event.regcontents
                       first (or (. lines 1) "")]
                   (when (vim.startswith first idle-prefix.text)
                     (let [stripped (string.sub first (+ (length idle-prefix.text) 1))
                           reg (or event.regname "\"")]
                       (tset lines 1 stripped)
                       (vim.schedule
                         (fn []
                           (vim.fn.setreg reg lines event.regtype)
                           (when (not= reg "+") (vim.fn.setreg "+" lines event.regtype))
                           (when (not= reg "*") (vim.fn.setreg "*" lines event.regtype))))))))})

  (fn get-state [] state)

  {: render : render-highlights : get-text : save-live-text
   : set-text : set-text-internal : clear
   : set-status : set-loading : set-steering : set-status-anchor-line
   : add-to-history : history-prev : history-next
   : get-state})

{: create}
