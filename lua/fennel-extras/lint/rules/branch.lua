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
local function contains_3f(items, target, index)
  if (index > #items) then
    return false
  else
    return ((items[index] == target) or contains_3f(items, target, (index + 1)))
  end
end
local function default_conditional_form_3f(form)
  return (string.match(form.form, " > then$") or string.match(form.form, " > else$") or string.match(form.form, " > then#[0-9]+$"))
end
local function named_conditional_form_3f(form, name)
  return (string.match(form.form, (" > " .. name .. "[^ >]* > then$")) or string.match(form.form, (" > " .. name .. "[^ >]* > else$")) or string.match(form.form, (" > " .. name .. "[^ >]* > then#[0-9]+$")))
end
local function conditional_form_3f(form, policy, index)
  local forms = registry["rule-options"](policy, "if-branch-call").forms
  local name = forms[index]
  return (((name == "if") and default_conditional_form_3f(form)) or ((name ~= "if") and named_conditional_form_3f(form, name)) or ((index < #forms) and conditional_form_3f(form, policy, (index + 1))))
end
local function custom_branch_3f(node, forms)
  local children = meaningful_children(node)
  local head = list_head(node)
  return ((node.kind == "list") and contains_3f(forms, head, 1) and (head ~= "if") and (do_branch_3f(children[3]) or do_branch_3f(children[4])))
end
local finding
do
  local function finding0(path, form, policy, node)
    local forms = registry["rule-options"](policy, "if-branch-call").forms
    local custom = (forms and (forms[1] ~= "if"))
    if ((((list_head(node) == "do") and do_branch_3f(node) and (custom or conditional_form_3f(form, policy, 1))) or custom_branch_3f(node, forms)) and enabled_3f(policy, "if-branch-call")) then
      return {make_finding(path, form, rule_severity(policy, "if-branch-call"), "if-branch-call", "if branch contains multiple expressions; move them to a named helper", node)}
    else
      return {}
    end
  end
  _2amodule_2a["finding"] = finding0
  finding = _2amodule_2a.finding
end
return nil
