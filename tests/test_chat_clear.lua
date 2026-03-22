local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local function flush(ms)
  vim.uv.sleep(ms or 120)
  child.api.nvim_eval("1")
end

local function setup_helpers()
  _G.fill_chat = function()
    local sidebar = require("eca").get()
    local chat = sidebar.containers.chat
    vim.api.nvim_buf_set_lines(chat.bufnr, 0, -1, false, { "hello", "world", "foo" })
  end

  _G.get_chat_lines = function()
    local sidebar = require("eca").get()
    if not sidebar then
      return nil
    end
    local chat = sidebar.containers and sidebar.containers.chat
    if not chat or not vim.api.nvim_buf_is_valid(chat.bufnr) then
      return nil
    end
    return vim.api.nvim_buf_get_lines(chat.bufnr, 0, -1, false)
  end

  _G.chat_has_old_content = function()
    for _, line in ipairs(_G.get_chat_lines() or {}) do
      if line == "hello" or line == "world" or line == "foo" then
        return true
      end
    end
    return false
  end

  _G.get_sidebar_flags = function()
    local sidebar = require("eca").get()
    if not sidebar then
      return nil
    end
    return {
      welcome_message_applied = sidebar._welcome_message_applied,
      force_welcome = sidebar._force_welcome,
    }
  end
end

local function setup_env(preserve_chat_history)
  child.lua(
    [[
    local Eca = require("eca")
    Eca.setup({
      behavior = {
        auto_start_server = false,
        auto_set_keymaps = false,
        preserve_chat_history = ...,
      },
    })
    local tab = vim.api.nvim_get_current_tabpage()
    Eca._init(tab)
    Eca.open_sidebar({})
  ]],
    { preserve_chat_history }
  )
  child.lua_func(setup_helpers)
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
    end,
    post_once = child.stop,
  },
})

-- EcaChatClear ---------------------------------------------------------------

T["EcaChatClear"] = MiniTest.new_set()

T["EcaChatClear"]["command is registered"] = function()
  setup_env(false)
  local commands = child.lua_get("vim.api.nvim_get_commands({})")
  eq(type(commands.EcaChatClear), "table")
  eq(commands.EcaChatClear.name, "EcaChatClear")
end

T["EcaChatClear"]["clears chat buffer when sidebar is open"] = function()
  setup_env(false)
  flush(200)

  child.lua("_G.fill_chat()")
  eq(#child.lua_get("_G.get_chat_lines()"), 3)

  child.cmd("EcaChatClear")

  eq(child.lua_get("_G.get_chat_lines()"), { "" })
end

T["EcaChatClear"]["works without error when buffer is already empty"] = function()
  setup_env(false)
  flush(200)

  child.lua([[
    local sidebar = require("eca").get()
    vim.api.nvim_buf_set_lines(sidebar.containers.chat.bufnr, 0, -1, false, {})
  ]])

  child.cmd("EcaChatClear")

  eq(child.lua_get("_G.get_chat_lines()"), { "" })
end

T["EcaChatClear"]["clears hidden buffer when sidebar is closed with preserve=true"] = function()
  setup_env(true)
  flush(200)

  child.lua("_G.fill_chat()")
  child.lua([[require("eca").close_sidebar()]])
  flush(100)

  child.cmd("EcaChatClear")

  eq(child.lua_get("_G.get_chat_lines()"), { "" })
end

T["EcaChatClear"]["buffer stays cleared on reopen with preserve=true"] = function()
  setup_env(true)
  flush(200)

  child.lua("_G.fill_chat()")
  child.lua([[require("eca").close_sidebar()]])
  flush(100)

  child.cmd("EcaChatClear")

  eq(child.lua_get("_G.get_chat_lines()"), { "" })

  child.lua([[require("eca").open_sidebar({})]])
  flush(200)

  eq(child.lua_get("_G.chat_has_old_content()"), false)
end

T["EcaChatClear"]["is a no-op when sidebar is closed and buffer was destroyed (preserve=false)"] = function()
  -- With preserve=false, closing the sidebar destroys the buffer, so there is
  -- nothing for EcaChatClear to clear. The important guarantee is that the
  -- command does not raise an error in this state.
  setup_env(false)
  flush(200)

  child.lua("_G.fill_chat()")
  child.lua([[require("eca").close_sidebar()]])
  flush(100)

  local ok = child.lua_get("pcall(vim.cmd, 'EcaChatClear')")
  eq(ok, true)
end

T["EcaChatClear"]["marks welcome as applied and clears force_welcome after clear"] = function()
  setup_env(false)
  flush(200)

  child.lua("_G.fill_chat()")
  child.cmd("EcaChatClear")

  local flags = child.lua_get("_G.get_sidebar_flags()")
  eq(flags.welcome_message_applied, true)
  eq(flags.force_welcome, false)
end

T["EcaChatClear"]["is idempotent when called twice"] = function()
  setup_env(false)
  flush(200)

  child.lua("_G.fill_chat()")
  child.cmd("EcaChatClear")
  child.cmd("EcaChatClear")

  eq(child.lua_get("_G.get_chat_lines()"), { "" })
end

-- preserve_chat_history toggle cycle -----------------------------------------

T["preserve_chat_history"] = MiniTest.new_set()

T["preserve_chat_history"]["reuses same bufnr and keeps content across close/open"] = function()
  setup_env(true)
  flush(200)

  child.lua("_G.fill_chat()")
  local bufnr_before = child.lua_get("require('eca').get().containers.chat.bufnr")

  child.lua([[require("eca").close_sidebar()]])
  flush(100)
  child.lua([[require("eca").open_sidebar({})]])
  flush(200)

  local bufnr_after = child.lua_get("require('eca').get().containers.chat.bufnr")
  eq(bufnr_before, bufnr_after)
  eq(child.lua_get("_G.chat_has_old_content()"), true)
end

T["preserve_chat_history"]["does not leak buffers across repeated toggles"] = function()
  setup_env(true)
  flush(200)

  local buf_count_before = child.lua_get("#vim.api.nvim_list_bufs()")

  for _ = 1, 5 do
    child.lua([[require("eca").close_sidebar()]])
    flush(100)
    child.lua([[require("eca").open_sidebar({})]])
    flush(200)
  end

  local buf_count_after = child.lua_get("#vim.api.nvim_list_bufs()")
  -- Allow at most 1 extra buffer (nui internals), but definitely not 5+
  eq(buf_count_after - buf_count_before <= 1, true)
end

T["preserve_chat_history"]["content is lost when preserve is disabled"] = function()
  setup_env(false)
  flush(200)

  child.lua("_G.fill_chat()")

  child.lua([[require("eca").close_sidebar()]])
  flush(100)
  child.lua([[require("eca").open_sidebar({})]])
  flush(200)

  eq(child.lua_get("_G.chat_has_old_content()"), false)
end

return T
