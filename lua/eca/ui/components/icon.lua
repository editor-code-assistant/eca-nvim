-- [nfnl] fnl/eca/ui/components/icon.fnl
local icons = {collapsed = "\226\143\181", expanded = "\226\143\183", pending = "\226\143\179", running = "\226\143\179", success = "\226\156\133", error = "\226\157\140", approval = "\240\159\154\167", loading = "\226\143\179", stop = "\226\143\185", new = "+", close = "\195\151"}
local icon_highlights = {collapsed = "EcaExpandableIcon", expanded = "EcaExpandableIcon", pending = "EcaToolCallPending", running = "EcaToolCallPending", success = "EcaToolCallSuccess", error = "EcaToolCallError", approval = "EcaToolCallApproval", loading = "EcaSpinner", stop = "EcaToolCallError", new = "EcaButtonAccept", close = "EcaButtonReject"}
local function render(_1_)
  local name = _1_.name
  local icon = (icons[name] or "?")
  local hl = (icon_highlights[name] or "EcaExpandableIcon")
  return {text = icon, ["hl-group"] = hl}
end
return {render = render, icons = icons}
