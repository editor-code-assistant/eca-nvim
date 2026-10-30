-- [nfnl] fnl/eca/ui/widgets/status-bar.fnl
local function create(canvas, initial_sections)
  local state
  local _2_
  do
    local t_1_ = initial_sections
    if (nil ~= t_1_) then
      t_1_ = t_1_.left
    else
    end
    _2_ = t_1_
  end
  local _5_
  do
    local t_4_ = initial_sections
    if (nil ~= t_4_) then
      t_4_ = t_4_.center
    else
    end
    _5_ = t_4_
  end
  local _8_
  do
    local t_7_ = initial_sections
    if (nil ~= t_7_) then
      t_7_ = t_7_.right
    else
    end
    _8_ = t_7_
  end
  state = {left = (_2_ or {}), center = (_5_ or {}), right = (_8_ or {})}
  local function build_section(items)
    local parts
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, item in ipairs(items) do
        local val_28_ = ("%#" .. (item["hl-group"] or "Normal") .. "# " .. item.text .. " ")
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      parts = tbl_26_
    end
    return table.concat(parts, "")
  end
  local function build_statusline()
    local left = build_section(state.left)
    local center = build_section(state.center)
    local right = build_section(state.right)
    return (left .. "%=" .. center .. "%=" .. right)
  end
  local function render()
    local statusline = build_statusline()
    return canvas["set-option"](canvas, "win", "statusline", statusline)
  end
  local function update(new_sections)
    if new_sections.left then
      state.left = new_sections.left
    else
    end
    if new_sections.center then
      state.center = new_sections.center
    else
    end
    if new_sections.right then
      state.right = new_sections.right
    else
    end
    return render()
  end
  local function get_state()
    return state
  end
  return {render = render, update = update, ["get-state"] = get_state}
end
return {create = create}
