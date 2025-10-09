local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[
        _G.captured = {}
        local Observer = require('eca.observer')
        -- Clear any prior subscriptions by reloading the module (defensive)
        package.loaded['eca.observer'] = nil
        Observer = require('eca.observer')

        -- Subscribe to capture all notifications
        Observer.subscribe('test-capture', function(message)
          table.insert(_G.captured, message)
        end)

        -- Instantiate state singleton
        _G.State = require('eca.state').new()

        -- Helper to filter captured messages by a predicate
        _G.filter_msgs = function(pred)
          local out = {}
          for _, m in ipairs(_G.captured) do
            if pred(m) then table.insert(out, m) end
          end
          return out
        end
      ]])
    end,
    post_case = function()
      child.lua([[require('eca.observer').unsubscribe('test-capture')]])
    end,
    post_once = child.stop,
  },
})

-- Ensure scheduled callbacks run (vim.schedule)
local function flush(ms)
  vim.uv.sleep(ms or 50)
  -- Force at least one main loop iteration
  child.api.nvim_eval("1")
end

T["singleton and defaults"] = MiniTest.new_set()

T["singleton and defaults"]["returns same instance"] = function()
  eq(child.lua_get("require('eca.state').new() == require('eca.state').new()"), true)
end

T["singleton and defaults"]["has expected default values"] = function()
  eq(child.lua_get("_G.State.status.state"), "idle")
  eq(child.lua_get("_G.State.status.text"), "Idle")

  eq(child.lua_get("vim.tbl_isempty(_G.State.config.behaviors.list)"), true)
  eq(child.lua_get("_G.State.config.behaviors.default"), vim.NIL)
  eq(child.lua_get("_G.State.config.behaviors.selected"), vim.NIL)

  eq(child.lua_get("vim.tbl_isempty(_G.State.config.models.list)"), true)
  eq(child.lua_get("_G.State.config.models.default"), vim.NIL)
  eq(child.lua_get("_G.State.config.models.selected"), vim.NIL)

  eq(child.lua_get("_G.State.config.welcome_message"), vim.NIL)

  eq(child.lua_get("_G.State.usage.tokens.limit"), 0)
  eq(child.lua_get("_G.State.usage.tokens.session"), 0)
  eq(child.lua_get("_G.State.usage.costs.last_message"), "0.00")
  eq(child.lua_get("_G.State.usage.costs.session"), "0.00")

  eq(child.lua_get("type(_G.State.tools)"), "table")
end

T["updates via observer notifications"] = MiniTest.new_set()

T["updates via observer notifications"]["updates status on progress content"] = function()
  child.lua([[require('eca.observer').notify({
    method = 'chat/contentReceived',
    params = { content = { type = 'progress', state = 'responding', text = 'Respondendo...' } },
  })]])
  flush()

  eq(child.lua_get("_G.State.status.state"), "responding")
  eq(child.lua_get("_G.State.status.text"), "Respondendo...")

  -- Verify a state/updated notification was emitted for status
  local updates = child.lua_get([[ _G.filter_msgs(function(m)
    return type(m) == 'table' and m.type == 'state/updated' and type(m.content) == 'table' and m.content.status ~= nil
  end) ]])
  eq(#updates >= 1, true)
end

T["updates via observer notifications"]["updates usage on usage content"] = function()
  child.lua([[require('eca.observer').notify({
    method = 'chat/contentReceived',
    params = { content = {
      type = 'usage',
      limit = { output = 1024 },
      sessionTokens = 256,
      lastMessageCost = '0.42',
      sessionCost = '3.14',
    } },
  })]])
  flush()

  eq(child.lua_get("_G.State.usage.tokens.limit"), 1024)
  eq(child.lua_get("_G.State.usage.tokens.session"), 256)
  eq(child.lua_get("_G.State.usage.costs.last_message"), "0.42")
  eq(child.lua_get("_G.State.usage.costs.session"), "3.14")

  local updates = child.lua_get([[ _G.filter_msgs(function(m)
    return type(m) == 'table' and m.type == 'state/updated' and type(m.content) == 'table' and m.content.usage ~= nil
  end) ]])
  eq(#updates >= 1, true)
end

T["updates via observer notifications"]["updates config on config/updated"] = function()
  child.lua([[require('eca.observer').notify({
    method = 'config/updated',
    params = { chat = {
      behaviors = { 'agent', 'plan' },
      defaultBehavior = 'agent',
      selectBehavior = 'plan',
      models = { 'openai/gpt-5-mini', 'anthropic/claude' },
      defaultModel = 'openai/gpt-5-mini',
      selectModel = 'anthropic/claude',
      welcomeMessage = 'Bem-vindo ao ECA!',
    } },
  })]])
  flush()

  eq(child.lua_get("_G.State.config.behaviors.list[1]"), "agent")
  eq(child.lua_get("_G.State.config.behaviors.list[2]"), "plan")
  eq(child.lua_get("_G.State.config.behaviors.default"), "agent")
  eq(child.lua_get("_G.State.config.behaviors.selected"), "plan")

  eq(child.lua_get("_G.State.config.models.list[1]"), "openai/gpt-5-mini")
  eq(child.lua_get("_G.State.config.models.list[2]"), "anthropic/claude")
  eq(child.lua_get("_G.State.config.models.default"), "openai/gpt-5-mini")
  eq(child.lua_get("_G.State.config.models.selected"), "anthropic/claude")

  eq(child.lua_get("_G.State.config.welcome_message"), "Bem-vindo ao ECA!")

  local updates = child.lua_get([[ _G.filter_msgs(function(m)
    return type(m) == 'table' and m.type == 'state/updated' and type(m.content) == 'table' and m.content.config ~= nil
  end) ]])
  eq(#updates >= 1, true)
end

T["updates via observer notifications"]["updates tools on tool/serverUpdated"] = function()
  -- Initial add
  child.lua([[require('eca.observer').notify({
    method = 'tool/serverUpdated',
    params = { name = 'server-1', type = 'mcp', status = 'connected' },
  })]])
  flush()

  eq(child.lua_get("_G.State.tools['server-1'].name"), "server-1")
  eq(child.lua_get("_G.State.tools['server-1'].type"), "mcp")
  eq(child.lua_get("_G.State.tools['server-1'].status"), "connected")

  -- Update only status, keep type
  child.lua([[require('eca.observer').notify({
    method = 'tool/serverUpdated',
    params = { name = 'server-1', status = 'disconnected' },
  })]])
  flush()

  eq(child.lua_get("_G.State.tools['server-1'].type"), "mcp")
  eq(child.lua_get("_G.State.tools['server-1'].status"), "disconnected")

  -- Invalid: missing name should be ignored (no errors, no new entries)
  local before = child.lua_get("vim.tbl_count(_G.State.tools)")
  child.lua([[require('eca.observer').notify({ method = 'tool/serverUpdated', params = { status = 'x' } })]])
  flush()
  local after = child.lua_get("vim.tbl_count(_G.State.tools)")
  eq(after, before)

  local updates = child.lua_get([[ _G.filter_msgs(function(m)
    return type(m) == 'table' and m.type == 'state/updated' and type(m.content) == 'table' and m.content.tools ~= nil
  end) ]])
  eq(#updates >= 1, true)
end

return T
