;; prompt-prefix component — renders "> " or "⏳" based on loading state.
;; Stateless, pure function.

(fn render [{: loading?}]
  "Render the prompt prefix.
   Returns {: text : hl-group}."
  (if loading?
    {:text "⏳ "
     :hl-group :EcaPromptPrefixLoading}
    {:text "> "
     :hl-group :EcaPromptPrefix}))

{: render}
