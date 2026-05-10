-- [nfnl] fnl/eca/ui/widgets/message-list.fnl
local message_component = require("eca.ui.components.message")
local separator_component = require("eca.ui.components.separator")
local function create(canvas)
  local state = {messages = {}, ["ns-id"] = nil, ["end-line"] = 0}
  local function ensure_ns()
    if (nil == state["ns-id"]) then
      state["ns-id"] = canvas["create-namespace"](canvas, "eca-messages")
    else
    end
    return state["ns-id"]
  end
  local function apply_highlights(lines_offset, highlights)
    local ns = ensure_ns()
    for _, hl in ipairs(highlights) do
      canvas["add-extmark"](canvas, ns, (lines_offset + hl["line-idx"]), hl["col-start"], {end_col = hl["col-end"], hl_group = hl["hl-group"]})
    end
    return nil
  end
  local function render_single_message(msg, start_line)
    local rendered = message_component.render(msg)
    local sep = separator_component.render({width = 50})
    canvas["set-modifiable"](canvas, true)
    canvas["set-lines"](canvas, start_line, start_line, rendered.lines)
    apply_highlights(start_line, rendered.highlights)
    local sep_line = (start_line + #rendered.lines)
    canvas["set-lines"](canvas, sep_line, sep_line, {sep.line})
    apply_highlights(sep_line, sep.highlights)
    canvas["set-modifiable"](canvas, false)
    return (#rendered.lines + 1)
  end
  local function render()
    local ns = ensure_ns()
    canvas["set-modifiable"](canvas, true)
    do
      local total_lines = canvas["line-count"](canvas)
      canvas["set-lines"](canvas, 0, state["end-line"], {})
    end
    state["end-line"] = 0
    if (0 == #state.messages) then
      local welcome = message_component["render-welcome"]()
      canvas["set-lines"](canvas, 0, 0, welcome.lines)
      apply_highlights(0, welcome.highlights)
      state["end-line"] = #welcome.lines
    else
      for _, msg in ipairs(state.messages) do
        local lines_written = render_single_message(msg, state["end-line"])
        state["end-line"] = (state["end-line"] + lines_written)
      end
    end
    return canvas["set-modifiable"](canvas, false)
  end
  local function append_message(msg)
    table.insert(state.messages, msg)
    if (1 == #state.messages) then
      render()
    else
      local lines_written = render_single_message(msg, state["end-line"])
      state["end-line"] = (state["end-line"] + lines_written)
    end
    if canvas["win-valid?"](canvas) then
      local total = canvas["line-count"](canvas)
      return canvas["set-cursor"](canvas, total, 0)
    else
      return nil
    end
  end
  local function update_message(id, new_content)
    local found = false
    for i, msg in ipairs(state.messages) do
      if (msg.id == id) then
        msg["content"] = new_content
        found = true
      else
      end
    end
    if found then
      return render()
    else
      return nil
    end
  end
  local function clear()
    state.messages = {}
    state["end-line"] = 0
    return render()
  end
  local function get_state()
    return state
  end
  local function get_end_line()
    return state["end-line"]
  end
  return {render = render, ["append-message"] = append_message, ["update-message"] = update_message, clear = clear, ["get-state"] = get_state, ["get-end-line"] = get_end_line}
end
return {create = create}
