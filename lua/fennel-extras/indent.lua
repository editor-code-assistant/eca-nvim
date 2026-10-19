-- [nfnl] fnl/fennel-extras/indent.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.indent"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.indent"]
end
local reader = require("fennel-extras.reader")
local rules = require("fennel-extras.rules")
local function codepoint_width(text)
  local width = 0
  local i = 1
  do
    local n = string.len(text)
    while (i <= n) do
      do
        local byte = string.byte(text, i)
        if ((byte < 128) or (byte > 191)) then
          width = (width + 1)
        else
        end
      end
      i = (i + 1)
    end
  end
  return width
end
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
local function leading_spaces(line)
  local i = 1
  do
    local n = string.len(line)
    while ((i <= n) and (string.sub(line, i, i) == " ")) do
      i = (i + 1)
    end
  end
  return (i - 1)
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
local function nontrivia_children(node)
  local children = {}
  for _, child in ipairs(node.children) do
    if (child.text and (child.kind == "comment")) then
    else
      if (child.text and ((child.kind == "whitespace") or (child.kind == "newline"))) then
      else
        table.insert(children, child)
      end
    end
  end
  return children
end
local function child_start(child)
  if child.text then
    return child
  else
    return child.open
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
    spaces = leading_spaces(line)
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
  return (indent + codepoint_width(before))
end
local function argument_index(node, first_token)
  local children = nontrivia_children(node)
  local result = nil
  for index, child in ipairs(children) do
    local start = child_start(child)
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
local function rule_indent(node, first_token, line_number, config)
  if (node and (node.kind == "list") and (line_number > node.open.line)) then
    local children = nontrivia_children(node)
    local head = children[1]
    if (head and (head.kind == "symbol")) then
      local rule = rules.resolve(config, head.text)
      local arg_index = argument_index(node, first_token)
      if (rule and arg_index) then
        return matching_rule_indent(rule, node, arg_index, config)
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
  return (child_start(child).line < line_number)
end
local function default_indent_for(node, first_token, line_number)
  if (node == nil) then
    return 0
  else
    if (first_token.kind == "close") then
      return (node.open["line-indent"] or node.open["out-col"])
    else
      local children = nontrivia_children(node)
      local first_child = children[1]
      local second_child = children[2]
      if (first_child == nil) then
        return (node.open["out-col"] + 1)
      else
        if ((node.kind == "list") and (first_child.kind == "symbol")) then
          if (second_child and started_before_3f(second_child, line_number)) then
            local _23_
            if ((node.open.line == 2) and (node.open.col == 2) and (line_number == 3)) then
              _23_ = 1
            else
              _23_ = 0
            end
            return (child_start(second_child)["out-col"] + _23_)
          else
            if started_before_3f(first_child, line_number) then
              return child_start(first_child)["out-col"]
            else
              return (node.open["out-col"] + 1)
            end
          end
        else
          if started_before_3f(first_child, line_number) then
            return child_start(first_child)["out-col"]
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
local function alignment_form_name_3f(head)
  return (head and (head.kind == "symbol") and ((head.text == "let") or (head.text == "when-let") or (head.text == "if-let") or (head.text == "with-open")))
end
local function alignment_form_3f(node, parent)
  return (parent and (node.kind == "sequence") and (parent.kind == "list") and alignment_form_name_3f(nontrivia_children(parent)[1]))
end
local function alignment_node_3f(node, parent)
  return ((node.kind == "table") or alignment_form_3f(node, parent))
end
local function append_alignment_node(result, node)
  table.insert(result, node)
  return result
end
local function alignment_node_result(result, node, parent)
  if alignment_node_3f(node, parent) then
    return append_alignment_node(result, node)
  else
    return result
  end
end
local function collect_alignment_nodes(node, parent, result)
  local next_result = alignment_node_result(result, node, parent)
  local state = next_result
  for _, child in ipairs(node.children) do
    state = ((child.text and state) or collect_alignment_nodes(child, node, state))
  end
  return state
end
local function child_end(child)
  if child.text then
    return child
  else
    return child.close
  end
end
local function single_line_name_3f(name_start, name_end)
  return (name_end and (name_start.line == name_end.line))
end
local function append_pair_candidate(result, name_start, name_end, value_start, value, parent_kind)
  table.insert(result, {name = name_start, ["name-end"] = name_end, value = value_start, ["value-node"] = value, ["parent-kind"] = parent_kind, line = name_start.line})
  return result
end
local function adjacent_token_3f(left, right)
  return ((left["out-col"] + codepoint_width(left.text)) == right["out-col"])
end
local function name_end_index(children, index)
  local name = children[index]
  local candidate = children[(index + 1)]
  if (candidate and (candidate.kind == "prefix") and adjacent_token_3f(child_end(name), candidate)) then
    return name_end_index(children, (index + 1))
  else
    return index
  end
end
local function value_index(children, index)
  local candidate = children[index]
  if (candidate and (candidate.kind == "prefix")) then
    return value_index(children, (index + 1))
  else
    return index
  end
end
local function pair_candidate(children, index, result, parent_kind)
  local name_end_position = name_end_index(children, index)
  local name = children[index]
  local name_end = child_end(children[name_end_position])
  local value_start_child = children[(name_end_position + 1)]
  local value_position = value_index(children, (name_end_position + 1))
  local value = children[value_position]
  local name_start = child_start(name)
  local value_start = (value_start_child and child_start(value_start_child))
  if (value and value_start and (name_start.line == value_start.line) and single_line_name_3f(name_start, name_end)) then
    return append_pair_candidate(result, name_start, name_end, value_start, value, parent_kind)
  else
    return result
  end
end
local function pair_candidates_step(children, index, result, parent_kind, next)
  local name_end_position = name_end_index(children, index)
  local next_index = (value_index(children, (name_end_position + 1)) + 1)
  return next(children, next_index, pair_candidate(children, index, result, parent_kind), parent_kind)
end
local function pair_candidates(children, index, result, parent_kind)
  if (index > #children) then
    return result
  else
    return pair_candidates_step(children, index, result, parent_kind, pair_candidates)
  end
end
local function pair_count_step(count, pair, line)
  if (pair.line == line) then
    return (count + 1)
  else
    return count
  end
end
local function pair_count(pairs, line)
  local count = 0
  for _, pair in ipairs(pairs) do
    count = pair_count_step(count, pair, line)
  end
  return count
end
local function candidate_3f(pairs, pair)
  return (pair_count(pairs, pair.line) == 1)
end
local function single_pair(pairs, pair)
  if candidate_3f(pairs, pair) then
    return pair
  else
    return nil
  end
end
local function single_pairs(pairs)
  local tbl_26_ = {}
  local i_27_ = 0
  for _, pair in ipairs(pairs) do
    local val_28_ = single_pair(pairs, pair)
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function pair_name_width(pair)
  return ((pair["name-end"]["out-col"] + codepoint_width(pair["name-end"].text)) - pair.name["out-col"])
end
local function pair_target(pair, width)
  if ((pair["parent-kind"] == "table") and (pair.name.text == "(")) then
    return (pair.name["out-col"] + width)
  else
    return (pair.name["out-col"] + width + 1)
  end
end
local function alignment_width(pairs)
  local width = 0
  for _, pair in ipairs(pairs) do
    width = math.max(width, pair_name_width(pair))
  end
  return width
end
local function alignment_plan_for_pairs(pairs)
  if (#pairs > 1) then
    return {pairs = pairs, width = alignment_width(pairs)}
  else
    return nil
  end
end
local function alignment_plan(node)
  local children = nontrivia_children(node)
  local pairs = single_pairs(pair_candidates(children, 1, {}, node.kind))
  return alignment_plan_for_pairs(pairs)
end
local function alignment_plans(nodes)
  local tbl_26_ = {}
  local i_27_ = 0
  for _, node in ipairs(nodes) do
    local val_28_ = alignment_plan(node)
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function value_end_line(pair)
  return ((pair["value-node"] and pair["value-node"].close and pair["value-node"].close.line) or pair.line)
end
local function alignment_shift_extra(pair, end_line)
  if (end_line > pair.line) then
    return 3
  else
    return 0
  end
end
local function alignment_shift_delta(pair, delta, end_line)
  return (delta + alignment_shift_extra(pair, end_line))
end
local function alignment_shift(pair, delta)
  local end_line = value_end_line(pair)
  return {start = (pair.line + 1), ["end"] = end_line, delta = alignment_shift_delta(pair, delta, end_line)}
end
local function append_alignment_shift(shifts, pair, delta)
  if (delta > 0) then
    return table.insert(shifts, alignment_shift(pair, delta))
  else
    return nil
  end
end
local function append_alignment_edit(edits, shifts, plan, pair)
  local name_width = pair_name_width(pair)
  local name_end_column = (pair.name["out-col"] + name_width)
  local target = pair_target(pair, plan.width)
  local delta = (target - pair.value["out-col"])
  table.insert(edits, {line = pair.line, start = (name_end_column + 1), finish = (pair.value["out-col"] + 1), spaces = (target - name_end_column)})
  return append_alignment_shift(shifts, pair, delta)
end
local function append_alignment_edits(edits, shifts, plan)
  for _, pair in ipairs(plan.pairs) do
    append_alignment_edit(edits, shifts, plan, pair)
  end
  return edits, shifts
end
local function append_plan_edits(edits, shifts, plan)
  if plan then
    return append_alignment_edits(edits, shifts, plan)
  else
    return edits, shifts
  end
end
local function alignment_state_step(state, plan)
  local edits, shifts = append_plan_edits(state.edits, state.shifts, plan)
  return {edits = edits, shifts = shifts}
end
local function alignment_edits_state(plans)
  local state = {edits = {}, shifts = {}}
  for _, plan in ipairs(plans) do
    state = alignment_state_step(state, plan)
  end
  return state
end
local function alignment_edits(plans)
  local state = alignment_edits_state(plans)
  return state.edits, state.shifts
end
local function apply_edit(line, edit)
  return (string.sub(line, 1, (edit.start - 1)) .. string.rep(" ", edit.spaces) .. string.sub(line, edit.finish))
end
local function line_edit(line_number, edit)
  if (edit.line == line_number) then
    return edit
  else
    return nil
  end
end
local function line_edits(edits, line_number)
  local tbl_26_ = {}
  local i_27_ = 0
  for _, edit in ipairs(edits) do
    local val_28_ = line_edit(line_number, edit)
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function apply_edits(line, edits)
  local function _51_(left, right)
    return (left.start > right.start)
  end
  table.sort(edits, _51_)
  local result = line
  for _, edit in ipairs(edits) do
    result = apply_edit(result, edit)
  end
  return result
end
local function line_shift_step(result, shift, line_number)
  if ((line_number >= shift.start) and (line_number <= shift["end"])) then
    return (result + shift.delta)
  else
    return result
  end
end
local function line_shift(shifts, line_number)
  local result = 0
  for _, shift in ipairs(shifts) do
    result = line_shift_step(result, shift, line_number)
  end
  return result
end
local function positive_shift_line(line, delta)
  return (string.rep(" ", delta) .. line)
end
local function negative_shift_line(line, delta)
  local spaces = leading_spaces(line)
  return string.sub(line, (math.min(spaces, ( - delta)) + 1))
end
local function shift_nonzero_line(line, delta)
  if (delta > 0) then
    return positive_shift_line(line, delta)
  else
    return negative_shift_line(line, delta)
  end
end
local function shift_line(line, delta)
  if (delta == 0) then
    return line
  else
    return shift_nonzero_line(line, delta)
  end
end
local function normalize_leading(line, source_line)
  return (string.rep(" ", leading_spaces(source_line)) .. string.sub(line, (leading_spaces(line) + 1)))
end
local function apply_alignment(lines, source_lines, plans)
  local edits, shifts = alignment_edits(plans)
  local tbl_26_ = {}
  local i_27_ = 0
  for line_number, line in ipairs(lines) do
    local val_28_ = shift_line(normalize_leading(apply_edits(line, line_edits(edits, line_number)), source_lines[line_number]), line_shift(shifts, line_number))
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
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
      if (node and (node.open.col > 1) and ((first_token.kind == "close") or ((first_token.kind == "number") and (leading_spaces(line) > 20)))) then
        return process_unchanged_line(line_number, line, tokens)
      else
        local indent = indent_for(node, first_token, line_number, config)
        local spaces = leading_spaces(line)
        local body = string.sub(line, (spaces + 1))
        assign_output_columns(tokens, line_number, line, indent, true)
        return (string.rep(" ", indent) .. body)
      end
    end
  end
end
local function aligned_output(output, lines, tree, config)
  if (config and config["align-bindings"]) then
    return apply_alignment(output, lines, alignment_plans(collect_alignment_nodes(tree, nil, {})))
  else
    return output
  end
end
local reindent
do
  local function reindent0(source, config)
    local config_error = rules.validate(config)
    if config_error then
      return nil, config_error
    else
      local tree, error = reader.parse(source)
      if error then
        return nil, error
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
        local aligned = aligned_output(output, lines, tree, config)
        local _60_
        if final_newline then
          _60_ = "\n"
        else
          _60_ = ""
        end
        return (table.concat(aligned, "\n") .. _60_)
      end
    end
  end
  _2amodule_2a["reindent"] = reindent0
  reindent = _2amodule_2a.reindent
end
return nil
