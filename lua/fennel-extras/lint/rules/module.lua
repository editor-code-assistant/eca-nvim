-- [nfnl] fnl/fennel-extras/lint/rules/module.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.module"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.module"]
end
local core = require("eca.nfnl.core")
local ast = require("fennel-extras.lint.rules.ast")
local registry = require("fennel-extras.lint.rules.registry")
local meaningful_children = ast["meaningful-children"]
local symbol_text = ast["symbol-text"]
local list_head = ast["list-head"]
local literal_text = ast["literal-text"]
local enabled_3f = registry["enabled?"]
local rule_severity = registry["rule-severity"]
local finding = registry.finding
local module_finding
do
  local function module_finding0(path, forms, policy, module_ok)
    if (enabled_3f(policy, "module-style") and not module_ok) then
      return {{kind = "finding", path = path, line = 1, col = 1, ["end-line"] = 1, ["end-col"] = 1, severity = rule_severity(policy, "module-style"), rule = "module-style", form = (path .. " > file"), message = "file must use the module style", node = nil}}
    else
      return {}
    end
  end
  _2amodule_2a["module-finding"] = module_finding0
  module_finding = _2amodule_2a["module-finding"]
end
local function core_finding_form(path, form, head, children)
  if (head == "local") then
    return {line = form.line, col = form.col, ["end-line"] = form["end-line"], ["end-col"] = form["end-col"], form = (path .. " > local:" .. symbol_text(children[2]))}
  else
    return form
  end
end
local function add_core_finding(findings, path, form, head, children, node, policy)
  do
    local finding_form = core_finding_form(path, form, head, children)
    table.insert(findings, finding(path, finding_form, rule_severity(policy, "direct-require"), "direct-require", "bind eca.nfnl.core as core", node))
  end
  return nil
end
local function direct_require_form(head, children, node)
  return (((head == "local") and children[3]) or node)
end
local function direct_require_target(require_form, require_children)
  return ((list_head(require_form) == "require") and literal_text(require_children[2]))
end
local function canonical_direct_require_3f(head, children, require_children, binding)
  return (((head == "local") and (#children == 3) and (symbol_text(children[2]) == binding) and (#require_children == 2)) or ((head == "require") and (#children == 2)))
end
local function maybe_add_direct_require_finding(findings, path, form, head, children, node, policy, target, canonical, options)
  if (options and (options.mode == "require") and (target == options.module) and not canonical) then
    return add_core_finding(findings, path, form, head, children, node, policy)
  else
    return nil
  end
end
local function direct_require_children(require_form)
  if require_form then
    return meaningful_children(require_form)
  else
    return {}
  end
end
local direct_require_finding
do
  local function direct_require_finding0(findings, path, form, head, node, policy)
    local children = meaningful_children(node)
    local require_form = direct_require_form(head, children, node)
    local require_children = direct_require_children(require_form)
    local target = direct_require_target(require_form, require_children)
    local options = registry["rule-options"](policy, "direct-require")
    local binding = (options and options.binding)
    local canonical = canonical_direct_require_3f(head, children, require_children, binding)
    return maybe_add_direct_require_finding(findings, path, form, head, children, node, policy, target, canonical, options)
  end
  _2amodule_2a["direct-require-finding"] = direct_require_finding0
  direct_require_finding = _2amodule_2a["direct-require-finding"]
end
return nil
