-- [nfnl] fnl/eca/ui/components/separator.fnl
local function render(_1_)
  local char = _1_.char
  local width = _1_.width
  local c = (char or "\226\148\128")
  local w = (width or 40)
  local line = string.rep(c, w)
  return {line = line, highlights = {{["hl-group"] = "EcaSeparator", ["col-start"] = 0, ["col-end"] = #line}}}
end
return {render = render}
