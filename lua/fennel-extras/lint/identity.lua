-- [nfnl] fnl/fennel-extras/lint/identity.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.identity"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.identity"]
end
local core = require("eca.nfnl.core")
local reader = require("fennel-extras.reader")
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
local function container_3f(node)
  return ((node.kind == "list") or (node.kind == "sequence") or (node.kind == "table"))
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
local function local_fn_3f(node)
  local children = meaningful_children(node)
  local value = children[3]
  local value_children = local_fn_value_children(value)
  return ("fn" == symbol_text(value_children[1]))
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
local function named_segment(node)
  local head, name = head_name(node)
  if (head and name) then
    return declaration_segment(head, name, node)
  else
    return nil
  end
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
local function quoted_child_3f(children, index)
  local previous = children[(index - 1)]
  return (previous and (previous.kind == "prefix") and ((previous.text == "'") or (previous.text == "`")))
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
local function branch_kind(parent, child_index)
  return branch_kind_for_index(meaningful_index(parent.children, child_index), #meaningful_children(parent))
end
local function list_head(node)
  local children = meaningful_children(node)
  return symbol_text(children[1])
end
local function function_parameter_index(named_fn_3f)
  if named_fn_3f then
    return 3
  else
    return 2
  end
end
local function parameter_list_3f(parent, child_index, child)
  local head = list_head(parent)
  local children = meaningful_children(parent)
  local index = meaningful_index(parent.children, child_index)
  local named_fn_3f = (((head == "fn") or (head == "lambda") or (head == "\206\187")) and symbol_text(children[2]))
  local binding_form_3f = ((head == "let") or (head == "when-let") or (head == "if-let") or (head == "each") or (head == "for") or (head == "icollect") or (head == "collect") or (head == "accumulate") or (head == "with-open"))
  local function_form_3f = ((head == "fn") or (head == "lambda") or (head == "\206\187"))
  local declaration_form_3f = ((head == "defn") or (head == "defn-") or (head == "macro"))
  return ((child.kind == "sequence") and ((binding_form_3f and (index == 2)) or (declaration_form_3f and (index == 3)) or (function_form_3f and (index == function_parameter_index(named_fn_3f)))))
end
local function append_path(path, segment)
  if segment then
    return (path .. " > " .. segment)
  else
    return path
  end
end
local function identity_form(path, node)
  local end_line, end_col = node_end(node)
  return {form = path, line = node.open.line, col = node.open.col, ["end-line"] = end_line, ["end-col"] = end_col, node = node}
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
local function node_path(node, state, top_level_3f)
  local segment = named_segment(node)
  if segment then
    return append_path(state.ancestor, segment), state
  else
    return node_path_without_segment(node, state, top_level_3f)
  end
end
local function interesting_node_3f(node, segment, head, top_level_3f, skip_identity_3f)
  return (not skip_identity_3f and (top_level_3f or segment or (head == "if") or (head == "testing") or (node.kind == "sequence") or (node.kind == "table")))
end
local function branch_node_3f(branch_segment, node, skip_identity_3f)
  return (not skip_identity_3f and branch_segment and (list_head(node) ~= "is"))
end
local function state_for_branch(state, branch_segment)
  local branch_path = append_path(state.ancestor, branch_segment)
  return {state = {forms = state.forms, ancestor = branch_path, ordinals = {}, ["top-ordinal"] = 0}, path = branch_path}
end
local function child_state_ordinals(state, segmented_3f)
  if segmented_3f then
    return {}
  else
    return state.ordinals
  end
end
local function child_state(state, final_path, segmented_3f)
  return {forms = state.forms, ancestor = final_path, ordinals = child_state_ordinals(state, segmented_3f), ["top-ordinal"] = 0}
end
local function add_identity(state, path, node)
  return core.assoc(state, "forms", core.concat(state.forms, {identity_form(path, node)}))
end
local function walk_local_fn_child(walker, node, fn_child, next_state, fn_index)
  if (container_3f(fn_child) and not quoted_child_3f(node.children, fn_index)) then
    return walker(fn_child, next_state, false, nil, false, parameter_list_3f(node, fn_index, fn_child))
  else
    return next_state
  end
end
local function walk_local_fn_children(walker, node, state)
  local next_state = state
  for fn_index, fn_child in ipairs(node.children) do
    next_state = walk_local_fn_child(walker, node, fn_child, next_state, fn_index)
  end
  return next_state
end
local function regular_child_branch(node, index)
  if (list_head(node) == "if") then
    return branch_kind(node, index)
  else
    return nil
  end
end
local function walk_regular_child(walker, node, child, state, index)
  local child_branch = regular_child_branch(node, index)
  return walker(child, state, false, child_branch, false, parameter_list_3f(node, index, child))
end
local function walk_child(walker, node, child, state, index, local_fn)
  if (local_fn and (list_head(child) == "fn")) then
    return walk_local_fn_children(walker, child, state)
  else
    return walk_regular_child(walker, node, child, state, index)
  end
end
local function walk_children(walker, node, state, final_path, segmented_3f, head, quoted_3f)
  if not quoted_3f then
    local next_state = child_state(state, final_path, segmented_3f)
    local local_fn = ((head == "local") and local_fn_3f(node))
    local current = next_state
    for index, child in ipairs(node.children) do
      if container_3f(child) then
        current = walk_child(walker, node, child, current, index, local_fn)
      else
        current = current
      end
    end
    return current
  else
    return state
  end
end
local function non_interesting_path(state, branch_path, skip_identity_3f)
  if skip_identity_3f then
    return state.ancestor
  else
    return branch_path
  end
end
local function final_path_for_node(node, state, node_state, branch_path, top_level_3f, node_interesting_3f, skip_identity_3f)
  if node_interesting_3f then
    return node_path(node, node_state, top_level_3f)
  else
    return non_interesting_path(state, branch_path, skip_identity_3f), node_state
  end
end
local function branch_info(state, branch_segment)
  if branch_segment then
    return state_for_branch(state, branch_segment)
  else
    return {state = state, path = append_path(state.ancestor, branch_segment)}
  end
end
local function add_branch_identity(branch_3f, final_state, branch_path, node)
  if branch_3f then
    return add_identity(final_state, branch_path, node)
  else
    return final_state
  end
end
local function add_node_identity(node_interesting_3f, with_branch, final_path, node)
  if node_interesting_3f then
    return add_identity(with_branch, final_path, node)
  else
    return with_branch
  end
end
local function walk_node_ordinals(node_interesting_3f, final_state, child_result)
  if node_interesting_3f then
    return final_state.ordinals
  else
    return child_result.ordinals
  end
end
local function walk_node(node, state, top_level_3f, branch_segment, quoted_3f, skip_identity_3f)
  local segment = named_segment(node)
  local head = list_head(node)
  local node_interesting_3f = interesting_node_3f(node, segment, head, top_level_3f, skip_identity_3f)
  local branch_3f = branch_node_3f(branch_segment, node, skip_identity_3f)
  local branch_info0 = branch_info(state, branch_segment)
  local node_state = branch_info0.state
  local branch_path = branch_info0.path
  local final_path, final_state = final_path_for_node(node, state, node_state, branch_path, top_level_3f, node_interesting_3f, skip_identity_3f)
  local with_branch = add_branch_identity(branch_3f, final_state, branch_path, node)
  local with_node = add_node_identity(node_interesting_3f, with_branch, final_path, node)
  local child_result = walk_children(walk_node, node, with_node, final_path, (branch_segment or node_interesting_3f), head, quoted_3f)
  return {forms = child_result.forms, ancestor = state.ancestor, ordinals = walk_node_ordinals(node_interesting_3f, final_state, child_result), ["top-ordinal"] = final_state["top-ordinal"]}
end
local function walk_root_child(root, path, state, index, child)
  local quoted_3f = quoted_child_3f(root.children, index)
  local segment = named_segment(child)
  local next_state = walk_node(child, state, true, nil, quoted_3f, false)
  if (list_head(child) == "module") then
    return core.assoc(next_state, "ancestor", append_path(path, segment))
  else
    return next_state
  end
end
local function walk_root_container_child(root, path, current, index, child)
  if container_3f(child) then
    return walk_root_child(root, path, current, index, child)
  else
    return current
  end
end
local function walk_root_state(root, path, state)
  local current = state
  for index, child in ipairs(root.children) do
    current = walk_root_container_child(root, path, current, index, child)
  end
  return current
end
local function walk_root(root, path)
  local state = {forms = {}, ancestor = path, ordinals = {}, ["top-ordinal"] = 0}
  local final_state = walk_root_state(root, path, state)
  return final_state.forms
end
local forms
do
  local function forms0(source, path)
    local root, error = reader.parse(source)
    if root then
      return walk_root(root, path)
    else
      return nil, error
    end
  end
  _2amodule_2a["forms"] = forms0
  forms = _2amodule_2a.forms
end
return nil
