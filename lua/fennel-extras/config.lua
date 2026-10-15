-- [nfnl] fnl/fennel-extras/config.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.config"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.config"]
end
local core = require("eca.nfnl.core")
local reader = require("fennel-extras.reader")
local lint_rules = require("fennel-extras.lint.rules")
local sequence_marker = "fennel-extras-sequence"
local table_marker = "fennel-extras-table"
local function marked_sequence(value)
  return setmetatable(value, {[sequence_marker] = true})
end
local function marked_table(value)
  return setmetatable(value, {[table_marker] = true})
end
local function plain_sequence_step(value, key, count, maximum)
  local next_key, next_value = next(value, key)
  if (next_key == nil) then
    return ((count == maximum) and (count == #value))
  else
    return ((type(next_key) == "number") and (next_key == math.floor(next_key)) and (next_key > 0) and (next_value ~= nil) and plain_sequence_step(value, next_key, (count + 1), math.max(maximum, next_key)))
  end
end
local function sequence_3f(value)
  local and_2_ = (type(value) == "table")
  if and_2_ then
    local metadata = getmetatable(value)
    and_2_ = ((metadata and metadata[sequence_marker]) or ((metadata == nil) and plain_sequence_step(value, nil, 0, 0)))
  end
  return and_2_
end
local function parsed_table_3f(value)
  local and_4_ = (type(value) == "table")
  if and_4_ then
    local metadata = getmetatable(value)
    and_4_ = (metadata and metadata[table_marker])
  end
  return and_4_
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
    if ((next_key == "rules") or (next_key == "exclusions")) then
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
  local or_22_ = exclusion_keys_error(exclusion, index, unknown_key)
  if not or_22_ then
    if (type(rule) ~= "string") then
      or_22_ = {message = ("lint exclusion " .. index .. ": rule must be a string")}
    else
      or_22_ = exclusion_rule_error(exclusions, index, rule, form, reason, duplicate, next_error)
    end
  end
  return or_22_
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
local function lint_table_error(rules, exclusions, unknown_key)
  local or_26_ = unknown_lint_key_error(unknown_key)
  if not or_26_ then
    if (rules and ((type(rules) ~= "table") or (sequence_3f(rules) and ((getmetatable(rules) ~= nil) or (#rules > 0))))) then
      or_26_ = {message = "lint rules must be a table"}
    else
      or_26_ = nil
    end
  end
  if not or_26_ then
    if rules then
      or_26_ = first_lint_rule_error(rules, nil)
    else
      or_26_ = nil
    end
  end
  if not or_26_ then
    if (exclusions and not sequence_3f(exclusions)) then
      or_26_ = {message = "lint exclusions must be a list"}
    else
      or_26_ = nil
    end
  end
  if not or_26_ then
    if exclusions then
      or_26_ = first_exclusion_error(exclusions, 1)
    else
      or_26_ = nil
    end
  end
  return or_26_
end
local function lint_error(lint)
  if (type(lint) ~= "table") then
    return {message = "lint must be a table"}
  else
    local rules = lint.rules
    local exclusions = lint.exclusions
    local unknown_key = first_unknown_lint_key(lint, nil, nil)
    return lint_table_error(rules, exclusions, unknown_key)
  end
end
local function error_at(message, token)
  return {message = message, line = token.line, col = token.col}
end
local function trivia_3f(child)
  if child then
    if child.kind then
      return ((child.kind == "whitespace") or (child.kind == "newline") or (child.kind == "comment") or (child.kind == "tab"))
    else
      return false
    end
  else
    return false
  end
end
local function meaningful_children(children)
  local result = {}
  for _, child in ipairs(children) do
    if not trivia_3f(child) then
      table.insert(result, child)
    else
    end
  end
  return result
end
local function decode_string(token)
  local text = token.text
  local n = string.len(text)
  local result = {}
  local i = 2
  while (i < n) do
    local c = string.sub(text, i, i)
    if (c == "\\") then
      local escaped = string.sub(text, (i + 1), (i + 1))
      if (escaped == "\"") then
        table.insert(result, "\"")
      else
        if (escaped == "\\") then
          table.insert(result, "\\")
        else
          if (escaped == "n") then
            table.insert(result, "\n")
          else
            if (escaped == "t") then
              table.insert(result, "\t")
            else
              error(error_at("unsupported string escape", token), 0)
            end
          end
        end
      end
      i = (i + 2)
    else
      table.insert(result, c)
      i = (i + 1)
    end
  end
  return table.concat(result)
end
local function convert_symbol(token)
  local text = token.text
  if (string.sub(text, 1, 1) == ":") then
    return string.sub(text, 2)
  else
    if (text == "true") then
      return true
    else
      if (text == "false") then
        return false
      else
        if (text == "nil") then
          return nil
        else
          return error(error_at("symbols are not allowed", token), 0)
        end
      end
    end
  end
end
local function convert(node)
  if (node.kind == "table") then
    local children = meaningful_children(node.children)
    local result = {}
    local i = 1
    local failure = nil
    if (math.fmod(#children, 2) == 1) then
      return error(error_at("table must contain key/value pairs", node.open), 0)
    else
      while ((i <= #children) and not failure) do
        do
          local key, key_error = convert(children[i])
          local value, value_error = convert(rawget(children, (i + 1)))
          if key_error then
            failure = key_error
          else
            if value_error then
              failure = value_error
            else
              result[key] = value
            end
          end
        end
        i = (i + 2)
      end
      if failure then
        return error(failure, 0)
      else
        return marked_table(result)
      end
    end
  else
    if (node.kind == "sequence") then
      local result = {}
      local failure = nil
      for _, child in ipairs(meaningful_children(node.children)) do
        if not failure then
          local value, error = convert(child)
          if error then
            failure = error
          else
            table.insert(result, value)
          end
        else
        end
      end
      if failure then
        return error(failure, 0)
      else
        return marked_sequence(result)
      end
    else
      if (node.kind == "list") then
        return error(error_at("lists are not allowed", node.open), 0)
      else
        if (node.kind == "string") then
          return decode_string(node)
        else
          if (node.kind == "symbol") then
            return convert_symbol(node)
          else
            if (node.kind == "number") then
              local clean = string.gsub(node.text, "_", "")
              return tonumber(clean)
            else
              if (node.kind == "prefix") then
                return error(error_at("reader prefixes are not allowed", node), 0)
              else
                return error(error_at("unsupported form", node), 0)
              end
            end
          end
        end
      end
    end
  end
end
local parse_string
do
  local function parse_string0(text)
    local ok, result
    local function _58_()
      local root, reader_error = reader.parse(text)
      if reader_error then
        return {error = reader_error}
      else
        local children = meaningful_children(root.children)
        if (#children == 0) then
          return {error = {message = "expected one top-level table", line = 1, col = 1}}
        else
          if (#children > 1) then
            return {error = error_at("expected exactly one top-level form", children[2])}
          else
            local top = children[1]
            if (top.kind == "table") then
              return {value = convert(top)}
            else
              return {error = error_at("top-level form must be a table", (top.open or top))}
            end
          end
        end
      end
    end
    ok, result = pcall(_58_)
    if not ok then
      return nil, result
    else
      if result.error then
        return nil, result.error
      else
        return result.value
      end
    end
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
local function boolean_3f(value)
  return ((value == true) or (value == false))
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
  return (failure or (lint and lint_error(lint)))
end
local function configuration_error(tbl)
  local width = tbl["indent-width"]
  local builtins = tbl.builtins
  local fallbacks = tbl["prefix-fallbacks"]
  local extensions = tbl.extensions
  local skip_dotfiles = tbl["skip-dotfiles"]
  local follow_symlinks = tbl["follow-symlinks"]
  local parser = tbl.parser
  local lint = tbl.lint
  local failure = nil
  if ((failure == nil) and (width ~= nil) and not (integer_3f(width) and (width > 0))) then
    failure = {message = "indent-width must be a positive integer"}
  else
  end
  if ((failure == nil) and (builtins ~= nil) and not (builtins == true) and not (builtins == false) and (type(builtins) ~= "table")) then
    failure = {message = "builtins must be true, false, or a table of rules"}
  else
  end
  if ((failure == nil) and (type(builtins) == "table")) then
    failure = rule_map_error(builtins, "builtins rule ")
  else
  end
  if ((failure == nil) and (fallbacks ~= nil) and not (fallbacks == false) and (type(fallbacks) ~= "table")) then
    failure = {message = "prefix-fallbacks must be false or a table of rules"}
  else
  end
  if ((failure == nil) and (type(fallbacks) == "table")) then
    failure = rule_map_error(fallbacks, "prefix-fallbacks rule ")
  else
  end
  if ((failure == nil) and (extensions ~= nil) and not extensions_3f(extensions)) then
    failure = {message = "extensions must be a non-empty list of strings starting with \".\""}
  else
  end
  if ((failure == nil) and (skip_dotfiles ~= nil) and not boolean_3f(skip_dotfiles)) then
    failure = {message = "skip-dotfiles must be a boolean"}
  else
  end
  if ((failure == nil) and (follow_symlinks ~= nil) and not boolean_3f(follow_symlinks)) then
    failure = {message = "follow-symlinks must be a boolean"}
  else
  end
  if ((failure == nil) and (parser ~= nil) and (type(parser) ~= "string")) then
    failure = {message = "parser must be a string"}
  else
  end
  return configuration_error_with_lint(failure, lint)
end
local validate
do
  local function validate0(tbl)
    if (type(tbl) ~= "table") then
      return nil, {message = "configuration must be a table"}
    else
      local allowed = {indents = true, ["format-as"] = true, ["indent-patterns"] = true, paths = true, exclude = true, ["indent-width"] = true, builtins = true, ["prefix-fallbacks"] = true, extensions = true, ["skip-dotfiles"] = true, ["follow-symlinks"] = true, parser = true, lint = true}
      local failure = nil
      for key, _ in pairs(tbl) do
        if not allowed[key] then
          failure = {message = ("unknown configuration key: " .. key)}
        else
        end
      end
      if failure then
        return nil, failure
      else
        local new_error = configuration_error(tbl)
        if new_error then
          return nil, new_error
        else
          if (tbl.paths and not array_of_strings_3f(tbl.paths)) then
            return nil, {message = "paths must be an array of strings"}
          else
            if (tbl.exclude and not array_of_strings_3f(tbl.exclude)) then
              return nil, {message = "exclude must be an array of strings"}
            else
              return tbl
            end
          end
        end
      end
    end
  end
  _2amodule_2a["validate"] = validate0
  validate = _2amodule_2a.validate
end
local function valid_lint_policy(cfg)
  local lint = cfg.lint
  local overrides = ((lint and lint.rules) or {})
  local exclusions = ((lint and lint.exclusions) or {})
  return {rules = core.merge(lint_rules.defaults(), overrides), exclusions = exclusions}
end
local lint_policy
do
  local function lint_policy0(cfg)
    local valid, error = validate(cfg)
    if error then
      return nil, error
    else
      return valid_lint_policy(valid)
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
local function exists_3f(path)
  local uv = ((vim and vim.loop) or (vim and vim.uv))
  if uv then
    return (nil ~= uv.fs_stat(path))
  else
    local file = io.open(path, "r")
    if file then
      file:close()
      return true
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
local find
do
  local function find0(start_dir)
    local dir = start_dir
    local result = nil
    local searching = true
    while searching do
      local candidate = join_path(dir, ".fnl-extras.fnl")
      if exists_3f(candidate) then
        result = candidate
        searching = false
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
      local function _102_()
        return parse_string(text)
      end
      ok, parsed_or_error = pcall(_102_)
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
