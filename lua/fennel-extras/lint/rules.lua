-- [nfnl] fnl/fennel-extras/lint/rules.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules"]
end
local core = require("eca.nfnl.core")
local ast = require("fennel-extras.lint.rules.ast")
local registry = require("fennel-extras.lint.rules.registry")
local module_rule = require("fennel-extras.lint.rules.module")
local spec_rule = require("fennel-extras.lint.rules.spec")
local branch_rule = require("fennel-extras.lint.rules.branch")
local size_rule = require("fennel-extras.lint.rules.size")
local mutation_rule = require("fennel-extras.lint.rules.mutation")
local shape_rule = require("fennel-extras.lint.rules.shape")
local shape_leaf = require("fennel-extras.lint.rules.shape.leaf")
local defaults_map = registry["defaults-map"]
local root_forms = ast["root-forms"]
local list_head = ast["list-head"]
local macro_import_3f = ast["macro-import?"]
local has_all_3f = ast["has-all?"]
local has_module_import_3f = ast["has-module-import?"]
local spec_file_3f = ast["spec-file?"]
local require_node_3f = ast["require-node?"]
local enabled_3f = registry["enabled?"]
local finding = registry.finding
local rule_severity = registry["rule-severity"]
local defaults
do
  local function defaults0()
    return registry.defaults()
  end
  _2amodule_2a["defaults"] = defaults0
  defaults = _2amodule_2a.defaults
end
local function module_import_state(state, import_info)
  if (import_info and (import_info.target == "eca.nfnl.macros.aniseed")) then
    return has_module_import_3f(import_info.names)
  else
    return state["module-import"]
  end
end
local function spec_import_state(state, import_info)
  if (import_info and (import_info.target == "spec.eca.macros")) then
    return has_all_3f(import_info.names)
  else
    return state["spec-import"]
  end
end
local function update_check_state(state, import_info, head)
  return {["module-import"] = module_import_state(state, import_info), ["module-form"] = (state["module-form"] or (head == "module")), ["spec-import"] = spec_import_state(state, import_info)}
end
local function check_state_step(nodes, index, state, recurse)
  local node = nodes[index]
  return recurse(nodes, (index + 1), update_check_state(state, macro_import_3f(node), list_head(node)))
end
local function check_state(nodes, index, state)
  if (index > #nodes) then
    return state
  else
    return check_state_step(nodes, index, state, check_state)
  end
end
local function append_all(target, items)
  for _, value in ipairs((items or {})) do
    table.insert(target, value)
  end
  return target
end
local function evaluate_form(path, form, forms, policy)
  local node = form.node
  local head = list_head(node)
  local findings = {}
  if (spec_file_3f(path) and (head == "module") and enabled_3f(policy, "spec-no-module")) then
    table.insert(findings, finding(path, form, rule_severity(policy, "spec-no-module"), "spec-no-module", "specs must not declare a module", node))
  else
  end
  if (spec_file_3f(path) and not spec_rule["direct-require?"](path) and require_node_3f(node)) then
    spec_rule["spec-direct-require-finding"](findings, path, form, policy, node)
  else
  end
  if (head == "testing") then
    spec_rule["testing-finding"](findings, path, form, policy, node)
  else
  end
  if (node and shape_leaf["function-head?"](head)) then
    shape_rule["add-function-findings"](findings, path, form, forms, policy, node)
  else
  end
  append_all(findings, branch_rule.finding(path, form, policy, node))
  if (((head == "local") or (head == "require")) and node and enabled_3f(policy, "core-require")) then
    module_rule["core-require-finding"](findings, path, form, head, node, policy)
  else
  end
  return findings
end
local function append_form_findings(all, path, forms, policy, spec_import)
  append_all(all, spec_rule["spec-import-finding"](path, forms, policy, spec_import))
  for _, form in ipairs(forms) do
    append_all(all, evaluate_form(path, form, forms, policy))
  end
  return all
end
local function append_synthetic_findings(all, path, forms, policy, source)
  return shape_rule["synthetic-findings"](all, path, forms, policy, source)
end
local function remove_contained_function_findings(findings)
  return shape_rule["remove-contained-function-findings"](findings)
end
local function check_result(path, forms, policy, source, max_code_lines, state)
  local file_policy = core.assoc(policy, "max-code-lines", max_code_lines)
  local findings = size_rule.finding(path, file_policy, source)
  local findings0 = append_all(findings, module_rule["module-finding"](path, forms, policy, (state["module-import"] and state["module-form"])))
  local findings1 = append_form_findings(findings0, path, forms, policy, state["spec-import"])
  local findings2 = append_synthetic_findings(findings1, path, forms, policy, source)
  local findings3 = mutation_rule.findings(findings2, path, forms, policy, source)
  return remove_contained_function_findings(findings3)
end
local check
do
  local function check0(path, forms, policy, source, max_code_lines)
    local state = check_state(root_forms(source), 1, {["module-form"] = false, ["module-import"] = false, ["spec-import"] = false})
    return check_result(path, forms, policy, source, (max_code_lines or 300), state)
  end
  _2amodule_2a["check"] = check0
  check = _2amodule_2a.check
end
return nil
