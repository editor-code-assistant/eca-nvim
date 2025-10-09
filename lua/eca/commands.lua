local Utils = require("eca.utils")
local Logger = require("eca.logger")

local M = {}

--- Setup ECA commands
function M.setup()
  -- Define ECA commands
  vim.api.nvim_create_user_command("EcaChat", function(opts)
    require("eca.api").chat(opts.args and { message = opts.args } or {})
  end, {
    desc = "Open ECA chat",
    nargs = "?",
  })

  vim.api.nvim_create_user_command("EcaToggle", function()
    require("eca.api").toggle()
  end, {
    desc = "Toggle ECA sidebar",
  })

  vim.api.nvim_create_user_command("EcaFocus", function()
    require("eca.api").focus()
  end, {
    desc = "Focus ECA sidebar",
  })

  vim.api.nvim_create_user_command("EcaClose", function()
    require("eca.api").close()
  end, {
    desc = "Close ECA sidebar",
  })

  vim.api.nvim_create_user_command("EcaAddFile", function(opts)
    if opts.args and opts.args ~= "" then
      require("eca.api").add_file_context(opts.args)
    else
      require("eca.api").add_current_file_context()
    end
  end, {
    desc = "Add file as context to ECA",
    nargs = "?",
    complete = "file",
  })

  vim.api.nvim_create_user_command("EcaAddSelection", function()
    -- Force exit visual mode and set marks
    vim.cmd("normal! \\<Esc>")
    vim.defer_fn(function()
      require("eca.api").add_selection_context()
    end, 50) -- Small delay to ensure marks are set
  end, {
    desc = "Add current selection as context to ECA",
    range = true,
  })

  vim.api.nvim_create_user_command("EcaListContexts", function()
    require("eca.api").list_contexts()
  end, {
    desc = "List active contexts in ECA",
  })

  vim.api.nvim_create_user_command("EcaClearContexts", function()
    require("eca.api").clear_contexts()
  end, {
    desc = "Clear all contexts from ECA",
  })

  vim.api.nvim_create_user_command("EcaRemoveContext", function(opts)
    if opts.args and opts.args ~= "" then
      require("eca.api").remove_context(opts.args)
    else
      Logger.notify("Please provide a file path to remove", vim.log.levels.WARN)
    end
  end, {
    desc = "Remove specific context from ECA",
    nargs = "+",
    complete = "file",
  })

  vim.api.nvim_create_user_command("EcaAddRepoMap", function()
    require("eca.api").add_repo_map_context()
  end, {
    desc = "Add repository map context to ECA",
  })

  -- ===== Selected Code Commands =====

  vim.api.nvim_create_user_command("EcaShowSelection", function()
    require("eca.api").show_selected_code()
  end, {
    desc = "Show currently selected code in ECA",
  })

  vim.api.nvim_create_user_command("EcaClearSelection", function()
    require("eca.api").clear_selected_code()
  end, {
    desc = "Clear selected code from ECA",
  })

  -- ===== TODOs Commands =====

  vim.api.nvim_create_user_command("EcaAddTodo", function(opts)
    if opts.args and opts.args ~= "" then
      require("eca.api").add_todo(opts.args)
    else
      Logger.notify("Please provide TODO content", vim.log.levels.WARN)
    end
  end, {
    desc = "Add a new TODO to ECA",
    nargs = "+",
  })

  vim.api.nvim_create_user_command("EcaListTodos", function()
    require("eca.api").list_todos()
  end, {
    desc = "List active TODOs in ECA",
  })

  vim.api.nvim_create_user_command("EcaToggleTodo", function(opts)
    if opts.args and opts.args ~= "" then
      local index = tonumber(opts.args)
      if index then
        require("eca.api").toggle_todo(index)
      else
        Logger.notify("Please provide a valid TODO index", vim.log.levels.WARN)
      end
    else
      Logger.notify("Please provide TODO index to toggle", vim.log.levels.WARN)
    end
  end, {
    desc = "Toggle TODO completion status",
    nargs = 1,
  })

  vim.api.nvim_create_user_command("EcaClearTodos", function()
    require("eca.api").clear_todos()
  end, {
    desc = "Clear all TODOs from ECA",
  })

  vim.api.nvim_create_user_command("EcaServerStart", function()
    require("eca.api").start_server()
  end, {
    desc = "Start ECA server",
  })

  vim.api.nvim_create_user_command("EcaServerStop", function()
    require("eca.api").stop_server()
  end, {
    desc = "Stop ECA server",
  })

  vim.api.nvim_create_user_command("EcaServerRestart", function()
    require("eca.api").restart_server()
  end, {
    desc = "Restart ECA server",
  })

  vim.api.nvim_create_user_command("EcaServerMessages", function()
    local has_snacks, snacks = pcall(require, "snacks")
    if not has_snacks then
      Logger.notify("snacks.nvim is not available", vim.log.levels.ERROR)
      return
    end

    snacks.picker(
      ---@type snacks.picker.Config
      {
        source = "eca messages",
        finder = function(opts, ctx)
          ---@type snacks.picker.finder.Item[]
          local items = {}
          local eca = require("eca")
          if not eca or not eca.server then
            Logger.notify("ECA plugin is not available", vim.log.levels.ERROR)
            return items
          end

          for msg in vim.iter(eca.server.messages) do
            local decoded = vim.json.decode(msg.content)
            table.insert(items, {
              text = decoded.method,
              idx = decoded.id,
              preview = {
                text = vim.inspect(decoded),
                ft = "lua",
              },
            })
          end
          return items
        end,
        preview = "preview",
        format = "text",
        confirm = function(self, item, _)
          vim.fn.setreg("", item.preview.text)
          self:close()
        end,
      }
    )
  end, {
    desc = "Display Messages Sent to and Received by ECA server",
  })

  vim.api.nvim_create_user_command("EcaLogs", function(opts)
    local Api = require("eca.api")
    local subcommand = opts.args and opts.args:match("%S+") or "show"

    if subcommand == "show" then
      Api.show_logs()
    elseif subcommand == "log_path" then
      local log_path = Logger.get_log_path()
      Logger.notify("ECA log file: " .. log_path, vim.log.levels.INFO)
    elseif subcommand == "clear" then
      if Logger.clear_log() then
        Logger.notify("ECA log file cleared", vim.log.levels.INFO)
      else
        Logger.notify("Failed to clear log file", vim.log.levels.WARN)
      end
    elseif subcommand == "stats" then
      local stats = Logger.get_log_stats()
      if stats then
        Logger.notify(string.format("Log file: %s", stats.path), vim.log.levels.INFO)
        Logger.notify(string.format("Size: %.2fMB (%d bytes)", stats.size_mb, stats.size), vim.log.levels.INFO)
        Logger.notify(string.format("Last modified: %s", stats.modified), vim.log.levels.INFO)
      else
        Logger.notify("No log file stats available", vim.log.levels.INFO)
      end
    else
      Logger.notify("Unknown EcaLogs subcommand: " .. subcommand, vim.log.levels.WARN)
      Logger.notify("Available subcommands: show, log_path, clear, stats", vim.log.levels.INFO)
    end
  end, {
    desc = "ECA logging commands (show, log_path, clear, stats)",
    nargs = "?",
    complete = function(ArgLead, CmdLine, CursorPos)
      local subcommands = { "show", "log_path", "clear", "stats" }
      return vim.tbl_filter(function(cmd)
        return cmd:match("^" .. ArgLead)
      end, subcommands)
    end,
  })

  vim.api.nvim_create_user_command("EcaSend", function(opts)
    if opts.args and opts.args ~= "" then
      require("eca.api").send_message(opts.args)
    else
      Logger.notify("Please provide a message to send", vim.log.levels.WARN)
    end
  end, {
    desc = "Send a message to ECA",
    nargs = "+",
  })

  vim.api.nvim_create_user_command("EcaDebugWidth", function()
    local Config = require("eca.config")
    local width = Config.get_window_width()
    local columns = vim.o.columns
    local percentage = Config.options.windows.width
    Logger.notify(
      string.format("Width: %d columns (%.1f%% of %d total columns)", width, percentage, columns),
      vim.log.levels.INFO
    )
  end, {
    desc = "Debug window width calculation",
  })

  vim.api.nvim_create_user_command("EcaRedownload", function()
    local eca = require("eca")
    local Utils = require("eca.utils")

    if eca.server and eca.server:is_running() then
      Logger.notify("Stopping server before re-download...", vim.log.levels.INFO)
      eca.server:stop()
    end

    -- Remove existing version file to force re-download
    local cache_dir = Utils.get_cache_dir()
    local version_file = cache_dir .. "/eca-version"
    os.remove(version_file)

    -- Remove existing binary
    local server_binary = cache_dir .. "/eca"
    os.remove(server_binary)

    Logger.notify("Removed cached ECA server. Will re-download on next start.", vim.log.levels.INFO)

    -- Restart server
    vim.defer_fn(function()
      if eca.server then
        eca.server:start()
      end
    end, 1000)
  end, {
    desc = "Force re-download of ECA server",
  })

  vim.api.nvim_create_user_command("EcaStopResponse", function()
    local eca = require("eca")
    local Utils = require("eca.utils")

    -- Force stop any ongoing streaming response
    if eca.sidebar then
      eca.sidebar:_finalize_streaming_response()
      Logger.notify("Forced stop of streaming response", vim.log.levels.INFO)
    else
      Logger.notify("No active sidebar to stop", vim.log.levels.WARN)
    end
  end, {
    desc = "Emergency stop for infinite loops or runaway responses",
  })

  vim.api.nvim_create_user_command("EcaFixTreesitter", function()
    local Utils = require("eca.utils")

    -- Emergency treesitter fix for chat buffer
    vim.schedule(function()
      local eca = require("eca")
      if eca.sidebar and eca.sidebar.containers and eca.sidebar.containers.chat then
        local bufnr = eca.sidebar.containers.chat.bufnr
        if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
          -- Disable all highlighting for this buffer
          pcall(vim.api.nvim_set_option_value, "syntax", "off", { buf = bufnr })

          -- Destroy treesitter highlighter if it exists
          pcall(function()
            if vim.treesitter.highlighter.active[bufnr] then
              vim.treesitter.highlighter.active[bufnr]:destroy()
              vim.treesitter.highlighter.active[bufnr] = nil
            end
          end)

          Logger.notify("Disabled treesitter highlighting for ECA chat buffer", vim.log.levels.INFO)
          Logger.notify("Buffer " .. bufnr .. " highlighting disabled", vim.log.levels.INFO)
        else
          Logger.notify("No valid chat buffer found", vim.log.levels.WARN)
        end
      else
        Logger.notify("No active ECA sidebar found", vim.log.levels.WARN)
      end
    end)
  end, {
    desc = "Emergency fix for treesitter issues in ECA chat",
  })

  Logger.debug("ECA commands registered")
end

return M
