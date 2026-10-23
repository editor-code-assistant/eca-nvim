-- [nfnl] fnl/fennel-extras/lint/rules/registry.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.registry"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.registry"]
end
local rule_name_list = {"module-style", "spec-macro-import", "spec-no-module", "spec-direct-require", "one-is-per-testing", "if-branch-call", "if-without-else", "control-layout", "unused-and-or", "defn-args-newline", "function-shape", "no-mutation", "multiline-layout", "file-size", "core-require", "binding-per-line", "call-data-arg"}
local options = require("fennel-extras.lint.rules.options")
local rule_properties = {["module-style"] = {scope = "file"}, ["spec-macro-import"] = {scope = "file"}, ["file-size"] = {scope = "file"}}
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
local rule_scope
do
  local function rule_scope0(rule)
    local properties = rule_properties[rule]
    return (properties and properties.scope)
  end
  _2amodule_2a["rule-scope"] = rule_scope0
  rule_scope = _2amodule_2a["rule-scope"]
end
local rule_options
do
  local function rule_options0(policy, rule)
    return (policy and policy.options and policy.options[rule])
  end
  _2amodule_2a["rule-options"] = rule_options0
  rule_options = _2amodule_2a["rule-options"]
end
local applies_to_3f
do
  local function applies_to_3f0(policy, rule, spec_3f)
    local target = rule_options(policy, rule)["applies-to"]
    return ((target == "all") or (target == "spec") or ((target == "source") and not spec_3f))
  end
  _2amodule_2a["applies-to?"] = applies_to_3f0
  applies_to_3f = _2amodule_2a["applies-to?"]
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
