-- [nfnl] fnl/eca/ui/widgets/prompt-area.fnl
local separator_component = require("eca.ui.components.separator")
local prompt_prefix_component = require("eca.ui.components.prompt-prefix")
local context_bar_widget = require("eca.ui.widgets.context-bar")
local function create(canvas)
  local state = {["prompt-text"] = "", history = {}, ["history-idx"] = 0, ["prompt-start-line"] = 0, ["ns-id"] = nil, ["loading?"] = false}
  local ctx_bar = context_bar_widget.create(canvas)
  local function ensure_ns()
    if (nil == state["ns-id"]) then
      state["ns-id"] = canvas["create-namespace"](canvas, "eca-prompt-area")
    else
    end
    return state["ns-id"]
  end
  local function render(start_line)
    state["prompt-start-line"] = start_line
    local ns = ensure_ns()
    local sep = separator_component.render({width = 50})
    local prefix = prompt_prefix_component.render({["loading?"] = state["loading?"]})
    local ctx_state = ctx_bar["get-state"]()
    local has_contexts_3f = (#ctx_state.contexts > 0)
    local lines = {sep.line}
    if has_contexts_3f then
      local parts = {}
      local col = 0
      for i, ctx in ipairs(ctx_state.contexts) do
        if (i > 1) then
          table.insert(parts, " ")
        else
        end
        local ci = require("eca.ui.components.context-item")
        local rendered = ci.render(ctx)
        table.insert(parts, rendered.text)
      end
      table.insert(lines, table.concat(parts, ""))
    else
    end
    table.insert(lines, (prefix.text .. state["prompt-text"]))
    canvas["set-modifiable"](canvas, true)
    canvas["set-lines"](canvas, start_line, -1, lines)
    canvas["add-extmark"](canvas, ns, start_line, 0, {end_col = #sep.line, hl_group = "EcaSeparator"})
    do
      local prompt_line_idx = ((start_line + #lines) - 1)
      canvas["add-extmark"](canvas, ns, prompt_line_idx, 0, {end_col = #prefix.text, hl_group = prefix["hl-group"]})
    end
    if has_contexts_3f then
      ctx_bar.render((start_line + 1))
    else
    end
    canvas["set-modifiable"](canvas, false)
    if canvas["win-valid?"](canvas) then
      local prompt_line = (start_line + #lines)
      local col_pos = (#prefix.text + #state["prompt-text"])
      canvas["set-cursor"](canvas, prompt_line, col_pos)
    else
    end
    return #lines
  end
  local function get_text()
    local total = canvas["line-count"](canvas)
    local last_line_idx = (total - 1)
    local lines = canvas["get-lines"](canvas, last_line_idx, total)
    if (lines and (#lines > 0)) then
      local last_line = lines[1]
      local prefix = prompt_prefix_component.render({["loading?"] = state["loading?"]})
      local prefix_len = #prefix.text
      if (#last_line >= prefix_len) then
        return string.sub(last_line, (prefix_len + 1))
      else
        return ""
      end
    else
      return nil
    end
  end
  local function set_text(text)
    state["prompt-text"] = (text or "")
    local prefix = prompt_prefix_component.render({["loading?"] = state["loading?"]})
    local total = canvas["line-count"](canvas)
    local last_line_idx = (total - 1)
    canvas["set-modifiable"](canvas, true)
    canvas["set-lines"](canvas, last_line_idx, total, {(prefix.text .. state["prompt-text"])})
    return canvas["set-modifiable"](canvas, false)
  end
  local function clear()
    return set_text("")
  end
  local function set_loading(bool)
    state["loading?"] = bool
    local prefix = prompt_prefix_component.render({["loading?"] = bool})
    local total = canvas["line-count"](canvas)
    local last_line_idx = (total - 1)
    canvas["set-modifiable"](canvas, true)
    canvas["set-lines"](canvas, last_line_idx, total, {(prefix.text .. state["prompt-text"])})
    return canvas["set-modifiable"](canvas, false)
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
