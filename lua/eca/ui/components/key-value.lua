-- [nfnl] fnl/eca/ui/components/key-value.fnl
local function render(_1_)
  local title = _1_.title
  local value = _1_.value
  local hl_title = _1_["hl-title"]
  local hl_value = _1_["hl-value"]
  local title_str = (title or "")
  local value_str = (value or "")
  local separator = ":"
  local line = (title_str .. separator .. value_str)
  local title_end = #title_str
  local value_start = (title_end + #separator)
  local value_end = (value_start + #value_str)
  return {line = line, highlights = {{["hl-group"] = (hl_title or "EcaHeaderKey"), ["col-start"] = 0, ["col-end"] = title_end}, {["hl-group"] = (hl_value or "EcaHeaderValue"), ["col-start"] = value_start, ["col-end"] = value_end}}}
end
return {render = render}
