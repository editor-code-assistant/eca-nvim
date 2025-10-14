---@class eca.StateStatus
---@field state string
---@field text string

---@class eca.StateConfig
---@field welcome_message string?
---@field behaviors { list: string[], default: string?, selected: string? }
---@field models { list: string[], default: string?, selected: string? }

---@class eca.StateUsage
---@field tokens { limit: number, session: number }
---@field costs { last_message: string, session: string }

---@class eca.StateTool
---@field type string
---@field name string
---@field status string
---
---@class eca.State
---@field id string?
---@field status eca.StateStatus
---@field config eca.StateConfig
---@field usage eca.StateUsage
---@field tools table<string, eca.StateTool>
---@field contexts eca.Context[]
local State = {}

---@return eca.State
function State._new()
  local instance = setmetatable({
    id = nil,
    status = {
      state = "idle",
      text = "Idle",
    },
    config = {
      welcome_message = nil,
      behaviors = {
        list = {},
        default = nil,
        selected = nil,
      },
      models = {
        list = {},
        default = nil,
        selected = nil,
      },
    },
    usage = {
      tokens = {
        limit = 0,
        session = 0,
      },
      costs = {
        last_message = "0.00",
        session = "0.00",
      },
    },
    tools = {},
    contexts = {},
  }, { __index = State })

  local handlers = {
    ["chat/contentReceived"] = function(message) instance:_chat_content_received(message) end,
    ["config/updated"] = function(message) instance:_config_updated(message) end,
    ["tool/serverUpdated"] = function(message) instance:_tool_server_updated(message) end,
  }

  require("eca.observer").subscribe("state-1", function(message)
    if not message or not message.method then
      return
    end

    local handler = handlers[message.method]

    if not handler or type(handler) ~= 'function' then
      return
    end

    handler(message)
  end)

  return instance
end

local _instance

---@return eca.State
function State.new()
  if not _instance then
    _instance = State._new()
  end

  return _instance
end

function State:_chat_content_received(message)
  if not message or not message.params then
    return
  end

  if not message.params.content or not message.params.content.type then
    return
  end

  if message.params.chatId and message.params.chatId ~= self.id then
    self.id = message.params.chatId
  end

  local content = message.params.content

  if content.type == "progress" then
    self:_update_status(content)
  end

  if content.type == "usage" then
    self:_update_usage(content)
  end
end

function State:_config_updated(message)
  if not message or not message.params then
    return
  end

  if not message.params.chat or type(message.params.chat) ~= "table" then
    return
  end

  self:_update_config({ chat = vim.deepcopy(message.params.chat) })
end

function State:_tool_server_updated(message)
  if not message or not message.params then
    return
  end

  self:_update_tools(message.params)
end

function State:_update_config(config)
  local chat = config.chat

  if not chat or type(chat) ~= "table" then
    return
  end

  self.config.behaviors = {
    list = (chat.behaviors and vim.deepcopy(chat.behaviors)) or self.config.behaviors.list,
    default = (chat.defaultBehavior) or self.config.behaviors.default,
    selected = (chat.selectBehavior) or self.config.behaviors.selected,
  }

  self.config.models = {
    list = (chat.models and vim.deepcopy(chat.models)) or self.config.models.list,
    default = (chat.defaultModel) or self.config.models.default,
    selected = (chat.selectModel) or self.config.models.selected,
  }

  self.config.welcome_message = (chat and chat.welcomeMessage) or self.config.welcome_message

  vim.schedule(function()
    require("eca.observer").notify({ type = "state/updated", content = { config = vim.deepcopy(self.config) } })
  end)
end

function State:_update_status(status)
  self.status.state = status.state or self.status.state
  self.status.text = status.text or self.status.text

  vim.schedule(function()
    require("eca.observer").notify({ type = "state/updated", content = { status = vim.deepcopy(self.status) } })
  end)
end

function State:_update_usage(usage)
  self.usage = {
    tokens = {
      limit = (usage.limit and usage.limit.context) or self.usage.tokens.limit,
      session = usage.sessionTokens or self.usage.tokens.session,
    },
    costs = {
      last_message = usage.lastMessageCost or self.usage.costs.last_message,
      session = usage.sessionCost or self.usage.costs.session,
    },
  }

  vim.schedule(function()
    require("eca.observer").notify({ type = "state/updated", content = { usage = vim.deepcopy(self.usage) } })
  end)
end

function State:_update_tools(tool)
  if not tool.name then
    return
  end

  self.tools[tool.name] = {
    name = tool.name,
    type = tool.type or (self.tools[tool.name] and self.tools[tool.name].type) or "unknown",
    status = tool.status or (self.tools[tool.name] and self.tools[tool.name].status) or "unknown",
  }

  vim.schedule(function()
    require("eca.observer").notify({ type = "state/updated", content = { tools = vim.deepcopy(self.tools) } })
  end)
end

function State:update_selected_model(model)
  if not model or type(model) ~= "string" then
    return
  end

  self.config.models.selected = model

  vim.schedule(function()
    require("eca.observer").notify({ type = "state/updated", content = { config = vim.deepcopy(self.config) } })
  end)
end

function State:update_selected_behavior(behavior)
  if not behavior or type(behavior) ~= "string" then
    return
  end

  self.config.behaviors.selected = behavior

  vim.schedule(function()
    require("eca.observer").notify({ type = "state/updated", content = { config = vim.deepcopy(self.config) } })
  end)
end

function State:_update_contexts()
  vim.schedule(function()
    require("eca.observer").notify({ type = "state/updated", content = { contexts = vim.deepcopy(self.contexts) } })
  end)
end

function State:add_context(context)
  if not context or type(context) ~= "table" then
    return
  end

  if not context.type or not context.data then
    return
  end

  -- avoid duplicates
  for _, ctx in ipairs(self.contexts) do
    if ctx.type == context.type and vim.deep_equal(ctx.data, context.data) then
      return
    end
  end

  -- if is 'cursor' type and exists 'cursor' in contexts, replace
  if context.type == "cursor" then
    for i, ctx in ipairs(self.contexts) do
      if ctx.type == "cursor" then
        self.contexts[i] = context
        self:_update_contexts()
        return
      end
    end
  end

  table.insert(self.contexts, context)
  self:_update_contexts()
end

function State:remove_context(context)
  if not context or type(context) ~= "table" then
    return
  end

  for i, ctx in ipairs(self.contexts) do
    if ctx.type == context.type and vim.deep_equal(ctx.data, context.data) then
      table.remove(self.contexts, i)
      self:_update_contexts()
    end
  end
end

function State:clear_contexts()
  self.contexts = {}
  self:_update_contexts()
end

return State
