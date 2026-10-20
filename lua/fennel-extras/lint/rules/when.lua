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
local function if_without_else_3f(node)
  local children = meaningful_children(node)
  local else_child = children[4]
  return ((node.kind == "list") and (list_head(node) == "if") and ((#children == 3) or ((#children == 4) and (else_child.kind == "symbol") and (else_child.text == "nil"))))
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
local findings
do
  local function findings0(findings1, path, forms, policy, source)
    if enabled_3f(policy, "if-without-else") then
      append_node_findings(findings1, path, forms, policy, mutation["executable-nodes"](source, if_without_else_3f))
    else
    end
    return findings1
  end
  _2amodule_2a["findings"] = findings0
  findings = _2amodule_2a.findings
end
return nil
