-- [nfnl] fnl/eca/ui/canvas.fnl
local protocol_keys = {"set-lines", "get-lines", "add-extmark", "del-extmark", "get-extmarks", "create-namespace", "set-option", "get-option", "line-count", "get-cursor", "set-cursor", "buf-valid?", "win-valid?", "set-modifiable", "close-win", "set-hl", "buf-id", "win-id"}
local function validate(canvas)
  local missing
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, key in ipairs(protocol_keys) do
      local val_28_
      if (nil == canvas[key]) then
        val_28_ = key
      else
        val_28_ = nil
      end
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    missing = tbl_26_
  end
  if (0 == #missing) then
    return true
  else
    return false, missing
  end
end
local function describe()
  return protocol_keys
end
return {validate = validate, describe = describe, ["protocol-keys"] = protocol_keys}
