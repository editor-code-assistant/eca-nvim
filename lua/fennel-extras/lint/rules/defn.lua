-- [nfnl] fnl/fennel-extras/lint/rules/defn.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.defn"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.defn"]
end
local ast = require("fennel-extras.lint.rules.ast")
local mutation = require("fennel-extras.lint.rules.mutation")
local registry = require("fennel-extras.lint.rules.registry")
local meaningful_children = ast["meaningful-children"]
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
local function defn_node_3f(node, policy)
  local heads = registry["rule-options"](policy, "defn-args-newline").forms
  return ((node.kind == "list") and contains_3f(heads, list_head(node), 1))
end
local function docstring_3f(children)
  local third = children[3]
  return (third and (third.kind == "string"))
end
local function parameter_index(children)
  if docstring_3f(children) then
    return 4
  else
    return 3
  end
end
local function parameter_vector(node)
  local children = meaningful_children(node)
  local index = parameter_index(children)
  return children[index]
end
local function invalid_layout_3f(node)
  local children = meaningful_children(node)
  local name = children[2]
  local args = parameter_vector(node)
  return (name and args and (args.open.line <= name.line))
end
local function finding_form(path, forms, node)
  local existing = form_for_node(forms, node, nil)
  local base = (existing or nearest_form(forms, node) or {form = path})
  return (existing or {line = node.open.line, col = node.open.col, ["end-line"] = node.close.line, ["end-col"] = (node.close.col + 1), form = (base.form .. " > defn-args-newline"), node = node})
end
local function add_finding(findings, path, policy, node, form)
  return table.insert(findings, finding(path, form, rule_severity(policy, "defn-args-newline"), "defn-args-newline", "put the defn argument vector on the line below the name", node))
end
local function append_finding(findings, path, forms, policy, node)
  if invalid_layout_3f(node) then
    add_finding(findings, path, policy, node, finding_form(path, forms, node))
  else
  end
  return findings
end
local function append_node_finding(findings, path, forms, policy, node)
  return append_finding(findings, path, forms, policy, node)
end
local function defn_nodes(source, policy)
  local function _4_(node)
    return defn_node_3f(node, policy)
  end
  return mutation["executable-nodes"](source, _4_)
end
local function append_node_findings(findings, path, forms, policy, source)
  for _, node in ipairs(defn_nodes(source, policy)) do
    append_node_finding(findings, path, forms, policy, node)
  end
  return findings
end
local findings
do
  local function findings0(findings1, path, forms, policy, source)
    if enabled_3f(policy, "defn-args-newline") then
      append_node_findings(findings1, path, forms, policy, source)
    else
    end
    return findings1
  end
  _2amodule_2a["findings"] = findings0
  findings = _2amodule_2a.findings
end
return nil
