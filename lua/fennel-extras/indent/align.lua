-- [nfnl] fnl/fennel-extras/indent/align.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.indent.align"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.indent.align"]
end
local helpers = require("fennel-extras.indent.node")
local function alignment_form_name_3f(head)
  return (head and (head.kind == "symbol") and ((head.text == "let") or (head.text == "when-let") or (head.text == "if-let") or (head.text == "with-open")))
end
local function alignment_form_3f(node, parent)
  return (parent and (node.kind == "sequence") and (parent.kind == "list") and alignment_form_name_3f(helpers["nontrivia-children"](parent)[1]))
end
local function clause_form_name_3f(head)
  return (head and (head.kind == "symbol") and ((head.text == "case") or (head.text == "match") or (head.text == "case-try") or (head.text == "match-try") or (head.text == "if")))
end
local function clause_form_3f(node)
  return ((node.kind == "list") and clause_form_name_3f(helpers["nontrivia-children"](node)[1]))
end
local function alignment_node_3f(node, parent)
  return ((node.kind == "table") or alignment_form_3f(node, parent) or clause_form_3f(node))
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
  for _, child in ipairs((node.children or {})) do
    state = ((child.text and state) or (child.children and collect_alignment_nodes(child, node, state)) or state)
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
    return append_pair_candidate(result, {name = name_start, ["name-end"] = name_end, value = value_start, ["value-node"] = value, ["parent-kind"] = parent_kind, line = name_start.line})
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
local function clause_pair_3f(node, pair)
  return (not clause_form_3f(node) or (pair.line > node.open.line))
end
local function comment_on_line_3f(node, line)
  local found = false
  for _, child in ipairs(node.children) do
    found = (found or (child.text and (child.kind == "comment") and (child.line == line)))
  end
  return found
end
local function usable_pair_3f(node, pair)
  return (clause_pair_3f(node, pair) and not comment_on_line_3f(node, pair.line))
end
local function usable_pair_result(node, pair)
  if usable_pair_3f(node, pair) then
    return pair
  else
    return nil
  end
end
local function usable_pairs(node, pairs)
  local tbl_26_ = {}
  local i_27_ = 0
  for _, pair in ipairs(pairs) do
    local val_28_ = usable_pair_result(node, pair)
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function alignment_plan_result(pairs)
  if (#pairs > 1) then
    return {pairs = pairs, width = alignment_width(pairs)}
  else
    return nil
  end
end
local function alignment_start(node)
  if clause_form_3f(node) then
    return clause_start_index(node)
  else
    return 1
  end
end
local function alignment_plan(node)
  local children = helpers["nontrivia-children"](node)
  local start = alignment_start(node)
  local pairs = single_pairs(pair_candidates(children, start, {}, node.kind))
  local usable = usable_pairs(node, pairs)
  return alignment_plan_result(usable)
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
local function append_alignment_edit(edits, plan, pair)
  local name_width = pair_name_width(pair)
  local name_end_column = (pair.name["out-col"] + name_width)
  local target = pair_target(pair, plan.width)
  return table.insert(edits, {line = pair.line, start = (name_end_column + 1), finish = (pair.value["out-col"] + 1), spaces = (target - name_end_column)})
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
  local function _19_(left, right)
    return (left.start > right.start)
  end
  table.sort(edits, _19_)
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
  local function apply0(output, tree)
    local nodes = collect_alignment_nodes(tree, nil, {})
    return apply_alignment(output, alignment_plans(nodes))
  end
  _2amodule_2a["apply"] = apply0
  apply = _2amodule_2a.apply
end
return nil
