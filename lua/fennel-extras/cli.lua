-- [nfnl] fnl/fennel-extras/cli.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.cli"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.cli"]
end
local config = require("fennel-extras.config")
local formatter = require("fennel-extras.format")
local function emit(printer, line)
  return printer(line)
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
local function add_file(root, path, rel, result, seen, excludes, extensions, dedupe)
  if (fnl_file_3f(rel, extensions) and not excluded_3f(rel, excludes) and not seen[dedupe]) then
    seen[dedupe] = true
    return table.insert(result, {relative = rel, absolute = path})
  else
    return nil
  end
end
local function walk(root, directory, prefix, result, seen, excludes, extensions, skip_dotfiles, follow_symlinks, error_prefix, visited)
  local uv = (vim.uv or vim.loop)
  local handle, scan_error = uv.fs_scandir(directory)
  if not handle then
    local or_15_ = error_prefix
    if not or_15_ then
      if (prefix == "") then
        or_15_ = "."
      else
        or_15_ = prefix
      end
    end
    return nil, ("cannot read directory " .. or_15_)
  else
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
              visited[target] = true
              local walk_result, error = walk(root, target, rel, result, seen, excludes, extensions, skip_dotfiles, follow_symlinks, rel, visited)
              if error then
                failure = error
              else
              end
            else
              if (target_stat and (target_stat.type == "file")) then
                local function _20_()
                  if follow_symlinks then
                    return target
                  else
                    return relative(root, path)
                  end
                end
                add_file(root, target, rel, result, seen, excludes, extensions, _20_())
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
                local function _24_()
                  if follow_symlinks then
                    return target0
                  else
                    return relative(root, path)
                  end
                end
                add_file(root, target0, rel, result, seen, excludes, extensions, _24_())
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
    local function _43_(a, b)
      return (a.relative < b.relative)
    end
    table.sort(result, _43_)
    return result, nil
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
local function parse_args(args)
  local command = args[1]
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
              i = (i + 1)
              parser_name = args[i]
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
local function config_for(root, printer)
  local path = config.find(root)
  if path then
    local loaded, error = config.load(path)
    if error then
      emit(printer, (path .. ": " .. (error.message or tostring(error))))
      return nil, true, nil
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
      open_error = error
      if not string.match(tostring(error), "EEXIST") then
        attempt = max_attempts
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
      os.remove(temp)
      return nil, (write_error or close_error or "could not write temporary file")
    else
      return temp, nil
    end
  end
end
local function run_files(root, mode, parser, cfg, files, printer)
  local formatted = {}
  local changed = {}
  local failure = nil
  for _, file in ipairs(files) do
    if not failure then
      local source, read_error = read_file(file.absolute)
      if read_error then
        failure = {path = file.relative, error = read_error}
      else
        local ok, output, error
        local function _67_()
          return formatter["format-string"](source, {parser = parser, config = formatter_config(cfg)})
        end
        ok, output, error = pcall(_67_)
        if not ok then
          failure = {path = file.relative, error = output}
        else
          if error then
            failure = {path = file.relative, error = error}
          else
            table.insert(formatted, {path = file.absolute, relative = file.relative, source = source, text = output})
            if (source ~= output) then
              table.insert(changed, file.relative)
            else
            end
          end
        end
      end
    else
    end
  end
  if failure then
    emit(printer, error_line(failure.path, failure.error))
    return 2
  else
    table.sort(changed)
    if (mode == "check") then
      for _, path in ipairs(changed) do
        emit(printer, path)
      end
      if (#changed > 0) then
        return 1
      else
        return 0
      end
    else
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
        for _, item in ipairs(temps) do
          os.remove(item.temp)
        end
        emit(printer, (write_failure.path .. ": " .. write_failure.error))
        return 2
      else
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
        if rename_failure then
          for _, item in ipairs(temps) do
            os.remove(item.temp)
          end
          emit(printer, (rename_failure.path .. ": " .. rename_failure.error))
          return 2
        else
          for _, path in ipairs(changed) do
            emit(printer, path)
          end
          return 0
        end
      end
    end
  end
end
local run
do
  local function run0(args, opts)
    local opts0 = (opts or {})
    local printer = (opts0.print or print)
    local root = (opts0.cwd or cwd())
    local parsed, parse_error = parse_args(args)
    if parse_error then
      emit(printer, parse_error)
      return 2
    else
      local cfg, config_error, config_path = config_for(root, printer)
      if config_error then
        return 2
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
          emit(printer, discovery_error)
          return 2
        else
          if (#files == 0) then
            emit(printer, "no files found")
            return 2
          else
            local parser, parser_error = load_parser((parsed.parser or cfg.parser))
            if parser_error then
              emit(printer, parser_error)
              return 2
            else
              return run_files(root, parsed.mode, parser, cfg, files, printer)
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
