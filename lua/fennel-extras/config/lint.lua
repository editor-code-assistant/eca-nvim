-- [nfnl] fnl/fennel-extras/config/lint.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.config.lint"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.config.lint"]
end
local registry = require("fennel-extras.lint.rules.registry")
local options = require("fennel-extras.lint.rules.options")
local parse = require("fennel-extras.config.parse")
local sequence_3f = parse["sequence?"]
local function canonical_sequence_of_strings_3f(value)
  local and_1_ = sequence_3f(value)
  if and_1_ then
    local valid = true
    for _, item in ipairs(value) do
      if (type(item) ~= "string") then
        valid = false
      else
      end
    end
    and_1_ = valid
  end
  return and_1_
end
local function sorted_unknown_key(value, allowed)
  local candidate = nil
  for key, _ in pairs(value) do
    if (not allowed[key] and ((candidate == nil) or (tostring(key) < tostring(candidate)))) then
      candidate = key
    else
      candidate = candidate
    end
  end
  return candidate
end
local function canonical_map_keys_error(value, path, allowed)
  if (type(value) == "table") then
    local key = sorted_unknown_key(value, allowed)
    if key then
      return {message = (path .. "." .. tostring(key) .. ": unknown key")}
    else
      return nil
    end
  else
    return nil
  end
end
local function canonical_contract_key_error(value, allowed, prefix)
  if (type(value) == "table") then
    local key = sorted_unknown_key(value, allowed)
    if key then
      return {message = (prefix .. tostring(key))}
    else
      return nil
    end
  else
    return nil
  end
end
local function canonical_applies_to_error(value, path)
  local _9_
  if (type(value) ~= "table") then
    _9_ = {message = (path .. " must be a table")}
  else
    _9_ = nil
  end
  local or_11_ = _9_ or canonical_contract_key_error(value, {files = true, forms = true, modules = true}, "unknown applies-to key: ")
  if not or_11_ then
    if (value.files and not canonical_sequence_of_strings_3f(value.files)) then
      or_11_ = {message = (path .. ".files must be a list of strings")}
    else
      or_11_ = nil
    end
  end
  if not or_11_ then
    if (value.forms and not canonical_sequence_of_strings_3f(value.forms)) then
      or_11_ = {message = (path .. ".forms must be a list of strings")}
    else
      or_11_ = nil
    end
  end
  if not or_11_ then
    if (value.modules and not canonical_sequence_of_strings_3f(value.modules)) then
      or_11_ = {message = (path .. ".modules must be a list of strings")}
    else
      or_11_ = nil
    end
  end
  return or_11_
end
local function canonical_exclusions_error(value, path)
  local _15_
  if not sequence_3f(value) then
    _15_ = {message = (path .. " must be a list")}
  else
    _15_ = nil
  end
  local or_17_ = _15_
  if not or_17_ then
    local failure = nil
    for index, exclusion in ipairs(value) do
      if (failure == nil) then
        if (type(exclusion) ~= "table") then
          failure = {message = (path .. "[" .. index .. "] must be a table")}
        else
          local unknown = canonical_map_keys_error(exclusion, (path .. "[" .. index .. "]"), {path = true, reason = true})
          if unknown then
            failure = unknown
          else
            if ((type(exclusion.path) ~= "string") or (type(exclusion.reason) ~= "string")) then
              failure = {message = (path .. "[" .. index .. "] requires string path and reason")}
            else
            end
          end
        end
      else
      end
    end
    or_17_ = failure
  end
  return or_17_
end
local function canonical_options_error(name, option_values, path)
  if (type(option_values) == "table") then
    local error = options.validate(name, option_values)
    if error then
      return {message = (path .. ": " .. error.message)}
    else
      return nil
    end
  else
    return nil
  end
end
local function canonical_missing_option_step(name, index, option_values, names, option_index)
  if (option_index > #names) then
    return nil
  else
    local option_name = names[option_index]
    return (((option_values[option_name] == nil) and {message = ("missing lint.rules." .. name .. "[" .. index .. "].options." .. option_name)}) or canonical_missing_option_step(name, index, option_values, names, (option_index + 1)))
  end
end
local function canonical_missing_option_error(name, index, instance)
  if (instance.severity ~= "off") then
    if (name == "module-import") then
      local or_26_ = canonical_missing_option_step(name, index, instance.options, {"mode"}, 1)
      if not or_26_ then
        if (instance.options.mode == "require") then
          if instance.options.forms then
            or_26_ = canonical_missing_option_step(name, index, instance.options, {"module"}, 1)
          else
            or_26_ = canonical_missing_option_step(name, index, instance.options, {"module", "binding"}, 1)
          end
        else
          or_26_ = canonical_missing_option_step(name, index, instance.options, {"modules", "exempt-files"}, 1)
        end
      end
      return or_26_
    else
      return canonical_missing_option_step(name, index, instance.options, registry["required-option-names"](name), 1)
    end
  else
    return nil
  end
end
local function canonical_instance_error(name, index, instance)
  local path = ("lint.rules." .. name .. "[" .. index .. "]")
  local _31_
  if (type(instance) ~= "table") then
    _31_ = {message = (path .. " must be a table")}
  else
    _31_ = nil
  end
  local or_33_ = _31_ or canonical_map_keys_error(instance, path, {severity = true, ["applies-to"] = true, options = true, exclusions = true})
  if not or_33_ then
    if not ((instance.severity == "error") or (instance.severity == "warning") or (instance.severity == "off")) then
      or_33_ = {message = (path .. ".severity must be error, warning, or off")}
    else
      or_33_ = nil
    end
  end
  or_33_ = or_33_ or canonical_applies_to_error(instance["applies-to"], (path .. ".applies-to"))
  if not or_33_ then
    if (type(instance.options) ~= "table") then
      or_33_ = {message = (path .. ".options must be a table")}
    else
      or_33_ = nil
    end
  end
  return (or_33_ or canonical_options_error(name, instance.options, (path .. ".options")) or canonical_missing_option_error(name, index, instance) or canonical_exclusions_error(instance.exclusions, (path .. ".exclusions")))
end
local function canonical_rule_error_step(rules, key, candidate)
  if ((candidate == nil) or (tostring(key) < tostring(candidate))) then
    return key
  else
    return candidate
  end
end
local function canonical_rules_error(rules)
  local _37_
  if (type(rules) ~= "table") then
    _37_ = {message = "lint.rules must be a table"}
  else
    _37_ = nil
  end
  local or_39_ = _37_
  if not or_39_ then
    local name
    do
      local candidate = nil
      for key, _ in pairs(rules) do
        candidate = canonical_rule_error_step(rules, key, candidate)
      end
      name = candidate
    end
    if name then
      local instances = rules[name]
      if (type(name) ~= "string") then
        or_39_ = {message = ("lint.rules." .. tostring(name) .. ": rule key must be a keyword")}
      else
        if (registry.defaults()[name] == nil) then
          or_39_ = {message = ("unknown lint rule: " .. name)}
        else
          if not (sequence_3f(instances) and (#instances > 0)) then
            or_39_ = {message = ("lint.rules." .. name .. " must be a non-empty vector")}
          else
            local failure = nil
            for index, instance in ipairs(instances) do
              if (failure == nil) then
                failure = canonical_instance_error(name, index, instance)
              else
              end
            end
            or_39_ = failure
          end
        end
      end
    else
      or_39_ = nil
    end
  end
  return or_39_
end
local function canonical_lint_error(lint)
  local _48_
  if (type(lint) ~= "table") then
    _48_ = {message = "lint must be a table"}
  else
    _48_ = nil
  end
  return (_48_ or canonical_contract_key_error(lint, {rules = true}, "unknown lint key: ") or canonical_rules_error(lint.rules))
end
local lint_error
do
  local function lint_error0(lint)
    return canonical_lint_error(lint)
  end
  _2amodule_2a["lint-error"] = lint_error0
  lint_error = _2amodule_2a["lint-error"]
end
return nil
