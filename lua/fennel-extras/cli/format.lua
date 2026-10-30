-- [nfnl] fnl/fennel-extras/cli/format.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.cli.format"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.cli.format"]
end
local formatter = require("fennel-extras.format")
local fs = require("fennel-extras.cli.fs")
local scan = require("fennel-extras.cli.scan")
local scan_path = require("fennel-extras.cli.scan.path")
local table_copy = require("fennel-extras.cli.table")
local error_line
do
  local function error_line0(path, error)
    local message = (error.message or tostring(error))
    local line = error.line
    local col = (error.col or error.column)
    if (line and col) then
      return (path .. ":" .. line .. ":" .. col .. ": " .. message)
    else
      return (path .. ": " .. message)
    end
  end
  _2amodule_2a["error-line"] = error_line0
  error_line = _2amodule_2a["error-line"]
end
local function formatter_config(cfg)
  local format = cfg.format
  return {indents = format.indents, ["format-as"] = format["format-as"], ["indent-patterns"] = format["indent-patterns"], ["indent-width"] = format["indent-width"], builtins = format.builtins, ["prefix-fallbacks"] = format["prefix-fallbacks"], parser = format.parser, alignment = format.alignment, newline = format.newline}
end
local function normalized_path(path)
  if (string.sub(path, 1, 9) == "/private/") then
    return string.sub(path, 9)
  else
    return path
  end
end
local same_path_3f
do
  local function same_path_3f0(left, right)
    local uv = (vim.uv or vim.loop)
    local left0 = normalized_path((scan.realpath(uv, left) or left))
    local right0 = normalized_path((scan.realpath(uv, right) or right))
    return (left0 == right0)
  end
  _2amodule_2a["same-path?"] = same_path_3f0
  same_path_3f = _2amodule_2a["same-path?"]
end
local explicit_config_file_3f
do
  local function explicit_config_file_3f0(root, paths, config_path)
    local and_3_ = config_path and (#paths == 1)
    if and_3_ then
      local result = false
      for _, input in ipairs(paths) do
        result = (result or same_path_3f(scan_path.absolute(root, input), config_path))
      end
      and_3_ = result
    end
    return and_3_
  end
  _2amodule_2a["explicit-config-file?"] = explicit_config_file_3f0
  explicit_config_file_3f = _2amodule_2a["explicit-config-file?"]
end
local function config_file_kept_3f(file, config_path)
  return not same_path_3f(file.absolute, config_path)
end
local function without_config_file_item(file, config_path)
  if config_file_kept_3f(file, config_path) then
    return file
  else
    return nil
  end
end
local function without_config_file_result(files, config_path)
  local tbl_26_ = {}
  local i_27_ = 0
  for _, file in ipairs(files) do
    local val_28_ = without_config_file_item(file, config_path)
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local without_config_file
do
  local function without_config_file0(files, config_path)
    if config_path then
      return without_config_file_result(files, config_path)
    else
      return files
    end
  end
  _2amodule_2a["without-config-file"] = without_config_file0
  without_config_file = _2amodule_2a["without-config-file"]
end
local discovered_files
do
  local function discovered_files0(root, paths, discovered, config_path, include_config_3f)
    if ((include_config_3f and ((#paths == 0) or ((#paths == 1) and (paths[1] == ".")))) or explicit_config_file_3f(root, paths, config_path)) then
      return discovered
    else
      return without_config_file(discovered, config_path)
    end
  end
  _2amodule_2a["discovered-files"] = discovered_files0
  discovered_files = _2amodule_2a["discovered-files"]
end
local function append_config_input(result, input)
  table.insert(result, input)
  return result
end
local function append_config_inputs(inputs, config_path)
  local result = {}
  for _, input in ipairs(inputs) do
    append_config_input(result, input)
  end
  return append_config_input(result, config_path)
end
local discovery_inputs
do
  local function discovery_inputs0(parsed, inputs, config_path, include_config_3f)
    if (include_config_3f and config_path and ((#parsed.paths == 0) or ((#parsed.paths == 1) and (parsed.paths[1] == ".")))) then
      return append_config_inputs(inputs, config_path)
    else
      return inputs
    end
  end
  _2amodule_2a["discovery-inputs"] = discovery_inputs0
  discovery_inputs = _2amodule_2a["discovery-inputs"]
end
local function record_formatted(state, file, source, output)
  table.insert(state.formatted, {path = file.absolute, relative = file.relative, source = source, text = output})
  if (source ~= output) then
    table.insert(state.changed, file.relative)
  else
  end
  return state
end
local function run_files_error(printer, failure)
  printer(error_line(failure.path, failure.error))
  return 2
end
local function check_files(changed, printer)
  for _, path in ipairs(changed) do
    printer(path)
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
  printer((write_failure.path .. ": " .. write_failure.error))
  return 2
end
local function rename_item(item)
  local ok, renamed, error = pcall(os.rename, item.temp, item.path)
  if (not ok or not renamed) then
    return {path = item.relative, error = (error or "could not rename temporary file")}
  else
    return nil
  end
end
local function rename_step(rename_failure, item)
  if rename_failure then
    return rename_failure
  else
    return rename_item(item)
  end
end
local function rename_loop(temps, index, failure)
  if (index > #temps) then
    return failure
  else
    return rename_loop(temps, (index + 1), rename_step(failure, temps[index]))
  end
end
local function rename_files(temps)
  return rename_loop(temps, 1, nil)
end
local function rename_failure_result(temps, rename_failure, printer)
  for _, item in ipairs(temps) do
    os.remove(item.temp)
  end
  printer((rename_failure.path .. ": " .. rename_failure.error))
  return 2
end
local function format_source_error(file, source, output, error)
  if error then
    return nil, {path = file.relative, error = error}
  else
    return {path = file.absolute, relative = file.relative, source = source, text = output}, nil
  end
end
local function format_source_result(file, source, result)
  local case_15_ = not result.ok
  if (case_15_ == true) then
    return nil, {path = file.relative, error = result.output}
  elseif (case_15_ == false) then
    return format_source_error(file, source, result.output, result.error)
  else
    return nil
  end
end
local function format_string_call(parser, cfg, source)
  return formatter["format-string"](source, {parser = parser, config = formatter_config(cfg)})
end
local function format_file_source(parser, cfg, file, source)
  local ok, output, error = pcall(format_string_call, parser, cfg, source)
  return format_source_result(file, source, {ok = ok, output = output, error = error})
end
local function format_file(parser, cfg, file)
  local source, read_error = fs["read-file"](file.absolute)
  if read_error then
    return nil, {path = file.relative, error = read_error}
  else
    return format_file_source(parser, cfg, file, source)
  end
end
local function append_formatted(state, item)
  table.insert(state.formatted, item)
  if (item.source ~= item.text) then
    table.insert(state.changed, item.relative)
  else
  end
  return state
end
local function write_success_result(changed, printer)
  for _, path in ipairs(changed) do
    printer(path)
  end
  return 0
end
local function write_item(item, temps)
  local temp, error = fs["temp-write"](item.path, item.text)
  if not temp then
    return {path = item.relative, error = error}
  else
    return table.insert(temps, {path = item.path, relative = item.relative, temp = temp})
  end
end
local function write_step(write_failure, item, temps)
  if (write_failure or (item.source == item.text)) then
    return write_failure
  else
    return write_item(item, temps)
  end
end
local function write_files_loop(formatted, index, temps, failure)
  if (index > #formatted) then
    return temps, failure
  else
    return write_files_loop(formatted, (index + 1), temps, write_step(failure, formatted[index], temps))
  end
end
local function write_files_rename(temps, changed, printer)
  local rename_failure = rename_files(temps)
  if rename_failure then
    return rename_failure_result(temps, rename_failure, printer)
  else
    return write_success_result(changed, printer)
  end
end
local function write_files_finish(formatted, changed, printer)
  local temps, write_failure = write_files_loop(formatted, 1, {}, nil)
  if write_failure then
    return write_failure_result(temps, write_failure, printer)
  else
    return write_files_rename(temps, changed, printer)
  end
end
local function process_files_result(mode, formatted, changed, printer)
  table.sort(changed)
  if (mode == "check") then
    return check_files(changed, printer)
  else
    return write_files_finish(formatted, changed, printer)
  end
end
local function run_file_item(ctx, state, file)
  local item, error = format_file(ctx.parser, ctx.cfg, file)
  if error then
    return table_copy.update(state, {failure = error})
  else
    return append_formatted(state, item)
  end
end
local function run_files_step(ctx, state, file)
  if state.failure then
    return state
  else
    return run_file_item(ctx, state, file)
  end
end
local function run_files_result(ctx, state)
  if state.failure then
    return run_files_error(ctx.printer, state.failure)
  else
    return process_files_result(ctx.mode, state.formatted, state.changed, ctx.printer)
  end
end
local function run_files_loop(ctx, state, files, index)
  if (index > #files) then
    return state
  else
    return run_files_loop(ctx, run_files_step(ctx, state, files[index]), files, (index + 1))
  end
end
local run_files
do
  local function run_files0(context, parser, files)
    local ctx = table_copy.update(context, {mode = context.parsed.mode, parser = parser})
    local state = {formatted = {}, changed = {}, failure = nil}
    return run_files_result(ctx, run_files_loop(ctx, state, files, 1))
  end
  _2amodule_2a["run-files"] = run_files0
  run_files = _2amodule_2a["run-files"]
end
return nil
