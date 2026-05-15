;; Highlight groups — linked to standard Neovim groups.

(local nvim vim.api)

(local groups
  {:EcaUser              {:link "Title"}
   :EcaAssistant         {:link "Normal"}
   :EcaSystem            {:link "Comment"}
   :EcaWelcome           {:link "Comment"}
   :EcaMessagePrefix     {:link "Title"}
   :EcaSeparator         {:link "WinSeparator"}
   :EcaPromptPrefix      {:link "Statement"}
   :EcaPromptPrefixLoading {:link "WarningMsg"}
   :EcaToolCallPending   {:link "WarningMsg"}
   :EcaToolCallSuccess   {:link "DiagnosticOk"}
   :EcaToolCallError     {:link "DiagnosticError"}
   :EcaToolCallApproval  {:link "DiagnosticWarn"}
   :EcaExpandableIcon    {:link "Comment"}
   :EcaExpandableLabel   {:link "Bold"}
   :EcaContextFile       {:link "Underlined"}
   :EcaContextDir        {:link "Underlined"}
   :EcaContextRepoMap    {:link "Special"}
   :EcaContextCursor     {:link "Comment"}
   :EcaContextMcp        {:link "String"}
   :EcaHeaderKey         {:link "Comment"}
   :EcaHeaderValue       {:link "Bold"}
   :EcaUsage             {:link "Comment"}
   :EcaElapsed           {:link "Comment"}
   :EcaTrustOn           {:link "DiagnosticError"}
   :EcaTrustOff          {:link "Comment"}
   :EcaSpinner           {:link "WarningMsg"}
   :EcaButtonAccept      {:link "DiagnosticOk"}
   :EcaButtonReject      {:link "DiagnosticError"}
   :EcaStopLabel         {:link "Underlined"}
   :EcaSteeringLabel     {:link "WarningMsg"}
   :EcaTabActive         {:link "TabLineSel"}
   :EcaTabInactive       {:link "TabLine"}
   :EcaTabLoading        {:link "WarningMsg"}})

(fn setup []
  (each [group opts (pairs groups)]
    (nvim.nvim_set_hl 0 group opts)))

{: groups : setup}
