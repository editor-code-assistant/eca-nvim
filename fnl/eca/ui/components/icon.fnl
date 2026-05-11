;; icon component — maps UI semantic names to unicode icons.
;; Stateless, pure function. Handles UI concepts, not business logic.

(local icons
  {:collapsed  "⏵"
   :expanded   "⏷"
   :loading    "⏳"
   :success    "✅"
   :error      "❌"
   :warning    "⚠️"
   :info       "ℹ️"
   :stop       "⏹"
   :new        "+"
   :close      "×"})

(fn render [{: name : text : hl-group}]
  "Render an icon by semantic name or direct text.
   name: lookup key (e.g. :collapsed, :success)
   text: direct icon text (overrides name lookup)
   hl-group: highlight group
   Returns {: text : hl-group}."
  {:text (or text (. icons name) "?")
   :hl-group (or hl-group :Normal)})

{: render
 : icons}
