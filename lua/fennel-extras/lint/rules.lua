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
local forbidden_rule = require("fennel-extras.lint.rules.forbidden")
local branch_rule = require("fennel-extras.lint.rules.branch")
local size_rule = require("fennel-extras.lint.rules.size")
local mutation_rule = require("fennel-extras.lint.rules.mutation")
local layout_rule = require("fennel-extras.lint.rules.layout")
local control_rule = require("fennel-extras.lint.rules.control")
local discard_rule = require("fennel-extras.lint.rules.discard")
local when_rule = require("fennel-extras.lint.rules.when")
local binding_rule = require("fennel-extras.lint.rules.binding")
local call_rule = require("fennel-extras.lint.rules.call")
local shape_rule = require("fennel-extras.lint.rules.shape")
local shape_leaf = require("fennel-extras.lint.rules.shape.leaf")
local root_forms = ast["root-forms"]
local list_head = ast["list-head"]
local macro_import_3f = ast["macro-import?"]
local has_all_3f = ast["has-all?"]
local has_module_import_3f = ast["has-module-import?"]
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
local function module_import_state_enabled(state, import_info, policy)
  local target_module = registry["rule-options"](policy, "module-style").module
  if (import_info and (import_info.target == target_module)) then
    return has_module_import_3f(import_info.names)
  else
    return state["module-import"]
  end
end
local function module_import_state(state, import_info, policy)
  if enabled_3f(policy, "module-style") then
    return module_import_state_enabled(state, import_info, policy)
  else
    return state["module-import"]
  end
end
local function spec_import_state_enabled(state, import_info, policy)
  local options = registry["rule-options"](policy, "macro-import")
  if (import_info and (import_info.target == options.module)) then
    return has_all_3f(import_info.names, options.forms)
  else
    return state["spec-import"]
  end
end
local function spec_import_state(state, import_info, policy)
  if enabled_3f(policy, "macro-import") then
    return spec_import_state_enabled(state, import_info, policy)
  else
    return state["spec-import"]
  end
end
local function update_check_state(state, import_info, head, policy)
  return {["module-import"] = module_import_state(state, import_info, policy), ["module-form"] = (state["module-form"] or (head == "module")), ["spec-import"] = spec_import_state(state, import_info, policy)}
end
local function check_state_step(nodes, index, state, policy, recurse)
  local node = nodes[index]
  return recurse(nodes, (index + 1), update_check_state(state, macro_import_3f(node), list_head(node), policy), policy)
end
local function check_state(nodes, index, state, policy)
  if (index > #nodes) then
    return state
  else
    return check_state_step(nodes, index, state, policy, check_state)
  end
end
local function append_all(target, items)
  for _, value in ipairs((items or {})) do
    table.insert(target, value)
  end
  return target
end
local function contains_3f(items, target, index)
  if (index > #items) then
    return false
  else
    return ((items[index] == target) or contains_3f(items, target, (index + 1)))
  end
end
local function evaluate_form(path, form, forms, policy)
  local node = form.node
  local head = list_head(node)
  local findings = {}
  if (enabled_3f(policy, "no-module") and (head == registry["rule-options"](policy, "no-module").module)) then
    table.insert(findings, finding(path, form, rule_severity(policy, "no-module"), "no-module", "specs must not declare a module", node))
  else
  end
  if (enabled_3f(policy, "direct-require") and require_node_3f(node)) then
    spec_rule["direct-require-finding"](findings, path, form, policy, node)
  else
  end
  if enabled_3f(policy, "form-child-count") then
    spec_rule["form-child-count-finding"](findings, path, form, policy, node)
  else
  end
  if enabled_3f(policy, "forbidden-form") then
    forbidden_rule.findings(findings, path, form, policy, node)
  else
  end
  if (enabled_3f(policy, "function-shape") and node and contains_3f(registry["rule-options"](policy, "function-shape").forms, head, 1)) then
    shape_rule["add-function-findings"](findings, path, form, forms, policy, node)
  else
  end
  if enabled_3f(policy, "if-branch-call") then
    append_all(findings, branch_rule.finding(path, form, policy, node))
  else
  end
  if (((head == "local") or (head == "require")) and node and enabled_3f(policy, "direct-require")) then
    module_rule["direct-require-finding"](findings, path, form, head, node, policy)
  else
  end
  return findings
end
local function append_form_findings(all, path, forms, policy, spec_import)
  if enabled_3f(policy, "macro-import") then
    append_all(all, spec_rule["spec-import-finding"](path, forms, policy, spec_import))
  else
  end
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
local function append_file_size_findings(findings, path, policy, source)
  if enabled_3f(policy, "file-size") then
    return size_rule.finding(path, policy, source)
  else
    return findings
  end
end
local function append_module_findings(findings, path, forms, policy, state)
  if enabled_3f(policy, "module-style") then
    return append_all(findings, module_rule["module-finding"](path, forms, policy, (state["module-import"] and state["module-form"])))
  else
    return findings
  end
end
local function append_shape_findings(findings, path, forms, policy, source)
  if enabled_3f(policy, "function-shape") then
    return append_synthetic_findings(findings, path, forms, policy, source)
  else
    return findings
  end
end
local function append_when_findings(findings, path, forms, policy, source)
  if enabled_3f(policy, "if-without-else") then
    return when_rule.findings(findings, path, forms, policy, source)
  else
    return findings
  end
end
local function append_layout_findings(findings, path, forms, policy, source)
  if (enabled_3f(policy, "multiline-layout") or enabled_3f(policy, "if-branch-call")) then
    return layout_rule.findings(findings, path, forms, policy, source)
  else
    return findings
  end
end
local function append_control_findings(findings, path, forms, policy, source)
  if enabled_3f(policy, "control-layout") then
    return control_rule.findings(findings, path, forms, policy, source)
  else
    return findings
  end
end
local function append_discard_findings(findings, path, forms, policy, source)
  if enabled_3f(policy, "unused-and-or") then
    return discard_rule.findings(findings, path, forms, policy, source)
  else
    return findings
  end
end
local function append_mutation_findings(findings, path, forms, policy, source)
  if enabled_3f(policy, "no-mutation") then
    return mutation_rule.findings(findings, path, forms, policy, source)
  else
    return findings
  end
end
local function append_binding_findings(findings, path, forms, policy, source)
  if enabled_3f(policy, "binding-per-line") then
    return binding_rule.findings(findings, path, forms, policy, source)
  else
    return findings
  end
end
local function append_call_findings(findings, path, forms, policy, source)
  if enabled_3f(policy, "call-data-arg") then
    return call_rule.findings(findings, path, forms, policy, source)
  else
    return findings
  end
end
local function check_result(path, forms, policy, source, state)
  local findings = append_file_size_findings({}, path, policy, source)
  local findings0 = append_module_findings(findings, path, forms, policy, state)
  local findings1 = append_form_findings(findings0, path, forms, policy, state["spec-import"])
  local findings2 = append_shape_findings(findings1, path, forms, policy, source)
  local findings3 = append_when_findings(findings2, path, forms, policy, source)
  local findings4 = append_layout_findings(findings3, path, forms, policy, source)
  local findings5 = append_control_findings(findings4, path, forms, policy, source)
  local findings6 = append_discard_findings(findings5, path, forms, policy, source)
  local findings7 = append_mutation_findings(findings6, path, forms, policy, source)
  local findings8 = append_binding_findings(findings7, path, forms, policy, source)
  local findings9 = append_call_findings(findings8, path, forms, policy, source)
  return remove_contained_function_findings(findings9)
end
local function check_instance(path, forms, policy, source, instance)
  local instance_policy = registry["evaluator-policy"](policy, instance.rule, instance.value)
  local state = check_state(root_forms(source), 1, {["module-form"] = false, ["module-import"] = false, ["spec-import"] = false}, instance_policy)
  local result = check_result(path, forms, instance_policy, source, state)
  local tbl_26_ = {}
  local i_27_ = 0
  for _, finding0 in ipairs(result) do
    local val_28_
    if registry["instance-applies-to?"](instance.value, finding0, policy.matcher) then
      val_28_ = core.assoc(finding0, "instance", instance.index)
    else
      val_28_ = nil
    end
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function append_instance_findings(result, path, forms, policy, source, instance)
  for _, finding0 in ipairs(check_instance(path, forms, policy, source, instance)) do
    table.insert(result, finding0)
  end
  return result
end
local check
do
  local function check0(path, forms, policy, source)
    local result = {}
    for _, instance in ipairs(registry.instances(policy)) do
      result = append_instance_findings(result, path, forms, policy, source, instance)
    end
    return result
  end
  _2amodule_2a["check"] = check0
  check = _2amodule_2a.check
end
return nil
