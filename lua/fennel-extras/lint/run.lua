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
    if exclusion_match_3f(exclusions[index], finding) then
      return true
    else
      return excluded_3f(exclusions, finding, (index + 1))
    end
  end
end
local function keep_finding(findings, exclusions, index, result)
  if (index > #findings) then
    return result
  else
    local finding = findings[index]
    if not excluded_3f(exclusions, finding, 1) then
      table.insert(result, finding)
    else
    end
    return keep_finding(findings, exclusions, (index + 1), result)
  end
end
local function matching_exclusion_3f(exclusion, findings, index)
  if (index > #findings) then
    return false
  else
    if exclusion_match_3f(exclusion, findings[index]) then
      return true
    else
      return matching_exclusion_3f(exclusion, findings, (index + 1))
    end
  end
end
local function stale_exclusion(exclusion, config_path)
  return {kind = "stale-exclusion", path = config_path, line = 1, col = 1, severity = "error", rule = exclusion.rule, form = exclusion.form, message = ("stale exclusion: " .. exclusion.form)}
end
local function append_stale(exclusions, findings, config_path, index, result)
  if (index > #exclusions) then
    return result
  else
    local exclusion = exclusions[index]
    if not matching_exclusion_3f(exclusion, findings, 1) then
      table.insert(result, stale_exclusion(exclusion, config_path))
    else
    end
    return append_stale(exclusions, findings, config_path, (index + 1), result)
  end
end
local function normalized_form(finding)
  if (finding.rule == "one-is-per-testing") then
    if string.match(finding.form, " > top#[0-9]+$") then
      return (finding.form .. " > testing#1")
    else
      return finding.form
    end
  else
    local form = string.gsub(finding.form, " > (top#[0-9]+) > (then.*)$", " > %1 > if#1 > %2")
    return form
  end
end
local function normalize_findings(findings, index, result)
  if (index > #findings) then
    return result
  else
    local finding = findings[index]
    table.insert(result, {kind = finding.kind, path = finding.path, line = finding.line, col = finding.col, ["end-line"] = finding["end-line"], ["end-col"] = finding["end-col"], severity = finding.severity, rule = finding.rule, form = normalized_form(finding), message = finding.message})
    return normalize_findings(findings, (index + 1), result)
  end
end
local function lint_file(file, policy)
  local findings, error = lint.check(file.source, {path = file.path, rules = policy.rules, selection = file.selection})
  if error then
    return nil, {message = error.message, line = error.line, col = error.col, path = file.path}
  else
    return normalize_findings(findings, 1, {}), nil
  end
end
local function lint_files_at(files, policy, index, result)
  if (index > #files) then
    return result, nil
  else
    local findings, error = lint_file(files[index], policy)
    if error then
      return nil, error
    else
      local function _13_()
        for _, finding in ipairs(findings) do
          table.insert(result, finding)
        end
        return result
      end
      return lint_files_at(files, policy, (index + 1), _13_())
    end
  end
end
local function exclusion_path(exclusion)
  return (string.match(exclusion.form, "^(.-) > ") or exclusion.form)
end
local function path_in_scope_3f(paths, path, index)
  if (index > #paths) then
    return false
  else
    if (path == paths[index]) then
      return true
    else
      return path_in_scope_3f(paths, path, (index + 1))
    end
  end
end
local function scoped_exclusions(exclusions, paths, index, result)
  if (index > #exclusions) then
    return result
  else
    local exclusion = exclusions[index]
    if ((paths == nil) or path_in_scope_3f(paths, exclusion_path(exclusion), 1)) then
      table.insert(result, exclusion)
    else
    end
    return scoped_exclusions(exclusions, paths, (index + 1), result)
  end
end
local function keep_non_warning(findings, index, result)
  if (index > #findings) then
    return result
  else
    local finding = findings[index]
    if not (finding.severity == "warning") then
      table.insert(result, finding)
    else
    end
    return keep_non_warning(findings, (index + 1), result)
  end
end
local function diagnostics(findings, policy, config_path, scope_paths)
  local exclusions = scoped_exclusions(policy.exclusions, scope_paths, 1, {})
  local filtered = keep_finding(findings, exclusions, 1, {})
  local stale = append_stale(exclusions, findings, config_path, 1, {})
  local source
  if ((#policy.exclusions > 0) and (scope_paths or (#stale > 0))) then
    source = keep_non_warning(filtered, 1, {})
  else
    source = filtered
  end
  local function _23_()
    for _, finding in ipairs(stale) do
      table.insert(source, finding)
    end
    return source
  end
  return output.sort(_23_())
end
local function has_errors_3f(findings, index)
  if (index > #findings) then
    return false
  else
    if (findings[index].severity == "error") then
      return true
    else
      return has_errors_3f(findings, (index + 1))
    end
  end
end
local function render(findings, format)
  if (format == "json") then
    return output["json-lines"](findings)
  else
    return output["text-lines"](findings)
  end
end
local function result(findings, format)
  local _27_
  if has_errors_3f(findings, 1) then
    _27_ = 1
  else
    _27_ = 0
  end
  return {lines = render(findings, format), status = _27_}
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
