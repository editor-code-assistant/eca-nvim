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
  self.server:send_request(method, params, callback)
end

function mediator:selected_behavior()
  return self.state.config.behaviors.selected
end

function mediator:selected_model()
  return self.state.config.models.selected
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

return mediator
