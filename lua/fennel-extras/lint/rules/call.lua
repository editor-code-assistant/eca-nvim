-- [nfnl] fnl/fennel-extras/lint/rules/call.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.call"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.call"]
end
local ast = require("fennel-extras.lint.rules.ast")
local mutation = require("fennel-extras.lint.rules.mutation")
local valid = require("fennel-extras.lint.rules.shape.leaf.valid")
local registry = require("fennel-extras.lint.rules.registry")
local meaningful_children = ast["meaningful-children"]
local list_head = ast["list-head"]
local quoted_child_3f = ast["quoted-child?"]
local spec_file_3f = ast["spec-file?"]
local form_for_node = ast["form-for-node"]
local nearest_form = ast["nearest-form"]
local finding = registry.finding
local enabled_3f = registry["enabled?"]
local rule_severity = registry["rule-severity"]
local control_heads = {["and"] = true, ["or"] = true, ["if"] = true, when = true, case = true, match = true, ["case-try"] = true, ["match-try"] = true}
local binding_heads = {let = true, ["when-let"] = true, ["if-let"] = true, ["with-open"] = true}
local definition_heads = {["local"] = true, global = true, var = true, set = true, tset = true, ["do"] = true, macro = true, ["import-macros"] = true}
local function_heads = {defn = true, ["defn-"] = true, fn = true, lambda = true, ["\206\187"] = true}
local function special_head_3f(head)
  return (control_heads[head] or binding_heads[head] or definition_heads[head] or function_heads[head] or valid["loop-head?"](head))
end
local function multiline_data_3f(node)
  return (((node.kind == "sequence") or (node.kind == "table")) and (node.close.line > node.open.line))
end
local function data_argument_3f(children, index, child)
  return ((index >= 2) and not quoted_child_3f(children, index) and multiline_data_3f(child))
end
local function data_argument_step(children, index, child)
  if data_argument_3f(children, index, child) then
    return true
  else
    return false
  end
end
local function has_data_argument_3f(children)
  local result = false
  for index, child in ipairs(children) do
    result = (result or data_argument_step(children, index, child))
  end
  return result
end
local function contains_3f(items, target, index)
  if (index > #items) then
    return false
  else
    return ((items[index] == target) or contains_3f(items, target, (index + 1)))
  end
end
local function plain_call_3f(node, policy)
  local head = list_head(node)
  local ignore = registry["rule-options"](policy, "call-data-arg")["ignore-forms"]
  return ((node.kind == "list") and head and not special_head_3f(head) and not contains_3f(ignore, head, 1))
end
local function offending_node_3f(node, policy)
  return (plain_call_3f(node, policy) and has_data_argument_3f(meaningful_children(node)))
end
local function call_nodes(source, policy)
  local function _3_(node)
    return offending_node_3f(node, policy)
  end
  return mutation["executable-nodes"](source, _3_)
end
local function update_ordinal(ordinals, key, ordinal)
  ordinals[key] = ordinal
  return ordinals
end
local function append_finding(findings, path, forms, policy, node, ordinals)
  local existing = form_for_node(forms, node, nil)
  local base = (existing or nearest_form(forms, node) or {form = path})
  local ordinal = ((ordinals[base.form] or 0) + 1)
  local form = (existing or {line = node.open.line, col = node.open.col, ["end-line"] = node.close.line, ["end-col"] = (node.close.col + 1), form = (base.form .. " > call-data-arg#" .. ordinal), node = node})
  table.insert(findings, finding(path, form, rule_severity(policy, "call-data-arg"), "call-data-arg", "move this multi-line map/vector into a let binding so the call fits on one line", node))
  return update_ordinal(ordinals, base.form, ordinal)
end
local function append_node_finding(findings, path, forms, policy, node, ordinals)
  if (not spec_file_3f(path, policy["spec-files"], policy.matcher) and enabled_3f(policy, "call-data-arg")) then
    return append_finding(findings, path, forms, policy, node, ordinals)
  else
    return ordinals
  end
end
local findings
do
  local function findings0(findings1, path, forms, policy, source)
    do
      local ordinals = {}
      for _, node in ipairs(call_nodes(source, policy)) do
        ordinals = append_node_finding(findings1, path, forms, policy, node, ordinals)
      end
    end
    return findings1
  end
  _2amodule_2a["findings"] = findings0
  findings = _2amodule_2a.findings
end
return nil
