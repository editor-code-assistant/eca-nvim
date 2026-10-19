-- [nfnl] fnl/fennel-extras/lint/rules/ast.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.ast"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.ast"]
end
local core = require("eca.nfnl.core")
local reader = require("fennel-extras.reader")
local trivia_3f
do
  local function trivia_3f0(node)
    return ((node.kind ~= "list") and (node.kind ~= "sequence") and (node.kind ~= "table") and ((node.kind == "whitespace") or (node.kind == "newline") or (node.kind == "comment")))
  end
  _2amodule_2a["trivia?"] = trivia_3f0
  trivia_3f = _2amodule_2a["trivia?"]
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
local meaningful_children
do
  local function meaningful_children0(node)
    local result = {}
    if (node and node.children) then
      collect_meaningful_children(node.children, result)
    else
    end
    return result
  end
  _2amodule_2a["meaningful-children"] = meaningful_children0
  meaningful_children = _2amodule_2a["meaningful-children"]
end
local symbol_text
do
  local function symbol_text0(node)
    if (node and (node.kind == "symbol")) then
      return node.text
    else
      return nil
    end
  end
  _2amodule_2a["symbol-text"] = symbol_text0
  symbol_text = _2amodule_2a["symbol-text"]
end
local list_head
do
  local function list_head0(node)
    local children = meaningful_children(node)
    return symbol_text(children[1])
  end
  _2amodule_2a["list-head"] = list_head0
  list_head = _2amodule_2a["list-head"]
end
local literal_text
do
  local function literal_text0(node)
    return (node and ((node.kind == "string") or (node.kind == "symbol")) and (((node.kind == "string") and string.sub(node.text, 2, (string.len(node.text) - 1))) or ((string.sub(node.text, 1, 1) == ":") and string.sub(node.text, 2)) or node.text))
  end
  _2amodule_2a["literal-text"] = literal_text0
  literal_text = _2amodule_2a["literal-text"]
end
local spec_file_3f
do
  local function spec_file_3f0(path)
    return ((string.sub(path, 1, 9) == "fnl/spec/") and true)
  end
  _2amodule_2a["spec-file?"] = spec_file_3f0
  spec_file_3f = _2amodule_2a["spec-file?"]
end
local function newline_value(text, index)
  if (string.sub(text, index, index) == "\n") then
    return 1
  else
    return 0
  end
end
local newline_count
do
  local function newline_count0(text, index, count)
    if (index > string.len(text)) then
      return count
    else
      return newline_count0(text, (index + 1), (count + newline_value(text, index)))
    end
  end
  _2amodule_2a["newline-count"] = newline_count0
  newline_count = _2amodule_2a["newline-count"]
end
local function string_token_on_line_value(token, line)
  if ((token.kind == "string") and (token.line < line) and (line <= (token.line + newline_count(token.text, 1, 0)))) then
    return token
  else
    return nil
  end
end
local function string_token_on_line_step(tokens, line, index)
  local token = tokens[index]
  if (index > #tokens) then
    return false
  else
    return (string_token_on_line_value(token, line) or string_token_on_line_step(tokens, line, (index + 1)))
  end
end
local function string_token_on_line_3f(tokens, line)
  return string_token_on_line_step(tokens, line, 1)
end
local function first_token_on_line_value(token, line)
  if ((token.line == line) and not ((token.kind == "whitespace") or (token.kind == "newline"))) then
    return token
  else
    return nil
  end
end
local function first_token_on_line_step(tokens, line, index)
  local token = tokens[index]
  if (index > #tokens) then
    return nil
  else
    return (first_token_on_line_value(token, line) or first_token_on_line_step(tokens, line, (index + 1)))
  end
end
local function first_token_on_line(tokens, line)
  return first_token_on_line_step(tokens, line, 1)
end
local function code_line_3f(tokens, line)
  local token = first_token_on_line(tokens, line)
  return ((token and (token.kind ~= "comment")) or string_token_on_line_3f(tokens, line))
end
local function code_line_value(tokens, line)
  if code_line_3f(tokens, line) then
    return 1
  else
    return 0
  end
end
local code_line_count
do
  local function code_line_count0(tokens, line, total, count)
    if (line > total) then
      return count
    else
      return code_line_count0(tokens, (line + 1), total, (count + code_line_value(tokens, line)))
    end
  end
  _2amodule_2a["code-line-count"] = code_line_count0
  code_line_count = _2amodule_2a["code-line-count"]
end
local function collect_macro_names_step(children, index, names, recurse)
  local key = symbol_text(children[index])
  local value = symbol_text(children[(index + 1)])
  if ((key == ":") and value) then
    return recurse(children, (index + 2), core.assoc(names, value, true))
  else
    return recurse(children, (index + 2), names)
  end
end
local function collect_macro_names(children, index, names)
  if (index > #children) then
    return names
  else
    return collect_macro_names_step(children, index, names, collect_macro_names)
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
local macro_import_3f
do
  local function macro_import_3f0(node)
    local children = meaningful_children(node)
    local bindings = children[2]
    local target = literal_text(children[3])
    if (list_head(node) == "import-macros") then
      return macro_import_data(bindings, target)
    else
      return nil
    end
  end
  _2amodule_2a["macro-import?"] = macro_import_3f0
  macro_import_3f = _2amodule_2a["macro-import?"]
end
local has_all_3f
do
  local function has_all_3f0(names)
    return (names.deftest and names.testing and names.is)
  end
  _2amodule_2a["has-all?"] = has_all_3f0
  has_all_3f = _2amodule_2a["has-all?"]
end
local has_module_import_3f
do
  local function has_module_import_3f0(names)
    return (names.module and names.def and names.defn and names["defn-"])
  end
  _2amodule_2a["has-module-import?"] = has_module_import_3f0
  has_module_import_3f = _2amodule_2a["has-module-import?"]
end
local previous_meaningful_child
do
  local function previous_meaningful_child0(children, previous_index)
    local previous = children[previous_index]
    if (previous_index <= 0) then
      return nil
    else
      return ((trivia_3f(previous) and previous_meaningful_child0(children, (previous_index - 1))) or previous)
    end
  end
  _2amodule_2a["previous-meaningful-child"] = previous_meaningful_child0
  previous_meaningful_child = _2amodule_2a["previous-meaningful-child"]
end
local function previous_meaningful_index_step(children, index, recurse)
  local previous_index = (index - 1)
  if trivia_3f(children[previous_index]) then
    return recurse(children, previous_index, recurse)
  else
    return previous_index
  end
end
local previous_meaningful_index
do
  local function previous_meaningful_index0(children, index)
    if (index <= 1) then
      return nil
    else
      return previous_meaningful_index_step(children, index, previous_meaningful_index0)
    end
  end
  _2amodule_2a["previous-meaningful-index"] = previous_meaningful_index0
  previous_meaningful_index = _2amodule_2a["previous-meaningful-index"]
end
local previous_meaningful
do
  local function previous_meaningful0(children, index)
    return previous_meaningful_child(children, (index - 1))
  end
  _2amodule_2a["previous-meaningful"] = previous_meaningful0
  previous_meaningful = _2amodule_2a["previous-meaningful"]
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
local root_forms
do
  local function root_forms0(source)
    local root = reader.parse(source)
    local forms = {}
    if root then
      collect_root_forms(root, forms)
    else
    end
    return forms
  end
  _2amodule_2a["root-forms"] = root_forms0
  root_forms = _2amodule_2a["root-forms"]
end
local require_node_3f
do
  local function require_node_3f0(node)
    return (list_head(node) == "require")
  end
  _2amodule_2a["require-node?"] = require_node_3f0
  require_node_3f = _2amodule_2a["require-node?"]
end
local do_branch_3f
do
  local function do_branch_3f0(node)
    local children = meaningful_children(node)
    return ((symbol_text(children[1]) == "do") and (#children >= 3))
  end
  _2amodule_2a["do-branch?"] = do_branch_3f0
  do_branch_3f = _2amodule_2a["do-branch?"]
end
local quoted_child_3f
do
  local function quoted_child_3f0(children, index)
    local previous = previous_meaningful(children, index)
    return (previous and (previous.kind == "prefix") and ((previous.text == "'") or (previous.text == "`")))
  end
  _2amodule_2a["quoted-child?"] = quoted_child_3f0
  quoted_child_3f = _2amodule_2a["quoted-child?"]
end
local function count_is_child(node, child, index, count, recurse)
  return ((child and ((child.kind == "list") or (child.kind == "sequence") or (child.kind == "table")) and not quoted_child_3f(node.children, index) and (((list_head(child) == "testing") and recurse(node, (index + 1), count)) or ((list_head(child) == "is") and recurse(node, (index + 1), (count + 1))) or recurse(node, (index + 1), (count + recurse(child, 1, 0))))) or recurse(node, (index + 1), count))
end
local count_is
do
  local function count_is0(node, index, count)
    local child = node.children[index]
    if (index > #node.children) then
      return count
    else
      return count_is_child(node, child, index, count, count_is0)
    end
  end
  _2amodule_2a["count-is"] = count_is0
  count_is = _2amodule_2a["count-is"]
end
local append_nodes
do
  local function append_nodes0(target, nodes)
    for _, node in ipairs(nodes) do
      table.insert(target, node)
    end
    return target
  end
  _2amodule_2a["append-nodes"] = append_nodes0
  append_nodes = _2amodule_2a["append-nodes"]
end
local function skip_first_form_step(index, value)
  if (index > 1) then
    return value
  else
    return nil
  end
end
local function forms_without_first(forms)
  local tbl_26_ = {}
  local i_27_ = 0
  for index, value in ipairs(forms) do
    local val_28_ = skip_first_form_step(index, value)
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function form_for_node_step(forms, node, fallback, recurse)
  local form = forms[1]
  if ((form.node == node) or (node.open and (form.line == node.open.line) and (form.col == node.open.col))) then
    return form
  else
    return recurse(forms_without_first(forms), node, fallback)
  end
end
local form_for_node
do
  local function form_for_node0(forms, node, fallback)
    if (#forms > 0) then
      return form_for_node_step(forms, node, fallback, form_for_node0)
    else
      return fallback
    end
  end
  _2amodule_2a["form-for-node"] = form_for_node0
  form_for_node = _2amodule_2a["form-for-node"]
end
local function position_before_or_at_3f(line, col, other_line, other_col)
  return ((line < other_line) or ((line == other_line) and (col <= other_col)))
end
local function position_after_or_at_3f(line, col, other_line, other_col)
  return ((line > other_line) or ((line == other_line) and (col >= other_col)))
end
local function form_contains_node_3f(form, node)
  return (position_before_or_at_3f(form.line, form.col, node.open.line, node.open.col) and position_after_or_at_3f(form["end-line"], form["end-col"], node.close.line, (node.close.col + 1)))
end
local function form_span_size(form)
  return (((form["end-line"] - form.line) * 1000000) + (form["end-col"] - form.col))
end
local function narrower_form(candidate, current)
  if (not current or (form_span_size(candidate) < form_span_size(current))) then
    return candidate
  else
    return current
  end
end
local function nearest_form_step(current, form, node)
  if form_contains_node_3f(form, node) then
    return narrower_form(form, current)
  else
    return current
  end
end
local nearest_form
do
  local function nearest_form0(forms, node)
    local current = nil
    for _, form in ipairs(forms) do
      current = nearest_form_step(current, form, node)
    end
    return current
  end
  _2amodule_2a["nearest-form"] = nearest_form0
  nearest_form = _2amodule_2a["nearest-form"]
end
return nil
