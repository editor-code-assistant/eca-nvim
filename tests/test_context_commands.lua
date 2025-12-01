local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local function flush(ms)
  vim.uv.sleep(ms or 100)
  child.api.nvim_eval("1")
end

local function setup_test_environment()
  child.lua([[
    local Eca = require('eca')

    -- Setup plugin with no auto server or keymaps so tests are
    -- deterministic and don't spawn external processes.
    Eca.setup({
      behavior = {
        auto_start_server = false,
        auto_set_keymaps = false,
      },
    })

    -- Ensure we have a sidebar/mediator for the current tab
    local tab = vim.api.nvim_get_current_tabpage()
    Eca._init(tab)
    Eca.open_sidebar({})

    -- Fake server so eca.api thinks it is running but we never
    -- actually start the external binary.
    if Eca.server then
      Eca.server.is_running = function()
        return true
      end
    else
      Eca.server = {
        is_running = function()
          return true
        end,
      }
    end

    -- Clear any existing contexts before each test
    if Eca.mediator then
      Eca.mediator:clear_contexts()
    end

    -- Capture Logger.notify calls (used by deprecated commands and
    -- some API helpers) so we can assert on deprecation messages.
    local Logger = require('eca.logger')
    _G.Logger = Logger
    _G.original_logger_notify = Logger.notify
    _G.captured_notifications = {}

    Logger.notify = function(msg, level, opts)
      level = level or vim.log.levels.INFO
      opts = opts or {}

      table.insert(_G.captured_notifications, {
        message = msg,
        level = level,
        opts = opts,
      })

      if _G.original_logger_notify then
        _G.original_logger_notify(msg, level, opts)
      end
    end
  ]])
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      setup_test_environment()
    end,
    post_once = child.stop,
  },
})

local function contexts_count()
  return child.lua_get("#require('eca').mediator:contexts()")
end

local function get_contexts()
  return child.lua_get("require('eca').mediator:contexts()")
end

-- EcaChatAddFile -----------------------------------------------------------

T["EcaChatAddFile"] = MiniTest.new_set()

T["EcaChatAddFile"]["command is registered"] = function()
  local commands = child.lua_get("vim.api.nvim_get_commands({})")
  eq(type(commands.EcaChatAddFile), "table")
  eq(commands.EcaChatAddFile.name, "EcaChatAddFile")
end

T["EcaChatAddFile"]["adds current file as context when no args"] = function()
  child.cmd("edit README.md")
  local abs = child.lua_get("vim.fn.fnamemodify('README.md', ':p')")

  eq(contexts_count(), 0)

  child.cmd("EcaChatAddFile")
  flush()

  local contexts = get_contexts()
  eq(#contexts, 1)
  eq(contexts[1].type, "file")
  eq(contexts[1].data.path, abs)
end

T["EcaChatAddFile"]["adds provided path as context when args are given"] = function()
  local filename = "README.md"
  local expected_abs = child.lua_get("vim.fn.fnamemodify(..., ':p')", { filename })

  eq(contexts_count(), 0)

  child.cmd("EcaChatAddFile " .. filename)
  flush()

  local contexts = get_contexts()
  eq(#contexts, 1)
  eq(contexts[1].type, "file")
  eq(contexts[1].data.path, expected_abs)
end

-- Deprecated EcaAddFile ----------------------------------------------------

T["EcaAddFile"] = MiniTest.new_set()

T["EcaAddFile"]["command is registered"] = function()
  local commands = child.lua_get("vim.api.nvim_get_commands({})")
  eq(type(commands.EcaAddFile), "table")
  eq(commands.EcaAddFile.name, "EcaAddFile")
end

T["EcaAddFile"]["shows deprecation notice when called"] = function()
  child.cmd("EcaAddFile")
  flush()

  local notifications = child.lua_get("_G.captured_notifications")
  eq(#notifications > 0, true)
  eq(notifications[1].message, "EcaAddFile is deprecated. Use EcaChatAddFile instead.")
  eq(notifications[1].level, child.lua_get("vim.log.levels.WARN"))
end

-- EcaChatRemoveFile --------------------------------------------------------

T["EcaChatRemoveFile"] = MiniTest.new_set()

T["EcaChatRemoveFile"]["command is registered"] = function()
  local commands = child.lua_get("vim.api.nvim_get_commands({})")
  eq(type(commands.EcaChatRemoveFile), "table")
  eq(commands.EcaChatRemoveFile.name, "EcaChatRemoveFile")
end

T["EcaChatRemoveFile"]["removes current file context when no args"] = function()
  child.cmd("edit README.md")

  child.cmd("EcaChatAddFile")
  flush()
  eq(contexts_count(), 1)

  child.cmd("EcaChatRemoveFile")
  flush()

  eq(contexts_count(), 0)
end

T["EcaChatRemoveFile"]["removes context for provided path when args are given"] = function()
  local filename = "README.md"

  child.cmd("edit README.md")
  child.cmd("EcaChatAddFile")
  flush()
  eq(contexts_count(), 1)

  child.cmd("EcaChatRemoveFile " .. filename)
  flush()

  eq(contexts_count(), 0)
end

-- Deprecated EcaRemoveContext ---------------------------------------------

T["EcaRemoveContext"] = MiniTest.new_set()

T["EcaRemoveContext"]["command is registered"] = function()
  local commands = child.lua_get("vim.api.nvim_get_commands({})")
  eq(type(commands.EcaRemoveContext), "table")
  eq(commands.EcaRemoveContext.name, "EcaRemoveContext")
end

T["EcaRemoveContext"]["shows deprecation notice when called"] = function()
  child.cmd("EcaRemoveContext")
  flush()

  local notifications = child.lua_get("_G.captured_notifications")
  eq(#notifications > 0, true)
  eq(notifications[1].message, "EcaRemoveContext is deprecated. Use EcaChatRemoveFile instead.")
  eq(notifications[1].level, child.lua_get("vim.log.levels.WARN"))
end

T["EcaChatAddSelection"] = MiniTest.new_set()

T["EcaChatAddSelection"]["command is registered"] = function()
  local commands = child.lua_get("vim.api.nvim_get_commands({})")
  eq(type(commands.EcaChatAddSelection), "table")
  eq(commands.EcaChatAddSelection.name, "EcaChatAddSelection")
end

T["EcaChatAddSelection"]["adds a ranged file context based on visual selection"] = function()
  child.cmd("edit README.md")
  local abs = child.lua_get("vim.fn.fnamemodify('README.md', ':p')")

  -- Manually set visual selection marks for lines 1-2 to avoid headless
  -- visual-mode quirks
  child.lua([[
    local bufnr = vim.api.nvim_get_current_buf()
    vim.fn.setpos("'<", {bufnr, 1, 1, 0})
    vim.fn.setpos("'>", {bufnr, 2, 1, 0})
  ]])

  eq(contexts_count(), 0)

  child.cmd("EcaChatAddSelection")
  flush(200)

  local contexts = get_contexts()
  eq(#contexts, 1)
  eq(contexts[1].type, "file")
  eq(contexts[1].data.path, abs)
  eq(contexts[1].data.lines_range.line_start, 1)
  eq(contexts[1].data.lines_range.line_end, 2)
end

-- Deprecated EcaAddSelection -----------------------------------------------

T["EcaAddSelection"] = MiniTest.new_set()

T["EcaAddSelection"]["command is registered"] = function()
  local commands = child.lua_get("vim.api.nvim_get_commands({})")
  eq(type(commands.EcaAddSelection), "table")
  eq(commands.EcaAddSelection.name, "EcaAddSelection")
end

T["EcaAddSelection"]["shows deprecation notice when called"] = function()
  child.cmd("EcaAddSelection")
  flush(200)

  local notifications = child.lua_get("_G.captured_notifications")
  eq(#notifications > 0, true)
  eq(notifications[1].message, "EcaAddSelection is deprecated. Use EcaChatAddSelection instead.")
  eq(notifications[1].level, child.lua_get("vim.log.levels.WARN"))
end

T["EcaChatListContexts"] = MiniTest.new_set()

T["EcaChatListContexts"]["command is registered"] = function()
  local commands = child.lua_get("vim.api.nvim_get_commands({})")
  eq(type(commands.EcaChatListContexts), "table")
  eq(commands.EcaChatListContexts.name, "EcaChatListContexts")
end

T["EcaChatListContexts"]["runs without modifying contexts"] = function()
  child.cmd("edit README.md")
  child.cmd("EcaChatAddFile")
  flush()

  local before = contexts_count()
  child.cmd("EcaChatListContexts")
  flush()
  local after = contexts_count()

  eq(after, before)
end

-- Deprecated EcaListContexts -----------------------------------------------

T["EcaListContexts"] = MiniTest.new_set()

T["EcaListContexts"]["command is registered"] = function()
  local commands = child.lua_get("vim.api.nvim_get_commands({})")
  eq(type(commands.EcaListContexts), "table")
  eq(commands.EcaListContexts.name, "EcaListContexts")
end

T["EcaListContexts"]["shows deprecation notice when called"] = function()
  child.cmd("EcaListContexts")
  flush()

  local notifications = child.lua_get("_G.captured_notifications")
  eq(#notifications > 0, true)
  eq(notifications[1].message, "EcaListContexts is deprecated. Use EcaChatListContexts instead.")
  eq(notifications[1].level, child.lua_get("vim.log.levels.WARN"))
  -- No explicit level is passed in the command for this deprecation,
  -- so we only assert on the message.
end

T["EcaChatClearContexts"] = MiniTest.new_set()

T["EcaChatClearContexts"]["command is registered"] = function()
  local commands = child.lua_get("vim.api.nvim_get_commands({})")
  eq(type(commands.EcaChatClearContexts), "table")
  eq(commands.EcaChatClearContexts.name, "EcaChatClearContexts")
end

T["EcaChatClearContexts"]["clears all contexts"] = function()
  child.cmd("edit README.md")
  child.cmd("EcaChatAddFile")
  child.cmd("EcaChatAddFile")
  flush()
  eq(contexts_count() > 0, true)

  child.cmd("EcaChatClearContexts")
  flush()

  eq(contexts_count(), 0)
end

-- Deprecated EcaClearContexts ----------------------------------------------

T["EcaClearContexts"] = MiniTest.new_set()

T["EcaClearContexts"]["command is registered"] = function()
  local commands = child.lua_get("vim.api.nvim_get_commands({})")
  eq(type(commands.EcaClearContexts), "table")
  eq(commands.EcaClearContexts.name, "EcaClearContexts")
end

T["EcaClearContexts"]["shows deprecation notice when called"] = function()
  child.cmd("EcaClearContexts")
  flush()

  local notifications = child.lua_get("_G.captured_notifications")
  eq(#notifications > 0, true)
  eq(notifications[1].message, "EcaClearContexts is deprecated. Use EcaChatClearContexts instead.")
  eq(notifications[1].level, child.lua_get("vim.log.levels.WARN"))
  -- No explicit level is passed in the command for this deprecation,
  -- so we only assert on the message.
end

return T
