-- [nfnl] fnl/fennel-extras/cli/args.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.cli.args"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.cli.args"]
end
local table_update = require("fennel-extras.cli.table")
local lint_inputs
do
  local function lint_inputs0(parsed, cfg)
    if (#parsed.paths > 0) then
      return parsed.paths
    else
      return (cfg.paths or {"."})
    end
  end
  _2amodule_2a["lint-inputs"] = lint_inputs0
  lint_inputs = _2amodule_2a["lint-inputs"]
end
local function lint_state(args, index, result)
  return {args = args, index = index, result = result}
end
local function lint_update(state, result)
  return lint_state(state.args, state.index, result)
end
local function lint_advance(state, offset, result)
  return lint_state(state.args, (state.index + offset), result)
end
local function append_path(paths, path)
  local result = {}
  for _, value in ipairs(paths) do
    table.insert(result, value)
  end
  table.insert(result, path)
  return result
end
local function parse_lint_format_value(state, value)
  if ((value ~= "text") and (value ~= "json")) then
    return nil, "format must be text or json"
  else
    return lint_advance(state, 2, table_update.update(state.result, {format = value, ["format-seen"] = true})), nil
  end
end
local function parse_lint_value_present(state, key, value)
  if (key == "--format") then
    return parse_lint_format_value(state, value)
  else
    local _ = key
    return lint_advance(state, 2, table_update.update(state.result, {base = value, changed = true})), nil
  end
end
local function parse_lint_value(state, key)
  if (state.index >= #state.args) then
    return nil, ("missing argument for " .. key)
  else
    return parse_lint_value_present(state, key, state.args[(state.index + 1)])
  end
end
local function parse_lint_path(state)
  return lint_advance(state, 1, table_update.update(state.result, {paths = append_path(state.result.paths, state.args[state.index])})), nil
end
local function parse_lint_all(state)
  if (state.result.all or state.result.changed) then
    return nil, "unknown or duplicate lint flag: --all"
  else
    return lint_advance(state, 1, table_update.update(state.result, {all = true, changed = false})), nil
  end
end
local function parse_lint_changed(state)
  if (state.result.changed or state.result.all) then
    return nil, "unknown or duplicate lint flag: --changed"
  else
    return lint_advance(state, 1, table_update.update(state.result, {changed = true})), nil
  end
end
local function parse_lint_base(state)
  if state.result.base then
    return nil, "unknown or duplicate lint flag: --base"
  else
    return parse_lint_value(state, "--base")
  end
end
local function parse_lint_format(state)
  if state.result["format-seen"] then
    return nil, "unknown or duplicate lint flag: --format"
  else
    return parse_lint_value(state, "--format")
  end
end
local function parse_lint_unsupported(state)
  return nil, ("unsupported lint flag: " .. state.args[state.index])
end
local function parse_lint_path_or_unknown(state)
  local arg = state.args[state.index]
  if (string.sub(arg, 1, 2) == "--") then
    return nil, ("unknown flag: " .. arg)
  else
    return parse_lint_path(state)
  end
end
local function parse_lint_arg(state)
  local case_10_ = state.args[state.index]
  if (case_10_ == "--all") then
    return parse_lint_all(state)
  elseif (case_10_ == "--changed") then
    return parse_lint_changed(state)
  elseif (case_10_ == "--base") then
    return parse_lint_base(state)
  elseif (case_10_ == "--format") then
    return parse_lint_format(state)
  elseif (case_10_ == "--write") then
    return parse_lint_unsupported(state)
  elseif (case_10_ == "--check") then
    return parse_lint_unsupported(state)
  elseif (case_10_ == "--parser") then
    return parse_lint_unsupported(state)
  else
    local _ = case_10_
    return parse_lint_path_or_unknown(state)
  end
end
local function parse_lint_success(result)
  if (result.all and result.base) then
    return nil, "--base cannot be used with --all"
  else
    return result
  end
end
local function parse_lint_result(state, error)
  if error then
    return nil, error
  else
    return parse_lint_success(state.result)
  end
end
local function parse_lint_arg_result(state)
  local next_state, error = parse_lint_arg(state)
  if error then
    return {kind = "error", error = error}
  else
    return {kind = "next", state = next_state}
  end
end
local function parse_lint_step(state)
  if (state.index > #state.args) then
    return {kind = "done", state = state}
  else
    return parse_lint_arg_result(state)
  end
end
local function parse_lint_loop(state)
  local step = parse_lint_step(state)
  local case_16_ = step.kind
  if (case_16_ == "error") then
    return nil, step.error
  elseif (case_16_ == "done") then
    return state, nil
  else
    local _ = case_16_
    return parse_lint_loop(step.state)
  end
end
local function parse_lint_args(args)
  local result = {base = nil, format = "text", paths = {}, all = false, changed = false, ["format-seen"] = false}
  local state = lint_state(args, 2, result)
  local final_state, error = parse_lint_loop(state)
  return parse_lint_result(final_state, error)
end
local function parse_format_mode_value(arg)
  if (arg == "--check") then
    return "check"
  else
    local _ = arg
    return "write"
  end
end
local function parse_format_mode(state)
  if state.mode then
    return nil, "unknown or duplicate mode flag"
  else
    return {args = state.args, index = (state.index + 1), mode = parse_format_mode_value(state.args[state.index]), parser = state.parser, paths = state.paths}, nil
  end
end
local function parse_format_parser(state)
  if (state.index >= #state.args) then
    return nil, "missing argument for --parser"
  else
    return {args = state.args, index = (state.index + 2), mode = state.mode, parser = state.args[(state.index + 1)], paths = state.paths}, nil
  end
end
local function parse_format_path(state)
  local arg = state.args[state.index]
  if (string.sub(arg, 1, 2) == "--") then
    return nil, ("unknown flag: " .. arg)
  else
    return {args = state.args, index = (state.index + 1), mode = state.mode, parser = state.parser, paths = append_path(state.paths, arg)}, nil
  end
end
local function parse_format_arg(state)
  local case_22_ = state.args[state.index]
  if (case_22_ == "--check") then
    return parse_format_mode(state)
  elseif (case_22_ == "--write") then
    return parse_format_mode(state)
  elseif (case_22_ == "--parser") then
    return parse_format_parser(state)
  else
    local _ = case_22_
    return parse_format_path(state)
  end
end
local function parse_format_success(state)
  if not state.mode then
    return nil, "missing --check or --write"
  else
    return {mode = state.mode, parser = state.parser, paths = state.paths}
  end
end
local function parse_format_arg_result(state)
  local next_state, error = parse_format_arg(state)
  if error then
    return {kind = "error", error = error}
  else
    return {kind = "next", state = next_state}
  end
end
local function parse_format_step(state)
  if (state.index > #state.args) then
    return {kind = "done", state = state}
  else
    return parse_format_arg_result(state)
  end
end
local function parse_format_loop(state)
  local step = parse_format_step(state)
  local case_27_ = step.kind
  if (case_27_ == "error") then
    return nil, step.error
  elseif (case_27_ == "done") then
    return parse_format_success(state)
  else
    local _ = case_27_
    return parse_format_loop(step.state)
  end
end
local function parse_format_args(args)
  return parse_format_loop({args = args, index = 2, mode = nil, parser = nil, paths = {}})
end
local parse_args
do
  local function parse_args0(args)
    local case_29_ = args[1]
    if (case_29_ == "lint") then
      return parse_lint_args(args)
    elseif (case_29_ == "format") then
      return parse_format_args(args)
    else
      local _ = case_29_
      return nil, ("unknown command: " .. (args[1] or ""))
    end
  end
  _2amodule_2a["parse-args"] = parse_args0
  parse_args = _2amodule_2a["parse-args"]
end
return nil
