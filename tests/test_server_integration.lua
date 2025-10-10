local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local function setup_test_environment()
  _G.log = {}
  _G.notifications = {}
  Logger = require("eca.logger")
  Logger.log = function(message, level)
    table.insert(_G.log, { message = message, level = level })
  end
  Logger.notify = function(message, level, opts)
    table.insert(_G.notifications, { message = message, level = level, opts = opts })
  end
  _G.server = require("eca.server").new()
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua_func(setup_test_environment)
    end,
    post_case = function()
      child.lua("if _G.server and _G.server.process then _G.server.process:kill() end")
    end,
    post_once = child.stop,
  },
})

-- See https://github.com/echasnovski/mini.nvim/issues/1863#issuecomment-2983629024
-- for why the sleep is necessary when testing something with a callback
local function sleep(ms)
  vim.uv.sleep(ms)
  -- Execute 'nvim_eval' (a deferred function) to
  -- force at least one main_loop iteration
  child.api.nvim_eval("1")
end

T["server"] = MiniTest.new_set()

T["server"]["start"] = function()
  child.lua("_G.server:start()")
  child.lua([[
    _G.server_started = vim.wait(10000, function()
      return _G.server and _G.server:is_running()
    end, 100)
  ]])
  eq(child.lua_get("_G.server_started"), true)
  sleep(1000)
  eq(child.lua_get("_G.server.initialized"), true)
end

T["server"]["start without initialize"] = function()
  child.lua("_G.server:start({ initialize = false })")
  child.lua([[
    _G.server_started = vim.wait(10000, function()
      return _G.server and _G.server:is_running()
    end, 100)
  ]])
  eq(child.lua_get("_G.server_started"), true)
  sleep(1000)
  eq(child.lua_get("_G.server.initialized"), false)
end

T["server"]["start with inexistent path"] = function()
  child.lua([[
    _G.config = require("eca.config")
    _G.config.setup({ server_path = "non-existing-path" })
    _G.server:start()
  ]])
  child.lua([[
    _G.server_started = vim.wait(1000, function()
      return _G.server and _G.server:is_running()
    end, 100)
  ]])

  eq(child.lua_get("_G.server_started"), false)
  sleep(1000)
  eq(child.lua_get("_G.server.initialized"), false)
  eq(string.find(child.lua_get("_G.notifications[1].message"), "non-existing-path", 1 , true) ~= nil, true)
end

return T
