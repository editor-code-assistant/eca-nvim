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
local rule_options = require("fennel-extras.lint.rules.options")
local compatibility_policy = {["module-style"] = "error", ["spec-macro-import"] = "error", ["spec-no-module"] = "error", ["spec-direct-require"] = "error", ["one-is-per-testing"] = "error", ["if-branch-call"] = "warning", ["if-without-else"] = "warning", ["control-layout"] = "warning", ["unused-and-or"] = "warning", ["defn-args-newline"] = "warning", ["function-shape"] = "warning", ["no-mutation"] = "warning", ["multiline-layout"] = "warning", ["file-size"] = "warning", ["core-require"] = "error", ["binding-per-line"] = "warning", ["call-data-arg"] = "warning"}
local function effective_policy(policy)
  if (next(policy, nil) == nil) then
    return {}
  else
    return core.merge(compatibility_policy, policy)
  end
end
local function normalized_policy_entry(entry)
  if (type(entry) == "table") then
    return entry.severity
  else
    return entry
  end
end
local function normalized_context_policy(raw_policy)
  local result = {}
  for rule, entry in pairs(raw_policy) do
    result[rule] = normalized_policy_entry(entry)
  end
  return result
end
local function context_policy(context, raw_policy)
  if context.matcher then
    return normalized_context_policy(raw_policy)
  else
    return effective_policy(raw_policy)
  end
end
local function policy_for_context(context)
  local raw_policy = context.rules
  if raw_policy then
    return context_policy(context, raw_policy)
  else
    return {}
  end
end
local function append_context_option(result, rule, entry)
  if ((type(entry) == "table") and entry.options) then
    return core.assoc(result, rule, entry.options)
  else
    return result
  end
end
local function context_options(context)
  local result = {}
  for rule, entry in pairs((context.rules or {})) do
    result = append_context_option(result, rule, entry)
  end
  return result
end
local function normalized_testing_form(finding)
  return ((string.match(finding.form, " > top#[0-9]+$") and (finding.form .. " > testing#1")) or finding.form)
end
local function normalized_branch_form(finding)
  local form = string.gsub(finding.form, " > (top#[0-9]+) > (then.*)$", " > %1 > if#1 > %2")
  return form
end
local function normalized_form(finding)
  if (finding.rule == "one-is-per-testing") then
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
local function checked_findings_success(forms, path, policy, max_code_lines, exclusions, scope, source, matcher, defer)
  local findings = rules.check(path, forms, policy, source, max_code_lines)
  return filter_checked_findings(findings, forms, scope, exclusions, source, matcher, defer)
end
local function checked_findings(forms, error, path, policy, max_code_lines, exclusions, scope, source, matcher, defer)
  if error then
    return nil, error
  else
    return checked_findings_success(forms, path, policy, max_code_lines, exclusions, scope, source, matcher, defer)
  end
end
local function copy_context_exclusion(rule, value)
  local copy = {}
  for key, item in pairs(value) do
    copy[key] = item
  end
  return core.assoc(copy, "rule", rule)
end
local function append_context_values(result, rule, entries)
  for _, value in ipairs(entries) do
    table.insert(result, copy_context_exclusion(rule, value))
  end
  return result
end
local function append_context_entry(result, rule, entry)
  if ((type(entry) == "table") and entry.exclusions) then
    return append_context_values(result, rule, entry.exclusions)
  else
    return result
  end
end
local function append_context_exclusions(result, raw_policy)
  for rule, entry in pairs(raw_policy) do
    append_context_entry(result, rule, entry)
  end
  return result
end
local function context_exclusions(context)
  local result = core.concat({}, (context.exclusions or {}))
  return append_context_exclusions(result, (context.rules or {}))
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
local function regex_spec_files_error_entry(spec_files, matcher, index)
  if ((matcher == nil) and not ast["literal-prefix-pattern?"](spec_files[index])) then
    return {message = ("lint spec-files " .. index .. ": regex patterns require a matcher")}
  else
    return nil
  end
end
local function regex_spec_files_error(spec_files, matcher, index)
  if (index > #spec_files) then
    return nil
  else
    return (regex_spec_files_error_entry(spec_files, matcher, index) or regex_spec_files_error(spec_files, matcher, (index + 1)))
  end
end
local function policy_with_options(base_policy, context, matcher, spec_files)
  local options = rule_options.normalized((context.options or context_options(context)))
  return core.merge(base_policy, {options = options, ["spec-files"] = spec_files, matcher = matcher})
end
local check
do
  local function check0(source, context)
    local path = (context.path or "")
    local base_policy = policy_for_context(context)
    local matcher = context.matcher
    local spec_files = (context["spec-files"] or rule_options["spec-files"]())
    local policy = policy_with_options(base_policy, context, matcher, spec_files)
    local max_code_lines = (context["max-code-lines"] or 300)
    local exclusions = context_exclusions(context)
    local scope = context.selection
    local forms, parse_error = identity.forms(source, path)
    local matcher_error = (regex_exclusion_error(exclusions, matcher, 1) or regex_spec_files_error(spec_files, matcher, 1))
    if matcher_error then
      return _G.error(matcher_error)
    else
      return checked_findings(forms, parse_error, path, policy, max_code_lines, exclusions, scope, source, matcher, context["defer-exclusions"])
    end
  end
  _2amodule_2a["check"] = check0
  check = _2amodule_2a.check
end
return nil
