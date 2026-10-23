-- [nfnl] fnl/fennel-extras/lint/rules/when.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.when"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.when"]
end
local ast = require("fennel-extras.lint.rules.ast")
local mutation = require("fennel-extras.lint.rules.mutation")
local registry = require("fennel-extras.lint.rules.registry")
local list_head = ast["list-head"]
local meaningful_children = ast["meaningful-children"]
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
local function if_without_else_3f(node, policy)
  local children = meaningful_children(node)
  local else_child = children[4]
  local options = registry["rule-options"](policy, "if-without-else")
  local forms = options["if-forms"]
  local flag_nil_else = options["flag-nil-else"]
  return ((node.kind == "list") and contains_3f(forms, list_head(node), 1) and ((#children == 3) or (flag_nil_else and (#children == 4) and (else_child.kind == "symbol") and (else_child.text == "nil"))))
end
local function finding_form(path, forms, node)
  return (form_for_node(forms, node, nil) or nearest_form(forms, node) or {line = node.open.line, col = node.open.col, ["end-line"] = node.close.line, ["end-col"] = (node.close.col + 1), form = path, node = node})
end
local function append_finding(findings, path, forms, policy, node)
  table.insert(findings, finding(path, finding_form(path, forms, node), rule_severity(policy, "if-without-else"), "if-without-else", "if without else; use when", node))
  return findings
end
local function append_node_findings(findings, path, forms, policy, nodes)
  for _, node in ipairs(nodes) do
    append_finding(findings, path, forms, policy, node)
  end
  return findings
end
local function if_nodes(source, policy)
  local function _2_(node)
    return if_without_else_3f(node, policy)
  end
  return mutation["executable-nodes"](source, _2_)
end
local findings
do
  local function findings0(findings1, path, forms, policy, source)
    if enabled_3f(policy, "if-without-else") then
      append_node_findings(findings1, path, forms, policy, if_nodes(source, policy))
    else
    end
    return findings1
  end
  _2amodule_2a["findings"] = findings0
  findings = _2amodule_2a.findings
end
return nil
