-- [nfnl] fnl/fennel-extras/lint/rules/binding.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.binding"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.binding"]
end
local bindings = require("fennel-extras.indent.bindings")
local ast = require("fennel-extras.lint.rules.ast")
local mutation = require("fennel-extras.lint.rules.mutation")
local registry = require("fennel-extras.lint.rules.registry")
local list_head = ast["list-head"]
local form_for_node = ast["form-for-node"]
local nearest_form = ast["nearest-form"]
local finding = registry.finding
local enabled_3f = registry["enabled?"]
local rule_severity = registry["rule-severity"]
local binding_heads = {let = true, ["when-let"] = true, ["if-let"] = true, ["with-open"] = true}
local function pair_line(pair)
  return ((pair.name and pair.name.line) or (pair.name and pair.name.open and pair.name.open.line))
end
local function line_state(state, pair)
  local line = pair_line(pair)
  return {valid = (state.valid and line and (not state.previous or (line > state.previous))), previous = line}
end
local function valid_state_3f(state)
  return state.valid
end
local function lines_valid_3f(pairs)
  local function _1_()
    local state = {valid = true, previous = nil}
    for _, pair in ipairs(pairs) do
      state = line_state(state, pair)
    end
    return state
  end
  return valid_state_3f(_1_())
end
local function pair_lines_valid_3f(node)
  return ((node.kind == "sequence") and lines_valid_3f(bindings.pairs(node)))
end
local function contains_3f(items, target, index)
  if (index > #items) then
    return false
  else
    return ((items[index] == target) or contains_3f(items, target, (index + 1)))
  end
end
local function offending_node_3f(node, policy)
  local children = ast["meaningful-children"](node)
  local binding = children[2]
  local heads = (registry["rule-options"](policy, "binding-per-line").forms or {})
  return ((node.kind == "list") and binding_heads[list_head(node)] and contains_3f(heads, list_head(node), 1) and not pair_lines_valid_3f(binding))
end
local function binding_nodes(source, policy)
  local function _3_(node)
    return offending_node_3f(node, policy)
  end
  return mutation["executable-nodes"](source, _3_)
end
local function update_ordinal(ordinals, key, ordinal)
  ordinals[key] = ordinal
  return ordinals
end
local function append_finding(findings, path, forms, policy, node, ordinals)
  local existing = form_for_node(forms, node, nil)
  local base = (existing or nearest_form(forms, node) or {form = path})
  local ordinal = ((ordinals[base.form] or 0) + 1)
  local form = (existing or {line = node.open.line, col = node.open.col, ["end-line"] = node.close.line, ["end-col"] = (node.close.col + 1), form = (base.form .. " > binding-per-line#" .. ordinal), node = node})
  table.insert(findings, finding(path, form, rule_severity(policy, "binding-per-line"), "binding-per-line", "put each binding on its own line", node))
  return update_ordinal(ordinals, base.form, ordinal)
end
local function append_node_finding(findings, path, forms, policy, node, ordinals)
  if enabled_3f(policy, "binding-per-line") then
    return append_finding(findings, path, forms, policy, node, ordinals)
  else
    return ordinals
  end
end
local findings
do
  local function findings0(findings1, path, forms, policy, source)
    do
      local ordinals = {}
      for _, node in ipairs(binding_nodes(source, policy)) do
        ordinals = append_node_finding(findings1, path, forms, policy, node, ordinals)
      end
    end
    return findings1
  end
  _2amodule_2a["findings"] = findings0
  findings = _2amodule_2a.findings
end
return nil
