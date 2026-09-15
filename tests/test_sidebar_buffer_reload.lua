local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local function flush(ms)
  vim.uv.sleep(ms or 80)
  child.api.nvim_eval("1")
end

local function setup_env()
  _G.Server = require("eca.server").new()
  _G.State = require("eca.state").new()
  _G.Mediator = require("eca.mediator").new(_G.Server, _G.State)
  _G.Sidebar = require("eca.sidebar").new(1, _G.Mediator)

  _G.Sidebar:open()
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua_func(setup_env)
    end,
    post_case = function()
      child.lua([[
        if _G.Sidebar then _G.Sidebar:close() end
        if _G.test_tmpfile then
          os.remove(_G.test_tmpfile)
          _G.test_tmpfile = nil
        end
      ]])
    end,
    post_once = child.stop,
  },
})

local function report_file_change(path)
  child.lua(string.format(
    [[
      Sidebar:handle_chat_content_received({
        chatId = 'chat-reload',
        content = {
          type = 'toolCalled',
          id = 'tool-reload',
          name = 'write_file',
          summary = 'Apply edit',
          details = { type = 'fileChange', path = %q, diff = '+updated' },
        },
      })
    ]],
    path
  ))
end

T["buffer reload on server file change"] = MiniTest.new_set()

T["buffer reload on server file change"]["reloads a loaded buffer when the server edits its file"] = function()
  child.lua([[
    local tmpfile = vim.fn.tempname() .. '.txt'
    vim.fn.writefile({ 'original content' }, tmpfile)
    _G.test_tmpfile = tmpfile

    vim.cmd('edit ' .. vim.fn.fnameescape(tmpfile))
    _G.test_bufnr = vim.api.nvim_get_current_buf()

    -- Simulate the server writing new content behind Neovim's back, and
    -- force the mtime forward so :checktime reliably detects the change
    -- even on filesystems with coarse mtime resolution.
    vim.fn.writefile({ 'updated content from server' }, tmpfile)
    local future = os.time() + 5
    vim.uv.fs_utime(tmpfile, future, future)
  ]])

  local tmpfile = child.lua_get("_G.test_tmpfile")
  report_file_change(tmpfile)
  flush(150)

  local lines = child.lua_get("vim.api.nvim_buf_get_lines(_G.test_bufnr, 0, -1, false)")
  eq(lines, { "updated content from server" })
end

T["buffer reload on server file change"]["does not error when the changed file has no loaded buffer"] = function()
  child.lua([[
    local tmpfile = vim.fn.tempname() .. '.txt'
    vim.fn.writefile({ 'not open in any buffer' }, tmpfile)
    _G.test_tmpfile = tmpfile
  ]])

  local tmpfile = child.lua_get("_G.test_tmpfile")

  local ok = child.lua_get(string.format(
    [[(pcall(function()
      Sidebar:handle_chat_content_received({
        chatId = 'chat-reload',
        content = {
          type = 'toolCalled',
          id = 'tool-reload',
          name = 'write_file',
          summary = 'Apply edit',
          details = { type = 'fileChange', path = %q, diff = '+updated' },
        },
      })
    end))]],
    tmpfile
  ))

  eq(ok, true)
end

T["buffer reload on server file change"]["does not discard unsaved local edits in the buffer"] = function()
  child.lua([[
    local tmpfile = vim.fn.tempname() .. '.txt'
    vim.fn.writefile({ 'original content' }, tmpfile)
    _G.test_tmpfile = tmpfile

    vim.cmd('edit ' .. vim.fn.fnameescape(tmpfile))
    _G.test_bufnr = vim.api.nvim_get_current_buf()

    -- Make an unsaved local edit before the server writes to the file.
    vim.api.nvim_buf_set_lines(_G.test_bufnr, 0, -1, false, { 'local unsaved edit' })

    vim.fn.writefile({ 'updated content from server' }, tmpfile)
    local future = os.time() + 5
    vim.uv.fs_utime(tmpfile, future, future)
  ]])

  local tmpfile = child.lua_get("_G.test_tmpfile")
  report_file_change(tmpfile)
  flush(150)

  local lines = child.lua_get("vim.api.nvim_buf_get_lines(_G.test_bufnr, 0, -1, false)")
  eq(lines, { "local unsaved edit" })
end

T["buffer reload on server file change"]["resolves a relative path to the loaded buffer's absolute path"] = function()
  child.lua([[
    local tmpfile = vim.fn.tempname() .. '.txt'
    vim.fn.writefile({ 'original content' }, tmpfile)
    _G.test_tmpfile = tmpfile

    vim.cmd('edit ' .. vim.fn.fnameescape(tmpfile))
    _G.test_bufnr = vim.api.nvim_get_current_buf()

    vim.fn.writefile({ 'updated content from server' }, tmpfile)
    local future = os.time() + 5
    vim.uv.fs_utime(tmpfile, future, future)

    -- The server may report a path relative to the current directory
    -- rather than an absolute one.
    _G.test_relative_path = vim.fn.fnamemodify(tmpfile, ':.')
  ]])

  local relative_path = child.lua_get("_G.test_relative_path")
  report_file_change(relative_path)
  flush(150)

  local lines = child.lua_get("vim.api.nvim_buf_get_lines(_G.test_bufnr, 0, -1, false)")
  eq(lines, { "updated content from server" })
end

T["buffer reload on server file change"]["still appends the filename to the tool call summary"] = function()
  child.lua([[
    local tmpfile = vim.fn.tempname() .. '.txt'
    vim.fn.writefile({ 'original content' }, tmpfile)
    _G.test_tmpfile = tmpfile

    vim.cmd('edit ' .. vim.fn.fnameescape(tmpfile))
    _G.test_bufnr = vim.api.nvim_get_current_buf()

    vim.fn.writefile({ 'updated content from server' }, tmpfile)
    local future = os.time() + 5
    vim.uv.fs_utime(tmpfile, future, future)
  ]])

  local tmpfile = child.lua_get("_G.test_tmpfile")
  report_file_change(tmpfile)
  flush(150)

  child.lua([[
    local call = Sidebar._tool_calls[1]
    local buf = Sidebar.containers.chat.bufnr
    _G.file_summary_header = call and vim.api.nvim_buf_get_lines(buf, call.header_line - 1, call.header_line, false)[1] or ''
  ]])

  local header = child.lua_get("_G.file_summary_header")
  local expected_name = child.lua_get(string.format("vim.fn.fnamemodify(%q, ':t')", tmpfile))
  local has_filename = child.lua_get(string.format("string.find(..., %q, 1, true) ~= nil", expected_name), { header })
  eq(has_filename, true)
end

return T
