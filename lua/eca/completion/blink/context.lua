---@module 'blink.cmp'
---@class blink.cmp.Source
local source = {}

-- `opts` table comes from `sources.providers.your_provider.opts`
-- You may also accept a second argument `config`, to get the full
-- `sources.providers.your_provider` table
function source.new(opts)
  -- vim.validate("your-source.opts.some_option", opts.some_option, { "string" })
  -- vim.validate("your-source.opts.optional_option", opts.optional_option, { "string" }, true)

  local self = setmetatable({}, { __index = source })
  self.opts = opts
  return self
end

function source:enabled()
  return vim.bo.filetype == "eca-input"
end

-- (Optional) Non-alphanumeric characters that trigger the source
function source:get_trigger_characters()
  return { "@", "#" }
end

---@param context eca.ChatContext
---@return lsp.CompletionItem
local function as_completion_item(context)
  local kinds = require("blink.cmp.types").CompletionItemKind
  ---@type lsp.CompletionItem
  ---@diagnostic disable-next-line: missing-fields
  local item = {}
  if context.type == "file" then
    item.label = vim.fn.fnamemodify(context.path, ":.")
    item.kind = kinds.File
    item.data = {
      context_item = context,
    }
  elseif context.type == "directory" then
    item.label = vim.fn.fnamemodify(context.path, ":.")
    item.kind = kinds.Folder
  elseif context.type == "web" then
    item.label = context.url
    item.kind = kinds.File
  elseif context.type == "repoMap" then
    item.label = "repoMap"
    item.kind = kinds.Module
    item.detail = "Summary view of workspace files."
  elseif context.type == "mcpResource" then
    item.label = string.format("%s:%s", context.server, context.name)
    item.kind = kinds.Struct
    item.detail = context.description
  end
  if not item.label then
    return {}
  end
  return item
end

---@param ctx blink.cmp.Context
---@param callback fun(response?: blink.cmp.CompletionResponse)
function source:get_completions(ctx, callback)
  local context = require("eca.completion.context")
  local query = context.get_query(ctx.line, ctx.cursor)
  if query then
    context.get_completion_candidates(query, as_completion_item, callback)
  end
end

---@param item lsp.CompletionItem
---@param callback fun(any)
function source:resolve(item, callback)
  require("eca.completion.context").resolve_completion_item(item, callback)
end

---Executed after the item was selected
---@param item lsp.CompletionItem
---@param callback fun(any)
function source:execute(item, callback)
  require("eca.completion.context").execute(item, callback)
end

return source
