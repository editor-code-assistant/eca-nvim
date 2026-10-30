-- [nfnl] fnl/fennel-extras/indent/bindings.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.indent.bindings"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.indent.bindings"]
end
local function trivia_3f(child)
  return (child and ((child.kind == "comment") or (child.kind == "whitespace") or (child.kind == "newline")))
end
local function append_child(result, child)
  table.insert(result, child)
  return result
end
local function meaningful_child_result(result, child)
  if trivia_3f(child) then
    return result
  else
    return append_child(result, child)
  end
end
local meaningful_children
do
  local function meaningful_children0(node)
    local result = {}
    for _, child in ipairs((node.children or {})) do
      result = meaningful_child_result(result, child)
    end
    return result
  end
  _2amodule_2a["meaningful-children"] = meaningful_children0
  meaningful_children = _2amodule_2a["meaningful-children"]
end
local function append_pair(result, pair)
  table.insert(result, pair)
  return result
end
local function pair_record(name, value_end, previous_end)
  return {name = name, ["value-end"] = value_end, ["previous-end"] = previous_end}
end
local function previous_end(pair)
  return (pair and pair["value-end"])
end
local function prefix_offset(value)
  if (value.kind == "prefix") then
    return 1
  else
    return 0
  end
end
local function binding_value_end(value_index, value)
  return (value_index + prefix_offset(value))
end
local function pair_records_present_step(recur, items, index, result)
  local value_index = (index + 1)
  local value = items[value_index]
  local value_end = binding_value_end(value_index, value)
  local name = items[index]
  local previous_pair = result[#result]
  local pair = pair_record(name, items[value_end], previous_end(previous_pair))
  local next_result = append_pair(result, pair)
  if name then
    return recur(items, (value_end + 1), next_result)
  else
    return {}
  end
end
local function pair_records_step(recur, items, index, result)
  if items[(index + 1)] then
    return pair_records_present_step(recur, items, index, result)
  else
    return {}
  end
end
local function pair_records(items, index, result)
  if (index > #items) then
    return result
  else
    return pair_records_step(pair_records, items, index, result)
  end
end
local pairs
do
  local function pairs0(node)
    return pair_records(meaningful_children(node), 1, {})
  end
  _2amodule_2a["pairs"] = pairs0
  pairs = _2amodule_2a.pairs
end
return nil
