-- [nfnl] fnl/fennel-extras/lint/rules/module.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.module"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.module"]
end
local core = require("eca.nfnl.core")
local ast = require("fennel-extras.lint.rules.ast")
local root_forms = ast["root-forms"]
local registry = require("fennel-extras.lint.rules.registry")
local meaningful_children = ast["meaningful-children"]
local symbol_text = ast["symbol-text"]
local list_head = ast["list-head"]
local literal_text = ast["literal-text"]
local import_macros_3f = ast["import-macros?"]
local has_all_3f = ast["has-all?"]
local enabled_3f = registry["enabled?"]
local rule_severity = registry["rule-severity"]
local finding = registry.finding
local required_form_finding
do
  local function required_form_finding0(path, source, policy)
    if enabled_3f(policy, "required-form") then
      local options = registry["rule-options"](policy, "required-form")
      local found
      do
        local result = false
        for _, form in ipairs(root_forms(source)) do
          result = (result or (list_head((form.node or form)) == options.forms[1]))
        end
        found = result
      end
      if not found then
        return {{kind = "finding", path = path, line = 1, col = 1, ["end-line"] = 1, ["end-col"] = 1, severity = rule_severity(policy, "required-form"), rule = "required-form", form = (path .. " > file"), message = "file must contain a required top-level form", node = nil}}
      else
        return {}
      end
    else
      return {}
    end
  end
  _2amodule_2a["required-form-finding"] = required_form_finding0
  required_form_finding = _2amodule_2a["required-form-finding"]
end
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
local function contains_3f(items, target, index)
  if (index > #items) then
    return false
  else
    return ((items[index] == target) or contains_3f(items, target, (index + 1)))
  end
end
local function module_target(node)
  local head = list_head(node)
  local children = meaningful_children(node)
  local index
  if (head == "import-macros") then
    index = 3
  else
    index = 2
  end
  if ((head == "require") or (head == "import") or (head == "import-macros") or (head == "module")) then
    return literal_text(children[index])
  else
    return nil
  end
end
local function finding_form(path, form, head, children)
  if (head == "local") then
    return {line = form.line, col = form.col, ["end-line"] = form["end-line"], ["end-col"] = form["end-col"], form = (path .. " > local:" .. symbol_text(children[2]))}
  else
    return form
  end
end
local function canonical_require_3f(head, children, require_children, binding)
  return (((head == "local") and (#children == 3) and (symbol_text(children[2]) == binding) and (#require_children == 2)) or ((head == "require") and (#children == 2)))
end
local function exempt_file_3f(path, policy, options)
  local patterns = (options["exempt-files"] or {})
  local result = false
  for _, pattern in ipairs(patterns) do
    result = (result or (policy.matcher and policy.matcher(pattern, path)))
  end
  return result
end
local module_import_finding
do
  local function module_import_finding0(findings, path, form, head, node, policy)
    local children = meaningful_children(node)
    local require = ((head == "local") and children[3])
    local req_children
    if require then
      req_children = meaningful_children(require)
    else
      req_children = {}
    end
    local options = registry["rule-options"](policy, "module-import")
    local target = module_target((require or node))
    local import_info = import_macros_3f(node)
    local modules = (options.modules or {})
    local binding = (options.binding or "core")
    local forbidden = ((options.mode == "forbid") and not exempt_file_3f(path, policy, options) and target and contains_3f(modules, target, 1))
    local required
    local and_9_ = (options.mode == "require") and not exempt_file_3f(path, policy, options) and (target == options.module)
    if and_9_ then
      if import_info then
        and_9_ = not has_all_3f(import_info.names, (options.forms or {}))
      else
        and_9_ = not canonical_require_3f(head, children, req_children, binding)
      end
    end
    required = and_9_
    if (enabled_3f(policy, "module-import") and (forbidden or required)) then
      local _11_
      if forbidden then
        _11_ = "forbidden module import"
      else
        _11_ = "bind the required module canonically"
      end
      return table.insert(findings, finding(path, finding_form(path, form, head, children), rule_severity(policy, "module-import"), "module-import", _11_, node))
    else
      return nil
    end
  end
  _2amodule_2a["module-import-finding"] = module_import_finding0
  module_import_finding = _2amodule_2a["module-import-finding"]
end
return nil
