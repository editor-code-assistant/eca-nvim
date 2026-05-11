-- [nfnl] fnl/eca/ui/widgets/prompt-area.fnl
local nvim = vim.api
local prompt_prefix_component = require("eca.ui.components.prompt-prefix")
local context_bar_widget = require("eca.ui.widgets.context-bar")
local function create(buf_id)
  local state = {["prompt-text"] = "", history = {}, ["history-idx"] = 0, ["prompt-start-line"] = 0, ["ns-id"] = nil, ["loading?"] = false}
  local ctx_bar = context_bar_widget.create(buf_id)
  local function ensure_ns()
    if (nil == state["ns-id"]) then
      state["ns-id"] = nvim.nvim_create_namespace("eca-prompt-area")
    else
    end
    return state["ns-id"]
  end
  local function render(start_line)
    state["prompt-start-line"] = start_line
    local ns = ensure_ns()
    local prefix = prompt_prefix_component.render({["loading?"] = state["loading?"]})
    local ctx_state = ctx_bar["get-state"]()
    local has_contexts_3f = (#ctx_state.items > 0)
    local lines = {}
    if has_contexts_3f then
      local parts
      do
        local tbl_26_ = {}
        local i_27_ = 0
        for _, item in ipairs(ctx_state.items) do
          local val_28_ = item.text
          if (nil ~= val_28_) then
            i_27_ = (i_27_ + 1)
            tbl_26_[i_27_] = val_28_
          else
          end
        end
        parts = tbl_26_
      end
      table.insert(lines, table.concat(parts, " "))
    else
    end
    table.insert(lines, (prefix.text .. state["prompt-text"]))
    nvim.nvim_buf_set_lines(buf_id, start_line, -1, false, lines)
    do
      local prompt_line_idx = ((start_line + #lines) - 1)
      nvim.nvim_buf_set_extmark(buf_id, ns, prompt_line_idx, 0, {end_col = #prefix.text, hl_group = prefix["hl-group"]})
    end
    if has_contexts_3f then
      ctx_bar.render(start_line)
    else
    end
    return #lines
  end
  local function get_text()
    local total = nvim.nvim_buf_line_count(buf_id)
    local prompt_lines = nvim.nvim_buf_get_lines(buf_id, state["prompt-start-line"], total, false)
    local prefix = prompt_prefix_component.render({["loading?"] = state["loading?"]})
    if (prompt_lines and (#prompt_lines > 0)) then
      local first_line = prompt_lines[1]
      local stripped
      if vim.startswith(first_line, prefix.text) then
        stripped = string.sub(first_line, (#prefix.text + 1))
      else
        stripped = first_line
      end
      local parts = {stripped}
      for i = 2, #prompt_lines do
        table.insert(parts, prompt_lines[i])
      end
      return table.concat(parts, "\n")
    else
      return nil
    end
  end
  local function set_text(text)
    state["prompt-text"] = (text or "")
    local prefix = prompt_prefix_component.render({["loading?"] = state["loading?"]})
    local total = nvim.nvim_buf_line_count(buf_id)
    local last_line_idx = (total - 1)
    return nvim.nvim_buf_set_lines(buf_id, last_line_idx, total, false, {(prefix.text .. state["prompt-text"])})
  end
  local function clear()
    return set_text("")
  end
  local function set_loading(bool)
    state["loading?"] = bool
    local prefix = prompt_prefix_component.render({["loading?"] = bool})
    local total = nvim.nvim_buf_line_count(buf_id)
    local last_line_idx = (total - 1)
    return nvim.nvim_buf_set_lines(buf_id, last_line_idx, total, false, {(prefix.text .. state["prompt-text"])})
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
  local function add_context(ctx)
    return ctx_bar.add(ctx)
  end
  local function remove_context(name)
    return ctx_bar.remove(name)
  end
  local function get_state()
    return state
  end
  return {render = render, ["get-text"] = get_text, ["set-text"] = set_text, clear = clear, ["set-loading"] = set_loading, ["add-to-history"] = add_to_history, ["history-prev"] = history_prev, ["history-next"] = history_next, ["add-context"] = add_context, ["remove-context"] = remove_context, ["get-state"] = get_state}
end
return {create = create}
