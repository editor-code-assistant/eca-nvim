local Handler  = require('eca-nvim.handler')
local Chat     = require('eca-nvim.ui.chat')
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

  local eca      = ECA.new()
  local chat     = Chat.open({})
  local client   = Client.new { server = { cmd = start_command, args = spawn_args } }
  local executor = Executor.new()
  local logger   = log.get_logger(config.get('log'))

  if logger and type(logger.filepath) == "string" and logger.filepath ~= "" then
    vim.api.nvim_create_user_command("EcaLogs", function()
      vim.cmd('tabedit ' .. vim.fn.fnameescape(logger.filepath))
    end, {})
  end

  local handler = Handler.new(eca, chat, client, executor, logger)

  for _, winnr in ipairs({ chat.winnr, chat.input_winnr }) do
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

  local function set_submit_prompt_keymap(callback)
    local function handle_input()
      local lines = vim.api.nvim_buf_get_lines(chat.input_bufnr, 0, -1, false)
      local text = table.concat(lines, "\n")

      callback(text)

      vim.api.nvim_buf_set_lines(chat.input_bufnr, 0, -1, false, {})
    end

    vim.keymap.set('n', '<CR>', handle_input, { buffer = chat.input_bufnr, nowait = true })
    vim.keymap.set('i', '<C-s>', handle_input, { buffer = chat.input_bufnr, nowait = true })
  end

  handler:init(set_submit_prompt_keymap)
end

vim.api.nvim_create_user_command("EcaChat", function()
  M.run()
end, {})

return M
