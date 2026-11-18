local script_dir = vim.fn.fnamemodify(arg[0], ':p:h')
local root = vim.fn.fnamemodify(script_dir, ':h')
vim.opt.rtp:prepend(root)
package.path = root .. '/lua/?.lua;' .. root .. '/lua/?/init.lua;' .. package.path

local args = {}
for i = 1, #arg do
  args[i] = arg[i]
end

local code = require('fennel-extras.cli').run(args, {cwd = vim.loop.cwd()})
os.exit(code)
