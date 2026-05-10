-- [nfnl] fnl/eca/ui/components/message.fnl
local role_config = {user = {prefix = "  You", ["hl-group"] = "EcaUser"}, assistant = {prefix = "  ECA", ["hl-group"] = "EcaAssistant"}, system = {prefix = "  System", ["hl-group"] = "EcaSystem"}}
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
  local role = _2_.role
  local content = _2_.content
  local cfg = (role_config[role] or {prefix = "  ?", ["hl-group"] = "EcaAssistant"})
  local content_lines = split_lines((content or ""))
  local lines = {cfg.prefix, ""}
  local highlights = {{["line-idx"] = 0, ["hl-group"] = cfg["hl-group"], ["col-start"] = 0, ["col-end"] = #cfg.prefix}}
  for _, line in ipairs(content_lines) do
    table.insert(lines, line)
  end
  table.insert(lines, "")
  return {lines = lines, highlights = highlights}
end
local function render_welcome()
  local lines = {"", "  Welcome to ECA Chat", "", "  Type your message below and press Enter to send.", "  Use @ to attach context (files, directories, etc.)", ""}
  return {lines = lines, highlights = {{["line-idx"] = 1, ["hl-group"] = "EcaWelcome", ["col-start"] = 0, ["col-end"] = #"  Welcome to ECA Chat"}}}
end
return {render = render, ["render-welcome"] = render_welcome}
