-- [nfnl] fnl/eca/ui/widgets/expandable-block.fnl
local icon_component = require("eca.ui.components.icon")
local function format_elapsed(ms)
  if (nil == ms) then
    return ""
  else
    local seconds = math.floor((ms / 1000))
    if (seconds >= 60) then
      local mins = math.floor((seconds / 60))
      local secs = (seconds % 60)
      return (tostring(mins) .. "m " .. tostring(secs) .. "s")
    else
      return (tostring(seconds) .. "s")
    end
  end
end
local function build_label(state)
  local expanded_3f = state["expanded?"]
  local type = state.type
  local label = state.label
  local status = state.status
  local elapsed_ms = state["elapsed-ms"]
  local toggle_icon
  local _3_
  if expanded_3f then
    _3_ = "expanded"
  else
    _3_ = "collapsed"
  end
  toggle_icon = icon_component.render({name = _3_})
  local status_icon
  if status then
    status_icon = icon_component.render({name = status})
  else
    status_icon = nil
  end
  local elapsed_str = format_elapsed(elapsed_ms)
  local parts = {toggle_icon.text}
  table.insert(parts, (" " .. (label or (type or "block"))))
  if status_icon then
    table.insert(parts, (" " .. status_icon.text))
  else
  end
  if (elapsed_str and ("" ~= elapsed_str)) then
    table.insert(parts, (" " .. elapsed_str))
  else
  end
  return table.concat(parts, "")
end
local function create(canvas, initial_state)
  local state = vim.tbl_extend("force", {id = nil, type = "tool-call", status = nil, label = "", content = {}, ["elapsed-ms"] = nil, children = {}, ["start-line"] = 0, ["ns-id"] = nil, ["expanded?"] = false}, (initial_state or {}))
  local function ensure_ns()
    if (nil == state["ns-id"]) then
      state["ns-id"] = canvas["create-namespace"](canvas, ("eca-expandable-" .. (state.id or "unknown")))
    else
    end
    return state["ns-id"]
  end
  local function render(start_line)
    state["start-line"] = start_line
    local ns = ensure_ns()
    local label_line = build_label(state)
    local lines = {label_line}
    if state["expanded?"] then
      for _, line in ipairs(state.content) do
        table.insert(lines, ("  " .. line))
      end
    else
    end
    canvas["set-modifiable"](canvas, true)
    canvas["set-lines"](canvas, start_line, start_line, lines)
    canvas["add-extmark"](canvas, ns, start_line, 0, {end_col = #label_line, hl_group = "EcaExpandableLabel"})
    canvas["set-modifiable"](canvas, false)
    return #lines
  end
  local function toggle()
    state["expanded?"] = not state["expanded?"]
    return nil
  end
  local function expand()
    state["expanded?"] = true
    return nil
  end
  local function collapse()
    state["expanded?"] = false
    return nil
  end
  local function update_status(new_status, _3felapsed_ms)
    state.status = new_status
    if _3felapsed_ms then
      state["elapsed-ms"] = _3felapsed_ms
      return nil
    else
      return nil
    end
  end
  local function get_state()
    return state
  end
  return {render = render, toggle = toggle, expand = expand, collapse = collapse, ["update-status"] = update_status, ["get-state"] = get_state}
end
return {create = create}
