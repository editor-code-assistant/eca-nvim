local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local function setup_test_environment()
  -- makes easy to debug test
  _G.log = {}
  Logger = require("eca.logger")
  Logger.test = function(message)
    table.insert(_G.log, message)
  end

  -- Setup a minimal environment: Server, State, Mediator, Sidebar
  _G.Server = require('eca.server').new()
  _G.State = require('eca.state').new()
  _G.Mediator = require('eca.mediator').new(_G.Server, _G.State)
  _G.Sidebar = require('eca.sidebar').new(1, _G.Mediator)
  _G.Eca = require('eca')
  _G.Eca.sidebars[1] = _G.Sidebar
  _G.Eca.current = { sidebar = _G.Sidebar }

  _G.get_state = function()
    local buf = _G.Sidebar.containers.input.bufnr
    local win = _G.Sidebar.containers.input.winid
    local contexts_ns = _G.Sidebar.extmarks.contexts._ns
    local contexts_ids = _G.Sidebar.extmarks.contexts._id
    local contexts = {}
    for _, id in ipairs(contexts_ids) do
      local mark = vim.api.nvim_buf_get_extmark_by_id(buf, contexts_ns, id, { details = true })
      local _, _, details = unpack(mark)
      local context_name = details and details.virt_text[1][1] or nil
      if context_name then
        table.insert(contexts, context_name)
      end
    end
    return {
      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false),
      cursor = vim.api.nvim_win_get_cursor(win),
      prefix = require('eca.config').windows.input.prefix,
      contexts = contexts,
    }
  end

  _G.set_lines = function(opts)
    local buf = _G.Sidebar.containers.input.bufnr
    local line_start = opts and opts.line_start or 0
    local line_end = opts and opts.line_end or -1
    local lines = opts and opts.lines or {}
    vim.api.nvim_buf_set_lines(buf, line_start, line_end, true, lines)
  end

  _G.set_text = function(opts)
    local buf = _G.Sidebar.containers.input.bufnr
    local start_row = opts and opts.start_row or 0
    local start_col = opts and opts.start_col or 0
    local end_row = opts and opts.end_row or 0
    local end_col = opts and opts.end_col or 1
    local lines = opts and opts.lines or {}
    vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, lines)
  end

  _G.set_cursor = function(row, col)
    local win = _G.Sidebar.containers.input.winid
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_cursor(win, { row, col })
  end

  _G.add_contexts = function(ctxs)
    for _, ctx in ipairs(ctxs) do
      _G.Mediator:add_context(ctx)
    end
  end

  -- Open the sidebar so containers are created
  _G.Sidebar:open()
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua_func(setup_test_environment)
    end,
    post_case = function()
      -- Ensure sidebar windows cleaned
      child.lua([[ if _G.Sidebar then _G.Sidebar:close() end ]])
    end,
    post_once = child.stop,
  },
})

-- Helper to flush scheduled operations (vim.schedule / vim.defer_fn)
local function flush(ms)
  vim.uv.sleep(ms or 100)
  child.api.nvim_eval("1")
end

T["context area"] = MiniTest.new_set()

T["context area"]["deletes all lines"] = function()
  flush()

  local initial = child.lua_get("_G.get_state()")

  eq(initial.lines, { "@", "" })
  eq(initial.cursor, { 2, 0 })
  eq(initial.contexts, {})

  -- Delete all lines in input buffer
  child.lua("_G.set_lines({ lines = {} })")

  flush()

  local result = child.lua_get("_G.get_state()")

  eq(result.lines, { "@", "" })
  eq(result.cursor, { 2, 0 })
  eq(result.contexts, {})
end

T["context area"]["deletes the contexts line"] = function()
  flush()

  local initial = child.lua_get("_G.get_state()")

  eq(initial.lines, { "@", "" })
  eq(initial.cursor, { 2, 0 })
  eq(initial.contexts, {})

  -- Delete only first line
  child.lua("_G.set_lines({ line_start = 0, line_end = 1, lines = {} })")

  flush()

  local result = child.lua_get("_G.get_state()")

  eq(result.lines, { "@", "" })
  eq(result.cursor, { 2, 0 })
  eq(result.contexts, {})
end

T["context area"]["deletes the input line"] = function()
  flush()

  local initial = child.lua_get("_G.get_state()")

  eq(initial.lines, { "@", "" })
  eq(initial.cursor, { 2, 0 })
  eq(initial.contexts, {})

  -- Delete the input line
  child.lua("_G.set_lines({ line_start = 1, line_end = -1, lines = {} })")

  flush()

  local result = child.lua_get("_G.get_state()")

  eq(result.lines, { "@", "" })
  eq(result.cursor, { 2, 0 })
  eq(result.contexts, {})
end

T["context area"]["keep input text when deleting contexts line"] = function()
  flush()

  local input_text = "text*in<>the > input#preFIX 123456 lIne"

  -- Set input text
  child.lua(string.format("_G.set_lines({ line_start = 1, line_end = -1, lines = { '%s' } })", input_text))

  flush()

  local initial = child.lua_get("_G.get_state()")

  eq(initial.lines, { "@", input_text })
  eq(initial.cursor, { 2, 0 })
  eq(initial.contexts, {})

  -- Delete the contexts line
  child.lua("_G.set_lines({ line_start = 0, line_end = 1, lines = {} })")

  flush()

  local result = child.lua_get("_G.get_state()")

  eq(result.lines, { "@", input_text })
  eq(result.cursor, { 2, #input_text })
  eq(result.contexts, {})
end

T["context area"]["keep multiple lines text input when removing the first context"] = function()
  flush()

  local input_text_first_line = "text*in<>the > input#preFIX 123456 lIne"
  local input_text_second_line = "text in the 2nd line after input prefix line"

  -- Set input text
  child.lua(string.format("_G.set_lines({ line_start = 1, line_end = -1, lines = { '%s', '%s' } })", input_text_first_line, input_text_second_line))

  -- Add context
  child.lua([[_G.add_contexts({
    { type = 'file', data = { path = '/tmp/sidebar.lua' } }
  })]])

  flush()

  local initial = child.lua_get("_G.get_state()")

  eq(initial.lines, { "@@", input_text_first_line, input_text_second_line })
  eq(initial.cursor, { 3, #input_text_second_line })
  eq(initial.contexts, { "sidebar.lua " })

  -- Set cursor to first context placeholder
  child.lua("_G.set_cursor(1, 0)")

  -- Delete the context placeholder in contexts line
  child.lua("_G.set_text({ start_row = 0, start_col = 0, end_row = 0, end_col = 1, lines = {} })")

  flush()

  -- eq(child.lua_get("_G.log"), {})

  local result = child.lua_get("_G.get_state()")

  eq(result.lines, { "@", input_text_first_line, input_text_second_line })
  eq(result.cursor, { 3, #input_text_second_line })
  eq(result.contexts, {})
end

T["context area"]["remove all contexts when deleting the contexts line"] = function()
  flush()

  local input_text_first_line = "text*in<>the > input#preFIX 123456 lIne"
  local input_text_second_line = "text in the 2nd line after input prefix line"
  local input_text_fourth_line = "another text in the 4 line (note that line 3 is only with a newline)"

  -- Set input text
  child.lua(string.format("_G.set_lines({ line_start = 1, line_end = -1, lines = { '%s', '%s', '', '%s' } })", input_text_first_line, input_text_second_line, input_text_fourth_line))

  -- Add context
  child.lua([[_G.add_contexts({
    { type = 'file', data = { path = '/tmp/sidebar.lua' } },
    { type = 'file', data = { path = '/tmp/sidebar.lua', lines_range = {line_start = 25, line_end = 50 } } }
  })]])

  flush()

  local initial = child.lua_get("_G.get_state()")

  eq(initial.lines, { "@@@", input_text_first_line, input_text_second_line, "", input_text_fourth_line })
  eq(initial.cursor, { 5, #input_text_fourth_line })
  eq(initial.contexts, { "sidebar.lua ", "sidebar.lua:25-50 " })

  -- Delete the contexts line
  child.lua("_G.set_lines({ line_start = 0, line_end = 1, lines = {} })")

  flush()

  local result = child.lua_get("_G.get_state()")

  eq(result.lines, { "@", input_text_first_line, input_text_second_line, "", input_text_fourth_line })
  eq(result.cursor, { 5, #input_text_fourth_line })
  eq(result.contexts, {})
end

T["context area"]["remove one specific context when multiple contexts are present"] = function()
  flush()

  local input_text_first_line = "text*in<>the > input#preFIX 123456 lIne"
  local input_text_second_line = "text in the 2nd line after input prefix line"
  local input_text_fourth_line = "another text in the 4 line (note that line 3 is only with a newline)"

  -- Set input text
  child.lua(string.format("_G.set_lines({ line_start = 1, line_end = -1, lines = { '%s', '%s', '', '%s' } })", input_text_first_line, input_text_second_line, input_text_fourth_line))

  -- Add context
  child.lua([[_G.add_contexts({
    { type = 'file', data = { path = '/tmp/sidebar.lua' } },
    { type = 'file', data = { path = '/tmp/sidebar.lua', lines_range = { line_start = 25, line_end = 50 } } },
    { type = 'file', data = { path = '/tmp/server.lua' } }
  })]])

  flush()

  local initial = child.lua_get("_G.get_state()")

  eq(initial.lines, { "@@@@", input_text_first_line, input_text_second_line, "", input_text_fourth_line })
  eq(initial.cursor, { 5, #input_text_fourth_line })
  eq(initial.contexts, { "sidebar.lua ", "sidebar.lua:25-50 ", "server.lua " })

  -- Set cursor to the second context placeholder
  child.lua("_G.set_cursor(1, 1)")

  -- Delete the context placeholder in contexts line
  child.lua("_G.set_text({ start_row = 0, start_col = 1, end_row = 0, end_col = 2, lines = {} })")

  flush()

  local result = child.lua_get("_G.get_state()")

  eq(result.lines, { "@@@", input_text_first_line, input_text_second_line, "", input_text_fourth_line })
  eq(result.cursor, { 5, #input_text_fourth_line })
  eq(result.contexts, { "sidebar.lua ", "server.lua " })
end

T["context area"]["remove contexts one by one in an arbitrary order while preserving input"] = function()
  flush()

  local input_text_first_line = "text*in<>the > input#preFIX 123456 lIne"
  local input_text_second_line = "text in the 2nd line after input prefix line"
  local input_text_fourth_line = "another text in the 4 line (note that line 3 is only with a newline)"

  -- Set input text
  child.lua(string.format("_G.set_lines({ line_start = 1, line_end = -1, lines = { '%s', '%s', '', '%s' } })", input_text_first_line, input_text_second_line, input_text_fourth_line))

  -- Add context
  child.lua([[_G.add_contexts({
    { type = 'file', data = { path = '/dev/chat.lua' } },
    { type = 'file', data = { path = '/tmp/sidebar.lua' } },
    { type = 'file', data = { path = '/tmp/sidebar.lua', lines_range = { line_start = 25, line_end = 50 } } },
    { type = 'file', data = { path = '/dev/server.lua', lines_range = { line_start = 999, line_end = 1200 } } },
    { type = 'file', data = { path = '/dev/server.lua' } },
  })]])

  flush()

  local initial = child.lua_get("_G.get_state()")

  eq(initial.lines, { "@@@@@@", input_text_first_line, input_text_second_line, "", input_text_fourth_line })
  eq(initial.cursor, { 5, #input_text_fourth_line })
  eq(initial.contexts, { "chat.lua ", "sidebar.lua ", "sidebar.lua:25-50 ", "server.lua:999-1200 ", "server.lua " })

  -- Set cursor to the second context placeholder
  child.lua("_G.set_cursor(1, 1)")

  -- Delete the context placeholder in contexts line
  child.lua("_G.set_text({ start_row = 0, start_col = 1, end_row = 0, end_col = 2, lines = {} })")

  flush()

  local result = child.lua_get("_G.get_state()")

  eq(result.lines, { "@@@@@", input_text_first_line, input_text_second_line, "", input_text_fourth_line })
  eq(result.cursor, { 5, #input_text_fourth_line })
  eq(result.contexts, { "chat.lua ", "sidebar.lua:25-50 ", "server.lua:999-1200 ", "server.lua " })

  -- Set cursor to the second context placeholder
  child.lua("_G.set_cursor(1, 3)")

  -- Delete the context placeholder in contexts line
  child.lua("_G.set_text({ start_row = 0, start_col = 3, end_row = 0, end_col = 4, lines = {} })")

  flush()

  local result_2 = child.lua_get("_G.get_state()")

  eq(result_2.lines, { "@@@@", input_text_first_line, input_text_second_line, "", input_text_fourth_line })
  eq(result_2.cursor, { 5, #input_text_fourth_line })
  eq(result_2.contexts, { "chat.lua ", "sidebar.lua:25-50 ", "server.lua:999-1200 " })

  -- Set cursor to the second context placeholder
  child.lua("_G.set_cursor(1, 0)")

  -- Delete the context placeholder in contexts line
  child.lua("_G.set_text({ start_row = 0, start_col = 0, end_row = 0, end_col = 1, lines = {} })")

  flush()

  local result_3 = child.lua_get("_G.get_state()")

  eq(result_3.lines, { "@@@", input_text_first_line, input_text_second_line, "", input_text_fourth_line })
  eq(result_3.cursor, { 5, #input_text_fourth_line })
  eq(result_3.contexts, { "sidebar.lua:25-50 ", "server.lua:999-1200 " })

  -- Delete the contexts line
  child.lua("_G.set_lines({ line_start = 0, line_end = 1, lines = {} })")

  flush()

  local result_4 = child.lua_get("_G.get_state()")

  eq(result_4.lines, { "@", input_text_first_line, input_text_second_line, "", input_text_fourth_line })
  eq(result_4.cursor, { 5, #input_text_fourth_line })
  eq(result_4.contexts, {})
end

T["context area"]["displays filename in context area and expands path in sent message"] = function()
  flush()

  local rel_path = "lua/eca/sidebar.lua"
  local abs_path = child.lua_get("vim.fn.fnamemodify(..., ':p')", { rel_path })
  local tail = child.lua_get("vim.fn.fnamemodify(..., ':t')", { rel_path }) .. " "

  -- Add a context with relative path; context area should show only the
  -- filename (tail), not the full path.
  child.lua([[_G.add_contexts({
    { type = 'file', data = { path = 'lua/eca/sidebar.lua' } },
  })]])

  flush()

  local state = child.lua_get("_G.get_state()")

  -- Contexts in the area should use the tail of the path
  eq(state.contexts, { tail })

  -- Mock server on mediator so we don't start a real process. Capture
  -- the last request instead of sending anything.
  child.lua([[
    _G.last_request = nil
    _G.Mediator.server = {
      is_running = function()
        return true
      end,
      send_request = function(_, method, params, callback)
        _G.last_request = { method = method, params = params }
        if callback then
          callback(nil, {})
        end
      end,
    }
  ]])

  -- Send a message that references the same relative path using the
  -- @path shorthand. Sidebar should expand it to an absolute path
  -- before sending to the (mocked) server.
  child.lua("_G.Sidebar:_send_message('please check @' .. '" .. rel_path .. "')")

  local req = child.lua_get("_G.last_request")
  eq(req.method, "chat/prompt")

  local msg = req.params.message
  local expected = "please check @" .. abs_path

  -- Message sent to the server must contain the absolute path and no
  -- longer contain the original relative path.
  eq(msg, expected)
end

return T
