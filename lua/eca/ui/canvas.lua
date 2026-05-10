-- [nfnl] fnl/eca/ui/canvas.fnl
local protocol_keys = {"set-lines", "get-lines", "add-extmark", "del-extmark", "get-extmarks", "create-namespace", "set-option", "get-option", "line-count", "get-cursor", "set-cursor", "buf-valid?", "win-valid?", "set-modifiable", "close-win", "set-hl", "buf-id", "win-id"}
local function validate(canvas)
  local missing = {}
  for _, key in ipairs(protocol_keys) do
    if (nil == canvas[key]) then
      table.insert(missing, key)
    else
    end
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
