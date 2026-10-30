-- [nfnl] fnl/eca/ui/widgets/tab-bar.fnl
local function create(canvas, initial_state)
  local state = vim.tbl_extend("force", {tabs = {}, ["active-id"] = nil}, (initial_state or {}))
  local function build_tabline()
    local parts = {}
    for _, tab in ipairs(state.tabs) do
      local is_active = (tab.id == state["active-id"])
      local hl
      local or_1_ = tab["hl-group"]
      if not or_1_ then
        if is_active then
          or_1_ = "EcaTabActive"
        else
          or_1_ = "EcaTabInactive"
        end
      end
      hl = or_1_
      table.insert(parts, ("%#" .. hl .. "# " .. (tab.label or tostring(tab.id)) .. " "))
    end
    return table.concat(parts, "%#Normal#\226\148\130")
  end
  local function render()
    local tabline = build_tabline()
    canvas["set-option"](canvas, "global", "tabline", tabline)
    return canvas["set-option"](canvas, "global", "showtabline", 2)
  end
  local function add_tab(tab)
    table.insert(state.tabs, tab)
    if (nil == state["active-id"]) then
      state["active-id"] = tab.id
      return nil
    else
      return nil
    end
  end
  local function remove_tab(id)
    local new_tabs
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, tab in ipairs(state.tabs) do
        local val_28_
        if (tab.id ~= id) then
          val_28_ = tab
        else
          val_28_ = nil
        end
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      new_tabs = tbl_26_
    end
    state.tabs = new_tabs
    if (state["active-id"] == id) then
      if (#new_tabs > 0) then
        state["active-id"] = new_tabs[1].id
      else
        state["active-id"] = nil
      end
      return nil
    else
      return nil
    end
  end
  local function select_tab(id)
    state["active-id"] = id
    return nil
  end
  local function update_tab(id, new_data)
    for _, tab in ipairs(state.tabs) do
      if (tab.id == id) then
        for k, v in pairs(new_data) do
          tab[k] = v
        end
      else
      end
    end
    return nil
  end
  local function get_state()
    return state
  end
  return {render = render, ["add-tab"] = add_tab, ["remove-tab"] = remove_tab, ["select-tab"] = select_tab, ["update-tab"] = update_tab, ["get-state"] = get_state}
end
return {create = create}
