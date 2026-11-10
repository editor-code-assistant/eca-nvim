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
local size_rule = require("fennel-extras.lint.rules.size")
local root_forms = ast["root-forms"]
local list_head = ast["list-head"]
local import_macros_3f = ast["import-macros?"]
local has_module_import_3f = ast["has-module-import?"]
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
local function update_check_state(state, import_info, head, policy)
  return {["module-import"] = state["module-import"]}
end
local function check_state_step(nodes, index, state, policy, recurse)
  local node = nodes[index]
  return recurse(nodes, (index + 1), update_check_state(state, import_macros_3f(node), list_head(node), policy), policy)
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
  return ((index <= #items) and ((items[index] == target) or contains_3f(items, target, (index + 1))))
end
local function evaluate_form(path, form, forms, policy)
  local node = form.node
  local head = list_head(node)
  local findings = {}
  if enabled_3f(policy, "form-child-count") then
    spec_rule["form-child-count-finding"](findings, path, form, policy, node)
  else
  end
  if enabled_3f(policy, "child-count") then
    spec_rule["child-count-finding"](findings, path, form, policy, node)
  else
  end
  if enabled_3f(policy, "forbidden-form") then
    forbidden_rule.findings(findings, path, form, policy, node, "forbidden-form")
  else
  end
  if (node and enabled_3f(policy, "module-import")) then
    module_rule["module-import-finding"](findings, path, form, head, node, policy)
  else
  end
  return findings
end
local function append_form_findings(all, path, forms, policy)
  for _, form in ipairs(forms) do
    append_all(all, evaluate_form(path, form, forms, policy))
  end
  return all
end
local function append_file_size_findings(findings, path, policy, source)
  if enabled_3f(policy, "file-size") then
    return size_rule.finding(path, policy, source)
  else
    return findings
  end
end
local function check_result(path, forms, policy, source, state)
  local findings = append_file_size_findings({}, path, policy, source)
  local findings0 = append_all(findings, module_rule["required-form-finding"](path, source, policy))
  local findings1 = append_form_findings(findings0, path, forms, policy)
  return findings1
end
local function check_instance(path, forms, policy, source, instance)
  local instance_policy = registry["evaluator-policy"](policy, instance.rule, instance.value)
  local state = check_state(root_forms(source), 1, {["module-import"] = false}, instance_policy)
  local result = check_result(path, forms, instance_policy, source, state)
  local tbl_26_ = {}
  local i_27_ = 0
  for _, finding0 in ipairs(result) do
    local val_28_
    if registry["instance-applies-to?"](instance.rule, instance.value, finding0, policy.matcher) then
      local with_instance = core.assoc(finding0, "instance", instance.index)
      if instance.value.description then
        val_28_ = core.assoc(with_instance, "description", instance.value.description)
      else
        val_28_ = with_instance
      end
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
