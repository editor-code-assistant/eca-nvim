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
