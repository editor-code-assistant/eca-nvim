-- [nfnl] fnl/fennel-extras/config/lint.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.config.lint"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.config.lint"]
end
local core = require("eca.nfnl.core")
local lint_rules = require("fennel-extras.lint.rules")
local registry = require("fennel-extras.lint.rules.registry")
local options = require("fennel-extras.lint.rules.options")
local parse = require("fennel-extras.config.parse")
local exclusion = require("fennel-extras.config.exclusion")
local sequence_3f = parse["sequence?"]
local function parsed_table_3f(value)
  local and_1_ = (type(value) == "table")
  if and_1_ then
    local metadata = getmetatable(value)
    and_1_ = (metadata and metadata["fennel-extras-table"])
  end
  return and_1_
end
local function lint_rule_known_3f(rule)
  return lint_rules.defaults()[rule]
end
local function lint_severity_3f(severity)
  return ((severity == "error") or (severity == "warning") or (severity == "off"))
end
local function positive_integer_3f(value)
  return ((type(value) == "number") and (value == math.floor(value)) and (value > 0))
end
local function option_known_3f(rule, option)
  return registry["option-schema"](rule)[option]
end
local function option_value_error(rule, option, value)
  local error = options.validate(rule, {[option] = value})
  return (error and not error.unknown and error)
end
local function unknown_option_error(rule, option)
  return {message = ("unknown option " .. tostring(option) .. " for lint rule " .. rule)}
end
local function first_option_error_step(rule, options0, next_key, next_value, recurse)
  if not option_known_3f(rule, next_key) then
    return unknown_option_error(rule, next_key)
  else
    return (option_value_error(rule, next_key, next_value) or recurse(rule, options0, next_key))
  end
end
local function first_option_error(rule, options0, key)
  local next_key, next_value = next(options0, key)
  if (next_key == nil) then
    return nil
  else
    return first_option_error_step(rule, options0, next_key, next_value, first_option_error)
  end
end
local function first_rule_map_key_step(rule, key, next_key, recurse)
  if ((next_key == "severity") or (next_key == "options") or (next_key == "exclusions")) then
    return recurse(rule, next_key)
  else
    return next_key
  end
end
local function first_rule_map_key(rule, key)
  local next_key = next(rule, key)
  if (next_key == nil) then
    return nil
  else
    return first_rule_map_key_step(rule, key, next_key, first_rule_map_key)
  end
end
local function lint_rule_severity_error(name, severity, options0, unknown)
  if ((severity == nil) and (options0 == nil) and (unknown == nil)) then
    return {message = ("lint rule " .. name .. " must be error, warning, or off")}
  else
    return {message = ("lint rule " .. name .. " severity must be error, warning, or off")}
  end
end
local function lint_rule_unknown_key_error(name, unknown)
  if unknown then
    return {message = ("lint rule " .. name .. ": unknown key " .. tostring(unknown))}
  else
    return nil
  end
end
local function lint_rule_options_type_error(name, options0)
  if (options0 and (type(options0) ~= "table")) then
    return {message = ("options for lint rule " .. name .. " must be a table")}
  else
    return nil
  end
end
local function lint_rule_options_error(name, options0)
  return (options0 and first_option_error(name, options0, nil))
end
local function lint_rule_severity_option_error(name, severity, options0, unknown)
  if not lint_severity_3f(severity) then
    return lint_rule_severity_error(name, severity, options0, unknown)
  else
    return nil
  end
end
local function per_rule_selector_3f(exclusions, index)
  if (index > #exclusions) then
    return false
  else
    return (exclusions[index].rule or exclusions[index].rules or per_rule_selector_3f(exclusions, (index + 1)))
  end
end
local function per_rule_exclusions_error(name, exclusions)
  if exclusions then
    local error = exclusion.validate(lint_rules.defaults(), exclusions)
    local or_12_ = error
    if not or_12_ then
      if per_rule_selector_3f(exclusions, 1) then
        or_12_ = {message = ("lint rule " .. name .. " exclusions cannot select a rule")}
      else
        or_12_ = nil
      end
    end
    return or_12_
  else
    return nil
  end
end
local function lint_rule_table_error(name, entry)
  local severity = entry.severity
  local options0 = entry.options
  local exclusions = entry.exclusions
  local unknown = first_rule_map_key(entry, nil)
  return (lint_rule_unknown_key_error(name, unknown) or lint_rule_severity_option_error(name, severity, options0, unknown) or lint_rule_options_type_error(name, options0) or lint_rule_options_error(name, options0) or per_rule_exclusions_error(name, exclusions))
end
local function lint_rule_invalid_entry_error(name, entry)
  if not lint_severity_3f(entry) then
    return {message = ("lint rule " .. name .. " must be error, warning, or off")}
  else
    return nil
  end
end
local function lint_rule_entry_error(name, entry)
  if (type(entry) == "table") then
    return lint_rule_table_error(name, entry)
  else
    return lint_rule_invalid_entry_error(name, entry)
  end
end
local function lint_key_sort_value(key)
  return (type(key) .. ":" .. tostring(key))
end
local function next_unknown_candidate(next_key, candidate)
  if ((candidate == nil) or (lint_key_sort_value(next_key) < lint_key_sort_value(candidate))) then
    return next_key
  else
    return candidate
  end
end
local function first_unknown_lint_key_step(lint, next_key, candidate, recurse)
  if ((next_key == "rules") or (next_key == "exclusions") or (next_key == "max-code-lines") or (next_key == "spec-files")) then
    return recurse(lint, next_key, candidate)
  else
    return recurse(lint, next_key, next_unknown_candidate(next_key, candidate))
  end
end
local function first_unknown_lint_key(lint, key, candidate)
  local next_key = next(lint, key)
  if (next_key == nil) then
    return candidate
  else
    return first_unknown_lint_key_step(lint, next_key, candidate, first_unknown_lint_key)
  end
end
local function unknown_lint_key_error(key)
  if key then
    return {message = ("unknown lint key: " .. tostring(key))}
  else
    return nil
  end
end
local function blank_3f(text)
  return (string.match(text, "^%s*$") == text)
end
local function first_lint_rule_error_step(rules, next_key, next_value, recurse)
  if not lint_rule_known_3f(next_key) then
    return {message = ("unknown lint rule: " .. tostring(next_key))}
  else
    return (lint_rule_entry_error(next_key, next_value) or recurse(rules, next_key))
  end
end
local function first_lint_rule_error(rules, key)
  local next_key, next_value = next(rules, key)
  if (next_key == nil) then
    return nil
  else
    return first_lint_rule_error_step(rules, next_key, next_value, first_lint_rule_error)
  end
end
local function next_exclusion_key_error(exclusion0, index, key, next_error)
  return next_error(exclusion0, index, next(exclusion0, key))
end
local function exclusion_keys_error(exclusion0, index, key)
  if (key == nil) then
    return nil
  else
    if ((key == "rule") or (key == "form") or (key == "reason")) then
      return next_exclusion_key_error(exclusion0, index, key, exclusion_keys_error)
    else
      return {message = ("lint exclusion " .. index .. ": unknown key " .. tostring(key))}
    end
  end
end
local function duplicate_exclusion_index_entry(exclusions, index, rule, form, candidate, entry, next_index)
  if ((entry.rule == rule) and (entry.form == form)) then
    return index
  else
    return next_index(exclusions, (index + 1), rule, form, candidate)
  end
end
local function duplicate_exclusion_index(exclusions, index, rule, form, candidate)
  if (index >= candidate) then
    return nil
  else
    return duplicate_exclusion_index_entry(exclusions, index, rule, form, candidate, exclusions[index], duplicate_exclusion_index)
  end
end
local function exclusion_duplicate_error(exclusions, index, duplicate, next_error)
  if duplicate then
    return {message = ("lint exclusion " .. index .. ": duplicate of exclusion " .. duplicate)}
  else
    return next_error(exclusions, (index + 1))
  end
end
local function exclusion_rule_known_error(exclusions, index, rule, form, reason, duplicate, next_error)
  if not lint_rule_known_3f(rule) then
    return {message = ("lint exclusion " .. index .. ": unknown rule " .. rule)}
  else
    return exclusion_duplicate_error(exclusions, index, duplicate, next_error)
  end
end
local function exclusion_reason_error(exclusions, index, rule, form, reason, duplicate, next_error)
  if blank_3f(reason) then
    return {message = ("lint exclusion " .. index .. ": reason must not be blank")}
  else
    return exclusion_rule_known_error(exclusions, index, rule, form, reason, duplicate, next_error)
  end
end
local function exclusion_form_error(exclusions, index, rule, form, reason, duplicate, next_error)
  if (type(reason) ~= "string") then
    return {message = ("lint exclusion " .. index .. ": reason must be a string")}
  else
    return exclusion_reason_error(exclusions, index, rule, form, reason, duplicate, next_error)
  end
end
local function exclusion_rule_error(exclusions, index, rule, form, reason, duplicate, next_error)
  if (type(form) ~= "string") then
    return {message = ("lint exclusion " .. index .. ": form must be a string")}
  else
    return exclusion_form_error(exclusions, index, rule, form, reason, duplicate, next_error)
  end
end
local function first_exclusion_error_entry(exclusions, index, exclusion0, next_error)
  local unknown_key = next(exclusion0, nil)
  local rule = exclusion0.rule
  local form = exclusion0.form
  local reason = exclusion0.reason
  local duplicate = duplicate_exclusion_index(exclusions, 1, rule, form, index)
  local or_32_ = exclusion_keys_error(exclusion0, index, unknown_key)
  if not or_32_ then
    if (type(rule) ~= "string") then
      or_32_ = {message = ("lint exclusion " .. index .. ": rule must be a string")}
    else
      or_32_ = exclusion_rule_error(exclusions, index, rule, form, reason, duplicate, next_error)
    end
  end
  return or_32_
end
local function first_exclusion_error(exclusions, index)
  local exclusion0 = exclusions[index]
  if (exclusion0 == nil) then
    return nil
  else
    if (type(exclusion0) ~= "table") then
      return {message = ("lint exclusion " .. index .. " must be a table")}
    else
      return first_exclusion_error_entry(exclusions, index, exclusion0, first_exclusion_error)
    end
  end
end
local function lint_max_code_lines_error(max_code_lines)
  if ((max_code_lines ~= nil) and not ((type(max_code_lines) == "number") and (max_code_lines == math.floor(max_code_lines)) and (max_code_lines > 0))) then
    return {message = "max-code-lines must be a positive integer"}
  else
    return nil
  end
end
local function nested_max_code_lines(rules)
  local entry = (rules and rules["file-size"])
  return ((type(entry) == "table") and (entry.options and entry.options["max-code-lines"]))
end
local function lint_max_code_lines_conflict_error(rules, max_code_lines)
  local nested = nested_max_code_lines(rules)
  if (max_code_lines and nested and (max_code_lines ~= nested)) then
    return {message = "lint max-code-lines conflicts with file-size option max-code-lines"}
  else
    return nil
  end
end
local function lint_table_error(rules, exclusions, max_code_lines, spec_files, unknown_key)
  local or_38_ = unknown_lint_key_error(unknown_key)
  if not or_38_ then
    if (rules and ((type(rules) ~= "table") or (sequence_3f(rules) and ((getmetatable(rules) ~= nil) or (#rules > 0))))) then
      or_38_ = {message = "lint rules must be a table"}
    else
      or_38_ = nil
    end
  end
  if not or_38_ then
    if rules then
      or_38_ = first_lint_rule_error(rules, nil)
    else
      or_38_ = nil
    end
  end
  return (or_38_ or lint_max_code_lines_error(max_code_lines) or lint_max_code_lines_conflict_error(rules, max_code_lines) or options["spec-files-error"](spec_files) or exclusion.validate(lint_rules.defaults(), exclusions))
end
local function append_exclusions(result, rule, entry)
  if ((type(entry) == "table") and entry.exclusions) then
    for _, value in ipairs(entry.exclusions) do
      local copy = {}
      for key, item in pairs(value) do
        copy[key] = item
      end
      table.insert(result, core.assoc(copy, "rule", rule))
    end
  else
  end
  return result
end
local exclusions
do
  local function exclusions0(rules)
    local result = {}
    for rule, entry in pairs(rules) do
      append_exclusions(result, rule, entry)
    end
    return result
  end
  _2amodule_2a["exclusions"] = exclusions0
  exclusions = _2amodule_2a.exclusions
end
local lint_error
do
  local function lint_error0(lint)
    if (type(lint) ~= "table") then
      return {message = "lint must be a table"}
    else
      local rules = lint.rules
      local exclusions0 = lint.exclusions
      local max_code_lines = lint["max-code-lines"]
      local spec_files = lint["spec-files"]
      local unknown_key = first_unknown_lint_key(lint, nil, nil)
      return lint_table_error(rules, exclusions0, max_code_lines, spec_files, unknown_key)
    end
  end
  _2amodule_2a["lint-error"] = lint_error0
  lint_error = _2amodule_2a["lint-error"]
end
return nil
