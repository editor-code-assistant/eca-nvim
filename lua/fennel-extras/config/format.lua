-- [nfnl] fnl/fennel-extras/config/format.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.config.format"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.config.format"]
end
local alignment = require("fennel-extras.indent.settings")
local function integer_3f(value)
  return ((type(value) == "number") and (value == math.floor(value)))
end
local function every_ipairs_3f(predicate, value, index)
  local item = value[index]
  if (item == nil) then
    return true
  else
    return (predicate(item) and every_ipairs_3f(predicate, value, (index + 1)))
  end
end
local function string_3f(value)
  return (type(value) == "string")
end
local function dotted_string_3f(value)
  return (string.sub(value, 1, 1) == ".")
end
local function array_of_strings_3f(value)
  return ((type(value) == "table") and (#value > 0) and every_ipairs_3f(string_3f, value, 1))
end
local function boolean_3f(value)
  return ((value == true) or (value == false))
end
local function extensions_3f(value)
  return (array_of_strings_3f(value) and every_ipairs_3f(dotted_string_3f, value, 1))
end
local function block_rule_3f(value)
  return ((value[1] == "block") and integer_3f(value[2]) and (value[2] >= 0) and (value[3] == nil))
end
local function inner_rule_3f(value)
  return ((value[1] == "inner") and (value[2] == 0) and ((value[3] == nil) or (integer_3f(value[3]) and (value[3] >= 0))))
end
local function rule_3f(value)
  return ((type(value) == "table") and (type(value[1]) == "string") and (block_rule_3f(value) or inner_rule_3f(value)))
end
local function rule_list_3f(value)
  return ((type(value) == "table") and every_ipairs_3f(rule_3f, value, 1))
end
local function rule_map_entries_3f(value, key)
  local next_key, next_value = next(value, key)
  if (next_key == nil) then
    return true
  else
    return ((type(next_key) == "string") and rule_list_3f(next_value) and rule_map_entries_3f(value, next_key))
  end
end
local function rule_map_3f(value)
  return ((type(value) == "table") and rule_map_entries_3f(value, nil))
end
local function missing(path)
  return {message = ("missing " .. path)}
end
local function required(config, key, path)
  if (config[key] == nil) then
    return missing(path)
  else
    return nil
  end
end
local function validate_builtins(config)
  local value = config.builtins
  if ((value ~= nil) and (value ~= false) and not rule_map_3f(value)) then
    return {message = "builtins must be a map or false"}
  else
    return nil
  end
end
local function validate_prefix_fallbacks(config)
  local value = config["prefix-fallbacks"]
  if ((value ~= nil) and (value ~= false) and not rule_map_3f(value)) then
    return {message = "prefix-fallbacks must be a map or false"}
  else
    return nil
  end
end
local function invalid_width_3f(width, strict_3f)
  return ((strict_3f or (width ~= nil)) and not (integer_3f(width) and (width > 0)))
end
local function invalid_extensions_3f(config, require_scan_3f)
  return ((require_scan_3f or (config.extensions ~= nil)) and not extensions_3f(config.extensions))
end
local function invalid_parser_3f(parser, strict_3f)
  return ((strict_3f or (parser ~= nil)) and (parser ~= false) and (type(parser) ~= "string"))
end
local function invalid_boolean_3f(value)
  return ((value ~= nil) and not boolean_3f(value))
end
local function validate_values(config, require_scan_3f, strict_3f)
  local width = config["indent-width"]
  local parser = config.parser
  local skip_dotfiles = config["skip-dotfiles"]
  local follow_symlinks = config["follow-symlinks"]
  return ((invalid_width_3f(width, strict_3f) and {message = "indent-width must be a positive integer"}) or (invalid_extensions_3f(config, require_scan_3f) and {message = "extensions must be a non-empty list of strings starting with \".\""}) or (invalid_parser_3f(parser, strict_3f) and {message = "parser must be a string or false"}) or (invalid_boolean_3f(skip_dotfiles) and {message = "skip-dotfiles must be a boolean"}) or (invalid_boolean_3f(follow_symlinks) and {message = "follow-symlinks must be a boolean"}))
end
local function missing_binding_forms(value)
  if ((value.bindings or value["split-bindings"]) and (value["binding-forms"] == nil)) then
    return missing("alignment.binding-forms")
  else
    return nil
  end
end
local function missing_clause_forms(value)
  if (value.clauses and (value["clause-forms"] == nil)) then
    return missing("alignment.clause-forms")
  else
    return nil
  end
end
local function validate_alignment(config)
  local value = config.alignment
  return (alignment.validate(value) or (value and (missing_binding_forms(value) or missing_clause_forms(value))))
end
local function newline_instance_3f(value)
  return ((type(value) == "table") and (type(value["applies-to"]) == "table") and ((value["applies-to"].forms == nil) or array_of_strings_3f(value["applies-to"].forms)) and (type(value.options) == "table") and ((value.options.after == nil) or (integer_3f(value.options.after) and (value.options.after >= 0))) and ((value.options.before == nil) or (integer_3f(value.options.before) and (value.options.before >= 0))))
end
local function validate_newline(config)
  local value = config.newline
  if ((value ~= nil) and not ((type(value) == "table") and every_ipairs_3f(newline_instance_3f, value, 1))) then
    return {message = "newline must be a list of instances"}
  else
    return nil
  end
end
local function validate_extensions(config)
  return (((config.extensions == nil) and missing("extensions")) or ((config.extensions ~= nil) and not extensions_3f(config.extensions) and {message = "extensions must be a non-empty list of strings starting with \".\""}))
end
local function validate_paths(config, require_paths_3f)
  return ((require_paths_3f and (config.paths == nil) and missing("paths")) or (config.paths and not array_of_strings_3f(config.paths) and {message = "paths must be an array of strings"}))
end
local validate_scan
do
  local function validate_scan0(config, require_paths_3f)
    return (validate_extensions(config) or validate_paths(config, require_paths_3f))
  end
  _2amodule_2a["validate-scan"] = validate_scan0
  validate_scan = _2amodule_2a["validate-scan"]
end
local function validate_table(config, require_paths_3f, require_scan_3f, strict_3f)
  return ((strict_3f and required(config, "indent-width", "indent-width")) or (strict_3f and required(config, "builtins", "builtins")) or (strict_3f and required(config, "prefix-fallbacks", "prefix-fallbacks")) or (strict_3f and required(config, "parser", "parser")) or (require_scan_3f and required(config, "extensions", "extensions")) or (require_paths_3f and required(config, "paths", "paths")) or validate_builtins(config) or validate_prefix_fallbacks(config) or validate_values(config, require_scan_3f, strict_3f) or validate_alignment(config) or validate_newline(config))
end
local validate
do
  local function validate0(config, require_paths_3f, require_scan_3f, strict_3f)
    if (type(config) == "table") then
      return validate_table(config, require_paths_3f, require_scan_3f, strict_3f)
    else
      return {message = "configuration must be a table"}
    end
  end
  _2amodule_2a["validate"] = validate0
  validate = _2amodule_2a.validate
end
return nil
