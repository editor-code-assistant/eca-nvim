-- [nfnl] fnl/eca/ui/widgets/tab-bar.fnl
local function create(canvas, initial_state)
  local state = vim.tbl_extend("force", {tabs = {}, ["active-id"] = nil}, (initial_state or {}))
  local function build_tabline()
    local parts = {}
    for _, tab in ipairs(state.tabs) do
      local is_active = (tab.id == state["active-id"])
      local hl_group
      if tab["approval?"] then
        hl_group = "EcaTabLoading"
      elseif tab["loading?"] then
        hl_group = "EcaTabLoading"
      elseif is_active then
        hl_group = "EcaTabActive"
      else
        hl_group = "EcaTabInactive"
      end
      local prefix
      if tab["approval?"] then
        prefix = "\240\159\154\167 "
      elseif tab["loading?"] then
        prefix = "\226\143\179 "
      else
        prefix = ""
      end
      local title = (tab.title or tostring(tab.id))
      table.insert(parts, ("%#" .. hl_group .. "# " .. prefix .. title .. " "))
    end
    table.insert(parts, "%#EcaButtonAccept# + ")
    table.insert(parts, "%#EcaButtonReject# \195\151 ")
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
    local new_tabs = {}
    for _, tab in ipairs(state.tabs) do
      if (tab.id ~= id) then
        table.insert(new_tabs, tab)
      else
      end
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
  local function update_tab(id, new_state)
    for _, tab in ipairs(state.tabs) do
      if (tab.id == id) then
        for k, v in pairs(new_state) do
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
