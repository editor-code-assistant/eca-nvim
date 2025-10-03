local ServerPath = {}

-- Export module
_G.ServerPath = ServerPath

ServerPath.run = function(custom_path)
  local path_finder = require("eca.path_finder"):new()
  local path

  local ok, err = pcall(function()
    path = path_finder:find(custom_path)
  end)

  if not ok then
    io.stderr:write(tostring(err))
    os.exit(1)
  end

  io.stdout:write(tostring(path))
  os.exit(0)
end

return ServerPath
