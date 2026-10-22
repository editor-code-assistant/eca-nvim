-- [nfnl] fnl/fennel-extras/cli/matcher.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.cli.matcher"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.cli.matcher"]
end
local function matches_pattern_3f(pattern, text)
  local regex = vim.regex(pattern)
  return (nil ~= regex:match_str(text))
end
local compile_pattern
do
  local function compile_pattern0(pattern)
    vim.regex(pattern)
    return true
  end
  _2amodule_2a["compile-pattern"] = compile_pattern0
  compile_pattern = _2amodule_2a["compile-pattern"]
end
local vim_matcher
do
  local function vim_matcher0()
    return matches_pattern_3f
  end
  _2amodule_2a["vim-matcher"] = vim_matcher0
  vim_matcher = _2amodule_2a["vim-matcher"]
end
return nil
