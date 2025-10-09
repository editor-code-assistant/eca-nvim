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
---@field status eca.StateStatus
---@field config eca.StateConfig
---@field usage eca.StateUsage
---@field tools table<string, eca.StateTool>
local State = {}

---@return eca.State
function State._new()
  local instance = setmetatable({
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
      limit = (usage.limit and usage.limit.output) or self.usage.tokens.limit,
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

return State
