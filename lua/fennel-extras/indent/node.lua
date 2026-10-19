-- [nfnl] fnl/fennel-extras/indent/node.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.indent.node"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.indent.node"]
end
local codepoint_width
do
  local function codepoint_width0(text)
    return select(2, string.gsub(text, "[^\128-\191]", ""))
  end
  _2amodule_2a["codepoint-width"] = codepoint_width0
  codepoint_width = _2amodule_2a["codepoint-width"]
end
local function leading_spaces_step(line, index)
  if ((index <= string.len(line)) and (string.sub(line, index, index) == " ")) then
    return leading_spaces_step(line, (index + 1))
  else
    return (index - 1)
  end
end
local leading_spaces
do
  local function leading_spaces0(line)
    return leading_spaces_step(line, 1)
  end
  _2amodule_2a["leading-spaces"] = leading_spaces0
  leading_spaces = _2amodule_2a["leading-spaces"]
end
local function nontrivia_child_3f(child)
  return not (child.text and ((child.kind == "comment") or (child.kind == "whitespace") or (child.kind == "newline")))
end
local function insert_nontrivia_child(children, child)
  table.insert(children, child)
  return children
end
local function append_nontrivia_child(children, child)
  if nontrivia_child_3f(child) then
    return insert_nontrivia_child(children, child)
  else
    return children
  end
end
local nontrivia_children
do
  local function nontrivia_children0(node)
    local children = {}
    for _, child in ipairs(node.children) do
      children = append_nontrivia_child(children, child)
    end
    return children
  end
  _2amodule_2a["nontrivia-children"] = nontrivia_children0
  nontrivia_children = _2amodule_2a["nontrivia-children"]
end
local child_start
do
  local function child_start0(child)
    if child.text then
      return child
    else
      return child.open
    end
  end
  _2amodule_2a["child-start"] = child_start0
  child_start = _2amodule_2a["child-start"]
end
local child_end
do
  local function child_end0(child)
    if child.text then
      return child
    else
      return child.close
    end
  end
  _2amodule_2a["child-end"] = child_end0
  child_end = _2amodule_2a["child-end"]
end
return nil
