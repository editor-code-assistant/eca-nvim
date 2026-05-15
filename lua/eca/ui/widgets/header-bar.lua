-- [nfnl] fnl/eca/ui/widgets/header-bar.fnl
local nvim = vim.api
local bar = require("eca.ui.components.bar-items")
local function create(buf_id, win_id, initial_items)
  local items = (initial_items or {})
  local function render()
    nvim.nvim_set_option_value("winbar", bar.render({items = items}), {win = win_id})
    nvim.nvim_buf_set_lines(buf_id, 0, 1, false, {""})
    return 1
  end
  local function update(new_items)
    items = new_items
    return render()
  end
  local function get_state()
    return items
  end
  local function line_count()
    return 1
  end
  return {render = render, update = update, ["get-state"] = get_state, ["line-count"] = line_count}
end
return {create = create}
