local MiniTest = require("mini.test")
local T = MiniTest.new_set()

-- Test that the plugin loads without errors
T["loads without error"] = function()
  MiniTest.expect.no_error(function()
    require("eca")
  end)
end

-- Test basic config functionality
T["config"] = MiniTest.new_set()

T["config"]["has default values"] = function()
  local config = require("eca.config")
  MiniTest.expect.equality(type(config), "table")
end

T["config"]["has usage window defaults"] = function()
  local config = require("eca.config")
  MiniTest.expect.equality(
    config.options.windows.usage.format,
    "{session_tokens_short} / {limit_tokens_short} (${session_cost})"
  )
end

-- Test utilities
T["utils"] = MiniTest.new_set()

T["utils"]["module exists"] = function()
  MiniTest.expect.no_error(function()
    require("eca.utils")
  end)
end

return T
