-- [nfnl] fnl/eca/ui/widgets/steering-area.fnl
local nvim = vim.api
local function create(buf_id)
  local state = {items = {}, ["ns-id"] = nil, ["start-line"] = 0, ["end-line"] = 0}
  local function ensure_ns()
    if (nil == state["ns-id"]) then
      state["ns-id"] = nvim.nvim_create_namespace("eca-steering-area")
    else
    end
    return state["ns-id"]
  end
  local function has_items_3f()
    return (#state.items > 0)
  end
  local function apply_virt_text(line_num)
    local ns = ensure_ns()
    local combined = table.concat(state.items, "\n")
    local truncated
    if (#combined > 60) then
      truncated = (string.sub(combined, 1, 60) .. "...")
    else
      truncated = combined
    end
    local prefix = ("Steering: " .. truncated .. " [")
    nvim.nvim_buf_set_extmark(buf_id, ns, line_num, 0, {virt_text = {{prefix, "EcaSteeringLabel"}}, virt_text_pos = "inline"})
    nvim.nvim_buf_set_extmark(buf_id, ns, line_num, 1, {virt_text = {{"]", "EcaStopLabel"}}, virt_text_pos = "inline"})
    return nvim.nvim_buf_set_extmark(buf_id, ns, line_num, 0, {end_col = 1, hl_group = "EcaStopLabel"})
  end
  local function render(start_line)
    state["start-line"] = start_line
    local ns = ensure_ns()
    nvim.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
    if not has_items_3f() then
      state["end-line"] = start_line
      return 0
    else
      nvim.nvim_buf_set_lines(buf_id, start_line, start_line, false, {"-"})
      state["end-line"] = (start_line + 1)
      apply_virt_text(start_line)
      return 1
    end
  end
  local function render_highlights(line_num)
    state["start-line"] = line_num
    state["end-line"] = (line_num + 1)
    if has_items_3f() then
      local ns = ensure_ns()
      nvim.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
      return apply_virt_text(line_num)
    else
      return nil
    end
  end
  local function set_items(items)
    state.items = (items or {})
    return nil
  end
  local function is_on_steering_line_3f()
    local and_5_ = has_items_3f()
    if and_5_ then
      local cursor = nvim.nvim_win_get_cursor(0)
      local row = cursor[1]
      and_5_ = (row == (state["start-line"] + 1))
    end
    return and_5_
  end
  local function clear()
    state.items = {}
    return nil
  end
  local function get_state()
    return state
  end
  local function get_end_line()
    return state["end-line"]
  end
  return {render = render, ["render-highlights"] = render_highlights, ["set-items"] = set_items, ["has-items?"] = has_items_3f, ["is-on-steering-line?"] = is_on_steering_line_3f, clear = clear, ["get-state"] = get_state, ["get-end-line"] = get_end_line}
end
return {create = create}
