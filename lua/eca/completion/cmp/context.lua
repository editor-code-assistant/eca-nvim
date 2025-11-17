local cmp = require("cmp")
---@module 'cmp'
---@param context eca.ChatContext
---@return cmp.CompletionItem
local function as_completion_item(context)
  ---@type lsp.CompletionItem
  ---@diagnostic disable-next-line: missing-fields
  local item = {}
  if context.type == "file" then
    item.label = string.format("@%s", vim.fn.fnamemodify(context.path, ":."))
    item.kind = cmp.lsp.CompletionItemKind.File
    item.data = {
      context_item = context,
    }
  elseif context.type == "directory" then
    item.label = string.format("@%s", vim.fn.fnamemodify(context.path, ":."))
    item.kind = cmp.lsp.CompletionItemKind.Folder
  elseif context.type == "web" then
    item.label = context.url
    item.kind = cmp.lsp.CompletionItemKind.File
  elseif context.type == "repoMap" then
    item.label = "repoMap"
    item.kind = cmp.lsp.CompletionItemKind.Module
    item.detail = "Summary view of workspace files."
  elseif context.type == "mcpResource" then
    item.label = string.format("%s:%s", context.server, context.name)
    item.kind = cmp.lsp.CompletionItemKind.Struct
    item.detail = context.description
  end
  if not item.label then
    return {}
  end
  return item
end

local source = {}

function source.new()
  return setmetatable({}, { __index = source })
end

function source:get_trigger_characters()
  return { "@" }
end

function source:get_keyword_pattern()
  return [[\k\+]]
end

function source:is_available()
  return vim.bo.filetype == "eca-input"
end

---@param params cmp.SourceCompletionApiParams
---@diagnostic disable-next-line: unused-local
function source:complete(params, callback)
  local context = require("eca.completion.context")
  local query = context.get_query(params.context.cursor_line, params.context.cursor)
  if query then
    context.get_completion_candidates(query, as_completion_item, callback)
  end
end

---@param completion_item lsp.CompletionItem
function source:resolve(completion_item, callback)
  require("eca.completion.context").resolve_completion_item(completion_item, callback)
end

---Executed after the item was selected.
---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
function source:execute(completion_item, callback)
  require("eca.completion.context").execute(completion_item, callback)
end

return source
