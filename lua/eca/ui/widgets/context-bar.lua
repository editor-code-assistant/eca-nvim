-- [nfnl] fnl/eca/ui/widgets/context-bar.fnl
local context_item_component = require("eca.ui.components.context-item")
local function create(canvas)
  local state = {contexts = {}, ["ns-id"] = nil}
  local function ensure_ns()
    if (nil == state["ns-id"]) then
      state["ns-id"] = canvas["create-namespace"](canvas, "eca-context-bar")
    else
    end
    return state["ns-id"]
  end
  local function build_line()
    if (0 == #state.contexts) then
      return {line = "", parts = {}}
    else
      local parts = {}
      local highlights = {}
      local col = 0
      for i, ctx in ipairs(state.contexts) do
        if (i > 1) then
          table.insert(parts, " ")
          col = (col + 1)
        else
        end
        local rendered = context_item_component.render(ctx)
        table.insert(parts, rendered.text)
        table.insert(highlights, {["hl-group"] = rendered["hl-group"], ["col-start"] = col, ["col-end"] = (col + #rendered.text)})
        col = (col + #rendered.text)
      end
      return {line = table.concat(parts, ""), highlights = highlights}
    end
  end
  local function render(line_num)
    local ns = ensure_ns()
    local _let_4_ = build_line()
    local line = _let_4_.line
    local highlights = _let_4_.highlights
    if (line and ("" ~= line)) then
      canvas["set-modifiable"](canvas, true)
      canvas["set-lines"](canvas, line_num, (line_num + 1), {line})
      for _, hl in ipairs((highlights or {})) do
        canvas["add-extmark"](canvas, ns, line_num, hl["col-start"], {end_col = hl["col-end"], hl_group = hl["hl-group"]})
      end
      return canvas["set-modifiable"](canvas, false)
    else
      return nil
    end
  end
  local function add(ctx)
    local exists = false
    for _, existing in ipairs(state.contexts) do
      if (existing.name == ctx.name) then
        exists = true
      else
      end
    end
    if not exists then
      return table.insert(state.contexts, ctx)
    else
      return nil
    end
  end
  local function remove(name)
    local new_contexts = {}
    for _, ctx in ipairs(state.contexts) do
      if (ctx.name ~= name) then
        table.insert(new_contexts, ctx)
      else
      end
    end
    state.contexts = new_contexts
    return nil
  end
  local function clear()
    state.contexts = {}
    return nil
  end
  local function get_state()
    return state
  end
  return {render = render, add = add, remove = remove, clear = clear, ["get-state"] = get_state}
end
return {create = create}
