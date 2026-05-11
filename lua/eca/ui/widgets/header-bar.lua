-- [nfnl] fnl/eca/ui/widgets/header-bar.fnl
local nvim = vim.api
local function create(buf_id, win_id, initial_items)
  local items = (initial_items or {})
  local function build_winbar()
    local parts
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, item in ipairs(items) do
        local val_28_ = ("%#EcaHeaderKey#" .. item.title .. "%#EcaHeaderValue#:" .. item.value)
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      parts = tbl_26_
    end
    local count = #parts
    if (count == 0) then
      return ""
    elseif (count == 1) then
      return (" " .. parts[1])
    elseif (count == 2) then
      return (" " .. parts[1] .. "%=" .. parts[2] .. " ")
    else
      local _ = count
      local left = parts[1]
      local right = parts[count]
      local center_parts = {}
      local _0
      for i = 2, (count - 1) do
        table.insert(center_parts, parts[i])
      end
      _0 = nil
      local center = table.concat(center_parts, "  ")
      return (" " .. left .. "%=" .. center .. "%=" .. right .. " ")
    end
  end
  local function render()
    nvim.nvim_set_option_value("winbar", build_winbar(), {win = win_id})
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
