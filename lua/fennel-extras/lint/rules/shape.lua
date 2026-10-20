-- [nfnl] fnl/fennel-extras/lint/rules/shape.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.shape"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.shape"]
end
local core = require("eca.nfnl.core")
local ast = require("fennel-extras.lint.rules.ast")
local registry = require("fennel-extras.lint.rules.registry")
local leaf = require("fennel-extras.lint.rules.shape.leaf")
local branch = require("fennel-extras.lint.rules.shape.branch")
local meaningful_children = ast["meaningful-children"]
local list_head = ast["list-head"]
local quoted_child_3f = ast["quoted-child?"]
local root_forms = ast["root-forms"]
local form_for_node = ast["form-for-node"]
local function_info = leaf["function-info"]
local validate_function_body = branch["validate-function-body"]
local function_head_3f = leaf["function-head?"]
local finding = registry.finding
local rule_severity = registry["rule-severity"]
local enabled_3f = registry["enabled?"]
local function_violations
do
  local function function_violations0(node)
    local info = function_info(node)
    local body = ((info and info.body) or {})
    return validate_function_body(body, {})
  end
  _2amodule_2a["function-violations"] = function_violations0
  function_violations = _2amodule_2a["function-violations"]
end
local function function_target(base, offending)
  if ((list_head(offending) == "if") and (string.match(base.form, " > then$") or string.match(base.form, " > else$"))) then
    return core.assoc(base, "form", (base.form .. " > if#1"))
  else
    return base
  end
end
local function add_function_finding(findings, path, form, forms, policy, offending)
  local base = form_for_node(forms, offending, form)
  local target = function_target(base, offending)
  return table.insert(findings, finding(path, target, rule_severity(policy, "function-shape"), "function-shape", "function body is too deep; move this into a named private function", offending))
end
local function add_function_findings_for_node(findings, path, form, forms, policy, node)
  for _, offending in ipairs(function_violations(node)) do
    add_function_finding(findings, path, form, forms, policy, offending)
  end
  return nil
end
local add_function_findings
do
  local function add_function_findings0(findings, path, form, forms, policy, node)
    if enabled_3f(policy, "function-shape") then
      return add_function_findings_for_node(findings, path, form, forms, policy, node)
    else
      return nil
    end
  end
  _2amodule_2a["add-function-findings"] = add_function_findings0
  add_function_findings = _2amodule_2a["add-function-findings"]
end
local function function_child_3f(node, index, child)
  return (((child.kind == "list") or (child.kind == "sequence") or (child.kind == "table")) and not quoted_child_3f(node.children, index))
end
local function collect_function_child(node, result, walker, index, child)
  if function_child_3f(node, index, child) then
    return walker(child, result)
  else
    return nil
  end
end
local function collect_function_children(node, result, walker)
  for index, child in ipairs((node.children or {})) do
    collect_function_child(node, result, walker, index, child)
  end
  return result
end
local function collect_function_nodes(node, result)
  if (node and (node.kind == "list") and ((list_head(node) == "fn") or (list_head(node) == "lambda") or (list_head(node) == "\206\187"))) then
    table.insert(result, node)
  else
  end
  if node then
    collect_function_children(node, result, collect_function_nodes)
  else
  end
  return result
end
local function synthetic_form(path, node)
  return {line = node.open.line, col = node.open.col, ["end-line"] = node.close.line, ["end-col"] = (node.close.col + 1), form = (path .. " > function-shape"), node = node}
end
local function function_nodes(source)
  local functions = {}
  for _, root in ipairs(root_forms(source)) do
    collect_function_nodes(root, functions)
  end
  return functions
end
local function append_synthetic_node(all, path, forms, policy, node)
  return (not form_for_node(forms, node, nil) and add_function_findings(all, path, synthetic_form(path, node), forms, policy, node))
end
local function append_synthetic_nodes(all, path, forms, policy, source)
  for _, node in ipairs(function_nodes(source)) do
    append_synthetic_node(all, path, forms, policy, node)
  end
  return all
end
local function append_synthetic_findings(all, path, forms, policy, source)
  return append_synthetic_nodes(all, path, forms, policy, source)
end
local function position_before_or_equal_3f(left, right)
  return ((left.line < right.line) or ((left.line == right.line) and (left.col <= right.col)))
end
local function position_after_or_equal_3f(left, right)
  return ((left.line > right.line) or ((left.line == right.line) and (left.col >= right.col)))
end
local function node_contains_3f(outer, inner)
  return (outer and inner and outer.open and outer.close and inner.open and inner.close and position_before_or_equal_3f(outer.open, inner.open) and position_after_or_equal_3f(outer.close, inner.close) and ((outer.open.line < inner.open.line) or (outer.open.col < inner.open.col) or (outer.close.line > inner.close.line) or (outer.close.col > inner.close.col)))
end
local function contained_function_finding_3f(finding0, candidate)
  return ((candidate.rule == "function-shape") and (finding0 ~= candidate) and node_contains_3f(candidate.node, finding0.node))
end
local function function_finding_contained_3f(finding0, findings)
  local contained_3f = false
  for _, candidate in ipairs(findings) do
    contained_3f = (contained_3f or contained_function_finding_3f(finding0, candidate))
  end
  return contained_3f
end
local function keep_function_finding(finding0, findings)
  if not ((finding0.rule == "function-shape") and function_finding_contained_3f(finding0, findings)) then
    return finding0
  else
    return nil
  end
end
local remove_contained_function_findings
do
  local function remove_contained_function_findings0(findings)
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding0 in ipairs(findings) do
      local val_28_ = keep_function_finding(finding0, findings)
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    return tbl_26_
  end
  _2amodule_2a["remove-contained-function-findings"] = remove_contained_function_findings0
  remove_contained_function_findings = _2amodule_2a["remove-contained-function-findings"]
end
local synthetic_findings
do
  local function synthetic_findings0(all, path, forms, policy, source)
    return append_synthetic_findings(all, path, forms, policy, source)
  end
  _2amodule_2a["synthetic-findings"] = synthetic_findings0
  synthetic_findings = _2amodule_2a["synthetic-findings"]
end
return nil
