-- [nfnl] fnl/fennel-extras/lint/rules/branch.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.branch"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.branch"]
end
local ast = require("fennel-extras.lint.rules.ast")
local registry = require("fennel-extras.lint.rules.registry")
local list_head = ast["list-head"]
local meaningful_children = ast["meaningful-children"]
local symbol_text = ast["symbol-text"]
local do_branch_3f = ast["do-branch?"]
local make_finding = registry.finding
local enabled_3f = registry["enabled?"]
local rule_severity = registry["rule-severity"]
local finding
do
  local function finding0(path, form, policy, node)
    if ((list_head(node) == "do") and do_branch_3f(node) and (string.match(form.form, " > then$") or string.match(form.form, " > else$") or string.match(form.form, " > then#[0-9]+$")) and enabled_3f(policy, "if-branch-call")) then
      return {make_finding(path, form, rule_severity(policy, "if-branch-call"), "if-branch-call", "if branch contains multiple expressions; move them to a named helper", node)}
    else
      return {}
    end
  end
  _2amodule_2a["finding"] = finding0
  finding = _2amodule_2a.finding
end
return nil
