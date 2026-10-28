-- [nfnl] fnl/fennel-extras/lint/rules/registry.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.registry"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.registry"]
end
local rule_name_list = {"forbidden-form", "required-form", "module-style", "module-import", "form-child-count", "if-branch-call", "if-without-else", "control-layout", "unused-and-or", "function-shape", "multiline-layout", "file-size", "call-data-arg"}
local core = require("eca.nfnl.core")
local ast = require("fennel-extras.lint.rules.ast")
local options = require("fennel-extras.lint.rules.options")
local rule_properties = {["module-style"] = {scope = "file"}, ["required-form"] = {scope = "file"}, ["file-size"] = {scope = "file"}}
local defaults
do
  local function defaults0()
    local result = {}
    for _, rule in ipairs(rule_name_list) do
      result[rule] = "off"
    end
    return result
  end
  _2amodule_2a["defaults"] = defaults0
  defaults = _2amodule_2a.defaults
end
local rule_names
do
  local function rule_names0()
    return rule_name_list
  end
  _2amodule_2a["rule-names"] = rule_names0
  rule_names = _2amodule_2a["rule-names"]
end
local option_schema
do
  local function option_schema0(rule)
    return options.schema(rule)
  end
  _2amodule_2a["option-schema"] = option_schema0
  option_schema = _2amodule_2a["option-schema"]
end
local required_option_names
do
  local function required_option_names0(rule)
    return options["required-names"](rule)
  end
  _2amodule_2a["required-option-names"] = required_option_names0
  required_option_names = _2amodule_2a["required-option-names"]
end
local rule_scope
do
  local function rule_scope0(rule)
    local properties = rule_properties[rule]
    return (properties and properties.scope)
  end
  _2amodule_2a["rule-scope"] = rule_scope0
  rule_scope = _2amodule_2a["rule-scope"]
end
local function append_instances(result, rule, instances)
  for index, instance in ipairs(instances) do
    table.insert(result, {rule = rule, index = index, value = instance})
  end
  return result
end
local instances
do
  local function instances0(policy)
    local rules = ((policy and policy.rules) or policy)
    local result = {}
    for _, rule in ipairs(rule_name_list) do
      append_instances(result, rule, (rules[rule] or {}))
    end
    return result
  end
  _2amodule_2a["instances"] = instances0
  instances = _2amodule_2a.instances
end
local evaluator_policy
do
  local function evaluator_policy0(policy, rule, instance)
    local result = defaults()
    local with_options = core.assoc(result, "options", (instance.options or {}))
    result[rule] = instance.severity
    return core.assoc(with_options, "matcher", policy.matcher)
  end
  _2amodule_2a["evaluator-policy"] = evaluator_policy0
  evaluator_policy = _2amodule_2a["evaluator-policy"]
end
local function matches_3f(matcher, pattern, value)
  local and_1_ = pattern and value
  if and_1_ then
    if matcher then
      and_1_ = matcher(pattern, value)
    else
      and_1_ = (pattern == value)
    end
  end
  return and_1_
end
local function any_match_3f(items, matcher, value)
  local result = false
  for _, pattern in ipairs(items) do
    result = (result or matches_3f(matcher, pattern, value))
  end
  return result
end
local function node_form(node)
  return ast["list-head"](node)
end
local function node_module(node)
  return node.text
end
local function node_matches_3f(items, finding, matcher, value_fn)
  return ((#items == 0) or (finding.node and any_match_3f(items, matcher, value_fn(finding.node))))
end
local function scope_matches_3f(applies, finding, matcher)
  return (((#(applies.files or {}) == 0) or any_match_3f((applies.files or {}), matcher, finding.path)) and node_matches_3f((applies.forms or {}), finding, matcher, node_form) and node_matches_3f((applies.modules or {}), finding, matcher, node_module))
end
local instance_applies_to_3f
do
  local function instance_applies_to_3f0(instance, finding, matcher)
    return scope_matches_3f((instance["applies-to"] or {}), finding, matcher)
  end
  _2amodule_2a["instance-applies-to?"] = instance_applies_to_3f0
  instance_applies_to_3f = _2amodule_2a["instance-applies-to?"]
end
local rule_options
do
  local function rule_options0(policy, rule)
    return (policy and policy.options)
  end
  _2amodule_2a["rule-options"] = rule_options0
  rule_options = _2amodule_2a["rule-options"]
end
local finding
do
  local function finding0(path, form, severity, rule, message, node)
    return {kind = "finding", path = path, line = form.line, col = form.col, ["end-line"] = form["end-line"], ["end-col"] = form["end-col"], severity = severity, rule = rule, form = form.form, message = message, node = node}
  end
  _2amodule_2a["finding"] = finding0
  finding = _2amodule_2a.finding
end
local rule_severity
do
  local function rule_severity0(policy, rule)
    return ((policy and policy[rule]) or "off")
  end
  _2amodule_2a["rule-severity"] = rule_severity0
  rule_severity = _2amodule_2a["rule-severity"]
end
local enabled_3f
do
  local function enabled_3f0(policy, rule)
    return (rule_severity(policy, rule) ~= "off")
  end
  _2amodule_2a["enabled?"] = enabled_3f0
  enabled_3f = _2amodule_2a["enabled?"]
end
return nil
