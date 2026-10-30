-- [nfnl] fnl/fennel-extras/lint/rules/registry.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.registry"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.registry"]
end
local core = require("eca.nfnl.core")
local lint_rule_name_list = {"forbidden-form", "required-form", "module-style", "module-import", "form-child-count", "control-layout", "unused-and-or", "multiline-layout", "file-size", "call-data-arg"}
local design_rule_name_list = {"function-shape", "if-branch-call", "if-without-else", "nested-forms", "leading-bindings", "no-mutation"}
local rule_name_list = core.concat(lint_rule_name_list, {"function-shape", "if-branch-call", "if-without-else"})
local ast = require("fennel-extras.lint.rules.ast")
local options = require("fennel-extras.lint.rules.options")
local rule_properties = {["module-style"] = {scope = "file"}, ["required-form"] = {scope = "file"}, ["file-size"] = {scope = "file"}}
local semantic_applies_to = {["forbidden-form"] = {"module", "forms"}, ["required-form"] = {"forms"}, ["module-style"] = {"module", "forms"}, ["module-import"] = {"module", "modules", "forms"}, ["if-branch-call"] = {"forms"}, ["if-without-else"] = {"forms"}, ["control-layout"] = {"forms"}, ["unused-and-or"] = {"forms"}, ["function-shape"] = {"forms"}, ["call-data-arg"] = {"forms"}, ["nested-forms"] = {"forms"}, ["leading-bindings"] = {"forms"}, ["no-mutation"] = {"forms"}}
local required_semantic_applies_to = {["required-form"] = {"forms"}, ["module-style"] = {"module", "forms"}, ["if-branch-call"] = {"forms"}, ["if-without-else"] = {"forms"}, ["control-layout"] = {"forms"}, ["unused-and-or"] = {"forms"}, ["function-shape"] = {"forms"}, ["call-data-arg"] = {"forms"}, ["nested-forms"] = {"forms"}, ["leading-bindings"] = {"forms"}, ["no-mutation"] = {"forms"}}
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
local lint_rule_names
do
  local function lint_rule_names0()
    return lint_rule_name_list
  end
  _2amodule_2a["lint-rule-names"] = lint_rule_names0
  lint_rule_names = _2amodule_2a["lint-rule-names"]
end
local design_rule_names
do
  local function design_rule_names0()
    return design_rule_name_list
  end
  _2amodule_2a["design-rule-names"] = design_rule_names0
  design_rule_names = _2amodule_2a["design-rule-names"]
end
local rule_domain
do
  local function rule_domain0(rule)
    local _1_
    do
      local found = false
      for _, name in ipairs(design_rule_name_list) do
        found = (found or (name == rule))
      end
      _1_ = found
    end
    if _1_ then
      return "design"
    else
      return "lint"
    end
  end
  _2amodule_2a["rule-domain"] = rule_domain0
  rule_domain = _2amodule_2a["rule-domain"]
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
local applies_to_required_names
do
  local function applies_to_required_names0(rule)
    return required_semantic_applies_to[rule]
  end
  _2amodule_2a["applies-to-required-names"] = applies_to_required_names0
  applies_to_required_names = _2amodule_2a["applies-to-required-names"]
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
    local lint_rules = ((policy and policy.rules) or (policy and not policy.rules and policy) or {})
    local design_rules = ((policy and policy.design) or lint_rules or {})
    local result = {}
    for _, rule in ipairs(lint_rule_name_list) do
      append_instances(result, rule, (lint_rules[rule] or {}))
    end
    for _, rule in ipairs(design_rule_name_list) do
      append_instances(result, rule, (design_rules[rule] or {}))
    end
    return result
  end
  _2amodule_2a["instances"] = instances0
  instances = _2amodule_2a.instances
end
local function singleton_module_value(value)
  if (type(value) == "string") then
    return value
  else
    if ((type(value) == "table") and (#value == 1)) then
      return value[1]
    else
      return value
    end
  end
end
local function module_set_value(value)
  if (type(value) == "string") then
    return {value}
  else
    return value
  end
end
local function semantic_option_value(applies, name, singleton)
  if (name == "module") then
    if singleton then
      return singleton_module_value(applies.modules)
    else
      return nil
    end
  else
    if (name == "modules") then
      return module_set_value(applies.modules)
    else
      return applies.forms
    end
  end
end
local function normalized_options(rule, instance)
  local options0 = core.merge((instance.options or {}))
  local applies = (instance["applies-to"] or {})
  local singleton = ((rule == "forbidden-form") or (rule == "module-style") or ((rule == "module-import") and (options0.mode == "require")))
  local result = options0
  for _, name in ipairs((semantic_applies_to[rule] or {})) do
    local value = semantic_option_value(applies, name, singleton)
    if ((value == nil) or ((rule == "module-import") and (name == "modules") and (type(applies.modules) == "string") and options0.modules)) then
      result = result
    else
      result = core.assoc(result, name, value)
    end
  end
  return result
end
local evaluator_policy
do
  local function evaluator_policy0(policy, rule, instance)
    local base_result = core.assoc(defaults(), rule, instance.severity)
    local result
    if (rule == "no-mutation") then
      result = core.assoc(core.assoc(base_result, "forbidden-form", instance.severity), "no-mutation", instance.severity)
    else
      result = base_result
    end
    local raw_options = normalized_options(rule, instance)
    local normalized
    if ((rule == "module-import") and raw_options.module and (raw_options.mode == "forbid")) then
      normalized = core.assoc(raw_options, "mode", "require")
    else
      normalized = raw_options
    end
    local with_options = core.assoc(result, "options", normalized)
    return core.assoc(with_options, "matcher", policy.matcher)
  end
  _2amodule_2a["evaluator-policy"] = evaluator_policy0
  evaluator_policy = _2amodule_2a["evaluator-policy"]
end
local function matches_3f(matcher, pattern, value)
  local and_12_ = pattern and value
  if and_12_ then
    if matcher then
      and_12_ = matcher(pattern, value)
    else
      and_12_ = (vim.fn.match(value, pattern) >= 0)
    end
  end
  return and_12_
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
local function semantic_name_3f(rule, name)
  local found = false
  for _, candidate in ipairs((semantic_applies_to[rule] or {})) do
    found = (found or (candidate == name))
  end
  return found
end
local function generic_applies_to(rule, applies)
  local result = {}
  for _, name in ipairs({"files", "forms", "modules"}) do
    if (applies[name] and not (semantic_name_3f(rule, name) or ((name == "modules") and semantic_name_3f(rule, "module")))) then
      result[name] = (((name == "modules") and module_set_value(applies[name])) or applies[name])
    else
    end
  end
  return result
end
local instance_applies_to_3f
do
  local function instance_applies_to_3f0(rule, instance, finding, matcher)
    return scope_matches_3f(generic_applies_to(rule, (instance["applies-to"] or {})), finding, matcher)
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
