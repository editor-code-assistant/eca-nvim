local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local function flush(ms)
  vim.uv.sleep(ms or 80)
  child.api.nvim_eval("1")
end

local function setup_env()
  -- Minimal environment with Server, State, Mediator, Sidebar
  _G.Server = require('eca.server').new()
  _G.State = require('eca.state').new()
  _G.Mediator = require('eca.mediator').new(_G.Server, _G.State)
  _G.Sidebar = require('eca.sidebar').new(1, _G.Mediator)

  -- Open sidebar so containers are created
  _G.Sidebar:open()
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

T["usage formatting"] = MiniTest.new_set()

T["usage formatting"]["uses default short token format"] = function()
  child.lua([[
    local Sidebar = _G.Sidebar
    local Mediator = _G.Mediator

    -- Stub mediator usage values
    function Mediator:status_state() return 'responding' end
    function Mediator:status_text() return 'Responding' end
    function Mediator:tokens_session() return 1499 end
    function Mediator:tokens_limit() return 1501 end
    function Mediator:costs_session() return '0.00' end

    Sidebar:_update_usage_info()
  ]])

  local info = child.lua_get("_G.Sidebar._usage_info")
  -- 1499 -> 1k, 1501 -> 2k with rounding
  eq(info, "1k / 2k ($0.00)")
end

T["usage formatting"]["respects custom windows.usage.format"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        usage = {
          format = '{session_tokens} of {limit_tokens} tokens (${session_cost})',
        },
      },
    })

    local Sidebar = _G.Sidebar
    local Mediator = _G.Mediator

    function Mediator:status_state() return 'responding' end
    function Mediator:status_text() return 'Responding' end
    function Mediator:tokens_session() return 42 end
    function Mediator:tokens_limit() return 1000 end
    function Mediator:costs_session() return '1.23' end

    Sidebar:_update_usage_info()
  ]])

  local info = child.lua_get("_G.Sidebar._usage_info")
  eq(info, "42 of 1000 tokens ($1.23)")
end

T["tool call diffs"] = MiniTest.new_set()

T["tool call diffs"]["shows arguments and outputs sections when expanded"] = function()
  child.lua([[
    local Sidebar = _G.Sidebar

    -- Simulate a tool call lifecycle with arguments and outputs (no diff)
    Sidebar:handle_chat_content_received({
      chatId = 'chat-out',
      content = {
        type = 'toolCallPrepare',
        id = 'tool-out',
        name = 'test_tool',
        summary = 'Test Tool',
        argumentsText = '{"value": 1}',
        details = {},
      },
    })

    Sidebar:handle_chat_content_received({
      chatId = 'chat-out',
      content = {
        type = 'toolCallRunning',
        id = 'tool-out',
      },
    })

    Sidebar:handle_chat_content_received({
      chatId = 'chat-out',
      content = {
        type = 'toolCalled',
        id = 'tool-out',
        name = 'test_tool',
        summary = 'Test Tool',
        outputs = {
          { type = 'text', text = 'tool-output-123' },
        },
      },
    })
  ]])

  flush(100)

  child.lua([[
    local Sidebar = _G.Sidebar
    local call = Sidebar._tool_calls[1]
    local chat = Sidebar.containers.chat

    if not call or not chat or not chat.bufnr then
      _G.tool_details = { expanded = false, has_arguments = false, has_output = false, has_output_text = false }
      return
    end

    -- Expand the arguments/output block via the header
    vim.api.nvim_win_set_cursor(chat.winid, { call.header_line, 0 })
    Sidebar:_toggle_tool_call_at_cursor()

    local buf = chat.bufnr
    local lines = vim.api.nvim_buf_get_lines(buf, call.header_line, call.header_line + 20, false)

    local details = {
      expanded = call.expanded,
      has_arguments = false,
      has_output = false,
      has_output_text = false,
    }

    for _, line in ipairs(lines) do
      if line == 'Arguments:' then
        details.has_arguments = true
      elseif line == 'Output:' then
        details.has_output = true
      end
      if string.find(line, 'tool-output-123', 1, true) then
        details.has_output_text = true
      end
    end

    _G.tool_details = details
  ]])

  local info = child.lua_get("_G.tool_details")

  eq(info.expanded, true)
  eq(info.has_arguments, true)
  eq(info.has_output, true)
  eq(info.has_output_text, true)
end

T["tool call diffs"]["shows diff label and toggles diff block with <CR>"] = function()
  child.lua([[
    local Sidebar = _G.Sidebar
    local chat = Sidebar.containers.chat

    -- Simulate a tool call lifecycle with diff
    Sidebar:handle_chat_content_received({
      chatId = 'chat-1',
      content = {
        type = 'toolCallPrepare',
        id = 'tool-1',
        name = 'test_tool',
        summary = 'Test Tool',
        argumentsText = '{"value": 1}',
        details = {},
      },
    })

    Sidebar:handle_chat_content_received({
      chatId = 'chat-1',
      content = {
        type = 'toolCallRunning',
        id = 'tool-1',
      },
    })

    Sidebar:handle_chat_content_received({
      chatId = 'chat-1',
      content = {
        type = 'toolCalled',
        id = 'tool-1',
        name = 'test_tool',
        summary = 'Test Tool',
        details = { diff = '+added\n-removed' },
      },
    })
  ]])

  flush(100)

  child.lua([[
    local Sidebar = _G.Sidebar
    local call = Sidebar._tool_calls[1]
    local buf = Sidebar.containers.chat.bufnr
    _G.call_info = {
      has_diff = call and call.has_diff or false,
      header_line = call and call.header_line or 0,
      label_line = call and call.label_line or 0,
      header_text = call and vim.api.nvim_buf_get_lines(buf, call.header_line - 1, call.header_line, false)[1] or '',
      label_text = call and vim.api.nvim_buf_get_lines(buf, call.label_line - 1, call.label_line, false)[1] or '',
    }
  ]])

  local call_info = child.lua_get("_G.call_info")

  eq(call_info.has_diff, true)
  eq(call_info.label_line > 0, true)

  -- Default collapsed label
  eq(call_info.label_text, "+ view diff")

  -- Header should mention the summary
  local has_summary = child.lua_get("string.find(..., 'Test Tool', 1, true) ~= nil", { call_info.header_text })
  eq(has_summary, true)

  -- Toggle on the diff label line should expand/collapse only the diff block
  child.lua([[
    local Sidebar = _G.Sidebar
    local call = Sidebar._tool_calls[1]
    local chat = Sidebar.containers.chat

    vim.api.nvim_win_set_cursor(chat.winid, { call.label_line, 0 })
    Sidebar:_toggle_tool_call_at_cursor() -- expand diff
  ]])

  flush(50)

  child.lua([[
    local Sidebar = _G.Sidebar
    local call = Sidebar._tool_calls[1]
    local buf = Sidebar.containers.chat.bufnr
    local first_diff = vim.api.nvim_buf_get_lines(buf, call.label_line, call.label_line + 1, false)[1] or ''
    _G.expanded_info = {
      diff_expanded = call.diff_expanded,
      first_diff = first_diff,
    }
  ]])

  local expanded = child.lua_get("_G.expanded_info")

  eq(expanded.diff_expanded, true)
  eq(expanded.first_diff, "```diff")

  -- Collapse again
  child.lua([[
    local Sidebar = _G.Sidebar
    local call = Sidebar._tool_calls[1]
    local chat = Sidebar.containers.chat

    vim.api.nvim_win_set_cursor(chat.winid, { call.label_line, 0 })
    Sidebar:_toggle_tool_call_at_cursor() -- collapse diff
  ]])

  flush(50)

  local collapsed = child.lua_get("_G.Sidebar._tool_calls[1].diff_expanded")
  eq(collapsed, false)
end

T["reasoning blocks"] = MiniTest.new_set()

T["reasoning blocks"]["stream reasoning and toggle body"] = function()
  child.lua([[
    local Sidebar = _G.Sidebar

    Sidebar:handle_chat_content_received({
      chatId = 'chat-r',
      content = { type = 'reasonStarted', id = 'r1' },
    })

    Sidebar:handle_chat_content_received({
      chatId = 'chat-r',
      content = { type = 'reasonText', id = 'r1', text = 'First line.\nSecond line.' },
    })

    Sidebar:handle_chat_content_received({
      chatId = 'chat-r',
      content = { type = 'reasonFinished', id = 'r1', totalTimeMs = 1234 },
    })
  ]])

  flush(100)

  child.lua([[
    local Sidebar = _G.Sidebar
    local call = Sidebar._reasons['r1']
    local buf = Sidebar.containers.chat.bufnr
    local header = call and vim.api.nvim_buf_get_lines(buf, call.header_line - 1, call.header_line, false)[1] or ''
    _G.reason_info = {
      has_reason = call ~= nil,
      header_line = call and call.header_line or 0,
      header = header,
    }
  ]])

  local info = child.lua_get("_G.reason_info")

  eq(info.has_reason, true)

  -- Header should contain the finished label and elapsed time
  local has_thought = child.lua_get("string.find(..., 'Thought', 1, true) ~= nil", { info.header })
  eq(has_thought, true)

  local has_secs = child.lua_get("string.find(..., 's', 1, true) ~= nil", { info.header })
  eq(has_secs, true)

  -- Toggle body via header line
  child.lua([[
    local Sidebar = _G.Sidebar
    local call = Sidebar._reasons['r1']
    local chat = Sidebar.containers.chat
    vim.api.nvim_win_set_cursor(chat.winid, { call.header_line, 0 })
    Sidebar:_toggle_tool_call_at_cursor()
  ]])

  flush(80)

  child.lua([[
    local Sidebar = _G.Sidebar
    local call = Sidebar._reasons['r1']
    local buf = Sidebar.containers.chat.bufnr
    local first = vim.api.nvim_buf_get_lines(buf, call.header_line, call.header_line + 1, false)[1] or ''
    _G.reason_body = {
      expanded = call.expanded,
      first = first,
    }
  ]])

  local body = child.lua_get("_G.reason_body")

  eq(body.expanded, true)
  local has_first_line = child.lua_get("string.find(..., 'First line.', 1, true) ~= nil", { body.first })
  eq(has_first_line, true)
end

T["replace_text"] = MiniTest.new_set()

T["replace_text"]["supports multi-line replacement"] = function()
  child.lua([[
    local Sidebar = _G.Sidebar
    local chat = Sidebar.containers.chat

    vim.api.nvim_buf_set_lines(chat.bufnr, 0, -1, false, {
      'prefix TARGET suffix',
      'other line',
    })

    _G.changed = Sidebar:_replace_text('TARGET', 'foo\nbar')
    _G.lines = vim.api.nvim_buf_get_lines(chat.bufnr, 0, -1, false)
  ]])

  local changed = child.lua_get("_G.changed")
  eq(changed, true)

  local lines = child.lua_get("_G.lines")
  eq(lines[1], "prefix foo")
  eq(lines[2], "bar suffix")
  eq(lines[3], "other line")
end

T["tool call config"] = MiniTest.new_set()

T["tool call config"]["respects windows.chat.tool_call.diff labels and expanded flag"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          tool_call = {
            diff = {
              collapsed_label = '[open diff]',
              expanded_label = '[close diff]',
              expanded = true,
            },
          },
        },
      },
    })

    local Sidebar = _G.Sidebar

    Sidebar:handle_chat_content_received({
      chatId = 'chat-cfg',
      content = {
        type = 'toolCallPrepare',
        id = 'cfg-tool',
        name = 'cfg_tool',
        summary = 'Config Tool',
        argumentsText = '{"foo": 1}',
        details = {},
      },
    })

    Sidebar:handle_chat_content_received({
      chatId = 'chat-cfg',
      content = {
        type = 'toolCallRunning',
        id = 'cfg-tool',
      },
    })

    Sidebar:handle_chat_content_received({
      chatId = 'chat-cfg',
      content = {
        type = 'toolCalled',
        id = 'cfg-tool',
        name = 'cfg_tool',
        summary = 'Config Tool',
        details = { diff = '+x\n-y' },
      },
    })
  ]])

  flush(100)

  child.lua([[
    local Sidebar = _G.Sidebar
    local call = Sidebar._tool_calls[1]
    local buf = Sidebar.containers.chat.bufnr
    _G.cfg_call = {
      label_line = call and call.label_line or 0,
      label_text = call and vim.api.nvim_buf_get_lines(buf, call.label_line - 1, call.label_line, false)[1] or '',
      diff_expanded = call and call.diff_expanded or false,
      first_diff = call and vim.api.nvim_buf_get_lines(buf, call.label_line, call.label_line + 1, false)[1] or '',
    }
  ]])

  local cfg = child.lua_get("_G.cfg_call")

  eq(cfg.label_text, "[close diff]")
  eq(cfg.diff_expanded, true)
  eq(cfg.first_diff, "```diff")
end

T["reasoning blocks"]["use configured labels"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          reasoning = {
            running_label = 'Working...',
            finished_label = 'Plan',
          },
        },
      },
    })

    local Sidebar = _G.Sidebar

    Sidebar:handle_chat_content_received({
      chatId = 'chat-r2',
      content = { type = 'reasonStarted', id = 'r2' },
    })

    Sidebar:handle_chat_content_received({
      chatId = 'chat-r2',
      content = { type = 'reasonFinished', id = 'r2', totalTimeMs = 500 },
    })
  ]])

  flush(80)

  child.lua([[
    local Sidebar = _G.Sidebar
    local call = Sidebar._reasons['r2']
    local buf = Sidebar.containers.chat.bufnr
    _G.reason_cfg = {
      header = call and vim.api.nvim_buf_get_lines(buf, call.header_line - 1, call.header_line, false)[1] or '',
    }
  ]])

  local rcfg = child.lua_get("_G.reason_cfg")

  local has_plan = child.lua_get("string.find(..., 'Plan', 1, true) ~= nil", { rcfg.header })
  eq(has_plan, true)
end

T["reasoning blocks"]["start expanded when configured"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          reasoning = {
            expanded = true,
          },
        },
      },
    })

    local Sidebar = _G.Sidebar

    Sidebar:handle_chat_content_received({
      chatId = 'chat-r3',
      content = { type = 'reasonStarted', id = 'r3' },
    })

    Sidebar:handle_chat_content_received({
      chatId = 'chat-r3',
      content = { type = 'reasonText', id = 'r3', text = 'First line.' },
    })
  ]])

  flush(80)

  child.lua([[
    local Sidebar = _G.Sidebar
    local call = Sidebar._reasons['r3']
    local buf = Sidebar.containers.chat.bufnr
    _G.reason_expanded = {
      expanded = call and call.expanded or false,
      first = call and vim.api.nvim_buf_get_lines(buf, call.header_line, call.header_line + 1, false)[1] or '',
    }
  ]])

  local r = child.lua_get("_G.reason_expanded")

  eq(r.expanded, true)
  local has_first = child.lua_get("string.find(..., 'First line.', 1, true) ~= nil", { r.first })
  eq(has_first, true)
end

T["reasoning blocks"]["hide arrow until there is body text"] = function()
  child.lua([[
    local Sidebar = _G.Sidebar

    Sidebar:handle_chat_content_received({
      chatId = 'chat-r0',
      content = { type = 'reasonStarted', id = 'r0' },
    })
  ]])

  flush(50)

  child.lua([[
    local Sidebar = _G.Sidebar
    local call = Sidebar._reasons['r0']
    local buf = Sidebar.containers.chat.bufnr
    _G.reason_header = call and vim.api.nvim_buf_get_lines(buf, call.header_line - 1, call.header_line, false)[1] or ''
  ]])

  local header = child.lua_get("_G.reason_header")

  -- With no streamed reasoning text yet, the header should not show
  -- the expand/collapse arrow icon.
  local has_arrow = child.lua_get("string.find(..., '▶', 1, true) ~= nil", { header })
  eq(has_arrow, false)
end

T["mcps display"] = MiniTest.new_set()

T["mcps display"]["shows active and registered counts with highlights"] = function()
  child.lua([[
    local Sidebar = _G.Sidebar
    local Mediator = _G.Mediator

    function Mediator:selected_model() return 'gpt' end
    function Mediator:selected_behavior() return 'default' end

    function Mediator:mcps()
      return {
        a = { status = 'starting' },
        b = { status = 'running' },
        c = { status = 'failed' },
      }
    end

    Sidebar:_update_config_display()
  ]])

  child.lua([[
    local Sidebar = _G.Sidebar
    local buf = Sidebar.containers.config.bufnr
    local ns = Sidebar.extmarks.config._ns
    local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
    local virt = marks[1][4].virt_text
    _G.mcps_info = {
      active_text = virt[8][1],
      active_hl = virt[8][2],
      registered_text = virt[10][1],
      registered_hl = virt[10][2],
    }
  ]])

  local info = child.lua_get("_G.mcps_info")

  eq(info.active_text, "2") -- starting + running
  eq(info.active_hl, "EcaLabel")
  eq(info.registered_text, "3")
  eq(info.registered_hl, "Exception")
end

T["tool call summaries"] = MiniTest.new_set()

T["tool call summaries"]["appends filename for fileChange details"] = function()
  child.lua([[
    local Sidebar = _G.Sidebar

    -- Simulate a tool call lifecycle that reports a file change
    Sidebar:handle_chat_content_received({
      chatId = 'chat-file',
      content = {
        type = 'toolCallPrepare',
        id = 'tool-file',
        name = 'write_file',
        summary = 'Apply edit',
        argumentsText = '{"value": 1}',
        details = {},
      },
    })

    Sidebar:handle_chat_content_received({
      chatId = 'chat-file',
      content = {
        type = 'toolCallRunning',
        id = 'tool-file',
      },
    })

    Sidebar:handle_chat_content_received({
      chatId = 'chat-file',
      content = {
        type = 'toolCalled',
        id = 'tool-file',
        name = 'write_file',
        summary = 'Apply edit',
        details = { type = 'fileChange', path = '/tmp/example/foo.lua', diff = '+added' },
      },
    })
  ]])

  flush(100)

  child.lua([[
    local Sidebar = _G.Sidebar
    local call = Sidebar._tool_calls[1]
    local buf = Sidebar.containers.chat.bufnr
    _G.file_summary = {
      header = call and vim.api.nvim_buf_get_lines(buf, call.header_line - 1, call.header_line, false)[1] or '',
    }
  ]])

  local info = child.lua_get("_G.file_summary")

  -- Header should mention the basename of the changed file
  local has_filename = child.lua_get("string.find(..., 'foo.lua', 1, true) ~= nil", { info.header })
  eq(has_filename, true)
end

return T
