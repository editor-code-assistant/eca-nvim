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
  if (value[index] == nil) then
    return true
  else
    if (type(value[index]) == "string") then
      return array_of_strings_step(value, (index + 1))
    else
      return false
    end
  end
end
local function array_of_strings_3f(value)
  if (type(value) == "table") then
    return array_of_strings_step(value, 1)
  else
    return false
  end
end
local function integer_3f(value)
  if (type(value) == "number") then
    return (value == math.floor(value))
  else
    return false
  end
end
local function valid_index_3f(index)
  if (index == nil) then
    return true
  else
    if integer_3f(index) then
      return (index >= 0)
    else
      return false
    end
  end
end
local function valid_rule_values_3f(rule)
  local kind = rule[1]
  local value = rule[2]
  local index = rule[3]
  if (kind == "block") then
    return (integer_3f(value) and (value >= 0) and (index == nil))
  else
    if (kind == "inner") then
      return ((value == 0) and valid_index_3f(index))
    else
      return false
    end
  end
end
local function valid_rule_3f(rule)
  return ((type(rule) == "table") and (type(rule[1]) == "string") and valid_rule_values_3f(rule))
end
local function valid_rule_list_step(value, index)
  if (index > #value) then
    return true
  else
    if valid_rule_3f(value[index]) then
      return valid_rule_list_step(value, (index + 1))
    else
      return false
    end
  end
end
local function valid_rule_list_3f(value)
  if (type(value) == "table") then
    return valid_rule_list_step(value, 1)
  else
    return false
  end
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
  if (index > #value) then
    return true
  else
    if ((type(value[index]) == "string") and (string.sub(value[index], 1, 1) == ".")) then
      return extensions_step(value, (index + 1))
    else
      return false
    end
  end
end
local function extensions_3f(value)
  return ((type(value) == "table") and (#value > 0) and extensions_step(value, 1))
end
local function configuration_error_with_lint(failure, lint)
  if failure then
    return failure
  else
    if lint then
      return lint_config["lint-error"](lint)
    else
      return nil
    end
  end
end
local function configuration_error(tbl)
  local format_error = (tbl.format and format_config.validate(tbl.format, false, false, false))
  local lint_error = configuration_error_with_lint(format_error, tbl.lint)
  if lint_error then
    return lint_error
  else
    if tbl.design then
      return lint_config["design-error"](tbl.design)
    else
      return nil
    end
  end
end
local function workspace_key_candidate_3f(allowed, candidate, name)
  if allowed[name] then
    return false
  else
    if (candidate == nil) then
      return true
    else
      return (tostring(name) < tostring(candidate))
    end
  end
end
local function workspace_key(workspace)
  local allowed = {paths = true, exclude = true, extensions = true, dotfiles = true, symlinks = true, config = true}
  local candidate = nil
  for name, _ in pairs(workspace) do
    if workspace_key_candidate_3f(allowed, candidate, name) then
      candidate = name
    else
      candidate = candidate
    end
  end
  return candidate
end
local function workspace_key_error(workspace)
  local key = ((type(workspace) == "table") and workspace_key(workspace))
  if key then
    return {message = ("unknown workspace key: " .. key)}
  else
    return nil
  end
end
local function workspace_error_message(message)
  return {message = message}
end
local function boolean_3f(value)
  return ((value == true) or (value == false))
end
local function invalid_optional_boolean_3f(workspace, key)
  return (workspace and (workspace[key] ~= nil) and not boolean_3f(workspace[key]))
end
local function validate_workspace_value(workspace, require_workspace_3f, require_paths_3f)
  local table_3f = (type(workspace) == "table")
  local workspace_required = (require_workspace_3f or (workspace ~= nil))
  local key_error = (table_3f and workspace_key_error(workspace))
  if (workspace_required and not table_3f) then
    return workspace_error_message("workspace must be a table")
  else
    if key_error then
      return key_error
    else
      if (table_3f and require_paths_3f and (workspace.paths == nil)) then
        return workspace_error_message("missing workspace.paths")
      else
        if (table_3f and workspace.paths and not array_of_strings_3f(workspace.paths)) then
          return workspace_error_message("workspace.paths must be an array of strings")
        else
          if (table_3f and workspace.exclude and not array_of_strings_3f(workspace.exclude)) then
            return workspace_error_message("workspace.exclude must be an array of strings")
          else
            if (table_3f and workspace.extensions and not extensions_3f(workspace.extensions)) then
              return workspace_error_message("workspace.extensions must be a non-empty list of strings starting with \".\"")
            else
              if invalid_optional_boolean_3f(workspace, "dotfiles") then
                return workspace_error_message("workspace.dotfiles must be a boolean")
              else
                if invalid_optional_boolean_3f(workspace, "symlinks") then
                  return workspace_error_message("workspace.symlinks must be a boolean")
                else
                  if invalid_optional_boolean_3f(workspace, "config") then
                    return workspace_error_message("workspace.config must be a boolean")
                  else
                    return nil
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
local function workspace_error(tbl)
  return validate_workspace_value(tbl.workspace, false, false)
end
local validate_workspace
do
  local function validate_workspace0(workspace, require_paths_3f)
    return validate_workspace_value(workspace, true, require_paths_3f)
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
  return (configuration_error(tbl) or workspace_error(tbl))
end
local function valid_table(tbl)
  return validation_result(tbl, validation_failure(tbl))
end
local function unknown_config_key(tbl)
  local allowed = {workspace = true, format = true, lint = true, design = true}
  local candidate = nil
  for key, _ in pairs(tbl) do
    if workspace_key_candidate_3f(allowed, candidate, key) then
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
  local failure = format_config["validate-fragment"](tbl)
  return validation_result(tbl, failure)
end
local validate
do
  local function validate0(tbl)
    if (type(tbl) ~= "table") then
      return nil, {message = "configuration must be a table"}
    else
      if ((rawget(tbl, "workspace") ~= nil) or (rawget(tbl, "format") ~= nil) or (rawget(tbl, "lint") ~= nil) or (rawget(tbl, "design") ~= nil)) then
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
  table.insert(result, core.assoc(core.assoc(exclusion, "rule", rule), "instance", index))
  return result
end
local function append_canonical_instance_exclusions(result, rule, index, instance)
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, exclusion in ipairs((instance.exclusions or {})) do
      local val_28_ = append_canonical_exclusion(result, rule, index, exclusion)
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
  end
  return result
end
local function append_canonical_rule_exclusions(result, rule, instances)
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for index, instance in ipairs((instances or {})) do
      local val_28_ = append_canonical_instance_exclusions(result, rule, index, instance)
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
  end
  return result
end
local function canonical_exclusions(rules)
  local result = {}
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for rule, instances in pairs(rules) do
      local val_28_ = append_canonical_rule_exclusions(result, rule, instances)
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
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
local function merge_design_rules(rules, design)
  local result = core.merge(rules)
  for rule, instances in pairs((design or {})) do
    if (result[rule] == nil) then
      result = core.assoc(result, rule, instances)
    else
      result = result
    end
  end
  return result
end
local function valid_lint_policy(cfg)
  local rules = core.merge(((cfg.lint and cfg.lint.rules) or {}))
  local design = (cfg.design and cfg.design.rules)
  return valid_lint_policy_result(cfg, merge_design_rules(rules, design), design)
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
  local function _47_()
    return parse_string(text)
  end
  ok, parsed_or_error = pcall(_47_)
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
