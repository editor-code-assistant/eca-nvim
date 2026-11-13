-- [nfnl] fnl/eca/ui/widgets/expandable-block.fnl
local function create(canvas, initial_state)
  local state = vim.tbl_extend("force", {id = nil, label = "", ["icon-expanded"] = "\226\143\183", ["icon-collapsed"] = "\226\143\181", content = {}, ["start-line"] = 0, ["ns-id"] = nil, ["expanded?"] = false}, (initial_state or {}))
  local function ensure_ns()
    if (nil == state["ns-id"]) then
      state["ns-id"] = canvas["create-namespace"](canvas, ("eca-expandable-" .. (state.id or "unknown")))
    else
    end
    return state["ns-id"]
  end
  local function build_label()
    local icon
    if state["expanded?"] then
      icon = state["icon-expanded"]
    else
      icon = state["icon-collapsed"]
    end
    return (icon .. " " .. state.label)
  end
  local function render(start_line)
    state["start-line"] = start_line
    local ns = ensure_ns()
    local label_line = build_label()
    local lines = {label_line}
    if state["expanded?"] then
      for _, line in ipairs(state.content) do
        table.insert(lines, ("  " .. line))
      end
    else
    end
    canvas["set-lines"](canvas, start_line, start_line, lines)
    canvas["add-extmark"](canvas, ns, start_line, 0, {end_col = #label_line, hl_group = "EcaExpandableLabel"})
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
  local function update_label(new_label)
    state.label = new_label
    return nil
  end
  local function get_state()
    return state
  end
  return {render = render, toggle = toggle, expand = expand, collapse = collapse, ["update-label"] = update_label, ["get-state"] = get_state}
end
return {create = create}
