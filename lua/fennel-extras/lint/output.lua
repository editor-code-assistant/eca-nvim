-- [nfnl] fnl/fennel-extras/lint/output.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.output"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.output"]
end
local slash = string.char(92)
local double_quote = string.char(34)
local newline = string.char(10)
local tab = string.char(9)
local carriage_return = string.char(13)
local replacement = (string.char(239) .. string.char(191) .. string.char(189))
local function severity_rank(severity)
  if (severity == "error") then
    return 1
  else
    return 2
  end
end
local function finding_less_3f(a, b)
  return ((a.path < b.path) or ((a.path == b.path) and ((a.line < b.line) or ((a.line == b.line) and ((a.col < b.col) or ((a.col == b.col) and ((severity_rank(a.severity) < severity_rank(b.severity)) or ((severity_rank(a.severity) == severity_rank(b.severity)) and ((a.rule < b.rule) or ((a.rule == b.rule) and ((a.form < b.form) or ((a.form == b.form) and (a.message < b.message)))))))))))))
end
local function insert_finding(copied, finding)
  table.insert(copied, finding)
  return copied
end
local function copy_findings(findings, index, copied)
  if (index > #findings) then
    return copied
  else
    return copy_findings(findings, (index + 1), insert_finding(copied, findings[index]))
  end
end
local sort
do
  local function sort0(findings)
    local copied = copy_findings(findings, 1, {})
    table.sort(copied, finding_less_3f)
    return copied
  end
  _2amodule_2a["sort"] = sort0
  sort = _2amodule_2a.sort
end
local function escape_control_carriage(character)
  if (character == carriage_return) then
    return (slash .. "r")
  else
    return string.format((slash .. "u00%02X"), string.byte(character))
  end
end
local function escape_control_whitespace(character)
  if (character == tab) then
    return (slash .. "t")
  else
    return escape_control_carriage(character)
  end
end
local function escape_control_newline(character)
  if (character == newline) then
    return (slash .. "n")
  else
    return escape_control_whitespace(character)
  end
end
local function escape_control_tail(character)
  if (character == slash) then
    return (slash .. slash)
  else
    return escape_control_newline(character)
  end
end
local function escape_control(character)
  if (character == double_quote) then
    return (slash .. double_quote)
  else
    return escape_control_tail(character)
  end
end
local function valid_continuation_3f(byte)
  return (byte and (byte >= 128) and (byte <= 191))
end
local function valid_two_byte_3f(first, second)
  return ((first >= 194) and (first <= 223) and valid_continuation_3f(second))
end
local function valid_three_byte_3f(first, second, third)
  return (valid_continuation_3f(second) and valid_continuation_3f(third) and (((first == 224) and (second >= 160) and (second <= 191)) or ((first >= 225) and (first <= 236)) or ((first == 237) and (second >= 128) and (second <= 159)) or ((first >= 238) and (first <= 239))))
end
local function valid_four_byte_3f(first, second, third, fourth)
  return (valid_continuation_3f(second) and valid_continuation_3f(third) and valid_continuation_3f(fourth) and (((first == 240) and (second >= 144) and (second <= 191)) or ((first >= 241) and (first <= 243)) or ((first == 244) and (second >= 128) and (second <= 143))))
end
local function append_replacement(chunks)
  table.insert(chunks, replacement)
  return chunks
end
local function append_byte(chunks, value, index)
  table.insert(chunks, string.sub(value, index, index))
  return chunks
end
local function append_sequence(chunks, value, index, span)
  table.insert(chunks, string.sub(value, index, (index + span + -1)))
  return chunks
end
local function normalize_utf8_step(value, index, chunks, first, second, third, fourth, recurse)
  return (((first < 128) and recurse(value, (index + 1), append_byte(chunks, value, index))) or (valid_two_byte_3f(first, second) and recurse(value, (index + 2), append_sequence(chunks, value, index, 2))) or (valid_three_byte_3f(first, second, third) and recurse(value, (index + 3), append_sequence(chunks, value, index, 3))) or (valid_four_byte_3f(first, second, third, fourth) and recurse(value, (index + 4), append_sequence(chunks, value, index, 4))) or recurse(value, (index + 1), append_replacement(chunks)))
end
local function normalize_utf8_bytes(value, index, chunks, recurse)
  local first = string.byte(value, index)
  local second = string.byte(value, (index + 1))
  local third = string.byte(value, (index + 2))
  local fourth = string.byte(value, (index + 3))
  return normalize_utf8_step(value, index, chunks, first, second, third, fourth, recurse)
end
local function normalize_utf8_at(value, index, chunks)
  if (index > #value) then
    return table.concat(chunks)
  else
    return normalize_utf8_bytes(value, index, chunks, normalize_utf8_at)
  end
end
local function normalize_utf8(value)
  return normalize_utf8_at(value, 1, {})
end
local function json_string(value)
  return (double_quote .. string.gsub(normalize_utf8(value), "[%z\1-\31\\\"]", escape_control) .. double_quote)
end
local function exclusion_line(finding)
  return ("  exclusion: {:rule " .. json_string(finding.rule) .. " :form " .. json_string(finding.form) .. " :reason \"explain why this is intentional\"}")
end
local function text_rule(finding)
  return string.match(finding.rule, "^[^\\\"]+")
end
local function text_line(finding)
  return (finding.path .. ":" .. finding.line .. ":" .. finding.col .. ": " .. finding.severity .. " " .. text_rule(finding) .. ": " .. finding.message)
end
local function append_text(lines, finding)
  table.insert(lines, text_line(finding))
  if (finding.kind == "finding") then
    table.insert(lines, exclusion_line(finding))
  else
  end
  return lines
end
local function append_text_lines(diagnostics, index, lines)
  if (index > #diagnostics) then
    return lines
  else
    return append_text_lines(diagnostics, (index + 1), append_text(lines, diagnostics[index]))
  end
end
local text_lines
do
  local function text_lines0(diagnostics)
    return append_text_lines(diagnostics, 1, {})
  end
  _2amodule_2a["text-lines"] = text_lines0
  text_lines = _2amodule_2a["text-lines"]
end
local function json_field(name, value)
  return (double_quote .. name .. double_quote .. ":" .. value)
end
local function json_string_field(name, value)
  return json_field(name, json_string(value))
end
local function finding_json(finding)
  local fields = {json_string_field("kind", finding.kind), json_string_field("path", finding.path), json_field("line", tostring(finding.line)), json_field("col", tostring(finding.col)), json_field("end-line", tostring(finding["end-line"])), json_field("end-col", tostring(finding["end-col"])), json_string_field("severity", finding.severity), json_string_field("rule", finding.rule), json_string_field("form", finding.form), json_string_field("message", finding.message)}
  return table.concat(fields, ",")
end
local function stale_json(finding)
  local fields = {json_string_field("kind", finding.kind), json_string_field("path", finding.path), json_field("line", tostring(finding.line)), json_field("col", tostring(finding.col)), json_string_field("severity", finding.severity), json_string_field("rule", finding.rule), json_string_field("form", finding.form), json_string_field("message", finding.message)}
  return table.concat(fields, ",")
end
local function diagnostic_json(finding)
  if (finding.kind == "finding") then
    return finding_json(finding)
  else
    return stale_json(finding)
  end
end
local function append_json(lines, finding)
  table.insert(lines, ("{" .. diagnostic_json(finding) .. "}"))
  return lines
end
local function append_json_lines(diagnostics, index, lines)
  if (index > #diagnostics) then
    return lines
  else
    return append_json_lines(diagnostics, (index + 1), append_json(lines, diagnostics[index]))
  end
end
local json_lines
do
  local function json_lines0(diagnostics)
    return append_json_lines(diagnostics, 1, {})
  end
  _2amodule_2a["json-lines"] = json_lines0
  json_lines = _2amodule_2a["json-lines"]
end
return nil
