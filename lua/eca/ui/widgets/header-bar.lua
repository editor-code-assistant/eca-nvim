-- [nfnl] fnl/eca/ui/widgets/header-bar.fnl
local key_value = require("eca.ui.components.key-value")
local function build_winbar_string(state)
  local model = state.model
  local agent = state.agent
  local variant = state.variant
  local mcps_total = state["mcps-total"]
  local mcps_ready = state["mcps-ready"]
  local parts = {}
  if model then
    table.insert(parts, ("%#EcaHeaderKey#model%#EcaHeaderValue#:" .. model))
  else
  end
  if agent then
    table.insert(parts, ("%#EcaHeaderKey#agent%#EcaHeaderValue#:" .. agent))
  else
  end
  if variant then
    table.insert(parts, ("%#EcaHeaderKey#variant%#EcaHeaderValue#:" .. variant))
  else
  end
  if mcps_total then
    local ready = (mcps_ready or 0)
    local total = mcps_total
    table.insert(parts, ("%#EcaHeaderKey#mcps%#EcaHeaderValue#:" .. tostring(ready) .. "/" .. tostring(total)))
  else
  end
  return table.concat(parts, "  ")
end
local function create(canvas, initial_state)
  local state = (initial_state or {model = "claude", agent = "coder", variant = nil, ["mcps-total"] = 0, ["mcps-ready"] = 0})
  local function render()
    local winbar = build_winbar_string(state)
    return canvas["set-option"](canvas, "win", "winbar", winbar)
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
