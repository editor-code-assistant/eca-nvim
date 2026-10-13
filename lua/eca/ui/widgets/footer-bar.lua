-- [nfnl] fnl/eca/ui/widgets/footer-bar.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["eca.ui.widgets.footer-bar"] = {}
  _2amodule_2a = pkg_1_auto.loaded["eca.ui.widgets.footer-bar"]
end
local core = require("eca.nfnl.core")
local bar_items = require("eca.ui.components.bar-items")
local lualine = require("eca.ui.components.lualine")
local function set_native_statusline(items)
  return vim.api.nvim_set_option_value("statusline", bar_items.render({items = items}), {})
end
local function apply(items)
  if lualine.plugin() then
    return lualine.setup(items)
  else
    return set_native_statusline(items)
  end
end
local function render(state)
  core.assoc(state, "active", true)
  apply(core.get(state, "items"))
  return 0
end
local function update(state, new_items)
  core.assoc(state, "items", new_items)
  if core.get(state, "active") then
    return apply(core.get(state, "items"))
  else
    return nil
  end
end
local function get_state(state)
  return core.get(state, "items")
end
local create
do
  local function create0(buf_id, win_id, initial_items)
    local state = {items = (initial_items or {}), active = false}
    local function _3_()
      if core.get(state, "active") then
        local function _4_()
          return apply(core.get(state, "items"))
        end
        return vim.defer_fn(_4_, 10)
      else
        return nil
      end
    end
    vim.api.nvim_create_autocmd({"WinEnter", "ColorScheme"}, {callback = _3_})
    local function _6_()
      return render(state)
    end
    local function _7_(new_items)
      return update(state, new_items)
    end
    local function _8_()
      return get_state(state)
    end
    return {render = _6_, update = _7_, ["get-state"] = _8_}
  end
  _2amodule_2a["create"] = create0
  create = _2amodule_2a.create
end
return nil
