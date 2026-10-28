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
local parse_string
do
  local function parse_string0(text)
    return parse["parse-string"](text)
  end
  _2amodule_2a["parse-string"] = parse_string0
  parse_string = _2amodule_2a["parse-string"]
end
local function array_of_strings_3f(value)
  if (type(value) ~= "table") then
    return false
  else
    local valid = true
    local index = 1
    while (valid and (value[index] ~= nil)) do
      if (type(value[index]) ~= "string") then
        valid = false
      else
      end
      index = (index + 1)
    end
    return valid
  end
end
local function integer_3f(value)
  return ((type(value) == "number") and (value == math.floor(value)))
end
local function valid_rule_3f(rule)
  if ((type(rule) == "table") and (type(rule[1]) == "string")) then
    local kind = rule[1]
    local value = rule[2]
    local index = rule[3]
    if (kind == "block") then
      return (integer_3f(value) and (value >= 0) and (index == nil))
    else
      if (kind == "inner") then
        return ((value == 0) and ((index == nil) or (integer_3f(index) and (index >= 0))))
      else
        return false
      end
    end
  else
    return false
  end
end
local function valid_rule_list_3f(value)
  if (type(value) == "table") then
    local valid = true
    for _, rule in ipairs(value) do
      if not valid_rule_3f(rule) then
        valid = false
      else
      end
    end
    return valid
  else
    return false
  end
end
local function rule_map_error(value, prefix)
  if (type(value) == "table") then
    local failure = nil
    for name, rule in pairs(value) do
      if (failure == nil) then
        if not valid_rule_list_3f(rule) then
          failure = {message = (prefix .. name .. ": invalid indentation rule")}
        else
        end
      else
      end
    end
    return failure
  else
    return {message = (prefix .. ": invalid indentation rule")}
  end
end
local function extensions_3f(value)
  if ((type(value) == "table") and (#value > 0)) then
    local valid = true
    for _, extension in ipairs(value) do
      if ((type(extension) ~= "string") or not (string.sub(extension, 1, 1) == ".")) then
        valid = false
      else
      end
    end
    return valid
  else
    return false
  end
end
local function configuration_error_with_lint(failure, lint)
  return (failure or (lint and lint_config["lint-error"](lint)))
end
local function configuration_error(tbl)
  return ((tbl.format and format_config.validate(tbl.format, false, false, false)) or configuration_error_with_lint(nil, tbl.lint))
end
local function workspace_key_error(workspace)
  if (type(workspace) == "table") then
    local allowed = {paths = true, exclude = true, extensions = true, dotfiles = true, symlinks = true}
    local key
    do
      local candidate = nil
      for name, _ in pairs(workspace) do
        if (not allowed[name] and ((candidate == nil) or (tostring(name) < tostring(candidate)))) then
          candidate = name
        else
          candidate = candidate
        end
      end
      key = candidate
    end
    if key then
      return {message = ("unknown workspace key: " .. key)}
    else
      return nil
    end
  else
    return nil
  end
end
local function workspace_error(tbl)
  local workspace = tbl.workspace
  local _16_
  if (workspace and (type(workspace) ~= "table")) then
    _16_ = {message = "workspace must be a table"}
  else
    _16_ = nil
  end
  local or_18_ = _16_ or workspace_key_error(workspace)
  if not or_18_ then
    if (workspace and workspace.paths and not array_of_strings_3f(workspace.paths)) then
      or_18_ = {message = "workspace.paths must be an array of strings"}
    else
      or_18_ = nil
    end
  end
  if not or_18_ then
    if (workspace and workspace.exclude and not array_of_strings_3f(workspace.exclude)) then
      or_18_ = {message = "workspace.exclude must be an array of strings"}
    else
      or_18_ = nil
    end
  end
  if not or_18_ then
    if (workspace and workspace.extensions and not extensions_3f(workspace.extensions)) then
      or_18_ = {message = "workspace.extensions must be a non-empty list of strings starting with \".\""}
    else
      or_18_ = nil
    end
  end
  if not or_18_ then
    if (workspace and (workspace.dotfiles ~= nil) and not ((workspace.dotfiles == true) or (workspace.dotfiles == false))) then
      or_18_ = {message = "workspace.dotfiles must be a boolean"}
    else
      or_18_ = nil
    end
  end
  if not or_18_ then
    if (workspace and (workspace.symlinks ~= nil) and not ((workspace.symlinks == true) or (workspace.symlinks == false))) then
      or_18_ = {message = "workspace.symlinks must be a boolean"}
    else
      or_18_ = nil
    end
  end
  return or_18_
end
local function content_error(tbl)
  return workspace_error(tbl)
end
local validate_workspace
do
  local function validate_workspace0(workspace, require_paths_3f)
    local _24_
    if (type(workspace) ~= "table") then
      _24_ = {message = "workspace must be a table"}
    else
      _24_ = nil
    end
    local or_26_ = _24_ or workspace_key_error(workspace)
    if not or_26_ then
      if (require_paths_3f and (workspace.paths == nil)) then
        or_26_ = {message = "missing workspace.paths"}
      else
        or_26_ = nil
      end
    end
    if not or_26_ then
      if (workspace.paths and not array_of_strings_3f(workspace.paths)) then
        or_26_ = {message = "workspace.paths must be an array of strings"}
      else
        or_26_ = nil
      end
    end
    if not or_26_ then
      if (workspace.exclude and not array_of_strings_3f(workspace.exclude)) then
        or_26_ = {message = "workspace.exclude must be an array of strings"}
      else
        or_26_ = nil
      end
    end
    if not or_26_ then
      if (workspace.extensions and not extensions_3f(workspace.extensions)) then
        or_26_ = {message = "workspace.extensions must be a non-empty list of strings starting with \".\""}
      else
        or_26_ = nil
      end
    end
    if not or_26_ then
      if ((workspace.dotfiles ~= nil) and not ((workspace.dotfiles == true) or (workspace.dotfiles == false))) then
        or_26_ = {message = "workspace.dotfiles must be a boolean"}
      else
        or_26_ = nil
      end
    end
    if not or_26_ then
      if ((workspace.symlinks ~= nil) and not ((workspace.symlinks == true) or (workspace.symlinks == false))) then
        or_26_ = {message = "workspace.symlinks must be a boolean"}
      else
        or_26_ = nil
      end
    end
    return or_26_
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
  return (configuration_error(tbl) or content_error(tbl))
end
local function valid_table(tbl)
  return validation_result(tbl, validation_failure(tbl))
end
local function unknown_config_key(tbl)
  local allowed = {workspace = true, format = true, lint = true}
  local candidate = nil
  for key, _ in pairs(tbl) do
    if (not allowed[key] and ((candidate == nil) or (tostring(key) < tostring(candidate)))) then
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
local function format_fragment_key_3f(key)
  return ((key == "indent-width") or (key == "builtins") or (key == "prefix-fallbacks") or (key == "parser") or (key == "indents") or (key == "format-as") or (key == "indent-patterns") or (key == "alignment") or (key == "newline") or (key == "extensions"))
end
local function unknown_format_fragment_key(tbl)
  local candidate = nil
  for key, _ in pairs(tbl) do
    if (not format_fragment_key_3f(key) and ((candidate == nil) or (tostring(key) < tostring(candidate)))) then
      candidate = key
    else
      candidate = candidate
    end
  end
  return candidate
end
local function format_fragment_error(tbl)
  local key = unknown_format_fragment_key(tbl)
  if key then
    return {message = ("unknown configuration key: " .. key)}
  else
    return format_config.validate(tbl, false, false, false)
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
local validate
do
  local function validate0(tbl)
    if (type(tbl) ~= "table") then
      return nil, {message = "configuration must be a table"}
    else
      if (tbl.workspace or tbl.format or tbl.lint) then
        return validate_canonical_table(tbl)
      else
        local failure = format_fragment_error(tbl)
        return validation_result(tbl, failure)
      end
    end
  end
  _2amodule_2a["validate"] = validate0
  validate = _2amodule_2a.validate
end
local function append_canonical_instance_exclusions(result, rule, index, instance)
  for _, exclusion in ipairs((instance.exclusions or {})) do
    local copy = {}
    for key, value in pairs(exclusion) do
      copy[key] = value
    end
    table.insert(result, core.assoc(core.assoc(copy, "rule", rule), "instance", index))
  end
  return result
end
local function append_canonical_rule_exclusions(result, rule, instances)
  for index, instance in ipairs((instances or {})) do
    append_canonical_instance_exclusions(result, rule, index, instance)
  end
  return result
end
local function canonical_exclusions(rules)
  local result = {}
  for rule, instances in pairs(rules) do
    append_canonical_rule_exclusions(result, rule, instances)
  end
  return result
end
local function valid_lint_policy(cfg)
  local rules = cfg.lint.rules
  return {rules = rules, exclusions = canonical_exclusions(rules)}
end
local function lint_policy_valid(valid)
  if (valid.lint == nil) then
    return nil, {message = "missing lint"}
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
local function join_path(dir, name)
  if (string.sub(dir, -1) == "/") then
    return (dir .. name)
  else
    return (dir .. "/" .. name)
  end
end
local function close_file(file)
  file:close()
  return true
end
local function exists_3f(path)
  local uv = ((vim and vim.loop) or (vim and vim.uv))
  if uv then
    return (nil ~= uv.fs_stat(path))
  else
    local file = io.open(path, "r")
    if file then
      return close_file(file)
    else
      return false
    end
  end
end
local function git_marker_3f(dir)
  return (exists_3f(join_path(dir, ".git")) or exists_3f(join_path(join_path(dir, ".git"), "HEAD")))
end
local function parent_dir(dir)
  local trimmed
  if ((string.len(dir) > 1) and (string.sub(dir, -1) == "/")) then
    trimmed = string.sub(dir, 1, -2)
  else
    trimmed = dir
  end
  local parent = string.match(trimmed, "^(.*)/[^/]+$")
  if parent then
    if (parent == "") then
      return "/"
    else
      return parent
    end
  else
    return nil
  end
end
local function found_config(candidate)
  return candidate, false
end
local find
do
  local function find0(start_dir)
    local dir = start_dir
    local result = nil
    local searching = true
    while searching do
      local candidate = join_path(dir, ".fnl-extras.fnl")
      if exists_3f(candidate) then
        local new_result, new_searching = found_config(candidate)
        result = new_result
        searching = new_searching
      else
        if git_marker_3f(dir) then
          searching = false
        else
          local parent = parent_dir(dir)
          if parent then
            dir = parent
          else
            searching = false
          end
        end
      end
    end
    return result
  end
  _2amodule_2a["find"] = find0
  find = _2amodule_2a.find
end
local load
do
  local function load0(path)
    local file = io.open(path, "r")
    if not file then
      return nil, {message = ("could not read config file: " .. path)}
    else
      local text = file:read("*a")
      file:close()
      local ok, parsed_or_error
      local function _52_()
        return parse_string(text)
      end
      ok, parsed_or_error = pcall(_52_)
      if not ok then
        return nil, parsed_or_error
      else
        return validate(parsed_or_error)
      end
    end
  end
  _2amodule_2a["load"] = load0
  load = _2amodule_2a.load
end
return nil
