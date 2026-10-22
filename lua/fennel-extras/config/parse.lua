-- [nfnl] fnl/fennel-extras/config/parse.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.config.parse"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.config.parse"]
end
local reader = require("fennel-extras.reader")
local reader0 = require("fennel-extras.reader")
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
local sequence_3f
do
  local function sequence_3f0(value)
    local and_2_ = (type(value) == "table")
    if and_2_ then
      local metadata = getmetatable(value)
      and_2_ = ((metadata and metadata[sequence_marker]) or ((metadata == nil) and plain_sequence_step(value, nil, 0, 0)))
    end
    return and_2_
  end
  _2amodule_2a["sequence?"] = sequence_3f0
  sequence_3f = _2amodule_2a["sequence?"]
end
local function parsed_table_3f(value)
  local and_4_ = (type(value) == "table")
  if and_4_ then
    local metadata = getmetatable(value)
    and_4_ = (metadata and metadata[table_marker])
  end
  return and_4_
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
local function append_meaningful_child(result, child)
  if not trivia_3f(child) then
    return table.insert(result, child)
  else
    return nil
  end
end
local function meaningful_children(children)
  local result = {}
  for _, child in ipairs(children) do
    append_meaningful_child(result, child)
  end
  return result
end
local function append_decoded_char(result, c)
  return table.insert(result, c)
end
local function normalize_escaped_delimiters_step(state)
  local text = state.text
  local index = state.index
  local in_string = state["in-string"]
  local result = state.result
  if (index > string.len(text)) then
    return result
  else
    local c = string.sub(text, index, index)
    local next = string.sub(text, (index + 1), (index + 1))
    if (not in_string and (c == "\\") and (next == "\"")) then
      return normalize_escaped_delimiters_step({text = text, index = (index + 2), ["in-string"] = in_string, result = (result .. next)})
    else
      if (in_string and (c == "\\")) then
        return normalize_escaped_delimiters_step({text = text, index = (index + 2), ["in-string"] = in_string, result = (result .. c .. next)})
      else
        local _9_
        if (c == "\"") then
          _9_ = not in_string
        else
          _9_ = in_string
        end
        return normalize_escaped_delimiters_step({text = text, index = (index + 1), ["in-string"] = _9_, result = (result .. c)})
      end
    end
  end
end
local function normalize_escaped_delimiters(text)
  local state = {text = text, index = 1, result = "", ["in-string"] = false}
  return normalize_escaped_delimiters_step(state)
end
local function append_unsupported_escape(result, escaped)
  table.insert(result, "\\")
  return table.insert(result, escaped)
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
              append_unsupported_escape(result, escaped)
            end
          end
        end
      end
      i = (i + 2)
    else
      local _ = append_decoded_char(result, c)
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
local function convert_table_children(convert_fn, children, result)
  local i = 1
  local failure = nil
  while ((i <= #children) and not failure) do
    do
      local key, key_error = convert_fn(children[i])
      local value, value_error = convert_fn(rawget(children, (i + 1)))
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
  return failure
end
local function convert(node)
  if (node.kind == "table") then
    local children = meaningful_children(node.children)
    local result = {}
    if (math.fmod(#children, 2) == 1) then
      return error(error_at("table must contain key/value pairs", node.open), 0)
    else
      local failure = convert_table_children(convert, children, result)
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
    local function _37_()
      local root, reader_error = reader0.parse(normalize_escaped_delimiters(text))
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
    ok, result = pcall(_37_)
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
return nil
