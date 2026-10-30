-- [nfnl] fnl/fennel-extras/lint/exclusion.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.exclusion"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.exclusion"]
end
local core = require("eca.nfnl.core")
local function source_lines(source)
  local tbl_26_ = {}
  local i_27_ = 0
  for value in string.gmatch(source, "([^\n]*)\n?") do
    local val_28_ = value
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function line_text(source, line)
  return (source_lines(source)[line] or "")
end
local function span_start(index, state)
  if (index == state.first) then
    return state.start
  else
    return 1
  end
end
local function span_end(index, state)
  if (index == state.last) then
    return (state["end"] - 1)
  else
    return -1
  end
end
local function span_line(text, index, state)
  local start = span_start(index, state)
  local _end = span_end(index, state)
  return string.sub(text, start, _end)
end
local function append_span_line(result, text)
  table.insert(result, text)
  return result
end
local function append_span_line_at(lines, state, recurse)
  local text = lines[state.index]
  local result = append_span_line(state.result, span_line(text, state.index, state))
  return recurse(lines, core.assoc(state, "index", (state.index + 1), "result", result), recurse)
end
local function multiline_source_step(lines, state, recurse)
  if (state.index > state.last) then
    return table.concat(state.result, "\n")
  else
    return append_span_line_at(lines, state, recurse)
  end
end
local function multiline_source(source, finding)
  local lines = source_lines(source)
  local state = {first = finding.line, last = finding["end-line"], start = finding.col, ["end"] = finding["end-col"], index = finding.line, result = {}}
  return multiline_source_step(lines, state, multiline_source_step)
end
local function finding_source(source, finding)
  local first_line = line_text(source, finding.line)
  if (finding.line == finding["end-line"]) then
    return string.sub(first_line, finding.col, (finding["end-col"] - 1))
  else
    return multiline_source(source, finding)
  end
end
local function rule_list_selected_3f(names, rule, index)
  if (index > #names) then
    return false
  else
    return ((names[index] == rule) or rule_list_selected_3f(names, rule, (index + 1)))
  end
end
local function rule_selected_3f(exclusion, rule)
  return ((exclusion.rule == nil) or (exclusion.rule == rule) or (exclusion.rules and rule_list_selected_3f(exclusion.rules, rule, 1)))
end
local function line_selected_3f(exclusion, finding)
  return ((exclusion.line and (finding.line <= exclusion.line) and (exclusion.line <= finding["end-line"])) or (exclusion.lines and (finding.line <= exclusion.lines.to) and (exclusion.lines.from <= finding["end-line"])))
end
local function path_selected_3f(exclusion, finding, matcher)
  local and_7_ = (not exclusion.pattern or matcher(exclusion.pattern, finding.path))
  if and_7_ then
    local or_8_ = not exclusion.path
    if not or_8_ then
      if matcher then
        or_8_ = matcher(exclusion.path, finding.path)
      else
        or_8_ = (exclusion.path == finding.path)
      end
    end
    and_7_ = or_8_
  end
  return and_7_
end
local function code_selected_3f(exclusion, finding, source, matcher)
  return (not exclusion.code or (finding.node and matcher(exclusion.code, finding_source((source or finding.source), finding))))
end
local function selector_selected_3f(exclusion, finding, source, matcher)
  return (path_selected_3f(exclusion, finding, matcher) and (not (exclusion.line or exclusion.lines) or line_selected_3f(exclusion, finding)) and code_selected_3f(exclusion, finding, source, matcher) and (not exclusion.form or (exclusion.form == finding.form)))
end
local matches_3f
do
  local function matches_3f0(exclusion, finding, source, matcher)
    return (rule_selected_3f(exclusion, finding.rule) and ((exclusion.instance == nil) or (finding.instance == exclusion.instance)) and selector_selected_3f(exclusion, finding, source, matcher))
  end
  _2amodule_2a["matches?"] = matches_3f0
  matches_3f = _2amodule_2a["matches?"]
end
local function mark_match(finding, exclusion, source, matcher, index, matched)
  if matches_3f(exclusion, finding, source, matcher) then
    matched[index] = true
  else
  end
  return matched
end
local function mark_matches_step(finding, exclusions, source, matcher, index, matched, excluded, recurse)
  local exclusion = exclusions[index]
  local matched0 = mark_match(finding, exclusion, source, matcher, index, matched)
  local excluded0 = (excluded or matches_3f(exclusion, finding, source, matcher))
  return recurse(finding, exclusions, source, matcher, (index + 1), matched0, excluded0, recurse)
end
local function mark_matches(finding, exclusions, source, matcher, index, matched, excluded, recurse)
  if (index > #exclusions) then
    return excluded, matched
  else
    return mark_matches_step(finding, exclusions, source, matcher, index, matched, excluded, recurse)
  end
end
local function append_finding(result, finding)
  table.insert(result, finding)
  return result
end
local function apply_finding(finding, exclusions, source, matcher, result, matched)
  local excluded, next_matched = mark_matches(finding, exclusions, source, matcher, 1, matched, false, mark_matches)
  if excluded then
    return result, next_matched
  else
    return append_finding(result, finding), next_matched
  end
end
local function apply_findings_step(findings, exclusions, source, matcher, index, result, matched, recurse)
  local finding = findings[index]
  local next_result, next_matched = apply_finding(finding, exclusions, source, matcher, result, matched)
  return recurse(findings, exclusions, source, matcher, (index + 1), next_result, next_matched, recurse)
end
local function apply_findings(findings, exclusions, source, matcher, index, result, matched, recurse)
  if (index > #findings) then
    return result, matched
  else
    return apply_findings_step(findings, exclusions, source, matcher, index, result, matched, recurse)
  end
end
local apply
do
  local function apply0(findings, exclusions, source, matcher)
    local matched = {}
    for index, _ in ipairs(exclusions) do
      matched[index] = false
    end
    return apply_findings(findings, exclusions, source, matcher, 1, {}, matched, apply_findings)
  end
  _2amodule_2a["apply"] = apply0
  apply = _2amodule_2a.apply
end
return nil
