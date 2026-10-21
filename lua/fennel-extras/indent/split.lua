-- [nfnl] fnl/fennel-extras/indent/split.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.indent.split"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.indent.split"]
end
local reader = require("fennel-extras.reader")
local helpers = require("fennel-extras.indent.node")
local bindings = require("fennel-extras.indent.bindings")
local binding_forms = {let = true, ["when-let"] = true, ["if-let"] = true, ["with-open"] = true}
local function prefixed_3f(child)
  return (child and child.text and (child.kind == "prefix"))
end
local function quoted_child_3f(previous)
  return prefixed_3f(previous)
end
local function binding_head(node)
  return bindings["meaningful-children"](node)[1]
end
local function supported_form_3f(node)
  local head = binding_head(node)
  return ((node.kind == "list") and head and (head.kind == "symbol") and binding_forms[head.text])
end
local function same_line_edit(name_start, value_end)
  if (name_start and value_end and (name_start.line == value_end.line)) then
    return {line = name_start.line, column = name_start.col}
  else
    return nil
  end
end
local function pair_edit(pair)
  local name_start = (pair.name and helpers["child-start"](pair.name))
  local value_end = (pair["previous-end"] and helpers["child-end"](pair["previous-end"]))
  return same_line_edit(name_start, value_end)
end
local function append_edit(edits, edit)
  table.insert(edits, edit)
  return edits
end
local function pair_edit_result(edits, pair)
  local edit = pair_edit(pair)
  if edit then
    return append_edit(edits, edit)
  else
    return edits
  end
end
local function pair_edits(vector)
  local edits = {}
  for _, pair in ipairs(bindings.pairs(vector)) do
    edits = pair_edit_result(edits, pair)
  end
  return edits
end
local function vector_edits(node)
  local vector = bindings["meaningful-children"](node)[2]
  if (vector and (vector.kind == "sequence")) then
    return pair_edits(vector)
  else
    return {}
  end
end
local function append_edits_step(result, edit)
  table.insert(result, edit)
  return result
end
local function append_edits(left, right)
  local result = left
  for _, edit in ipairs(right) do
    result = append_edits_step(result, edit)
  end
  return result
end
local function walk_text_child(state, child)
  return {edits = state.edits, previous = child}
end
local function walk_nested_child(recur, state, child, quoted)
  local child_quoted = (quoted or quoted_child_3f(state.previous))
  local nested = recur(child, child_quoted)
  local edits = append_edits(state.edits, nested)
  return {edits = edits, previous = nil}
end
local function walk_child(recur, state, child, quoted)
  if child.text then
    return walk_text_child(state, child)
  else
    return walk_nested_child(recur, state, child, quoted)
  end
end
local function walk_edits(node, quoted)
  if (not quoted and supported_form_3f(node)) then
    return vector_edits(node)
  else
    return {}
  end
end
local function walk_state(recur, node, edits, quoted)
  local state = {edits = edits, previous = nil}
  for _, child in ipairs((node.children or {})) do
    state = walk_child(recur, state, child, quoted)
  end
  return state
end
local function walk_node(node, quoted)
  local edits = walk_edits(node, quoted)
  local state = walk_state(walk_node, node, edits, quoted)
  return state.edits
end
local function whitespace_3f(line, index)
  local character = string.sub(line, index, index)
  return ((character == " ") or (character == "\t"))
end
local function whitespace_start(line, finish)
  if ((finish > 1) and whitespace_3f(line, (finish - 1))) then
    return whitespace_start(line, (finish - 1))
  else
    return finish
  end
end
local function apply_edit(line, edit)
  local finish = edit.column
  local start = whitespace_start(line, finish)
  return (string.sub(line, 1, (start - 1)) .. "\n" .. string.sub(line, finish))
end
local function prepend_line(lines, line)
  table.insert(lines, 1, line)
  return lines
end
local function split_lines_step(recur, source, at)
  local line = string.sub(source, 1, (at - 1))
  local lines = recur(string.sub(source, (at + 1)))
  return prepend_line(lines, line)
end
local function split_lines(source)
  local at = string.find(source, "\n", 1, true)
  if at then
    return split_lines_step(split_lines, source, at)
  else
    return {source}
  end
end
local function apply_edit_step(recur, lines, edits, edit)
  local line = lines[edit.line]
  local value = apply_edit(line, edit)
  lines[edit.line] = value
  return recur(recur, lines, edits)
end
local function apply_edits_step(recur, lines, edits)
  if (#edits == 0) then
    return lines
  else
    return apply_edit_step(recur, lines, edits, table.remove(edits, 1))
  end
end
local function edit_before_3f(left, right)
  if (left.line == right.line) then
    return (left.column > right.column)
  else
    return (left.line > right.line)
  end
end
local function apply_edits(source, edits)
  local lines = split_lines(source)
  table.sort(edits, edit_before_3f)
  return table.concat(apply_edits_step(apply_edits_step, lines, edits), "\n")
end
local function split_success(source, tree)
  local edits = walk_node(tree, false)
  return apply_edits(source, edits), nil, edits
end
local split
do
  local function split0(source)
    local tree, error = reader.parse(source)
    if error then
      return nil, error, {}
    else
      return split_success(source, tree)
    end
  end
  _2amodule_2a["split"] = split0
  split = _2amodule_2a.split
end
return nil
