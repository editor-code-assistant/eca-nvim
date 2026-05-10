;; Highlight groups — declarative definitions for all UI elements.
;; Receives a canvas to apply them. Supports dark and light themes.

(local groups
  {;; Messages
   :EcaUser              {:fg "#61afef" :bold true}
   :EcaAssistant         {:fg "#abb2bf"}
   :EcaSystem            {:fg "#5c6370" :italic true}
   :EcaWelcome           {:fg "#5c6370" :italic true}
   :EcaSeparator         {:fg "#3e4452"}

   ;; Prompt
   :EcaPromptPrefix        {:fg "#98c379" :bold true}
   :EcaPromptPrefixLoading {:fg "#e5c07b"}

   ;; Tool calls
   :EcaToolCallPending  {:fg "#e5c07b"}
   :EcaToolCallSuccess  {:fg "#98c379"}
   :EcaToolCallError    {:fg "#e06c75"}
   :EcaToolCallApproval {:fg "#d19a66" :bg "#3e3522" :bold true}

   ;; Expandable blocks
   :EcaExpandableIcon   {:fg "#5c6370"}
   :EcaExpandableLabel  {:bold true}

   ;; Context items
   :EcaContextFile      {:fg "#e06c75" :underline true}
   :EcaContextDir       {:fg "#e06c75" :underline true}
   :EcaContextRepoMap   {:fg "#56b6c2"}
   :EcaContextCursor    {:fg "#5c6370"}
   :EcaContextMcp       {:fg "#98c379"}

   ;; Header bar
   :EcaHeaderKey        {:fg "#5c6370"}
   :EcaHeaderValue      {:fg "#abb2bf" :bold true}

   ;; Status bar
   :EcaUsage            {:fg "#5c6370"}
   :EcaElapsed          {:fg "#5c6370"}
   :EcaTrustOn          {:fg "#e06c75" :bold true}
   :EcaTrustOff         {:fg "#5c6370"}
   :EcaSpinner          {:fg "#e5c07b"}

   ;; Buttons
   :EcaButtonAccept     {:fg "#98c379" :bold true}
   :EcaButtonReject     {:fg "#e06c75" :bold true}

   ;; Tab bar
   :EcaTabActive        {:fg "#abb2bf" :bold true}
   :EcaTabInactive      {:fg "#5c6370"}
   :EcaTabLoading       {:fg "#e5c07b"}})

(fn setup [canvas]
  "Apply all highlight groups using the provided canvas."
  (each [group opts (pairs groups)]
    (canvas:set-hl 0 group opts)))

{: groups
 : setup}
