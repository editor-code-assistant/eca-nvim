-- [nfnl] fnl/fennel-extras/indent/align.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.indent.align"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.indent.align"]
end
local helpers = require("fennel-extras.indent.node")
local settings = require("fennel-extras.indent.settings")
local function alignment_form_name_3f(head, alignment)
  return (head and (head.kind == "symbol") and settings["binding-form?"](alignment, head.text))
end
local function alignment_form_3f(node, parent, alignment)
  return (parent and (node.kind == "sequence") and (parent.kind == "list") and alignment_form_name_3f(helpers["nontrivia-children"](parent)[1], alignment))
end
local function clause_form_name_3f(head, alignment)
  return (head and (head.kind == "symbol") and settings["clause-form?"](alignment, head.text))
end
local function clause_form_3f(node, alignment)
  return ((node.kind == "list") and clause_form_name_3f(helpers["nontrivia-children"](node)[1], alignment))
end
local function alignment_node_3f(node, parent, alignment)
  return ((alignment.maps and (node.kind == "table")) or (alignment.bindings and alignment_form_3f(node, parent, alignment)) or (alignment.clauses and clause_form_3f(node, alignment)))
end
local function append_alignment_node(result, node)
  table.insert(result, node)
  return result
end
local function alignment_node_result(result, node, parent, alignment)
  if alignment_node_3f(node, parent, alignment) then
    return append_alignment_node(result, node)
  else
    return result
  end
end
local function collect_alignment_nodes(node, parent, result, alignment)
  local next_result = alignment_node_result(result, node, parent, alignment)
  local state = next_result
  for _, child in ipairs((node.children or {})) do
    state = ((child.text and state) or (child.children and collect_alignment_nodes(child, node, state, alignment)) or state)
  end
  return state
end
local function single_line_name_3f(name_start, name_end)
  return (name_end and (name_start.line == name_end.line))
end
local function append_pair_candidate(result, pair)
  table.insert(result, pair)
  return result
end
local function adjacent_token_3f(left, right)
  return ((left["out-col"] + helpers["codepoint-width"](left.text)) == right["out-col"])
end
local function name_end_index(children, index)
  local name = children[index]
  local candidate = children[(index + 1)]
  if (candidate and (candidate.kind == "prefix") and adjacent_token_3f(helpers["child-end"](name), candidate)) then
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
local function pair_data(name_start, name_end, value_start, details)
  return {name = name_start, ["name-end"] = name_end, value = value_start, ["value-node"] = details.value, ["parent-kind"] = details["parent-kind"], line = name_start.line}
end
local function pair_details(value_start, value, parent_kind)
  return {["value-start"] = value_start, value = value, ["parent-kind"] = parent_kind}
end
local function append_pair_candidate_with_details(result, name_start, name_end, details)
  return append_pair_candidate(result, pair_data(name_start, name_end, details["value-start"], details))
end
local function pair_candidate(children, index, result, parent_kind)
  local name_end_position = name_end_index(children, index)
  local name = children[index]
  local name_end = helpers["child-end"](children[name_end_position])
  local value_start_child = children[(name_end_position + 1)]
  local value_position = value_index(children, (name_end_position + 1))
  local value = children[value_position]
  local name_start = helpers["child-start"](name)
  local value_start = (value_start_child and helpers["child-start"](value_start_child))
  if (value and value_start and (name_start.line == value_start.line) and single_line_name_3f(name_start, name_end)) then
    return append_pair_candidate_with_details(result, name_start, name_end, pair_details(value_start, value, parent_kind))
  else
    return result
  end
end
local function pair_candidates(children, index, result, parent_kind)
  local done = (index > #children)
  local name_end_position = (not done and name_end_index(children, index))
  local next_index = (name_end_position and (value_index(children, (name_end_position + 1)) + 1))
  local next_result = (next_index and pair_candidate(children, index, result, parent_kind))
  if done then
    return result
  else
    return pair_candidates(children, next_index, next_result, parent_kind)
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
local function single_pair(pairs, pair)
  if (pair_count(pairs, pair.line) == 1) then
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
  return ((pair["name-end"]["out-col"] + helpers["codepoint-width"](pair["name-end"].text)) - pair.name["out-col"])
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
local function clause_start_index(node)
  local head = helpers["nontrivia-children"](node)[1]
  if (head.text == "if") then
    return 2
  else
    return 3
  end
end
local function clause_pair_3f(node, pair, alignment)
  return (not clause_form_3f(node, alignment) or (pair.line > node.open.line))
end
local function comment_on_line_3f(node, line)
  local found = false
  for _, child in ipairs(node.children) do
    found = (found or (child.text and (child.kind == "comment") and (child.line == line)))
  end
  return found
end
local function usable_pair_3f(node, pair, alignment)
  return (clause_pair_3f(node, pair, alignment) and not comment_on_line_3f(node, pair.line))
end
local function usable_pair_result(node, pair, alignment)
  if usable_pair_3f(node, pair, alignment) then
    return pair
  else
    return nil
  end
end
local function usable_pairs(node, pairs, alignment)
  local tbl_26_ = {}
  local i_27_ = 0
  for _, pair in ipairs(pairs) do
    local val_28_ = usable_pair_result(node, pair, alignment)
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function single_line_node_3f(node)
  return (node.close and (node.open.line == node.close.line))
end
local function node_plan(node, pairs, alignment)
  if (alignment["collapse-padding"] and single_line_node_3f(node)) then
    return {pairs = pairs, collapse = true}
  else
    return {pairs = pairs, width = alignment_width(pairs)}
  end
end
local function alignment_plan_result(node, pairs, alignment)
  if (#pairs > 1) then
    return node_plan(node, pairs, alignment)
  else
    return nil
  end
end
local function usable_single_line_pair(node, pair)
  if not comment_on_line_3f(node, pair.line) then
    return pair
  else
    return nil
  end
end
local function all_usable_pairs(node, pairs)
  local tbl_26_ = {}
  local i_27_ = 0
  for _, pair in ipairs(pairs) do
    local val_28_ = usable_single_line_pair(node, pair)
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function candidate_pairs(node, pairs, alignment)
  if single_line_node_3f(node) then
    return all_usable_pairs(node, pairs)
  else
    return usable_pairs(node, pairs, alignment)
  end
end
local function alignment_pairs(node, pairs)
  if single_line_node_3f(node) then
    return pairs
  else
    return single_pairs(pairs)
  end
end
local function alignment_start(node, alignment)
  if clause_form_3f(node, alignment) then
    return clause_start_index(node)
  else
    return 1
  end
end
local function alignment_plan(node, alignment)
  local children = helpers["nontrivia-children"](node)
  local start = alignment_start(node, alignment)
  local pairs = pair_candidates(children, start, {}, node.kind)
  local aligned = alignment_pairs(node, pairs)
  local usable = candidate_pairs(node, aligned, alignment)
  return alignment_plan_result(node, usable, alignment)
end
local function alignment_plans(nodes, alignment)
  local tbl_26_ = {}
  local i_27_ = 0
  for _, node in ipairs(nodes) do
    local val_28_ = alignment_plan(node, alignment)
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function edit_spaces(plan, pair, name_end_column)
  if plan.collapse then
    return 1
  else
    return (pair_target(pair, plan.width) - name_end_column)
  end
end
local function append_alignment_edit(edits, plan, pair)
  local name_width = pair_name_width(pair)
  local name_end_column = (pair.name["out-col"] + name_width)
  local spaces = edit_spaces(plan, pair, name_end_column)
  local edit = {line = pair.line, start = (name_end_column + 1), finish = (pair.value["out-col"] + 1), spaces = spaces}
  return table.insert(edits, edit)
end
local function append_plan_pairs(edits, plan)
  for _, pair in ipairs(plan.pairs) do
    append_alignment_edit(edits, plan, pair)
  end
  return edits
end
local function append_plan_edits(edits, plan)
  if plan then
    return append_plan_pairs(edits, plan)
  else
    return edits
  end
end
local function alignment_edits(plans)
  local edits = {}
  for _, plan in ipairs(plans) do
    edits = append_plan_edits(edits, plan)
  end
  return edits
end
local function replace_edit(line, start, finish, spaces)
  return (string.sub(line, 1, (start - 1)) .. string.rep(" ", spaces) .. string.sub(line, finish))
end
local function apply_edit(line, edit)
  local start = helpers["byte-column"](line, edit.start)
  local finish = helpers["byte-column"](line, edit.finish)
  local spaces = string.rep(" ", edit.spaces)
  if (string.sub(line, start, (finish - 1)) == spaces) then
    return line
  else
    return replace_edit(line, start, finish, edit.spaces)
  end
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
  local function _26_(left, right)
    return (left.start > right.start)
  end
  table.sort(edits, _26_)
  local result = line
  for _, edit in ipairs(edits) do
    result = apply_edit(result, edit)
  end
  return result
end
local function apply_alignment(lines, plans)
  local edits = alignment_edits(plans)
  local tbl_26_ = {}
  local i_27_ = 0
  for line_number, line in ipairs(lines) do
    local val_28_ = apply_edits(line, line_edits(edits, line_number))
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local apply
do
  local function apply0(output, tree, alignment)
    local nodes = collect_alignment_nodes(tree, nil, {}, alignment)
    return apply_alignment(output, alignment_plans(nodes, alignment))
  end
  _2amodule_2a["apply"] = apply0
  apply = _2amodule_2a.apply
end
return nil
