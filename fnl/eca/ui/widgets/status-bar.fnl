;; status-bar widget — generic statusline with sections.
;; Zero business logic. Receives pre-formatted sections.

(fn create [canvas initial-sections]
  "Create a status-bar widget.
   initial-sections: {: left : center : right}
   Each section is a list of {: text : hl-group}.
   Returns {: render : update : get-state}."
  (local state {:left (or (?. initial-sections :left) [])
                :center (or (?. initial-sections :center) [])
                :right (or (?. initial-sections :right) [])})

  (fn build-section [items]
    (let [parts (icollect [_ item (ipairs items)]
                  (.. "%#" (or item.hl-group "Normal") "# " item.text " "))]
      (table.concat parts "")))

  (fn build-statusline []
    (let [left (build-section state.left)
          center (build-section state.center)
          right (build-section state.right)]
      (.. left "%=" center "%=" right)))

  (fn render []
    (let [statusline (build-statusline)]
      (canvas:set-option :win :statusline statusline)))

  (fn update [new-sections]
    (when new-sections.left
      (set state.left new-sections.left))
    (when new-sections.center
      (set state.center new-sections.center))
    (when new-sections.right
      (set state.right new-sections.right))
    (render))

  (fn get-state []
    state)

  {: render
   : update
   : get-state})

{: create}
