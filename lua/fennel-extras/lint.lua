-- [nfnl] fnl/fennel-extras/lint.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint"]
end
local identity = require("fennel-extras.lint.identity")
local rules = require("fennel-extras.lint.rules")
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
local function selected_form_3f(forms, target, scope, index)
  if (index > #forms) then
    return false
  else
    local form = forms[index]
    if (form.form == target) then
      return selection["form-selected?"](form, scope)
    else
      return selected_form_3f(forms, target, scope, (index + 1))
    end
  end
end
local function selected_branch_3f(finding, forms, scope)
  local branch = branch_form(finding.form)
  return (branch and selected_form_3f(forms, branch, scope, 1))
end
local function selected_scope_3f(finding, forms, scope)
  if ((finding.rule == "module-style") or (finding.rule == "spec-macro-import")) then
    return (#scope > 0)
  else
    return (selection["form-selected?"](finding, scope) or selected_branch_3f(finding, forms, scope))
  end
end
local function selected_3f(finding, forms, scope)
  return ((scope == nil) or (scope == true) or selected_scope_3f(finding, forms, scope))
end
local function filter_findings(findings, forms, exclusions, scope, index, result)
  if (index > #findings) then
    return result
  else
    local finding = findings[index]
    if (selected_3f(finding, forms, scope) and not excluded_3f(exclusions, finding, 1)) then
      table.insert(result, finding)
    else
    end
    return filter_findings(findings, forms, exclusions, scope, (index + 1), result)
  end
end
local check
do
  local function check0(source, context)
    local path = (context.path or "")
    local policy = (context.rules or {})
    local exclusions = (context.exclusions or {})
    local scope = context.selection
    local forms, error = identity.forms(source, path)
    if error then
      return nil, error
    else
      return filter_findings(rules.check(path, forms, policy, source), forms, exclusions, scope, 1, {})
    end
  end
  _2amodule_2a["check"] = check0
  check = _2amodule_2a.check
end
return nil
