-- [nfnl] fnl/eca/ui/widgets/footer-bar.fnl
local _local_1_ = require("eca.nfnl.core")
local assoc = _local_1_.assoc
local constantly = _local_1_.constantly
local get = _local_1_.get
local vals = _local_1_.vals
local concat = _local_1_.concat
local bar_items = require("eca.ui.components.bar-items")
local lualine = require("eca.ui.components.lualine")
--[[ (if (lualine.enabled?) (lualine.setup [{:value "~/dev/eca-nvim"} {:value "⏱ 0s"} {:value "0/200K ($0.00)"}]) (vim.notify "no lualine")) ]]
local function create(buf_id, win_id, initial_items)
  local items = (initial_items or {})
  local active = false
  local function apply()
    local ok, lualine0 = pcall(require, "lualine")
    if ok then
      local my_extension = {sections = {lualine_a = {"mode"}}}
      return constantly(nil)
    else
      local str = bar_items.render({items = items})
      return vim.api.nvim_set_option_value("statusline", str, {})
    end
  end
  local function _3_()
    if active then
      return vim.defer_fn(apply, 10)
    else
      return nil
    end
  end
  vim.api.nvim_create_autocmd({"WinEnter", "ColorScheme"}, {callback = _3_})
  local function render()
    active = true
    apply()
    return 0
  end
  local function update(new_items)
    items = new_items
    if active then
      return apply()
    else
      return nil
    end
  end
  local function get_state()
    return items
  end
  return {render = render, update = update, ["get-state"] = get_state}
end
return {create = create}
