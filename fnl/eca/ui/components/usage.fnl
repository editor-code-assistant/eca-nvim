;; usage component — renders a formatted text string.
;; Stateless, pure function. Zero business logic.

(fn render [{: text : hl-group}]
  "Render a usage/info text.
   text: pre-formatted display string (e.g. '31K/200K ($0.03)')
   hl-group: highlight group
   Returns {: text : hl-group}."
  {:text (or text "")
   :hl-group (or hl-group :Normal)})

{: render}
