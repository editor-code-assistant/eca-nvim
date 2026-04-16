local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
    end,
    post_once = child.stop,
  },
})

-- ===== Chat config merging tests =====

T["chat_config"] = MiniTest.new_set()

T["chat_config"]["get_chat_config merges legacy and new config"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      chat = {
        headers = {
          user = "OLD> ",
        },
      },
      windows = {
        chat = {
          headers = {
            user = "NEW> ",
            assistant = "AI: ",
          },
        },
      },
    })

    local Utils = require('eca.utils')
    local merged = Utils.get_chat_config()
    _G.merged_config = {
      user_header = merged.headers and merged.headers.user or nil,
      assistant_header = merged.headers and merged.headers.assistant or nil,
    }
  ]])

  local merged = child.lua_get("_G.merged_config")

  -- Legacy chat.headers overrides windows.chat.headers via deep_extend
  eq(merged.user_header, "OLD> ")
  eq(merged.assistant_header, "AI: ")
end

T["chat_config"]["get_chat_config returns windows.chat when no legacy config"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          headers = {
            user = "> ",
            assistant = "",
          },
        },
      },
    })

    local Utils = require('eca.utils')
    local merged = Utils.get_chat_config()
    _G.merged_config = {
      user_header = merged.headers and merged.headers.user or nil,
      assistant_header = merged.headers and merged.headers.assistant or nil,
    }
  ]])

  local merged = child.lua_get("_G.merged_config")

  eq(merged.user_header, "> ")
  eq(merged.assistant_header, "")
end

-- ===== Diff expansion config tests =====

T["diff_config"] = MiniTest.new_set()

T["diff_config"]["should_start_diff_expanded respects windows.chat.tool_call.diff.expanded"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          tool_call = {
            diff = {
              expanded = true,
            },
          },
        },
      },
    })

    local Utils = require('eca.utils')
    _G.should_expand = Utils.should_start_diff_expanded()
  ]])

  eq(child.lua_get("_G.should_expand"), true)
end

T["diff_config"]["should_start_diff_expanded checks diff.expanded only"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          tool_call = {
            diff = {
              expanded = false,
            },
          },
        },
      },
    })

    local Utils = require('eca.utils')
    _G.should_expand = Utils.should_start_diff_expanded()
  ]])

  eq(child.lua_get("_G.should_expand"), false)
end

T["diff_config"]["should_start_diff_expanded defaults to false"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({})

    local Utils = require('eca.utils')
    _G.should_expand = Utils.should_start_diff_expanded()
  ]])

  eq(child.lua_get("_G.should_expand"), false)
end

-- ===== Preserve cursor config tests =====

T["preserve_cursor_config"] = MiniTest.new_set()

T["preserve_cursor_config"]["should_preserve_cursor returns true when enabled"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          tool_call = {
            preserve_cursor = true,
          },
        },
      },
    })

    local Utils = require('eca.utils')
    _G.preserve = Utils.should_preserve_cursor()
  ]])

  eq(child.lua_get("_G.preserve"), true)
end

T["preserve_cursor_config"]["should_preserve_cursor returns false when disabled"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          tool_call = {
            preserve_cursor = false,
          },
        },
      },
    })

    local Utils = require('eca.utils')
    _G.preserve = Utils.should_preserve_cursor()
  ]])

  eq(child.lua_get("_G.preserve"), false)
end

T["preserve_cursor_config"]["should_preserve_cursor defaults to true"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({})

    local Utils = require('eca.utils')
    _G.preserve = Utils.should_preserve_cursor()
  ]])

  eq(child.lua_get("_G.preserve"), true)
end

T["preserve_cursor_config"]["should_preserve_cursor respects legacy chat.tool_call config"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      chat = {
        tool_call = {
          preserve_cursor = true,
        },
      },
    })

    local Utils = require('eca.utils')
    _G.preserve = Utils.should_preserve_cursor()
  ]])

  eq(child.lua_get("_G.preserve"), true)
end

T["preserve_cursor_config"]["should_preserve_cursor merges windows.chat and chat config"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          tool_call = {
            preserve_cursor = false,
          },
        },
      },
      chat = {
        tool_call = {
          preserve_cursor = true,
        },
      },
    })

    local Utils = require('eca.utils')
    _G.preserve = Utils.should_preserve_cursor()
  ]])

  -- Legacy chat config should override windows.chat via deep_extend
  eq(child.lua_get("_G.preserve"), true)
end

-- ===== Behavioral validation tests =====
-- These tests verify that config changes actually affect sidebar behavior

T["behavior_validation"] = MiniTest.new_set()

T["behavior_validation"]["preserve_cursor=true actually preserves cursor position on expand"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          tool_call = {
            preserve_cursor = true,
          },
        },
      },
    })

    local Server = require('eca.server').new()
    local State = require('eca.state').new()
    local Mediator = require('eca.mediator').new(Server, State)
    local Sidebar = require('eca.sidebar')
    local sidebar = Sidebar.new(1, Mediator)

    sidebar:open()

    local chat = sidebar.containers.chat
    vim.api.nvim_buf_set_lines(chat.bufnr, 0, -1, false, {
      "Line 1",
      "Line 2",
      "Line 3",
      "Line 4",
      "Line 5",
    })

    sidebar._tool_calls = {
      {
        id = "test-id",
        title = "Test",
        header_line = 2,
        expanded = false,
        arguments = "{}",
        arguments_lines = {"arg1", "arg2"},
        details = {},
        has_diff = false,
      }
    }

    vim.api.nvim_win_set_cursor(chat.winid, {5, 0})
    sidebar:_expand_tool_call(sidebar._tool_calls[1])

    local cursor = vim.api.nvim_win_get_cursor(chat.winid)
    _G.cursor_after = cursor[1]
    _G.expected = 7  -- Line 5 + 2 inserted lines
  ]])

  eq(child.lua_get("_G.cursor_after"), child.lua_get("_G.expected"))
end

T["behavior_validation"]["preserve_cursor=false moves cursor to end on expand"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          tool_call = {
            preserve_cursor = false,
          },
        },
      },
    })

    local Server = require('eca.server').new()
    local State = require('eca.state').new()
    local Mediator = require('eca.mediator').new(Server, State)
    local Sidebar = require('eca.sidebar')
    local sidebar = Sidebar.new(1, Mediator)

    sidebar:open()

    local chat = sidebar.containers.chat
    vim.api.nvim_buf_set_lines(chat.bufnr, 0, -1, false, {
      "Line 1",
      "Line 2",
      "Line 3",
      "Line 4",
    })

    sidebar._tool_calls = {
      {
        id = "test-id",
        title = "Test",
        header_line = 2,
        expanded = false,
        arguments = "{}",
        arguments_lines = {"arg1", "arg2"},
        details = {},
        has_diff = false,
      }
    }

    vim.api.nvim_win_set_cursor(chat.winid, {1, 0})
    sidebar:_expand_tool_call(sidebar._tool_calls[1])

    local cursor = vim.api.nvim_win_get_cursor(chat.winid)
    _G.cursor_after = cursor[1]
    _G.expected = 4  -- header_line (2) + arguments_lines count (2)
  ]])

  eq(child.lua_get("_G.cursor_after"), child.lua_get("_G.expected"))
end

T["behavior_validation"]["diff.expanded=true causes diffs to start expanded"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          tool_call = {
            diff = {
              expanded = true,
            },
          },
        },
      },
    })

    local Server = require('eca.server').new()
    local State = require('eca.state').new()
    local Mediator = require('eca.mediator').new(Server, State)
    local Sidebar = require('eca.sidebar')
    local sidebar = Sidebar.new(1, Mediator)

    sidebar:open()

    local chat = sidebar.containers.chat
    vim.api.nvim_buf_set_lines(chat.bufnr, 0, -1, false, {"Line 1"})

    -- Simulate a tool call with diff that should auto-expand
    sidebar:handle_chat_content_received({
      chatId = 'test',
      content = {
        type = 'toolCallPrepare',
        id = 'tool-1',
        name = 'test_tool',
        summary = 'Test',
        argumentsText = '{}',
        details = {
          diff = '@@ -1 +1 @@\n-old\n+new',
        },
      },
    })

    sidebar:handle_chat_content_received({
      chatId = 'test',
      content = {
        type = 'toolCalled',
        id = 'tool-1',
        name = 'test_tool',
        details = {
          diff = '@@ -1 +1 @@\n-old\n+new',
        },
        outputs = {},
      },
    })

    -- Find the tool call and check if diff is expanded
    local call = sidebar._tool_calls[1]
    _G.diff_expanded = call and call.diff_expanded or false
  ]])

  eq(child.lua_get("_G.diff_expanded"), true)
end

T["behavior_validation"]["diff.expanded=false causes diffs to start collapsed"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          tool_call = {
            diff = {
              expanded = false,
            },
          },
        },
      },
    })

    local Server = require('eca.server').new()
    local State = require('eca.state').new()
    local Mediator = require('eca.mediator').new(Server, State)
    local Sidebar = require('eca.sidebar')
    local sidebar = Sidebar.new(1, Mediator)

    sidebar:open()

    local chat = sidebar.containers.chat
    vim.api.nvim_buf_set_lines(chat.bufnr, 0, -1, false, {"Line 1"})

    -- Simulate a tool call with diff that should NOT auto-expand
    sidebar:handle_chat_content_received({
      chatId = 'test',
      content = {
        type = 'toolCallPrepare',
        id = 'tool-1',
        name = 'test_tool',
        summary = 'Test',
        argumentsText = '{}',
        details = {
          diff = '@@ -1 +1 @@\n-old\n+new',
        },
      },
    })

    sidebar:handle_chat_content_received({
      chatId = 'test',
      content = {
        type = 'toolCalled',
        id = 'tool-1',
        name = 'test_tool',
        details = {
          diff = '@@ -1 +1 @@\n-old\n+new',
        },
        outputs = {},
      },
    })

    -- Find the tool call and check if diff is collapsed
    local call = sidebar._tool_calls[1]
    _G.diff_expanded = call and call.diff_expanded or false
  ]])

  eq(child.lua_get("_G.diff_expanded"), false)
end

T["behavior_validation"]["reasoning.expanded=true causes reasoning to start expanded"] = function()
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

    local Server = require('eca.server').new()
    local State = require('eca.state').new()
    local Mediator = require('eca.mediator').new(Server, State)
    local Sidebar = require('eca.sidebar')
    local sidebar = Sidebar.new(1, Mediator)

    sidebar:open()

    -- Simulate reasoning started event
    sidebar:handle_chat_content_received({
      chatId = 'test',
      content = {
        type = 'reasonStarted',
        id = 'reason-1',
      },
    })

    -- Check if reasoning block started expanded
    local call = sidebar._reasons['reason-1']
    _G.expanded = call and call.expanded or false
  ]])

  eq(child.lua_get("_G.expanded"), true)
end

T["behavior_validation"]["reasoning.expanded=false causes reasoning to start collapsed"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          reasoning = {
            expanded = false,
          },
        },
      },
    })

    local Server = require('eca.server').new()
    local State = require('eca.state').new()
    local Mediator = require('eca.mediator').new(Server, State)
    local Sidebar = require('eca.sidebar')
    local sidebar = Sidebar.new(1, Mediator)

    sidebar:open()

    -- Simulate reasoning started event
    sidebar:handle_chat_content_received({
      chatId = 'test',
      content = {
        type = 'reasonStarted',
        id = 'reason-1',
      },
    })

    -- Check if reasoning block started collapsed
    local call = sidebar._reasons['reason-1']
    _G.expanded = call and call.expanded or false
  ]])

  eq(child.lua_get("_G.expanded"), false)
end

T["behavior_validation"]["typing.enabled=false displays text instantly"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          typing = {
            enabled = false,
          },
        },
      },
    })

    local Server = require('eca.server').new()
    local State = require('eca.state').new()
    local Mediator = require('eca.mediator').new(Server, State)
    local Sidebar = require('eca.sidebar')
    local sidebar = Sidebar.new(1, Mediator)

    -- Check that stream queue was configured for instant display
    local queue = sidebar._stream_queue
    _G.chars_per_tick = queue.chars_per_tick
    -- When typing is disabled, chars_per_tick should be a large number (instant)
    _G.is_instant = _G.chars_per_tick >= 1000
  ]])

  eq(child.lua_get("_G.is_instant"), true)
end

T["behavior_validation"]["typing.enabled=true enables gradual display"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          typing = {
            enabled = true,
            chars_per_tick = 2,
            tick_delay = 5,
          },
        },
      },
    })

    local Server = require('eca.server').new()
    local State = require('eca.state').new()
    local Mediator = require('eca.mediator').new(Server, State)
    local Sidebar = require('eca.sidebar')
    local sidebar = Sidebar.new(1, Mediator)

    -- Check that stream queue was configured with custom values
    local queue = sidebar._stream_queue
    _G.chars_per_tick = queue.chars_per_tick
    _G.tick_delay = queue.tick_delay
  ]])

  eq(child.lua_get("_G.chars_per_tick"), 2)
  eq(child.lua_get("_G.tick_delay"), 5)
end

-- ===== Mappings tests =====

T["mappings"] = MiniTest.new_set()

T["mappings"]["submit defaults bind <CR> in normal and <C-s> in insert"] = function()
  child.lua([[
    local Server = require('eca.server').new()
    local State = require('eca.state').new()
    local Mediator = require('eca.mediator').new(Server, State)
    local Sidebar = require('eca.sidebar')
    local sidebar = Sidebar.new(1, Mediator)

    sidebar:open()

    local input_bufnr = sidebar.containers.input.bufnr

    -- Normalize a key string the same way nvim does internally for keymaps
    local function norm(k)
      return vim.api.nvim_replace_termcodes(k, true, true, true)
    end
    local function has_mapping(mode, key)
      local target = norm(key)
      for _, m in ipairs(vim.api.nvim_buf_get_keymap(input_bufnr, mode)) do
        if norm(m.lhs) == target then
          return true
        end
      end
      return false
    end

    _G.has_normal_cr = has_mapping("n", "<CR>")
    _G.has_insert_cs = has_mapping("i", "<C-s>")
  ]])

  eq(child.lua_get("_G.has_normal_cr"), true)
  eq(child.lua_get("_G.has_insert_cs"), true)
end

T["mappings"]["submit partial override preserves other mode default"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      mappings = {
        submit = {
          insert = "<C-x>",
        },
      },
    })

    local Server = require('eca.server').new()
    local State = require('eca.state').new()
    local Mediator = require('eca.mediator').new(Server, State)
    local Sidebar = require('eca.sidebar')
    local sidebar = Sidebar.new(1, Mediator)

    sidebar:open()

    local input_bufnr = sidebar.containers.input.bufnr

    local function norm(k)
      return vim.api.nvim_replace_termcodes(k, true, true, true)
    end
    local function has_mapping(mode, key)
      local target = norm(key)
      for _, m in ipairs(vim.api.nvim_buf_get_keymap(input_bufnr, mode)) do
        if norm(m.lhs) == target then
          return true
        end
      end
      return false
    end

    _G.has_normal_cr = has_mapping("n", "<CR>")        -- default preserved
    _G.has_insert_cx = has_mapping("i", "<C-x>")       -- override applied
    _G.has_insert_cs = has_mapping("i", "<C-s>")       -- old default unbound
  ]])

  eq(child.lua_get("_G.has_normal_cr"), true)
  eq(child.lua_get("_G.has_insert_cx"), true)
  eq(child.lua_get("_G.has_insert_cs"), false)
end

T["mappings"]["submit full override binds both modes"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      mappings = {
        submit = {
          normal = "<C-y>",
          insert = "<C-x>",
        },
      },
    })

    local Server = require('eca.server').new()
    local State = require('eca.state').new()
    local Mediator = require('eca.mediator').new(Server, State)
    local Sidebar = require('eca.sidebar')
    local sidebar = Sidebar.new(1, Mediator)

    sidebar:open()

    local input_bufnr = sidebar.containers.input.bufnr

    local function norm(k)
      return vim.api.nvim_replace_termcodes(k, true, true, true)
    end
    local function has_mapping(mode, key)
      local target = norm(key)
      for _, m in ipairs(vim.api.nvim_buf_get_keymap(input_bufnr, mode)) do
        if norm(m.lhs) == target then
          return true
        end
      end
      return false
    end

    _G.has_normal_cy = has_mapping("n", "<C-y>")
    _G.has_insert_cx = has_mapping("i", "<C-x>")
    _G.has_normal_cr = has_mapping("n", "<CR>")
  ]])

  eq(child.lua_get("_G.has_normal_cy"), true)
  eq(child.lua_get("_G.has_insert_cx"), true)
  eq(child.lua_get("_G.has_normal_cr"), false)
end

T["mappings"]["welcome tip substitutes submit key placeholders"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      mappings = {
        submit = {
          normal = "<C-y>",
          insert = "<C-x>",
        },
      },
      windows = {
        chat = {
          welcome = {
            tips = {
              "normal={submit_key_normal} insert={submit_key_insert} unknown={nope}",
            },
          },
        },
      },
    })

    local Server = require('eca.server').new()
    local State = require('eca.state').new()
    local Mediator = require('eca.mediator').new(Server, State)
    -- Force a non-empty welcome_message so the tips branch runs
    function Mediator:welcome_message() return "welcome" end

    local Sidebar = require('eca.sidebar')
    local sidebar = Sidebar.new(1, Mediator)
    sidebar:open()
    sidebar:_update_welcome_content()

    local chat_bufnr = sidebar.containers.chat.bufnr
    local lines = vim.api.nvim_buf_get_lines(chat_bufnr, 0, -1, false)
    _G.lines = lines
  ]])

  local lines = child.lua_get("_G.lines")
  local found = false
  for _, line in ipairs(lines) do
    if line == "normal=<C-y> insert=<C-x> unknown={nope}" then
      found = true
      break
    end
  end
  eq(found, true)
end

return T
