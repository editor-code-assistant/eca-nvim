-- [nfnl] fnl/fennel-extras/indent/comment.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.indent.comment"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.indent.comment"]
end
local first_code_token_after
do
  local function first_code_token_after0(tokens, line_number)
    local result = nil
    for _, token in ipairs(tokens) do
      result = (result or ((token.line > line_number) and not ((token.kind == "whitespace") or (token.kind == "newline") or (token.kind == "comment")) and token))
    end
    return result
  end
  _2amodule_2a["first-code-token-after"] = first_code_token_after0
  first_code_token_after = _2amodule_2a["first-code-token-after"]
end
local function code_before_comment_3f(tokens, line_number, comment_token)
  local before = false
  for _, prior in ipairs(tokens) do
    before = (before or ((prior.line == line_number) and (prior.col < comment_token.col) and not ((prior.kind == "whitespace") or (prior.kind == "newline") or (prior.kind == "comment"))))
  end
  return before
end
local function code_before_comment_on_line_3f(tokens, line_number)
  local found = false
  for _, token in ipairs(tokens) do
    found = (found or ((token.kind == "comment") and (token.line == line_number) and code_before_comment_3f(tokens, line_number, token)))
  end
  return found
end
local continuation_indent
do
  local function continuation_indent0(indent, tokens, line_number)
    if code_before_comment_on_line_3f(tokens, (line_number - 1)) then
      return (indent + 1)
    else
      return indent
    end
  end
  _2amodule_2a["continuation-indent"] = continuation_indent0
  continuation_indent = _2amodule_2a["continuation-indent"]
end
return nil
