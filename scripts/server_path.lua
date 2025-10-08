local ServerPath = {}

-- Setup if headless
if #vim.api.nvim_list_uis() == 0 then
  _G.ServerPath = ServerPath

  -- hijack to make server tests work on CI using --clean mode
  local eca_available = pcall(require, "eca")
  if not eca_available then
    vim.cmd([[let &rtp.=','.getcwd()]])
    vim.cmd('set rtp+=deps/nui.nvim')
    vim.cmd('set rtp+=deps/eca-nvim')
  end

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
