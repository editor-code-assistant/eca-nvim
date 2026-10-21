-- [nfnl] fnl/fennel-extras/format.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.format"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.format"]
end
local indent = require("fennel-extras.indent")
local reader = require("fennel-extras.reader")
local function split_lines(source)
  local lines = {}
  local start = 1
  local at = string.find(source, "\n", start, true)
  while at do
    table.insert(lines, string.sub(source, start, (at - 1)))
    start = (at + 1)
    at = string.find(source, "\n", start, true)
  end
  table.insert(lines, string.sub(source, start))
  return lines
end
local function leading_spaces(line)
  return string.len(string.match(line, "^ *"))
end
local function spaces_only_3f(line)
  return (line == string.rep(" ", string.len(line)))
end
local function indentation_lines_equal_3f(left, right)
  local same = true
  for i, line in ipairs(left) do
    local other = right[i]
    local body = string.sub(line, (leading_spaces(line) + 1))
    local spaces = string.sub(other, 1, leading_spaces(other))
    if not ((line == other) or (other == (spaces .. body)) or ((other == "") and spaces_only_3f(line))) then
      same = false
    else
    end
  end
  return same
end
local function whitespace_kind_3f(kind)
  return ((kind == "whitespace") or (kind == "newline"))
end
local function token_kind_equal_3f(left, right)
  return ((left.kind == right.kind) or (whitespace_kind_3f(left.kind) and whitespace_kind_3f(right.kind)))
end
local function non_whitespace_token_equal_3f(left, right)
  return (left.text == right.text)
end
local function newline_count(text)
  local count = select(2, string.gsub(text, "\n", ""))
  return count
end
local function whitespace_token_equal_3f(left, right)
  return ((string.len(left.text) > 0) and (string.len(right.text) > 0) and (newline_count(right.text) >= newline_count(left.text)))
end
local function token_text_equal_3f(left, right)
  if whitespace_kind_3f(left.kind) then
    return whitespace_token_equal_3f(left, right)
  else
    return non_whitespace_token_equal_3f(left, right)
  end
end
local function token_sequence_step(left, right, index, next)
  local token = left[index]
  local other = right[index]
  return (token_kind_equal_3f(token, other) and token_text_equal_3f(token, other) and next(left, right, (index + 1)))
end
local function token_sequences_equal_3f(left, right, index)
  if (index > #left) then
    return true
  else
    return token_sequence_step(left, right, index, token_sequences_equal_3f)
  end
end
local function binding_whitespace_equal_3f(left, right)
  local left_body = string.gsub(left, "^ *", "")
  local right_body = string.gsub(right, "^ *", "")
  local left_tokens, left_error = reader.tokenize(left_body)
  local right_tokens, right_error = reader.tokenize(right_body)
  return (not left_error and not right_error and (left_body ~= right_body) and token_sequences_equal_3f(left_tokens, right_tokens, 1))
end
local function line_equal_3f(line, other, allow_binding_whitespace_3f)
  return ((line == other) or (other == (string.sub(other, 1, leading_spaces(other)) .. string.sub(line, (leading_spaces(line) + 1)))) or (allow_binding_whitespace_3f and binding_whitespace_equal_3f(line, other)) or ((other == "") and spaces_only_3f(line)))
end
local function lines_equal_3f(left, right, index, allow_binding_whitespace_3f)
  if (index > #left) then
    return true
  else
    return (line_equal_3f(left[index], right[index], allow_binding_whitespace_3f) and lines_equal_3f(left, right, (index + 1), allow_binding_whitespace_3f))
  end
end
local function replace_last_token(tokens, token)
  table.remove(tokens)
  return table.insert(tokens, token)
end
local function merged_whitespace_token(previous, token)
  return {kind = "whitespace", text = (previous.text .. token.text)}
end
local function merge_whitespace_token(tokens, token)
  local previous = tokens[#tokens]
  if (previous and whitespace_kind_3f(previous.kind) and whitespace_kind_3f(token.kind)) then
    return replace_last_token(tokens, merged_whitespace_token(previous, token))
  else
    return table.insert(tokens, token)
  end
end
local function normalized_tokens(tokens)
  local result = {}
  for _, token in ipairs(tokens) do
    merge_whitespace_token(result, token)
  end
  return result
end
local function token_whitespace_only_3f(before, after)
  local left, left_error = reader.tokenize(before)
  local right, right_error = reader.tokenize(after)
  local left_normalized = normalized_tokens(left)
  local right_normalized = normalized_tokens(right)
  return (not left_error and not right_error and (#left_normalized == #right_normalized) and token_sequences_equal_3f(left_normalized, right_normalized, 1))
end
local indent_only_3f
do
  local function indent_only_3f0(before, after, allow_binding_whitespace_3f)
    local left = split_lines(before)
    local right = split_lines(after)
    return (((#left == #right) and lines_equal_3f(left, right, 1, allow_binding_whitespace_3f)) or (allow_binding_whitespace_3f and token_whitespace_only_3f(before, after)))
  end
  _2amodule_2a["indent-only?"] = indent_only_3f0
  indent_only_3f = _2amodule_2a["indent-only?"]
end
local function ignored_3f(key)
  return ((key == "filename") or (key == "line") or (key == "col") or (key == "bytestart") or (key == "byteend") or (key == "endline") or (key == "endcol") or (key == "closer") or (key == "filename") or (key == "line") or (key == "col") or (key == "bytestart") or (key == "byteend") or (key == "endline") or (key == "endcol") or (key == "closer"))
end
local function symbol_3f(value)
  local meta = ((type(value) == "table") and getmetatable(value))
  return (meta and (tostring(meta[1]) == "SYMBOL"))
end
local function equal_key_3f(a, b)
  if (symbol_3f(a) and symbol_3f(b)) then
    return (tostring(a) == tostring(b))
  else
    return (a == b)
  end
end
local function entries(value)
  local result = {}
  for key, item in pairs(value) do
    if not ignored_3f(key) then
      table.insert(result, {key = key, value = item})
    else
    end
  end
  return result
end
local function matching_entry(equal, parser, entry, right)
  local found_index = nil
  for index, candidate in ipairs(right) do
    if ((found_index == nil) and equal_key_3f(entry.key, candidate.key) and equal(parser, entry.value, candidate.value)) then
      found_index = index
    else
    end
  end
  return found_index
end
local function remove_and_continue(continue, equal, parser, left, right, found_index)
  table.remove(right, found_index)
  return continue(equal, parser, left, right)
end
local function continue_equal_entries(continue, equal, parser, left, right, found_index)
  if found_index then
    return remove_and_continue(continue, equal, parser, left, right, found_index)
  else
    return false
  end
end
local function equal_entries_3f(equal, parser, left, right)
  if (#left == 0) then
    return true
  else
    local entry = table.remove(left, 1)
    local found_index = matching_entry(equal, parser, entry, right)
    return continue_equal_entries(equal_entries_3f, equal, parser, left, right, found_index)
  end
end
local function equal_table_3f(equal, parser, a, b)
  local left = entries(a)
  local right = entries(b)
  return ((#left == #right) and equal_entries_3f(equal, parser, left, right))
end
local function equal_value(parser, a, b)
  if (type(a) ~= type(b)) then
    return false
  else
    if (type(a) == "table") then
      if (symbol_3f(a) or parser["comment?"](a)) then
        return (tostring(a) == tostring(b))
      else
        return equal_table_3f(equal_value, parser, a, b)
      end
    else
      return (a == b)
    end
  end
end
local function parse_all(parser, source)
  local iterator = parser.parser(source, "fennel-extras", {comments = true})
  local forms = {}
  local done = false
  while not done do
    local ok, form = iterator()
    if ok then
      table.insert(forms, form)
    else
      done = true
    end
  end
  return forms
end
local function forms_equal_3f(parser, left, right)
  local same = true
  for i, form in ipairs(left) do
    if not equal_value(parser, form, right[i]) then
      same = false
    else
    end
  end
  return same
end
local ast_equal_3f
do
  local function ast_equal_3f0(parser, a, b)
    local ok, result
    local function _16_()
      local left = parse_all(parser, a)
      local right = parse_all(parser, b)
      if (#left ~= #right) then
        return false
      else
        return forms_equal_3f(parser, left, right)
      end
    end
    ok, result = pcall(_16_)
    return (ok and result)
  end
  _2amodule_2a["ast-equal?"] = ast_equal_3f0
  ast_equal_3f = _2amodule_2a["ast-equal?"]
end
local format_string
do
  local function format_string0(source, opts)
    local config = (opts.config or {})
    local parser = opts.parser
    local out, error = indent.reindent(source, config)
    if error then
      return nil, error
    else
      if not indent_only_3f(source, out, (config["align-bindings"] and true)) then
        return nil, {message = "formatter changed more than indentation"}
      else
        if (parser and not ast_equal_3f(parser, source, out)) then
          return nil, {message = "formatter changed the parsed form"}
        else
          return out
        end
      end
    end
  end
  _2amodule_2a["format-string"] = format_string0
  format_string = _2amodule_2a["format-string"]
end
return nil
