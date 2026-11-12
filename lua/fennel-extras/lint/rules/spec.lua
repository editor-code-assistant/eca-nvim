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
local function nil_literal_3f(node)
  return (node and (node.kind == "symbol") and (node.text == "nil"))
end
local function contains_3f(items, target, index)
  return ((index <= #items) and ((items[index] == target) or contains_3f(items, target, (index + 1))))
end
local function not_counted_literal_3f(node, options)
  return (node and (node.kind == "symbol") and contains_3f((options["not-counted"] or {}), node.text, 1))
end
local function direct_count_step(children, options, index, result)
  if (index > #children) then
    return result
  else
    local function _3_()
      if not not_counted_literal_3f(children[index], options) then
        return (result + 1)
      else
        return result
      end
    end
    return direct_count_step(children, options, (index + 1), _3_())
  end
end
local function direct_count(node, options)
  local children = meaningful_children(node)
  local start
  if (list_head(node) == "if") then
    start = 3
  else
    start = 2
  end
  return direct_count_step(children, options, start, 0)
end
local function direct_child_valid_3f(node, options)
  local children = meaningful_children(node)
  local head = list_head(node)
  local missing = ((head == "if") and (#children == 3))
  local multi_clause = ((head == "if") and (#children > 4))
  local nil_else = ((head == "if") and (#children == 4) and nil_literal_3f(children[4]))
  local count = direct_count(node, options)
  local min = options["min-count"]
  local max = options["max-count"]
  return (not missing and not multi_clause and (not nil_else or options["nil-count"] or contains_3f((options["not-counted"] or {}), "nil", 1)) and (count >= min) and (count <= max))
end
local function child_count_invalid_3f(node, options)
  if options.children then
    return (count_child_forms(node, options.children, 1, 0) ~= options["max-count"])
  else
    return not direct_child_valid_3f(node, options)
  end
end
local child_count_finding
do
  local function child_count_finding0(findings, path, form, policy, node)
    local options = rule_options(policy, "child-count")
    local form_applies = ((#(options.forms or {}) == 0) or contains_3f(options.forms, list_head(node), 1))
    if (form_applies and enabled_3f(policy, "child-count") and child_count_invalid_3f(node, options)) then
      return table.insert(findings, finding(path, form, rule_severity(policy, "child-count"), "child-count", "form has an invalid child count", node))
    else
      return nil
    end
  end
  _2amodule_2a["child-count-finding"] = child_count_finding0
  child_count_finding = _2amodule_2a["child-count-finding"]
end
return nil
