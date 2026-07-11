-- [nfnl] fnl/eca/ui/components/button.fnl
local function render(_1_)
  local label = _1_.label
  local hl_group = _1_["hl-group"]
  local keybind = _1_.keybind
  local display
  if keybind then
    display = (label .. " (" .. keybind .. ")")
  else
    display = label
  end
  return {text = display, ["hl-group"] = (hl_group or "EcaButtonAccept")}
end
return {render = render}
