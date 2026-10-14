-- [nfnl] fnl/fennel-extras/format.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.format"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.format"]
end
local indent = require("fennel-extras.indent")
local function split_lines(source)
  local lines = {}
  local start = 1
  local at = string.find(source, "\n", start, true)
  while at do
    table.insert(lines, string.sub(source, start, (at - 1)))
    start = (at + 1)
    at = string.find(source, "\n", start, true)
  end
  table.insert(lines, string.sub(source, start))
  return lines
end
local function leading_spaces(line)
  return string.len(string.match(line, "^ *"))
end
local function spaces_only_3f(line)
  return (line == string.rep(" ", string.len(line)))
end
local indent_only_3f
do
  local function indent_only_3f0(before, after)
    local left = split_lines(before)
    local right = split_lines(after)
    if (#left ~= #right) then
      return false
    else
      local same = true
      for i, line in ipairs(left) do
        local other = right[i]
        local body = string.sub(line, (leading_spaces(line) + 1))
        local spaces = string.sub(other, 1, leading_spaces(other))
        if not ((line == other) or (other == (spaces .. body)) or ((other == "") and spaces_only_3f(line))) then
          same = false
        else
        end
      end
      return same
    end
  end
  _2amodule_2a["indent-only?"] = indent_only_3f0
  indent_only_3f = _2amodule_2a["indent-only?"]
end
local function ignored_3f(key)
  return ((key == "filename") or (key == "line") or (key == "col") or (key == "bytestart") or (key == "byteend") or (key == "endline") or (key == "endcol") or (key == "closer") or (key == "filename") or (key == "line") or (key == "col") or (key == "bytestart") or (key == "byteend") or (key == "endline") or (key == "endcol") or (key == "closer"))
end
local function equal_value(parser, a, b)
  if (type(a) ~= type(b)) then
    return false
  else
    if (type(a) == "table") then
      if (parser["sym?"](a) or parser["comment?"](a)) then
        return (tostring(a) == tostring(b))
      else
        local same = true
        for key, value in pairs(a) do
          if not ignored_3f(key) then
            if not equal_value(parser, value, b[key]) then
              same = false
            else
            end
          else
          end
        end
        return same
      end
    else
      return (a == b)
    end
  end
end
local function parse_all(parser, source)
  local iterator = parser.parser(source, "fennel-extras", {comments = true})
  local forms = {}
  local done = false
  while not done do
    local ok, form = iterator()
    if ok then
      table.insert(forms, form)
    else
      done = true
    end
  end
  return forms
end
local ast_equal_3f
do
  local function ast_equal_3f0(parser, a, b)
    local ok, result
    local function _9_()
      local left = parse_all(parser, a)
      local right = parse_all(parser, b)
      if (#left ~= #right) then
        return false
      else
        local same = true
        for i, form in ipairs(left) do
          if not equal_value(parser, form, right[i]) then
            same = false
          else
          end
        end
        return same
      end
    end
    ok, result = pcall(_9_)
    return (ok and result)
  end
  _2amodule_2a["ast-equal?"] = ast_equal_3f0
  ast_equal_3f = _2amodule_2a["ast-equal?"]
end
local format_string
do
  local function format_string0(source, opts)
    local config = (opts.config or {})
    local parser = opts.parser
    local out, error = indent.reindent(source, config)
    if error then
      return nil, error
    else
      if not indent_only_3f(source, out) then
        return nil, {message = "formatter changed more than indentation"}
      else
        if (parser and not ast_equal_3f(parser, source, out)) then
          return nil, {message = "formatter changed the parsed form"}
        else
          return out
        end
      end
    end
  end
  _2amodule_2a["format-string"] = format_string0
  format_string = _2amodule_2a["format-string"]
end
return nil
