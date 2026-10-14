-- [nfnl] fnl/fennel-extras/config.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.config"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.config"]
end
local reader = require("fennel-extras.reader")
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
        return result
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
        return result
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
    local function _27_()
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
    ok, result = pcall(_27_)
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
local validate
do
  local function validate0(tbl)
    if (type(tbl) ~= "table") then
      return nil, {message = "configuration must be a table"}
    else
      local allowed = {indents = true, ["format-as"] = true, ["indent-patterns"] = true, paths = true, exclude = true}
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
  _2amodule_2a["validate"] = validate0
  validate = _2amodule_2a.validate
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
      local function _50_()
        return parse_string(text)
      end
      ok, parsed_or_error = pcall(_50_)
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
