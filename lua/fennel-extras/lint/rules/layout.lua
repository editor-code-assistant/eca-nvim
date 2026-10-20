-- [nfnl] fnl/fennel-extras/lint/rules/layout.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.layout"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.layout"]
end
local core = require("eca.nfnl.core")
local ast = require("fennel-extras.lint.rules.ast")
local mutation = require("fennel-extras.lint.rules.mutation")
local registry = require("fennel-extras.lint.rules.registry")
local meaningful_children = ast["meaningful-children"]
local list_head = ast["list-head"]
local form_for_node = ast["form-for-node"]
local nearest_form = ast["nearest-form"]
local finding = registry.finding
local enabled_3f = registry["enabled?"]
local rule_severity = registry["rule-severity"]
local clause_heads = {case = true, match = true, ["case-try"] = true, ["match-try"] = true}
local binding_heads = {let = true, ["when-let"] = true, ["if-let"] = true, ["with-open"] = true}
local function child_line(child)
  return ((child and child.open and child.open.line) or (child and child.line) or 0)
end
local function child_end_line(child)
  return ((child and child.close and child.close.line) or (child and child.line) or 0)
end
local function unit(children, first_index, last_index)
  return {start = child_line(children[first_index]), ["end"] = child_end_line(children[last_index])}
end
local function pair_index_3f(index, start_index)
  return ((index >= start_index) and (math.fmod((index - start_index), 2) == 0))
end
local function append_pair_unit(result, children, start_index, index)
  if pair_index_3f(index, start_index) then
    return core.concat(result, {unit(children, index, math.min((index + 1), #children))})
  else
    return result
  end
end
local function pair_units(children, start_index)
  local result = {}
  for index, _ in ipairs(children) do
    result = append_pair_unit(result, children, start_index, index)
  end
  return result
end
local function ordinary_units(children)
  local tbl_26_ = {}
  local i_27_ = 0
  for index, _ in ipairs(children) do
    local val_28_ = unit(children, index, index)
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function units_for_list(node, children)
  local head = list_head(node)
  return (((head == "if") and (#children >= 5) and pair_units(children, 2)) or (clause_heads[head] and pair_units(children, 3)) or ordinary_units(children))
end
local function units_for_node(node)
  local children = meaningful_children(node)
  return (((node.kind == "table") and pair_units(children, 1)) or ((node.kind == "list") and units_for_list(node, children)) or ordinary_units(children))
end
local function offending_adjacency_3f(node, index, previous, current)
  local opening_line = node.open.line
  local opening_list_3f = ((node.kind == "list") and (index == 2))
  local allowed_opening_3f = (opening_list_3f and (current.start == opening_line))
  return (not allowed_opening_3f and (current.start <= previous["end"]))
end
local function offending_units_step(node, units, index, previous)
  local current = units[index]
  if (index > #units) then
    return false
  else
    return ((previous and offending_adjacency_3f(node, index, previous, current)) or offending_units_step(node, units, (index + 1), current))
  end
end
local function offending_units_3f(node)
  local units = units_for_node(node)
  return ((node.close.line > node.open.line) and offending_units_step(node, units, 2, units[1]))
end
local function binding_layout_3f(node)
  local children = meaningful_children(node)
  local and_4_ = binding_heads[list_head(node)]
  if and_4_ then
    local result = false
    for _, child in ipairs(children) do
      result = (result or ((child.kind == "sequence") and offending_units_3f(core.assoc(child, "kind", "table"))))
    end
    and_4_ = result
  end
  return and_4_
end
local function layout_container_3f(node)
  return ((node.kind == "list") or (node.kind == "sequence") or (node.kind == "table"))
end
local function layout_excluded_3f(node, head)
  return (((node.kind == "list") and ((head == "defn") or (head == "defn-"))) or ((node.kind == "sequence") and (math.fmod(#meaningful_children(node), 2) == 0)))
end
local function delayed_list_head_3f(node)
  local children = meaningful_children(node)
  local head = children[1]
  local head_line = child_line(head)
  return ((node.kind == "list") and head and (head_line ~= node.open.line))
end
local function layout_body_result(node, head)
  if ((node.kind == "list") and binding_heads[head]) then
    return binding_layout_3f(node)
  else
    return offending_units_3f(node)
  end
end
local function layout_result(node, head)
  return (delayed_list_head_3f(node) or layout_body_result(node, head))
end
local function layout_node_3f(node)
  local head = list_head(node)
  return (layout_container_3f(node) and not layout_excluded_3f(node, head) and layout_result(node, head))
end
local function finding_form(path, forms, node, ordinals)
  local existing = form_for_node(forms, node, nil)
  local base = (existing or nearest_form(forms, node) or {form = path})
  local ordinal = ((ordinals[base.form] or 0) + 1)
  return (existing or {line = node.open.line, col = node.open.col, ["end-line"] = node.close.line, ["end-col"] = (node.close.col + 1), form = (base.form .. " > multiline-layout#" .. ordinal), node = node}), core.assoc(ordinals, base.form, ordinal)
end
local function insert_finding(findings, path, forms, policy, node, ordinals, key)
  local form, next_ordinals = finding_form(path, forms, node, ordinals)
  table.insert(findings, finding(path, form, rule_severity(policy, "multiline-layout"), "multiline-layout", "multi-line form: put each item on its own line", node))
  return core.assoc(next_ordinals, key, true)
end
local function append_finding(findings, path, forms, policy, node, ordinals)
  local base = (form_for_node(forms, node, nil) or nearest_form(forms, node) or {form = path})
  local key = (base.form .. ":" .. node.open.line)
  if ordinals[key] then
    return ordinals
  else
    return insert_finding(findings, path, forms, policy, node, ordinals, key)
  end
end
local function append_layout_findings(findings, path, forms, policy, source)
  local ordinals = {}
  for _, node in ipairs(mutation["executable-nodes"](source, layout_node_3f)) do
    ordinals = append_finding(findings, path, forms, policy, node, ordinals)
  end
  return ordinals
end
local findings
do
  local function findings0(findings1, path, forms, policy, source)
    if enabled_3f(policy, "multiline-layout") then
      append_layout_findings(findings1, path, forms, policy, source)
    else
    end
    return findings1
  end
  _2amodule_2a["findings"] = findings0
  findings = _2amodule_2a.findings
end
return nil
