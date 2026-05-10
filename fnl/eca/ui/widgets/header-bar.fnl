;; header-bar widget — winbar with model/agent/variant/mcps info.
;; Stateful: composes key-value components, renders via canvas.

(local key-value (require :eca.ui.components.key-value))

(fn build-winbar-string [state]
  "Build the winbar format string from state.
   Uses %#HlGroup# syntax for Neovim statusline/winbar highlighting."
  (let [{: model : agent : variant : mcps-total : mcps-ready} state
        parts []]
    (when model
      (table.insert parts
        (.. "%#EcaHeaderKey#model%#EcaHeaderValue#:" model)))
    (when agent
      (table.insert parts
        (.. "%#EcaHeaderKey#agent%#EcaHeaderValue#:" agent)))
    (when variant
      (table.insert parts
        (.. "%#EcaHeaderKey#variant%#EcaHeaderValue#:" variant)))
    (when mcps-total
      (let [ready (or mcps-ready 0)
            total mcps-total]
        (table.insert parts
          (.. "%#EcaHeaderKey#mcps%#EcaHeaderValue#:" (tostring ready) "/" (tostring total)))))
    (table.concat parts "  ")))

(fn create [canvas initial-state]
  "Create a header-bar widget.
   initial-state: {: model : agent : variant : mcps-total : mcps-ready}
   Returns {: render : update : get-state}."
  (local state (or initial-state
                 {:model "claude"
                  :agent "coder"
                  :variant nil
                  :mcps-total 0
                  :mcps-ready 0}))

  (fn render []
    (let [winbar (build-winbar-string state)]
      (canvas:set-option :win :winbar winbar)))

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
