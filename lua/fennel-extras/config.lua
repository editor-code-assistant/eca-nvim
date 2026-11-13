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
local format_config = require("fennel-extras.config.format")
local find_config = require("fennel-extras.config.find")
local parse_string
do
  local function parse_string0(text)
    return parse["parse-string"](text)
  end
  _2amodule_2a["parse-string"] = parse_string0
  parse_string = _2amodule_2a["parse-string"]
end
local function array_of_strings_step(value, index)
  return ((value[index] == nil) or ((type(value[index]) == "string") and array_of_strings_step(value, (index + 1))))
end
local function array_of_strings_3f(value)
  return ((type(value) == "table") and array_of_strings_step(value, 1))
end
local function integer_3f(value)
  return ((type(value) == "number") and (value == math.floor(value)))
end
local function valid_rule_values_3f(rule)
  local kind = rule[1]
  local value = rule[2]
  local index = rule[3]
  if (kind == "block") then
    return (integer_3f(value) and (value >= 0) and (index == nil))
  else
    return ((kind == "inner") and ((value == 0) and ((index == nil) or (integer_3f(index) and (index >= 0)))))
  end
end
local function valid_rule_3f(rule)
  return ((type(rule) == "table") and (type(rule[1]) == "string") and valid_rule_values_3f(rule))
end
local function valid_rule_list_step(value, index)
  return ((index > #value) or (valid_rule_3f(value[index]) and valid_rule_list_step(value, (index + 1))))
end
local function valid_rule_list_3f(value)
  return ((type(value) == "table") and valid_rule_list_step(value, 1))
end
local function rule_map_error_step(value, prefix, name)
  local next_name, rule = next(value, name)
  if next_name then
    if valid_rule_list_3f(rule) then
      return rule_map_error_step(value, prefix, next_name)
    else
      return {message = (prefix .. next_name .. ": invalid indentation rule")}
    end
  else
    return nil
  end
end
local function rule_map_error(value, prefix)
  if (type(value) == "table") then
    return rule_map_error_step(value, prefix, nil)
  else
    return {message = (prefix .. ": invalid indentation rule")}
  end
end
local function extensions_step(value, index)
  return ((index > #value) or ((type(value[index]) == "string") and (string.sub(value[index], 1, 1) == ".") and extensions_step(value, (index + 1))))
end
local function extensions_3f(value)
  return ((type(value) == "table") and (#value > 0) and extensions_step(value, 1))
end
local function configuration_error_with_lint(failure, lint)
  return (failure or (lint and lint_config["lint-error"](lint)))
end
local function configuration_error(tbl)
  return ((tbl.format and format_config.validate(tbl.format, false, false, false)) or configuration_error_with_lint(nil, tbl.lint) or (tbl.design and lint_config["design-error"](tbl.design)))
end
local function workspace_key(workspace)
  local allowed = {paths = true, exclude = true, extensions = true, dotfiles = true, symlinks = true, config = true}
  local candidate = nil
  for name, _ in pairs(workspace) do
    if (not allowed[name] and ((candidate == nil) or (tostring(name) < tostring(candidate)))) then
      candidate = name
    else
      candidate = candidate
    end
  end
  return candidate
end
local function workspace_key_error_result(workspace)
  local key = workspace_key(workspace)
  if key then
    return {message = ("unknown workspace key: " .. key)}
  else
    return nil
  end
end
local function workspace_key_error(workspace)
  return ((type(workspace) == "table") and workspace_key_error_result(workspace))
end
local function workspace_error(tbl)
  local workspace = tbl.workspace
  local _7_
  if (workspace and (type(workspace) ~= "table")) then
    _7_ = {message = "workspace must be a table"}
  else
    _7_ = nil
  end
  local or_9_ = _7_ or workspace_key_error(workspace)
  if not or_9_ then
    if (workspace and workspace.paths and not array_of_strings_3f(workspace.paths)) then
      or_9_ = {message = "workspace.paths must be an array of strings"}
    else
      or_9_ = nil
    end
  end
  if not or_9_ then
    if (workspace and workspace.exclude and not array_of_strings_3f(workspace.exclude)) then
      or_9_ = {message = "workspace.exclude must be an array of strings"}
    else
      or_9_ = nil
    end
  end
  if not or_9_ then
    if (workspace and workspace.extensions and not extensions_3f(workspace.extensions)) then
      or_9_ = {message = "workspace.extensions must be a non-empty list of strings starting with \".\""}
    else
      or_9_ = nil
    end
  end
  if not or_9_ then
    if (workspace and (workspace.dotfiles ~= nil) and not ((workspace.dotfiles == true) or (workspace.dotfiles == false))) then
      or_9_ = {message = "workspace.dotfiles must be a boolean"}
    else
      or_9_ = nil
    end
  end
  if not or_9_ then
    if (workspace and (workspace.symlinks ~= nil) and not ((workspace.symlinks == true) or (workspace.symlinks == false))) then
      or_9_ = {message = "workspace.symlinks must be a boolean"}
    else
      or_9_ = nil
    end
  end
  if not or_9_ then
    if (workspace and (workspace.config ~= nil) and not ((workspace.config == true) or (workspace.config == false))) then
      or_9_ = {message = "workspace.config must be a boolean"}
    else
      or_9_ = nil
    end
  end
  return or_9_
end
local function content_error(tbl)
  return workspace_error(tbl)
end
local validate_workspace
do
  local function validate_workspace0(workspace, require_paths_3f)
    local _16_
    if (type(workspace) ~= "table") then
      _16_ = {message = "workspace must be a table"}
    else
      _16_ = nil
    end
    local or_18_ = _16_ or workspace_key_error(workspace)
    if not or_18_ then
      if (require_paths_3f and (workspace.paths == nil)) then
        or_18_ = {message = "missing workspace.paths"}
      else
        or_18_ = nil
      end
    end
    if not or_18_ then
      if (workspace.paths and not array_of_strings_3f(workspace.paths)) then
        or_18_ = {message = "workspace.paths must be an array of strings"}
      else
        or_18_ = nil
      end
    end
    if not or_18_ then
      if (workspace.exclude and not array_of_strings_3f(workspace.exclude)) then
        or_18_ = {message = "workspace.exclude must be an array of strings"}
      else
        or_18_ = nil
      end
    end
    if not or_18_ then
      if (workspace.extensions and not extensions_3f(workspace.extensions)) then
        or_18_ = {message = "workspace.extensions must be a non-empty list of strings starting with \".\""}
      else
        or_18_ = nil
      end
    end
    if not or_18_ then
      if ((workspace.dotfiles ~= nil) and not ((workspace.dotfiles == true) or (workspace.dotfiles == false))) then
        or_18_ = {message = "workspace.dotfiles must be a boolean"}
      else
        or_18_ = nil
      end
    end
    if not or_18_ then
      if ((workspace.symlinks ~= nil) and not ((workspace.symlinks == true) or (workspace.symlinks == false))) then
        or_18_ = {message = "workspace.symlinks must be a boolean"}
      else
        or_18_ = nil
      end
    end
    if not or_18_ then
      if ((workspace.config ~= nil) and not ((workspace.config == true) or (workspace.config == false))) then
        or_18_ = {message = "workspace.config must be a boolean"}
      else
        or_18_ = nil
      end
    end
    return or_18_
  end
  _2amodule_2a["validate-workspace"] = validate_workspace0
  validate_workspace = _2amodule_2a["validate-workspace"]
end
local function validation_result(tbl, failure)
  if failure then
    return nil, failure
  else
    return tbl
  end
end
local function validation_failure(tbl)
  return (configuration_error(tbl) or content_error(tbl))
end
local function valid_table(tbl)
  return validation_result(tbl, validation_failure(tbl))
end
local function unknown_config_key(tbl)
  local allowed = {workspace = true, format = true, lint = true, design = true}
  local candidate = nil
  for key, _ in pairs(tbl) do
    if (not allowed[key] and ((candidate == nil) or (tostring(key) < tostring(candidate)))) then
      candidate = key
    else
      candidate = candidate
    end
  end
  return candidate
end
local function unknown_config_error(tbl)
  local key = unknown_config_key(tbl)
  if key then
    return {message = ("unknown configuration key: " .. key)}
  else
    return nil
  end
end
local function format_fragment_key_3f(key)
  return ((key == "indent-width") or (key == "parser") or (key == "indents") or (key == "format-as") or (key == "alignment") or (key == "newline") or (key == "extensions"))
end
local function unknown_format_fragment_key(tbl)
  local candidate = nil
  for key, _ in pairs(tbl) do
    if (not format_fragment_key_3f(key) and ((candidate == nil) or (tostring(key) < tostring(candidate)))) then
      candidate = key
    else
      candidate = candidate
    end
  end
  return candidate
end
local function format_fragment_error(tbl)
  local key = unknown_format_fragment_key(tbl)
  if key then
    return {message = ("unknown configuration key: " .. key)}
  else
    return format_config.validate(tbl, false, false, false)
  end
end
local function validate_table_result(tbl, failure)
  if failure then
    return nil, failure
  else
    return valid_table(tbl)
  end
end
local function validate_canonical_table(tbl)
  return validate_table_result(tbl, unknown_config_error(tbl))
end
local function validate_format_fragment(tbl)
  local failure = format_fragment_error(tbl)
  return validation_result(tbl, failure)
end
local validate
do
  local function validate0(tbl)
    if (type(tbl) ~= "table") then
      return nil, {message = "configuration must be a table"}
    else
      if (tbl.workspace or tbl.format or tbl.lint or tbl.design) then
        return validate_canonical_table(tbl)
      else
        return validate_format_fragment(tbl)
      end
    end
  end
  _2amodule_2a["validate"] = validate0
  validate = _2amodule_2a.validate
end
local function append_canonical_exclusion(result, rule, index, exclusion)
  do
    local copy = {}
    for key, value in pairs(exclusion) do
      copy[key] = value
    end
    table.insert(result, core.assoc(core.assoc(copy, "rule", rule), "instance", index))
  end
  return result
end
local function append_canonical_instance_exclusions(result, rule, index, instance)
  for _, exclusion in ipairs((instance.exclusions or {})) do
    append_canonical_exclusion(result, rule, index, exclusion)
  end
  return result
end
local function append_canonical_rule_exclusions(result, rule, instances)
  for index, instance in ipairs((instances or {})) do
    append_canonical_instance_exclusions(result, rule, index, instance)
  end
  return result
end
local function canonical_exclusions(rules)
  local result = {}
  for rule, instances in pairs(rules) do
    append_canonical_rule_exclusions(result, rule, instances)
  end
  return result
end
local function normalize_lint_rules(rules)
  local normalized
  if (rules["form-child-count"] and rules["child-count"]) then
    normalized = core.assoc(rules, "form-child-count", nil)
  else
    normalized = rules
  end
  return normalized
end
local function valid_lint_policy_result(cfg, rules, design)
  local normalized = normalize_lint_rules(rules)
  return {rules = normalized, design = (cfg.design and {rules = design}), exclusions = canonical_exclusions(normalized)}
end
local function valid_lint_policy(cfg)
  local rules = core.merge(((cfg.lint and cfg.lint.rules) or {}))
  local design = (cfg.design and cfg.design.rules)
  for rule, instances in pairs((design or {})) do
    if (rules[rule] == nil) then
      rules[rule] = instances
    else
    end
  end
  return valid_lint_policy_result(cfg, rules, design)
end
local function lint_policy_valid(valid)
  if ((valid.lint == nil) and (valid.design == nil)) then
    return nil, {message = "missing lint or design"}
  else
    return valid_lint_policy(valid)
  end
end
local lint_policy
do
  local function lint_policy0(cfg)
    local valid, error = validate(cfg)
    if error then
      return nil, error
    else
      return lint_policy_valid(valid)
    end
  end
  _2amodule_2a["lint-policy"] = lint_policy0
  lint_policy = _2amodule_2a["lint-policy"]
end
local find
do
  local function find0(start_dir)
    return find_config.find(start_dir)
  end
  _2amodule_2a["find"] = find0
  find = _2amodule_2a.find
end
local function parse_loaded_text(text)
  local ok, parsed_or_error
  local function _38_()
    return parse_string(text)
  end
  ok, parsed_or_error = pcall(_38_)
  if not ok then
    return nil, parsed_or_error
  else
    return validate(parsed_or_error)
  end
end
local function read_file_text(file)
  local text = file:read("*a")
  file:close()
  return text
end
local load
do
  local function load0(path)
    local file = io.open(path, "r")
    if not file then
      return nil, {message = ("could not read config file: " .. path)}
    else
      return parse_loaded_text(read_file_text(file))
    end
  end
  _2amodule_2a["load"] = load0
  load = _2amodule_2a.load
end
return nil
