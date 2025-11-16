local M = {}

---@param cursor_line string
---@param cursor_position lsp.Position|vim.Position
---@return string
function M.get_query(cursor_line, cursor_position)
  local before_cursor = cursor_line:sub(1, cursor_position.col)
  ---@type string[]
  local matches = {}
  local it = before_cursor:gmatch("@([%w%./_\\%-~]*)")
  for match in it do
    table.insert(matches, match)
  end
  return matches[#matches]
end

---@param query string
---@param as_completion_item fun(eca.ChatContext): lsp.CompletionItem
---@param callback fun(resp: {items: lsp.CompletionItem[], isIncomplete?: boolean, is_incomplete_forward?: boolean, is_incomplete_backward?: boolean})
function M.get_completion_candidates(query, as_completion_item, callback)
  local server = require("eca").server
  server:send_request("chat/queryContext", { query = query }, function(err, result)
    if err then
      callback({ items = {} })
      return
    end

    if result and result.contexts then
      local items = vim.iter(result.contexts):map(as_completion_item):totable()
      callback({ items = items })
    else
      callback({ items = {} })
    end
  end)
end

--- Taken from https://github.com/hrsh7th/cmp-path/blob/9a16c8e5d0be845f1d1b64a0331b155a9fe6db4d/lua/cmp_path/init.lua
--- Show a small preview of file context items in the documentation window.
---@param context_item eca.ChatContext
---@param max_lines integer
---@return lsp.MarkupContent
local function documentation(context_item, max_lines)
  if context_item and context_item.path then
    local filename = context_item.path
    local binary = assert(io.open(context_item.path, "rb"))
    local first_kb = binary:read(1024)
    if first_kb and first_kb:find("\0") then
      return { kind = vim.lsp.protocol.MarkupKind.PlainText, value = "binary file" }
    end

    local content = io.lines(context_item.path)

    --- Try to support line ranges, I don't know if this works or not yet
    local start = context_item.lines_range and context_item.lines_range.start or 1
    local last = context_item.lines_range and context_item.lines_range["end"] or max_lines
    local skip_lines = start - 1
    local take_lines = last - start
    local contents = vim.iter(content):skip(skip_lines):take(take_lines):totable()

    local filetype = vim.filetype.match({ filename = filename })
    if not filetype then
      return { kind = vim.lsp.protocol.MarkupKind.PlainText, value = table.concat(contents, "\n") }
    end

    table.insert(contents, 1, "```" .. filetype)
    table.insert(contents, "```")
    return { kind = vim.lsp.protocol.MarkupKind.Markdown, value = table.concat(contents, "\n") }
  end
  return {}
end

---@param completion_item lsp.CompletionItem
---@param callback fun(any)
function M.resolve_completion_item(completion_item, callback)
  if completion_item.data then
    local context_item = completion_item.data.context_item
    ---@cast context_item eca.ChatContext
    if context_item.type == "file" then
      completion_item.documentation = documentation(context_item, 20)
    end
    vim.api.nvim_exec_autocmds("User", {
      pattern = { "EcaChatContextUpdated" },
      data = completion_item.data.context_item,
    })
    callback(completion_item)
  end
end
return M
