-- [nfnl] fnl/fennel-extras/lint/identity/naming.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.identity.naming"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.identity.naming"]
end
local core = require("eca.nfnl.core")
local function trivia_3f(node)
  return ((node.kind ~= "list") and (node.kind ~= "sequence") and (node.kind ~= "table") and ((node.kind == "whitespace") or (node.kind == "newline") or (node.kind == "comment") or (node.kind == "tab") or (node.kind == "cr")))
end
local function meaningful_child(child)
  if not trivia_3f(child) then
    return child
  else
    return nil
  end
end
local container_3f
do
  local function container_3f0(node)
    return ((node.kind == "list") or (node.kind == "sequence") or (node.kind == "table"))
  end
  _2amodule_2a["container?"] = container_3f0
  container_3f = _2amodule_2a["container?"]
end
local function meaningful_children(node)
  local tbl_26_ = {}
  local i_27_ = 0
  for _, child in ipairs(node.children) do
    local val_28_ = meaningful_child(child)
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function symbol_text(node)
  if (node and (node.kind == "symbol")) then
    return node.text
  else
    return nil
  end
end
local function head_name(node)
  local children = meaningful_children(node)
  local head = symbol_text(children[1])
  local name = symbol_text(children[2])
  if (head and name) then
    return head, name
  else
    return head, nil
  end
end
local function named_declaration_3f(head)
  return ((head == "module") or (head == "def") or (head == "defn") or (head == "defn-") or (head == "deftest") or (head == "fn"))
end
local function local_fn_value_children(value)
  if (value and (value.kind == "list")) then
    return meaningful_children(value)
  else
    return {}
  end
end
local local_fn_3f
do
  local function local_fn_3f0(node)
    local children = meaningful_children(node)
    local value = children[3]
    local value_children = local_fn_value_children(value)
    return ("fn" == symbol_text(value_children[1]))
  end
  _2amodule_2a["local-fn?"] = local_fn_3f0
  local_fn_3f = _2amodule_2a["local-fn?"]
end
local function local_named_segment(head, name, node)
  if ((head == "local") and local_fn_3f(node)) then
    return ("local:" .. name)
  else
    return nil
  end
end
local function declaration_segment(head, name, node)
  if named_declaration_3f(head) then
    return (head .. ":" .. name)
  else
    return local_named_segment(head, name, node)
  end
end
local named_segment
do
  local function named_segment0(node)
    local head, name = head_name(node)
    if (head and name) then
      return declaration_segment(head, name, node)
    else
      return nil
    end
  end
  _2amodule_2a["named-segment"] = named_segment0
  named_segment = _2amodule_2a["named-segment"]
end
local function anonymous_list_kind(node)
  local children = meaningful_children(node)
  return (symbol_text(children[1]) or "list")
end
local function anonymous_container_kind(node)
  local case_9_ = node.kind
  if (case_9_ == "sequence") then
    return "sequence"
  elseif (case_9_ == "table") then
    return "table"
  else
    local _ = case_9_
    return "form"
  end
end
local function anonymous_kind(node)
  if (node.kind == "list") then
    return anonymous_list_kind(node)
  else
    return anonymous_container_kind(node)
  end
end
local function node_end(node)
  return node.close.line, (node.close.col + 1)
end
local quoted_child_3f
do
  local function quoted_child_3f0(children, index)
    local previous = children[(index - 1)]
    return (previous and (previous.kind == "prefix") and ((previous.text == "'") or (previous.text == "`")))
  end
  _2amodule_2a["quoted-child?"] = quoted_child_3f0
  quoted_child_3f = _2amodule_2a["quoted-child?"]
end
local function increment_meaningful(ordinal, child)
  if not trivia_3f(child) then
    return (ordinal + 1)
  else
    return ordinal
  end
end
local function advance_meaningful_index(ordinal, child_index, index, child)
  if (index <= child_index) then
    return increment_meaningful(ordinal, child)
  else
    return ordinal
  end
end
local function index_result(child_index, index, ordinal, result)
  if (index == child_index) then
    return ordinal
  else
    return result
  end
end
local function meaningful_index_state(state, child_index, index, child)
  local ordinal = advance_meaningful_index(state.ordinal, child_index, index, child)
  return {ordinal = ordinal, result = index_result(child_index, index, ordinal, state.result)}
end
local function meaningful_index_result(children, child_index)
  local state = {ordinal = 0, result = nil}
  for index, child in ipairs(children) do
    state = meaningful_index_state(state, child_index, index, child)
  end
  return state
end
local function meaningful_index(children, child_index)
  local result = meaningful_index_result(children, child_index)
  return result.result
end
local function numbered_then_kind(branch_index)
  if ((branch_index > 3) and ((branch_index % 2) == 1)) then
    return ("then#" .. (1 + ((branch_index - 3) / 2)))
  else
    return nil
  end
end
local function branch_kind_after_then(branch_index, child_count)
  if ((child_count > 3) and (branch_index == child_count) and ((branch_index % 2) == 0)) then
    return "else"
  else
    return numbered_then_kind(branch_index)
  end
end
local function branch_kind_for_index(branch_index, child_count)
  if (branch_index == 3) then
    return "then"
  else
    return branch_kind_after_then(branch_index, child_count)
  end
end
local branch_kind
do
  local function branch_kind0(parent, child_index)
    return branch_kind_for_index(meaningful_index(parent.children, child_index), #meaningful_children(parent))
  end
  _2amodule_2a["branch-kind"] = branch_kind0
  branch_kind = _2amodule_2a["branch-kind"]
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
local function function_parameter_index(named_fn_3f)
  if named_fn_3f then
    return 3
  else
    return 2
  end
end
local parameter_list_3f
do
  local function parameter_list_3f0(parent, child_index, child)
    local head = list_head(parent)
    local children = meaningful_children(parent)
    local index = meaningful_index(parent.children, child_index)
    local named_fn_3f = (((head == "fn") or (head == "lambda") or (head == "\206\187")) and symbol_text(children[2]))
    local binding_form_3f = ((head == "let") or (head == "when-let") or (head == "if-let") or (head == "each") or (head == "for") or (head == "icollect") or (head == "collect") or (head == "accumulate") or (head == "with-open"))
    local function_form_3f = ((head == "fn") or (head == "lambda") or (head == "\206\187"))
    local declaration_form_3f = ((head == "defn") or (head == "defn-") or (head == "macro"))
    return ((child.kind == "sequence") and ((binding_form_3f and (index == 2)) or (declaration_form_3f and (index == 3)) or (function_form_3f and (index == function_parameter_index(named_fn_3f)))))
  end
  _2amodule_2a["parameter-list?"] = parameter_list_3f0
  parameter_list_3f = _2amodule_2a["parameter-list?"]
end
local append_path
do
  local function append_path0(path, segment)
    if segment then
      return (path .. " > " .. segment)
    else
      return path
    end
  end
  _2amodule_2a["append-path"] = append_path0
  append_path = _2amodule_2a["append-path"]
end
local identity_form
do
  local function identity_form0(path, node)
    local end_line, end_col = node_end(node)
    return {form = path, line = node.open.line, col = node.open.col, ["end-line"] = end_line, ["end-col"] = end_col, node = node}
  end
  _2amodule_2a["identity-form"] = identity_form0
  identity_form = _2amodule_2a["identity-form"]
end
local function top_level_path(state)
  local ordinal = (state["top-ordinal"] + 1)
  return append_path(state.ancestor, ("top#" .. ordinal)), core.assoc(state, "top-ordinal", ordinal)
end
local function anonymous_path(node, state)
  local kind = anonymous_kind(node)
  local ordinal = ((state.ordinals[kind] or 0) + 1)
  return append_path(state.ancestor, (kind .. "#" .. ordinal)), core.assoc(state, "ordinals", core.assoc(state.ordinals, kind, ordinal))
end
local function node_path_without_segment(node, state, top_level_3f)
  if top_level_3f then
    return top_level_path(state)
  else
    return anonymous_path(node, state)
  end
end
local node_path
do
  local function node_path0(node, state, top_level_3f)
    local segment = named_segment(node)
    if segment then
      return append_path(state.ancestor, segment), state
    else
      return node_path_without_segment(node, state, top_level_3f)
    end
  end
  _2amodule_2a["node-path"] = node_path0
  node_path = _2amodule_2a["node-path"]
end
return nil
