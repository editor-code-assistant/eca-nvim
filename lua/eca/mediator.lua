---@class eca.Mediator
---@field server eca.Server
---@field state eca.State
local mediator = {}

---@param server eca.Server
---@param state eca.State
---@return eca.Mediator
function mediator.new(server, state)
  return setmetatable({
    server = server,
    state = state,
  }, { __index = mediator })
end

local function context_adapter(context)
  if not context or not context.type or not context.data then
    return nil
  end

  local function is_pos(p)
    return type(p) == "table" and type(p.line) == "number" and type(p.character) == "number"
  end

  local adapters = {
    cursor = function(ctx)
      local d = ctx.data

      if type(d.path) ~= "string" or type(d.position) ~= "table" then
        return nil
      end

      local start_src = d.position.position_start
      local end_src = d.position.position_end

      if not (is_pos(start_src) and is_pos(end_src)) then
        return nil
      end

      return {
        type = ctx.type,
        path = d.path,
        position = {
          start = {
            line = start_src.line,
            character = start_src.character,
          },
          ["end"] = {
            line = end_src.line,
            character = end_src.character,
          },
        },
      }
    end,
    directory = function(ctx)
      if type(ctx.data.path) ~= "string" then
        return nil
      end
      return {
        type = ctx.type,
        path = ctx.data.path,
      }
    end,
    file = function(ctx)
      local d = ctx.data
      if type(d.path) ~= "string" then
        return nil
      end
      local linesRange = nil
      if type(d.lines_range) == "table" and type(d.lines_range.line_start) == "number" and type(d.lines_range.line_end) == "number" then
        linesRange = {
          start = d.lines_range.line_start,
          ["end"] = d.lines_range.line_end,
        }
      end

      return {
        type = ctx.type,
        path = d.path,
        linesRange = linesRange,
      }
    end,
    web = function(ctx)
      if type(ctx.data.path) ~= "string" then
        return nil
      end
      return {
        type = ctx.type,
        url = ctx.data.path,
      }
    end,
  }

  local adapter = adapters[context.type]

  if not adapter then
    return nil
  end

  return adapter(context)
end

---@param method string
---@param params eca.MessageParams
---@param callback? fun(err?: string, result?: table)
function mediator:send(method, params, callback)
  if not self.server:is_running() then
    if callback then
      callback("Server is not running, please start the server", nil)
    end
    require("eca.logger").notify("Server is not rnning, please start the server", vim.log.levels.WARN)
  end

  local contexts = {}

  for _, context in pairs(params.contexts) do
    local adapted = context_adapter(context)
    if adapted then
      table.insert(contexts, adapted)
    end
  end

  params.contexts = contexts

  self.server:send_request(method, params, callback)
end

function mediator:behaviors()
  return self.state.config.behaviors.list
end

function mediator:selected_behavior()
  return self.state.config.behaviors.selected
end

function mediator:update_selected_behavior(behavior)
  self.state:update_selected_behavior(behavior)
end

function mediator:models()
  return self.state.config.models.list
end

function mediator:selected_model()
  return self.state.config.models.selected
end

function mediator:update_selected_model(model)
  self.state:update_selected_model(model)
end

function mediator:tokens_session()
  return self.state.usage.tokens.session
end

function mediator:tokens_limit()
  return self.state.usage.tokens.limit
end

function mediator:costs_session()
  return self.state.usage.costs.session
end

function mediator:status_state()
  return self.state.status.state
end

function mediator:status_text()
  return self.state.status.text
end

function mediator:welcome_message()
  return (self.state and self.state.config and self.state.config.welcome_message) or nil
end

function mediator:mcps()
  local mcps = {}

  for _, tool in pairs(self.state.tools) do
    if tool.type == "mcp" then
      table.insert(mcps, tool)
    end
  end

  return mcps
end

function mediator:id()
  return self.state and self.state.id
end

function mediator:contexts()
  return self.state and self.state.contexts
end

function mediator:add_context(context)
  if not self.state then
    return
  end

  self.state:add_context(context)
end

function mediator:remove_context(name)
  if not self.state then
    return
  end

  self.state:remove_context(name)
end

function mediator:clear_contexts()
  if not self.state then
    return
  end

  self.state:clear_contexts()
end

return mediator
