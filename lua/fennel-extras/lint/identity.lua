-- [nfnl] fnl/fennel-extras/lint/identity.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.identity"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.identity"]
end
local core = require("eca.nfnl.core")
local reader = require("fennel-extras.reader")
local naming = require("fennel-extras.lint.identity.naming")
local function interesting_node_3f(node, segment, head, top_level_3f, skip_identity_3f)
  return (not skip_identity_3f and (top_level_3f or segment or (head == "if") or (head == "testing") or (node.kind == "sequence") or (node.kind == "table")))
end
local function branch_node_3f(branch_segment, node, skip_identity_3f)
  return (not skip_identity_3f and branch_segment and (naming["list-head"](node) ~= "is"))
end
local function state_for_branch(state, branch_segment)
  local branch_path = naming["append-path"](state.ancestor, branch_segment)
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
  return core.assoc(state, "forms", core.concat(state.forms, {naming["identity-form"](path, node)}))
end
local function walk_local_fn_child(walker, node, fn_child, next_state, fn_index)
  if (naming["container?"](fn_child) and not naming["quoted-child?"](node.children, fn_index)) then
    return walker(fn_child, next_state, false, nil, false, naming["parameter-list?"](node, fn_index, fn_child))
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
  if (naming["list-head"](node) == "if") then
    return naming["branch-kind"](node, index)
  else
    return nil
  end
end
local function walk_regular_child(walker, node, child, state, index)
  local child_branch = regular_child_branch(node, index)
  return walker(child, state, false, child_branch, false, naming["parameter-list?"](node, index, child))
end
local function walk_child(walker, node, child, state, index, local_fn)
  if (local_fn and (naming["list-head"](child) == "fn")) then
    return walk_local_fn_children(walker, child, state)
  else
    return walk_regular_child(walker, node, child, state, index)
  end
end
local function walk_child_step(walker, node, local_fn, current, index, child)
  if naming["container?"](child) then
    return walk_child(walker, node, child, current, index, local_fn)
  else
    return current
  end
end
local function walk_children_step(walker, node, state, final_path, segmented_3f, head)
  local next_state = child_state(state, final_path, segmented_3f)
  local local_fn = ((head == "local") and naming["local-fn?"](node))
  local current = next_state
  for index, child in ipairs(node.children) do
    current = walk_child_step(walker, node, local_fn, current, index, child)
  end
  return current
end
local function walk_children(walker, node, state, final_path, segmented_3f, head, quoted_3f)
  if not quoted_3f then
    return walk_children_step(walker, node, state, final_path, segmented_3f, head)
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
    return naming["node-path"](node, node_state, top_level_3f)
  else
    return non_interesting_path(state, branch_path, skip_identity_3f), node_state
  end
end
local function branch_info(state, branch_segment)
  if branch_segment then
    return state_for_branch(state, branch_segment)
  else
    return {state = state, path = naming["append-path"](state.ancestor, branch_segment)}
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
  local segment = naming["named-segment"](node)
  local head = naming["list-head"](node)
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
  local quoted_3f = naming["quoted-child?"](root.children, index)
  local segment = naming["named-segment"](child)
  local next_state = walk_node(child, state, true, nil, quoted_3f, false)
  if (naming["list-head"](child) == "module") then
    return core.assoc(next_state, "ancestor", naming["append-path"](path, segment))
  else
    return next_state
  end
end
local function walk_root_container_child(root, path, current, index, child)
  if naming["container?"](child) then
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
