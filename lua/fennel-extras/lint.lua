-- [nfnl] fnl/fennel-extras/lint.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint"]
end
local identity = require("fennel-extras.lint.identity")
local rules = require("fennel-extras.lint.rules")
local registry = require("fennel-extras.lint.rules.registry")
local selection = require("fennel-extras.lint.selection")
local function exclusion_match_3f(exclusion, finding)
  return ((exclusion.rule == finding.rule) and (exclusion.form == finding.form))
end
local function excluded_3f(exclusions, finding, index)
  if (index > #exclusions) then
    return false
  else
    return ((exclusion_match_3f(exclusions[index], finding) and true) or excluded_3f(exclusions, finding, (index + 1)))
  end
end
local function branch_base(form, suffix)
  return string.gsub(form, suffix, "")
end
local function branch_form(form)
  local then_base = branch_base(form, " > then$")
  local else_base = branch_base(form, " > else$")
  return (((then_base ~= form) and then_base) or ((else_base ~= form) and else_base))
end
local function selected_form_step(forms, target, scope, index, recurse)
  local form = forms[index]
  if (form.form == target) then
    return selection["form-selected?"](form, scope)
  else
    return recurse(forms, target, scope, (index + 1))
  end
end
local function selected_form_3f(forms, target, scope, index)
  if (index > #forms) then
    return false
  else
    return selected_form_step(forms, target, scope, index, selected_form_3f)
  end
end
local function selected_branch_3f(finding, forms, scope)
  local branch = branch_form(finding.form)
  return (branch and selected_form_3f(forms, branch, scope, 1))
end
local function selected_scope_3f(finding, forms, scope)
  if (registry["rule-scope"](finding.rule) == "file") then
    return (#scope > 0)
  else
    return (selection["form-selected?"](finding, scope) or selected_branch_3f(finding, forms, scope))
  end
end
local function selected_3f(finding, forms, scope)
  return ((scope == nil) or (scope == true) or selected_scope_3f(finding, forms, scope))
end
local function append_selected_finding(result, finding, forms, exclusions, scope)
  if (selected_3f(finding, forms, scope) and not excluded_3f(exclusions, finding, 1)) then
    table.insert(result, finding)
  else
  end
  return result
end
local function filter_findings_step(findings, forms, exclusions, scope, index, result, recurse)
  local finding = findings[index]
  local next_result = append_selected_finding(result, finding, forms, exclusions, scope)
  return recurse(findings, forms, exclusions, scope, (index + 1), next_result)
end
local function filter_findings(findings, forms, exclusions, scope, index, result)
  if (index > #findings) then
    return result
  else
    return filter_findings_step(findings, forms, exclusions, scope, index, result, filter_findings)
  end
end
local function checked_findings(forms, error, path, policy, max_code_lines, exclusions, scope, source)
  if error then
    return nil, error
  else
    return filter_findings(rules.check(path, forms, policy, source, max_code_lines), forms, exclusions, scope, 1, {})
  end
end
local check
do
  local function check0(source, context)
    local path = (context.path or "")
    local policy = (context.rules or {})
    local max_code_lines = (context["max-code-lines"] or 300)
    local exclusions = (context.exclusions or {})
    local scope = context.selection
    local forms, error = identity.forms(source, path)
    return checked_findings(forms, error, path, policy, max_code_lines, exclusions, scope, source)
  end
  _2amodule_2a["check"] = check0
  check = _2amodule_2a.check
end
return nil
