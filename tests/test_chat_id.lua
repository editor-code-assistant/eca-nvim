local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local function flush(ms)
  vim.uv.sleep(ms or 50)
  child.api.nvim_eval("1")
end

local function setup_env()
  -- Initialize everything
  _G.Server = require('eca.server').new()
  _G.State = require('eca.state').new()
  _G.Mediator = require('eca.mediator').new(_G.Server, _G.State)
  _G.Sidebar = require('eca.sidebar').new(1, _G.Mediator)
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[require('eca.commands').setup()]])
      child.lua_func(setup_env)
    end,
    post_case = function()
      child.lua("if _G.Server and _G.Server.process then _G.Server.process:kill() end")
    end,
    post_once = child.stop,
  },
})

T["chat id lifecycle"] = MiniTest.new_set()

T["chat id lifecycle"]["mediator id follows state id updates"] = function()
  -- Initially there is no chat id
  eq(child.lua_get("_G.State.id"), vim.NIL)
  eq(child.lua_get("_G.Mediator:id()"), vim.NIL)

  -- Simulate a content notification with a chatId
  child.lua([[require('eca.observer').notify({
    method = 'chat/contentReceived',
    params = { chatId = 'chat-123', content = { type = 'progress', state = 'responding', text = '...' } },
  })]])
  flush()

  eq(child.lua_get("_G.State.id"), "chat-123")
  eq(child.lua_get("_G.Mediator:id()"), "chat-123")
end

T["chat id lifecycle"]["send request uses current chat id when available"] = function()
  -- Ensure no chat id initially
  eq(child.lua_get("_G.State.id"), vim.NIL)

  -- Send a message before any chat id exists
  child.lua([[_G.Sidebar:_send_message('hello')]])

  -- Inspect the last message sent to the server
  local last_json = child.lua_get("_G.Server.messages[#_G.Server.messages].content")
  local parsed = child.lua_get("vim.json.decode(...)", { last_json })
  eq(parsed.method, "chat/prompt")
  -- When id is nil, chatId should be absent in params
  eq(parsed.params.chatId == nil, true)

  -- Now simulate receiving a new chat id
  child.lua([[require('eca.observer').notify({
    method = 'chat/contentReceived',
    params = { chatId = 'chat-new', content = { type = 'progress', state = 'responding', text = '...' } },
  })]])
  flush()
  eq(child.lua_get("_G.State.id"), "chat-new")

  -- Send another message; it should include the new chat id
  child.lua([[_G.Sidebar:_send_message('again')]])
  local last_json2 = child.lua_get("_G.Server.messages[#_G.Server.messages].content")
  local parsed2 = child.lua_get("vim.json.decode(...)", { last_json2 })
  eq(parsed2.method, "chat/prompt")
  eq(parsed2.params.chatId, "chat-new")
end

T["chat id lifecycle"]["reopening neovim uses a new chat id"] = function()
  -- First session: set a chat id via notification
  child.lua([[require('eca.observer').notify({
    method = 'chat/contentReceived',
    params = { chatId = 'chat-first', content = { type = 'progress', state = 'responding', text = '...' } },
  })]])
  flush()
  eq(child.lua_get("_G.State.id"), "chat-first")

  -- Restart Neovim to simulate reopening
  child.restart({ "-u", "scripts/minimal_init.lua" })
  child.lua([[require('eca.commands').setup()]])
  child.lua_func(setup_env)

  -- New session should not carry over the previous chat id
  eq(child.lua_get("_G.State.id"), vim.NIL)

  -- First message should not include a chatId
  child.lua([[_G.Sidebar:_send_message('hello after reopen')]])
  local last_json3 = child.lua_get("_G.Server.messages[#_G.Server.messages].content")
  local parsed = child.lua_get("vim.json.decode(...)", { last_json3 })
  eq(parsed.method, "chat/prompt")
  eq(parsed.params.chatId == nil, true)

  -- After receiving content, a new chat id should be used
  child.lua([[require('eca.observer').notify({
    method = 'chat/contentReceived',
    params = { chatId = 'chat-second', content = { type = 'progress', state = 'responding', text = '...' } },
  })]])
  flush()
  eq(child.lua_get("_G.State.id"), "chat-second")

  child.lua([[_G.Sidebar:_send_message('use new id')]])
  local last_json4 = child.lua_get("_G.Server.messages[#_G.Server.messages].content")
  local parsed2 = child.lua_get("vim.json.decode(...)", { last_json4 })
  eq(parsed2.params.chatId, "chat-second")
end

return T
