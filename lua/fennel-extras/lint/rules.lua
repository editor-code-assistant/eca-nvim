-- [nfnl] fnl/fennel-extras/lint/rules.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules"]
end
local core = require("eca.nfnl.core")
local reader = require("fennel-extras.reader")
local defaults_map = {["module-style"] = "error", ["spec-macro-import"] = "error", ["spec-no-module"] = "error", ["spec-direct-require"] = "error", ["one-is-per-testing"] = "error", ["if-branch-call"] = "warning", ["function-shape"] = "warning", ["core-require"] = "error"}
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
local function collect_meaningful_child(result, child)
  if not trivia_3f(child) then
    return table.insert(result, child)
  else
    return nil
  end
end
local function collect_meaningful_children(children, result)
  for _, child in ipairs(children) do
    collect_meaningful_child(result, child)
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
  return (node and ((node.kind == "string") or (node.kind == "symbol")) and (((node.kind == "string") and string.sub(node.text, 2, (string.len(node.text) - 1))) or ((string.sub(node.text, 1, 1) == ":") and string.sub(node.text, 2)) or node.text))
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
local function macro_binding_children(bindings)
  if (bindings and (bindings.kind == "table")) then
    return meaningful_children(bindings)
  else
    return {}
  end
end
local function macro_import_data(bindings, target)
  local binding_children = macro_binding_children(bindings)
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
local function previous_meaningful_child(children, previous_index)
  local previous = children[previous_index]
  if (previous_index <= 0) then
    return nil
  else
    return ((trivia_3f(previous) and previous_meaningful_child(children, (previous_index - 1))) or previous)
  end
end
local function previous_meaningful(children, index)
  return previous_meaningful_child(children, (index - 1))
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
    do local _ = (((child.kind == "list") or (child.kind == "sequence") or (child.kind == "table")) and not prefixed_root_child_3f(root, index) and table.insert(forms, child)) end
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
local function count_is_child(node, child, index, count, recurse)
  return ((child and ((child.kind == "list") or (child.kind == "sequence") or (child.kind == "table")) and not quoted_child_3f(node.children, index) and (((list_head(child) == "testing") and recurse(node, (index + 1), count)) or ((list_head(child) == "is") and recurse(node, (index + 1), (count + 1))) or recurse(node, (index + 1), (count + recurse(child, 1, 0))))) or recurse(node, (index + 1), count))
end
local function count_is(node, index, count)
  local child = node.children[index]
  if (index > #node.children) then
    return count
  else
    return count_is_child(node, child, index, count, count_is)
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
local function core_require_form(head, children, node)
  return (((head == "local") and children[3]) or node)
end
local function core_require_target(require_form, require_children)
  return ((list_head(require_form) == "require") and literal_text(require_children[2]))
end
local function canonical_core_require_3f(head, children, require_children)
  return (((head == "local") and (#children == 3) and (symbol_text(children[2]) == "core") and (#require_children == 2)) or ((head == "require") and (#children == 2)))
end
local function maybe_add_core_require_finding(findings, path, form, head, children, node, policy, target, canonical)
  if ((target == "eca.nfnl.core") and not canonical) then
    return add_core_finding(findings, path, form, head, children, node, policy)
  else
    return nil
  end
end
local function core_require_children(require_form)
  if require_form then
    return meaningful_children(require_form)
  else
    return {}
  end
end
local function add_core_require_finding(findings, path, form, head, node, policy)
  local children = meaningful_children(node)
  local require_form = core_require_form(head, children, node)
  local require_children = core_require_children(require_form)
  local target = core_require_target(require_form, require_children)
  local canonical = canonical_core_require_3f(head, children, require_children)
  return maybe_add_core_require_finding(findings, path, form, head, children, node, policy, target, canonical)
end
local function function_head_3f(head)
  return ((head == "defn") or (head == "defn-") or (head == "fn") or (head == "lambda") or (head == "\206\187"))
end
local function layer_head_3f(head)
  return ((head == "if") or (head == "when") or (head == "case") or (head == "match") or (head == "each") or (head == "for") or (head == "icollect") or (head == "collect") or (head == "accumulate") or (head == "while") or function_head_3f(head))
end
local function loop_head_3f(head)
  return ((head == "each") or (head == "for") or (head == "icollect") or (head == "collect") or (head == "accumulate") or (head == "while"))
end
local function append_nodes(target, nodes)
  for _, node in ipairs(nodes) do
    table.insert(target, node)
  end
  return target
end
local function parameter_index(children, head, index)
  if (index > #children) then
    return nil
  else
    return (((head ~= "defn") and (head ~= "defn-") and (children[index].kind == "sequence") and index) or parameter_index(children, head, (index + 1)))
  end
end
local function docstring_adjusted_index(children, index)
  if (index and children[index] and (children[index].kind == "string")) then
    return (index + 1)
  else
    return index
  end
end
local function function_body_child(children, body_start, index, child)
  if (body_start and (index >= body_start) and not quoted_child_3f(children, index)) then
    return child
  else
    return nil
  end
end
local function function_body(children, body_start)
  local tbl_26_ = {}
  local i_27_ = 0
  for index, child in ipairs(children) do
    local val_28_ = function_body_child(children, body_start, index, child)
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function function_parameter(children, head)
  if ((head == "defn") or (head == "defn-")) then
    return 3
  else
    return parameter_index(children, head, 2)
  end
end
local function function_body_index(parameter)
  return (parameter and (parameter + 1))
end
local function function_body_start(children, parameter)
  return docstring_adjusted_index(children, function_body_index(parameter))
end
local function function_info(node)
  local children = meaningful_children(node)
  local head = symbol_text(children[1])
  local parameter = function_parameter(children, head)
  local body_start = function_body_start(children, parameter)
  local body = function_body(children, body_start)
  return (function_head_3f(head) and parameter and {head = head, children = children, parameter = parameter, body = body})
end
local function marker_3f(node, text)
  return (node and (node.kind == "symbol") and (node.text == text))
end
local function direct_layer_3f(children, index)
  return (not quoted_child_3f(children, index) and (loop_head_3f(list_head(children[index])) or function_head_3f(list_head(children[index]))))
end
local function direct_layer_value(children, index)
  if direct_layer_3f(children, index) then
    return 1
  else
    return 0
  end
end
local function layer_value(layer_3f)
  if layer_3f then
    return 1
  else
    return 0
  end
end
local function direct_layer_count(children, index)
  return (((index > #children) and 0) or (direct_layer_value(children, index) + direct_layer_count(children, (index + 1))))
end
local function leaf_valid_sequence_step(state, children, child, index, valid_3f)
  return (state and (quoted_child_3f(children, index) or valid_3f(child)))
end
local function leaf_valid_sequence_3f(node, valid_3f)
  local children = meaningful_children(node)
  local state = true
  for index, child in ipairs(children) do
    state = leaf_valid_sequence_step(state, children, child, index, valid_3f)
  end
  return state
end
local function leaf_valid_binding_step(state, children, child, index, valid_3f)
  return (state and ((index < 2) or quoted_child_3f(children, index) or valid_3f(child)))
end
local function leaf_valid_binding_list_3f(children, valid_3f)
  local state = true
  for index, child in ipairs(children) do
    state = leaf_valid_binding_step(state, children, child, index, valid_3f)
  end
  return state
end
local function leaf_valid_call_state_update(state, child, valid_3f)
  local child_head = list_head(child)
  local layer_3f = (loop_head_3f(child_head) or function_head_3f(child_head))
  return {valid = (layer_3f or valid_3f(child)), layers = (state.layers + layer_value(layer_3f))}
end
local function leaf_valid_call_state_step(children, state, child, index, valid_3f)
  if (state.valid and (index >= 2) and not quoted_child_3f(children, index)) then
    return leaf_valid_call_state_update(state, child, valid_3f)
  else
    return state
  end
end
local function leaf_valid_call_state(children, valid_3f)
  local state = {valid = true, layers = 0}
  for index, child in ipairs(children) do
    state = leaf_valid_call_state_step(children, state, child, index, valid_3f)
  end
  return state
end
local function leaf_valid_call_3f(children, valid_3f)
  local result = leaf_valid_call_state(children, valid_3f)
  return (result.valid and (result.layers <= 1))
end
local function leaf_valid_list_3f(children, head, valid_3f)
  return (not (loop_head_3f(head) or function_head_3f(head)) and ((((head == "var") or (head == "set") or (head == "local") or (head == "tset")) and leaf_valid_binding_list_3f(children, valid_3f)) or (not ((head == "var") or (head == "set") or (head == "local") or (head == "tset")) and leaf_valid_call_3f(children, valid_3f))))
end
local function leaf_node_kind(node)
  return (((not node or (node.kind == "prefix") or (node.kind == "whitespace") or (node.kind == "newline") or (node.kind == "comment") or (node.kind == "string") or (node.kind == "symbol") or (node.kind == "number") or (node.kind == "boolean")) and "atomic") or ((node.kind == "sequence") and "sequence") or ((node.kind == "table") and "table") or ((node.kind == "list") and "list") or "other")
end
local function leaf_valid_list_node_3f(node, valid_3f)
  local children = meaningful_children(node)
  local head = symbol_text(children[1])
  if (head == "do") then
    return ((#children == 2) and (quoted_child_3f(children, 2) or valid_3f(children[2])))
  elseif (head == "if") then
    return false
  elseif (head == "when") then
    return false
  elseif (head == "case") then
    return false
  elseif (head == "match") then
    return false
  elseif (head == "let") then
    return false
  else
    local _ = head
    return leaf_valid_list_3f(children, head, valid_3f)
  end
end
local function leaf_valid_3f(node)
  local case_27_ = leaf_node_kind(node)
  if (case_27_ == "atomic") then
    return true
  elseif (case_27_ == "sequence") then
    return leaf_valid_sequence_3f(node, leaf_valid_3f)
  elseif (case_27_ == "table") then
    return leaf_valid_sequence_3f(node, leaf_valid_3f)
  elseif (case_27_ == "list") then
    return leaf_valid_list_node_3f(node, leaf_valid_3f)
  elseif (case_27_ == "other") then
    return true
  else
    return nil
  end
end
local function plain_call_one_layer_3f(node)
  local children = meaningful_children(node)
  local result
  do
    local state = {valid = true, layers = 0}
    for index, child in ipairs(children) do
      if (state.valid and (index >= 2) and not quoted_child_3f(children, index)) then
        local child_head = list_head(child)
        local layer_3f = (loop_head_3f(child_head) or function_head_3f(child_head))
        local _29_
        if layer_3f then
          _29_ = 1
        else
          _29_ = 0
        end
        state = {valid = (layer_3f or leaf_valid_3f(child)), layers = (state.layers + _29_)}
      else
        state = state
      end
    end
    result = state
  end
  return (result.valid and (result.layers == 1))
end
local function leaf_violations(node)
  if leaf_valid_3f(node) then
    return {}
  else
    return {node}
  end
end
local function expression_violations(node)
  local head = list_head(node)
  return (((head == "do") and {}) or ((head == "let") and {}) or ((node.kind == "list") and (loop_head_3f(head) or function_head_3f(head)) and {}) or ((node.kind == "list") and plain_call_one_layer_3f(node) and {}) or leaf_violations(node))
end
local function explicit_if_3f(children, index)
  if (index > #children) then
    return false
  else
    return (marker_3f(children[index], "then") or marker_3f(children[index], "elseif") or marker_3f(children[index], "else") or explicit_if_3f(children, (index + 1)))
  end
end
local function validate_if_explicit(children, index, result)
  if (index > #children) then
    return result
  else
    local child = children[index]
    if (marker_3f(child, "then") or marker_3f(child, "elseif") or marker_3f(child, "else")) then
      if children[(index + 1)] then
        return validate_if_explicit(children, (index + 2), append_nodes(result, expression_violations(children[(index + 1)])))
      else
        return validate_if_explicit(children, (index + 1), result)
      end
    else
      return validate_if_explicit(children, (index + 1), append_nodes(result, expression_violations(child)))
    end
  end
end
local function implicit_branch_values(children, index)
  return append_nodes(((children[(index + 1)] and expression_violations(children[(index + 1)])) or {}), expression_violations(children[index]))
end
local function append_implicit_branch(children, index, result)
  return append_nodes(result, implicit_branch_values(children, index))
end
local function validate_if_implicit(children, index, result)
  if (index > #children) then
    return result
  else
    return (((index == #children) and ((index % 2) == 0) and append_nodes(result, expression_violations(children[index]))) or validate_if_implicit(children, (index + 2), append_implicit_branch(children, index, result)))
  end
end
local function validate_if_children(children)
  if explicit_if_3f(children, 2) then
    return validate_if_explicit(children, 2, {})
  else
    return validate_if_implicit(children, 2, {})
  end
end
local function validate_if(node)
  return validate_if_children(meaningful_children(node))
end
local function validate_when_head(children, result)
  if children[2] then
    return append_nodes(result, expression_violations(children[2]))
  else
    return result
  end
end
local function append_if_index(result, index, threshold, value)
  if (index >= threshold) then
    return append_nodes(result, expression_violations(value))
  else
    return nil
  end
end
local function validate_when_body(children, result)
  for index, child in ipairs(children) do
    append_if_index(result, index, 3, child)
  end
  return result
end
local function validate_when(node)
  local children = meaningful_children(node)
  return validate_when_body(children, validate_when_head(children, {}))
end
local function loop_bindings(children)
  if (children[2] and (children[2].kind == "sequence")) then
    return meaningful_children(children[2])
  else
    return {}
  end
end
local function loop_start(bindings)
  if (#bindings > 0) then
    return 3
  else
    return 2
  end
end
local function append_if_unquoted(bindings, result, index, value)
  if not quoted_child_3f(bindings, index) then
    return append_nodes(result, expression_violations(value))
  else
    return nil
  end
end
local function validate_loop_bindings(bindings, result)
  for index, child in ipairs(bindings) do
    append_if_unquoted(bindings, result, index, child)
  end
  return result
end
local function validate_loop_body(children, start, result)
  for index, child in ipairs(children) do
    append_if_index(result, index, start, child)
  end
  return result
end
local function validate_loop(node)
  local children = meaningful_children(node)
  local bindings = loop_bindings(children)
  local start = loop_start(bindings)
  return validate_loop_body(children, start, validate_loop_bindings(bindings, {}))
end
local function validate_case(node)
  local result = {}
  for index, child in ipairs(meaningful_children(node)) do
    append_if_index(result, index, 2, child)
  end
  return result
end
local function validate_layer_by_head(node, head)
  return (((head == "if") and validate_if(node)) or ((head == "when") and validate_when(node)) or (((head == "case") or (head == "match")) and validate_case(node)) or (loop_head_3f(head) and validate_loop(node)) or {})
end
local function validate_layer(node)
  return validate_layer_by_head(node, list_head(node))
end
local function body_expression_result(node, head)
  return (((head == "let") and {node}) or ((head == "do") and ((not leaf_valid_3f(node) and {node}) or {})) or (layer_head_3f(head) and validate_layer(node)) or expression_violations(node))
end
local function body_expression_violations(node)
  return body_expression_result(node, list_head(node))
end
local function validate_let_bindings(bindings, result)
  if (bindings and (bindings.kind == "sequence")) then
    local binding_children = meaningful_children(bindings)
    for index, child in ipairs(binding_children) do
      if (((index % 2) == 0) and not quoted_child_3f(binding_children, index)) then
        append_nodes(result, expression_violations(child))
      else
      end
    end
  else
  end
  return result
end
local function validate_let_body(children, result)
  for index, child in ipairs(children) do
    do local _ = ((index >= 3) and append_nodes(result, body_expression_violations(child))) end
  end
  return result
end
local function validate_let(node)
  local children = meaningful_children(node)
  local bindings = children[2]
  return validate_let_body(children, validate_let_bindings(bindings, {}))
end
local function function_first_let_3f(body)
  return (body[1] and (list_head(body[1]) == "let"))
end
local function function_body_start_index(first_let_3f)
  if first_let_3f then
    return 2
  else
    return 1
  end
end
local function function_body_initial(body, result, first_let_3f)
  if first_let_3f then
    return append_nodes(result, validate_let(body[1]))
  else
    return result
  end
end
local function validate_function_body(body, result)
  local first_let_3f = function_first_let_3f(body)
  local start = function_body_start_index(first_let_3f)
  local initial = function_body_initial(body, result, first_let_3f)
  for index, child in ipairs(body) do
    do local _ = ((index >= start) and append_nodes(initial, body_expression_violations(child))) end
  end
  return initial
end
local function function_violations(node)
  local info = function_info(node)
  local body = ((info and info.body) or {})
  return validate_function_body(body, {})
end
local function form_for_node(forms, node, fallback)
  if (#forms > 0) then
    local form = forms[1]
    if ((form.node == node) or (node.open and (form.line == node.open.line) and (form.col == node.open.col))) then
      return form
    else
      local _48_
      do
        local tbl_26_ = {}
        local i_27_ = 0
        for index, value in ipairs(forms) do
          local val_28_
          if (index > 1) then
            val_28_ = value
          else
            val_28_ = nil
          end
          if (nil ~= val_28_) then
            i_27_ = (i_27_ + 1)
            tbl_26_[i_27_] = val_28_
          else
          end
        end
        _48_ = tbl_26_
      end
      return form_for_node(_48_, node, fallback)
    end
  else
    return fallback
  end
end
local function function_target(base, offending)
  if ((list_head(offending) == "if") and (string.match(base.form, " > then$") or string.match(base.form, " > else$"))) then
    return core.assoc(base, "form", (base.form .. " > if#1"))
  else
    return base
  end
end
local function add_function_findings_for_node(findings, path, form, forms, policy, node)
  for _, offending in ipairs(function_violations(node)) do
    local base = form_for_node(forms, offending, form)
    local target = function_target(base, offending)
    table.insert(findings, finding(path, target, rule_severity(policy, "function-shape"), "function-shape", "function body is too deep; move this into a named private function", offending))
  end
  return nil
end
local function add_function_findings(findings, path, form, forms, policy, node)
  if enabled_3f(policy, "function-shape") then
    return add_function_findings_for_node(findings, path, form, forms, policy, node)
  else
    return nil
  end
end
local function form_head(node)
  if node then
    return list_head(node)
  else
    return nil
  end
end
local function evaluate_form(path, form, forms, policy)
  local node = form.node
  local head = form_head(node)
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
  if (node and function_head_3f(head)) then
    add_function_findings(findings, path, form, forms, policy, node)
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
local function collect_function_children(node, result, walker)
  for index, child in ipairs((node.children or {})) do
    do local _ = (((child.kind == "list") or (child.kind == "sequence") or (child.kind == "table")) and not quoted_child_3f(node.children, index) and walker(child, result)) end
  end
  return result
end
local function collect_function_nodes(node, result)
  if (node and (node.kind == "list") and ((list_head(node) == "fn") or (list_head(node) == "lambda") or (list_head(node) == "\206\187"))) then
    table.insert(result, node)
  else
  end
  do local _ = (node and collect_function_children(node, result, collect_function_nodes)) end
  return result
end
local function synthetic_form(path, node)
  return {line = node.open.line, col = node.open.col, ["end-line"] = node.close.line, ["end-col"] = (node.close.col + 1), form = (path .. " > function-shape"), node = node}
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
local function check_state(nodes, index, state)
  local node = nodes[index]
  local import_info = macro_import_3f(node)
  if (index > #nodes) then
    return state
  else
    return check_state(nodes, (index + 1), update_check_state(state, import_info, list_head(node)))
  end
end
local function append_evaluated_form(all, path, forms, policy, form)
  for _, f in ipairs((evaluate_form(path, form, forms, policy) or {})) do
    table.insert(all, f)
  end
  return nil
end
local function append_form_findings(all, path, forms, policy, spec_import)
  for _, f in ipairs(spec_import_finding(path, forms, policy, spec_import)) do
    table.insert(all, f)
  end
  for _, form in ipairs(forms) do
    append_evaluated_form(all, path, forms, policy, form)
  end
  return all
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
local function check_result(path, forms, policy, source, state)
  return append_synthetic_findings(append_form_findings(module_finding(path, forms, policy, (state["module-import"] and state["module-form"])), path, forms, policy, state["spec-import"]), path, forms, policy, source)
end
local check
do
  local function check0(path, forms, policy, source)
    local state = check_state(root_forms(source), 1, {["module-form"] = false, ["module-import"] = false, ["spec-import"] = false})
    return check_result(path, forms, policy, source, state)
  end
  _2amodule_2a["check"] = check0
  check = _2amodule_2a.check
end
return nil
