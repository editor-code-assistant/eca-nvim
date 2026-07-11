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
  local collapsed_3f = _2_["collapsed?"]
  local collapse_prefix = _2_["collapse-prefix"]
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
  if collapsed_3f then
    local cpfx = (collapse_prefix or "\226\150\184 ")
    local first_content = (content_lines[1] or "")
    local line = (cpfx .. first_content)
    table.insert(lines, line)
    table.insert(highlights, {["line-idx"] = 0, ["hl-group"] = (hl or "EcaExpandableLabel"), ["col-start"] = 0, ["col-end"] = #cpfx})
    table.insert(lines, "")
  else
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
  end
  return {lines = lines, highlights = highlights}
end
return {render = render}
