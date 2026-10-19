-- [nfnl] fnl/fennel-extras/rules.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.rules"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.rules"]
end
local built_in_rules = {fn = {{"inner", 0}}, lambda = {{"inner", 0}}, macro = {{"inner", 0}}, let = {{"block", 1}}, when = {{"block", 1}}, ["when-let"] = {{"block", 1}}, ["if-let"] = {{"block", 1}}, each = {{"block", 1}}, ["for"] = {{"block", 1}}, icollect = {{"block", 1}}, collect = {{"block", 1}}, accumulate = {{"block", 1}}, case = {{"block", 1}}, match = {{"block", 1}}, ["while"] = {{"block", 1}}, ["with-open"] = {{"block", 1}}, ["do"] = {{"block", 0}}}
local prefix_rules = {def = {{"inner", 0}}, ["with-"] = {{"block", 1}}}
local allowed_keys = {indents = true, ["format-as"] = true, ["indent-patterns"] = true, ["indent-width"] = true, builtins = true, ["prefix-fallbacks"] = true, ["align-bindings"] = true}
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
local function validate_pattern_items(patterns)
  local failure = nil
  for _, entry in ipairs(patterns) do
    if (failure == nil) then
      if ((type(entry) == "table") and (type(entry[1]) == "string")) then
        local ok, _0 = pcall(string.match, "", entry[1])
        if not ok then
          failure = error("invalid indentation pattern")
        else
          failure = validate_rule_list(entry[2])
        end
      else
        failure = error("invalid indentation pattern")
      end
    else
    end
  end
  return failure
end
local function validate_patterns(patterns)
  if (patterns == nil) then
    return nil
  else
    if (type(patterns) == "table") then
      return validate_pattern_items(patterns)
    else
      return error("indentation patterns must be a list")
    end
  end
end
local function effective_builtins(config)
  local setting = config.builtins
  if (setting == nil) then
    return built_in_rules
  else
    if (setting == true) then
      return built_in_rules
    else
      if (setting == false) then
        return {}
      else
        return setting
      end
    end
  end
end
local function effective_prefix_rules(config)
  local setting = config["prefix-fallbacks"]
  if (setting == nil) then
    return prefix_rules
  else
    if (setting == false) then
      return {}
    else
      return setting
    end
  end
end
local function found_rule(rule)
  return rule, true
end
local function resolve_pattern(patterns, name)
  local result = nil
  local found = false
  for _, entry in ipairs(patterns) do
    if (not found and string.match(name, entry[1])) then
      local new_result, new_found = found_rule(entry[2])
      result = new_result
      found = new_found
    else
    end
  end
  return result, found
end
local function resolve_prefix(prefixes, name)
  local result = nil
  local found = false
  for prefix, rule in pairs(prefixes) do
    if (not found and ((string.sub(name, 1, string.len(prefix)) == prefix) or ((string.sub(prefix, -1) == "-") and (name == string.sub(prefix, 1, -2))))) then
      local new_result, new_found = found_rule(rule)
      result = new_result
      found = new_found
    else
    end
  end
  return result, found
end
local function _26_(config, name, seen)
  local indents = (config.indents or {})
  local aliases = (config["format-as"] or {})
  local patterns = (config["indent-patterns"] or {})
  local builtins = effective_builtins(config)
  local prefixes = effective_prefix_rules(config)
  if indents[name] then
    return indents[name], nil, true
  else
    if aliases[name] then
      return alias_rule(config, name, seen)
    else
      local result, found = resolve_pattern(patterns, name)
      if found then
        return result, nil, true
      else
        if builtins[name] then
          return builtins[name], nil, true
        else
          if (string.find(name, ".", 1, true) == nil) then
            local result0, found0 = resolve_prefix(prefixes, name)
            if found0 then
              return result0, nil, true
            else
              return nil, nil, false
            end
          else
            return nil, nil, false
          end
        end
      end
    end
  end
end
resolve_name = _26_
local function _33_(config, name, seen)
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
alias_rule = _33_
local function validate_custom_map(items, prefix)
  if (type(items) == "table") then
    local failure = nil
    for name, value in pairs(items) do
      if (failure == nil) then
        if (type(name) ~= "string") then
          failure = error("indentation names must be strings")
        else
          if (validate_rule_list(value) ~= nil) then
            failure = error((prefix .. name .. ": invalid indentation rule"))
          else
          end
        end
      else
      end
    end
    return failure
  else
    return error((prefix .. " must be a table of rules"))
  end
end
local function validate_custom_config(config)
  local builtins = config.builtins
  local fallbacks = config["prefix-fallbacks"]
  if ((builtins ~= nil) and not (builtins == true) and not (builtins == false) and (type(builtins) ~= "table")) then
    return error("builtins must be true, false, or a table of rules")
  else
    if ((type(builtins) == "table") and validate_custom_map(builtins, "builtins rule ")) then
      return validate_custom_map(builtins, "builtins rule ")
    else
      if ((fallbacks ~= nil) and not (fallbacks == false) and (type(fallbacks) ~= "table")) then
        return error("prefix-fallbacks must be false or a table of rules")
      else
        if ((type(fallbacks) == "table") and validate_custom_map(fallbacks, "prefix-fallbacks rule ")) then
          return validate_custom_map(fallbacks, "prefix-fallbacks rule ")
        else
          return nil
        end
      end
    end
  end
end
local function validate_align_bindings(config)
  local align_bindings = config["align-bindings"]
  if ((align_bindings ~= nil) and (type(align_bindings) ~= "boolean")) then
    return error("align-bindings must be a boolean")
  else
    return nil
  end
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
    failure = validate_patterns(config["indent-patterns"])
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
    failure = validate_align_bindings(config)
  else
  end
  if (failure == nil) then
    failure = validate_custom_config(config)
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
