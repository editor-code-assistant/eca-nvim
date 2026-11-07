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
local function normalized_base(base)
  if ((base == "") or (base == ".")) then
    return ""
  else
    return base
  end
end
local function base_prefix(base)
  if (base == "") then
    return ""
  else
    return (base .. "/")
  end
end
local function workspace_relative_path(base, path)
  local base0 = normalized_base(base)
  local prefix = base_prefix(base0)
  local starts = ((base0 ~= "") and (string.sub(path, 1, string.len(prefix)) == prefix))
  return (((base0 == "") and path) or ((path == base0) and "") or (starts and string.sub(path, (string.len(prefix) + 1))))
end
local function path_match_3f(pattern, path, base)
  local relative = workspace_relative_path(base, path)
  return (matches_pattern_3f(pattern, path) or (relative and matches_pattern_3f(pattern, relative)))
end
local function path_match_step(paths, pattern, path, index)
  if (index > #paths) then
    return false
  else
    return (path_match_3f(pattern, path, paths[index]) or path_match_step(paths, pattern, path, (index + 1)))
  end
end
local vim_path_matcher
do
  local function vim_path_matcher0(workspace_paths)
    local paths = (workspace_paths or {})
    local function _4_(pattern, path)
      return path_match_step(paths, pattern, path, 1)
    end
    return _4_
  end
  _2amodule_2a["vim-path-matcher"] = vim_path_matcher0
  vim_path_matcher = _2amodule_2a["vim-path-matcher"]
end
return nil
