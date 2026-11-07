-- [nfnl] fnl/fennel-extras/lint/rules/traverse.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.traverse"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.traverse"]
end
local core = require("eca.nfnl.core")
local ast = require("fennel-extras.lint.rules.ast")
local reader = require("fennel-extras.reader")
local previous_meaningful_index = ast["previous-meaningful-index"]
local function mutation_mode_for_prefix(prefix, mode)
  return (((prefix == "'") and "quoted") or ((mode == "quoted") and "quoted") or ((prefix == "`") and (mode + 1)) or ((prefix == ",") and math.max(0, (mode - 1))) or mode)
end
local function mutation_mode_for_child(node, index, mode)
  local previous_index = previous_meaningful_index(node.children, index)
  local previous = (previous_index and node.children[previous_index])
  if (previous and (previous.kind == "prefix")) then
    return mutation_mode_for_prefix(previous.text, mutation_mode_for_child(node, previous_index, mode))
  else
    return mode
  end
end
local function append_executable_child(node, result, index, child, mode, recurse, predicate)
  local child_mode = mutation_mode_for_child(node, index, mode)
  if (((child.kind == "list") or (child.kind == "sequence") or (child.kind == "table")) and (child_mode ~= "quoted")) then
    return recurse(child, result, child_mode, predicate)
  else
    return result
  end
end
local function collect_executable_children(node, result, mode, recurse, predicate)
  local state = result
  for index, child in ipairs((node.children or {})) do
    state = append_executable_child(node, state, index, child, mode, recurse, predicate)
  end
  return state
end
local function executable_node_result(node, result, mode, predicate)
  if ((mode == 0) and predicate(node)) then
    return core.concat(result, {node})
  else
    return result
  end
end
local function collect_executable_nodes(node, result, mode, predicate)
  return collect_executable_children(node, executable_node_result(node, result, mode, predicate), mode, collect_executable_nodes, predicate)
end
local executable_nodes
do
  local function executable_nodes0(source, predicate)
    local root = reader.parse(source)
    if root then
      return collect_executable_nodes(root, {}, 0, predicate)
    else
      return {}
    end
  end
  _2amodule_2a["executable-nodes"] = executable_nodes0
  executable_nodes = _2amodule_2a["executable-nodes"]
end
return nil
