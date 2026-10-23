-- [nfnl] fnl/fennel-extras/config/exclusion.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.config.exclusion"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.config.exclusion"]
end
local core = require("eca.nfnl.core")
local parse = require("fennel-extras.config.parse")
local sequence_3f = parse["sequence?"]
local function blank_3f(text)
  return (string.match(text, "^%s*$") == text)
end
local function positive_integer_3f(value)
  return ((type(value) == "number") and (value == math.floor(value)) and (value > 0))
end
local function known_rule_3f(rules, rule)
  return rules[rule]
end
local function known_exclusion_key_3f(key)
  return ((key == "rule") or (key == "rules") or (key == "pattern") or (key == "line") or (key == "lines") or (key == "code") or (key == "form") or (key == "reason"))
end
local function first_unknown_key_step(entry, key)
  local next_key = next(entry, key)
  return (next_key and ((known_exclusion_key_3f(next_key) and first_unknown_key_step(entry, next_key)) or (not known_exclusion_key_3f(next_key) and next_key)))
end
local function first_unknown_key(entry, key)
  return first_unknown_key_step(entry, key)
end
local function selector_value(entry, key)
  if entry[key] then
    return 1
  else
    return 0
  end
end
local function selector_count(entry)
  return (selector_value(entry, "pattern") + selector_value(entry, "line") + selector_value(entry, "lines") + selector_value(entry, "code") + selector_value(entry, "form"))
end
local function rule_list_error_value(rules, index, names, name)
  if not known_rule_3f(rules, name) then
    return {message = ("lint exclusion " .. index .. ": unknown rule " .. name)}
  else
    return (((index + 1) <= #names) and rule_list_error_value(rules, (index + 1), names, names[(index + 1)]))
  end
end
local function rule_list_error_step(rules, index, names)
  if (index > #names) then
    return nil
  else
    return rule_list_error_value(rules, index, names, names[index])
  end
end
local function rule_list_error(rules, index, names)
  return rule_list_error_step(rules, index, names)
end
local function invalid_line_range_3f(lines)
  return ((type(lines) ~= "table") or not positive_integer_3f(lines.from) or not positive_integer_3f(lines.to) or (lines.from > lines.to))
end
local function line_range_error(index, entry)
  local lines = entry.lines
  if (lines and invalid_line_range_3f(lines)) then
    return {message = ("lint exclusion " .. index .. ": lines must have positive from/to with from <= to")}
  else
    return nil
  end
end
local function invalid_line_error(index, entry)
  if (entry.line and not positive_integer_3f(entry.line)) then
    return {message = ("lint exclusion " .. index .. ": line must be a positive integer")}
  else
    return nil
  end
end
local function exclusive_selector_error(index, entry)
  if (entry.line and entry.lines) then
    return {message = ("lint exclusion " .. index .. ": line and lines are mutually exclusive")}
  else
    return nil
  end
end
local function missing_selector_error(index, entry)
  if (selector_count(entry) == 0) then
    return {message = ("lint exclusion " .. index .. ": at least one selector is required")}
  else
    return nil
  end
end
local function selector_error(index, entry)
  return (invalid_line_error(index, entry) or line_range_error(index, entry) or exclusive_selector_error(index, entry) or missing_selector_error(index, entry))
end
local function string_field_error(index, entry, key)
  local value = entry[key]
  if (value and (type(value) ~= "string")) then
    return {message = ("lint exclusion " .. index .. ": " .. tostring(key) .. " must be a string")}
  else
    return nil
  end
end
local function rules_field_error(rules, index, entry)
  local names = entry.rules
  if (names and (not sequence_3f(names) or (#names == 0))) then
    return {message = ("lint exclusion " .. index .. ": rules must be a non-empty list")}
  else
    return nil
  end
end
local function rules_name_error(rules, index, entry)
  local names = entry.rules
  if (names and sequence_3f(names) and (#names > 0)) then
    return rule_list_error(rules, 1, names)
  else
    return nil
  end
end
local function invalid_rule_error(index, entry)
  if (entry.rule and (type(entry.rule) ~= "string")) then
    return {message = ("lint exclusion " .. index .. ": rule must be a string")}
  else
    return nil
  end
end
local function exclusive_rule_error(index, entry)
  if (entry.rule and entry.rules) then
    return {message = ("lint exclusion " .. index .. ": rule and rules are mutually exclusive")}
  else
    return nil
  end
end
local function unknown_rule_error(rules, index, entry)
  if (entry.rule and not known_rule_3f(rules, entry.rule)) then
    return {message = ("lint exclusion " .. index .. ": unknown rule " .. entry.rule)}
  else
    return nil
  end
end
local function rule_field_error(rules, index, entry)
  return (invalid_rule_error(index, entry) or exclusive_rule_error(index, entry) or unknown_rule_error(rules, index, entry) or rules_field_error(rules, index, entry) or rules_name_error(rules, index, entry))
end
local function invalid_reason_error(index, entry)
  if (entry.reason and (type(entry.reason) ~= "string")) then
    return {message = ("lint exclusion " .. index .. ": reason must be a string")}
  else
    return nil
  end
end
local function blank_reason_error(index, entry)
  if (entry.reason and blank_3f(entry.reason)) then
    return {message = ("lint exclusion " .. index .. ": reason must not be blank")}
  else
    return nil
  end
end
local function reason_error(index, entry)
  return (invalid_reason_error(index, entry) or blank_reason_error(index, entry))
end
local function unknown_entry_key_error(index, entry)
  local unknown = first_unknown_key(entry, nil)
  if unknown then
    return {message = ("lint exclusion " .. index .. ": unknown key " .. tostring(unknown))}
  else
    return nil
  end
end
local function entry_error(rules, index, entry)
  return (unknown_entry_key_error(index, entry) or rule_field_error(rules, index, entry) or string_field_error(index, entry, "pattern") or string_field_error(index, entry, "code") or string_field_error(index, entry, "form") or reason_error(index, entry) or selector_error(index, entry))
end
local function lines_equal_values_3f(left, right)
  return (left and right and (left.from == right.from) and (left.to == right.to))
end
local function lines_equal_3f(left, right)
  return ((left == right) or lines_equal_values_3f(left, right))
end
local function duplicate_3f(candidate, entry)
  return ((candidate.rule == entry.rule) and (candidate.rules == entry.rules) and (candidate.form == entry.form) and (candidate.pattern == entry.pattern) and (candidate.line == entry.line) and lines_equal_3f(candidate.lines, entry.lines) and (candidate.code == entry.code))
end
local function duplicate_index_value(exclusions, index, entry, prior, candidate)
  if duplicate_3f(candidate, entry) then
    return prior
  else
    return (((prior + 1) < index) and duplicate_index_value(exclusions, index, entry, (prior + 1), exclusions[(prior + 1)]))
  end
end
local function duplicate_index_step(exclusions, index, entry, prior)
  if (prior >= index) then
    return nil
  else
    return duplicate_index_value(exclusions, index, entry, prior, exclusions[prior])
  end
end
local function duplicate_index(exclusions, index, entry, prior)
  return duplicate_index_step(exclusions, index, entry, prior)
end
local function duplicate_error(exclusions, index, entry)
  local duplicate = duplicate_index(exclusions, index, entry, 1)
  if duplicate then
    return {message = ("lint exclusion " .. index .. ": duplicate of exclusion " .. duplicate)}
  else
    return nil
  end
end
local function invalid_entry_error(index, entry)
  if (type(entry) ~= "table") then
    return {message = ("lint exclusion " .. index .. " must be a table")}
  else
    return nil
  end
end
local function entry_validation_error(rules, exclusions, index, entry)
  return (invalid_entry_error(index, entry) or entry_error(rules, index, entry) or duplicate_error(exclusions, index, entry))
end
local function first_error(rules, exclusions, index)
  local entry = exclusions[index]
  if (entry == nil) then
    return nil
  else
    return (entry_validation_error(rules, exclusions, index, entry) or first_error(rules, exclusions, (index + 1)))
  end
end
local function validate_list(rules, exclusions)
  return first_error(rules, exclusions, 1)
end
local function invalid_list_error(exclusions)
  if not sequence_3f(exclusions) then
    return {message = "lint exclusions must be a list"}
  else
    return nil
  end
end
local function validate_value(rules, exclusions)
  return (invalid_list_error(exclusions) or validate_list(rules, exclusions))
end
local validate
do
  local function validate0(rules, exclusions)
    if exclusions then
      return validate_value(rules, exclusions)
    else
      return nil
    end
  end
  _2amodule_2a["validate"] = validate0
  validate = _2amodule_2a.validate
end
local function copy_entry(entry, rule)
  local result = {}
  for key, value in pairs(entry) do
    result[key] = value
  end
  if rule then
    return core.assoc(result, "rule", rule)
  else
    return result
  end
end
local function append_rule_exclusions(result, rule, entry)
  for _, exclusion in ipairs((entry.exclusions or {})) do
    table.insert(result, copy_entry(exclusion, rule))
  end
  return result
end
local function normalize_entry(result, rule, entry)
  if (type(entry) == "table") then
    return append_rule_exclusions(result, rule, entry)
  else
    return nil
  end
end
local function normalize_rules(rules, result)
  for rule, entry in pairs(rules) do
    normalize_entry(result, rule, entry)
  end
  return result
end
local normalize
do
  local function normalize0(rules)
    return normalize_rules(rules, {})
  end
  _2amodule_2a["normalize"] = normalize0
  normalize = _2amodule_2a.normalize
end
return nil
