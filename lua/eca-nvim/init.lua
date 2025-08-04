local Handler  = require('eca-nvim.handler')
local Chat     = require('eca-nvim.ui.chat')
local select   = require('eca-nvim.ui.select')
local Client   = require('eca-nvim.protocols.client')
local ECA      = require('eca-nvim.protocols.eca')
local Executor = require('eca-nvim.protocols.executor')
local config   = require('eca-nvim.tools.config')
local server   = require('eca-nvim.tools.server')
local log      = require('eca-nvim.tools.log')

local M        = {}

function M.setup(opts)
  config.apply(opts or {})
end

function M.run()
  local custom_server_config = config.get('server') or {}
  local start_command        = custom_server_config and custom_server_config.command
  local spawn_args           = custom_server_config and custom_server_config.spawn_args

  if not (type(start_command) == 'table' and #start_command > 0) then
    local ok, server_path = server.get_path()

    if not ok then
      return
    end

    start_command = { '/usr/bin/java', '-jar', server_path, 'server' }
  end

  if type(spawn_args) ~= 'table' then
    spawn_args = {}
  end

  local protocols = {
    eca      = ECA.new(),
    client   = Client.new({ server = { cmd = start_command, args = spawn_args } }),
    executor = Executor.new(),
  }

  local ui = {
    chat = Chat.open({}),
    select = select,
  }

  local logger   = log.get_logger(config.get('log'))

  if logger and type(logger.filepath) == "string" and logger.filepath ~= "" then
    vim.api.nvim_create_user_command("EcaLogs", function()
      vim.cmd('tabedit ' .. vim.fn.fnameescape(logger.filepath))
    end, {})
  end

  local handler = Handler.new(protocols, ui, logger)
  handler:start()

  for _, winnr in ipairs({ ui.chat.winnr, ui.chat.input_winnr }) do
    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(winnr),
      callback = function()
        handler:stop()
      end,
    })
  end

  vim.api.nvim_create_user_command("EcaModel", function()
    handler:select_model()
  end, {})

  vim.api.nvim_create_user_command("EcaBehavior", function()
    handler:select_behavior()
  end, {})

  local function set_submit_prompt_keymap()
    local function handle_input()
      local lines = vim.api.nvim_buf_get_lines(ui.chat.input_bufnr, 0, -1, false)
      local text = table.concat(lines, "\n")

      handler:send_request(text)

      vim.api.nvim_buf_set_lines(ui.chat.input_bufnr, 0, -1, false, {})
    end

    vim.keymap.set('n', '<CR>', handle_input, { buffer = ui.chat.input_bufnr, nowait = true })
    vim.keymap.set('i', '<C-s>', handle_input, { buffer = ui.chat.input_bufnr, nowait = true })
  end

  set_submit_prompt_keymap()
end

vim.api.nvim_create_user_command("EcaChat", function()
  M.run()
end, {})

return M
