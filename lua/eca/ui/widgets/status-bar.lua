-- [nfnl] fnl/eca/ui/widgets/status-bar.fnl
local usage_component = require("eca.ui.components.usage")
local function format_elapsed(ms)
  if (nil == ms) then
    return nil
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
local function create(canvas, initial_state)
  local state = vim.tbl_extend("force", {workspaces = {}, ["elapsed-ms"] = nil, ["tokens-in"] = 0, ["tokens-out"] = 0, ["max-tokens"] = 200000, cost = nil, ["init-progress"] = nil, ["pending-approvals?"] = false, ["trust?"] = false}, (initial_state or {}))
  local function build_statusline()
    local parts = {}
    if (#state.workspaces > 0) then
      table.insert(parts, ("%#EcaHeaderValue# " .. table.concat(state.workspaces, ", ") .. " "))
    else
    end
    table.insert(parts, "%=")
    if state["init-progress"] then
      table.insert(parts, ("%#EcaSpinner# \226\143\179 " .. state["init-progress"] .. " "))
    else
    end
    do
      local elapsed = format_elapsed(state["elapsed-ms"])
      if elapsed then
        local icon
        if state["pending-approvals?"] then
          icon = "\240\159\154\167"
        else
          icon = "\226\143\177"
        end
        table.insert(parts, ("%#EcaElapsed# " .. icon .. " " .. elapsed .. " "))
      else
      end
    end
    do
      local usage_rendered = usage_component.render(state)
      table.insert(parts, ("%#EcaUsage# " .. usage_rendered.text .. " "))
    end
    if state["trust?"] then
      table.insert(parts, "%#EcaTrustOn# \240\159\148\165 ")
    else
      table.insert(parts, "%#EcaTrustOff# \240\159\155\161\239\184\143 ")
    end
    return table.concat(parts, "")
  end
  local function render()
    local statusline = build_statusline()
    return canvas["set-option"](canvas, "win", "statusline", statusline)
  end
  local function update(new_state)
    for k, v in pairs(new_state) do
      state[k] = v
    end
    return render()
  end
  local function get_state()
    return state
  end
  return {render = render, update = update, ["get-state"] = get_state}
end
return {create = create}
