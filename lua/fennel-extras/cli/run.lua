-- [nfnl] fnl/fennel-extras/cli/run.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.cli.run"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.cli.run"]
end
local table_update = require("fennel-extras.cli.table")
local config = require("fennel-extras.config")
local lint_run = require("fennel-extras.lint.run")
local scan = require("fennel-extras.cli.scan")
local arg_parser = require("fennel-extras.cli.args")
local fs = require("fennel-extras.cli.fs")
local git = require("fennel-extras.cli.git")
local format = require("fennel-extras.cli.format")
local matcher = require("fennel-extras.cli.matcher")
local function default_print(line)
  io.write((string.gsub(line, "\n+$", "") .. "\n"))
  return io.flush()
end
local function config_default(cfg, key, default)
  local value = cfg[key]
  if (value == nil) then
    return default
  else
    return value
  end
end
local function load_parser_result(name, ok, parser)
  if ok then
    return parser
  else
    return nil, ("could not require parser module: " .. name)
  end
end
local function load_parser_result_call(name)
  local ok, parser = pcall(require, name)
  return load_parser_result(name, ok, parser)
end
local function load_parser(name)
  if name then
    return load_parser_result_call(name)
  else
    return nil
  end
end
local function config_load_error(printer, path, error)
  printer((path .. ": " .. (error.message or tostring(error))))
  return nil, true, nil
end
local function config_loaded(printer, path)
  local loaded, error = config.load(path)
  if error then
    return config_load_error(printer, path, error)
  else
    return loaded, nil, path
  end
end
local function config_for(root, printer)
  local path = config.find(root)
  if path then
    return config_loaded(printer, path)
  else
    return {}, nil, nil
  end
end
local function read_lint_item(file)
  local source, error = fs["read-file"](file.absolute)
  if error then
    return nil, error
  else
    return source, nil
  end
end
local function append_lint_source(result, file, source)
  table.insert(result, {path = file.relative, source = source})
  return result
end
local function read_lint_item_result(state)
  local file = state.files[state.index]
  local source, error = read_lint_item(file)
  if error then
    return nil, {path = file.relative, error = error}
  else
    return {files = state.files, index = (state.index + 1), result = append_lint_source(state.result, file, source)}, nil
  end
end
local function read_lint_step_result(state)
  local next_state, error = read_lint_item_result(state)
  if error then
    return {kind = "error", error = error}
  else
    return {kind = "next", state = next_state}
  end
end
local function read_lint_step(state)
  if (state.index > #state.files) then
    return {kind = "done", result = state.result}
  else
    return read_lint_step_result(state)
  end
end
local function read_lint_files(state)
  local step = read_lint_step(state)
  local case_10_ = step.kind
  if (case_10_ == "error") then
    return nil, step.error
  elseif (case_10_ == "done") then
    return step.result, nil
  else
    local _ = case_10_
    return read_lint_files(step.state)
  end
end
local function lint_policy_error(root, config_path, printer, error)
  printer(format["error-line"](scan.relative(root, (config_path or ".fnl-extras.fnl")), error))
  return 2
end
local function lint_read_error(printer, error)
  printer(format["error-line"](error.path, error.error))
  return 2
end
local function lint_run_error(printer, error)
  printer(format["error-line"](error.path, error))
  return 2
end
local function lint_result(printer, result)
  for _, line in ipairs(result.lines) do
    printer(line)
  end
  return result.status
end
local function run_lint_sources(context, policy, sources)
  local selected, paths = git["lint-selection"](context.parsed, sources, context["git-info"])
  local root = context["git-info"].root
  local result, error = lint_run["lint-files"](selected, policy, (context["config-path"] and scan.relative(root, context["config-path"])), context.parsed.format, paths)
  if error then
    return lint_run_error(context.printer, error)
  else
    return lint_result(context.printer, result)
  end
end
local function run_lint_files(context, policy, files)
  local sources, read_error = read_lint_files({files = files, index = 1, result = {}})
  if read_error then
    return lint_read_error(context.printer, read_error)
  else
    return run_lint_sources(context, policy, sources)
  end
end
local function compile_exclusion_entry(entry)
  if entry.pattern then
    matcher["compile-pattern"](entry.pattern)
  else
  end
  if entry.code then
    return matcher["compile-pattern"](entry.code)
  else
    return nil
  end
end
local function compile_exclusion_patterns_step(exclusions, index, recurse)
  compile_exclusion_entry(exclusions[index])
  return recurse(exclusions, (index + 1), recurse)
end
local function compile_exclusion_patterns(exclusions, index, recurse)
  if (index > #exclusions) then
    return nil
  else
    return compile_exclusion_patterns_step(exclusions, index, recurse)
  end
end
local function compile_spec_file_pattern(spec_files, index, recurse)
  local ok, compile_error = pcall(matcher["compile-pattern"], spec_files[index])
  if ok then
    return recurse(spec_files, (index + 1), recurse)
  else
    return {index = index, error = compile_error}
  end
end
local function compile_spec_files_patterns_step(spec_files, index, recurse)
  if (index > #spec_files) then
    return nil
  else
    return compile_spec_file_pattern(spec_files, index, recurse)
  end
end
local function compile_spec_files_patterns(spec_files, index, recurse)
  return compile_spec_files_patterns_step(spec_files, index, recurse)
end
local function run_lint_policy_spec_files(context, files, policy)
  local spec_error = compile_spec_files_patterns(policy["spec-files"], 1, compile_spec_files_patterns)
  if spec_error then
    return lint_policy_error(context.root, context["config-path"], context.printer, {message = ("invalid spec-files regex " .. spec_error.index .. ": " .. tostring(spec_error.error))})
  else
    return run_lint_files(context, table_update.update(policy, {matcher = matcher["vim-matcher"]()}), files)
  end
end
local function run_lint_policy_success(context, files, policy)
  local ok, compile_error = pcall(compile_exclusion_patterns, policy.exclusions, 1, compile_exclusion_patterns)
  if not ok then
    return lint_policy_error(context.root, context["config-path"], context.printer, {message = ("invalid exclusion pattern regex: " .. tostring(compile_error))})
  else
    return run_lint_policy_spec_files(context, files, policy)
  end
end
local function run_lint_policy(context, files)
  local policy, policy_error = config["lint-policy"](context.cfg)
  if policy_error then
    return lint_policy_error(context.root, context["config-path"], context.printer, policy_error)
  else
    return run_lint_policy_success(context, files, policy)
  end
end
local function run_lint_discovery(context)
  local inputs = arg_parser["lint-inputs"](context.parsed, context.cfg)
  local extensions = (context.cfg.extensions or {".fnl", ".fnlm"})
  local skip_dotfiles = config_default(context.cfg, "skip-dotfiles", true)
  local follow_symlinks = config_default(context.cfg, "follow-symlinks", false)
  local discovered, discovery_error = scan["sorted-files"](context["git-info"].root, inputs, {excludes = (context.cfg.exclude or {}), extensions = extensions, ["skip-dotfiles"] = skip_dotfiles, ["follow-symlinks"] = follow_symlinks})
  local files = (discovered and format["without-config-file"](discovered, context["config-path"]))
  if discovery_error then
    return git["emit-git-error"](context.printer, discovery_error)
  else
    return run_lint_policy(context, files)
  end
end
local function run_lint(context)
  local git_info, git_error_value = git["lint-git-info"](context.root, context.parsed, context["require-git"])
  if git_error_value then
    return git["emit-git-error"](context.printer, git_error_value)
  else
    return run_lint_discovery(table_update.update(context, {["git-info"] = git_info}))
  end
end
local function run_format_files(context, files)
  local parser, parser_error = load_parser((context.parsed.parser or context.cfg.parser))
  if parser_error then
    return git["emit-git-error"](context.printer, parser_error)
  else
    return format["run-files"](context, parser, files)
  end
end
local function run_format_discovery(root, parsed, cfg, config_path)
  local inputs = arg_parser["lint-inputs"](parsed, cfg)
  local extensions = (cfg.extensions or {".fnl", ".fnlm"})
  local skip_dotfiles = config_default(cfg, "skip-dotfiles", true)
  local follow_symlinks = config_default(cfg, "follow-symlinks", false)
  local discovered, discovery_error = scan["sorted-files"](root, inputs, {excludes = (cfg.exclude or {}), extensions = extensions, ["skip-dotfiles"] = skip_dotfiles, ["follow-symlinks"] = follow_symlinks})
  return (discovered and format["without-config-file"](discovered, config_path)), discovery_error
end
local function run_format_files_result(context, files)
  if (#files == 0) then
    return git["emit-git-error"](context.printer, "no files found")
  else
    return run_format_files(context, files)
  end
end
local function run_format_result(context, files, discovery_error)
  if discovery_error then
    return git["emit-git-error"](context.printer, discovery_error)
  else
    return run_format_files_result(context, files)
  end
end
local function run_format(context)
  local files, discovery_error = run_format_discovery(context.root, context.parsed, context.cfg, context["config-path"])
  return run_format_result(context, files, discovery_error)
end
local function run_command_mode(context)
  local case_27_ = context.args[1]
  if (case_27_ == "lint") then
    return run_lint(table_update.update(context, {["require-git"] = context.parsed.changed}))
  else
    local _ = case_27_
    return run_format(context)
  end
end
local function run_command(context)
  local cfg, config_error, config_path = config_for(context.root, context.printer)
  if config_error then
    return 2
  else
    return run_command_mode(table_update.update(context, {cfg = cfg, ["config-path"] = config_path}))
  end
end
local run
do
  local function run0(args, opts)
    local opts0 = (opts or {})
    local printer = (opts0.print or default_print)
    local root = (opts0.cwd or scan.cwd())
    local parsed, parse_error = arg_parser["parse-args"](args)
    if parse_error then
      return git["emit-git-error"](printer, parse_error)
    else
      return run_command({root = root, args = args, parsed = parsed, printer = printer})
    end
  end
  _2amodule_2a["run"] = run0
  run = _2amodule_2a.run
end
return nil
