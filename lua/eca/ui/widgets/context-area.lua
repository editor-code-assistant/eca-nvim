-- [nfnl] fnl/eca/ui/widgets/context-area.fnl
local nvim = vim.api
local function create(buf_id)
  local state = {items = {}, ["ns-id"] = nil, ["start-line"] = 0, ["end-line"] = 0}
  local function ensure_ns()
    if (nil == state["ns-id"]) then
      state["ns-id"] = nvim.nvim_create_namespace("eca-context-area")
    else
    end
    return state["ns-id"]
  end
  local function build_line()
    if (0 == #state.items) then
      return {line = nil, highlights = {}}
    else
      local result
      do
        local acc = {parts = {}, highlights = {}, col = 0}
        for _, item in ipairs(state.items) do
          local sep_col
          if (acc.col > 0) then
            table.insert(acc.parts, " ")
            sep_col = (acc.col + 1)
          else
            sep_col = acc.col
          end
          table.insert(acc.parts, item.text)
          table.insert(acc.highlights, {["hl-group"] = (item["hl-group"] or "Normal"), ["col-start"] = sep_col, ["col-end"] = (sep_col + #item.text)})
          acc = {parts = acc.parts, highlights = acc.highlights, col = (sep_col + #item.text)}
        end
        result = acc
      end
      return {line = table.concat(result.parts, ""), highlights = result.highlights}
    end
  end
  local function has_items_3f()
    return (#state.items > 0)
  end
  local function render(start_line)
    state["start-line"] = start_line
    local ns = ensure_ns()
    nvim.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
    if not has_items_3f() then
      state["end-line"] = start_line
      return 0
    else
      local _let_4_ = build_line()
      local line = _let_4_.line
      local highlights = _let_4_.highlights
      nvim.nvim_buf_set_lines(buf_id, start_line, start_line, false, {line})
      for _, hl in ipairs(highlights) do
        nvim.nvim_buf_set_extmark(buf_id, ns, start_line, hl["col-start"], {end_col = hl["col-end"], hl_group = hl["hl-group"]})
      end
      state["end-line"] = (start_line + 1)
      return 1
    end
  end
  local function add(item)
    local exists
    do
      local found = false
      for _, existing in ipairs(state.items) do
        found = (found or (existing.text == item.text))
      end
      exists = found
    end
    if not exists then
      return table.insert(state.items, item)
    else
      return nil
    end
  end
  local function remove(text)
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, item in ipairs(state.items) do
        local val_28_
        if (item.text ~= text) then
          val_28_ = item
        else
          val_28_ = nil
        end
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      state.items = tbl_26_
    end
    return nil
  end
  local function render_highlights(line_num)
    if has_items_3f() then
      local ns = ensure_ns()
      local _let_9_ = build_line()
      local highlights = _let_9_.highlights
      nvim.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
      for _, hl in ipairs(highlights) do
        nvim.nvim_buf_set_extmark(buf_id, ns, line_num, hl["col-start"], {end_col = hl["col-end"], hl_group = hl["hl-group"]})
      end
      return nil
    else
      return nil
    end
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
  return {render = render, ["render-highlights"] = render_highlights, add = add, remove = remove, clear = clear, ["has-items?"] = has_items_3f, ["get-state"] = get_state, ["get-end-line"] = get_end_line}
end
return {create = create}
