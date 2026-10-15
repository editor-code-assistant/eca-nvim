-- [nfnl] fnl/fennel-extras/lint/rules.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules"]
end
local core = require("eca.nfnl.core")
local reader = require("fennel-extras.reader")
local defaults_map = {["module-style"] = "error", ["spec-macro-import"] = "error", ["spec-no-module"] = "error", ["spec-direct-require"] = "error", ["one-is-per-testing"] = "error", ["if-branch-call"] = "warning", ["core-require"] = "error"}
local defaults
do
  local function defaults0()
    return defaults_map
  end
  _2amodule_2a["defaults"] = defaults0
  defaults = _2amodule_2a.defaults
end
local function trivia_3f(node)
  return ((node.kind ~= "list") and (node.kind ~= "sequence") and (node.kind ~= "table") and ((node.kind == "whitespace") or (node.kind == "newline") or (node.kind == "comment")))
end
local function collect_meaningful_children(children, result)
  for _, child in ipairs(children) do
    if not trivia_3f(child) then
      table.insert(result, child)
    else
    end
  end
  return nil
end
local function meaningful_children(node)
  local result = {}
  if (node and node.children) then
    collect_meaningful_children(node.children, result)
  else
  end
  return result
end
local function symbol_text(node)
  if (node and (node.kind == "symbol")) then
    return node.text
  else
    return nil
  end
end
local function list_head(node)
  local children = meaningful_children(node)
  return symbol_text(children[1])
end
local function literal_text(node)
  if (node and ((node.kind == "string") or (node.kind == "symbol"))) then
    if (node.kind == "string") then
      return string.sub(node.text, 2, (string.len(node.text) - 1))
    else
      if (string.sub(node.text, 1, 1) == ":") then
        return string.sub(node.text, 2)
      else
        return node.text
      end
    end
  else
    return nil
  end
end
local function spec_file_3f(path)
  return ((string.sub(path, 1, 9) == "fnl/spec/") and true)
end
local function collect_macro_names(children, index, names)
  if (index > #children) then
    return names
  else
    local key = symbol_text(children[index])
    local value = symbol_text(children[(index + 1)])
    if ((key == ":") and value) then
      return collect_macro_names(children, (index + 2), core.assoc(names, value, true))
    else
      return collect_macro_names(children, (index + 2), names)
    end
  end
end
local function macro_import_data(bindings, target)
  local binding_children
  if (bindings and (bindings.kind == "table")) then
    binding_children = meaningful_children(bindings)
  else
    binding_children = {}
  end
  return {target = target, names = collect_macro_names(binding_children, 1, {})}
end
local function macro_import_3f(node)
  local children = meaningful_children(node)
  local bindings = children[2]
  local target = literal_text(children[3])
  if (list_head(node) == "import-macros") then
    return macro_import_data(bindings, target)
  else
    return nil
  end
end
local function has_all_3f(names)
  return (names.deftest and names.testing and names.is)
end
local function has_module_import_3f(names)
  return (names.module and names.def and names.defn and names["defn-"])
end
local function previous_meaningful(children, index)
  local previous_index = (index - 1)
  local previous = children[previous_index]
  if (previous_index <= 0) then
    return nil
  else
    if trivia_3f(previous) then
      return previous_meaningful(children, previous_index)
    else
      return previous
    end
  end
end
local function prefixed_child_3f(children, index)
  local previous = previous_meaningful(children, index)
  return (previous and (previous.kind == "prefix"))
end
local function prefixed_root_child_3f(root, index)
  return prefixed_child_3f(root.children, index)
end
local function collect_root_forms(root, forms)
  for index, child in ipairs(root.children) do
    if (((child.kind == "list") or (child.kind == "sequence") or (child.kind == "table")) and not prefixed_root_child_3f(root, index)) then
      table.insert(forms, child)
    else
    end
  end
  return nil
end
local function root_forms(source)
  local root = reader.parse(source)
  local forms = {}
  if root then
    collect_root_forms(root, forms)
  else
  end
  return forms
end
local function require_node_3f(node)
  return (list_head(node) == "require")
end
local function do_branch_3f(node)
  local children = meaningful_children(node)
  return ((symbol_text(children[1]) == "do") and (#children >= 3))
end
local function quoted_child_3f(children, index)
  local previous = previous_meaningful(children, index)
  return (previous and (previous.kind == "prefix") and ((previous.text == "'") or (previous.text == "`")))
end
local function count_is(node, index, count)
  local child = node.children[index]
  if (index > #node.children) then
    return count
  else
    if (child and ((child.kind == "list") or (child.kind == "sequence") or (child.kind == "table")) and not quoted_child_3f(node.children, index)) then
      if (list_head(child) == "testing") then
        return count_is(node, (index + 1), count)
      else
        if (list_head(child) == "is") then
          return count_is(node, (index + 1), (count + 1))
        else
          return count_is(node, (index + 1), (count + count_is(child, 1, 0)))
        end
      end
    else
      return count_is(node, (index + 1), count)
    end
  end
end
local function finding(path, form, severity, rule, message, node)
  return {kind = "finding", path = path, line = form.line, col = form.col, ["end-line"] = form["end-line"], ["end-col"] = form["end-col"], severity = severity, rule = rule, form = form.form, message = message, node = node}
end
local function rule_severity(policy, rule)
  local override = (policy and policy[rule])
  return (override or defaults_map[rule])
end
local function enabled_3f(policy, rule)
  return (rule_severity(policy, rule) ~= "off")
end
local function module_finding(path, forms, policy, module_ok)
  if (not spec_file_3f(path) and enabled_3f(policy, "module-style") and not module_ok) then
    return {{kind = "finding", path = path, line = 1, col = 1, ["end-line"] = 1, ["end-col"] = 1, severity = rule_severity(policy, "module-style"), rule = "module-style", form = (path .. " > file"), message = "file must use the module style", node = nil}}
  else
    return {}
  end
end
local function spec_import_finding(path, forms, policy, valid)
  if (spec_file_3f(path) and (path ~= "fnl/spec/eca/macros.fnlm") and enabled_3f(policy, "spec-macro-import") and not valid) then
    return {{kind = "finding", path = path, line = 1, col = 1, ["end-line"] = 1, ["end-col"] = 1, severity = rule_severity(policy, "spec-macro-import"), rule = "spec-macro-import", form = (path .. " > spec"), message = "specs must import deftest, testing, and is from spec.eca.macros", node = nil}}
  else
    return {}
  end
end
local function direct_require_3f(path)
  return (path == "fnl/spec/eca/macros.fnlm")
end
local function add_core_finding(findings, path, form, head, children, node, policy)
  do
    local finding_form
    if (head == "local") then
      finding_form = {line = form.line, col = form.col, ["end-line"] = form["end-line"], ["end-col"] = form["end-col"], form = (path .. " > local:" .. symbol_text(children[2]))}
    else
      finding_form = form
    end
    table.insert(findings, finding(path, finding_form, rule_severity(policy, "core-require"), "core-require", "bind eca.nfnl.core as core", node))
  end
  return nil
end
local function add_spec_direct_require_finding(findings, path, form, policy, node)
  local children = meaningful_children(node)
  local target = literal_text(children[2])
  if (((target == "plenary.busted") or (target == "luassert")) and enabled_3f(policy, "spec-direct-require")) then
    return table.insert(findings, finding(path, form, rule_severity(policy, "spec-direct-require"), "spec-direct-require", "specs must use the shared macro import", node))
  else
    return nil
  end
end
local function add_testing_finding(findings, path, form, policy, node)
  local count = count_is(node, 1, 0)
  if ((count ~= 1) and enabled_3f(policy, "one-is-per-testing")) then
    return table.insert(findings, finding(path, form, rule_severity(policy, "one-is-per-testing"), "one-is-per-testing", "each testing form must contain exactly one is", node))
  else
    return nil
  end
end
local function add_core_require_finding(findings, path, form, head, node, policy)
  local children = meaningful_children(node)
  local require_form
  if (head == "local") then
    require_form = children[3]
  else
    require_form = node
  end
  local require_children
  if require_form then
    require_children = meaningful_children(require_form)
  else
    require_children = {}
  end
  local target
  if (list_head(require_form) == "require") then
    target = literal_text(require_children[2])
  else
    target = nil
  end
  local canonical
  if (head == "local") then
    canonical = ((#children == 3) and (symbol_text(children[2]) == "core") and (#require_children == 2))
  else
    canonical = (#children == 2)
  end
  if ((target == "eca.nfnl.core") and not canonical) then
    return add_core_finding(findings, path, form, head, children, node, policy)
  else
    return nil
  end
end
local function evaluate_form(path, form, policy)
  local node = form.node
  local head
  if node then
    head = list_head(node)
  else
    head = nil
  end
  local findings = {}
  if (spec_file_3f(path) and (head == "module") and enabled_3f(policy, "spec-no-module")) then
    table.insert(findings, finding(path, form, rule_severity(policy, "spec-no-module"), "spec-no-module", "specs must not declare a module", node))
  else
  end
  if (spec_file_3f(path) and not direct_require_3f(path) and require_node_3f(node)) then
    add_spec_direct_require_finding(findings, path, form, policy, node)
  else
  end
  if (head == "testing") then
    add_testing_finding(findings, path, form, policy, node)
  else
  end
  if ((head == "do") and do_branch_3f(node) and (string.match(form.form, " > then$") or string.match(form.form, " > else$") or string.match(form.form, " > then#[0-9]+$")) and enabled_3f(policy, "if-branch-call")) then
    table.insert(findings, finding(path, form, rule_severity(policy, "if-branch-call"), "if-branch-call", "if branch contains multiple expressions; move them to a named helper", node))
  else
  end
  if (((head == "local") or (head == "require")) and node and enabled_3f(policy, "core-require")) then
    add_core_require_finding(findings, path, form, head, node, policy)
  else
  end
  return findings
end
local function update_check_state(state, import_info, head)
  local module_import
  if (import_info and (import_info.target == "eca.nfnl.macros.aniseed")) then
    module_import = has_module_import_3f(import_info.names)
  else
    module_import = state["module-import"]
  end
  local module_form = (state["module-form"] or (head == "module"))
  local spec_import
  if (import_info and (import_info.target == "spec.eca.macros")) then
    spec_import = has_all_3f(import_info.names)
  else
    spec_import = state["spec-import"]
  end
  return {["module-import"] = module_import, ["module-form"] = module_form, ["spec-import"] = spec_import}
end
local function check_state(nodes, index, state)
  local node = nodes[index]
  local import_info = macro_import_3f(node)
  if (index > #nodes) then
    return state
  else
    return check_state(nodes, (index + 1), update_check_state(state, import_info, list_head(node)))
  end
end
local check
do
  local function check0(path, forms, policy, source)
    local state = check_state(root_forms(source), 1, {["module-form"] = false, ["module-import"] = false, ["spec-import"] = false})
    local all = module_finding(path, forms, policy, (state["module-import"] and state["module-form"]))
    for _, f in ipairs(spec_import_finding(path, forms, policy, state["spec-import"])) do
      table.insert(all, f)
    end
    for _, form in ipairs(forms) do
      for _0, f in ipairs((evaluate_form(path, form, policy) or {})) do
        table.insert(all, f)
      end
    end
    return all
  end
  _2amodule_2a["check"] = check0
  check = _2amodule_2a.check
end
return nil
