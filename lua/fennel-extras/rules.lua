-- [nfnl] fnl/fennel-extras/rules.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.rules"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.rules"]
end
local built_ins = {fn = {{"inner", 0}}, lambda = {{"inner", 0}}, macro = {{"inner", 0}}, let = {{"block", 1}}, when = {{"block", 1}}, ["when-let"] = {{"block", 1}}, ["if-let"] = {{"block", 1}}, each = {{"block", 1}}, ["for"] = {{"block", 1}}, icollect = {{"block", 1}}, collect = {{"block", 1}}, accumulate = {{"block", 1}}, case = {{"block", 1}}, match = {{"block", 1}}, ["while"] = {{"block", 1}}, ["with-open"] = {{"block", 1}}, ["do"] = {{"block", 0}}}
local allowed_keys = {indents = true, ["format-as"] = true, ["indent-patterns"] = true}
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
local function validate_rule_list(value)
  if (type(value) == "table") then
    local failure = nil
    for _, rule in ipairs(value) do
      if (failure == nil) then
        failure = validate_rule(rule)
      else
      end
    end
    return failure
  else
    return error("indentation rules must be a list")
  end
end
local function validate_map(items, rules_3f)
  if (items == nil) then
    return nil
  else
    if (type(items) == "table") then
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
    else
      return error("indentation configuration must be a table")
    end
  end
end
local function validate_patterns(patterns)
  if (patterns == nil) then
    return nil
  else
    if (type(patterns) == "table") then
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
    else
      return error("indentation patterns must be a list")
    end
  end
end
local function _19_(config, name, seen)
  local indents = (config.indents or {})
  local aliases = (config["format-as"] or {})
  local patterns = (config["indent-patterns"] or {})
  if indents[name] then
    return indents[name], nil, true
  else
    if aliases[name] then
      return alias_rule(config, name, seen)
    else
      local result = nil
      local found = false
      for _, entry in ipairs(patterns) do
        if (not found and string.match(name, entry[1])) then
          result = entry[2]
          found = true
        else
        end
      end
      if found then
        return result, nil, true
      else
        if built_ins[name] then
          return built_ins[name], nil, true
        else
          if ((string.find(name, ".", 1, true) == nil) and string.match(name, "^def")) then
            return {{"inner", 0}}, nil, true
          else
            if ((string.find(name, ".", 1, true) == nil) and string.match(name, "^with-")) then
              return {{"block", 1}}, nil, true
            else
              return nil, nil, false
            end
          end
        end
      end
    end
  end
end
resolve_name = _19_
local function _27_(config, name, seen)
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
alias_rule = _27_
local validate
do
  local function validate0(config)
    if (config == nil) then
      return nil
    else
      if (type(config) == "table") then
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
