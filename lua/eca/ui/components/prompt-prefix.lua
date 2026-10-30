-- [nfnl] fnl/eca/ui/components/prompt-prefix.fnl
local function render(_1_)
  local loading_3f = _1_["loading?"]
  if loading_3f then
    return {text = "\226\143\179 ", ["hl-group"] = "EcaPromptPrefixLoading"}
  else
    return {text = "> ", ["hl-group"] = "EcaPromptPrefix"}
  end
end
return {render = render}
