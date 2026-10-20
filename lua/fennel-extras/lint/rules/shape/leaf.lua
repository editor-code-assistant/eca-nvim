-- [nfnl] fnl/fennel-extras/lint/rules/shape/leaf.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.shape.leaf"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.shape.leaf"]
end
local valid = require("fennel-extras.lint.rules.shape.leaf.valid")
local call = require("fennel-extras.lint.rules.shape.leaf.call")
local function_head_3f
do
  _2amodule_2a["function-head?"] = valid["function-head?"]
  function_head_3f = _2amodule_2a["function-head?"]
end
local layer_head_3f
do
  _2amodule_2a["layer-head?"] = valid["layer-head?"]
  layer_head_3f = _2amodule_2a["layer-head?"]
end
local loop_head_3f
do
  _2amodule_2a["loop-head?"] = valid["loop-head?"]
  loop_head_3f = _2amodule_2a["loop-head?"]
end
local function_info
do
  _2amodule_2a["function-info"] = valid["function-info"]
  function_info = _2amodule_2a["function-info"]
end
local leaf_valid_3f
do
  _2amodule_2a["leaf-valid?"] = valid["leaf-valid?"]
  leaf_valid_3f = _2amodule_2a["leaf-valid?"]
end
local plain_call_one_layer_3f
do
  _2amodule_2a["plain-call-one-layer?"] = call["plain-call-one-layer?"]
  plain_call_one_layer_3f = _2amodule_2a["plain-call-one-layer?"]
end
local leaf_violations
do
  _2amodule_2a["leaf-violations"] = call["leaf-violations"]
  leaf_violations = _2amodule_2a["leaf-violations"]
end
local expression_violations
do
  _2amodule_2a["expression-violations"] = call["expression-violations"]
  expression_violations = _2amodule_2a["expression-violations"]
end
return nil
