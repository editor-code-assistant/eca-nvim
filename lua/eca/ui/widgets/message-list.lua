-- [nfnl] fnl/eca/ui/widgets/message-list.fnl
local nvim = vim.api
local message_component = require("eca.ui.components.message")
local function create(buf_id, _3fopts)
  local wrap_write
  local _2_
  do
    local t_1_ = _3fopts
    if (nil ~= t_1_) then
      t_1_ = t_1_["wrap-write"]
    else
    end
    _2_ = t_1_
  end
  local or_4_ = _2_
  if not or_4_ then
    local function _5_(f)
      return f()
    end
    or_4_ = _5_
  end
  wrap_write = or_4_
  local on_line_inserted
  local _7_
  do
    local t_6_ = _3fopts
    if (nil ~= t_6_) then
      t_6_ = t_6_["on-line-inserted"]
    else
    end
    _7_ = t_6_
  end
  local or_9_ = _7_
  if not or_9_ then
    local function _10_()
      return nil
    end
    or_9_ = _10_
  end
  on_line_inserted = or_9_
  local state = {messages = {}, ["ns-id"] = nil, ["end-line"] = 0, ["start-line"] = 0, ["welcome-lines"] = nil, ["streaming-id"] = nil, ["streaming-queue"] = "", ["streaming-displayed"] = "", ["streaming-timer"] = nil, ["streaming-line"] = nil, ["streaming-col"] = nil, ["streaming-chars-per-tick"] = 2, ["streaming-tick-ms"] = 20}
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
  local function find_message(id)
    local found = nil
    for _, msg in ipairs(state.messages) do
      if (not found and (msg.id == id)) then
        found = msg
      else
      end
    end
    return found
  end
  local function stream_append_char(char)
    if (state["streaming-line"] and state["streaming-col"]) then
      local buf_lines = nvim.nvim_buf_line_count(buf_id)
      if (state["streaming-line"] < buf_lines) then
        if (char == "\n") then
          local function _13_()
            local next_line = (state["streaming-line"] + 1)
            nvim.nvim_buf_set_lines(buf_id, next_line, next_line, false, {""})
            state["end-line"] = (state["end-line"] + 1)
            return on_line_inserted()
          end
          wrap_write(_13_)
          state["streaming-line"] = (state["streaming-line"] + 1)
          state["streaming-col"] = 0
          return nil
        else
          pcall(nvim.nvim_buf_set_text, buf_id, state["streaming-line"], state["streaming-col"], state["streaming-line"], state["streaming-col"], {char})
          state["streaming-col"] = (state["streaming-col"] + #char)
          return nil
        end
      else
        return nil
      end
    else
      return nil
    end
  end
  local function stream_tick()
    if (#state["streaming-queue"] > 0) then
      local function _17_()
        local take = math.min(state["streaming-chars-per-tick"], #state["streaming-queue"])
        for i = 1, take do
          local char = string.sub(state["streaming-queue"], i, i)
          stream_append_char(char)
          state["streaming-displayed"] = (state["streaming-displayed"] .. char)
        end
        state["streaming-queue"] = string.sub(state["streaming-queue"], (take + 1))
        return nil
      end
      wrap_write(_17_)
    else
    end
    if (#state["streaming-queue"] > 0) then
      state["streaming-timer"] = vim.defer_fn(stream_tick, state["streaming-tick-ms"])
      return nil
    else
      state["streaming-timer"] = nil
      return nil
    end
  end
  local function start_streaming_timer()
    if (not state["streaming-timer"] and (#state["streaming-queue"] > 0)) then
      state["streaming-timer"] = vim.defer_fn(stream_tick, state["streaming-tick-ms"])
      return nil
    else
      return nil
    end
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
    nvim.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
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
        local render_msg
        if (msg.id == state["streaming-id"]) then
          render_msg = vim.tbl_extend("force", msg, {content = state["streaming-displayed"]})
        else
          render_msg = msg
        end
        local lines_written = render_single_message(render_msg, state["end-line"])
        state["end-line"] = (state["end-line"] + lines_written)
      end
      return nil
    end
  end
  local function append_message(msg)
    if state["streaming-id"] then
      __fnl_global__finish_2dstreaming(state["streaming-id"])
    else
    end
    table.insert(state.messages, msg)
    if msg["streaming?"] then
      state["streaming-id"] = msg.id
      state["streaming-displayed"] = ""
      state["streaming-queue"] = (msg.content or "")
      local function _26_()
        nvim.nvim_buf_set_lines(buf_id, state["end-line"], state["end-line"], false, {"", ""})
        state["streaming-line"] = state["end-line"]
        state["streaming-col"] = 0
        state["end-line"] = (state["end-line"] + 2)
        return nil
      end
      wrap_write(_26_)
      return start_streaming_timer()
    else
      if (1 == #state.messages) then
        return render()
      else
        local lines_written = render_single_message(msg, state["end-line"])
        state["end-line"] = (state["end-line"] + lines_written)
        return nil
      end
    end
  end
  local function update_message(id, new_content)
    local msg = find_message(id)
    if msg then
      msg["content"] = new_content
      if (id == state["streaming-id"]) then
        local already = (#state["streaming-displayed"] + #state["streaming-queue"])
        local new_chars
        if (#new_content > already) then
          new_chars = string.sub(new_content, (already + 1))
        else
          new_chars = nil
        end
        if (new_chars and (#new_chars > 0)) then
          state["streaming-queue"] = (state["streaming-queue"] .. new_chars)
          return start_streaming_timer()
        else
          return nil
        end
      else
        return render()
      end
    else
      return nil
    end
  end
  local function finish_streaming(id)
    if (id == state["streaming-id"]) then
      if state["streaming-timer"] then
        state["streaming-timer"] = nil
      else
      end
      if (#state["streaming-queue"] > 0) then
        for i = 1, #state["streaming-queue"] do
          local char = string.sub(state["streaming-queue"], i, i)
          stream_append_char(char)
        end
        state["streaming-displayed"] = (state["streaming-displayed"] .. state["streaming-queue"])
        state["streaming-queue"] = ""
      else
      end
      state["streaming-id"] = nil
      state["streaming-line"] = nil
      state["streaming-col"] = nil
      return nil
    else
      return nil
    end
  end
  local function abort_streaming(id)
    if (id == state["streaming-id"]) then
      if state["streaming-timer"] then
        state["streaming-timer"] = nil
      else
      end
      state["streaming-queue"] = ""
      state["streaming-id"] = nil
      state["streaming-line"] = nil
      state["streaming-col"] = nil
      return nil
    else
      return nil
    end
  end
  local function clear()
    state.messages = {}
    state["end-line"] = state["start-line"]
    if state["streaming-timer"] then
      state["streaming-timer"] = nil
    else
    end
    state["streaming-id"] = nil
    state["streaming-queue"] = ""
    state["streaming-displayed"] = ""
    state["streaming-line"] = nil
    state["streaming-col"] = nil
    return render()
  end
  local function get_state()
    return state
  end
  local function get_end_line()
    return state["end-line"]
  end
  return {render = render, ["append-message"] = append_message, ["update-message"] = update_message, ["finish-streaming"] = finish_streaming, ["abort-streaming"] = abort_streaming, clear = clear, ["get-state"] = get_state, ["get-end-line"] = get_end_line, ["set-start-line"] = set_start_line, ["set-welcome"] = set_welcome}
end
return {create = create}
