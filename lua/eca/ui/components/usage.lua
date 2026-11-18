-- [nfnl] fnl/eca/ui/components/usage.fnl
local function render(_1_)
  local text = _1_.text
  local hl_group = _1_["hl-group"]
  return {text = (text or ""), ["hl-group"] = (hl_group or "Normal")}
end
return {render = render}
