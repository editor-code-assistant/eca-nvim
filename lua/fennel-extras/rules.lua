-- [nfnl] fnl/fennel-extras/rules.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.rules"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.rules"]
end
local alignment = require("fennel-extras.indent.settings")
local allowed_keys = {indents = true, ["format-as"] = true, ["indent-width"] = true, alignment = true}
local default_rules = {def = {{"inner", 0}}, ["def-"] = {{"inner", 0}}, defn = {{"inner", 0}}, ["defn-"] = {{"inner", 0}}}
local resolve_name = nil
local alias_rule = nil
local function error(message)
  return {message = message}
end
local function integer_3f(value)
  return ((type(value) == "number") and (value == math.floor(value)))
end
local function validate_rule(rule)
  if ((type(rule) == "table") and (type(rule[1]) == "string")) then
    local kind = rule[1]
    local value = rule[2]
    local index = rule[3]
    if (kind == "block") then
      if (integer_3f(value) and (value >= 0) and (index == nil)) then
        return nil
      else
        return error("invalid block rule")
      end
    else
      if (kind == "inner") then
        if ((value == 0) and ((index == nil) or (integer_3f(index) and (index >= 0)))) then
          return nil
        else
          return error("invalid inner rule")
        end
      else
        return error("unknown indentation rule")
      end
    end
  else
    return error("invalid indentation rule")
  end
end
local function validate_rule_items(value)
  local failure = nil
  for _, rule in ipairs(value) do
    if (failure == nil) then
      failure = validate_rule(rule)
    else
    end
  end
  return failure
end
local function validate_rule_list(value)
  if (type(value) == "table") then
    return validate_rule_items(value)
  else
    return error("indentation rules must be a list")
  end
end
local function validate_map_items(items, rules_3f)
  local failure = nil
  for name, value in pairs(items) do
    if (failure == nil) then
      if (type(name) ~= "string") then
        failure = error("indentation names must be strings")
      else
        if rules_3f then
          failure = validate_rule_list(value)
        else
          if (type(value) ~= "string") then
            failure = error("format-as targets must be strings")
          else
          end
        end
      end
    else
    end
  end
  return failure
end
local function validate_map(items, rules_3f)
  if (items == nil) then
    return nil
  else
    if (type(items) == "table") then
      return validate_map_items(items, rules_3f)
    else
      return error("indentation configuration must be a table")
    end
  end
end
local function _14_(config, name, seen)
  local indents = (config.indents or {})
  local aliases = (config["format-as"] or {})
  if indents[name] then
    return indents[name], nil, true
  else
    if aliases[name] then
      return alias_rule(config, name, seen)
    else
      if default_rules[name] then
        return default_rules[name], nil, true
      else
        return nil, nil, false
      end
    end
  end
end
resolve_name = _14_
local function _18_(config, name, seen)
  if seen[name] then
    return nil, error("format-as alias cycle")
  else
    local target = config["format-as"][name]
    seen[name] = true
    local rule, err, found = resolve_name(config, target, seen)
    seen[name] = nil
    if err then
      return nil, err
    else
      if found then
        return rule, nil, true
      else
        return nil, error("format-as target has no indentation rule")
      end
    end
  end
end
alias_rule = _18_
local function validate_alignment(config)
  return alignment.validate(config.alignment)
end
local function validate_config_table(config)
  local failure = nil
  for key, _ in pairs(config) do
    if ((failure == nil) and not allowed_keys[key]) then
      failure = error("unknown indentation configuration key")
    else
    end
  end
  if (failure == nil) then
    failure = validate_map(config.indents, true)
  else
  end
  if (failure == nil) then
    failure = validate_map(config["format-as"], false)
  else
  end
  if (failure == nil) then
    local width = config["indent-width"]
    if ((width ~= nil) and not (integer_3f(width) and (width > 0))) then
      failure = error("indent-width must be a positive integer")
    else
    end
  else
  end
  if (failure == nil) then
    failure = validate_alignment(config)
  else
  end
  if (failure == nil) then
    for name, _ in pairs((config["format-as"] or {})) do
      if (failure == nil) then
        local _0, err = resolve_name(config, name, {})
        if err then
          failure = err
        else
        end
      else
      end
    end
  else
  end
  if (failure == nil) then
    for name, _ in pairs((config.indents or {})) do
      if ((failure == nil) and (config["format-as"] or {})[name]) then
        failure = error("name has both indent and format-as rule")
      else
      end
    end
  else
  end
  return failure
end
local validate
do
  local function validate0(config)
    if (config == nil) then
      return nil
    else
      if (type(config) == "table") then
        return validate_config_table(config)
      else
        return error("indentation configuration must be a table")
      end
    end
  end
  _2amodule_2a["validate"] = validate0
  validate = _2amodule_2a.validate
end
local resolve
do
  local function resolve0(config, name)
    local rule, _, found = resolve_name((config or {}), name, {})
    if found then
      return rule
    else
      return nil
    end
  end
  _2amodule_2a["resolve"] = resolve0
  resolve = _2amodule_2a.resolve
end
return nil
