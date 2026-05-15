-- [nfnl] fnl/eca/ui/widgets/prompt-area.fnl
local nvim = vim.api
local prompt_prefix_component = require("eca.ui.components.prompt-prefix")
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
  local state = {["prompt-text"] = "", history = {}, ["history-idx"] = 0, ["prompt-start-line"] = 0, ["status-anchor-line"] = 0, ["ns-id"] = nil, ["status-text"] = nil, ["status-timer"] = nil, ["status-dots"] = 0, ["status-extmark-id"] = nil, ["stop-extmark-id"] = nil, ["steering-text"] = nil, ["loading?"] = false}
  local idle_prefix = prompt_prefix_component.render({["loading?"] = false})
  local loading_prefix = prompt_prefix_component.render({["loading?"] = true})
  local function ensure_ns()
    if (nil == state["ns-id"]) then
      state["ns-id"] = nvim.nvim_create_namespace("eca-prompt-area")
    else
    end
    return state["ns-id"]
  end
  local function update_status_virt()
    local ns = ensure_ns()
    if state["status-extmark-id"] then
      pcall(nvim.nvim_buf_del_extmark, buf_id, ns, state["status-extmark-id"])
      state["status-extmark-id"] = nil
    else
    end
    if state["status-text"] then
      local dots = string.rep(".", ((state["status-dots"] % 3) + 1))
      local status_str = (state["status-text"] .. dots)
      local total = nvim.nvim_buf_line_count(buf_id)
      local anchor = math.min(state["status-anchor-line"], (total - 1))
      state["status-extmark-id"] = nvim.nvim_buf_set_extmark(buf_id, ns, anchor, 0, {virt_lines = {{{status_str, "EcaSpinner"}}}})
      return nil
    else
      return nil
    end
  end
  local function update_stop_virt()
    local ns = ensure_ns()
    if state["stop-extmark-id"] then
      pcall(nvim.nvim_buf_del_extmark, buf_id, ns, state["stop-extmark-id"])
      state["stop-extmark-id"] = nil
    else
    end
    if state["loading?"] then
      local total = nvim.nvim_buf_line_count(buf_id)
      local anchor = math.min(state["prompt-start-line"], (total - 1))
      state["stop-extmark-id"] = nvim.nvim_buf_set_extmark(buf_id, ns, anchor, 0, {virt_lines_above = true, virt_lines = {{{loading_prefix.text, loading_prefix["hl-group"]}, {"stop", "EcaStopLabel"}}}})
      return nil
    else
      return nil
    end
  end
  local function update_virt_lines()
    update_status_virt()
    return update_stop_virt()
  end
  local function read_live_prompt_text()
    local total = nvim.nvim_buf_line_count(buf_id)
    local start = state["prompt-start-line"]
    if ((total > 0) and (start <= (total - 1))) then
      local lines = nvim.nvim_buf_get_lines(buf_id, start, total, false)
      if (#lines > 0) then
        do
          local first_line = lines[1]
          if vim.startswith(first_line, idle_prefix.text) then
            lines[1] = string.sub(first_line, (#idle_prefix.text + 1))
          else
          end
        end
        return table.concat(lines, "\n")
      else
        return nil
      end
    else
      return nil
    end
  end
  local function save_live_text()
    do
      local total = nvim.nvim_buf_line_count(buf_id)
      local start = state["prompt-start-line"]
      if ((start > 0) and (start <= (total - 1))) then
        local first_line = (nvim.nvim_buf_get_lines(buf_id, start, (start + 1), false)[1] or "")
        if vim.startswith(first_line, idle_prefix.text) then
          local live = (read_live_prompt_text() or "")
          state["prompt-text"] = live
        else
        end
      else
      end
    end
    return state["prompt-text"]
  end
  local function render(start_line, _3fskip_read)
    if not _3fskip_read then
      local live_text = (read_live_prompt_text() or state["prompt-text"])
      state["prompt-text"] = live_text
    else
    end
    state["prompt-start-line"] = start_line
    local ns = ensure_ns()
    local _ = nvim.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
    local lines = {}
    if state["steering-text"] then
      local truncated
      if (#state["steering-text"] > 50) then
        truncated = (string.sub(state["steering-text"], 1, 50) .. "...")
      else
        truncated = state["steering-text"]
      end
      table.insert(lines, ("Steering: " .. truncated .. " [-]"))
    else
    end
    do
      local text_lines = vim.split(state["prompt-text"], "\n", {plain = true})
      table.insert(lines, (idle_prefix.text .. (text_lines[1] or "")))
      for i = 2, #text_lines do
        table.insert(lines, text_lines[i])
      end
    end
    nvim.nvim_buf_set_lines(buf_id, start_line, -1, false, lines)
    do
      local prompt_line_idx = ((start_line + #lines) - 1)
      state["prompt-start-line"] = prompt_line_idx
      if state["steering-text"] then
        local steering_line_idx = (prompt_line_idx - 1)
        local line_text = lines[((steering_line_idx - start_line) + 1)]
        local cancel_start = (#line_text - 3)
        nvim.nvim_buf_set_extmark(buf_id, ns, steering_line_idx, 0, {end_col = math.min(10, #line_text), hl_group = "EcaSteeringLabel"})
        nvim.nvim_buf_set_extmark(buf_id, ns, steering_line_idx, cancel_start, {end_col = #line_text, hl_group = "EcaStopLabel"})
      else
      end
      local buf_line = (nvim.nvim_buf_get_lines(buf_id, prompt_line_idx, (prompt_line_idx + 1), false)[1] or "")
      if (#buf_line >= #idle_prefix.text) then
        nvim.nvim_buf_set_extmark(buf_id, ns, prompt_line_idx, 0, {end_col = #idle_prefix.text, hl_group = idle_prefix["hl-group"]})
      else
      end
    end
    update_virt_lines()
    return #lines
  end
  local function render_highlights(prompt_line)
    state["prompt-start-line"] = prompt_line
    local ns = ensure_ns()
    nvim.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
    do
      local buf_line = (nvim.nvim_buf_get_lines(buf_id, prompt_line, (prompt_line + 1), false)[1] or "")
      if (#buf_line >= #idle_prefix.text) then
        nvim.nvim_buf_set_extmark(buf_id, ns, prompt_line, 0, {end_col = #idle_prefix.text, hl_group = idle_prefix["hl-group"]})
      else
      end
    end
    return update_virt_lines()
  end
  local function animate_dots()
    state["status-dots"] = (state["status-dots"] + 1)
    if (state["status-text"] and nvim.nvim_buf_is_valid(buf_id)) then
      return update_virt_lines()
    else
      return nil
    end
  end
  local function set_status(text)
    if text then
      state["status-text"] = text
      state["status-dots"] = 0
      if not state["status-timer"] then
        local function tick()
          if state["status-text"] then
            animate_dots()
            state["status-timer"] = vim.defer_fn(tick, 400)
            return nil
          else
            return nil
          end
        end
        state["status-timer"] = vim.defer_fn(tick, 400)
        return nil
      else
        return nil
      end
    else
      state["status-text"] = nil
      state["status-timer"] = nil
      return update_virt_lines()
    end
  end
  local function set_loading(bool)
    state["loading?"] = bool
    return update_virt_lines()
  end
  local function set_status_anchor_line(line)
    state["status-anchor-line"] = line
    return nil
  end
  local function set_steering(text)
    state["steering-text"] = text
    return nil
  end
  local function get_text()
    local total = nvim.nvim_buf_line_count(buf_id)
    local start = state["prompt-start-line"]
    local lines = nvim.nvim_buf_get_lines(buf_id, start, total, false)
    if (#lines > 0) then
      local first_line = lines[1]
      if vim.startswith(first_line, idle_prefix.text) then
        lines[1] = string.sub(first_line, (#idle_prefix.text + 1))
      else
      end
    else
    end
    return table.concat(lines, "\n")
  end
  local function set_text(text)
    state["prompt-text"] = (text or "")
    if not state["loading?"] then
      local start = state["prompt-start-line"]
      local total = nvim.nvim_buf_line_count(buf_id)
      local text_lines = vim.split(state["prompt-text"], "\n", {plain = true})
      local buf_lines = {}
      table.insert(buf_lines, (idle_prefix.text .. (text_lines[1] or "")))
      for i = 2, #text_lines do
        table.insert(buf_lines, text_lines[i])
      end
      return nvim.nvim_buf_set_lines(buf_id, start, total, false, buf_lines)
    else
      return nil
    end
  end
  local function set_text_internal(text)
    state["prompt-text"] = (text or "")
    return nil
  end
  local function clear()
    return set_text("")
  end
  local function add_to_history(text)
    if (text and ("" ~= text)) then
      table.insert(state.history, text)
      state["history-idx"] = (#state.history + 1)
      return nil
    else
      return nil
    end
  end
  local function history_prev()
    if (state["history-idx"] > 1) then
      state["history-idx"] = (state["history-idx"] - 1)
      return set_text(state.history[state["history-idx"]])
    else
      return nil
    end
  end
  local function history_next()
    if (state["history-idx"] < #state.history) then
      state["history-idx"] = (state["history-idx"] + 1)
      return set_text(state.history[state["history-idx"]])
    else
      state["history-idx"] = (#state.history + 1)
      return set_text("")
    end
  end
  local function _32_()
    local event = vim.v.event
    local lines = event.regcontents
    local first = (lines[1] or "")
    if vim.startswith(first, idle_prefix.text) then
      local stripped = string.sub(first, (#idle_prefix.text + 1))
      local reg
      if (event.regname and (event.regname ~= "")) then
        reg = event.regname
      else
        reg = "\""
      end
      lines[1] = stripped
      local function _34_()
        vim.fn.setreg(reg, lines, event.regtype)
        vim.fn.setreg("+", lines, event.regtype)
        return vim.fn.setreg("*", lines, event.regtype)
      end
      return vim.schedule(_34_)
    else
      return nil
    end
  end
  nvim.nvim_create_autocmd("TextYankPost", {buffer = buf_id, callback = _32_})
  local function _36_()
    local cursor = nvim.nvim_win_get_cursor(0)
    local row = cursor[1]
    local col = cursor[2]
    local total = nvim.nvim_buf_line_count(buf_id)
    local prompt_row = (state["prompt-start-line"] + 1)
    if ((row == prompt_row) and (col < #idle_prefix.text)) then
      return nvim.nvim_win_set_cursor(0, {row, #idle_prefix.text})
    else
      return nil
    end
  end
  nvim.nvim_create_autocmd("CursorMovedI", {buffer = buf_id, callback = _36_})
  local function get_state()
    return state
  end
  return {render = render, ["render-highlights"] = render_highlights, ["get-text"] = get_text, ["save-live-text"] = save_live_text, ["set-text"] = set_text, ["set-text-internal"] = set_text_internal, clear = clear, ["set-status"] = set_status, ["set-loading"] = set_loading, ["set-steering"] = set_steering, ["set-status-anchor-line"] = set_status_anchor_line, ["add-to-history"] = add_to_history, ["history-prev"] = history_prev, ["history-next"] = history_next, ["get-state"] = get_state}
end
return {create = create}
