-- [nfnl] fnl/eca/ui/widgets/footer-bar.fnl
local nvim = vim.api
local bar = require("eca.ui.components.bar-items")
local function create(buf_id, win_id, initial_items)
  local items = (initial_items or {})
  local active = false
  local function is_global_3f()
    return (3 == nvim.nvim_get_option_value("laststatus", {}))
  end
  local function apply()
    local str = bar.render({items = items})
    if is_global_3f() then
      return nvim.nvim_set_option_value("statusline", str, {})
    else
      if (win_id and nvim.nvim_win_is_valid(win_id)) then
        return nvim.nvim_set_option_value("statusline", str, {win = win_id})
      else
        return nil
      end
    end
  end
  local function render()
    active = true
    apply()
    return 0
  end
  local function _3_()
    if (active and nvim.nvim_buf_is_valid(buf_id)) then
      if (nvim.nvim_get_current_buf() == buf_id) then
        local function _4_()
          return apply()
        end
        return vim.defer_fn(_4_, 10)
      else
        return nil
      end
    else
      return nil
    end
  end
  nvim.nvim_create_autocmd({"WinEnter", "ColorScheme"}, {callback = _3_})
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
