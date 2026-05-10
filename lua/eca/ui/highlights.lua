-- [nfnl] fnl/eca/ui/highlights.fnl
local groups = {EcaUser = {fg = "#61afef", bold = true}, EcaAssistant = {fg = "#abb2bf"}, EcaSystem = {fg = "#5c6370", italic = true}, EcaWelcome = {fg = "#5c6370", italic = true}, EcaSeparator = {fg = "#3e4452"}, EcaPromptPrefix = {fg = "#98c379", bold = true}, EcaPromptPrefixLoading = {fg = "#e5c07b"}, EcaToolCallPending = {fg = "#e5c07b"}, EcaToolCallSuccess = {fg = "#98c379"}, EcaToolCallError = {fg = "#e06c75"}, EcaToolCallApproval = {fg = "#d19a66", bg = "#3e3522", bold = true}, EcaExpandableIcon = {fg = "#5c6370"}, EcaExpandableLabel = {bold = true}, EcaContextFile = {fg = "#e06c75", underline = true}, EcaContextDir = {fg = "#e06c75", underline = true}, EcaContextRepoMap = {fg = "#56b6c2"}, EcaContextCursor = {fg = "#5c6370"}, EcaContextMcp = {fg = "#98c379"}, EcaHeaderKey = {fg = "#5c6370"}, EcaHeaderValue = {fg = "#abb2bf", bold = true}, EcaUsage = {fg = "#5c6370"}, EcaElapsed = {fg = "#5c6370"}, EcaTrustOn = {fg = "#e06c75", bold = true}, EcaTrustOff = {fg = "#5c6370"}, EcaSpinner = {fg = "#e5c07b"}, EcaButtonAccept = {fg = "#98c379", bold = true}, EcaButtonReject = {fg = "#e06c75", bold = true}, EcaTabActive = {fg = "#abb2bf", bold = true}, EcaTabInactive = {fg = "#5c6370"}, EcaTabLoading = {fg = "#e5c07b"}}
local function setup(canvas)
  for group, opts in pairs(groups) do
    canvas["set-hl"](canvas, 0, group, opts)
  end
  return nil
end
return {groups = groups, setup = setup}
