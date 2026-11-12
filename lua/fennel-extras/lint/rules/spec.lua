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
local function executable_child_3f(node)
  return (node and (node.kind ~= "prefix"))
end
local function append_executable_child(result, child, depth)
  if executable_child_3f(child) then
    return table.insert(result, {node = child, depth = depth})
  else
    return nil
  end
end
local function function_form_3f(node)
  return ((node.kind == "list") and ((list_head(node) == "fn") or (list_head(node) == "defn") or (list_head(node) == "defn-")))
end
local function collect_executable_children_step(children, index, result, depth, recursive_3f, recurse)
  if (index > #children) then
    return result
  else
    local child = children[index]
    if ast["quoted-child?"](children, index) then
      return recurse(children, (index + 1), result, depth, recursive_3f, recurse)
    else
      append_executable_child(result, child, depth)
      if ((child.kind == "list") and (recursive_3f or function_form_3f(child))) then
        local nested = recurse(meaningful_children(child), 2, result, (depth + 1), recursive_3f, recurse)
        return recurse(children, (index + 1), nested, depth, recursive_3f, recurse)
      else
        return recurse(children, (index + 1), result, depth, recursive_3f, recurse)
      end
    end
  end
end
local function collect_executable_children(node, start, recursive_3f)
  return collect_executable_children_step(meaningful_children(node), start, {}, 0, recursive_3f, collect_executable_children_step)
end
local function name_in_3f(names, target, index)
  return ((index <= #names) and ((names[index] == target) or name_in_3f(names, target, (index + 1))))
end
local function named_child_count_step(children, names, index, result, recurse)
  if (index > #children) then
    return result
  else
    if ast["quoted-child?"](children, index) then
      return recurse(children, names, (index + 1), result, recurse)
    else
      local node = children[index]
      local nested
      if (node.kind == "list") then
        nested = recurse(meaningful_children(node), names, 2, result, recurse)
      else
        nested = result
      end
      local _7_
      if ((node.kind == "list") and name_in_3f(names, list_head(node), 1)) then
        _7_ = (nested + 1)
      else
        _7_ = nested
      end
      return recurse(children, names, (index + 1), _7_, recurse)
    end
  end
end
local function named_child_count(node, names)
  return named_child_count_step(meaningful_children(node), names, 2, 0, named_child_count_step)
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
local function executable_count_step(children, options, index, result)
  if (index > #children) then
    return result
  else
    local child = children[index]
    local function _12_()
      if not not_counted_literal_3f(child.node, options) then
        return (result + 1)
      else
        return result
      end
    end
    return executable_count_step(children, options, (index + 1), _12_())
  end
end
local function direct_count(node, options)
  local start
  if (list_head(node) == "if") then
    start = 3
  else
    start = 2
  end
  return executable_count_step(collect_executable_children(node, start, false), options, 1, 0)
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
    return (named_child_count(node, options.children) ~= options["max-count"])
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
