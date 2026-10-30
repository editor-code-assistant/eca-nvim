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
    if (value.modules and not ((type(value.modules) == "string") or canonical_sequence_of_strings_3f(value.modules))) then
      or_11_ = {message = (path .. ".modules must be a string or list of strings")}
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
local function canonical_legacy_selector_error(instance, path)
  local options0 = instance.options
  if ((type(options0) == "table") and ((options0.forms ~= nil) or (options0.module ~= nil) or (options0.modules ~= nil))) then
    return {message = (path .. ": forms, module, and modules must be under applies-to")}
  else
    return nil
  end
end
local function canonical_missing_option_step(section, name, index, option_values, names, option_index)
  if (option_index > #names) then
    return nil
  else
    local option_name = names[option_index]
    return (((option_values[option_name] == nil) and {message = ("missing " .. section .. ".rules." .. name .. "[" .. index .. "].options." .. option_name)}) or canonical_missing_option_step(section, name, index, option_values, names, (option_index + 1)))
  end
end
local function canonical_missing_applies_step(section, name, index, applies, options0, names, option_index)
  if (option_index > #names) then
    return nil
  else
    local option_name = names[option_index]
    local key
    if (option_name == "module") then
      key = "modules"
    else
      if (option_name == "modules") then
        key = "modules"
      else
        key = "forms"
      end
    end
    return (((applies[key] == nil) and {message = ("missing " .. section .. ".rules." .. name .. "[" .. index .. "].applies-to." .. tostring(key))}) or canonical_missing_applies_step(section, name, index, applies, options0, names, (option_index + 1)))
  end
end
local function canonical_missing_option_error(section, name, index, instance)
  if (instance.severity ~= "off") then
    if (name == "module-import") then
      local or_30_ = canonical_missing_option_step(section, name, index, instance.options, {"mode"}, 1)
      if not or_30_ then
        if (instance.options.mode == "require") then
          if instance["applies-to"].forms then
            or_30_ = canonical_missing_applies_step(section, name, index, instance["applies-to"], instance.options, {"module"}, 1)
          else
            or_30_ = (canonical_missing_applies_step(section, name, index, instance["applies-to"], instance.options, {"module"}, 1) or canonical_missing_option_step(section, name, index, instance.options, {"binding"}, 1))
          end
        else
          or_30_ = canonical_missing_applies_step(section, name, index, instance["applies-to"], instance.options, {"modules"}, 1)
        end
      end
      return or_30_
    else
      local or_33_ = canonical_missing_option_step(section, name, index, instance.options, registry["required-option-names"](name), 1)
      if not or_33_ then
        local names
        if (name == "module-style") then
          names = {"module"}
        else
          names = registry["applies-to-required-names"](name)
        end
        or_33_ = (names and canonical_missing_applies_step(section, name, index, instance["applies-to"], instance.options, names, 1))
      end
      return or_33_
    end
  else
    return nil
  end
end
local function canonical_instance_error(section, name, index, instance)
  local path = (section .. ".rules." .. name .. "[" .. index .. "]")
  local _38_
  if (type(instance) ~= "table") then
    _38_ = {message = (path .. " must be a table")}
  else
    _38_ = nil
  end
  local or_40_ = _38_ or canonical_map_keys_error(instance, path, {severity = true, ["applies-to"] = true, options = true, exclusions = true})
  if not or_40_ then
    if not ((instance.severity == "error") or (instance.severity == "warning") or (instance.severity == "off")) then
      or_40_ = {message = (path .. ".severity must be error, warning, or off")}
    else
      or_40_ = nil
    end
  end
  or_40_ = or_40_ or canonical_applies_to_error(instance["applies-to"], (path .. ".applies-to"))
  if not or_40_ then
    if (type(instance.options) ~= "table") then
      or_40_ = {message = (path .. ".options must be a table")}
    else
      or_40_ = nil
    end
  end
  return (or_40_ or canonical_options_error(name, instance.options, (path .. ".options")) or canonical_legacy_selector_error(instance, (path .. ".options")) or canonical_missing_option_error(section, name, index, instance) or canonical_exclusions_error(instance.exclusions, (path .. ".exclusions")))
end
local function canonical_rule_error_step(rules, key, candidate)
  if ((candidate == nil) or (tostring(key) < tostring(candidate))) then
    return key
  else
    return candidate
  end
end
local function canonical_rules_error(section, rules)
  local _44_
  if (type(rules) ~= "table") then
    _44_ = {message = (section .. ".rules must be a table")}
  else
    _44_ = nil
  end
  local or_46_ = _44_
  if not or_46_ then
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
      local allowed
      if (section == "design") then
        allowed = registry["design-rule-names"]()
      else
        allowed = registry["lint-rule-names"]()
      end
      if (type(name) ~= "string") then
        or_46_ = {message = ("unknown " .. section .. " rule: " .. tostring(name))}
      else
        local _50_
        do
          local found = false
          for _, allowed_name in ipairs(allowed) do
            found = (found or (allowed_name == name))
          end
          _50_ = found
        end
        if not _50_ then
          or_46_ = {message = ("unknown " .. section .. " rule: " .. name)}
        else
          if not (sequence_3f(instances) and (#instances > 0)) then
            or_46_ = {message = (section .. ".rules." .. name .. " must be a non-empty vector")}
          else
            local failure = nil
            for index, instance in ipairs(instances) do
              if (failure == nil) then
                failure = canonical_instance_error(section, name, index, instance)
              else
              end
            end
            or_46_ = failure
          end
        end
      end
    else
      or_46_ = nil
    end
  end
  return or_46_
end
local function canonical_section_error(section, value)
  local _57_
  if (type(value) ~= "table") then
    _57_ = {message = (section .. " must be a table")}
  else
    _57_ = nil
  end
  return (_57_ or canonical_contract_key_error(value, {rules = true}, ("unknown " .. section .. " key: ")) or canonical_rules_error(section, value.rules))
end
local lint_error
do
  local function lint_error0(lint)
    return canonical_section_error("lint", lint)
  end
  _2amodule_2a["lint-error"] = lint_error0
  lint_error = _2amodule_2a["lint-error"]
end
local design_error
do
  local function design_error0(design)
    return canonical_section_error("design", design)
  end
  _2amodule_2a["design-error"] = design_error0
  design_error = _2amodule_2a["design-error"]
end
return nil
