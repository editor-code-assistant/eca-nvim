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
  local prefix
  if (string.sub(root, -1) == "/") then
    prefix = root
  else
    prefix = (root .. "/")
  end
  local result
  if (string.sub(path, 1, string.len(prefix)) == prefix) then
    result = string.sub(path, (string.len(prefix) + 1))
  else
    result = path
  end
  if (string.sub(result, 1, 2) == "./") then
    return string.sub(result, 3)
  else
    return result
  end
end
local function fnl_file_3f(path)
  return ((string.sub(path, -4) == ".fnl") or (string.sub(path, -5) == ".fnlm"))
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
local function add_file(root, path, result, seen, excludes)
  local rel = relative(root, path)
  if (fnl_file_3f(rel) and not excluded_3f(rel, excludes) and not seen[rel]) then
    seen[rel] = true
    return table.insert(result, {relative = rel, absolute = path})
  else
    return nil
  end
end
local function walk(root, directory, prefix, result, seen, excludes, error_prefix)
  local uv = (vim.uv or vim.loop)
  local handle, scan_error = uv.fs_scandir(directory)
  if not handle then
    local or_10_ = error_prefix
    if not or_10_ then
      if (prefix == "") then
        or_10_ = "."
      else
        or_10_ = prefix
      end
    end
    return nil, ("cannot read directory " .. or_10_)
  else
    local scanning = true
    local failure = nil
    while (scanning and not failure) do
      local name, type = uv.fs_scandir_next(handle)
      if not name then
        scanning = false
      else
        if (string.sub(name, 1, 1) == ".") then
        else
          local path = join(directory, name)
          local rel
          if (prefix == "") then
            rel = name
          else
            rel = (prefix .. "/" .. name)
          end
          if (type == "directory") then
            if not excluded_3f(rel, excludes) then
              local walk_result, error = walk(root, path, rel, result, seen, excludes, rel)
              if error then
                failure = error
              else
              end
            else
            end
          else
            if (type == "link") then
            else
              if (type == "file") then
                add_file(root, path, result, seen, excludes)
              else
              end
            end
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
local function add_path(root, input, result, seen, excludes)
  local uv = (vim.uv or vim.loop)
  local abs = absolute(root, input)
  local stat = uv.fs_lstat(abs)
  if stat then
    if (stat.type == "file") then
      return nil, add_file(root, abs, result, seen, excludes)
    else
      if (stat.type == "link") then
        return nil, (relative(root, abs) .. ": symlinks are not supported")
      else
        if (stat.type == "directory") then
          return walk(root, abs, "", result, seen, excludes, input)
        else
          return nil, nil
        end
      end
    end
  else
    return nil, nil
  end
end
local function sorted_files(root, inputs, excludes)
  local result = {}
  local seen = {}
  local failure = nil
  for _, input in ipairs(inputs) do
    if not failure then
      local path_result, error = add_path(root, input, result, seen, excludes)
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
    local function _28_(a, b)
      return (a.relative < b.relative)
    end
    table.sort(result, _28_)
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
      return nil, true
    else
      return loaded
    end
  else
    return {}
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
        local function _49_()
          return formatter["format-string"](source, {parser = parser, config = {indents = cfg.indents, ["format-as"] = cfg["format-as"], ["indent-patterns"] = cfg["indent-patterns"]}})
        end
        ok, output, error = pcall(_49_)
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
      local cfg, config_error = config_for(root, printer)
      if config_error then
        return 2
      else
        local inputs
        if (#parsed.paths > 0) then
          inputs = parsed.paths
        else
          inputs = (cfg.paths or {"."})
        end
        local files, discovery_error = sorted_files(root, inputs, (cfg.exclude or {}))
        if discovery_error then
          emit(printer, discovery_error)
          return 2
        else
          if (#files == 0) then
            emit(printer, "no files found")
            return 2
          else
            local parser, parser_error = load_parser(parsed.parser)
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
