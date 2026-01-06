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

T["utils"] = MiniTest.new_set()

T["utils"]["shorten_tokens formats numbers correctly"] = function()
  child.lua([[
    local Utils = require('eca.utils')
    _G.results = {
      small = Utils.shorten_tokens(999),
      exact_k = Utils.shorten_tokens(1000),
      over_k = Utils.shorten_tokens(1500),
      large = Utils.shorten_tokens(42000),
      very_large = Utils.shorten_tokens(1234567),
      nil_input = Utils.shorten_tokens(nil),
      string_input = Utils.shorten_tokens("1500"),
    }
  ]])

  local results = child.lua_get("_G.results")

  eq(results.small, "999")
  eq(results.exact_k, "1k")
  eq(results.over_k, "2k") -- Rounds 1500 to 2k
  eq(results.large, "42k")
  eq(results.very_large, "1235k")
  eq(results.nil_input, "0")
  eq(results.string_input, "2k")
end

T["utils"]["get_chat_config merges legacy and new config"] = function()
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

T["utils"]["get_chat_config returns windows.chat when no legacy config"] = function()
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

T["utils"]["should_start_diff_expanded respects windows.chat.tool_call.diff.expanded"] = function()
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

T["utils"]["should_start_diff_expanded checks diff.expanded only"] = function()
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

T["utils"]["should_start_diff_expanded defaults to false"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({})

    local Utils = require('eca.utils')
    _G.should_expand = Utils.should_start_diff_expanded()
  ]])

  eq(child.lua_get("_G.should_expand"), false)
end

T["utils"]["split_lines handles various line endings"] = function()
  child.lua([[
    local Utils = require('eca.utils')
    _G.results = {
      unix = Utils.split_lines("line1\nline2\nline3"),
      empty = Utils.split_lines(""),
      single = Utils.split_lines("single"),
      trailing = Utils.split_lines("line1\nline2\n"),
    }
  ]])

  local results = child.lua_get("_G.results")

  eq(#results.unix, 3)
  eq(results.unix[1], "line1")
  eq(results.unix[2], "line2")
  eq(results.unix[3], "line3")

  eq(#results.empty, 1)
  eq(results.empty[1], "")

  eq(#results.single, 1)
  eq(results.single[1], "single")

  -- Trailing newline should create an empty last line
  eq(#results.trailing, 3)
  eq(results.trailing[3], "")
end

return T
