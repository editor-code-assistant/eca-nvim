local ECA = {}

function ECA.new()
  local instance = {
    current_model = nil,
    models = {},
    current_behavior = nil,
    behaviors = {},
  }

  setmetatable(instance, { __index = ECA })

  return instance
end

function ECA:init(opts)
  local callback = opts.callback

  if not callback or type(callback) ~= 'function' then
    callback = function(...) end
  end

  return true, {
    method = 'initialize',
    params = {
      processId = vim.fn.getpid(),
      clientInfo = {
        name = 'Neovim',
        version = vim.version().major .. '.' .. vim.version().minor .. '.' .. vim.version().patch,
      },
      capabilities = {
        codeAssistant = {
          chat = true
        }
      },
      initializationOptions = {},
      workspaceFolders = {
        {
          uri = 'file://' .. vim.fn.getcwd(),
          name = 'current workspace',
        }
      },
    },
    callback = function(err, response)
      if err then
        callback(false, err)
        return
      end

      local ok, error = self:set_models(response.models, response.chatDefaultModel)

      if not ok then
        callback(false, error)
        return
      end

      ok, error = self:set_behaviors(response.chatBehaviors, response.chatDefaultBehavior)

      if not ok then
        callback(false, error)
        return
      end

      callback(true, response.chatWelcomeMessage)
    end
  }
end

function ECA:initialized()
  return true, {
    method = 'initialized'
  }
end

function ECA:set_behaviors(behaviors, default)
  if not behaviors or type(behaviors) ~= 'table' then
    return false, 'Failed to set_behaviors: Please provide a table of behavior names.'
  end

  self.behaviors = behaviors

  local ok, error = self:set_behavior(default)

  if not ok then
    return false, error
  end

  return true, behaviors
end

function ECA:set_behavior(behavior)
  if not behavior or type(behavior) ~= 'string' then
    return false, 'Failed to set_behavior: Invalid behavior name'
  end

  if not vim.tbl_contains(self.behaviors, behavior) then
    return false,
        'Failed to set_behavior: Behavior "' ..
        behavior .. '" is not available. Available behaviors: ' .. vim.inspect(self.behaviors)
  end

  self.current_behavior = behavior
  return true, nil
end

function ECA:set_models(models, default)
  if not models or type(models) ~= 'table' then
    return false, 'Failed to set_models: Please provide a table of model names.'
  end

  self.models = models

  local ok, error = self:set_model(default)

  if not ok then
    return false, error
  end

  return true, models
end

function ECA:set_model(model)
  if not model or type(model) ~= 'string' then
    return false, 'Failed to set_model: Invalid model name'
  end

  if not vim.tbl_contains(self.models, model) then
    return false,
        'Failed to set_model: Model "' .. model .. '" is not available. Available models: ' .. vim.inspect(self.models)
  end

  self.current_model = model

  return true, nil
end

function ECA:dispatchers(opts)
  local on_running = opts.on_running

  if not on_running or type(on_running) ~= 'function' then
    on_running = function(_) end
  end

  local on_finished = opts.on_finished

  if not on_finished or type(on_finished) ~= 'function' then
    on_finished = function(_) end
  end

  local on_answer = opts.on_answer

  if not on_answer or type(on_answer) ~= 'function' then
    on_answer = function(_) end
  end

  local on_unknown = opts.on_unknown

  if not on_unknown or type(on_unknown) ~= 'function' then
    on_unknown = function(_, _) end
  end

  local handlers = {
    system = {
      progress = function(content)
        if content.state == 'running' then
          on_running(content.text)
        elseif content.state == 'finished' then
          on_finished(content.text)
        end
      end
    },
    assistant = {
      text = function(content)
        on_answer(content.text)
      end,
    },
  }

  return true, {
    notification = function(method, params)
      if method == 'chat/contentReceived' then
        local handler = handlers[params.role] and handlers[params.role][params.content.type]

        if not handler or type(handler) ~= 'function' then
          on_unknown(method, params)
          return
        end

        handler(params.content)
      end
    end,
    server_request = function(method, params)
      vim.notify('Server request received: ' .. method .. '\nParams: ' .. vim.inspect(params), vim.log.levels.DEBUG)
    end,
    on_exit = function(code, signal)
      vim.notify('Server exited with code: ' .. code .. ' and signal: ' .. signal, vim.log.levels.DEBUG)
    end,
    on_error = function(code, err)
      vim.notify('Server error code: ' .. code .. '\nError: ' .. err, vim.log.levels.DEBUG)
    end,
  }
end

function ECA:prompt(text, opts, callback)
  if not self.current_model or not vim.tbl_contains(self.models, self.current_model) then
    return false, 'No model set. Please set a valid model before prompting.'
  end

  if not text or type(text) ~= 'string' or text == '' then
    return false, 'Invalid text. Please provide a non-empty string.'
  end

  if not opts or type(opts) ~= 'table' then
    return false, 'Invalid options. Expected a table.'
  end

  local opts_check = {
    { opt = 'chat_id',    type = 'number' },
    { opt = 'request_id', type = 'number' },
  }

  for _, check in ipairs(opts_check) do
    if not opts[check.opt] or type(opts[check.opt]) ~= check.type then
      return false, 'Invalid opts.' .. check.opt .. '. Please provide a valid ' .. check.opt .. '.'
    end
  end

  if not callback or type(callback) ~= 'function' then
    callback = function(...) end
  end

  return true, {
    method = 'chat/prompt',
    params = {
      chatId = opts.chat_id,
      requestId = opts.request_id,
      message = text,
      model = self.current_model,
      behavior = self.current_behavior,
    },
    callback = callback,
  }
end

function ECA:shutdown()
  return true, {
    method = 'shutdown',
    params = {},
  }
end

function ECA:exit()
  return true, {
    method = 'exit',
  }
end

return ECA
