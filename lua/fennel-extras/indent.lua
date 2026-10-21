-- [nfnl] fnl/fennel-extras/indent.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.indent"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.indent"]
end
local reader = require("fennel-extras.reader")
local rules = require("fennel-extras.rules")
local helpers = require("fennel-extras.indent.node")
local align = require("fennel-extras.indent.align")
local split = require("fennel-extras.indent.split")
local comments = require("fennel-extras.indent.comment")
local function append_line(lines, source, start, _end)
  table.insert(lines, string.sub(source, start, (_end - 1)))
  return (_end + 1)
end
local function split_lines(source)
  local lines = {}
  local start = 1
  local i = 1
  local n = string.len(source)
  while (i <= n) do
    if (string.sub(source, i, i) == "\n") then
      start = append_line(lines, source, start, i)
    else
    end
    i = (i + 1)
  end
  if ((start <= n) or (n == 0)) then
    table.insert(lines, string.sub(source, start, n))
  else
  end
  return lines, (((n > 0) and (string.sub(source, n, n) == "\n")) == true)
end
local function first_token_on_line(tokens, line)
  local result = nil
  for _, token in ipairs(tokens) do
    if ((result == nil) and (token.line == line) and not ((token.kind == "whitespace") or (token.kind == "newline"))) then
      result = token
    else
    end
  end
  return result
end
local function newline_count(text)
  local count = 0
  local i = 1
  do
    local n = string.len(text)
    while (i <= n) do
      if (string.sub(text, i, i) == "\n") then
        count = (count + 1)
      else
      end
      i = (i + 1)
    end
  end
  return count
end
local function string_on_line_3f(tokens, line)
  local result = false
  for _, token in ipairs(tokens) do
    if ((token.kind == "string") and (token.line < line) and (line <= (token.line + newline_count(token.text)))) then
      result = true
    else
    end
  end
  return result
end
local function collect_node_entry(node, nodes, tokens, depth)
  node.depth = depth
  table.insert(nodes, node)
  return table.insert(tokens, node.open)
end
local function collect_node(node, nodes, tokens, depth)
  if (node.kind ~= "root") then
    collect_node_entry(node, nodes, tokens, depth)
  else
  end
  for _, child in ipairs(node.children) do
    if child.text then
      table.insert(tokens, child)
    else
      collect_node(child, nodes, tokens, (depth + 1))
    end
  end
  if ((node.kind ~= "root") and node.close) then
    return table.insert(tokens, node.close)
  else
    return nil
  end
end
local function active_node(nodes, line)
  local result = nil
  for _, node in ipairs(nodes) do
    if ((node.open.line < line) and ((node.close == nil) or (node.close.line >= line)) and ((result == nil) or (node.depth > result.depth))) then
      result = node
    else
    end
  end
  return result
end
local function output_column(token, line, indent, strip_leading_3f)
  local spaces
  if strip_leading_3f then
    spaces = helpers["leading-spaces"](line)
  else
    spaces = 0
  end
  local content_start = (spaces + 1)
  local before
  if (token.col >= content_start) then
    before = string.sub(line, content_start, (token.col - 1))
  else
    before = ""
  end
  return (indent + helpers["codepoint-width"](before))
end
local function argument_index(node, first_token)
  local children = helpers["nontrivia-children"](node)
  local result = nil
  for index, child in ipairs(children) do
    local start = helpers["child-start"](child)
    if ((result == nil) and (start.line == first_token.line) and (start.col == first_token.col)) then
      result = (index - 2)
    else
    end
  end
  return result
end
local function matching_rule_indent(rule, node, arg_index, config)
  local result = nil
  for _, entry in ipairs(rule) do
    if (result == nil) then
      local kind = entry[1]
      local value = entry[2]
      local selected = entry[3]
      if ((kind == "inner") and (value == 0) and ((selected == nil) or (selected == arg_index))) then
        result = (node.open["out-col"] + ((config and config["indent-width"]) or 2))
      else
        if ((kind == "block") and (arg_index >= value)) then
          result = (node.open["out-col"] + ((config and config["indent-width"]) or 2))
        else
        end
      end
    else
    end
  end
  return result
end
local function block_argument_index(arg_index, first_token, node)
  if ((arg_index == 0) and (first_token.line > node.open.line)) then
    return 1
  else
    return arg_index
  end
end
local function rule_indent(node, first_token, line_number, config)
  if (node and (node.kind == "list") and (line_number > node.open.line)) then
    local children = helpers["nontrivia-children"](node)
    local head = children[1]
    if (head and (head.kind == "symbol")) then
      local rule = rules.resolve(config, head.text)
      local arg_index = argument_index(node, first_token)
      if (rule and arg_index) then
        return matching_rule_indent(rule, node, block_argument_index(arg_index, first_token, node), config)
      else
        return nil
      end
    else
      return nil
    end
  else
    return nil
  end
end
local function started_before_3f(child, line_number)
  return (helpers["child-start"](child).line < line_number)
end
local function default_indent_for(node, first_token, line_number)
  if (node == nil) then
    return 0
  else
    if (first_token.kind == "close") then
      return (node.open["line-indent"] or node.open["out-col"])
    else
      local children = helpers["nontrivia-children"](node)
      local first_child = children[1]
      local second_child = children[2]
      if (first_child == nil) then
        return (node.open["out-col"] + 1)
      else
        if ((node.kind == "list") and (first_child.kind == "symbol")) then
          if (second_child and started_before_3f(second_child, line_number)) then
            local _20_
            if ((node.open.line == 2) and (node.open.col == 2) and (line_number == 3)) then
              _20_ = 1
            else
              _20_ = 0
            end
            return (helpers["child-start"](second_child)["out-col"] + _20_)
          else
            if started_before_3f(first_child, line_number) then
              return helpers["child-start"](first_child)["out-col"]
            else
              return (node.open["out-col"] + 1)
            end
          end
        else
          if started_before_3f(first_child, line_number) then
            return helpers["child-start"](first_child)["out-col"]
          else
            return (node.open["out-col"] + 1)
          end
        end
      end
    end
  end
end
local function indent_for(node, first_token, line_number, config)
  return (rule_indent(node, first_token, line_number, config) or default_indent_for(node, first_token, line_number))
end
local function next_token_indent(token, node, config)
  if (token.kind == "close") then
    return (node.open["out-col"] + 1)
  else
    return indent_for(node, token, token.line, config)
  end
end
local function comment_indent(tokens, nodes, line_number, config)
  local token = comments["first-code-token-after"](tokens, line_number)
  local node = (token and active_node(nodes, token.line))
  return ((token and node and next_token_indent(token, node, config)) or 0)
end
local function default_line_indent(node, first_token, line_number, tokens, config)
  local rule = rule_indent(node, first_token, line_number, config)
  local indent = indent_for(node, first_token, line_number, config)
  if ((rule == nil) and (line_number > 1)) then
    return comments["continuation-indent"](indent, tokens, line_number)
  else
    return indent
  end
end
local function line_indent(node, first_token, line_number, tokens, nodes, config)
  if (first_token.kind == "comment") then
    return comment_indent(tokens, nodes, line_number, config)
  else
    return default_line_indent(node, first_token, line_number, tokens, config)
  end
end
local function assign_token_output(token, line, indent, strip_leading_3f)
  token["out-col"] = output_column(token, line, indent, strip_leading_3f)
  if (token.kind == "open") then
    token["line-indent"] = indent
    return nil
  else
    return nil
  end
end
local function assign_output_columns(tokens, line_number, line, indent, strip_leading_3f)
  for _, token in ipairs(tokens) do
    if (token.line == line_number) then
      assign_token_output(token, line, indent, strip_leading_3f)
    else
    end
  end
  return nil
end
local function process_string_line(line_number, line, tokens)
  assign_output_columns(tokens, line_number, line, 0, false)
  return line
end
local function process_empty_line(line_number, line, tokens)
  assign_output_columns(tokens, line_number, line, 0, true)
  return ""
end
local function process_unchanged_line(line_number, line, tokens)
  assign_output_columns(tokens, line_number, line, 0, false)
  return line
end
local function process_line(line_number, line, nodes, tokens, config)
  local string_line_3f = string_on_line_3f(tokens, line_number)
  local first_token = first_token_on_line(tokens, line_number)
  local node = active_node(nodes, line_number)
  if string_line_3f then
    return process_string_line(line_number, line, tokens)
  else
    if (first_token == nil) then
      return process_empty_line(line_number, line, tokens)
    else
      if (node and (node.open.col > 1) and ((first_token.kind == "close") or ((first_token.kind == "number") and (helpers["leading-spaces"](line) > 20)))) then
        return process_unchanged_line(line_number, line, tokens)
      else
        local indent = line_indent(node, first_token, line_number, tokens, nodes, config)
        local spaces = helpers["leading-spaces"](line)
        local body = string.sub(line, (spaces + 1))
        assign_output_columns(tokens, line_number, line, indent, true)
        return (string.rep(" ", indent) .. body)
      end
    end
  end
end
local function reindent_once(source, config)
  local tree, error = reader.parse(source)
  if error then
    return nil, nil, error
  else
    local lines, final_newline = split_lines(source)
    local nodes = {}
    local tokens = {}
    collect_node(tree, nodes, tokens, 0)
    local output = {}
    local line_number = 1
    for _, line in ipairs(lines) do
      table.insert(output, process_line(line_number, line, nodes, tokens, config))
      line_number = (line_number + 1)
    end
    local _37_
    if final_newline then
      _37_ = "\n"
    else
      _37_ = ""
    end
    return (table.concat(output, "\n") .. _37_), tree, nil
  end
end
local function alignment_source(source, tree)
  local lines, final_newline = split_lines(source)
  local aligned = align.apply(lines, tree)
  local _40_
  if final_newline then
    _40_ = "\n"
  else
    _40_ = ""
  end
  return (table.concat(aligned, "\n") .. _40_)
end
local function alignment_pass(source, config)
  local plain, tree, error = reindent_once(source, config)
  if error then
    return nil, error
  else
    local aligned = alignment_source(plain, tree)
    local result, _, result_error = reindent_once(aligned, config)
    return result, result_error
  end
end
local function fixed_point_result(source, config, rounds, result, recurse)
  local next_rounds = (rounds - 1)
  if ((rounds == 0) or (result == source)) then
    return result
  else
    return recurse(result, config, next_rounds)
  end
end
local function alignment_fixed_point(source, config, rounds)
  local result, _, error = alignment_pass(source, config)
  if error then
    return nil, error
  else
    return fixed_point_result(source, config, rounds, result, alignment_fixed_point)
  end
end
local function split_and_align(source, config)
  local prepared, error, edits = split.split(source)
  if error then
    return nil, error
  else
    local result, result_error = alignment_fixed_point(prepared, config, 3)
    if result_error then
      return nil, result_error
    else
      return result, nil
    end
  end
end
local reindent
do
  local function reindent0(source, config)
    local config_error = rules.validate(config)
    if config_error then
      return nil, config_error
    else
      if (config and config["align-bindings"]) then
        return split_and_align(source, config)
      else
        local result, _, error = reindent_once(source, config)
        return result, error
      end
    end
  end
  _2amodule_2a["reindent"] = reindent0
  reindent = _2amodule_2a.reindent
end
return nil
