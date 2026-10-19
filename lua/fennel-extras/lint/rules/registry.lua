-- [nfnl] fnl/fennel-extras/lint/rules/registry.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.registry"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.registry"]
end
local defaults_map = {["module-style"] = "error", ["spec-macro-import"] = "error", ["spec-no-module"] = "error", ["spec-direct-require"] = "error", ["one-is-per-testing"] = "error", ["if-branch-call"] = "warning", ["function-shape"] = "warning", ["no-mutation"] = "warning", ["file-size"] = "warning", ["core-require"] = "error"}
local rule_properties = {["module-style"] = {scope = "file"}, ["spec-macro-import"] = {scope = "file"}, ["file-size"] = {scope = "file"}}
local defaults
do
  local function defaults0()
    return defaults_map
  end
  _2amodule_2a["defaults"] = defaults0
  defaults = _2amodule_2a.defaults
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
    local override = (policy and policy[rule])
    return (override or defaults_map[rule])
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
