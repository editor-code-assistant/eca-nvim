local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local function flush(ms)
  vim.uv.sleep(ms or 50)
  child.api.nvim_eval("1")
end

local function setup_env()
  require('eca.commands').setup()

  -- Stub Picker.pick so commands can run without snacks.nvim
  local Picker = require('eca.ui.picker')
  _G.picker_calls = {}
  Picker.pick = function(config)
    table.insert(_G.picker_calls, config)
  end
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua_func(setup_env)
    end,
    post_case = function()
      child.lua("_G.picker_calls = nil")
    end,
    post_once = child.stop,
  },
})

T["EcaServerMessages"] = MiniTest.new_set()

T["EcaServerMessages"]["uses picker and filters invalid JSON messages"] = function()
  child.lua([[
    local eca = require('eca')
    eca.server = eca.server or {}
    eca.server.messages = {
      { id = 1, direction = 'send', content = vim.json.encode({ jsonrpc = '2.0', method = 'test/method', id = 1 }) },
      { id = 2, direction = 'recv', content = 'not-json' },
    }

    vim.cmd('EcaServerMessages')
  ]])

  flush()

  child.lua([[
    local calls = _G.picker_calls or {}
    local cfg = calls[1]
    _G.picker_info = {
      count = #calls,
      source = cfg and cfg.source or nil,
    }
  ]])

  local picker_info = child.lua_get("_G.picker_info")

  eq(picker_info.count, 1)
  eq(picker_info.source, "eca messages")

  -- Run finder and inspect produced items
  child.lua([[
    local cfg = _G.picker_calls[1]
    local items = cfg.finder({}, {})
    _G.result_messages = {
      count = #items,
      first = items[1],
    }
  ]])

  local result = child.lua_get("_G.result_messages")

  -- Only the valid JSON message should be included
  eq(result.count, 1)
  eq(type(result.first), "table")
  eq(result.first.idx, 1)
  eq(result.first.preview.ft, "lua")

  -- Preview text should contain the method name
  local has_method = child.lua_get("string.find(..., 'test/method', 1, true) ~= nil", { result.first.preview.text })
  eq(has_method, true)

  -- Confirm callback yanks preview text and closes picker
  child.lua([[
    local cfg = _G.picker_calls[1]
    local item = cfg.finder({}, {})[1]
    local picker = { closed = false }
    function picker:close() self.closed = true end

    cfg.confirm(picker, item, nil)

    _G.confirm_messages = {
      reg = vim.fn.getreg(''),
      closed = picker.closed,
    }
  ]])

  local confirm_ok = child.lua_get("_G.confirm_messages")

  eq(confirm_ok.closed, true)
  eq(type(confirm_ok.reg), "string")
  local has_method_in_reg = child.lua_get("string.find(..., 'test/method', 1, true) ~= nil", { confirm_ok.reg })
  eq(has_method_in_reg, true)
end

T["EcaServerTools"] = MiniTest.new_set()

T["EcaServerTools"]["lists tools from state in sorted order"] = function()
  child.lua([[
    local eca = require('eca')
    eca.state = eca.state or {}
    eca.state.tools = {
      zebra = { kind = 'z' },
      alpha = { kind = 'a' },
      middle = { kind = 'm' },
    }

    vim.cmd('EcaServerTools')
  ]])

  flush()

  child.lua([[
    local calls = _G.picker_calls or {}
    _G.picker_info = {
      count = #calls,
    }
  ]])

  local picker_info = child.lua_get("_G.picker_info")

  eq(picker_info.count, 1)

  child.lua([[
    local cfg = _G.picker_calls[1]
    local items = cfg.finder({}, {})
    _G.result_tools = {
      count = #items,
      names = { items[1].text, items[2].text, items[3].text },
      first = items[1],
    }
  ]])

  local result = child.lua_get("_G.result_tools")

  eq(result.count, 3)
  -- Names must be sorted alphabetically
  eq(result.names[1], "alpha")
  eq(result.names[2], "middle")
  eq(result.names[3], "zebra")

  -- Preview contains vim.inspect output of the tool
  local has_kind = child.lua_get("string.find(..., 'kind%p a', 1) ~= nil", { result.first.preview.text })
  eq(has_kind, true)

  -- Confirm yanks preview text and closes picker
  child.lua([[
    local cfg = _G.picker_calls[1]
    local items = cfg.finder({}, {})
    local picker = { closed = false }
    function picker:close() self.closed = true end

    cfg.confirm(picker, items[2], nil)

    _G.confirm_tools = {
      reg = vim.fn.getreg(''),
      closed = picker.closed,
    }
  ]])

  local confirm_ok = child.lua_get("_G.confirm_tools")

  eq(confirm_ok.closed, true)
  eq(type(confirm_ok.reg), "string")
  local has_middle = child.lua_get("string.find(..., 'middle', 1, true) ~= nil", { confirm_ok.reg })
  eq(has_middle, true)
end

return T
