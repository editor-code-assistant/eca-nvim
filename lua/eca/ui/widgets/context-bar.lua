-- [nfnl] fnl/eca/ui/widgets/context-bar.fnl
local nvim = vim.api
local function create(buf_id)
  local state = {items = {}, ["ns-id"] = nil}
  local function ensure_ns()
    if (nil == state["ns-id"]) then
      state["ns-id"] = nvim.nvim_create_namespace("eca-context-bar")
    else
    end
    return state["ns-id"]
  end
  local function build_line()
    if (0 == #state.items) then
      return {line = "", highlights = {}}
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
  local function render(line_num)
    local ns = ensure_ns()
    local _let_4_ = build_line()
    local line = _let_4_.line
    local highlights = _let_4_.highlights
    if (line and ("" ~= line)) then
      nvim.nvim_buf_set_lines(buf_id, line_num, (line_num + 1), false, {line})
      for _, hl in ipairs((highlights or {})) do
        nvim.nvim_buf_set_extmark(buf_id, ns, line_num, hl["col-start"], {end_col = hl["col-end"], hl_group = hl["hl-group"]})
      end
      return nil
    else
      return nil
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
  local function clear()
    state.items = {}
    return nil
  end
  local function get_state()
    return state
  end
  return {render = render, add = add, remove = remove, clear = clear, ["get-state"] = get_state}
end
return {create = create}
