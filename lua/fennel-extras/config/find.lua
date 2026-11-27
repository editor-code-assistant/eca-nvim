-- [nfnl] fnl/fennel-extras/config/find.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.config.find"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.config.find"]
end
local function join_path(dir, name)
  if (string.sub(dir, -1) == "/") then
    return (dir .. name)
  else
    return (dir .. "/" .. name)
  end
end
local function close_file(file)
  file:close()
  return true
end
local function exists_3f(path)
  local uv = ((vim and vim.loop) or (vim and vim.uv))
  if uv then
    return (nil ~= uv.fs_stat(path))
  else
    local file = io.open(path, "r")
    return ((file and close_file(file)) or false)
  end
end
local function git_marker_3f(dir)
  return (exists_3f(join_path(dir, ".git")) or exists_3f(join_path(join_path(dir, ".git"), "HEAD")))
end
local function parent_dir(dir)
  local trimmed
  if ((string.len(dir) > 1) and (string.sub(dir, -1) == "/")) then
    trimmed = string.sub(dir, 1, -2)
  else
    trimmed = dir
  end
  local parent = string.match(trimmed, "^(.*)/[^/]+$")
  if parent then
    if (parent == "") then
      return "/"
    else
      return parent
    end
  else
    return nil
  end
end
local function find_in(dir)
  local candidate = join_path(dir, ".fnl-extras.fnl")
  local or_6_ = (exists_3f(candidate) and candidate)
  if not or_6_ then
    if not git_marker_3f(dir) then
      local parent = parent_dir(dir)
      if parent then
        or_6_ = find_in(parent)
      else
        or_6_ = nil
      end
    else
      or_6_ = nil
    end
  end
  return or_6_
end
local find
do
  local function find0(start_dir)
    return find_in(start_dir)
  end
  _2amodule_2a["find"] = find0
  find = _2amodule_2a.find
end
return nil
