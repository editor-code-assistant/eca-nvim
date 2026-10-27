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
local count_is = ast["count-is"]
local rule_options = registry["rule-options"]
local enabled_3f = registry["enabled?"]
local rule_severity = registry["rule-severity"]
local finding = registry.finding
local function contains_3f(items, target, index)
  if (index > #items) then
    return false
  else
    return ((items[index] == target) or contains_3f(items, target, (index + 1)))
  end
end
local function exempt_file_3f(path, policy, rule)
  local patterns = rule_options(policy, rule)["exempt-files"]
  return (((path == "fnl/spec/eca/macros.fnlm") and ((rule == "spec-macro-import") or (rule == "spec-direct-require"))) or (patterns and (#patterns > 0) and ((policy.matcher and policy.matcher(patterns[1], path)) or (string.sub(path, 1, (string.len(patterns[1]) - 1)) == string.sub(patterns[1], 2)))))
end
local spec_import_finding
do
  local function spec_import_finding0(path, forms, policy, valid)
    if (not exempt_file_3f(path, policy, "spec-macro-import") and enabled_3f(policy, "spec-macro-import") and not valid) then
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
    local modules = rule_options(policy, "spec-direct-require").modules
    if (not exempt_file_3f(path, policy, "spec-direct-require") and enabled_3f(policy, "spec-direct-require") and contains_3f(modules, target, 1)) then
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
    local options = rule_options(policy, "one-is-per-testing")
    local count = count_is(node, 1, 0, options.testing, options.assertion)
    local expected_count = options.count
    if ((count ~= expected_count) and enabled_3f(policy, "one-is-per-testing")) then
      return table.insert(findings, finding(path, form, rule_severity(policy, "one-is-per-testing"), "one-is-per-testing", "each testing form must contain exactly one is", node))
    else
      return nil
    end
  end
  _2amodule_2a["testing-finding"] = testing_finding0
  testing_finding = _2amodule_2a["testing-finding"]
end
return nil
