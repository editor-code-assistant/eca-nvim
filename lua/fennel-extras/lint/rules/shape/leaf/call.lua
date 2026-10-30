-- [nfnl] fnl/fennel-extras/lint/rules/shape/leaf/call.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.shape.leaf.call"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.shape.leaf.call"]
end
local ast = require("fennel-extras.lint.rules.ast")
local valid = require("fennel-extras.lint.rules.shape.leaf.valid")
local meaningful_children = ast["meaningful-children"]
local list_head = ast["list-head"]
local quoted_child_3f = ast["quoted-child?"]
local loop_head_3f = valid["loop-head?"]
local function_head_3f = valid["function-head?"]
local layer_argument_valid_3f = valid["layer-argument-valid?"]
local leaf_valid_3f = valid["leaf-valid?"]
local function plain_call_layer_count(layer_3f)
  if layer_3f then
    return 1
  else
    return 0
  end
end
local function plain_call_layer_state(state, child)
  local child_head = list_head(child)
  local layer_3f = (loop_head_3f(child_head) or function_head_3f(child_head))
  return {valid = ((layer_3f and layer_argument_valid_3f(child, leaf_valid_3f)) or (not layer_3f and leaf_valid_3f(child))), layers = (state.layers + plain_call_layer_count(layer_3f))}
end
local function plain_call_state_step(children, state, child, index)
  if (state.valid and (index >= 2) and not quoted_child_3f(children, index)) then
    return plain_call_layer_state(state, child)
  else
    return state
  end
end
local function plain_call_result(children)
  local state = {valid = true, layers = 0}
  for index, child in ipairs(children) do
    state = plain_call_state_step(children, state, child, index)
  end
  return state
end
local plain_call_one_layer_3f
do
  local function plain_call_one_layer_3f0(node)
    local children = meaningful_children(node)
    local result = plain_call_result(children)
    return (result.valid and (result.layers >= 1))
  end
  _2amodule_2a["plain-call-one-layer?"] = plain_call_one_layer_3f0
  plain_call_one_layer_3f = _2amodule_2a["plain-call-one-layer?"]
end
local leaf_violations
do
  local function leaf_violations0(node)
    if leaf_valid_3f(node) then
      return {}
    else
      return {node}
    end
  end
  _2amodule_2a["leaf-violations"] = leaf_violations0
  leaf_violations = _2amodule_2a["leaf-violations"]
end
local expression_violations
do
  local function expression_violations0(node)
    local head = list_head(node)
    return (((head == "do") and {node}) or ((head == "let") and {node}) or ((node.kind == "list") and ((loop_head_3f(head) and not ((head == "icollect") or (head == "collect") or (head == "accumulate"))) or function_head_3f(head)) and {node}) or leaf_violations(node))
  end
  _2amodule_2a["expression-violations"] = expression_violations0
  expression_violations = _2amodule_2a["expression-violations"]
end
return nil
