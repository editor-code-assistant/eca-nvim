local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local function flush(ms)
  vim.uv.sleep(ms or 120)
  child.api.nvim_eval("1")
end

local function setup_env()
  _G.Server = require('eca.server').new()
  _G.State = require('eca.state').new()
  _G.Mediator = require('eca.mediator').new(_G.Server, _G.State)
  _G.Sidebar = require('eca.sidebar').new(1, _G.Mediator)

  _G.Sidebar:open()

  _G.fill_chat = function(n)
    local chat = _G.Sidebar.containers.chat
    vim.api.nvim_set_option_value('modifiable', true, { buf = chat.bufnr })

    local lines = {}
    for i = 1, n do
      lines[i] = string.format('line %03d', i)
    end

    vim.api.nvim_buf_set_lines(chat.bufnr, 0, -1, false, lines)
  end

  _G.focus_chat = function()
    vim.api.nvim_set_current_win(_G.Sidebar.containers.chat.winid)
  end

  _G.focus_input = function()
    vim.api.nvim_set_current_win(_G.Sidebar.containers.input.winid)
  end

  _G.set_chat_cursor = function(row)
    local win = _G.Sidebar.containers.chat.winid
    vim.api.nvim_win_set_cursor(win, { row, 0 })
  end

  _G.add_assistant_message = function(text)
    _G.Sidebar:_add_message('assistant', text)
  end

  _G.get_chat_view = function()
    local chat = _G.Sidebar.containers.chat
    local view = vim.api.nvim_win_call(chat.winid, function()
      local v = vim.fn.winsaveview()
      return { topline = v.topline, lnum = v.lnum }
    end)

    local bottomline = vim.api.nvim_win_call(chat.winid, function()
      return vim.fn.line('w$')
    end)

    return {
      current_win = vim.api.nvim_get_current_win(),
      chat_win = chat.winid,
      input_win = _G.Sidebar.containers.input.winid,
      cursor = vim.api.nvim_win_get_cursor(chat.winid),
      topline = view.topline,
      lnum = view.lnum,
      bottomline = bottomline,
      line_count = vim.api.nvim_buf_line_count(chat.bufnr),
    }
  end
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua_func(setup_env)
    end,
    post_case = function()
      child.lua([[ if _G.Sidebar then _G.Sidebar:close() end ]])
    end,
    post_once = child.stop,
  },
})

T["sidebar autoscroll"] = MiniTest.new_set()

T["sidebar autoscroll"]["auto-scrolls when chat is not focused"] = function()
  -- Let deferred sidebar setup (like initial focus) settle.
  flush(200)

  child.lua([[
    _G.fill_chat(100)
    _G.focus_chat()
    _G.set_chat_cursor(1)
    _G.focus_input()
  ]])

  -- Add a new assistant message while focus is on input.
  child.lua([[_G.add_assistant_message('incoming')]])

  flush(220)

  local view = child.lua_get("_G.get_chat_view()")

  -- Focus should remain on input.
  eq(view.current_win, view.input_win)
  -- Chat cursor should be moved to the bottom.
  eq(view.cursor[1], view.line_count)
end

T["sidebar autoscroll"]["does not auto-scroll when chat is focused and not at bottom"] = function()
  -- Let deferred sidebar setup (like initial focus) settle.
  flush(200)

  child.lua([[
    _G.fill_chat(100)
    _G.focus_chat()
    _G.set_chat_cursor(10)
    _G.before = _G.get_chat_view()
  ]])

  child.lua([[_G.add_assistant_message('incoming')]])

  flush(220)

  local before = child.lua_get("_G.before")
  local after = child.lua_get("_G.get_chat_view()")

  eq(after.current_win, after.chat_win)
  eq(after.cursor[1], before.cursor[1])
  eq(after.topline, before.topline)
end

T["sidebar autoscroll"]["auto-scrolls when chat is focused and at bottom"] = function()
  -- Let deferred sidebar setup (like initial focus) settle.
  flush(200)

  child.lua([[
    _G.fill_chat(100)
    _G.focus_chat()
    _G.set_chat_cursor(100)
    _G.before = _G.get_chat_view()
  ]])

  child.lua([[_G.add_assistant_message('incoming')]])

  flush(220)

  local after = child.lua_get("_G.get_chat_view()")

  eq(after.current_win, after.chat_win)
  eq(after.cursor[1], after.line_count)
end

return T
