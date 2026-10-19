-- [nfnl] fnl/fennel-extras/cli/scan.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.cli.scan"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.cli.scan"]
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
local function join(left, right)
  if (left == "/") then
    return (left .. right)
  else
    return join_with_slash(left, right)
  end
end
local function absolute(root, path)
  if (string.sub(path, 1, 1) == "/") then
    return path
  else
    return join(root, path)
  end
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
local function matched_result(path, extension, result)
  if extension_matches_3f(path, extension) then
    return true
  else
    return result
  end
end
local function fnl_file_3f(path, extensions)
  local result = false
  for _, extension in ipairs(extensions) do
    result = (result or extension_matches_3f(path, extension))
  end
  return result
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
local function excluded_3f(path, excludes)
  return excluded_any_3f(path, excludes, 1, under_prefix_3f(path, ".git"))
end
local function hidden_3f(name)
  return (string.sub(name, 1, 1) == ".")
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
local function walk_prefix(root, path)
  local rel = relative(root, path)
  if (rel == ".") then
    return ""
  else
    return rel
  end
end
local function scan_acc(acc, result)
  return {result = result, seen = acc.seen, visited = acc.visited}
end
local function record_file(acc, path, rel, dedupe)
  acc.seen[dedupe] = true
  table.insert(acc.result, {relative = rel, absolute = path})
  return scan_acc(acc, acc.result)
end
local function add_file(ctx, acc, path, target)
  if (fnl_file_3f(target.rel, ctx.extensions) and not excluded_3f(target.rel, ctx.excludes) and not acc.seen[target.dedupe]) then
    return record_file(acc, path, target.rel, target.dedupe)
  else
    return scan_acc(acc, acc.result)
  end
end
local function walk_target(ctx, acc, entry)
  local visited = acc.visited
  local _
  visited[entry.path] = true
  _ = nil
  local target = {directory = entry.path, prefix = entry.rel, path = entry.path, rel = entry.rel, ["error-prefix"] = entry.rel}
  return ctx.walk(ctx, acc, target)
end
local function scan_directory_target(ctx, acc, entry, target_stat)
  if ((target_stat.type == "directory") and not excluded_3f(entry.rel, ctx.excludes) and not acc.visited[entry.path]) then
    return walk_target(ctx, acc, entry)
  else
    return scan_acc(acc, acc.result), nil
  end
end
local function scan_file_dedupe(ctx, entry, target)
  if ctx["follow-symlinks"] then
    return target
  else
    return relative(ctx.root, entry.path)
  end
end
local function add_scan_file(ctx, acc, entry, target)
  return add_file(ctx, acc, target, {rel = entry.rel, dedupe = scan_file_dedupe(ctx, entry, target)})
end
local function scan_file_target(ctx, acc, entry, target_stat)
  if (target_stat.type == "file") then
    return add_scan_file(ctx, acc, entry, entry.target)
  else
    return scan_acc(acc, acc.result)
  end
end
local function scan_entry_target_stat(ctx, target)
  local uv = ctx.uv
  return (target and uv.fs_stat(target))
end
local function scan_target_entry(entry, target)
  return {directory = entry.directory, prefix = entry.prefix, name = entry.name, type = entry.type, path = target, target = target, rel = entry.rel, ["error-prefix"] = entry["error-prefix"]}
end
local function scan_target_stat_result(ctx, acc, entry, target_stat)
  local case_18_ = target_stat.type
  if (case_18_ == "directory") then
    return scan_directory_target(ctx, acc, entry, target_stat)
  elseif (case_18_ == "file") then
    return scan_file_target(ctx, acc, entry, target_stat)
  else
    local _ = case_18_
    return scan_acc(acc, acc.result), nil
  end
end
local function scan_target_stat(ctx, acc, entry, target)
  local target_stat = scan_entry_target_stat(ctx, target)
  local target_entry = (target_stat and scan_target_entry(entry, target))
  if target_stat then
    return scan_target_stat_result(ctx, acc, target_entry, target_stat)
  else
    return scan_acc(acc, acc.result), nil
  end
end
local function scan_entry_target_path(ctx, entry)
  if (entry.type == "link") then
    return realpath(ctx.uv, entry.path)
  else
    return entry.path
  end
end
local function scan_entry_target(ctx, acc, entry)
  local target = scan_entry_target_path(ctx, entry)
  return scan_target_stat(ctx, acc, entry, target)
end
local function scan_entry_rel(prefix, name)
  if (prefix == "") then
    return name
  else
    return (prefix .. "/" .. name)
  end
end
local function scan_entry_eligible(ctx, acc, entry)
  local eligible = (((entry.type == "directory") and not (entry.name == ".git")) or (entry.type == "file") or (ctx["follow-symlinks"] and (entry.type == "link")))
  if eligible then
    return scan_entry_target(ctx, acc, entry)
  else
    return scan_acc(acc, acc.result), nil
  end
end
local function scan_entry_path(ctx, acc, entry)
  local path = join(entry.directory, entry.name)
  local rel = scan_entry_rel(entry.prefix, entry.name)
  local child = {directory = entry.directory, prefix = entry.prefix, name = entry.name, type = entry.type, path = path, rel = rel, ["error-prefix"] = entry["error-prefix"]}
  return scan_entry_eligible(ctx, acc, child)
end
local function scan_entry(ctx, acc, entry)
  if (ctx["skip-dotfiles"] and hidden_3f(entry.name)) then
    return scan_acc(acc, acc.result), nil
  else
    return scan_entry_path(ctx, acc, entry)
  end
end
local function scan_entry_data(entry, name, type)
  return {directory = entry.directory, prefix = entry.prefix, name = name, type = type, ["error-prefix"] = entry["error-prefix"]}
end
local function walk_scan_step_result(ctx, acc, entry, handle)
  local next_acc, error = scan_entry(ctx, acc, entry)
  if error then
    return nil, error
  else
    return ctx.step(ctx, next_acc, entry, handle)
  end
end
local function walk_scan_step(ctx, acc, entry, handle)
  local uv = ctx.uv
  local name, type = uv.fs_scandir_next(handle)
  if not name then
    return scan_acc(acc, acc.result), nil
  else
    return walk_scan_step_result(ctx, acc, scan_entry_data(entry, name, type), handle)
  end
end
local function walk_scan(ctx, acc, entry, handle)
  return walk_scan_step(ctx, acc, entry, handle)
end
local function walk_prefix_or_dot(prefix)
  if (prefix == "") then
    return "."
  else
    return prefix
  end
end
local function walk_error_prefix(error_prefix, prefix)
  if error_prefix then
    return error_prefix
  else
    return walk_prefix_or_dot(prefix)
  end
end
local function walk_scan_error(error_prefix, prefix)
  return nil, ("cannot read directory " .. walk_error_prefix(error_prefix, prefix))
end
local function walk(ctx, acc, entry)
  local uv = ctx.uv
  local handle, err = uv.fs_scandir(entry.directory)
  local error_prefix = (entry["error-prefix"] or ctx["error-prefix"])
  if not handle then
    return walk_scan_error(error_prefix, entry.prefix)
  else
    return walk_scan(ctx, acc, entry, handle)
  end
end
local function followed_link_entry(entry)
  return {directory = entry.target, prefix = entry.rel, path = entry.target, rel = entry.rel, ["error-prefix"] = entry["error-prefix"]}
end
local function followed_link_directory(ctx, acc, entry, target_stat)
  if (target_stat.type == "directory") then
    return walk(ctx, acc, followed_link_entry(entry))
  else
    return nil
  end
end
local function followed_link_result(ctx, acc, entry, target_stat)
  if (target_stat.type == "file") then
    return add_file(ctx, acc, entry.target, {rel = entry.rel, dedupe = entry.target})
  else
    return followed_link_directory(ctx, acc, entry, target_stat)
  end
end
local function add_followed_link(ctx, acc, entry)
  local uv = ctx.uv
  local target = realpath(uv, entry.path)
  local target_stat = (target and uv.fs_stat(target))
  local target_entry = (target_stat and scan_target_entry(entry, target))
  if target_stat then
    return followed_link_result(ctx, acc, target_entry, target_stat)
  else
    return scan_acc(acc, acc.result), nil
  end
end
local function directory_target(ctx, path)
  if ctx["follow-symlinks"] then
    return realpath(ctx.uv, path)
  else
    return path
  end
end
local function directory_visited(ctx, target)
  if ctx["follow-symlinks"] then
    return {[target] = true}
  else
    return {}
  end
end
local function add_directory_path(ctx, acc, entry)
  local target = directory_target(ctx, entry.path)
  local visited = directory_visited(ctx, target)
  local next_acc = {result = acc.result, seen = acc.seen, visited = visited}
  local directory_entry = {directory = target, prefix = walk_prefix(ctx.root, entry.path), path = target, rel = entry.rel, ["error-prefix"] = entry["error-prefix"]}
  return walk(ctx, next_acc, directory_entry)
end
local function add_path_link(ctx, acc, entry)
  if ctx["follow-symlinks"] then
    return add_followed_link(ctx, acc, entry)
  else
    return nil, (entry.rel .. ": symlinks are not supported")
  end
end
local function add_path_stat(ctx, acc, entry, stat)
  local case_36_ = stat.type
  if (case_36_ == "file") then
    return add_file(ctx, acc, entry.path, {rel = entry.rel, dedupe = entry.rel})
  elseif (case_36_ == "link") then
    return add_path_link(ctx, acc, entry)
  elseif (case_36_ == "directory") then
    return add_directory_path(ctx, acc, entry)
  else
    local _ = case_36_
    return acc, nil
  end
end
local function add_path(ctx, acc, input)
  local uv = ctx.uv
  local abs = absolute(ctx.root, input)
  local stat = uv.fs_lstat(abs)
  local rel = relative(ctx.root, abs)
  local entry = {directory = abs, prefix = "", name = input, type = (stat and stat.type), path = abs, rel = rel, ["error-prefix"] = input}
  if stat then
    return add_path_stat(ctx, acc, entry, stat)
  else
    return scan_acc(acc, acc.result), nil
  end
end
local function sorted_files_failure(failure, error)
  return (error or failure)
end
local function sorted_files_success(result)
  local function _39_(a, b)
    return (a.relative < b.relative)
  end
  table.sort(result, _39_)
  return result, nil
end
local function sorted_files_result(failure, result)
  local case_40_ = not failure
  if (case_40_ == false) then
    return nil, failure
  elseif (case_40_ == true) then
    return sorted_files_success(result)
  else
    return nil
  end
end
local function sorted_files_add(ctx, state, input)
  local next_acc, error = add_path(ctx, state.acc, input)
  local acc = (next_acc or state.acc)
  return {acc = acc, failure = sorted_files_failure(state.failure, error)}
end
local function sorted_files_step(ctx, state, input)
  if state.failure then
    return state
  else
    return sorted_files_add(ctx, state, input)
  end
end
local function sorted_files_loop(ctx, inputs, index, state)
  if (index > #inputs) then
    return sorted_files_result(state.failure, state.acc.result)
  else
    return sorted_files_loop(ctx, inputs, (index + 1), sorted_files_step(ctx, state, inputs[index]))
  end
end
local sorted_files
do
  local function sorted_files0(root, inputs, options)
    local uv = (vim.uv or vim.loop)
    local ctx = {walk = walk, step = walk_scan_step, root = root, excludes = options.excludes, extensions = options.extensions, ["skip-dotfiles"] = options["skip-dotfiles"], ["follow-symlinks"] = options["follow-symlinks"], ["error-prefix"] = nil, uv = uv}
    local acc = {result = {}, seen = {}, visited = {}}
    local state = {acc = acc, failure = nil}
    return sorted_files_loop(ctx, inputs, 1, state)
  end
  _2amodule_2a["sorted-files"] = sorted_files0
  sorted_files = _2amodule_2a["sorted-files"]
end
return nil
