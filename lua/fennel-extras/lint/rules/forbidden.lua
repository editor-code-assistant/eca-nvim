-- [nfnl] fnl/fennel-extras/lint/rules/forbidden.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.forbidden"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.forbidden"]
end
local core = require("eca.nfnl.core")
local ast = require("fennel-extras.lint.rules.ast")
local registry = require("fennel-extras.lint.rules.registry")
local meaningful_children = ast["meaningful-children"]
local literal_text = ast["literal-text"]
local list_head = ast["list-head"]
local finding = registry.finding
local enabled_3f = registry["enabled?"]
local rule_severity = registry["rule-severity"]
local function module_target(node)
  local head = list_head(node)
  local children = meaningful_children(node)
  if ((head == "require") or (head == "import") or (head == "module")) then
    return literal_text(children[2])
  else
    return nil
  end
end
local function finding_node(node)
  local target = module_target(node)
  if target then
    return core.assoc(node, "text", target)
  else
    return node
  end
end
local findings
do
  local function findings0(result, path, form, policy, node)
    if (enabled_3f(policy, "forbidden-form") and node and (node.kind == "list") and list_head(node)) then
      table.insert(result, finding(path, form, rule_severity(policy, "forbidden-form"), "forbidden-form", "forbidden form", finding_node(node)))
    else
    end
    return result
  end
  _2amodule_2a["findings"] = findings0
  findings = _2amodule_2a.findings
end
return nil
