;; builder — orchestrates widgets, receives injected dependencies.
;; Builds a canvas from api functions and injects it into widgets.
;; The builder NEVER imports vim.api — all interaction goes through injected api.

(local highlights (require :eca.ui.highlights))
(local header-bar-widget (require :eca.ui.widgets.header-bar))
(local message-list-widget (require :eca.ui.widgets.message-list))
(local prompt-area-widget (require :eca.ui.widgets.prompt-area))
(local status-bar-widget (require :eca.ui.widgets.status-bar))
(local tab-bar-widget (require :eca.ui.widgets.tab-bar))

;; ── Canvas builder ──────────────────────────────────────

(fn build-canvas [api buf-id win-id]
  "Build a canvas object from flat api functions, bound to a specific buf/win.
   This is the bridge between the flat api module and the canvas protocol
   that widgets expect."
  (let [buf buf-id
        win win-id]

  {:set-lines
   (fn [_ start end lines]
     (api.buf-set-lines buf start end lines))

   :get-lines
   (fn [_ start end]
     (api.buf-get-lines buf start end))

   :line-count
   (fn [_]
     (api.buf-line-count buf))

   :add-extmark
   (fn [_ ns-id line col opts]
     (api.buf-set-extmark buf ns-id line col opts))

   :del-extmark
   (fn [_ ns-id id]
     (api.buf-del-extmark buf ns-id id))

   :get-extmarks
   (fn [_ ns-id start end opts]
     (api.buf-get-extmarks buf ns-id start end opts))

   :create-namespace
   (fn [_ name]
     (api.create-namespace name))

   :set-option
   (fn [_ scope key value]
     (case scope
       :win (api.set-option :win win key value)
       :buf (api.set-option :buf buf key value)
       :global (api.set-option :global nil key value)))

   :get-option
   (fn [_ scope key]
     (case scope
       :win (api.get-option :win win key)
       :buf (api.get-option :buf buf key)
       :global (api.get-option :global nil key)))

   :get-cursor
   (fn [_]
     (api.win-get-cursor win))

   :set-cursor
   (fn [_ line col]
     (api.win-set-cursor win [line col]))

   :buf-valid?
   (fn [_]
     (api.buf-is-valid buf))

   :win-valid?
   (fn [_]
     (api.win-is-valid win))

   :set-hl
   (fn [_ ns group opts]
     (api.set-hl ns group opts))

   :close-win
   (fn [_]
     (api.win-close win))

   :buf-id (fn [_] buf)
   :win-id (fn [_] win)}))

;; ── Buffer/window setup ─────────────────────────────────

(fn setup-chat-buffer [canvas]
  "Configure the chat buffer options."
  (canvas:set-option :buf :buftype "nofile")
  (canvas:set-option :buf :bufhidden "hide")
  (canvas:set-option :buf :swapfile false)
  (canvas:set-option :buf :filetype "eca-chat"))

(fn setup-chat-window [canvas]
  "Configure the chat window options."
  (canvas:set-option :win :number false)
  (canvas:set-option :win :relativenumber false)
  (canvas:set-option :win :signcolumn "no")
  (canvas:set-option :win :foldcolumn "0")
  (canvas:set-option :win :spell false)
  (canvas:set-option :win :wrap true)
  (canvas:set-option :win :linebreak true)
  (canvas:set-option :win :conceallevel 2))

;; ── Edit guard ──────────────────────────────────────────

(fn setup-edit-guard [api buf-id get-prompt-start-line]
  "Attach to buffer to guard editable region.
   Only the prompt area (from prompt-start-line onwards) is user-editable.
   Edits outside that region are undone immediately."
  (var internal-edit false)

  (fn set-internal [bool]
    (set internal-edit bool))

  (api.buf-attach buf-id
    {:on_lines
     (fn [_ buf changedtick first-line last-line new-last-line]
       ;; If this is an internal (widget) edit, allow it
       (when (not internal-edit)
         (let [prompt-start (get-prompt-start-line)]
           ;; If the edit touches lines before the prompt area, undo it
           (when (< first-line prompt-start)
             (api.schedule
               (fn []
                 (when (api.buf-is-valid buf)
                   (vim.cmd "silent! undo"))))))))})

  ;; Return a function to wrap internal edits
  set-internal)

;; ── Main entry ──────────────────────────────────────────

(fn create-chat-ui [{: api : on-submit : on-approve : on-reject
                     : on-stop : on-new-chat : on-select-tab
                     : on-context-add : opts}]
  "Create the chat UI. Receives injected dependencies.
   api: flat module of Neovim API functions (from eca.api)
   on-*: callback functions for user actions
   opts: {: ui} where ui contains {: width : position}

   Returns chat-ui with public API."
  (let [ui-config (or opts.ui {})
        config {:width (or ui-config.width 0.4)
                :position (or ui-config.position :right)}]

    (var canvas nil)
    (var set-internal-edit nil)
    (local widgets {:header nil
                    :messages nil
                    :prompt nil
                    :status nil
                    :tabs nil})

    (fn is-open? []
      (and (not= nil canvas)
           (canvas:buf-valid?)
           (canvas:win-valid?)))

    (fn get-prompt-start-line []
      "Get the line where the prompt area starts."
      (let [state (widgets.prompt.get-state)]
        (or state.prompt-start-line 0)))

    (fn with-internal-edit [f]
      "Wrap a function call as an internal edit (bypasses edit guard)."
      (when set-internal-edit
        (set-internal-edit true))
      (f)
      (when set-internal-edit
        (set-internal-edit false)))

    (fn render-all []
      "Full render of all widgets."
      (with-internal-edit
        (fn []
          (widgets.header.render)
          (widgets.messages.render)
          (let [end-line (widgets.messages.get-end-line)]
            (widgets.prompt.render end-line))
          (widgets.status.render)
          (widgets.tabs.render))))

    (fn open []
      "Open the chat window."
      (when (not (is-open?))
        (let [buf-id (api.buf-create {:listed false :scratch true})
              win-width (math.floor (* (api.editor-width) config.width))
              win-id (api.win-open buf-id
                       {:split :right
                        :width win-width})]
          ;; Build canvas from api functions + buf/win ids
          (set canvas (build-canvas api buf-id win-id))

          ;; Setup highlights, buffer and window options
          (highlights.setup canvas)
          (setup-chat-buffer canvas)
          (setup-chat-window canvas)

          ;; Create widgets — all receive canvas (never api directly)
          (set widgets.header
            (header-bar-widget.create canvas {}))
          (set widgets.messages
            (message-list-widget.create canvas))
          (set widgets.prompt
            (prompt-area-widget.create canvas))
          (set widgets.status
            (status-bar-widget.create canvas {}))
          (set widgets.tabs
            (tab-bar-widget.create canvas
              {:tabs [{:id 1 :title "Chat 1"}]
               :active-id 1}))

          ;; Setup edit guard — only prompt area is user-editable
          (set set-internal-edit
            (setup-edit-guard api buf-id get-prompt-start-line))

          ;; Initial render
          (with-internal-edit
            (fn []
              (canvas:set-lines 0 -1 [""])))
          (render-all))))

    (fn close []
      "Close the chat window."
      (when (is-open?)
        (canvas:close-win)))

    (fn toggle []
      "Toggle the chat window."
      (if (is-open?)
        (close)
        (open)))

    ;; === Message API ===
    (fn append-message [msg]
      (when (is-open?)
        (with-internal-edit
          (fn []
            (widgets.messages.append-message msg)
            (let [end-line (widgets.messages.get-end-line)]
              (widgets.prompt.render end-line))))))

    (fn update-message [id content]
      (when (is-open?)
        (with-internal-edit
          (fn []
            (widgets.messages.update-message id content)
            (let [end-line (widgets.messages.get-end-line)]
              (widgets.prompt.render end-line))))))

    (fn clear-messages []
      (when (is-open?)
        (with-internal-edit
          (fn []
            (widgets.messages.clear)
            (let [end-line (widgets.messages.get-end-line)]
              (widgets.prompt.render end-line))))))

    ;; === Tool call API (TODO) ===
    (fn show-tool-call [tc] nil)
    (fn update-tool-call [id status] nil)
    (fn show-approval [tc] nil)

    ;; === Status API ===
    (fn update-model-info [info]
      (when (is-open?)
        (widgets.header.update info)))

    (fn update-usage [usage]
      (when (is-open?)
        (widgets.status.update usage)))

    (fn update-progress [progress]
      (when (is-open?)
        (widgets.status.update {:init-progress progress})))

    ;; === Context API ===
    (fn add-context [ctx]
      (when (is-open?)
        (with-internal-edit
          (fn []
            (widgets.prompt.add-context ctx)
            (let [end-line (widgets.messages.get-end-line)]
              (widgets.prompt.render end-line))))))

    (fn remove-context [name]
      (when (is-open?)
        (with-internal-edit
          (fn []
            (widgets.prompt.remove-context name)
            (let [end-line (widgets.messages.get-end-line)]
              (widgets.prompt.render end-line))))))

    ;; === Tab API ===
    (fn add-chat-tab [tab]
      (when (is-open?)
        (widgets.tabs.add-tab tab)
        (widgets.tabs.render)))

    (fn remove-chat-tab [id]
      (when (is-open?)
        (widgets.tabs.remove-tab id)
        (widgets.tabs.render)))

    (fn select-chat-tab [id]
      (when (is-open?)
        (widgets.tabs.select-tab id)
        (widgets.tabs.render)))

    ;; === Prompt access ===
    (fn get-prompt-text []
      (when (is-open?)
        (widgets.prompt.get-text)))

    (fn submit-prompt []
      (when (is-open?)
        (let [text (widgets.prompt.get-text)]
          (when (and text (not= "" text))
            (widgets.prompt.add-to-history text)
            (with-internal-edit
              (fn [] (widgets.prompt.clear)))
            (when on-submit
              (on-submit text))))))

    (fn set-loading [bool]
      (when (is-open?)
        (with-internal-edit
          (fn [] (widgets.prompt.set-loading bool)))))

    ;; Public API
    {: open
     : close
     : toggle
     : is-open?
     : append-message
     : update-message
     : clear-messages
     : show-tool-call
     : update-tool-call
     : show-approval
     : update-model-info
     : update-usage
     : update-progress
     : add-context
     : remove-context
     : add-chat-tab
     : remove-chat-tab
     : select-chat-tab
     : get-prompt-text
     : submit-prompt
     : set-loading}))

{: create-chat-ui}
