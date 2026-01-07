local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[require('eca.highlights').setup()]])
    end,
    post_once = child.stop,
  },
})

T["highlights"] = MiniTest.new_set()

T["highlights"]["defines ECA highlight groups used in sidebar"] = function()
  local ok_label = child.lua_get("pcall(vim.api.nvim_get_hl, 0, { name = 'EcaLabel' })")
  local ok_tool = child.lua_get("pcall(vim.api.nvim_get_hl, 0, { name = 'EcaToolCall' })")
  local ok_link = child.lua_get("pcall(vim.api.nvim_get_hl, 0, { name = 'EcaHyperlink' })")

  eq(ok_label, true)
  eq(ok_tool, true)
  eq(ok_link, true)
end

return T
