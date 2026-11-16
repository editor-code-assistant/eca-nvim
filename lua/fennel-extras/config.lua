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
local function branch(condition, _then, _else)
  return ((condition and _then) or _else)()
end
local function noop()
  return nil
end
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
  local function _1_()
    return (integer_3f(value) and (value >= 0) and (index == nil))
  end
  local function _2_()
    return ((kind == "inner") and ((value == 0) and ((index == nil) or (integer_3f(index) and (index >= 0)))))
  end
  return branch((kind == "block"), _1_, _2_)
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
  local function _3_()
    local function _4_()
      return rule_map_error_step(value, prefix, next_name)
    end
    local function _5_()
      return {message = (prefix .. next_name .. ": invalid indentation rule")}
    end
    return branch(valid_rule_list_3f(rule), _4_, _5_)
  end
  return branch(next_name, _3_, noop)
end
local function rule_map_error(value, prefix)
  local function _6_()
    return rule_map_error_step(value, prefix, nil)
  end
  local function _7_()
    return {message = (prefix .. ": invalid indentation rule")}
  end
  return branch((type(value) == "table"), _6_, _7_)
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
    local function _8_()
      return name
    end
    local function _9_()
      return candidate
    end
    candidate = branch((not allowed[name] and ((candidate == nil) or (tostring(name) < tostring(candidate)))), _8_, _9_)
  end
  return candidate
end
local function workspace_key_error_result(workspace)
  local key = workspace_key(workspace)
  local function _10_()
    return {message = ("unknown workspace key: " .. key)}
  end
  return branch(key, _10_, noop)
end
local function workspace_key_error(workspace)
  return ((type(workspace) == "table") and workspace_key_error_result(workspace))
end
local function workspace_error(tbl)
  local workspace = tbl.workspace
  local function _11_()
    return {message = "workspace must be a table"}
  end
  local or_12_ = branch((workspace and (type(workspace) ~= "table")), _11_, noop) or workspace_key_error(workspace)
  if not or_12_ then
    local function _13_()
      return {message = "workspace.paths must be an array of strings"}
    end
    or_12_ = branch((workspace and workspace.paths and not array_of_strings_3f(workspace.paths)), _13_, noop)
  end
  if not or_12_ then
    local function _14_()
      return {message = "workspace.exclude must be an array of strings"}
    end
    or_12_ = branch((workspace and workspace.exclude and not array_of_strings_3f(workspace.exclude)), _14_, noop)
  end
  if not or_12_ then
    local function _15_()
      return {message = "workspace.extensions must be a non-empty list of strings starting with \".\""}
    end
    or_12_ = branch((workspace and workspace.extensions and not extensions_3f(workspace.extensions)), _15_, noop)
  end
  if not or_12_ then
    local function _16_()
      return {message = "workspace.dotfiles must be a boolean"}
    end
    or_12_ = branch((workspace and (workspace.dotfiles ~= nil) and not ((workspace.dotfiles == true) or (workspace.dotfiles == false))), _16_, noop)
  end
  if not or_12_ then
    local function _17_()
      return {message = "workspace.symlinks must be a boolean"}
    end
    or_12_ = branch((workspace and (workspace.symlinks ~= nil) and not ((workspace.symlinks == true) or (workspace.symlinks == false))), _17_, noop)
  end
  if not or_12_ then
    local function _18_()
      return {message = "workspace.config must be a boolean"}
    end
    or_12_ = branch((workspace and (workspace.config ~= nil) and not ((workspace.config == true) or (workspace.config == false))), _18_, noop)
  end
  return or_12_
end
local function content_error(tbl)
  return workspace_error(tbl)
end
local validate_workspace
do
  local function validate_workspace0(workspace, require_paths_3f)
    local function _19_()
      return {message = "workspace must be a table"}
    end
    local or_20_ = branch((type(workspace) ~= "table"), _19_, noop) or workspace_key_error(workspace)
    if not or_20_ then
      local function _21_()
        return {message = "missing workspace.paths"}
      end
      or_20_ = branch((require_paths_3f and (workspace.paths == nil)), _21_, noop)
    end
    if not or_20_ then
      local function _22_()
        return {message = "workspace.paths must be an array of strings"}
      end
      or_20_ = branch((workspace.paths and not array_of_strings_3f(workspace.paths)), _22_, noop)
    end
    if not or_20_ then
      local function _23_()
        return {message = "workspace.exclude must be an array of strings"}
      end
      or_20_ = branch((workspace.exclude and not array_of_strings_3f(workspace.exclude)), _23_, noop)
    end
    if not or_20_ then
      local function _24_()
        return {message = "workspace.extensions must be a non-empty list of strings starting with \".\""}
      end
      or_20_ = branch((workspace.extensions and not extensions_3f(workspace.extensions)), _24_, noop)
    end
    if not or_20_ then
      local function _25_()
        return {message = "workspace.dotfiles must be a boolean"}
      end
      or_20_ = branch(((workspace.dotfiles ~= nil) and not ((workspace.dotfiles == true) or (workspace.dotfiles == false))), _25_, noop)
    end
    if not or_20_ then
      local function _26_()
        return {message = "workspace.symlinks must be a boolean"}
      end
      or_20_ = branch(((workspace.symlinks ~= nil) and not ((workspace.symlinks == true) or (workspace.symlinks == false))), _26_, noop)
    end
    if not or_20_ then
      local function _27_()
        return {message = "workspace.config must be a boolean"}
      end
      or_20_ = branch(((workspace.config ~= nil) and not ((workspace.config == true) or (workspace.config == false))), _27_, noop)
    end
    return or_20_
  end
  _2amodule_2a["validate-workspace"] = validate_workspace0
  validate_workspace = _2amodule_2a["validate-workspace"]
end
local function validation_result(tbl, failure)
  local function _28_()
    return nil, failure
  end
  local function _29_()
    return tbl
  end
  return branch(failure, _28_, _29_)
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
    local function _30_()
      return key
    end
    local function _31_()
      return candidate
    end
    candidate = branch((not allowed[key] and ((candidate == nil) or (tostring(key) < tostring(candidate)))), _30_, _31_)
  end
  return candidate
end
local function unknown_config_error(tbl)
  local key = unknown_config_key(tbl)
  local function _32_()
    return {message = ("unknown configuration key: " .. key)}
  end
  return branch(key, _32_, noop)
end
local function format_fragment_key_3f(key)
  return ((key == "indent-width") or (key == "parser") or (key == "indents") or (key == "format-as") or (key == "alignment") or (key == "newline") or (key == "extensions"))
end
local function unknown_format_fragment_key(tbl)
  local candidate = nil
  for key, _ in pairs(tbl) do
    local function _33_()
      return key
    end
    local function _34_()
      return candidate
    end
    candidate = branch((not format_fragment_key_3f(key) and ((candidate == nil) or (tostring(key) < tostring(candidate)))), _33_, _34_)
  end
  return candidate
end
local function format_fragment_error(tbl)
  local key = unknown_format_fragment_key(tbl)
  local function _35_()
    return {message = ("unknown configuration key: " .. key)}
  end
  local function _36_()
    return format_config.validate(tbl, false, false, false)
  end
  return branch(key, _35_, _36_)
end
local function validate_table_result(tbl, failure)
  local function _37_()
    return nil, failure
  end
  local function _38_()
    return valid_table(tbl)
  end
  return branch(failure, _37_, _38_)
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
    local function _39_()
      return nil, {message = "configuration must be a table"}
    end
    local function _40_()
      local function _41_()
        return validate_canonical_table(tbl)
      end
      local function _42_()
        return validate_format_fragment(tbl)
      end
      return branch((tbl.workspace or tbl.format or tbl.lint or tbl.design), _41_, _42_)
    end
    return branch((type(tbl) ~= "table"), _39_, _40_)
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
  local function _43_()
    return core.assoc(rules, "form-child-count", nil)
  end
  local function _44_()
    return rules
  end
  normalized = branch((rules["form-child-count"] and rules["child-count"]), _43_, _44_)
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
    local function _45_()
      rules[rule] = instances
      return nil
    end
    branch((rules[rule] == nil), _45_, noop)
  end
  return valid_lint_policy_result(cfg, rules, design)
end
local function lint_policy_valid(valid)
  local function _46_()
    return nil, {message = "missing lint or design"}
  end
  local function _47_()
    return valid_lint_policy(valid)
  end
  return branch(((valid.lint == nil) and (valid.design == nil)), _46_, _47_)
end
local lint_policy
do
  local function lint_policy0(cfg)
    local valid, error = validate(cfg)
    local function _48_()
      return nil, error
    end
    local function _49_()
      return lint_policy_valid(valid)
    end
    return branch(error, _48_, _49_)
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
  local function _50_()
    return parse_string(text)
  end
  ok, parsed_or_error = pcall(_50_)
  local function _51_()
    return nil, parsed_or_error
  end
  local function _52_()
    return validate(parsed_or_error)
  end
  return branch(not ok, _51_, _52_)
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
    local function _53_()
      return nil, {message = ("could not read config file: " .. path)}
    end
    local function _54_()
      return parse_loaded_text(read_file_text(file))
    end
    return branch(not file, _53_, _54_)
  end
  _2amodule_2a["load"] = load0
  load = _2amodule_2a.load
end
return nil
