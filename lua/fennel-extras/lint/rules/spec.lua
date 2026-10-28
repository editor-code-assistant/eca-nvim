-- [nfnl] fnl/fennel-extras/lint/rules/spec.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.spec"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.spec"]
end
local ast = require("fennel-extras.lint.rules.ast")
local registry = require("fennel-extras.lint.rules.registry")
local meaningful_children = ast["meaningful-children"]
local list_head = ast["list-head"]
local rule_options = registry["rule-options"]
local enabled_3f = registry["enabled?"]
local rule_severity = registry["rule-severity"]
local finding = registry.finding
local count_is = ast["count-is"]
local function count_child_forms(node, children, index, result)
  if (index > #children) then
    return result
  else
    return count_child_forms(node, children, (index + 1), (result + count_is(node, 1, 0, list_head(node), children[index])))
  end
end
local form_child_count_finding
do
  local function form_child_count_finding0(findings, path, form, policy, node)
    local options = rule_options(policy, "form-child-count")
    local count = count_child_forms(node, options.children, 1, 0)
    if (enabled_3f(policy, "form-child-count") and (count ~= options["max-count"])) then
      return table.insert(findings, finding(path, form, rule_severity(policy, "form-child-count"), "form-child-count", "each testing form must contain exactly one is", node))
    else
      return nil
    end
  end
  _2amodule_2a["form-child-count-finding"] = form_child_count_finding0
  form_child_count_finding = _2amodule_2a["form-child-count-finding"]
end
return nil
