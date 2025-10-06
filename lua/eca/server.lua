local Utils = require("eca.utils")
local Config = require("eca.config")
local Logger = require("eca.logger")

---@class eca.Server
---@field process vim.SystemObj
---@field messages {content_length: integer, content: string}
---@field next_id integer next outgoing message id
---@field initialized boolean when true, server ready to receive messages
---@field on_initialize? function Callback when server initializes
---@field on_start? function Callback when the server process starts
---@field on_stop function Callback when the server stops
---Called when a notification is received(message without an ID)
---@field on_notification fun(server: eca.Server, message: table)
---@field pending_requests {id: fun(err, data)} -- outgoing requests with callbacks
---@field cwd string Current working directory for the server process
---@field workspace_folders {name: string, uri: string}[] Workspace folders to send on initialize
local M = {}

---@param opts? table
---@return eca.Server
function M.new(opts)
  opts = vim.tbl_extend("keep", opts or {}, {
    on_start = function(pid)
      require("eca.logger").debug("Started server with pid " .. pid)
    end,
    on_initialize = function()
      require("eca.logger").notify("Server ready to receive messages", vim.log.levels.INFO)
    end,
    on_stop = function()
      require("eca.logger").notify("Server stopped", vim.log.levels.INFO)
    end,
    ---@param _ eca.Server
    ---@param message table
    on_notification = function(_, message)
      return vim.schedule(function()
        require("eca.observer").notify(message)
      end)
    end,
    cwd = vim.fn.getcwd(),
    workspace_folders = {
      {
        name = vim.fn.fnamemodify(Utils.get_project_root(), ":t"),
        uri = "file://" .. Utils.get_project_root(),
      },
    },
  })

  return setmetatable({
    process = nil,
    on_start = opts.on_start,
    on_initialize = opts.on_initialize,
    on_stop = opts.on_stop,
    on_notification = opts.on_notification,
    messages = {},
    pending_requests = {},
    initialized = false,
    next_id = 0,
    cwd = opts.cwd,
    workspace_folders = opts.workspace_folders,
  }, { __index = M })
end

---@param server eca.Server
---@return fun(err: string, data: string)
local function on_stdout(server)
  return function(err, data)
    assert(not err)
    if data then
      local messages = require("eca.message_handler").parse_raw_messages(data)
      vim.iter(messages):each(function(message)
        if #message.content ~= message.content_length then
          return
        end
        table.insert(server.messages, message)
        local msg = vim.json.decode(message.content)
        server:handle_message(msg)
      end)
    end
  end
end

---@param err string
---@param data string
local function on_stderr(err, data)
  assert(not err)
  if data then
    vim.schedule(function()
      require("eca.logger").log(data, vim.log.levels.INFO)
    end)
  end
end

---@class eca.ServerStartOpts: vim.SystemOpts
---@field cmd string[] The command to pass to vim.system
---@field on_exit fun(out: vim.SystemCompleted) callback to pass to vim.system
---@field initialize boolean Send the initialize message to ECA on startup, used
---in testing
---@param opts? eca.ServerStartOpts
function M:start(opts)
  opts = opts or { initialize = true }

  local this_file = debug.getinfo(1, "S").source:sub(2)
  local proj_root = vim.fn.fnamemodify(this_file, ":p:h:h:h")
  local script_path = proj_root .. "/scripts/server_path.lua"

  local nvim_exe = vim.fn.exepath("nvim")

  if not nvim_exe or nvim_exe == "" then
    nvim_exe = "nvim"
  end

  local lua_cmd = string.format("lua ServerPath.run(%s)", Utils.lua_quote(Config.options.server_path) or "")

  local cmd = { nvim_exe, "--headless", "--noplugin", "-u", script_path, "-c", lua_cmd }

  vim.system(cmd, { text = true }, function(out)
    if out.code ~= 0 then
      Logger.notify(out.stderr, vim.log.levels.ERROR)
      return
    end

    local stdout_lines = Utils.split_lines(out.stdout)
    local server_path = stdout_lines[#stdout_lines]

    Logger.debug("Starting ECA server: " .. server_path)

    local args = { server_path, "server" }

    if Config.server_args and Config.server_args ~= "" then
      vim.list_extend(args, vim.split(Config.server_args, " "))
    end

    opts = vim.tbl_deep_extend("keep", opts, {
      cmd = args,
      text = true,
      cwd = self.cwd,
      stdin = true,
      stdout = on_stdout(self),
      stderr = on_stderr,
      ---@param output vim.SystemCompleted
      on_exit = function(output)
        if output.code ~= 0 then
          require("eca.logger").notify(string.format("Server exited with status code %d", output.code), vim.log.levels
          .ERROR)
        end
      end,
    })

    local started, process_or_err = pcall(vim.system, opts.cmd, {
      cwd = opts.cwd,
      text = opts.text,
      stdin = opts.stdin,
      stdout = opts.stdout,
      stderr = opts.stderr,
    }, opts.on_exit)

    if not started then
      self.process = nil
      Logger.notify(vim.inspect(process_or_err), vim.log.levels.ERROR)
      return
    end

    self.process = process_or_err
    if self.on_start then
      self.on_start(process_or_err.pid)
    end

    if opts.initialize then
      self:initialize()
    end
  end)
end

function M:initialize()
  self:send_request("initialize", {
    processId = vim.fn.getpid(),
    clientInfo = {
      name = "Neovim",
      version = vim.version().major .. "." .. vim.version().minor,
    },
    capabilities = {
      codeAssistant = {
        chat = true,
      },
    },
    workspaceFolders = vim.deepcopy(self.workspace_folders),
  }, function(err, _)
    if err then
      Logger.notify("Could not initialize server: " .. err, vim.log.levels.ERROR)
      return
    end

    self:send_notification("initialized", {})

    if self.on_initialize then
      self.on_initialize()
    end
    self.initialized = true
  end)
end

function M:stop()
  if self.process then
    self:send_request("shutdown", {}, function(err, _)
      if err then
        self.process:kill("TERM")
        return
      end
      self:send_request("exit", {})
      if self.on_stop then
        self:on_stop()
      end
      self.process = nil
    end)
  end

  self._rpc = nil
  self.next_id = 0
  self.initialized = false
end

---@return boolean
function M:is_running()
  return self.process and not self.process:is_closing()
end

---@param message table incoming decoded JSON message
function M:handle_message(message)
  if message.id and self.pending_requests[message.id] then
    local callback = self.pending_requests[message.id]
    self.pending_requests[message.id] = nil

    if message.error then
      callback(message.error, nil)
    else
      callback(nil, message.result)
    end
  elseif message.method and not message.id then
    if self.on_notification then
      self:on_notification(message)
    end
  end
end

---@return integer
function M:get_next_id()
  self.next_id = self.next_id + 1
  return self.next_id
end

---@param method string
---@param params table
---@param callback? function
function M:send_request(method, params, callback)
  if not self:is_running() then
    Logger.error("ECA server is not running")
    if callback then
      callback("Server not running", nil)
    end
  end
  local id = self:get_next_id()
  local message = {
    jsonrpc = "2.0",
    method = method,
    params = params,
  }
  if callback then
    message.id = id
    self.pending_requests[id] = callback
  end

  local json = vim.json.encode(message)
  table.insert(self.messages, { content = json, content_length = #json })
  local content = string.format("Content-Length: %d\r\n\r\n%s", #json, json)
  self.process:write(content)
end

---@param method string
---@param params table
function M:send_notification(method, params)
  if not self:is_running() then
    return
  end
  self:send_request(method, params)
end

return M
