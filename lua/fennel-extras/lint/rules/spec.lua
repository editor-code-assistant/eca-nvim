-- [nfnl] fnl/fennel-extras/lint/rules/spec.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.spec"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.spec"]
end
local ast = require("fennel-extras.lint.rules.ast")
local registry = require("fennel-extras.lint.rules.registry")
local meaningful_children = ast["meaningful-children"]
local literal_text = ast["literal-text"]
local list_head = ast["list-head"]
local spec_file_3f = ast["spec-file?"]
local count_is = ast["count-is"]
local enabled_3f = registry["enabled?"]
local rule_severity = registry["rule-severity"]
local finding = registry.finding
local spec_import_finding
do
  local function spec_import_finding0(path, forms, policy, valid)
    if (spec_file_3f(path) and (path ~= "fnl/spec/eca/macros.fnlm") and enabled_3f(policy, "spec-macro-import") and not valid) then
      return {{kind = "finding", path = path, line = 1, col = 1, ["end-line"] = 1, ["end-col"] = 1, severity = rule_severity(policy, "spec-macro-import"), rule = "spec-macro-import", form = (path .. " > spec"), message = "specs must import deftest, testing, and is from spec.eca.macros", node = nil}}
    else
      return {}
    end
  end
  _2amodule_2a["spec-import-finding"] = spec_import_finding0
  spec_import_finding = _2amodule_2a["spec-import-finding"]
end
local direct_require_3f
do
  local function direct_require_3f0(path)
    return (path == "fnl/spec/eca/macros.fnlm")
  end
  _2amodule_2a["direct-require?"] = direct_require_3f0
  direct_require_3f = _2amodule_2a["direct-require?"]
end
local spec_direct_require_finding
do
  local function spec_direct_require_finding0(findings, path, form, policy, node)
    local children = meaningful_children(node)
    local target = literal_text(children[2])
    if (((target == "plenary.busted") or (target == "luassert")) and enabled_3f(policy, "spec-direct-require")) then
      return table.insert(findings, finding(path, form, rule_severity(policy, "spec-direct-require"), "spec-direct-require", "specs must use the shared macro import", node))
    else
      return nil
    end
  end
  _2amodule_2a["spec-direct-require-finding"] = spec_direct_require_finding0
  spec_direct_require_finding = _2amodule_2a["spec-direct-require-finding"]
end
local testing_finding
do
  local function testing_finding0(findings, path, form, policy, node)
    local count = count_is(node, 1, 0)
    if ((count ~= 1) and enabled_3f(policy, "one-is-per-testing")) then
      return table.insert(findings, finding(path, form, rule_severity(policy, "one-is-per-testing"), "one-is-per-testing", "each testing form must contain exactly one is", node))
    else
      return nil
    end
  end
  _2amodule_2a["testing-finding"] = testing_finding0
  testing_finding = _2amodule_2a["testing-finding"]
end
return nil
