-- [nfnl] fnl/eca/ui/highlights.fnl
local nvim = vim.api
local groups = {EcaUser = {link = "Title"}, EcaAssistant = {link = "Normal"}, EcaSystem = {link = "Comment"}, EcaWelcome = {link = "Comment"}, EcaMessagePrefix = {link = "Title"}, EcaSeparator = {link = "WinSeparator"}, EcaPromptPrefix = {link = "Statement"}, EcaPromptPrefixLoading = {link = "WarningMsg"}, EcaToolCallPending = {link = "WarningMsg"}, EcaToolCallSuccess = {link = "DiagnosticOk"}, EcaToolCallError = {link = "DiagnosticError"}, EcaToolCallApproval = {link = "DiagnosticWarn"}, EcaExpandableIcon = {link = "Comment"}, EcaExpandableLabel = {link = "Bold"}, EcaContextFile = {link = "Underlined"}, EcaContextDir = {link = "Underlined"}, EcaContextRepoMap = {link = "Special"}, EcaContextCursor = {link = "Comment"}, EcaContextMcp = {link = "String"}, EcaHeaderKey = {link = "Comment"}, EcaHeaderValue = {link = "Bold"}, EcaUsage = {link = "Comment"}, EcaElapsed = {link = "Comment"}, EcaTrustOn = {link = "DiagnosticError"}, EcaTrustOff = {link = "Comment"}, EcaSpinner = {link = "WarningMsg"}, EcaButtonAccept = {link = "DiagnosticOk"}, EcaButtonReject = {link = "DiagnosticError"}, EcaTabActive = {link = "TabLineSel"}, EcaTabInactive = {link = "TabLine"}, EcaTabLoading = {link = "WarningMsg"}}
local function setup()
  for group, opts in pairs(groups) do
    nvim.nvim_set_hl(0, group, opts)
  end
  return nil
end
return {groups = groups, setup = setup}
