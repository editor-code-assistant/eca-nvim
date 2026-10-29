-- [nfnl] fnl/fennel-extras/lint.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint"]
end
local core = require("eca.nfnl.core")
local identity = require("fennel-extras.lint.identity")
local ast = require("fennel-extras.lint.rules.ast")
local rules = require("fennel-extras.lint.rules")
local registry = require("fennel-extras.lint.rules.registry")
local selection = require("fennel-extras.lint.selection")
local exclusion_matcher = require("fennel-extras.lint.exclusion")
local config_lint = require("fennel-extras.config.lint")
local function policy_for_context(context)
  return (context.rules or {})
end
local function normalized_testing_form(finding)
  return ((string.match(finding.form, " > top#[0-9]+$") and (finding.form .. " > testing#1")) or finding.form)
end
local function normalized_branch_form(finding)
  local form = string.gsub(finding.form, " > (top#[0-9]+) > (then.*)$", " > %1 > if#1 > %2")
  return form
end
local function normalized_form(finding)
  if (finding.rule == "form-child-count") then
    return normalized_testing_form(finding)
  else
    return normalized_branch_form(finding)
  end
end
local function normalize_finding(finding)
  local form = normalized_form(finding)
  if (finding.form == form) then
    return finding
  else
    return core.assoc(finding, "form", form)
  end
end
local function excluded_3f(exclusions, finding, source, matcher, index)
  if (index > #exclusions) then
    return false
  else
    return (exclusion_matcher["matches?"](exclusions[index], finding, source, matcher) or excluded_3f(exclusions, finding, source, matcher, (index + 1)))
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
local function append_selected_finding(result, finding, forms, scope, exclusions, source, matcher)
  do
    local normalized = normalize_finding(finding)
    if (selected_3f(finding, forms, scope) and not excluded_3f(exclusions, normalized, source, matcher, 1)) then
      table.insert(result, normalized)
    else
    end
  end
  return result
end
local function filter_findings_step(findings, forms, scope, exclusions, source, matcher, index, result, recurse)
  local finding = findings[index]
  local next_result = append_selected_finding(result, finding, forms, scope, exclusions, source, matcher)
  return recurse(findings, forms, scope, exclusions, source, matcher, (index + 1), next_result)
end
local function filter_findings(findings, forms, scope, exclusions, source, matcher, index, result)
  if (index > #findings) then
    return result
  else
    return filter_findings_step(findings, forms, scope, exclusions, source, matcher, index, result, filter_findings)
  end
end
local function filter_checked_findings(findings, forms, scope, exclusions, source, matcher, defer)
  if defer then
    return filter_findings(findings, forms, scope, {}, source, matcher, 1, {})
  else
    return filter_findings(findings, forms, scope, exclusions, source, matcher, 1, {})
  end
end
local function checked_findings_success(forms, path, policy, exclusions, scope, source, matcher, defer)
  local findings = rules.check(path, forms, policy, source)
  return filter_checked_findings(findings, forms, scope, exclusions, source, matcher, defer)
end
local function checked_findings(forms, error, path, policy, exclusions, scope, source, matcher, defer)
  if error then
    return nil, error
  else
    return checked_findings_success(forms, path, policy, exclusions, scope, source, matcher, defer)
  end
end
local function copy_context_exclusion(rule, index, value)
  local copy = {}
  for key, item in pairs(value) do
    copy[key] = item
  end
  return core.assoc(copy, "rule", rule, "instance", index)
end
local function append_context_values(result, rule, index, entries)
  for _, value in ipairs(entries) do
    table.insert(result, copy_context_exclusion(rule, index, value))
  end
  return result
end
local function append_context_entry(result, rule, index, entry)
  if ((type(entry) == "table") and entry.exclusions) then
    return append_context_values(result, rule, index, entry.exclusions)
  else
    return result
  end
end
local function append_context_entries(result, rule, entries)
  for index, entry in ipairs(entries) do
    append_context_entry(result, rule, index, entry)
  end
  return result
end
local function append_context_rule(result, rule, entries)
  if (type(entries) == "table") then
    return append_context_entries(result, rule, entries)
  else
    return result
  end
end
local function context_lint_value(context)
  local lint_rules = {}
  local design_rules = (context.design or {})
  for rule, entries in pairs((context.rules or {})) do
    if (registry["rule-domain"](rule) == "design") then
      design_rules[rule] = entries
    else
      lint_rules[rule] = entries
    end
  end
  return {rules = lint_rules, design = design_rules}
end
local function append_context_exclusions(result, raw_policy)
  for _, item in ipairs(registry.instances(raw_policy)) do
    for _0, exclusion in ipairs((item.value.exclusions or {})) do
      table.insert(result, copy_context_exclusion(item.rule, item.index, exclusion))
    end
  end
  return result
end
local function context_exclusions(context)
  return append_context_exclusions({}, context_lint_value(context))
end
local function regex_exclusion_error_entry(entry, matcher, index)
  if ((entry.pattern or entry.code) and (matcher == nil)) then
    return {message = ("lint exclusion " .. index .. ": regex selectors require a matcher")}
  else
    return nil
  end
end
local function regex_exclusion_error(exclusions, matcher, index)
  local entry = exclusions[index]
  if (entry == nil) then
    return nil
  else
    return (regex_exclusion_error_entry(entry, matcher, index) or regex_exclusion_error(exclusions, matcher, (index + 1)))
  end
end
local function context_policy(context)
  return core.merge(context_lint_value(context), {matcher = context.matcher})
end
local function context_matcher_error(context, exclusions)
  return regex_exclusion_error(exclusions, context.matcher, 1)
end
local function context_validation_error(context)
  local value = context_lint_value(context)
  return (config_lint["lint-error"]({rules = value.rules}) or config_lint["design-error"]({rules = value.design}))
end
local function context_forms(source, path)
  return identity.forms(source, path)
end
local function checked_context(forms, parse_error, path, policy, exclusions, scope, source, context, validation_error, matcher_error)
  local failure = (validation_error or matcher_error)
  if failure then
    return _G.error(failure)
  else
    return checked_findings(forms, parse_error, path, policy, exclusions, scope, source, context.matcher, context["defer-exclusions"])
  end
end
local check
do
  local function check0(source, context)
    local path = (context.path or "")
    local policy = context_policy(context)
    local exclusions = context_exclusions(context)
    local scope = context.selection
    local validation_error = context_validation_error(context)
    local forms, parse_error = context_forms(source, path)
    local matcher_error = context_matcher_error(context, exclusions)
    return checked_context(forms, parse_error, path, policy, exclusions, scope, source, context, validation_error, matcher_error)
  end
  _2amodule_2a["check"] = check0
  check = _2amodule_2a.check
end
return nil
