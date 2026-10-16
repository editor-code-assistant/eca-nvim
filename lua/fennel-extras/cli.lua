-- [nfnl] fnl/fennel-extras/cli.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.cli"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.cli"]
end
local config = require("fennel-extras.config")
local formatter = require("fennel-extras.format")
local lint_run = require("fennel-extras.lint.run")
local lint_selection = require("fennel-extras.lint.selection")
local function emit(printer, line)
  return printer(line)
end
local function default_print(line)
  io.write((string.gsub(line, "\n+$", "") .. "\n"))
  return io.flush()
end
local function cwd()
  return ((vim and vim.loop and vim.loop.cwd()) or (vim and vim.uv and vim.uv.cwd()) or ".")
end
local function join(left, right)
  if (left == "/") then
    return (left .. right)
  else
    if (string.sub(left, -1) == "/") then
      return (left .. right)
    else
      return (left .. "/" .. right)
    end
  end
end
local function absolute(root, path)
  if (string.sub(path, 1, 1) == "/") then
    return path
  else
    return join(root, path)
  end
end
local function relative(root, path)
  local root0
  if (string.sub(root, 1, 9) == "/private/") then
    root0 = string.sub(root, 9)
  else
    root0 = root
  end
  local path0
  if (string.sub(path, 1, 9) == "/private/") then
    path0 = string.sub(path, 9)
  else
    path0 = path
  end
  local prefix
  if (string.sub(root0, -1) == "/") then
    prefix = root0
  else
    prefix = (root0 .. "/")
  end
  local result
  if (string.sub(path0, 1, string.len(prefix)) == prefix) then
    result = string.sub(path0, (string.len(prefix) + 1))
  else
    result = path0
  end
  if (string.sub(result, 1, 2) == "./") then
    return string.sub(result, 3)
  else
    return result
  end
end
local function fnl_file_3f(path, extensions)
  local result = false
  for _, extension in ipairs(extensions) do
    if (string.sub(path, ( - string.len(extension))) == extension) then
      result = true
    else
    end
  end
  return result
end
local function under_prefix_3f(path, prefix)
  local clean
  if (string.sub(prefix, -1) == "/") then
    clean = string.sub(prefix, 1, -2)
  else
    clean = prefix
  end
  return ((path == clean) or (string.sub(path, 1, (string.len(clean) + 1)) == (clean .. "/")))
end
local function excluded_3f(path, excludes)
  local result = under_prefix_3f(path, ".git")
  for _, prefix in ipairs(excludes) do
    if under_prefix_3f(path, prefix) then
      result = true
    else
    end
  end
  return result
end
local function hidden_3f(name)
  return (string.sub(name, 1, 1) == ".")
end
local function realpath(uv, path)
  local resolved, error = pcall(uv.fs_realpath, path)
  if (resolved and error) then
    return error
  else
    return nil
  end
end
local function walk_prefix(root, path)
  local rel = relative(root, path)
  if (rel == ".") then
    return ""
  else
    return rel
  end
end
local function record_file(path, rel, result, seen, dedupe)
  seen[dedupe] = true
  return table.insert(result, {relative = rel, absolute = path})
end
local function add_file(root, path, rel, result, seen, excludes, extensions, dedupe)
  if (fnl_file_3f(rel, extensions) and not excluded_3f(rel, excludes) and not seen[dedupe]) then
    return record_file(path, rel, result, seen, dedupe)
  else
    return nil
  end
end
local function walk_target(walk_fn, root, target, rel, result, seen, excludes, extensions, skip_dotfiles, follow_symlinks, visited)
  visited[target] = true
  local walk_result, error = walk_fn(root, target, rel, result, seen, excludes, extensions, skip_dotfiles, follow_symlinks, rel, visited)
  if error then
    return nil, error
  else
    return result, nil
  end
end
local function walk_scan(walk_fn, root, directory, prefix, result, seen, excludes, extensions, skip_dotfiles, follow_symlinks, error_prefix, visited, uv, handle)
  local scanning = true
  local failure = nil
  while (scanning and not failure) do
    local name, type = uv.fs_scandir_next(handle)
    if not name then
      scanning = false
    else
      if (skip_dotfiles and hidden_3f(name)) then
      else
        local path = join(directory, name)
        local rel
        if (prefix == "") then
          rel = name
        else
          rel = (prefix .. "/" .. name)
        end
        if (((type == "directory") and not (name == ".git")) or (type == "file") or (follow_symlinks and (type == "link"))) then
          local target
          if (type == "link") then
            target = realpath(uv, path)
          else
            target = path
          end
          local target_stat = (target and uv.fs_stat(target))
          if (target_stat and (target_stat.type == "directory") and not excluded_3f(rel, excludes) and not visited[target]) then
            local walk_result, error = walk_target(walk_fn, root, target, rel, result, seen, excludes, extensions, skip_dotfiles, follow_symlinks, visited)
            if error then
              failure = error
            else
            end
          else
            if (target_stat and (target_stat.type == "file")) then
              local function _19_()
                if follow_symlinks then
                  return target
                else
                  return relative(root, path)
                end
              end
              add_file(root, target, rel, result, seen, excludes, extensions, _19_())
            else
            end
          end
          if (type == "file") then
            local target0
            if follow_symlinks then
              target0 = realpath(uv, path)
            else
              target0 = path
            end
            local target_stat0 = (target0 and uv.fs_stat(target0))
            if (target_stat0 and (target_stat0.type == "file")) then
              local function _23_()
                if follow_symlinks then
                  return target0
                else
                  return relative(root, path)
                end
              end
              add_file(root, target0, rel, result, seen, excludes, extensions, _23_())
            else
            end
          else
          end
        else
        end
      end
    end
  end
  if failure then
    return nil, failure
  else
    return result, nil
  end
end
local function walk(root, directory, prefix, result, seen, excludes, extensions, skip_dotfiles, follow_symlinks, error_prefix, visited)
  local uv = (vim.uv or vim.loop)
  local handle, scan_error = uv.fs_scandir(directory)
  if not handle then
    local or_30_ = error_prefix
    if not or_30_ then
      if (prefix == "") then
        or_30_ = "."
      else
        or_30_ = prefix
      end
    end
    return nil, ("cannot read directory " .. or_30_)
  else
    return walk_scan(walk, root, directory, prefix, result, seen, excludes, extensions, skip_dotfiles, follow_symlinks, error_prefix, visited, uv, handle)
  end
end
local function add_path(root, input, result, seen, excludes, extensions, skip_dotfiles, follow_symlinks)
  local uv = (vim.uv or vim.loop)
  local abs = absolute(root, input)
  local stat = uv.fs_lstat(abs)
  local rel = relative(root, abs)
  if stat then
    if (stat.type == "file") then
      return add_file(root, abs, rel, result, seen, excludes, extensions, rel)
    else
      if (stat.type == "link") then
        if follow_symlinks then
          local target = realpath(uv, abs)
          local target_stat = (target and uv.fs_stat(target))
          if (target_stat and (target_stat.type == "file")) then
            return add_file(root, target, rel, result, seen, excludes, extensions, target)
          else
            if (target_stat and (target_stat.type == "directory")) then
              return walk(root, target, rel, result, seen, excludes, extensions, skip_dotfiles, follow_symlinks, input, {})
            else
              return nil
            end
          end
        else
          return nil, (rel .. ": symlinks are not supported")
        end
      else
        if (stat.type == "directory") then
          local target
          if follow_symlinks then
            target = realpath(uv, abs)
          else
            target = abs
          end
          local visited
          if follow_symlinks then
            visited = {[target] = true}
          else
            visited = {}
          end
          return walk(root, target, walk_prefix(root, abs), result, seen, excludes, extensions, skip_dotfiles, follow_symlinks, input, visited)
        else
          return nil
        end
      end
    end
  else
    return nil
  end
end
local function sorted_files_success(result)
  local function _42_(a, b)
    return (a.relative < b.relative)
  end
  table.sort(result, _42_)
  return result, nil
end
local function sorted_files(root, inputs, excludes, extensions, skip_dotfiles, follow_symlinks)
  local result = {}
  local seen = {}
  local failure = nil
  for _, input in ipairs(inputs) do
    if not failure then
      local path_result, error = add_path(root, input, result, seen, excludes, extensions, skip_dotfiles, follow_symlinks)
      if error then
        failure = error
      else
      end
    else
    end
  end
  if failure then
    return nil, failure
  else
    return sorted_files_success(result)
  end
end
local function read_file(path)
  local file = io.open(path, "r")
  if file then
    local text = file:read("*a")
    file:close()
    return text, nil
  else
    return nil, {message = ("could not read file: " .. path)}
  end
end
local function error_line(path, error)
  local message = (error.message or tostring(error))
  local line = error.line
  local col = (error.col or error.column)
  if (line and col) then
    return (path .. ":" .. line .. ":" .. col .. ": " .. message)
  else
    return (path .. ": " .. message)
  end
end
local function append_path(paths, path)
  local result = {}
  for _, value in ipairs(paths) do
    table.insert(result, value)
  end
  table.insert(result, path)
  return result
end
local function parse_lint_value(args, index, state, key)
  if (index >= #args) then
    return nil, ("missing argument for " .. key)
  else
    local value = args[(index + 1)]
    if (key == "--format") then
      if ((value ~= "text") and (value ~= "json")) then
        return nil, "format must be text or json"
      else
        return (index + 2), {all = state.all, base = state.base, format = value, ["format-seen"] = true, paths = state.paths}
      end
    else
      local _ = key
      return (index + 2), {all = state.all, base = value, format = state.format, ["format-seen"] = state["format-seen"], paths = state.paths}
    end
  end
end
local function parse_lint_args_step(args, index, state)
  if (index > #args) then
    return state, nil
  else
    local arg = args[index]
    if (arg == "--all") then
      if state.all then
        return nil, "unknown or duplicate lint flag: --all"
      else
        return parse_lint_args_step(args, (index + 1), {all = true, base = state.base, format = state.format, ["format-seen"] = state["format-seen"], paths = state.paths})
      end
    elseif (arg == "--base") then
      if state.base then
        return nil, "unknown or duplicate lint flag: --base"
      else
        local next_index, next_state_or_error = parse_lint_value(args, index, state, "--base")
        if next_index then
          return parse_lint_args_step(args, next_index, next_state_or_error)
        else
          return nil, next_state_or_error
        end
      end
    elseif (arg == "--format") then
      if state["format-seen"] then
        return nil, "unknown or duplicate lint flag: --format"
      else
        local next_index, next_state_or_error = parse_lint_value(args, index, state, "--format")
        if next_index then
          return parse_lint_args_step(args, next_index, next_state_or_error)
        else
          return nil, next_state_or_error
        end
      end
    elseif (arg == "--write") then
      return nil, "unsupported lint flag: --write"
    elseif (arg == "--check") then
      return nil, "unsupported lint flag: --check"
    elseif (arg == "--parser") then
      return nil, "unsupported lint flag: --parser"
    else
      local _ = arg
      if (string.sub(arg, 1, 2) == "--") then
        return nil, ("unknown flag: " .. arg)
      else
        return parse_lint_args_step(args, (index + 1), {all = state.all, base = state.base, format = state.format, ["format-seen"] = state["format-seen"], paths = append_path(state.paths, arg)})
      end
    end
  end
end
local function parse_lint_args(args)
  local state, failure = parse_lint_args_step(args, 2, {base = nil, format = "text", paths = {}, all = false, ["format-seen"] = false})
  if failure then
    return nil, failure
  else
    if (state.all and state.base) then
      return nil, "--base cannot be used with --all"
    else
      return state
    end
  end
end
local function parse_parser_option(args, index)
  return (index + 1), args[(index + 1)]
end
local function parse_args(args)
  local command = args[1]
  if (command == "lint") then
    return parse_lint_args(args)
  else
    if (command ~= "format") then
      return nil, ("unknown command: " .. (command or ""))
    else
      local mode = nil
      local parser_name = nil
      local paths = {}
      local i = 2
      local failure = nil
      while ((i <= #args) and not failure) do
        do
          local arg = args[i]
          if ((arg == "--check") or (arg == "--write")) then
            if mode then
              failure = "unknown or duplicate mode flag"
            else
              if (arg == "--check") then
                mode = "check"
              else
                mode = "write"
              end
            end
          else
            if (arg == "--parser") then
              if (i >= #args) then
                failure = "missing argument for --parser"
              else
                local next_index, next_parser = parse_parser_option(args, i)
                i = next_index
                parser_name = next_parser
              end
            else
              if (string.sub(arg, 1, 2) == "--") then
                failure = ("unknown flag: " .. arg)
              else
                table.insert(paths, arg)
              end
            end
          end
        end
        i = (i + 1)
      end
      if failure then
        return nil, failure
      else
        if not mode then
          return nil, "missing --check or --write"
        else
          return {mode = mode, parser = parser_name, paths = paths}
        end
      end
    end
  end
end
local function load_parser(name)
  if name then
    local ok, parser = pcall(require, name)
    if ok then
      return parser
    else
      return nil, ("could not require parser module: " .. name)
    end
  else
    return nil
  end
end
local function config_load_error(printer, path, error)
  emit(printer, (path .. ": " .. (error.message or tostring(error))))
  return nil, true, nil
end
local function config_for(root, printer)
  local path = config.find(root)
  if path then
    local loaded, error = config.load(path)
    if error then
      return config_load_error(printer, path, error)
    else
      return loaded, nil, path
    end
  else
    return {}, nil, nil
  end
end
local function formatter_config(cfg)
  return {indents = cfg.indents, ["format-as"] = cfg["format-as"], ["indent-patterns"] = cfg["indent-patterns"], ["indent-width"] = cfg["indent-width"], builtins = cfg.builtins, ["prefix-fallbacks"] = cfg["prefix-fallbacks"]}
end
local function normalized_path(path)
  if (string.sub(path, 1, 9) == "/private/") then
    return string.sub(path, 9)
  else
    return path
  end
end
local function same_path_3f(left, right)
  local uv = (vim.uv or vim.loop)
  local left0 = normalized_path((realpath(uv, left) or left))
  local right0 = normalized_path((realpath(uv, right) or right))
  return (left0 == right0)
end
local function without_config_file(files, config_path)
  if config_path then
    local result = {}
    for _, file in ipairs(files) do
      if not same_path_3f(file.absolute, config_path) then
        table.insert(result, file)
      else
      end
    end
    return result
  else
    return files
  end
end
local function temp_open_attempt(error, max_attempts)
  if string.match(tostring(error), "EEXIST") then
    return nil
  else
    return max_attempts
  end
end
local function temp_write_error(temp, write_error, close_error)
  os.remove(temp)
  return nil, (write_error or close_error or "could not write temporary file")
end
local function temp_write(path, text)
  local uv = (vim.uv or vim.loop)
  local max_attempts = 10
  local attempt = 0
  local temp = nil
  local file = nil
  local open_error = nil
  while ((attempt < max_attempts) and not file) do
    attempt = (attempt + 1)
    temp = (path .. ".tmp-" .. tostring(math.random(1000000000)))
    local ok, fd, error = pcall(uv.fs_open, temp, "wx", 420)
    if (ok and fd) then
      file = fd
    else
      local next_attempt = temp_open_attempt(error, max_attempts)
      open_error = error
      if next_attempt then
        attempt = next_attempt
      else
      end
    end
  end
  if not file then
    return nil, (open_error or "could not open temporary file")
  else
    local write_ok, written, write_error = pcall(uv.fs_write, file, text)
    local close_ok, close_result, close_error = pcall(uv.fs_close, file)
    if (not write_ok or not written or write_error or not close_ok or not close_result or close_error) then
      return temp_write_error(temp, write_error, close_error)
    else
      return temp, nil
    end
  end
end
local function record_formatted(formatted, changed, file, source, output)
  table.insert(formatted, {path = file.absolute, relative = file.relative, source = source, text = output})
  if (source ~= output) then
    return table.insert(changed, file.relative)
  else
    return nil
  end
end
local function run_files_error(printer, failure)
  emit(printer, error_line(failure.path, failure.error))
  return 2
end
local function check_files(changed, printer)
  for _, path in ipairs(changed) do
    emit(printer, path)
  end
  if (#changed > 0) then
    return 1
  else
    return 0
  end
end
local function write_failure_result(temps, write_failure, printer)
  for _, item in ipairs(temps) do
    os.remove(item.temp)
  end
  emit(printer, (write_failure.path .. ": " .. write_failure.error))
  return 2
end
local function rename_files(temps)
  local rename_failure = nil
  for _, item in ipairs(temps) do
    if not rename_failure then
      local ok, renamed, error = pcall(os.rename, item.temp, item.path)
      if (not ok or not renamed) then
        rename_failure = {path = item.relative, error = (error or "could not rename temporary file")}
      else
      end
    else
    end
  end
  return rename_failure
end
local function rename_failure_result(temps, rename_failure, printer)
  for _, item in ipairs(temps) do
    os.remove(item.temp)
  end
  emit(printer, (rename_failure.path .. ": " .. rename_failure.error))
  return 2
end
local function format_file(parser, cfg, file)
  local source, read_error = read_file(file.absolute)
  if read_error then
    return nil, {path = file.relative, error = read_error}
  else
    local ok, output, error
    local function _87_()
      return formatter["format-string"](source, {parser = parser, config = formatter_config(cfg)})
    end
    ok, output, error = pcall(_87_)
    if not ok then
      return nil, {path = file.relative, error = output}
    else
      if error then
        return nil, {path = file.relative, error = error}
      else
        return {path = file.absolute, relative = file.relative, source = source, text = output}, nil
      end
    end
  end
end
local function append_formatted(formatted, changed, item)
  table.insert(formatted, item)
  if (item.source ~= item.text) then
    return table.insert(changed, item.relative)
  else
    return nil
  end
end
local function write_success_result(changed, printer)
  for _, path in ipairs(changed) do
    emit(printer, path)
  end
  return 0
end
local function write_files_result(formatted, changed, printer)
  local write_failure = nil
  local temps = {}
  for _, item in ipairs(formatted) do
    if (not write_failure and (item.source ~= item.text)) then
      local temp, error = temp_write(item.path, item.text)
      if temp then
        table.insert(temps, {path = item.path, relative = item.relative, temp = temp})
      else
        write_failure = {path = item.relative, error = error}
      end
    else
    end
  end
  if write_failure then
    return write_failure_result(temps, write_failure, printer)
  else
    local rename_failure = rename_files(temps)
    if rename_failure then
      return rename_failure_result(temps, rename_failure, printer)
    else
      return write_success_result(changed, printer)
    end
  end
end
local function process_files_result(mode, formatted, changed, printer)
  table.sort(changed)
  if (mode == "check") then
    return check_files(changed, printer)
  else
    return write_files_result(formatted, changed, printer)
  end
end
local function run_files(root, mode, parser, cfg, files, printer)
  local formatted = {}
  local changed = {}
  local failure = nil
  for _, file in ipairs(files) do
    if not failure then
      local item, error = format_file(parser, cfg, file)
      if error then
        failure = error
      else
        append_formatted(formatted, changed, item)
      end
    else
    end
  end
  if failure then
    return run_files_error(printer, failure)
  else
    return process_files_result(mode, formatted, changed, printer)
  end
end
local function read_lint_files(files, index, result)
  if (index > #files) then
    return result, nil
  else
    local file = files[index]
    local source, error = read_file(file.absolute)
    if error then
      return nil, {path = file.relative, error = error}
    else
      local function _100_()
        table.insert(result, {path = file.relative, source = source})
        return result
      end
      return read_lint_files(files, (index + 1), _100_())
    end
  end
end
local function lint_discovery_error(printer, error)
  emit(printer, error)
  return 2
end
local function lint_no_files(printer)
  emit(printer, "no files found")
  return 2
end
local function lint_policy_error(root, config_path, printer, error)
  emit(printer, error_line(relative(root, (config_path or ".fnl-extras.fnl")), error))
  return 2
end
local function lint_read_error(printer, error)
  emit(printer, error_line(error.path, error.error))
  return 2
end
local function lint_run_error(printer, error)
  emit(printer, error_line(error.path, error))
  return 2
end
local function lint_result(printer, result)
  for _, line in ipairs(result.lines) do
    emit(printer, line)
  end
  return result.status
end
local function parse_error_result(printer, error)
  emit(printer, error)
  return 2
end
local function discovery_error_result(printer, error)
  emit(printer, error)
  return 2
end
local function no_files_result(printer)
  emit(printer, "no files found")
  return 2
end
local function parser_error_result(printer, error)
  emit(printer, error)
  return 2
end
local function trim_newlines(text)
  return string.gsub(text, "\n+$", "")
end
local function git_command(root, args)
  local _103_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, arg in ipairs(args) do
      local val_28_ = vim.fn.shellescape(arg)
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _103_ = tbl_26_
  end
  return ("git -C " .. vim.fn.shellescape(root) .. " " .. table.concat(_103_, " "))
end
local function git_call(root, args)
  local file = io.popen((git_command(root, args) .. " </dev/null 2>&1; printf '\\n__ECA_STATUS__%s' $?"))
  local output
  if file then
    output = file:read("*a")
  else
    output = ""
  end
  if file then
    file:close()
  else
  end
  local marker = string.find(output, "\n__ECA_STATUS__")
  if marker then
    return string.sub(output, 1, (marker - 1)), tonumber(string.sub(output, (marker + 15)))
  else
    return output, 2
  end
end
local function git_root(start)
  local output, status = git_call(start, {"rev-parse", "--show-toplevel"})
  if (status == 0) then
    return trim_newlines(output)
  else
    return nil
  end
end
local function git_error(message)
  return {message = message}
end
local function git_plan_changed(root, parsed)
  local base = (parsed.base or "HEAD")
  local resolved, resolved_status = git_call(root, {"rev-parse", "--verify", (base .. "^{commit}")})
  if (resolved_status ~= 0) then
    return nil, git_error(("unknown base ref: " .. base))
  else
    local status_text, status_code = git_call(root, {"diff", "--name-status", "-z", "--find-renames", "--find-copies", base, "--"})
    local untracked_text, untracked_code = git_call(root, {"ls-files", "--others", "--exclude-standard", "-z"})
    if ((status_code ~= 0) or (untracked_code ~= 0)) then
      return nil, git_error("could not inspect Git changes")
    else
      local records = lint_selection["parse-name-status"](status_text)
      local untracked = lint_selection["parse-untracked"](untracked_text)
      return {root = root, records = records, untracked = untracked, plan = lint_selection.plan(records, untracked)}, nil
    end
  end
end
local function git_plan(start, parsed)
  local root = git_root(start)
  if (root == nil) then
    return nil, git_error("lint requires a Git repository")
  else
    local shallow, shallow_status = git_call(root, {"rev-parse", "--is-shallow-repository"})
    if ((shallow_status == 0) and (trim_newlines(shallow) == "true")) then
      return nil, git_error("lint requires a full clone; shallow repositories are not supported")
    else
      if parsed.all then
        return {root = root}, nil
      else
        return git_plan_changed(root, parsed)
      end
    end
  end
end
local function path_present_3f(paths, path, index)
  if (index > #paths) then
    return false
  else
    if (path == paths[index]) then
      return true
    else
      return path_present_3f(paths, path, (index + 1))
    end
  end
end
local function changed_file(root, base, file, whole_3f)
  if whole_3f then
    return {path = file.path, source = file.source, selection = true}
  else
    local patch, status = git_call(root, {"diff", "--unified=0", "--no-color", "--no-ext-diff", base, "--", file.path})
    if (status == 0) then
      return {path = file.path, source = file.source, selection = lint_selection["parse-hunks"](patch)}
    else
      return nil
    end
  end
end
local function append_selected(result, selected)
  table.insert(result, selected)
  return result
end
local function changed_files(root, base, files, plan, index, result)
  if (index > #files) then
    return result
  else
    local file = files[index]
    local whole_3f = path_present_3f(plan.whole, file.path, 1)
    local hunk_3f = path_present_3f(plan.hunks, file.path, 1)
    if (whole_3f or hunk_3f) then
      local selected = changed_file(root, base, file, whole_3f)
      if selected then
        return changed_files(root, base, files, plan, (index + 1), append_selected(result, selected))
      else
        return changed_files(root, base, files, plan, (index + 1), result)
      end
    else
      return changed_files(root, base, files, plan, (index + 1), result)
    end
  end
end
local function emit_git_error(printer, error)
  emit(printer, error.message)
  return 2
end
local function scope_paths(plan)
  local result = {}
  for _, path in ipairs(plan.whole) do
    table.insert(result, path)
  end
  for _, path in ipairs(plan.hunks) do
    table.insert(result, path)
  end
  for _, path in ipairs(plan.deleted) do
    table.insert(result, path)
  end
  return result
end
local function run_lint(root, parsed, cfg, config_path, printer, require_git_3f)
  local git_info, git_error_value
  if require_git_3f then
    git_info, git_error_value = git_plan(root, parsed)
  else
    git_info, git_error_value = {root = root}, nil
  end
  if git_error_value then
    return emit_git_error(printer, git_error_value)
  else
    local git_info0 = (git_info or {root = root, plan = {whole = {}, hunks = {}, deleted = {}}})
    local git_root_path = git_info0.root
    local inputs
    if (#parsed.paths > 0) then
      inputs = parsed.paths
    else
      inputs = (cfg.paths or {"."})
    end
    local extensions = (cfg.extensions or {".fnl", ".fnlm"})
    local skip_dotfiles
    if (cfg["skip-dotfiles"] == nil) then
      skip_dotfiles = true
    else
      skip_dotfiles = cfg["skip-dotfiles"]
    end
    local follow_symlinks
    if (cfg["follow-symlinks"] == nil) then
      follow_symlinks = false
    else
      follow_symlinks = cfg["follow-symlinks"]
    end
    local discovered, discovery_error = sorted_files(git_root_path, inputs, (cfg.exclude or {}), extensions, skip_dotfiles, follow_symlinks)
    local files = (discovered and without_config_file(discovered, config_path))
    if discovery_error then
      return lint_discovery_error(printer, discovery_error)
    else
      local policy, policy_error = config["lint-policy"](cfg)
      if policy_error then
        return lint_policy_error(git_root_path, config_path, printer, policy_error)
      else
        local sources, read_error = read_lint_files(files, 1, {})
        if read_error then
          return lint_read_error(printer, read_error)
        else
          local selected
          if parsed.all then
            selected = sources
          else
            selected = changed_files(git_root_path, (parsed.base or "HEAD"), sources, git_info0.plan, 1, {})
          end
          local paths
          if parsed.all then
            paths = nil
          else
            paths = scope_paths(git_info0.plan)
          end
          local result, error = lint_run["lint-files"](selected, policy, (config_path and relative(git_root_path, config_path)), parsed.format, paths)
          if error then
            return lint_run_error(printer, error)
          else
            return lint_result(printer, result)
          end
        end
      end
    end
  end
end
local run
do
  local function run0(args, opts)
    local opts0 = (opts or {})
    local printer = (opts0.print or default_print)
    local root = (opts0.cwd or cwd())
    local parsed, parse_error = parse_args(args)
    if parse_error then
      return parse_error_result(printer, parse_error)
    else
      local cfg, config_error, config_path = config_for(root, printer)
      if config_error then
        return 2
      else
        if (args[1] == "lint") then
          return run_lint(root, parsed, cfg, config_path, printer, not opts0.print)
        else
          local inputs
          if (#parsed.paths > 0) then
            inputs = parsed.paths
          else
            inputs = (cfg.paths or {"."})
          end
          local extensions = (cfg.extensions or {".fnl", ".fnlm"})
          local skip_dotfiles
          if (cfg["skip-dotfiles"] == nil) then
            skip_dotfiles = true
          else
            skip_dotfiles = cfg["skip-dotfiles"]
          end
          local follow_symlinks
          if (cfg["follow-symlinks"] == nil) then
            follow_symlinks = false
          else
            follow_symlinks = cfg["follow-symlinks"]
          end
          local discovered, discovery_error = sorted_files(root, inputs, (cfg.exclude or {}), extensions, skip_dotfiles, follow_symlinks)
          local files = (discovered and without_config_file(discovered, config_path))
          if discovery_error then
            return discovery_error_result(printer, discovery_error)
          else
            if (#files == 0) then
              return no_files_result(printer)
            else
              local parser, parser_error = load_parser((parsed.parser or cfg.parser))
              if parser_error then
                return parser_error_result(printer, parser_error)
              else
                return run_files(root, parsed.mode, parser, cfg, files, printer)
              end
            end
          end
        end
      end
    end
  end
  _2amodule_2a["run"] = run0
  run = _2amodule_2a.run
end
return nil
