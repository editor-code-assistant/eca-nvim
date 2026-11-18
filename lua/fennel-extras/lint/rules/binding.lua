-- [nfnl] fnl/fennel-extras/lint/rules/binding.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.binding"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.binding"]
end
local core = require("eca.nfnl.core")
local ast = require("fennel-extras.lint.rules.ast")
local bindings = require("fennel-extras.indent.bindings")
local registry = require("fennel-extras.lint.rules.registry")
local traverse = require("fennel-extras.lint.rules.traverse")
local function contains_3f(items, target, index)
  return ((index <= #(items or {})) and ((items[index] == target) or contains_3f(items, target, (index + 1))))
end
local function single_binding_3f(node)
  local children = ast["meaningful-children"](node)
  return ((#children == 3) and (#bindings.pairs(children[2]) == 1))
end
local function form_for_node(forms, path, node)
  local form = ast["form-for-node"](forms, node, {line = node.open.line, col = node.open.col, ["end-line"] = node.close.line, ["end-col"] = (node.close.col + 1), form = (path .. " > " .. (ast["list-head"](node) or "form")), node = node})
  local head = ast["list-head"](node)
  return core.assoc(form, "form", vim.fn.substitute(form.form, "top#\\d\\+$", (head .. "#1"), ""))
end
local findings
do
  local function findings0(path, forms, policy, source, rule)
    local result = {}
    local selected = (registry["enabled?"](policy, rule) and (policy.options.forms or {}))
    local function _1_(candidate)
      return (contains_3f(selected, ast["list-head"](candidate), 1) and single_binding_3f(candidate))
    end
    for _, node in ipairs(traverse["executable-nodes"](source, _1_)) do
      table.insert(result, registry.finding(path, form_for_node(forms, path, node), registry["rule-severity"](policy, rule), rule, "avoid introducing a local binding for a single body expression", node))
    end
    return result
  end
  _2amodule_2a["findings"] = findings0
  findings = _2amodule_2a.findings
end
return nil
