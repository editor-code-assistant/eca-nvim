local M = {}

---@param s string
---@return string?
function M.get_query(s)
  return s:match("^>?%s*/(.*)$") -- Cursor character followed by slash
end

---@param query string
---@param as_completion_item fun(eca.ChatCommand): lsp.CompletionItem
---@param callback fun(resp: {items: lsp.CompletionItem[], isIncomplete?: boolean, is_incomplete_forward?: boolean, is_incomplete_backward?: boolean})
function M.get_completion_candidates(query, as_completion_item, callback)
  local eca = require("eca")
  local chat = eca.get()

  if not chat or not chat.mediator then
    Logger.notify("No active ECA sidebar", vim.log.levels.WARN)
    return
  end

  chat.mediator:send("chat/queryCommands", {
      chatId = chat.mediator:id(),
      query = query,
    },
    function(err, result)
      if err then
        ---@diagnostic disable-next-line: missing-fields
        callback({ items = {} })
      end

      if result and result.commands then
        local items = vim.iter(result.commands):map(as_completion_item):totable()
        callback({ items = items })
      else
        callback({ items = {} })
      end
    end)
end

return M
