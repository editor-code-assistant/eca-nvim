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
      local result
      do
        local acc = {parts = {}, highlights = {}, col = 0}
        for _, ctx in ipairs(state.contexts) do
          local sep_col
          if (acc.col > 0) then
            table.insert(acc.parts, " ")
            sep_col = (acc.col + 1)
          else
            sep_col = acc.col
          end
          local rendered = context_item_component.render(ctx)
          table.insert(acc.parts, rendered.text)
          table.insert(acc.highlights, {["hl-group"] = rendered["hl-group"], ["col-start"] = sep_col, ["col-end"] = (sep_col + #rendered.text)})
          acc = {parts = acc.parts, highlights = acc.highlights, col = (sep_col + #rendered.text)}
        end
        result = acc
      end
      return {line = table.concat(result.parts, ""), highlights = result.highlights}
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
    local exists
    do
      local found = false
      for _, existing in ipairs(state.contexts) do
        found = (found or (existing.name == ctx.name))
      end
      exists = found
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
