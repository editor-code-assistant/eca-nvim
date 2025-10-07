local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local function setup_test_environment()
  Utils = require("eca.utils")
  _G.cmd = function(custom_path)
    return {
      "nvim",
      "--headless",
      "--noplugin",
      "--clean",
      "--cmd",
      [[lua package.preload["eca.path_finder"] = function()
        local M = {}
        function M.new()
          return setmetatable({}, { __index = M })
        end
        function M:find(custom_path)
          if custom_path == "error" then
            error("custom-server-path-error")
          end
          return (custom_path ~= "" and custom_path) or "no-custom-server-path"
        end
        return M
      end]],
      "-u",
      "scripts/server_path.lua",
      "-c",
      string.format("lua ServerPath.run(%s)", Utils.lua_quote(custom_path or "")),
    }
  end
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua_func(setup_test_environment)
    end,
    post_case = function()
    end,
    post_once = child.stop,
  },
})

T["server_path"] = MiniTest.new_set()

T["server_path"]["run without custom path should print to stdout"] = function()
  child.lua("_G.result = vim.system(_G.cmd(), { text = true }):wait()")
  eq(child.lua_get("_G.result.code"), 0)
  eq(child.lua_get("_G.result.stdout"), "no-custom-server-path")
  eq(child.lua_get("_G.result.stderr"), "")
end

T["server_path"]["run with custom path should print to stdout"] = function()
  child.lua("_G.result = vim.system(_G.cmd('custom-server-path'), { text = true }):wait()")
  eq(child.lua_get("_G.result.code"), 0)
  eq(child.lua_get("_G.result.stdout"), "custom-server-path")
  eq(child.lua_get("_G.result.stderr"), "")
end

T["server_path"]["run with error should print to stderr"] = function()
  child.lua("_G.result = vim.system(_G.cmd('error'), { text = true }):wait()")
  eq(child.lua_get("_G.result.code"), 1)
  eq(child.lua_get("_G.result.stdout"), "")
  eq(string.find(child.lua_get("_G.result.stderr"), "custom-server-path-error", 1 , true) ~= nil, true)
end

return T
