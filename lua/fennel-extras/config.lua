-- [nfnl] fnl/fennel-extras/config.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.config"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.config"]
end
local core = require("eca.nfnl.core")
local reader = require("fennel-extras.reader")
local parse = require("fennel-extras.config.parse")
local lint_config = require("fennel-extras.config.lint")
local lint_rules = require("fennel-extras.lint.rules")
local lint_options = require("fennel-extras.lint.rules.options")
local alignment = require("fennel-extras.indent.settings")
local compatibility_policy = {["module-style"] = "error", ["spec-macro-import"] = "error", ["spec-no-module"] = "error", ["spec-direct-require"] = "error", ["one-is-per-testing"] = "error", ["if-branch-call"] = "warning", ["if-without-else"] = "warning", ["control-layout"] = "warning", ["unused-and-or"] = "warning", ["defn-args-newline"] = "warning", ["function-shape"] = "warning", ["no-mutation"] = "warning", ["multiline-layout"] = "warning", ["file-size"] = "warning", ["core-require"] = "error", ["binding-per-line"] = "warning", ["call-data-arg"] = "warning"}
local parse_string
do
  local function parse_string0(text)
    return parse["parse-string"](text)
  end
  _2amodule_2a["parse-string"] = parse_string0
  parse_string = _2amodule_2a["parse-string"]
end
local function array_of_strings_3f(value)
  if (type(value) ~= "table") then
    return false
  else
    local valid = true
    local index = 1
    while (valid and (value[index] ~= nil)) do
      if (type(value[index]) ~= "string") then
        valid = false
      else
      end
      index = (index + 1)
    end
    return valid
  end
end
local function integer_3f(value)
  return ((type(value) == "number") and (value == math.floor(value)))
end
local function valid_rule_3f(rule)
  if ((type(rule) == "table") and (type(rule[1]) == "string")) then
    local kind = rule[1]
    local value = rule[2]
    local index = rule[3]
    if (kind == "block") then
      return (integer_3f(value) and (value >= 0) and (index == nil))
    else
      if (kind == "inner") then
        return ((value == 0) and ((index == nil) or (integer_3f(index) and (index >= 0))))
      else
        return false
      end
    end
  else
    return false
  end
end
local function valid_rule_list_3f(value)
  if (type(value) == "table") then
    local valid = true
    for _, rule in ipairs(value) do
      if not valid_rule_3f(rule) then
        valid = false
      else
      end
    end
    return valid
  else
    return false
  end
end
local function rule_map_error(value, prefix)
  if (type(value) == "table") then
    local failure = nil
    for name, rule in pairs(value) do
      if (failure == nil) then
        if not valid_rule_list_3f(rule) then
          failure = {message = (prefix .. name .. ": invalid indentation rule")}
        else
        end
      else
      end
    end
    return failure
  else
    return {message = (prefix .. ": invalid indentation rule")}
  end
end
local function boolean_3f(value)
  return ((value == true) or (value == false))
end
local function extensions_3f(value)
  if ((type(value) == "table") and (#value > 0)) then
    local valid = true
    for _, extension in ipairs(value) do
      if ((type(extension) ~= "string") or not (string.sub(extension, 1, 1) == ".")) then
        valid = false
      else
      end
    end
    return valid
  else
    return false
  end
end
local function configuration_error_with_lint(failure, lint)
  return (failure or (lint and lint_config["lint-error"](lint)))
end
local function alignment_error(align_bindings, alignment_table)
  if ((align_bindings ~= nil) and not boolean_3f(align_bindings)) then
    return {message = "align-bindings must be a boolean"}
  else
    return (alignment_table and alignment.validate(alignment_table))
  end
end
local function configuration_error(tbl)
  local width = tbl["indent-width"]
  local builtins = tbl.builtins
  local fallbacks = tbl["prefix-fallbacks"]
  local extensions = tbl.extensions
  local skip_dotfiles = tbl["skip-dotfiles"]
  local follow_symlinks = tbl["follow-symlinks"]
  local align_bindings = tbl["align-bindings"]
  local alignment_table = tbl.alignment
  local parser = tbl.parser
  local lint = tbl.lint
  local failure = nil
  if ((failure == nil) and (width ~= nil) and not (integer_3f(width) and (width > 0))) then
    failure = {message = "indent-width must be a positive integer"}
  else
  end
  if ((failure == nil) and (builtins ~= nil) and not (builtins == true) and not (builtins == false) and (type(builtins) ~= "table")) then
    failure = {message = "builtins must be true, false, or a table of rules"}
  else
  end
  if ((failure == nil) and (type(builtins) == "table")) then
    failure = rule_map_error(builtins, "builtins rule ")
  else
  end
  if ((failure == nil) and (fallbacks ~= nil) and not (fallbacks == false) and (type(fallbacks) ~= "table")) then
    failure = {message = "prefix-fallbacks must be false or a table of rules"}
  else
  end
  if ((failure == nil) and (type(fallbacks) == "table")) then
    failure = rule_map_error(fallbacks, "prefix-fallbacks rule ")
  else
  end
  if ((failure == nil) and (extensions ~= nil) and not extensions_3f(extensions)) then
    failure = {message = "extensions must be a non-empty list of strings starting with \".\""}
  else
  end
  if ((failure == nil) and (skip_dotfiles ~= nil) and not boolean_3f(skip_dotfiles)) then
    failure = {message = "skip-dotfiles must be a boolean"}
  else
  end
  if ((failure == nil) and (follow_symlinks ~= nil) and not boolean_3f(follow_symlinks)) then
    failure = {message = "follow-symlinks must be a boolean"}
  else
  end
  if (failure == nil) then
    failure = alignment_error(align_bindings, alignment_table)
  else
  end
  if ((failure == nil) and (parser ~= nil) and (type(parser) ~= "string")) then
    failure = {message = "parser must be a string"}
  else
  end
  return configuration_error_with_lint(failure, lint)
end
local function normalize_if_needed(tbl)
  if (tbl["align-bindings"] or tbl.alignment) then
    return alignment.normalize(tbl)
  else
    return tbl
  end
end
local function path_error(tbl)
  if (tbl.paths and not array_of_strings_3f(tbl.paths)) then
    return {message = "paths must be an array of strings"}
  else
    return nil
  end
end
local function exclude_error(tbl)
  if (tbl.exclude and not array_of_strings_3f(tbl.exclude)) then
    return {message = "exclude must be an array of strings"}
  else
    return nil
  end
end
local function content_error(tbl)
  return (path_error(tbl) or exclude_error(tbl))
end
local function validation_result(tbl, failure)
  if failure then
    return nil, failure
  else
    return normalize_if_needed(tbl)
  end
end
local function validation_failure(tbl)
  return (configuration_error(tbl) or content_error(tbl))
end
local function valid_table(tbl)
  return validation_result(tbl, validation_failure(tbl))
end
local validate
do
  local function validate0(tbl)
    if (type(tbl) ~= "table") then
      return nil, {message = "configuration must be a table"}
    else
      local allowed = {indents = true, ["format-as"] = true, ["indent-patterns"] = true, paths = true, exclude = true, ["indent-width"] = true, builtins = true, ["prefix-fallbacks"] = true, extensions = true, ["skip-dotfiles"] = true, ["follow-symlinks"] = true, ["align-bindings"] = true, alignment = true, parser = true, lint = true}
      local failure = nil
      for key, _ in pairs(tbl) do
        if not allowed[key] then
          failure = {message = ("unknown configuration key: " .. key)}
        else
        end
      end
      if failure then
        return nil, failure
      else
        return valid_table(tbl)
      end
    end
  end
  _2amodule_2a["validate"] = validate0
  validate = _2amodule_2a.validate
end
local function normalized_options(options, name, entry)
  if entry.options then
    return core.assoc(options, name, entry.options)
  else
    return options
  end
end
local function normalized_table_entry(rules, options, name, entry)
  return core.assoc(rules, name, entry.severity), normalized_options(options, name, entry)
end
local function normalized_value_entry(rules, options, name, entry)
  return core.assoc(rules, name, entry), options
end
local function normalized_rule_entry(rules, options, name, entry)
  if (type(entry) == "table") then
    return normalized_table_entry(rules, options, name, entry)
  else
    return normalized_value_entry(rules, options, name, entry)
  end
end
local function normalized_overrides_step(overrides, next_key, state, recurse)
  local new_rules, new_options = normalized_rule_entry(state.rules, state.options, next_key, state.entry)
  return recurse(overrides, next_key, new_rules, new_options)
end
local function normalized_rule_overrides(overrides, key, rules, options)
  local next_key, next_entry = next(overrides, key)
  if (next_key == nil) then
    return rules, options
  else
    return normalized_overrides_step(overrides, next_key, {entry = next_entry, rules = rules, options = options}, normalized_rule_overrides)
  end
end
local function lint_policy_result(rules, options, exclusions, max_code_lines, spec_files)
  return {rules = rules, options = options, ["spec-files"] = spec_files, exclusions = exclusions, ["max-code-lines"] = max_code_lines}
end
local function lint_policy_defaults(overrides)
  if (next(overrides, nil) == nil) then
    return lint_rules.defaults()
  else
    return compatibility_policy
  end
end
local function valid_lint_policy(cfg)
  local lint = cfg.lint
  local overrides = ((lint and lint.rules) or {})
  local general = ((lint and lint.exclusions) or {})
  local exclusions = core.concat(general, lint_config.exclusions(overrides))
  local max_code_lines = ((lint and lint["max-code-lines"]) or 300)
  local spec_files = ((lint and lint["spec-files"]) or lint_options["spec-files"]())
  local defaults = lint_policy_defaults(overrides)
  local rules, explicit_options = normalized_rule_overrides(overrides, nil, defaults, {})
  local options = lint_options.normalized(explicit_options)
  return lint_policy_result(rules, options, exclusions, max_code_lines, spec_files)
end
local lint_policy
do
  local function lint_policy0(cfg)
    local valid, error = validate(cfg)
    if error then
      return nil, error
    else
      return valid_lint_policy(valid)
    end
  end
  _2amodule_2a["lint-policy"] = lint_policy0
  lint_policy = _2amodule_2a["lint-policy"]
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
    if file then
      return close_file(file)
    else
      return false
    end
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
local function found_config(candidate)
  return candidate, false
end
local find
do
  local function find0(start_dir)
    local dir = start_dir
    local result = nil
    local searching = true
    while searching do
      local candidate = join_path(dir, ".fnl-extras.fnl")
      if exists_3f(candidate) then
        local new_result, new_searching = found_config(candidate)
        result = new_result
        searching = new_searching
      else
        if git_marker_3f(dir) then
          searching = false
        else
          local parent = parent_dir(dir)
          if parent then
            dir = parent
          else
            searching = false
          end
        end
      end
    end
    return result
  end
  _2amodule_2a["find"] = find0
  find = _2amodule_2a.find
end
local load
do
  local function load0(path)
    local file = io.open(path, "r")
    if not file then
      return nil, {message = ("could not read config file: " .. path)}
    else
      local text = file:read("*a")
      file:close()
      local ok, parsed_or_error
      local function _45_()
        return parse_string(text)
      end
      ok, parsed_or_error = pcall(_45_)
      if not ok then
        return nil, parsed_or_error
      else
        return validate(parsed_or_error)
      end
    end
  end
  _2amodule_2a["load"] = load0
  load = _2amodule_2a.load
end
return nil
