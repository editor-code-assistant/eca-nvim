-- [nfnl] fnl/fennel-extras/config/lint.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.config.lint"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.config.lint"]
end
local core = require("eca.nfnl.core")
local lint_rules = require("fennel-extras.lint.rules")
local parse = require("fennel-extras.config.parse")
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
local function lint_key_sort_value(key)
  return (type(key) .. ":" .. tostring(key))
end
local function first_unknown_lint_key(lint, key, candidate)
  local next_key = next(lint, key)
  if (next_key == nil) then
    return candidate
  else
    if ((next_key == "rules") or (next_key == "exclusions") or (next_key == "max-code-lines")) then
      return first_unknown_lint_key(lint, next_key, candidate)
    else
      if ((candidate == nil) or (lint_key_sort_value(next_key) < lint_key_sort_value(candidate))) then
        return first_unknown_lint_key(lint, next_key, next_key)
      else
        return first_unknown_lint_key(lint, next_key, candidate)
      end
    end
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
local function first_lint_rule_error(rules, key)
  local next_key, next_value = next(rules, key)
  if (next_key == nil) then
    return nil
  else
    if not lint_rule_known_3f(next_key) then
      return {message = ("unknown lint rule: " .. tostring(next_key))}
    else
      if not lint_severity_3f(next_value) then
        return {message = ("lint rule " .. tostring(next_key) .. " must be error, warning, or off")}
      else
        return first_lint_rule_error(rules, next_key)
      end
    end
  end
end
local function next_exclusion_key_error(exclusion, index, key, next_error)
  return next_error(exclusion, index, next(exclusion, key))
end
local function exclusion_keys_error(exclusion, index, key)
  if (key == nil) then
    return nil
  else
    if ((key == "rule") or (key == "form") or (key == "reason")) then
      return next_exclusion_key_error(exclusion, index, key, exclusion_keys_error)
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
local function first_exclusion_error_entry(exclusions, index, exclusion, next_error)
  local unknown_key = next(exclusion, nil)
  local rule = exclusion.rule
  local form = exclusion.form
  local reason = exclusion.reason
  local duplicate = duplicate_exclusion_index(exclusions, 1, rule, form, index)
  local or_19_ = exclusion_keys_error(exclusion, index, unknown_key)
  if not or_19_ then
    if (type(rule) ~= "string") then
      or_19_ = {message = ("lint exclusion " .. index .. ": rule must be a string")}
    else
      or_19_ = exclusion_rule_error(exclusions, index, rule, form, reason, duplicate, next_error)
    end
  end
  return or_19_
end
local function first_exclusion_error(exclusions, index)
  local exclusion = exclusions[index]
  if (exclusion == nil) then
    return nil
  else
    if (type(exclusion) ~= "table") then
      return {message = ("lint exclusion " .. index .. " must be a table")}
    else
      return first_exclusion_error_entry(exclusions, index, exclusion, first_exclusion_error)
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
local function lint_table_error(rules, exclusions, max_code_lines, unknown_key)
  local or_24_ = unknown_lint_key_error(unknown_key)
  if not or_24_ then
    if (rules and ((type(rules) ~= "table") or (sequence_3f(rules) and ((getmetatable(rules) ~= nil) or (#rules > 0))))) then
      or_24_ = {message = "lint rules must be a table"}
    else
      or_24_ = nil
    end
  end
  if not or_24_ then
    if rules then
      or_24_ = first_lint_rule_error(rules, nil)
    else
      or_24_ = nil
    end
  end
  or_24_ = or_24_ or lint_max_code_lines_error(max_code_lines)
  if not or_24_ then
    if (exclusions and not sequence_3f(exclusions)) then
      or_24_ = {message = "lint exclusions must be a list"}
    else
      or_24_ = nil
    end
  end
  if not or_24_ then
    if exclusions then
      or_24_ = first_exclusion_error(exclusions, 1)
    else
      or_24_ = nil
    end
  end
  return or_24_
end
local lint_error
do
  local function lint_error0(lint)
    if (type(lint) ~= "table") then
      return {message = "lint must be a table"}
    else
      local rules = lint.rules
      local exclusions = lint.exclusions
      local max_code_lines = lint["max-code-lines"]
      local unknown_key = first_unknown_lint_key(lint, nil, nil)
      return lint_table_error(rules, exclusions, max_code_lines, unknown_key)
    end
  end
  _2amodule_2a["lint-error"] = lint_error0
  lint_error = _2amodule_2a["lint-error"]
end
return nil
