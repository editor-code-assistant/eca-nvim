-- [nfnl] fnl/eca/ui/components/message.fnl
local function split_lines(text)
  local lines = {}
  if ((nil == text) or ("" == text)) then
    table.insert(lines, "")
  else
    for line in text:gmatch("([^\n]*)\n?") do
      table.insert(lines, line)
    end
  end
  return lines
end
local function render(_2_)
  local content = _2_.content
  local prefix = _2_.prefix
  local hl_group = _2_["hl-group"]
  local pfx = (prefix or "")
  local hl
  local or_3_ = hl_group
  if not or_3_ then
    if (prefix and (#prefix > 0)) then
      or_3_ = "EcaMessagePrefix"
    else
      or_3_ = nil
    end
  end
  hl = or_3_
  local content_lines = split_lines((content or ""))
  local lines = {}
  local highlights = {}
  for i, line in ipairs(content_lines) do
    local full
    if (i == 1) then
      full = (pfx .. line)
    else
      full = line
    end
    table.insert(lines, full)
    if hl then
      table.insert(highlights, {["line-idx"] = (#lines - 1), ["hl-group"] = hl, ["col-start"] = 0, ["col-end"] = #full})
    else
    end
  end
  table.insert(lines, "")
  return {lines = lines, highlights = highlights}
end
return {render = render}
