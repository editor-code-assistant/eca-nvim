-- [nfnl] fnl/fennel-extras/lint/run.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.run"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.run"]
end
local lint = require("fennel-extras.lint")
local output = require("fennel-extras.lint.output")
local function exclusion_match_3f(exclusion, finding)
  return ((exclusion.rule == finding.rule) and (exclusion.form == finding.form))
end
local function excluded_3f(exclusions, finding, index)
  if (index > #exclusions) then
    return false
  else
    return (exclusion_match_3f(exclusions[index], finding) or excluded_3f(exclusions, finding, (index + 1)))
  end
end
local function append_kept_finding(result, finding, exclusions)
  if not excluded_3f(exclusions, finding, 1) then
    table.insert(result, finding)
  else
  end
  return result
end
local function keep_finding_step(findings, exclusions, index, result, recurse)
  local finding = findings[index]
  return recurse(findings, exclusions, (index + 1), append_kept_finding(result, finding, exclusions))
end
local function keep_finding(findings, exclusions, index, result)
  if (index > #findings) then
    return result
  else
    return keep_finding_step(findings, exclusions, index, result, keep_finding)
  end
end
local function matching_exclusion_3f(exclusion, findings, index)
  if (index > #findings) then
    return false
  else
    return (exclusion_match_3f(exclusion, findings[index]) or matching_exclusion_3f(exclusion, findings, (index + 1)))
  end
end
local function stale_exclusion(exclusion, config_path)
  return {kind = "stale-exclusion", path = config_path, line = 1, col = 1, severity = "error", rule = exclusion.rule, form = exclusion.form, message = ("stale exclusion: " .. exclusion.form)}
end
local function append_stale_item(result, exclusion, findings, config_path)
  if not matching_exclusion_3f(exclusion, findings, 1) then
    table.insert(result, stale_exclusion(exclusion, config_path))
  else
  end
  return result
end
local function append_stale_step(exclusions, findings, config_path, index, result, recurse)
  local exclusion = exclusions[index]
  return recurse(exclusions, findings, config_path, (index + 1), append_stale_item(result, exclusion, findings, config_path))
end
local function append_stale(exclusions, findings, config_path, index, result)
  if (index > #exclusions) then
    return result
  else
    return append_stale_step(exclusions, findings, config_path, index, result, append_stale)
  end
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
local function normalized_finding(finding)
  return {kind = finding.kind, path = finding.path, line = finding.line, col = finding.col, ["end-line"] = finding["end-line"], ["end-col"] = finding["end-col"], severity = finding.severity, rule = finding.rule, form = normalized_form(finding), message = finding.message}
end
local function normalize_findings_step(findings, index, result, recurse)
  local finding = findings[index]
  table.insert(result, normalized_finding(finding))
  return recurse(findings, (index + 1), result)
end
local function normalize_findings(findings, index, result)
  if (index > #findings) then
    return result
  else
    return normalize_findings_step(findings, index, result, normalize_findings)
  end
end
local function lint_file(file, policy)
  local findings, error = lint.check(file.source, {path = file.path, rules = policy.rules, ["max-code-lines"] = policy["max-code-lines"], selection = file.selection})
  if error then
    return nil, {message = error.message, line = error.line, col = error.col, path = file.path}
  else
    return normalize_findings(findings, 1, {}), nil
  end
end
local function append_findings(result, findings)
  for _, finding in ipairs(findings) do
    table.insert(result, finding)
  end
  return result
end
local function lint_files_at_step(files, policy, index, result, recurse)
  local findings, error = lint_file(files[index], policy)
  if error then
    return nil, error
  else
    return recurse(files, policy, (index + 1), append_findings(result, findings))
  end
end
local function lint_files_at(files, policy, index, result)
  if (index > #files) then
    return result, nil
  else
    return lint_files_at_step(files, policy, index, result, lint_files_at)
  end
end
local function exclusion_path(exclusion)
  return (string.match(exclusion.form, "^(.-) > ") or exclusion.form)
end
local function path_in_scope_3f(paths, path, index)
  if (index > #paths) then
    return false
  else
    return ((path == paths[index]) or path_in_scope_3f(paths, path, (index + 1)))
  end
end
local function append_scoped_exclusion(result, exclusion, paths)
  if ((paths == nil) or path_in_scope_3f(paths, exclusion_path(exclusion), 1)) then
    table.insert(result, exclusion)
  else
  end
  return result
end
local function scoped_exclusions_step(exclusions, paths, index, result, recurse)
  local exclusion = exclusions[index]
  return recurse(exclusions, paths, (index + 1), append_scoped_exclusion(result, exclusion, paths))
end
local function scoped_exclusions(exclusions, paths, index, result)
  if (index > #exclusions) then
    return result
  else
    return scoped_exclusions_step(exclusions, paths, index, result, scoped_exclusions)
  end
end
local function append_non_warning(result, finding)
  if not (finding.severity == "warning") then
    table.insert(result, finding)
  else
  end
  return result
end
local function keep_non_warning_step(findings, index, result, recurse)
  local finding = findings[index]
  return recurse(findings, (index + 1), append_non_warning(result, finding))
end
local function keep_non_warning(findings, index, result)
  if (index > #findings) then
    return result
  else
    return keep_non_warning_step(findings, index, result, keep_non_warning)
  end
end
local function diagnostic_source(filtered, policy, stale, scope_paths)
  if ((#policy.exclusions > 0) and (scope_paths or (#stale > 0))) then
    return keep_non_warning(filtered, 1, {})
  else
    return filtered
  end
end
local function append_stale_findings(source, stale)
  for _, finding in ipairs(stale) do
    table.insert(source, finding)
  end
  return source
end
local function diagnostics(findings, policy, config_path, scope_paths)
  local exclusions = scoped_exclusions(policy.exclusions, scope_paths, 1, {})
  local filtered = keep_finding(findings, exclusions, 1, {})
  local stale = append_stale(exclusions, findings, config_path, 1, {})
  local source = diagnostic_source(filtered, policy, stale, scope_paths)
  return output.sort(append_stale_findings(source, stale))
end
local function has_errors_3f(findings, index)
  if (index > #findings) then
    return false
  else
    return ((findings[index].severity == "error") or has_errors_3f(findings, (index + 1)))
  end
end
local function render(findings, format)
  if (format == "json") then
    return output["json-lines"](findings)
  else
    return output["text-lines"](findings)
  end
end
local function result_status(findings)
  if has_errors_3f(findings, 1) then
    return 1
  else
    return 0
  end
end
local function result(findings, format)
  return {lines = render(findings, format), status = result_status(findings)}
end
local lint_files
do
  local function lint_files0(files, policy, config_path, format, scope_paths)
    local findings, error = lint_files_at(files, policy, 1, {})
    if error then
      return nil, error
    else
      return result(diagnostics(findings, policy, config_path, scope_paths), format)
    end
  end
  _2amodule_2a["lint-files"] = lint_files0
  lint_files = _2amodule_2a["lint-files"]
end
return nil
