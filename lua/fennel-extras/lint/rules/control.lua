-- [nfnl] fnl/fennel-extras/lint/rules/control.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.control"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.control"]
end
local core = require("eca.nfnl.core")
local ast = require("fennel-extras.lint.rules.ast")
local registry = require("fennel-extras.lint.rules.registry")
local list_head = ast["list-head"]
local meaningful_children = ast["meaningful-children"]
local previous_meaningful_index = ast["previous-meaningful-index"]
local form_for_node = ast["form-for-node"]
local nearest_form = ast["nearest-form"]
local finding = registry.finding
local enabled_3f = registry["enabled?"]
local rule_severity = registry["rule-severity"]
local function contains_3f(items, target, index)
  if (index > #items) then
    return false
  else
    return ((items[index] == target) or contains_3f(items, target, (index + 1)))
  end
end
local function_heads = {defn = true, ["defn-"] = true, fn = true, lambda = true, ["\206\187"] = true}
local binding_heads = {let = true, ["when-let"] = true, ["if-let"] = true, ["with-open"] = true}
local function quoted_mode_for_prefix(prefix, mode)
  return (((prefix == "'") and "quoted") or ((mode == "quoted") and "quoted") or ((prefix == "`") and (mode + 1)) or ((prefix == ",") and math.max(0, (mode - 1))) or mode)
end
local function quoted_mode_for_child(node, index, mode)
  local previous_index = previous_meaningful_index(node.children, index)
  local previous = (previous_index and node.children[previous_index])
  if (previous and (previous.kind == "prefix")) then
    return quoted_mode_for_prefix(previous.text, quoted_mode_for_child(node, previous_index, mode))
  else
    return mode
  end
end
local function meaningful_index_step(result, child, target, index)
  if ((result == 0) and (child == target)) then
    return index
  else
    return result
  end
end
local function meaningful_index(node, target)
  local children = meaningful_children(node)
  local result = 0
  for index, child in ipairs(children) do
    result = meaningful_index_step(result, child, target, index)
  end
  return result
end
local function function_body_offset(argument)
  if (argument and (argument.kind == "string")) then
    return 1
  else
    return 0
  end
end
local body_heads = {let = true, when = true, ["when-let"] = true, ["if-let"] = true, ["with-open"] = true, each = true, ["for"] = true, ["while"] = true, icollect = true, collect = true, accumulate = true}
local built_in_control_heads = {["if"] = true, when = true, ["and"] = true, ["or"] = true, case = true, match = true}
local function function_argument_index(head)
  return (((head == "defn") and 3) or ((head == "defn-") and 3) or 2)
end
local function function_base(head)
  return (((head == "defn") and 4) or ((head == "defn-") and 4) or 3)
end
local function body_form_3f(head, policy)
  return (body_heads[head] or (not built_in_control_heads[head] and contains_3f(registry["rule-options"](policy, "control-layout").forms, head, 1)))
end
local function body_start(head, children, policy)
  local argument = children[function_argument_index(head)]
  return ((function_heads[head] and (function_base(head) + function_body_offset(argument))) or (body_form_3f(head, policy) and 3) or ((head == "do") and 2) or 0)
end
local function body_child_3f(head, children, index, policy)
  local start = body_start(head, children, policy)
  return ((start > 0) and (index >= start))
end
local function last_body_child_3f(head, children, index, policy)
  return (body_child_3f(head, children, index, policy) and (index == #children))
end
local function custom_control_root_3f(parent, child, policy)
  return ((list_head(parent) == nil) and (child.kind == "list") and not built_in_control_heads[list_head(child)] and contains_3f(registry["rule-options"](policy, "control-layout").forms, list_head(child), 1))
end
local function statement_child_3f(parent, child, policy)
  local head = list_head(parent)
  local children = meaningful_children(parent)
  local index = meaningful_index(parent, child)
  return (custom_control_root_3f(parent, child, policy) or (body_child_3f(head, children, index, policy) and (#children == body_start(head, children, policy)) and not (last_body_child_3f(head, children, index, policy) and ((list_head(child) == "and") or (list_head(child) == "or")))))
end
local function executable_child_3f(child, mode)
  return (((child.kind == "list") or (child.kind == "sequence") or (child.kind == "table")) and (mode ~= "quoted"))
end
local function control_form_3f(node, statement_3f, policy)
  local heads = registry["rule-options"](policy, "control-layout").forms
  return (statement_3f and (node.kind == "list") and contains_3f(heads, list_head(node), 1))
end
local function append_control_finding(findings, path, forms, policy, node, ordinals)
  local existing = form_for_node(forms, node, nil)
  local base = (existing or nearest_form(forms, node) or {form = path})
  local head = list_head(node)
  local key = (base.form .. ":" .. head)
  local ordinal = ((ordinals[key] or 0) + 1)
  local form = (existing or {line = node.open.line, col = node.open.col, ["end-line"] = node.close.line, ["end-col"] = (node.close.col + 1), form = (base.form .. " > " .. head .. "#" .. ordinal), node = node})
  table.insert(findings, finding(path, form, rule_severity(policy, "control-layout"), "control-layout", "put this control form on several lines", node))
  return core.assoc(ordinals, key, ordinal)
end
local function offending_control_3f(node, statement_3f, mode, policy)
  return ((mode == 0) and control_form_3f(node, statement_3f, policy) and (node.open.line == node.close.line))
end
local function next_ordinals(findings, path, forms, policy, node, statement_3f, mode, ordinals)
  if offending_control_3f(node, statement_3f, mode, policy) then
    return append_control_finding(findings, path, forms, policy, node, ordinals)
  else
    return ordinals
  end
end
local function visit_child(state, index, child)
  local child_mode = quoted_mode_for_child(state.node, index, state.mode)
  if executable_child_3f(child, child_mode) then
    return state.visit(state.findings, state.path, state.forms, state.policy, child, statement_child_3f(state.node, child, state.policy), child_mode, state.ordinals)
  else
    return state.ordinals
  end
end
local function visit_node(findings, path, forms, policy, node, statement_3f, mode, ordinals)
  local next_ordinals0 = next_ordinals(findings, path, forms, policy, node, statement_3f, mode, ordinals)
  local state = {findings = findings, path = path, forms = forms, policy = policy, node = node, mode = mode, ordinals = next_ordinals0, visit = visit_node}
  local result = next_ordinals0
  for index, child in ipairs((node.children or {})) do
    result = visit_child(core.assoc(state, "ordinals", result), index, child)
  end
  return result
end
local function visit_root(findings, path, forms, policy, root)
  visit_node(findings, path, forms, policy, root, false, 0, {})
  return findings
end
local function append_control_findings(findings, path, forms, policy, source)
  local reader = require("fennel-extras.reader")
  local root = reader.parse(source)
  if root then
    return visit_root(findings, path, forms, policy, root)
  else
    return findings
  end
end
local findings
do
  local function findings0(findings1, path, forms, policy, source)
    if enabled_3f(policy, "control-layout") then
      return append_control_findings(findings1, path, forms, policy, source)
    else
      return findings1
    end
  end
  _2amodule_2a["findings"] = findings0
  findings = _2amodule_2a.findings
end
return nil
