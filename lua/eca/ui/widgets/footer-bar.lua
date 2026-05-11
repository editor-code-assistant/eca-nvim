-- [nfnl] fnl/eca/ui/widgets/footer-bar.fnl
local nvim = vim.api
local function create(buf_id, win_id, initial_items)
  local items = (initial_items or {})
  local saved_statusline = nil
  local function build_statusline_str()
    local parts
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, item in ipairs(items) do
        local val_28_
        if item.title then
          val_28_ = ("%#EcaHeaderKey#" .. item.title .. "%#EcaHeaderValue#:" .. item.value)
        else
          val_28_ = ("%#EcaHeaderValue#" .. item.value)
        end
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
  local function is_global_3f()
    return (3 == nvim.nvim_get_option_value("laststatus", {}))
  end
  local function apply_statusline()
    local str = build_statusline_str()
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
  local function restore_statusline()
    if (is_global_3f() and saved_statusline) then
      return nvim.nvim_set_option_value("statusline", saved_statusline, {})
    else
      return nil
    end
  end
  local function render()
    apply_statusline()
    return 0
  end
  saved_statusline = nvim.nvim_get_option_value("statusline", {})
  local function _7_()
    local function _8_()
      return apply_statusline()
    end
    return vim.defer_fn(_8_, 10)
  end
  nvim.nvim_create_autocmd("BufEnter", {buffer = buf_id, callback = _7_})
  local function _9_()
    return restore_statusline()
  end
  nvim.nvim_create_autocmd("BufLeave", {buffer = buf_id, callback = _9_})
  local function _10_()
    if nvim.nvim_buf_is_valid(buf_id) then
      return apply_statusline()
    else
      return nil
    end
  end
  nvim.nvim_create_autocmd("OptionSet", {pattern = "laststatus", callback = _10_})
  local function update(new_items)
    items = new_items
    return render()
  end
  local function get_state()
    return items
  end
  return {render = render, update = update, ["get-state"] = get_state}
end
return {create = create}
