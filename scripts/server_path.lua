local PathFinder = require("eca.path_finder")

local custom_path = _G.arg[1] or ""
local path_finder = PathFinder:new()
local path

local ok, err = pcall(function()
  path = path_finder:find(custom_path)
end)

if not ok then
  io.stderr:write(tostring(err))
  os.exit(1)
end

io.stdout:write(path)
