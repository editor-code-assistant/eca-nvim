-- [nfnl] fnl/fennel-extras/cli/table.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.cli.table"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.cli.table"]
end
local update
do
  local function update0(original, changes)
    local result = {}
    for key, value in pairs(original) do
      result[key] = value
    end
    for key, value in pairs(changes) do
      result[key] = value
    end
    return result
  end
  _2amodule_2a["update"] = update0
  update = _2amodule_2a.update
end
return nil
