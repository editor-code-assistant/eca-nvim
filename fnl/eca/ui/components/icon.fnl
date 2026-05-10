;; icon component — maps semantic names to unicode icons.
;; Stateless, pure function.

(local icons
  {:collapsed  "⏵"
   :expanded   "⏷"
   :pending    "⏳"
   :running    "⏳"
   :success    "✅"
   :error      "❌"
   :approval   "🚧"
   :loading    "⏳"
   :stop       "⏹"
   :new        "+"
   :close      "×"})

(local icon-highlights
  {:collapsed  :EcaExpandableIcon
   :expanded   :EcaExpandableIcon
   :pending    :EcaToolCallPending
   :running    :EcaToolCallPending
   :success    :EcaToolCallSuccess
   :error      :EcaToolCallError
   :approval   :EcaToolCallApproval
   :loading    :EcaSpinner
   :stop       :EcaToolCallError
   :new        :EcaButtonAccept
   :close      :EcaButtonReject})

(fn render [{: name}]
  "Render an icon by semantic name.
   Returns {: text : hl-group}."
  (let [icon (or (. icons name) "?")
        hl (or (. icon-highlights name) :EcaExpandableIcon)]
    {:text icon
     :hl-group hl}))

{: render
 : icons}
