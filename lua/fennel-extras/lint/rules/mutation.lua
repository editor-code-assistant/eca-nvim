-- [nfnl] fnl/fennel-extras/lint/rules/mutation.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.mutation"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.mutation"]
end
local core = require("eca.nfnl.core")
local ast = require("fennel-extras.lint.rules.ast")
local reader = require("fennel-extras.reader")
local registry = require("fennel-extras.lint.rules.registry")
local root_forms = ast["root-forms"]
local previous_meaningful_index = ast["previous-meaningful-index"]
local list_head = ast["list-head"]
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
local function mutation_head_3f(head, policy)
  return contains_3f(registry["rule-options"](policy, "no-mutation").forms, head, 1)
end
local function mutation_mode_for_prefix(prefix, mode)
  return (((prefix == "'") and "quoted") or ((mode == "quoted") and "quoted") or ((prefix == "`") and (mode + 1)) or ((prefix == ",") and math.max(0, (mode - 1))) or mode)
end
local function mutation_mode_for_child(node, index, mode)
  local previous_index = previous_meaningful_index(node.children, index)
  local previous = (previous_index and node.children[previous_index])
  if (previous and (previous.kind == "prefix")) then
    return mutation_mode_for_prefix(previous.text, mutation_mode_for_child(node, previous_index, mode))
  else
    return mode
  end
end
local function append_executable_child(node, result, index, child, mode, recurse, predicate)
  local child_mode = mutation_mode_for_child(node, index, mode)
  if (((child.kind == "list") or (child.kind == "sequence") or (child.kind == "table")) and (child_mode ~= "quoted")) then
    return recurse(child, result, child_mode, predicate)
  else
    return result
  end
end
local function collect_executable_children(node, result, mode, recurse, predicate)
  local state = result
  for index, child in ipairs((node.children or {})) do
    state = append_executable_child(node, state, index, child, mode, recurse, predicate)
  end
  return state
end
local function executable_node_result(node, result, mode, predicate)
  if ((mode == 0) and predicate(node)) then
    return core.concat(result, {node})
  else
    return result
  end
end
local function collect_executable_nodes(node, result, mode, predicate)
  return collect_executable_children(node, executable_node_result(node, result, mode, predicate), mode, collect_executable_nodes, predicate)
end
local executable_nodes
do
  local function executable_nodes0(source, predicate)
    local root = reader.parse(source)
    if root then
      return collect_executable_nodes(root, {}, 0, predicate)
    else
      return {}
    end
  end
  _2amodule_2a["executable-nodes"] = executable_nodes0
  executable_nodes = _2amodule_2a["executable-nodes"]
end
local function mutation_nodes(source, policy)
  local function _6_(node)
    return ((node.kind == "list") and mutation_head_3f(list_head(node), policy))
  end
  return executable_nodes(source, _6_)
end
local function mutation_form(path, node, base, ordinal)
  return {line = node.open.line, col = node.open.col, ["end-line"] = node.close.line, ["end-col"] = (node.close.col + 1), form = (base.form .. " > no-mutation#" .. ordinal), node = node}
end
local function append_mutation_finding(findings, path, forms, policy, node, ordinals)
  local existing = form_for_node(forms, node, nil)
  local base = (existing or nearest_form(forms, node) or {form = path})
  local ordinal = ((ordinals[base.form] or 0) + 1)
  local form = (existing or mutation_form(path, node, base, ordinal))
  table.insert(findings, finding(path, form, rule_severity(policy, "no-mutation"), "no-mutation", "avoid mutation (var/set/while); prefer a functional form", node))
  return core.assoc(ordinals, base.form, ordinal)
end
local function add_mutation_finding(findings, path, forms, policy, node, ordinals)
  if enabled_3f(policy, "no-mutation") then
    return append_mutation_finding(findings, path, forms, policy, node, ordinals)
  else
    return ordinals
  end
end
local findings
do
  local function findings0(findings1, path, forms, policy, source)
    do
      local ordinals = {}
      for _, node in ipairs(mutation_nodes(source, policy)) do
        ordinals = add_mutation_finding(findings1, path, forms, policy, node, ordinals)
      end
    end
    return findings1
  end
  _2amodule_2a["findings"] = findings0
  findings = _2amodule_2a.findings
end
return nil
