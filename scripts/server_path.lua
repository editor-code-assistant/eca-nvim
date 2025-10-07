local ServerPath = {}

-- Setup if headless
if #vim.api.nvim_list_uis() == 0 then
  _G.ServerPath = ServerPath
  vim.cmd([[let &rtp.=','.getcwd()]])
  vim.cmd('set rtp+=deps/nui.nvim')
  vim.cmd('set rtp+=deps/eca-nvim')
  vim.o.swapfile = false
  vim.o.backup = false
  vim.o.writebackup = false
  require("eca").setup({})
end

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
