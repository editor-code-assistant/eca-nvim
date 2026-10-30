-- [nfnl] fnl/fennel-extras/lint/rules/shape/branch.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.shape.branch"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.shape.branch"]
end
local ast = require("fennel-extras.lint.rules.ast")
local leaf = require("fennel-extras.lint.rules.shape.leaf")
local meaningful_children = ast["meaningful-children"]
local quoted_child_3f = ast["quoted-child?"]
local append_nodes = ast["append-nodes"]
local list_head = ast["list-head"]
local expression_violations = leaf["expression-violations"]
local leaf_valid_3f = leaf["leaf-valid?"]
local leaf_violations = leaf["leaf-violations"]
local layer_head_3f = leaf["layer-head?"]
local function_info = leaf["function-info"]
local plain_call_one_layer_3f = leaf["plain-call-one-layer?"]
local loop_head_3f = leaf["loop-head?"]
local marker_3f
local function _1_(node, text)
  return (node and (node.kind == "symbol") and (node.text == text))
end
marker_3f = _1_
local function_head_3f = leaf["function-head?"]
local function explicit_if_3f(children, index)
  if (index > #children) then
    return false
  else
    return (marker_3f(children[index], "then") or marker_3f(children[index], "elseif") or marker_3f(children[index], "else") or explicit_if_3f(children, (index + 1)))
  end
end
local function explicit_branch_result(children, index, result, recurse)
  if children[(index + 1)] then
    return recurse(children, (index + 2), append_nodes(result, expression_violations(children[(index + 1)])))
  else
    return recurse(children, (index + 1), result)
  end
end
local function validate_if_explicit_step(children, index, result, recurse)
  local child = children[index]
  if (marker_3f(child, "then") or marker_3f(child, "elseif") or marker_3f(child, "else")) then
    return explicit_branch_result(children, index, result, recurse)
  else
    return recurse(children, (index + 1), append_nodes(result, expression_violations(child)))
  end
end
local function validate_if_explicit(children, index, result)
  if (index > #children) then
    return result
  else
    return validate_if_explicit_step(children, index, result, validate_if_explicit)
  end
end
local function implicit_branch_values(children, index)
  return append_nodes(((children[(index + 1)] and expression_violations(children[(index + 1)])) or {}), expression_violations(children[index]))
end
local function append_implicit_branch(children, index, result)
  return append_nodes(result, implicit_branch_values(children, index))
end
local function validate_if_implicit(children, index, result)
  if (index > #children) then
    return result
  else
    return (((index == #children) and ((index % 2) == 0) and append_nodes(result, expression_violations(children[index]))) or validate_if_implicit(children, (index + 2), append_implicit_branch(children, index, result)))
  end
end
local function validate_if_children(children)
  if explicit_if_3f(children, 2) then
    return validate_if_explicit(children, 2, {})
  else
    return validate_if_implicit(children, 2, {})
  end
end
local function validate_if(node)
  return validate_if_children(meaningful_children(node))
end
local function validate_when_head(children, result)
  if children[2] then
    return append_nodes(result, expression_violations(children[2]))
  else
    return result
  end
end
local function append_if_index(result, index, threshold, value)
  if (index >= threshold) then
    return append_nodes(result, expression_violations(value))
  else
    return nil
  end
end
local function validate_when_body(children, result)
  for index, child in ipairs(children) do
    append_if_index(result, index, 3, child)
  end
  return result
end
local function validate_when(node)
  local children = meaningful_children(node)
  return validate_when_body(children, validate_when_head(children, {}))
end
local function loop_bindings(children)
  if (children[2] and (children[2].kind == "sequence")) then
    return meaningful_children(children[2])
  else
    return {}
  end
end
local function loop_start(bindings)
  if (#bindings > 0) then
    return 3
  else
    return 2
  end
end
local function append_if_unquoted(bindings, result, index, value)
  if not quoted_child_3f(bindings, index) then
    return append_nodes(result, expression_violations(value))
  else
    return nil
  end
end
local function validate_loop_bindings(bindings, result)
  for index, child in ipairs(bindings) do
    append_if_unquoted(bindings, result, index, child)
  end
  return result
end
local function validate_loop_body(children, start, result)
  for index, child in ipairs(children) do
    append_if_index(result, index, start, child)
  end
  return result
end
local function validate_loop(node)
  local children = meaningful_children(node)
  local bindings = loop_bindings(children)
  local start = loop_start(bindings)
  return validate_loop_body(children, start, validate_loop_bindings(bindings, {}))
end
local function validate_case(node)
  local result = {}
  for index, child in ipairs(meaningful_children(node)) do
    append_if_index(result, index, 2, child)
  end
  return result
end
local function function_layer_valid_3f(node)
  local info = function_info(node)
  local body = ((info and info.body) or {})
  local and_13_ = info
  if and_13_ then
    local state = true
    for _, child in ipairs(body) do
      state = (state and leaf_valid_3f(child))
    end
    and_13_ = state
  end
  return and_13_
end
local function validate_function_layer(node)
  if function_layer_valid_3f(node) then
    return {}
  else
    return {node}
  end
end
local function validate_layer_by_head(node, head)
  return (((head == "if") and validate_if(node)) or ((head == "when") and validate_when(node)) or (((head == "case") or (head == "match")) and validate_case(node)) or (loop_head_3f(head) and validate_loop(node)) or (function_head_3f(head) and validate_function_layer(node)) or {})
end
local function validate_layer(node)
  return validate_layer_by_head(node, list_head(node))
end
local function body_expression_result(node, head)
  return (((head == "let") and {node}) or ((head == "do") and {node}) or (layer_head_3f(head) and validate_layer(node)) or ((node.kind == "list") and plain_call_one_layer_3f(node) and {}) or expression_violations(node))
end
local function body_expression_violations(node)
  return body_expression_result(node, list_head(node))
end
local function validate_let_binding_step(binding_children, result, index, child)
  if (((index % 2) == 0) and not quoted_child_3f(binding_children, index)) then
    return append_nodes(result, leaf_violations(child))
  else
    return result
  end
end
local function validate_let_bindings_children(binding_children, result)
  local state = result
  for index, child in ipairs(binding_children) do
    state = validate_let_binding_step(binding_children, state, index, child)
  end
  return state
end
local function validate_let_bindings(bindings, result)
  if (bindings and (bindings.kind == "sequence")) then
    return validate_let_bindings_children(meaningful_children(bindings), result)
  else
    return result
  end
end
local function validate_let_body_child(result, index, child)
  if (index >= 3) then
    return append_nodes(result, body_expression_violations(child))
  else
    return nil
  end
end
local function validate_let_body(children, result)
  for index, child in ipairs(children) do
    validate_let_body_child(result, index, child)
  end
  return result
end
local function validate_let(node)
  local children = meaningful_children(node)
  local bindings = children[2]
  return validate_let_body(children, validate_let_bindings(bindings, {}))
end
local function function_first_let_3f(body)
  return (body[1] and (list_head(body[1]) == "let"))
end
local function function_body_start_index(first_let_3f)
  if first_let_3f then
    return 2
  else
    return 1
  end
end
local function function_body_initial(body, result, first_let_3f)
  if first_let_3f then
    return append_nodes(result, validate_let(body[1]))
  else
    return result
  end
end
local function validate_function_body_child(result, start, index, child)
  if (index >= start) then
    return append_nodes(result, body_expression_violations(child))
  else
    return nil
  end
end
local validate_function_body
do
  local function validate_function_body0(body, result)
    local first_let_3f = function_first_let_3f(body)
    local start = function_body_start_index(first_let_3f)
    local initial = function_body_initial(body, result, first_let_3f)
    for index, child in ipairs(body) do
      validate_function_body_child(initial, start, index, child)
    end
    return initial
  end
  _2amodule_2a["validate-function-body"] = validate_function_body0
  validate_function_body = _2amodule_2a["validate-function-body"]
end
return nil
