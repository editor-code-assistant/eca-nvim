-- [nfnl] fnl/fennel-extras/reader.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.reader"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.reader"]
end
local function token(kind, text, line, col)
  return {kind = kind, text = text, line = line, col = col}
end
local function fail(message, line, col)
  return nil, {message = message, line = line, col = col}
end
local function classify(c)
  if (c == "\"") then
    return "string"
  elseif (c == ";") then
    return "comment"
  elseif (c == " ") then
    return "whitespace"
  elseif (c == "\n") then
    return "newline"
  elseif (c == "(") then
    return "open"
  elseif (c == ")") then
    return "close"
  elseif (c == "[") then
    return "open"
  elseif (c == "]") then
    return "close"
  elseif (c == "{") then
    return "open"
  elseif (c == "}") then
    return "close"
  elseif (c == "`") then
    return "prefix"
  elseif (c == "'") then
    return "prefix"
  elseif (c == ",") then
    return "prefix"
  elseif (c == "#") then
    return "prefix"
  elseif (c == "\t") then
    return "tab"
  elseif (c == "\r") then
    return "cr"
  elseif (c == "@") then
    return "at"
  else
    local _ = c
    return "atom"
  end
end
local function close_string(j)
  return true, (j + 1)
end
local function scan_string(source, i)
  local n = string.len(source)
  local j = (i + 1)
  local closed = false
  local error = nil
  while ((j <= n) and not closed and not error) do
    local c = string.sub(source, j, j)
    if (c == "\\") then
      if (j == n) then
        error = {message = "unterminated string", line = nil, col = nil}
      else
        if (string.sub(source, (j + 1), (j + 1)) == "\r") then
          error = {message = "carriage return is not allowed", offset = (j + 1)}
        else
          j = (j + 2)
        end
      end
    else
      if (c == "\"") then
        local new_closed, new_j = close_string(j)
        closed = new_closed
        j = new_j
      else
        if (c == "\r") then
          error = {message = "carriage return is not allowed", offset = j}
        else
          j = (j + 1)
        end
      end
    end
  end
  if error then
    return nil, error
  else
    if closed then
      return (j - 1)
    else
      return nil, {message = "unterminated string", offset = i}
    end
  end
end
local function scan_comment(source, i)
  local n = string.len(source)
  local j = i
  while ((j <= n) and not (string.sub(source, j, j) == "\n")) do
    j = (j + 1)
  end
  return (j - 1)
end
local function scan_whitespace(source, i)
  local n = string.len(source)
  local j = i
  while ((j <= n) and (string.sub(source, j, j) == " ")) do
    j = (j + 1)
  end
  return (j - 1)
end
local function scan_atom(source, i)
  local n = string.len(source)
  local j = i
  while ((j <= n) and (classify(string.sub(source, j, j)) == "atom")) do
    j = (j + 1)
  end
  return (j - 1)
end
local function number_3f(text)
  return (string.match(text, "^[0-9][0-9_]*$") or string.match(text, "^%-[0-9][0-9_]*$") or string.match(text, "^[0-9][0-9_]*%.[0-9][0-9_]*$") or string.match(text, "^%-[0-9][0-9_]*%.[0-9][0-9_]*$") or string.match(text, "^[0-9][0-9_]*%.[0-9][0-9_]*[eE][0-9][0-9_]*$") or string.match(text, "^%-[0-9][0-9_]*%.[0-9][0-9_]*[eE][0-9][0-9_]*$") or string.match(text, "^[0-9][0-9_]*%.[0-9][0-9_]*[eE][+-][0-9][0-9_]*$") or string.match(text, "^%-[0-9][0-9_]*%.[0-9][0-9_]*[eE][+-][0-9][0-9_]*$") or string.match(text, "^0[xX][0-9A-Fa-f][0-9A-Fa-f_]*$") or string.match(text, "^%-0[xX][0-9A-Fa-f][0-9A-Fa-f_]*$") or string.match(text, "^[0-9][0-9_]*[eE][0-9][0-9_]*$") or string.match(text, "^%-[0-9][0-9_]*[eE][0-9][0-9_]*$") or string.match(text, "^[0-9][0-9_]*[eE][+-][0-9][0-9_]*$") or string.match(text, "^%-[0-9][0-9_]*[eE][+-][0-9][0-9_]*$"))
end
local function advance_line(line, col)
  return (line + 1), 1
end
local function advance_position(text, line, col)
  local j = 1
  local current_line = line
  local current_col = col
  do
    local n = string.len(text)
    while (j <= n) do
      if (string.sub(text, j, j) == "\n") then
        local new_line, new_col = advance_line(current_line, current_col)
        current_line = new_line
        current_col = new_col
      else
        current_col = (current_col + 1)
      end
      j = (j + 1)
    end
  end
  return current_line, current_col
end
local function next_token(source, i, line, col)
  local shebang_3f = ((i == 1) and (string.sub(source, 1, 1) == "#") and (string.sub(source, 2, 2) == "!"))
  local kind
  if shebang_3f then
    kind = "comment"
  else
    kind = classify(string.sub(source, i, i))
  end
  if (kind == "string") then
    local _end, result = scan_string(source, i)
    if _end then
      return token("string", string.sub(source, i, _end), line, col), (_end + 1)
    else
      return nil, {message = result.message, line = line, col = col}
    end
  elseif (kind == "comment") then
    local _end = scan_comment(source, i)
    return token("comment", string.sub(source, i, _end), line, col), (_end + 1)
  elseif (kind == "whitespace") then
    local _end = scan_whitespace(source, i)
    return token("whitespace", string.sub(source, i, _end), line, col), (_end + 1)
  elseif (kind == "atom") then
    local _end = scan_atom(source, i)
    local text = string.sub(source, i, _end)
    local _12_
    if number_3f(text) then
      _12_ = "number"
    else
      _12_ = "symbol"
    end
    return token(_12_, text, line, col), (_end + 1)
  elseif (kind == "open") then
    return token("open", string.sub(source, i, i), line, col), (i + 1)
  elseif (kind == "close") then
    return token("close", string.sub(source, i, i), line, col), (i + 1)
  elseif (kind == "newline") then
    return token("newline", "\n", line, col), (i + 1)
  elseif (kind == "tab") then
    return fail("tab is not allowed", line, col)
  elseif (kind == "cr") then
    return fail("carriage return is not allowed", line, col)
  elseif (kind == "at") then
    return fail("invalid at reader syntax", line, col)
  elseif (kind == "prefix") then
    if ((string.sub(source, i, i) == ",") and (string.sub(source, (i + 1), (i + 1)) == "@")) then
      return fail("invalid comma-at reader syntax", line, col)
    else
      return token("prefix", string.sub(source, i, i), line, col), (i + 1)
    end
  else
    return nil
  end
end
local function push_open_node(node, stack, tok)
  local child
  local _17_
  do
    local case_16_ = tok.text
    if (case_16_ == "(") then
      _17_ = "list"
    elseif (case_16_ == "[") then
      _17_ = "sequence"
    elseif (case_16_ == "{") then
      _17_ = "table"
    else
      _17_ = nil
    end
  end
  child = {kind = _17_, open = tok, children = {}}
  table.insert(node.children, child)
  return table.insert(stack, {node = child, open = tok})
end
local function advance_token(tokens, tok, line, col)
  table.insert(tokens, tok)
  return advance_position(tok.text, line, col)
end
local function close_matching_node(stack, tok)
  local top = stack[#stack]
  top.node.close = tok
  return table.remove(stack)
end
local tokenize
do
  local function tokenize0(source)
    local tokens = {}
    local n = string.len(source)
    local i = 1
    local line = 1
    local col = 1
    local error = nil
    while ((i <= n) and not error) do
      local old_i = i
      local tok, end_or_error = next_token(source, i, line, col)
      if tok then
        if (end_or_error <= old_i) then
          error = {message = "tokenizer made no progress", line = line, col = col}
        else
          local new_line, new_col = advance_token(tokens, tok, line, col)
          line = new_line
          col = new_col
          i = end_or_error
        end
      else
        error = end_or_error
      end
    end
    if error then
      return nil, error
    else
      return tokens
    end
  end
  _2amodule_2a["tokenize"] = tokenize0
  tokenize = _2amodule_2a.tokenize
end
local function matching_close(open)
  if (open == "(") then
    return ")"
  elseif (open == "[") then
    return "]"
  elseif (open == "{") then
    return "}"
  else
    return nil
  end
end
local function node_kind(open)
  if (open == "(") then
    return "list"
  elseif (open == "[") then
    return "sequence"
  elseif (open == "{") then
    return "table"
  else
    return nil
  end
end
local parse
do
  local function parse0(source)
    local tokens, error = tokenize(source)
    if error then
      return nil, error
    else
      local root = {kind = "root", children = {}}
      local stack = {{node = root, open = nil}}
      local failure = nil
      for _, tok in ipairs(tokens) do
        if not failure then
          local frame = stack[#stack]
          local node = frame.node
          if (tok.kind == "open") then
            push_open_node(node, stack, tok)
          else
            if (tok.kind == "close") then
              if (#stack == 1) then
                failure = {message = "unexpected closing delimiter", line = tok.line, col = tok.col}
              else
                local top = stack[#stack]
                if (tok.text == matching_close(top.open.text)) then
                  close_matching_node(stack, tok)
                else
                  failure = {message = "mismatched closing delimiter", line = tok.line, col = tok.col}
                end
              end
            else
              table.insert(node.children, tok)
            end
          end
        else
        end
      end
      if failure then
        return nil, failure
      else
        if (#stack > 1) then
          local top = stack[#stack]
          return fail("missing closing delimiter", top.open.line, top.open.col)
        else
          return root
        end
      end
    end
  end
  _2amodule_2a["parse"] = parse0
  parse = _2amodule_2a.parse
end
local function stringify_container(stringify, node, buffer)
  table.insert(buffer, node.open.text)
  for _, child in ipairs(node.children) do
    stringify(child, buffer)
  end
  return table.insert(buffer, node.close.text)
end
local function stringify(node, buffer)
  if (node.kind == "root") then
    for _, child in ipairs(node.children) do
      stringify(child, buffer)
    end
    return nil
  else
    if node.text then
      return table.insert(buffer, node.text)
    else
      return stringify_container(stringify, node, buffer)
    end
  end
end
local to_string
do
  local function to_string0(node)
    local buffer = {}
    stringify(node, buffer)
    return table.concat(buffer)
  end
  _2amodule_2a["to-string"] = to_string0
  to_string = _2amodule_2a["to-string"]
end
return nil
