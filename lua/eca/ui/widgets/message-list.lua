-- [nfnl] fnl/eca/ui/widgets/message-list.fnl
local nvim = vim.api
local message_component = require("eca.ui.components.message")
local function create(buf_id)
  local state = {messages = {}, ["ns-id"] = nil, ["end-line"] = 0, ["start-line"] = 0, ["welcome-lines"] = nil}
  local function ensure_ns()
    if (nil == state["ns-id"]) then
      state["ns-id"] = nvim.nvim_create_namespace("eca-messages")
    else
    end
    return state["ns-id"]
  end
  local function apply_highlights(lines_offset, highlights)
    local ns = ensure_ns()
    for _, hl in ipairs(highlights) do
      nvim.nvim_buf_set_extmark(buf_id, ns, (lines_offset + hl["line-idx"]), hl["col-start"], {end_col = hl["col-end"], hl_group = hl["hl-group"]})
    end
    return nil
  end
  local function render_single_message(msg, start_line)
    local rendered = message_component.render(msg)
    nvim.nvim_buf_set_lines(buf_id, start_line, start_line, false, rendered.lines)
    apply_highlights(start_line, rendered.highlights)
    return #rendered.lines
  end
  local function set_start_line(line)
    state["start-line"] = line
    if (state["end-line"] == 0) then
      state["end-line"] = line
      return nil
    else
      return nil
    end
  end
  local function set_welcome(data)
    state["welcome-lines"] = data
    return nil
  end
  local function render()
    local ns = ensure_ns()
    nvim.nvim_buf_set_lines(buf_id, state["start-line"], state["end-line"], false, {})
    state["end-line"] = state["start-line"]
    if (0 == #state.messages) then
      if state["welcome-lines"] then
        nvim.nvim_buf_set_lines(buf_id, state["start-line"], state["start-line"], false, state["welcome-lines"].lines)
        apply_highlights(state["start-line"], (state["welcome-lines"].highlights or {}))
        state["end-line"] = (state["start-line"] + #state["welcome-lines"].lines)
        return nil
      else
        return nil
      end
    else
      for _, msg in ipairs(state.messages) do
        local lines_written = render_single_message(msg, state["end-line"])
        state["end-line"] = (state["end-line"] + lines_written)
      end
      return nil
    end
  end
  local function append_message(msg)
    table.insert(state.messages, msg)
    if (1 == #state.messages) then
      return render()
    else
      local lines_written = render_single_message(msg, state["end-line"])
      state["end-line"] = (state["end-line"] + lines_written)
      return nil
    end
  end
  local function update_message(id, new_content)
    local found
    do
      local f = false
      for _, msg in ipairs(state.messages) do
        if (msg.id == id) then
          msg["content"] = new_content
          f = true
        else
          f = f
        end
      end
      found = f
    end
    if found then
      return render()
    else
      return nil
    end
  end
  local function clear()
    state.messages = {}
    state["end-line"] = state["start-line"]
    return render()
  end
  local function get_state()
    return state
  end
  local function get_end_line()
    return state["end-line"]
  end
  return {render = render, ["append-message"] = append_message, ["update-message"] = update_message, clear = clear, ["get-state"] = get_state, ["get-end-line"] = get_end_line, ["set-start-line"] = set_start_line, ["set-welcome"] = set_welcome}
end
return {create = create}
