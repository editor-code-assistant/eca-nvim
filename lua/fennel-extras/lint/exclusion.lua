-- [nfnl] fnl/fennel-extras/lint/exclusion.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.exclusion"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.exclusion"]
end
local matches_3f
do
  local function matches_3f0(exclusion, finding, _source, matcher)
    return (matcher and matcher(exclusion.path, finding.path))
  end
  _2amodule_2a["matches?"] = matches_3f0
  matches_3f = _2amodule_2a["matches?"]
end
local function mark_match(finding, exclusion, matcher, index, matched)
  if matches_3f(exclusion, finding, nil, matcher) then
    matched[index] = true
  else
  end
  return matched
end
local function mark_matches_step(finding, exclusions, matcher, index, matched, excluded, recurse)
  local exclusion = exclusions[index]
  local matched0 = mark_match(finding, exclusion, matcher, index, matched)
  local excluded0 = (excluded or matches_3f(exclusion, finding, nil, matcher))
  return recurse(finding, exclusions, matcher, (index + 1), matched0, excluded0, recurse)
end
local function mark_matches(finding, exclusions, matcher, index, matched, excluded, recurse)
  if (index > #exclusions) then
    return excluded, matched
  else
    return mark_matches_step(finding, exclusions, matcher, index, matched, excluded, recurse)
  end
end
local function append_finding(result, finding)
  table.insert(result, finding)
  return result
end
local function apply_finding(finding, exclusions, matcher, result, matched)
  local excluded, next_matched = mark_matches(finding, exclusions, matcher, 1, matched, false, mark_matches)
  if excluded then
    return result, next_matched
  else
    return append_finding(result, finding), next_matched
  end
end
local function apply_findings_step(findings, exclusions, matcher, index, result, matched, recurse)
  local finding = findings[index]
  local next_result, next_matched = apply_finding(finding, exclusions, matcher, result, matched)
  return recurse(findings, exclusions, matcher, (index + 1), next_result, next_matched, recurse)
end
local function apply_findings(findings, exclusions, matcher, index, result, matched, recurse)
  if (index > #findings) then
    return result, matched
  else
    return apply_findings_step(findings, exclusions, matcher, index, result, matched, recurse)
  end
end
local apply
do
  local function apply0(findings, exclusions, _source, matcher)
    local matched = {}
    for index, _ in ipairs(exclusions) do
      matched[index] = false
    end
    return apply_findings(findings, exclusions, matcher, 1, {}, matched, apply_findings)
  end
  _2amodule_2a["apply"] = apply0
  apply = _2amodule_2a.apply
end
return nil
