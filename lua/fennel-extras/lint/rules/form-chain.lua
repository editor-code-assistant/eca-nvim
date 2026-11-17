-- [nfnl] fnl/fennel-extras/lint/rules/form-chain.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.form-chain"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.form-chain"]
end
local core = require("eca.nfnl.core")
local ast = require("fennel-extras.lint.rules.ast")
local reader = require("fennel-extras.reader")
local registry = require("fennel-extras.lint.rules.registry")
local function container_3f(node)
  return (node and ((node.kind == "list") or (node.kind == "sequence") or (node.kind == "table")))
end
local function prefix_mode(prefix, mode)
  if (prefix == "'") then
    return "quoted"
  else
    if (mode == "quoted") then
      return "quoted"
    else
      if (prefix == "`") then
        return (mode + 1)
      else
        if (prefix == ",") then
          return math.max(0, (mode - 1))
        else
          return mode
        end
      end
    end
  end
end
local function child_mode(node, index, mode)
  local previous_index = ast["previous-meaningful-index"](node.children, index)
  local previous = (previous_index and node.children[previous_index])
  if (previous and (previous.kind == "prefix")) then
    return prefix_mode(previous.text, child_mode(node, previous_index, mode))
  else
    return mode
  end
end
local function meaningful_index(children, target, index)
  return ((index <= #children) and (((children[index] == target) and index) or meaningful_index(children, target, (index + 1))))
end
local body_starts = {def = 3, ["def-"] = 3, defn = 4, ["defn-"] = 4, fn = 3, lambda = 3, ["\206\187"] = 3, deftest = 3, when = 3, ["when-let"] = 3, ["if-let"] = 3, ["with-open"] = 3, testing = 3}
local function executable_children(node, mode)
  local result = {}
  for index, child in ipairs((node.children or {})) do
    local child_mode0 = child_mode(node, index, mode)
    if (container_3f(child) and (child_mode0 ~= "quoted")) then
      table.insert(result, {node = child, index = index})
    else
    end
  end
  return result
end
local function first_body_child_step(node, mode, raw_index)
  if (raw_index <= #(node.children or {})) then
    local child = node.children[raw_index]
    local child_mode0 = child_mode(node, raw_index, mode)
    return ((container_3f(child) and (child_mode0 ~= "quoted") and child) or first_body_child_step(node, mode, (raw_index + 1)))
  else
    return nil
  end
end
local function first_body_child(node, mode)
  local head = ast["list-head"](node)
  local start = body_starts[head]
  if start then
    local meaningful = ast["meaningful-children"](node)
    local candidate = meaningful[start]
    local raw_index = (candidate and meaningful_index(node.children, candidate, 1))
    return (raw_index and first_body_child_step(node, mode, raw_index))
  else
    return nil
  end
end
local function first_executable_head(node, mode)
  local children = executable_children(node, mode)
  local child = children[1]
  return (child and ast["list-head"](child.node))
end
local function contains_3f(items, target, index)
  return ((index <= #(items or {})) and ((items[index] == target) or contains_3f(items, target, (index + 1))))
end
local function root_marker_3f(value)
  return ((value == "root") or (value == "root"))
end
local function form_marker_3f(value)
  return ((value == "form") or (value == "form"))
end
local function root_chain_3f(pattern)
  return (contains_3f(pattern, "root", 1) or contains_3f(pattern, "root", 1))
end
local function match_step(subject, pattern, between, subject_index, pattern_index, matched_step_3f)
  if (pattern_index > #pattern) then
    return (subject_index > #subject)
  else
    local expected = pattern[pattern_index]
    local actual = subject[subject_index]
    local and_9_ = root_marker_3f(expected) and (subject_index == 1)
    if and_9_ then
      local _10_
      if (#pattern == 2) then
        _10_ = (subject_index + 1)
      else
        _10_ = subject_index
      end
      and_9_ = match_step(subject, pattern, between, _10_, (pattern_index + 1), true)
    end
    return (and_9_ or (form_marker_3f(expected) and actual and match_step(subject, pattern, between, (subject_index + 1), (pattern_index + 1), true)) or ((expected == actual) and match_step(subject, pattern, between, (subject_index + 1), (pattern_index + 1), true)) or (matched_step_3f and actual and contains_3f(between, actual, 1) and match_step(subject, pattern, between, (subject_index + 1), pattern_index, true)))
  end
end
local function root_chain_match_3f(chain, pattern, forms_between, root_count)
  local or_13_ = ((#pattern == 2) and root_marker_3f(pattern[1]) and form_marker_3f(pattern[2]) and ((#chain == 1) or ((#chain == 0) and ((root_count or 0) > 1))))
  if not or_13_ then
    local _14_
    if form_marker_3f(pattern[#pattern]) then
      _14_ = core.concat(chain, {"form"})
    else
      _14_ = chain
    end
    or_13_ = match_step(_14_, pattern, (forms_between or {}), 1, 1, false)
  end
  return or_13_
end
local function chain_matches_3f(chain, pattern, forms_between, root_count)
  local and_16_ = not contains_3f(chain, "not-first", 1)
  if and_16_ then
    if root_chain_3f(pattern) then
      and_16_ = root_chain_match_3f(chain, pattern, forms_between, root_count)
    else
      and_16_ = match_step(core.concat(chain, {"form"}), pattern, (forms_between or {}), 1, 1, false)
    end
  end
  return and_16_
end
local function any_chain_3f(chain, chains, forms_between, root_count)
  local found = false
  for _, pattern in ipairs((chains or {})) do
    found = (found or chain_matches_3f(chain, pattern, forms_between, root_count))
  end
  return found
end
local function subject_chain_matches_3f(subject, pattern, forms_between, root_count)
  local and_18_ = not contains_3f(subject, "not-first", 1)
  if and_18_ then
    if root_chain_3f(pattern) then
      and_18_ = root_chain_match_3f(subject, pattern, forms_between, root_count)
    else
      and_18_ = match_step(core.concat(subject, {"form"}), pattern, (forms_between or {}), 1, 1, false)
    end
  end
  return and_18_
end
local function any_subject_chain_3f(subject, chains, forms_between, root_count)
  local found = false
  for _, pattern in ipairs((chains or {})) do
    found = (found or subject_chain_matches_3f(subject, pattern, forms_between, root_count))
  end
  return found
end
local function forbidden_root_target_3f(chain, target, pattern, root_count)
  return ((root_count == 1) and (#chain == 1) and root_marker_3f(pattern[1]) and (pattern[2] == target) and form_marker_3f(pattern[3]))
end
local function forbidden_chain_3f(chain, target, pattern, forms_between, root_count)
  return (chain_matches_3f(chain, pattern, forms_between, root_count) or forbidden_root_target_3f(chain, target, pattern, root_count))
end
local function any_forbidden_chain_3f(chain, target, chains, forms_between, root_count)
  local found = false
  for _, pattern in ipairs((chains or {})) do
    found = (found or forbidden_chain_3f(chain, target, pattern, forms_between, root_count))
  end
  return found
end
local function node_form(forms, node, index)
  if (index <= #forms) then
    local form = forms[index]
    return ((form.node and (form.node.kind == node.kind) and (form.node.open.line == node.open.line) and (form.node.open.col == node.open.col) and form) or node_form(forms, node, (index + 1)))
  else
    return nil
  end
end
local function append_finding(result, path, forms, node, policy, rule)
  local existing = node_form(forms, node, 1)
  local form = (existing or {line = node.open.line, col = node.open.col, ["end-line"] = node.close.line, ["end-col"] = (node.close.col + 1), form = (path .. " > " .. (ast["list-head"](node) or "form")), node = node})
  table.insert(result, registry.finding(path, form, registry["rule-severity"](policy, rule), rule, "form is outside the allowed form chain", node))
  return result
end
local function walk_first_body(node, mode, chain, path, forms, policy, rule, result)
  local head = ast["list-head"](node)
  local next_chain = core.concat(chain, {head})
  local target_3f = (head == policy.options.target)
  local nested_chain
  do
    local child_head = first_executable_head(node, mode)
    nested_chain = (child_head and core.concat(chain, {head, child_head}))
  end
  local allowed_3f = ((policy.options["allowed-chains"] == nil) or any_chain_3f(chain, policy.options["allowed-chains"], policy.options["forms-between"], policy.options["root-count"]) or (nested_chain and any_subject_chain_3f(nested_chain, policy.options["allowed-chains"], policy.options["forms-between"], policy.options["root-count"])))
  local forbidden_3f = any_forbidden_chain_3f(chain, head, policy.options["forbidden-chains"], policy.options["forms-between"], policy.options["root-count"])
  if (target_3f and (not allowed_3f or forbidden_3f)) then
    append_finding(result, path, forms, node, policy, rule)
  else
  end
  for _, child in ipairs(executable_children(node, mode)) do
    local child_node = child.node
    local first_child = first_body_child(node, mode)
    local child_chain
    if (child_node == first_child) then
      child_chain = next_chain
    else
      child_chain = {"not-first"}
    end
    walk_first_body(child_node, child_mode(node, child.index, mode), child_chain, path, forms, policy, rule, result)
  end
  return result
end
local findings
do
  local function findings0(path, forms, policy, source, rule)
    local root, error = reader.parse(source)
    local result = {}
    if (root and not error) then
      for _, target in ipairs((policy.options.forms or {})) do
        local target_policy = core.assoc(policy, "options", core.assoc(core.assoc(policy.options, "target", target), "root-count", #ast["root-forms"](source)))
        for index, child in ipairs((root.children or {})) do
          local mode = child_mode(root, index, 0)
          if (container_3f(child) and (mode ~= "quoted")) then
            walk_first_body(child, mode, {}, path, forms, target_policy, rule, result)
          else
          end
        end
      end
    else
    end
    return result
  end
  _2amodule_2a["findings"] = findings0
  findings = _2amodule_2a.findings
end
return nil
