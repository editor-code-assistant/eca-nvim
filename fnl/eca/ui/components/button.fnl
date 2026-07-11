;; button component — renders clickable action buttons like [Accept] [Reject].
;; Stateless, pure function.

(fn render [{: label : hl-group : keybind}]
  "Render a button.
   Returns {: text : hl-group}.
   Format: 'Label (keybind)' or just 'Label'."
  (let [display (if keybind
                  (.. label " (" keybind ")")
                  label)]
    {:text display
     :hl-group (or hl-group :EcaButtonAccept)}))

{: render}
