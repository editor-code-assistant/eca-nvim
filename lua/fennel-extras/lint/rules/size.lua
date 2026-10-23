-- [nfnl] fnl/fennel-extras/lint/rules/size.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.size"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.size"]
end
local reader = require("fennel-extras.reader")
local ast = require("fennel-extras.lint.rules.ast")
local registry = require("fennel-extras.lint.rules.registry")
local code_line_count = ast["code-line-count"]
local newline_count = ast["newline-count"]
local spec_file_3f = ast["spec-file?"]
local enabled_3f = registry["enabled?"]
local rule_severity = registry["rule-severity"]
local function file_size_finding_result(path, policy, count, limit)
  if (count > limit) then
    return {{kind = "finding", path = path, line = 1, col = 1, ["end-line"] = 1, ["end-col"] = 1, severity = rule_severity(policy, "file-size"), rule = "file-size", form = (path .. " > file"), message = ("file has " .. count .. " code lines (max " .. limit .. "); split it by responsibility into smaller modules"), node = nil}}
  else
    return {}
  end
end
local function file_size_finding_source(path, policy, source)
  local tokens = reader.tokenize(source)
  local count = code_line_count(tokens, 1, (newline_count(source, 1, 0) + 1), 0)
  local options = (policy.options and policy.options["file-size"])
  local limit = ((options and options["max-code-lines"]) or 300)
  return file_size_finding_result(path, policy, count, limit)
end
local finding
do
  local function finding0(path, policy, source)
    if (not spec_file_3f(path, policy["spec-files"], policy.matcher) and enabled_3f(policy, "file-size")) then
      return file_size_finding_source(path, policy, source)
    else
      return {}
    end
  end
  _2amodule_2a["finding"] = finding0
  finding = _2amodule_2a.finding
end
return nil
