;; context-item component — renders a tagged text item.
;; Stateless, pure function. Zero business logic.

(fn render [{: text : hl-group}]
  "Render a context item.
   text: display text (e.g. '@file.lua', '@repoMap')
   hl-group: highlight group
   Returns {: text : hl-group}."
  {:text (or text "")
   :hl-group (or hl-group :Normal)})

{: render}
