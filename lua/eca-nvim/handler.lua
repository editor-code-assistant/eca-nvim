local Handler = {}

function Handler.new(protocols, ui, logger)
  local instance = {
    protocols = protocols,
    ui = ui,
    logger = logger,
  }

  setmetatable(instance, { __index = Handler })

  return instance
end

function Handler:start()
  self.protocols.executor:run(function(done)
    local dispatchers_ok, dispatchers = self.protocols.eca:dispatchers(
      {
        on_running = function() self:on_running() end,
        on_finished = function() self:on_finished() end,
        on_answer = function(...) self:on_answer(...) end,
        on_unknown = function(...) self:on_unknown(...) end,
      })

    if not dispatchers_ok then
      self.logger.error('Failed to initialize eca dispatchers: ' .. dispatchers)
      return
    end

    local connect_ok, dispatchers_err = self.protocols.client:connect(dispatchers)

    if not connect_ok then
      self.logger.error('Failed to connect client: ' .. dispatchers_err)
      return
    end

    local init_ok, init_request = self.protocols.eca:init(
      {
        callback = function(ok, welcome_message) self:setup(ok, welcome_message) end,
      })

    if not init_ok then
      self.logger.error('Failed to create init request: ' .. init_request)
      return
    end

    local request_ok, request_err = self.protocols.client:request(init_request)

    if not request_ok then
      self.logger.error('Failed to send init request: ' .. request_err)
      return
    end

    done()
  end)
end

function Handler:on_running()
  self.protocols.executor:run(function(done)
    if not self.ui.chat:is_locked() then
      self.ui.chat:lock()
    end
    done()
  end)
end

function Handler:on_finished()
  self.protocols.executor:run(function(done)
    self.ui.chat:append('\n')
    done()
  end)
end

function Handler:on_answer(text)
  self.protocols.executor:run(function(done)
    self.ui.chat:append(text)
    done()
  end)
end

function Handler:on_unknown(...)
  local args = { ... }
  self.protocols.executor:run(function(done)
    local log = ''
    for i, v in ipairs(args) do
      if type(v) ~= 'string' then
        v = vim.inspect(v)
      end

      log = log .. 'Arg ' .. i .. ': ' .. tostring(v) .. '\n'
    end

    self.logger.debug('Unknown event received:\n' .. log)
    done()
  end)
end

function Handler:setup(ok, welcome_message)
  self.protocols.executor:run(function(done)
    if not ok then
      self.logger.error('Failed to initialize: ' .. tostring(welcome_message))
      return
    end

    if self.protocols.eca.current_model then
      self.ui.chat:set_input_name(self.protocols.eca.current_model)
    end

    if self.protocols.eca.current_behavior then
      self.ui.chat:set_input_filetype(self.protocols.eca.current_behavior)
    end

    local initialized_ok, initialized_request = self.protocols.eca:initialized()

    if not initialized_ok then
      self.logger.error('Setup error: ' .. initialized_request)
      return
    end

    local notify_ok = self.protocols.client:notify(initialized_request)

    if not notify_ok then
      self.logger.error('Setup error: Failed to send initialization notification')
      return
    end

    self.ui.chat:add_message({
      id = self.protocols.executor:index(),
      role = 'assistant',
      content = welcome_message,
    })

    done()
  end)
end

function Handler:send_request(text)
  self.protocols.executor:run(function(done)
    if not text or type(text) ~= 'string' then
      self.logger.error('No user message found to send.')
      return
    end

    local index = self.protocols.executor:index()

    local prompt_ok, prompt_request = self.protocols.eca:prompt(
      text,
      {
        chat_id = 1,
        request_id = index
      },
      function(err)
        self.ui.chat:add_message({
          id = index,
          role = 'user',
          content = text,
        })

        self.ui.chat:append('\n')

        self.ui.chat:add_message({
          id = self.protocols.executor:index(),
          role = "assistant",
          content = err and err.message or '',
        })
      end
    )

    if not prompt_ok then
      self.logger.error('Failed to create prompt request: ' .. prompt_request)
      return
    end

    local request_ok, request_err = self.protocols.client:request(prompt_request)

    if not request_ok then
      self.logger.error('Failed to send prompt request: ' .. request_err)
    end

    done()
  end)
end

function Handler:stop()
  local shutdown_ok, shutdown_request = self.protocols.eca:shutdown()

  if not shutdown_ok then
    self.logger.error('Failed to create shutdown request: ' .. shutdown_request)
  end

  local request_ok, request_err = self.protocols.client:request(shutdown_request)

  if not request_ok then
    self.logger.error('Failed to send shutdown request: ' .. request_err)
  end

  local exit_ok, exit_request = self.protocols.eca:exit()

  if not exit_ok then
    self.logger.error('Failed to create exit request: ' .. exit_request)
  end

  local notify_ok = self.protocols.client:notify(exit_request)

  if not notify_ok then
    self.logger.error('Failed to send exit notification')
  end

  if self.protocols.client then
    self.protocols.client:stop()
  end

  if self.ui.chat then
    self.ui.chat:close()
  end
end

function Handler:select_model()
  if not (self.protocols.eca and self.protocols.eca.models) then
    self.logger.error('ECA models not available.')
    return
  end

  if not self.ui.chat or not self.ui.chat.set_input_name then
    self.logger.error('Chat UI does not support name changing.')
    return
  end

  self.ui.select.open(
    self.protocols.eca.models,
    { prompt = 'ECA Select a model:' },
    function(selected_model)
      if not selected_model then return end

      local ok, err = self.protocols.eca:set_model(selected_model)

      if not ok then
        self.logger.error('Failed to set model: ' .. err)
        return
      end

      self.ui.chat:set_input_name(selected_model)
    end)
end

function Handler:select_behavior()
  if not (self.protocols.eca and self.protocols.eca.behaviors) then
    self.logger.error('ECA behaviors not available.')
    return
  end

  if not self.ui.chat or not self.ui.chat.set_input_filetype then
    self.logger.error('Chat UI does not support filetype changing.')
    return
  end

  self.ui.select.open(
    self.protocols.eca.behaviors,
    { prompt = 'ECA Select a behavior:' },
    function(selected_behavior)
      if not selected_behavior then return end

      local ok, err = self.protocols.eca:set_behavior(selected_behavior)

      if not ok then
        self.logger.error('Failed to set behavior: ' .. err)
        return
      end

      self.ui.chat:set_input_filetype(selected_behavior)
    end)
end

return Handler
