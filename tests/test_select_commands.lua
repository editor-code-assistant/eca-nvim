local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

-- Returns the registered command's name, or nil if not registered. Filters
-- server-side so the function-valued `callback` field (present on 0.12+)
-- does not cross the MiniTest msgpack boundary.
local function cmd_registered_name(name)
  return child.lua_get(string.format(
    "(vim.api.nvim_get_commands({})[%q] or {}).name",
    name
  ))
end

local function setup_test_environment()
  -- Setup commands
  require('eca.commands').setup()

  -- Initialize everything
  _G.Server = require('eca.server').new()
  _G.State = require('eca.state').new()
  _G.Mediator = require('eca.mediator').new(_G.Server, _G.State)
  _G.Sidebar = require('eca.sidebar').new(1, _G.Mediator)
  _G.Eca = require('eca')
  _G.Eca.sidebars[1] = _G.Sidebar
  _G.Eca.current = { sidebar = _G.Sidebar }

  -- Mock vim.ui.select for testing
  _G.selected_choice = nil
  _G.shown_items = nil
  _G.shown_prompt = nil
  _G.original_select = vim.ui.select

  _G.mock_select = function(choice)
    _G.selected_choice = choice
    vim.ui.select = function(items, opts, on_choice)
      _G.shown_items = items
      _G.shown_prompt = opts.prompt
      on_choice(choice)
    end
  end

  _G.restore_select = function()
    vim.ui.select = _G.original_select
  end
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua_func(setup_test_environment)
    end,
    post_case = function()
      child.lua([[_G.restore_select()]])
    end,
    post_once = child.stop,
  },
})

-- Test EcaChatSelectModel command
T["EcaChatSelectModel"] = MiniTest.new_set()

T["EcaChatSelectModel"]["command is registered"] = function()
  eq(cmd_registered_name("EcaChatSelectModel"), "EcaChatSelectModel")
end

T["EcaChatSelectModel"]["updates state when model selected"] = function()
  -- Setup initial state with models
  child.lua([[
    _G.State.config.models.list = { "model1", "model2", "model3" }
    _G.State.config.models.selected = "model1"

    -- Mock vim.ui.select to auto-select model2
    _G.mock_select("model2")
  ]])

  -- Execute command
  child.cmd("EcaChatSelectModel")

  -- Check that state was updated
  eq(child.lua_get("_G.State.config.models.selected"), "model2")
end

T["EcaChatSelectModel"]["handles nil selection"] = function()
  -- Setup initial state
  child.lua([[
    _G.State.config.models.list = { "model1", "model2" }
    _G.State.config.models.selected = "model1"

    -- Mock vim.ui.select to return nil (user cancelled)
    _G.mock_select(nil)
  ]])

  -- Execute command
  child.cmd("EcaChatSelectModel")

  -- Check that state was NOT updated (still model1)
  eq(child.lua_get("_G.State.config.models.selected"), "model1")
end

T["EcaChatSelectModel"]["displays all available models"] = function()
  -- Setup models list
  child.lua([[
    _G.State.config.models.list = { "gpt-4", "gpt-3.5-turbo", "claude-3" }

    -- Mock vim.ui.select to capture the items shown
    _G.mock_select(nil)
  ]])

  -- Execute command
  child.cmd("EcaChatSelectModel")

  -- Verify all models were shown
  local shown_items = child.lua_get("_G.shown_items")
  eq(shown_items[1], "gpt-4")
  eq(shown_items[2], "gpt-3.5-turbo")
  eq(shown_items[3], "claude-3")
end

-- Test EcaChatSelectBehavior command
T["EcaChatSelectBehavior"] = MiniTest.new_set()

T["EcaChatSelectBehavior"]["command is registered"] = function()
  eq(cmd_registered_name("EcaChatSelectBehavior"), "EcaChatSelectBehavior")
end

T["EcaChatSelectBehavior"]["updates state when behavior selected"] = function()
  -- Setup initial state with behaviors
  child.lua([[
    _G.State.config.behaviors.list = { "helpful", "creative", "concise" }
    _G.State.config.behaviors.selected = "helpful"

    -- Mock vim.ui.select to auto-select creative
    _G.mock_select("creative")
  ]])

  -- Execute command
  child.cmd("EcaChatSelectBehavior")

  -- Check that state was updated
  eq(child.lua_get("_G.State.config.behaviors.selected"), "creative")
end

T["EcaChatSelectBehavior"]["handles nil selection"] = function()
  -- Setup initial state
  child.lua([[
    _G.State.config.behaviors.list = { "helpful", "creative" }
    _G.State.config.behaviors.selected = "helpful"

    -- Mock vim.ui.select to return nil (user cancelled)
    _G.mock_select(nil)
  ]])

  -- Execute command
  child.cmd("EcaChatSelectBehavior")

  -- Check that state was NOT updated (still helpful)
  eq(child.lua_get("_G.State.config.behaviors.selected"), "helpful")
end

T["EcaChatSelectBehavior"]["displays all available behaviors"] = function()
  -- Setup behaviors list
  child.lua([[
    _G.State.config.behaviors.list = { "helpful", "creative", "concise", "technical" }

    -- Mock vim.ui.select to capture the items shown
    _G.mock_select(nil)
  ]])

  -- Execute command
  child.cmd("EcaChatSelectBehavior")

  -- Verify all behaviors were shown
  local shown_items = child.lua_get("_G.shown_items")
  eq(shown_items[1], "helpful")
  eq(shown_items[2], "creative")
  eq(shown_items[3], "concise")
  eq(shown_items[4], "technical")
end

return T
