-- [nfnl] fnl/eca/ui/components/icon.fnl
local icons = {collapsed = "\226\143\181", expanded = "\226\143\183", loading = "\226\143\179", success = "\226\156\133", error = "\226\157\140", warning = "\226\154\160\239\184\143", info = "\226\132\185\239\184\143", stop = "\226\143\185", new = "+", close = "\195\151"}
local function render(_1_)
  local name = _1_.name
  local text = _1_.text
  local hl_group = _1_["hl-group"]
  return {text = (text or icons[name] or "?"), ["hl-group"] = (hl_group or "Normal")}
end
return {render = render, icons = icons}
