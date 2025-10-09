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
  child.lua("_G.server.start({cmd = {'fake'}})")
  eq(child.lua_get("_G.server.process"), vim.NIL)
  child.lua("_G.server:start()")
  eq(child.lua_get("_G.server:is_running()"), true)
end

T["server"]["initialize"] = function()
  local test_cases = {
    {
      method = "initialize",
      want = {
        chatBehaviors = { "agent", "plan" },
        chatDefaultBehavior = "agent",
        chatDefaultModel = "anthropic/claude-sonnet-4-20250514",
        chatWelcomeMessage = "Welcome to ECA!\n\nType '/' for commands\n\n",
        models = {
          "anthropic/claude-3-5-haiku-20241022",
          "anthropic/claude-opus-4-1-20250805",
          "anthropic/claude-opus-4-20250514",
          "anthropic/claude-sonnet-4-20250514",
          "github-copilot/claude-sonnet-4",
          "github-copilot/gpt-4.1",
          "github-copilot/gpt-5",
          "github-copilot/gpt-5-mini",
          "openai/gpt-4.1",
          "openai/gpt-5",
          "openai/gpt-5-mini",
          "openai/gpt-5-nano",
          "openai/o3",
          "openai/o4-mini",
        },
      },
    },
    { method = "not a command", want = vim.NIL },
  }
  for i, test_case in ipairs(test_cases) do
    if i == 1 then
      test_case = test_cases[i + 1]
    end
    child.lua("_G.method = " .. vim.inspect(test_case.method))
    child.lua("_G.server:start({initialize = false})")
    child.lua_func(function()
      _G.server:send_request(_G.method, {}, function(err, result)
        _G.err = err
        _G.result = result
      end)
    end)
    sleep(1500)
    eq(child.lua_get("_G.result"), test_case.want)
  end
end

return T
