-- [nfnl] fnl/eca/ui/components/bar.fnl
local function render(_1_)
  local items = _1_.items
  local hl_key = _1_["hl-key"]
  local hl_value = _1_["hl-value"]
  local hk = (hl_key or "EcaHeaderKey")
  local hv = (hl_value or "EcaHeaderValue")
  local parts
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, item in ipairs((items or {})) do
      local val_28_
      if item.title then
        val_28_ = ("%#" .. hk .. "#" .. item.title .. "%#" .. hv .. "#:" .. item.value)
      else
        val_28_ = ("%#" .. hv .. "#" .. item.value)
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
return {render = render}
