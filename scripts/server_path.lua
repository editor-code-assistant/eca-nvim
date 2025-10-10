-- Setup if headless
if #vim.api.nvim_list_uis() == 0 then
  -- hijack to make server tests work on CI using --clean mode
  local ok = pcall(require, "eca")
  if not ok then
    vim.cmd([[let &rtp.=','.getcwd()]])
    vim.cmd('set rtp+=deps/nui.nvim')
    vim.cmd('set rtp+=deps/eca-nvim')

    local try_again, err = pcall(require, "eca")
    if not try_again then
      error("Could not load eca.nvim: " .. tostring(err))
      os.exit(1)
    end
  end

  vim.o.swapfile = false
  vim.o.backup = false
  vim.o.writebackup = false
end

local path_finder, path_finder_or_err = pcall(require, "eca.path_finder")

if not path_finder then
  io.stderr:write("Could not load eca.path_finder: " .. tostring(path_finder_or_err))
  os.exit(1)
end

local PathFinder = path_finder_or_err:new()
local path

local ok, err = pcall(function()
  path = PathFinder:find()
end)

if not ok then
  io.stderr:write(tostring(err))
  os.exit(1)
end

io.stdout:write(tostring(path))
os.exit(0)
