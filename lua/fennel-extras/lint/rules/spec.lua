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
local rule_options = registry["rule-options"]
local enabled_3f = registry["enabled?"]
local rule_severity = registry["rule-severity"]
local finding = registry.finding
local count_is = ast["count-is"]
local function contains_3f(items, target, index)
  if (index > #items) then
    return false
  else
    return ((items[index] == target) or contains_3f(items, target, (index + 1)))
  end
end
local function exempt_file_3f(path, policy, rule)
  local patterns = rule_options(policy, rule)["exempt-files"]
  return (patterns and (#patterns > 0) and ((policy.matcher and policy.matcher(patterns[1], path)) or (string.sub(path, 1, (string.len(patterns[1]) - 1)) == string.sub(patterns[1], 2))))
end
local spec_import_finding
do
  local function spec_import_finding0(path, forms, policy, valid)
    if (not exempt_file_3f(path, policy, "macro-import") and enabled_3f(policy, "macro-import") and not valid) then
      return {{kind = "finding", path = path, line = 1, col = 1, ["end-line"] = 1, ["end-col"] = 1, severity = rule_severity(policy, "macro-import"), rule = "macro-import", form = (path .. " > spec"), message = "specs must import deftest, testing, and is from spec.eca.macros", node = nil}}
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
local direct_require_finding
do
  local function direct_require_finding0(findings, path, form, policy, node)
    local children = meaningful_children(node)
    local target = literal_text(children[2])
    local options = rule_options(policy, "direct-require")
    local modules = (options.modules or {})
    if ((options.mode == "forbid") and not exempt_file_3f(path, policy, "direct-require") and enabled_3f(policy, "direct-require") and contains_3f(modules, target, 1)) then
      return table.insert(findings, finding(path, form, rule_severity(policy, "direct-require"), "direct-require", "specs must use the shared macro import", node))
    else
      return nil
    end
  end
  _2amodule_2a["direct-require-finding"] = direct_require_finding0
  direct_require_finding = _2amodule_2a["direct-require-finding"]
end
local function count_child_forms(node, children, index, result)
  if (index > #children) then
    return result
  else
    return count_child_forms(node, children, (index + 1), (result + count_is(node, 1, 0, list_head(node), children[index])))
  end
end
local form_child_count_finding
do
  local function form_child_count_finding0(findings, path, form, policy, node)
    local options = rule_options(policy, "form-child-count")
    local count = count_child_forms(node, options.children, 1, 0)
    if (enabled_3f(policy, "form-child-count") and (count ~= options["max-count"])) then
      return table.insert(findings, finding(path, form, rule_severity(policy, "form-child-count"), "form-child-count", "each testing form must contain exactly one is", node))
    else
      return nil
    end
  end
  _2amodule_2a["form-child-count-finding"] = form_child_count_finding0
  form_child_count_finding = _2amodule_2a["form-child-count-finding"]
end
return nil
