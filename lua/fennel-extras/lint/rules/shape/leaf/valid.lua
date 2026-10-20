-- [nfnl] fnl/fennel-extras/lint/rules/shape/leaf/valid.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.shape.leaf.valid"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.shape.leaf.valid"]
end
local ast = require("fennel-extras.lint.rules.ast")
local meaningful_children = ast["meaningful-children"]
local symbol_text = ast["symbol-text"]
local list_head = ast["list-head"]
local quoted_child_3f = ast["quoted-child?"]
local append_nodes = ast["append-nodes"]
local function_head_3f
do
  local function function_head_3f0(head)
    return ((head == "defn") or (head == "defn-") or (head == "fn") or (head == "lambda") or (head == "\206\187"))
  end
  _2amodule_2a["function-head?"] = function_head_3f0
  function_head_3f = _2amodule_2a["function-head?"]
end
local layer_head_3f
do
  local function layer_head_3f0(head)
    return ((head == "if") or (head == "when") or (head == "case") or (head == "match") or (head == "each") or (head == "for") or (head == "icollect") or (head == "collect") or (head == "accumulate") or (head == "while") or function_head_3f(head))
  end
  _2amodule_2a["layer-head?"] = layer_head_3f0
  layer_head_3f = _2amodule_2a["layer-head?"]
end
local loop_head_3f
do
  local function loop_head_3f0(head)
    return ((head == "each") or (head == "for") or (head == "icollect") or (head == "collect") or (head == "accumulate") or (head == "while"))
  end
  _2amodule_2a["loop-head?"] = loop_head_3f0
  loop_head_3f = _2amodule_2a["loop-head?"]
end
local function append_nodes0(target, nodes)
  for _, node in ipairs(nodes) do
    table.insert(target, node)
  end
  return target
end
local function parameter_index(children, head, index)
  if (index > #children) then
    return nil
  else
    return (((head ~= "defn") and (head ~= "defn-") and (children[index].kind == "sequence") and index) or parameter_index(children, head, (index + 1)))
  end
end
local function docstring_adjusted_index(children, index)
  if (index and children[index] and (children[index].kind == "string")) then
    return (index + 1)
  else
    return index
  end
end
local function function_body_child(children, body_start, index, child)
  if (body_start and (index >= body_start) and not quoted_child_3f(children, index)) then
    return child
  else
    return nil
  end
end
local function function_body(children, body_start)
  local tbl_26_ = {}
  local i_27_ = 0
  for index, child in ipairs(children) do
    local val_28_ = function_body_child(children, body_start, index, child)
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function function_parameter(children, head)
  if ((head == "defn") or (head == "defn-")) then
    return 3
  else
    return parameter_index(children, head, 2)
  end
end
local function function_body_index(parameter)
  return (parameter and (parameter + 1))
end
local function function_body_start(children, parameter)
  return docstring_adjusted_index(children, function_body_index(parameter))
end
local function_info
do
  local function function_info0(node)
    local children = meaningful_children(node)
    local head = symbol_text(children[1])
    local parameter = function_parameter(children, head)
    local body_start = function_body_start(children, parameter)
    local body = function_body(children, body_start)
    return (function_head_3f(head) and parameter and {head = head, children = children, parameter = parameter, body = body})
  end
  _2amodule_2a["function-info"] = function_info0
  function_info = _2amodule_2a["function-info"]
end
local function marker_3f(node, text)
  return (node and (node.kind == "symbol") and (node.text == text))
end
local function direct_layer_3f(children, index)
  return (not quoted_child_3f(children, index) and (loop_head_3f(list_head(children[index])) or function_head_3f(list_head(children[index]))))
end
local function direct_layer_value(children, index)
  if direct_layer_3f(children, index) then
    return 1
  else
    return 0
  end
end
local function layer_value(layer_3f)
  if layer_3f then
    return 1
  else
    return 0
  end
end
local function direct_layer_count(children, index)
  return (((index > #children) and 0) or (direct_layer_value(children, index) + direct_layer_count(children, (index + 1))))
end
local function leaf_valid_sequence_step(state, children, child, index, valid_3f)
  return (state and (quoted_child_3f(children, index) or valid_3f(child)))
end
local function leaf_valid_sequence_3f(node, valid_3f)
  local children = meaningful_children(node)
  local state = true
  for index, child in ipairs(children) do
    state = leaf_valid_sequence_step(state, children, child, index, valid_3f)
  end
  return state
end
local function leaf_valid_binding_step(state, children, child, index, valid_3f)
  return (state and ((index < 2) or quoted_child_3f(children, index) or valid_3f(child)))
end
local function leaf_valid_binding_list_3f(children, valid_3f)
  local state = true
  for index, child in ipairs(children) do
    state = leaf_valid_binding_step(state, children, child, index, valid_3f)
  end
  return state
end
local function function_argument_leaf_valid_3f(node, valid_3f)
  local info = function_info(node)
  local body = ((info and info.body) or {})
  local and_8_ = info
  if and_8_ then
    local state = true
    for _, child in ipairs(body) do
      state = (state and valid_3f(child))
    end
    and_8_ = state
  end
  return and_8_
end
local function loop_start_index(bindings)
  if (bindings and (#bindings > 0)) then
    return 3
  else
    return 2
  end
end
local function loop_argument_leaf_valid_3f(node, valid_3f)
  local children = meaningful_children(node)
  local bindings = (children[2] and (children[2].kind == "sequence") and meaningful_children(children[2]))
  local start = loop_start_index(bindings)
  local and_10_ = (not bindings or leaf_valid_sequence_3f(children[2], valid_3f))
  if and_10_ then
    local state = true
    for index, child in ipairs(children) do
      state = (state and ((index < start) or quoted_child_3f(children, index) or valid_3f(child)))
    end
    and_10_ = state
  end
  return and_10_
end
local layer_argument_valid_3f
do
  local function layer_argument_valid_3f0(node, valid_3f)
    local head = list_head(node)
    return ((function_head_3f(head) and function_argument_leaf_valid_3f(node, valid_3f)) or (loop_head_3f(head) and loop_argument_leaf_valid_3f(node, valid_3f)))
  end
  _2amodule_2a["layer-argument-valid?"] = layer_argument_valid_3f0
  layer_argument_valid_3f = _2amodule_2a["layer-argument-valid?"]
end
local function leaf_valid_call_state_update(state, child, valid_3f)
  return {valid = (state.valid and valid_3f(child)), layers = state.layers}
end
local function leaf_valid_call_state_step(children, state, child, index, valid_3f)
  if (state.valid and (index >= 2) and not quoted_child_3f(children, index)) then
    return leaf_valid_call_state_update(state, child, valid_3f)
  else
    return state
  end
end
local function leaf_valid_call_state(children, valid_3f)
  local state = {valid = true, layers = 0}
  for index, child in ipairs(children) do
    state = leaf_valid_call_state_step(children, state, child, index, valid_3f)
  end
  return state
end
local function leaf_valid_call_3f(children, valid_3f)
  local result = leaf_valid_call_state(children, valid_3f)
  return (result.valid and (result.layers <= 1))
end
local function leaf_valid_list_3f(children, head, valid_3f)
  return (not (loop_head_3f(head) or function_head_3f(head)) and ((((head == "var") or (head == "set") or (head == "local") or (head == "tset")) and leaf_valid_binding_list_3f(children, valid_3f)) or (not ((head == "var") or (head == "set") or (head == "local") or (head == "tset")) and leaf_valid_call_3f(children, valid_3f))))
end
local function leaf_node_kind(node)
  return (((not node or (node.kind == "prefix") or (node.kind == "whitespace") or (node.kind == "newline") or (node.kind == "comment") or (node.kind == "string") or (node.kind == "symbol") or (node.kind == "number") or (node.kind == "boolean")) and "atomic") or ((node.kind == "sequence") and "sequence") or ((node.kind == "table") and "table") or ((node.kind == "list") and "list") or "other")
end
local function leaf_valid_list_node_3f(node, valid_3f)
  local children = meaningful_children(node)
  local head = symbol_text(children[1])
  if (head == "do") then
    return ((#children == 2) and (quoted_child_3f(children, 2) or valid_3f(children[2])))
  elseif (head == "if") then
    return false
  elseif (head == "when") then
    return false
  elseif (head == "case") then
    return false
  elseif (head == "match") then
    return false
  elseif (head == "let") then
    return false
  else
    local _ = head
    return leaf_valid_list_3f(children, head, valid_3f)
  end
end
local leaf_valid_3f
do
  local function leaf_valid_3f0(node)
    local case_13_ = leaf_node_kind(node)
    if (case_13_ == "atomic") then
      return true
    elseif (case_13_ == "sequence") then
      return leaf_valid_sequence_3f(node, leaf_valid_3f0)
    elseif (case_13_ == "table") then
      return leaf_valid_sequence_3f(node, leaf_valid_3f0)
    elseif (case_13_ == "list") then
      return leaf_valid_list_node_3f(node, leaf_valid_3f0)
    elseif (case_13_ == "other") then
      return true
    else
      return nil
    end
  end
  _2amodule_2a["leaf-valid?"] = leaf_valid_3f0
  leaf_valid_3f = _2amodule_2a["leaf-valid?"]
end
return nil
