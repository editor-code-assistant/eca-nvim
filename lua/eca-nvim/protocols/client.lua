local Client = {}

function Client.new(opts)
  local instance = {
    server = {
      cmd = opts.server.cmd,
      args = opts.server.args,
    },
    connection = nil,
  }

  setmetatable(instance, { __index = Client })

  return instance
end

function Client:connect(dispatchers)
  if self.connection then
    return false, 'Failed at Client connect: Instance already exists. Please disconnect first.'
  end

  if not self.server.cmd or type(self.server.cmd) ~= 'table' or #self.server.cmd < 1 then
    return false, 'Invalid command. Please provide a valid command to start the server.'
  end

  self.connection = vim.lsp.rpc.start(self.server.cmd, dispatchers, self.server.args)

  if not self.connection then
    return false,
        'Failed to start the server with command: ' ..
        vim.inspect(self.server.cmd) ' and args: ' .. vim.inspect(self.server.args)
  end

  return true, nil
end

function Client:notify(request)
  if not self.connection then
    return false, 'Client not started. Please start the server first.'
  end

  if not request.method or type(request.method) ~= 'string' then
    return false, 'Invalid request method: ' .. vim.inspect(request.method) .. '. Expected a string.'
  end

  local ok = self.connection.notify(request.method)

  if not ok then
    return false, 'RPC notification failed: ' .. request.method
  end

  return true, nil
end

function Client:request(request)
  if not self.connection then
    return false, 'Client not started. Please start the server first.'
  end

  if not request or type(request) ~= 'table' then
    return false, 'Invalid request argument. Expected a table.'
  end

  if not request.method or type(request.method) ~= 'string' then
    return false, 'Invalid request method: ' .. vim.inspect(request.method) .. '. Expected a string.'
  end

  if not request.params or type(request.params) ~= 'table' then
    return false, 'Invalid request params: ' .. vim.inspect(request.params) .. '. Expected a table.'
  end

  local callback = request.callback

  if not callback or type(callback) ~= 'function' then
    callback = function(...) end
  end

  local ok, request_id = self.connection.request(request.method, request.params, callback)

  if not ok then
    return false, 'Request failed: ' .. request.method .. '\nParams: ' .. vim.inspect(request.params)
  end

  return true, request_id
end

function Client:stop()
  if not self.connection or not self.connection.terminate then
    return true, nil
  end

  self.connection.terminate()
  self.connection = nil

  return true, nil
end

return Client
