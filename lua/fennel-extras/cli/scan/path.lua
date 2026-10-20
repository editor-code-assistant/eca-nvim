-- [nfnl] fnl/fennel-extras/cli/scan/path.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.cli.scan.path"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.cli.scan.path"]
end
local cwd
do
  local function cwd0()
    return ((vim and vim.loop and vim.loop.cwd()) or (vim and vim.uv and vim.uv.cwd()) or ".")
  end
  _2amodule_2a["cwd"] = cwd0
  cwd = _2amodule_2a.cwd
end
local function join_with_slash(left, right)
  if (string.sub(left, -1) == "/") then
    return (left .. right)
  else
    return (left .. "/" .. right)
  end
end
local join
do
  local function join0(left, right)
    if (left == "/") then
      return (left .. right)
    else
      return join_with_slash(left, right)
    end
  end
  _2amodule_2a["join"] = join0
  join = _2amodule_2a.join
end
local absolute
do
  local function absolute0(root, path)
    if (string.sub(path, 1, 1) == "/") then
      return path
    else
      return join(root, path)
    end
  end
  _2amodule_2a["absolute"] = absolute0
  absolute = _2amodule_2a.absolute
end
local function strip_private_prefix(path)
  if (string.sub(path, 1, 9) == "/private/") then
    return string.sub(path, 9)
  else
    return path
  end
end
local function ensure_trailing_slash(root)
  if (string.sub(root, -1) == "/") then
    return root
  else
    return (root .. "/")
  end
end
local function strip_relative_prefix(result)
  if (string.sub(result, 1, 2) == "./") then
    return string.sub(result, 3)
  else
    return result
  end
end
local function relative_result(path, prefix)
  if (string.sub(path, 1, string.len(prefix)) == prefix) then
    return string.sub(path, (string.len(prefix) + 1))
  else
    return path
  end
end
local relative
do
  local function relative0(root, path)
    local root0 = strip_private_prefix(root)
    local path0 = strip_private_prefix(path)
    local prefix = ensure_trailing_slash(root0)
    local result = relative_result(path0, prefix)
    return strip_relative_prefix(result)
  end
  _2amodule_2a["relative"] = relative0
  relative = _2amodule_2a.relative
end
local function extension_matches_3f(path, extension)
  return (string.sub(path, ( - string.len(extension))) == extension)
end
local fnl_file_3f
do
  local function fnl_file_3f0(path, extensions)
    local result = false
    for _, extension in ipairs(extensions) do
      result = (result or extension_matches_3f(path, extension))
    end
    return result
  end
  _2amodule_2a["fnl-file?"] = fnl_file_3f0
  fnl_file_3f = _2amodule_2a["fnl-file?"]
end
local function clean_prefix(prefix)
  if (string.sub(prefix, -1) == "/") then
    return string.sub(prefix, 1, -2)
  else
    return prefix
  end
end
local function under_prefix_3f(path, prefix)
  local clean = clean_prefix(prefix)
  return ((path == clean) or (string.sub(path, 1, (string.len(clean) + 1)) == (clean .. "/")))
end
local function excluded_result(path, prefix, result)
  if under_prefix_3f(path, prefix) then
    return true
  else
    return result
  end
end
local function excluded_any_3f(path, excludes, index, result)
  if (index > #excludes) then
    return result
  else
    return excluded_any_3f(path, excludes, (index + 1), excluded_result(path, excludes[index], result))
  end
end
local excluded_3f
do
  local function excluded_3f0(path, excludes)
    return excluded_any_3f(path, excludes, 1, under_prefix_3f(path, ".git"))
  end
  _2amodule_2a["excluded?"] = excluded_3f0
  excluded_3f = _2amodule_2a["excluded?"]
end
local hidden_3f
do
  local function hidden_3f0(name)
    return (string.sub(name, 1, 1) == ".")
  end
  _2amodule_2a["hidden?"] = hidden_3f0
  hidden_3f = _2amodule_2a["hidden?"]
end
local realpath
do
  local function realpath0(uv, path)
    local ok, resolved = pcall(uv.fs_realpath, path)
    if ok then
      return resolved
    else
      return nil
    end
  end
  _2amodule_2a["realpath"] = realpath0
  realpath = _2amodule_2a.realpath
end
local walk_prefix
do
  local function walk_prefix0(root, path)
    local rel = relative(root, path)
    if (rel == ".") then
      return ""
    else
      return rel
    end
  end
  _2amodule_2a["walk-prefix"] = walk_prefix0
  walk_prefix = _2amodule_2a["walk-prefix"]
end
return nil
