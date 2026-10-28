-- [nfnl] fnl/fennel-extras/format.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.format"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.format"]
end
local indent = require("fennel-extras.indent")
local reader = require("fennel-extras.reader")
local settings = require("fennel-extras.indent.settings")
local rules = require("fennel-extras.rules")
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
local function newline_rules(config)
  return (config.newline or {})
end
local function form_selected_3f(forms, head)
  local or_1_ = (forms == nil)
  if not or_1_ then
    local result = false
    for _, value in ipairs(forms) do
      result = (result or (value == head))
    end
    or_1_ = result
  end
  return or_1_
end
local function form_spans(source)
  local tokens, error = reader.tokenize(source)
  local stack = {}
  local result = {}
  if not error then
    for index, token in ipairs(tokens) do
      if (token.kind == "open") then
        table.insert(stack, {start = token.line, head = nil})
      else
        if (token.kind == "symbol") then
          local top = stack[#stack]
          if (top and (top.head == nil)) then
            top.head = token.text
          else
          end
        else
          if (token.kind == "close") then
            local top = table.remove(stack)
            if (top and top.head) then
              table.insert(result, {head = top.head, start = top.start, ["end"] = token.line})
            else
            end
          else
          end
        end
      end
    end
  else
  end
  local function _8_(left, right)
    return (left.start > right.start)
  end
  table.sort(result, _8_)
  return result
end
local function max_break(breaks, index, count)
  if (count > (breaks[index] or 0)) then
    breaks[index] = count
    return nil
  else
    return nil
  end
end
local function blank_run_after(lines, index)
  local next_index = (index + 1)
  if (lines[next_index] and (lines[next_index] == "")) then
    return (1 + blank_run_after(lines, next_index))
  else
    return 0
  end
end
local function preceding_break_index(lines, index)
  if ((index > 0) and (lines[index] == "")) then
    return preceding_break_index(lines, (index - 1))
  else
    return index
  end
end
local function apply_newline_rules(source, config)
  local lines = split_lines(source)
  local spans = form_spans(source)
  local breaks = {}
  for _, rule in ipairs(newline_rules(config)) do
    local forms = rule["applies-to"].forms
    local before = (rule.options.before or 0)
    local after = (rule.options.after or 0)
    for _0, span in ipairs(spans) do
      if form_selected_3f(forms, span.head) then
        max_break(breaks, preceding_break_index(lines, (span.start - 1)), before)
        if (span["end"] < #lines) then
          max_break(breaks, span["end"], after)
        else
        end
      else
      end
    end
  end
  local output = {}
  local limit
  if ((#lines > 1) and (lines[#lines] == "")) then
    limit = (1 + preceding_break_index(lines, (#lines - 1)))
  else
    limit = preceding_break_index(lines, #lines)
  end
  for index, line in ipairs(lines) do
    if (index <= limit) then
      table.insert(output, line)
      local count = (breaks[index] or 0)
      local existing = blank_run_after(lines, index)
      local needed = (count - existing)
      if (needed > 0) then
        for _ = 1, needed do
          table.insert(output, "")
        end
      else
      end
    else
    end
  end
  return table.concat(output, "\n")
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
local function token_sequences_equal_3f(left, right, index)
  local and_19_ = (#left == #right)
  if and_19_ then
    local result = true
    for offset in ipairs(left) do
      local token = left[offset]
      local other = right[offset]
      result = (result and token_kind_equal_3f(token, other) and token_text_equal_3f(token, other))
    end
    and_19_ = result
  end
  return and_19_
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
    local function _32_()
      local left = parse_all(parser, a)
      local right = parse_all(parser, b)
      if (#left ~= #right) then
        return false
      else
        return forms_equal_3f(parser, left, right)
      end
    end
    ok, result = pcall(_32_)
    return (ok and result)
  end
  _2amodule_2a["ast-equal?"] = ast_equal_3f0
  ast_equal_3f = _2amodule_2a["ast-equal?"]
end
local function alignment_enabled_3f(alignment)
  return (alignment.bindings or alignment.maps or alignment.clauses or alignment["split-bindings"] or alignment["collapse-padding"])
end
local function rules_config(config)
  return {indents = config.indents, ["format-as"] = config["format-as"], ["indent-patterns"] = config["indent-patterns"], ["indent-width"] = config["indent-width"], builtins = (config.builtins or false), ["prefix-fallbacks"] = (config["prefix-fallbacks"] or false), alignment = config.alignment}
end
local function indentation_output_error(source, alignment, out, config)
  if not (indent_only_3f(source, out, alignment_enabled_3f(alignment)) or config.newline) then
    return {message = "formatter changed more than indentation"}
  else
    return nil
  end
end
local function parser_output_error(source, parser, out)
  if (parser and not ast_equal_3f(parser, source, out)) then
    return {message = "formatter changed the parsed form"}
  else
    return nil
  end
end
local function formatted_output_error(source, parser, alignment, out, config)
  return (indentation_output_error(source, alignment, out, config) or parser_output_error(source, parser, out))
end
local function validated_output(source, parser, alignment, out, config)
  local output_error = formatted_output_error(source, parser, alignment, out, config)
  if output_error then
    return nil, output_error
  else
    return out
  end
end
local function format_string_error(alignment_error, rules_error)
  return (alignment_error or rules_error)
end
local function format_string_valid(source, parser, config)
  local alignment = settings.resolve(config)
  local out, error = indent.reindent(source, config)
  if error then
    return nil, error
  else
    local output = apply_newline_rules(out, config)
    return validated_output(source, parser, alignment, output, config)
  end
end
local format_string
do
  local function format_string0(source, opts)
    local config = (opts.config or {})
    local parser = opts.parser
    local alignment_error = settings.validate(config.alignment)
    local rule_config = rules_config(config)
    local rules_error = rules.validate(rule_config)
    local validation_error = format_string_error(alignment_error, rules_error)
    if validation_error then
      return nil, validation_error
    else
      return format_string_valid(source, parser, config)
    end
  end
  _2amodule_2a["format-string"] = format_string0
  format_string = _2amodule_2a["format-string"]
end
return nil
