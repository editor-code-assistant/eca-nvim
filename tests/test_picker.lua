local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[
        _G.captured_notifications = {}
        local Logger = require('eca.logger')
        _G._original_notify = Logger.notify
        Logger.notify = function(msg, level, opts)
          table.insert(_G.captured_notifications, {
            message = msg,
            level = level,
            opts = opts or {},
          })
        end
      ]])
    end,
    post_case = function()
      child.lua([[
        local Logger = require('eca.logger')
        if _G._original_notify then
          Logger.notify = _G._original_notify
        end
        _G.captured_notifications = nil
      ]])
    end,
    post_once = child.stop,
  },
})

T["picker wrapper"] = MiniTest.new_set()

T["picker wrapper"]["logs error when snacks is missing"] = function()
  child.lua([[
    package.loaded['snacks'] = nil
    local Picker = require('eca.ui.picker')
    _G.result = Picker.pick({ source = 'test-source' })
  ]])

  local result = child.lua_get("_G.result")
  eq(result, vim.NIL)

  local notifications = child.lua_get("_G.captured_notifications")
  eq(#notifications, 1)
  eq(notifications[1].message, "snacks.nvim is not available")
  eq(notifications[1].level, child.lua_get("vim.log.levels.ERROR"))
end

T["picker wrapper"]["delegates to snacks.picker when available"] = function()
  child.lua([[
    local calls = {}
    package.loaded['snacks'] = {
      picker = function(config)
        table.insert(calls, config)
        return 'OK'
      end,
    }
    _G.snacks_calls = calls

    local Picker = require('eca.ui.picker')
    _G.result = Picker.pick({ source = 'test-source', extra = true })
  ]])

  local result = child.lua_get("_G.result")
  eq(result, "OK")

  local calls = child.lua_get("_G.snacks_calls")
  eq(#calls, 1)
  eq(calls[1].source, "test-source")
  eq(calls[1].extra, true)
end

return T
