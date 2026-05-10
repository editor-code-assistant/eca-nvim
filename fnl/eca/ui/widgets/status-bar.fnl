;; status-bar widget — custom statusline for chat window.
;; Stateful: displays workspace, elapsed, usage, trust.

(local usage-component (require :eca.ui.components.usage))

(fn format-elapsed [ms]
  "Format elapsed milliseconds for statusline."
  (if (= nil ms) nil
      (let [seconds (math.floor (/ ms 1000))]
        (if (>= seconds 60)
          (let [mins (math.floor (/ seconds 60))
                secs (% seconds 60)]
            (.. (tostring mins) "m " (tostring secs) "s"))
          (.. (tostring seconds) "s")))))

(fn create [canvas initial-state]
  "Create a status-bar widget.
   initial-state: {: workspaces : elapsed-ms : tokens-in : tokens-out : max-tokens : cost : trust? : init-progress : pending-approvals?}
   Returns {: render : update : get-state}."
  (var state (vim.tbl_extend :force
               {:workspaces []
                :elapsed-ms nil
                :tokens-in 0
                :tokens-out 0
                :max-tokens 200000
                :cost nil
                :trust? false
                :init-progress nil
                :pending-approvals? false}
               (or initial-state {})))

  (fn build-statusline []
    "Build statusline format string."
    (let [parts []]
      ;; Workspace folders
      (when (> (length state.workspaces) 0)
        (table.insert parts
          (.. "%#EcaHeaderValue# " (table.concat state.workspaces ", ") " ")))

      ;; Spacer
      (table.insert parts "%=")

      ;; Init progress
      (when state.init-progress
        (table.insert parts
          (.. "%#EcaSpinner# ⏳ " state.init-progress " ")))

      ;; Elapsed time
      (let [elapsed (format-elapsed state.elapsed-ms)]
        (when elapsed
          (let [icon (if state.pending-approvals? "🚧" "⏱")]
            (table.insert parts
              (.. "%#EcaElapsed# " icon " " elapsed " ")))))

      ;; Token usage
      (let [usage-rendered (usage-component.render state)]
        (table.insert parts
          (.. "%#EcaUsage# " usage-rendered.text " ")))

      ;; Trust indicator
      (if state.trust?
        (table.insert parts "%#EcaTrustOn# 🔥 ")
        (table.insert parts "%#EcaTrustOff# 🛡️ "))

      (table.concat parts "")))

  (fn render []
    (let [statusline (build-statusline)]
      (canvas:set-option :win :statusline statusline)))

  (fn update [new-state]
    (each [k v (pairs new-state)]
      (tset state k v))
    (render))

  (fn get-state []
    state)

  {: render
   : update
   : get-state})

{: create}
