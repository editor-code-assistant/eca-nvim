local Utils = require("eca.utils")
local Logger = require("eca.logger")
local Picker = require("eca.ui.picker")

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
    Logger.notify("EcaAddFile is deprecated. Use EcaChatAddFile instead.", vim.log.levels.WARN)

    if opts.args and opts.args ~= "" and type(opts.args) == "string" then
      require("eca.api").add_file_context(vim.fn.fnamemodify(opts.args, ":p"))
    else
      require("eca.api").add_current_file_context()
    end
  end, {
    desc = "Add file as context to ECA",
    nargs = "?",
    complete = "file",
  })

  vim.api.nvim_create_user_command("EcaChatAddFile", function(opts)
    if opts.args and opts.args ~= "" and type(opts.args) == "string" then
      require("eca.api").add_file_context(vim.fn.fnamemodify(opts.args, ":p"))
    else
      require("eca.api").add_current_file_context()
    end
  end, {
    desc = "Add file as context to ECA",
    nargs = "?",
    complete = "file",
  })

  vim.api.nvim_create_user_command("EcaRemoveContext", function(opts)
    Logger.notify("EcaRemoveContext is deprecated. Use EcaChatRemoveFile instead.", vim.log.levels.WARN)

    if opts.args and opts.args ~= "" and type(opts.args) == "string" then
      require("eca.api").remove_file_context(vim.fn.fnamemodify(opts.args, ":p"))
    else
      require("eca.api").remove_current_file_context()
    end
  end, {
    desc = "Remove specific file context from ECA",
    nargs = "?",
    complete = "file",
  })

  vim.api.nvim_create_user_command("EcaChatRemoveFile", function(opts)
    if opts.args and opts.args ~= "" and type(opts.args) == "string" then
      require("eca.api").remove_file_context(vim.fn.fnamemodify(opts.args, ":p"))
    else
      require("eca.api").remove_current_file_context()
    end
  end, {
    desc = "Remove specific file context from ECA",
    nargs = "?",
    complete = "file",
  })

  vim.api.nvim_create_user_command("EcaAddSelection", function()
    Logger.notify("EcaAddSelection is deprecated. Use EcaChatAddSelection instead.", vim.log.levels.WARN)

    -- Force exit visual mode and set marks
    vim.cmd("normal! \\<Esc>")
    vim.defer_fn(function()
      require("eca.api").add_selection_context()
    end, 50) -- Small delay to ensure marks are set
  end, {
    desc = "Add current selection as context to ECA",
    range = true,
  })

  vim.api.nvim_create_user_command("EcaChatAddSelection", function()
    -- Force exit visual mode and set marks
    vim.cmd("normal! \\<Esc>")
    vim.defer_fn(function()
      require("eca.api").add_selection_context()
    end, 50) -- Small delay to ensure marks are set
  end, {
    desc = "Add current selection as context to ECA",
    range = true,
  })

  vim.api.nvim_create_user_command("EcaChatAddUrl", function()
    vim.ui.input({ prompt = "Enter URL to add as context: " }, function(input)
      if not input or input == "" then
        return
      end

      local url = vim.fn.trim(input)
      if url == "" then
        return
      end

      require("eca.api").add_web_context(url)
    end)
  end, {
    desc = "Add URL as web context to ECA",
  })

  vim.api.nvim_create_user_command("EcaListContexts", function()
    Logger.notify("EcaListContexts is deprecated. Use EcaChatListContexts instead.", vim.log.levels.WARN)

    require("eca.api").list_contexts()
  end, {
    desc = "List active contexts in ECA",
  })

  vim.api.nvim_create_user_command("EcaChatListContexts", function()
    require("eca.api").list_contexts()
  end, {
    desc = "List active contexts in ECA",
  })

  vim.api.nvim_create_user_command("EcaClearContexts", function()
    Logger.notify("EcaClearContexts is deprecated. Use EcaChatClearContexts instead.", vim.log.levels.WARN)

    require("eca.api").clear_contexts()
  end, {
    desc = "Clear all contexts from ECA",
  })

  vim.api.nvim_create_user_command("EcaChatClearContexts", function()
    require("eca.api").clear_contexts()
  end, {
    desc = "Clear all contexts from ECA",
  })

  -- ===== Server Commands =====

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
    Picker.pick(
      {
        source = "eca messages",
        finder = function(opts, _)
          local items = {}
          local eca = require("eca")
          if not eca or not eca.server then
            Logger.notify("ECA plugin is not available", vim.log.levels.ERROR)
            return items
          end

          -- First pass: collect messages so we can render them with
          -- a fixed header width and keep the separator in a constant column.
          local entries = {}

          for msg in vim.iter(eca.server.messages) do
            local ok, decoded = pcall(vim.json.decode, msg.content)
            if ok and type(decoded) == "table" then
              local parts = {}

              if msg.direction then
                table.insert(parts, string.format("[%s]", tostring(msg.direction)))
              end

              if decoded.method then
                table.insert(parts, tostring(decoded.method))
              end

              if decoded.id ~= nil then
                table.insert(parts, string.format("#%s", tostring(decoded.id)))
              end

              local header = table.concat(parts, " ")
              local preview_text = vim.inspect(decoded) or ""

              -- Flatten whitespace so searching works on a single line
              local flat_preview = ""
              if preview_text ~= "" then
                flat_preview = preview_text:gsub("%s+", " ")
              end

              local json_text = ""
              local ok_json, encoded = pcall(vim.json.encode, decoded)
              if ok_json and type(encoded) == "string" and encoded ~= "" then
                json_text = encoded
              end

              table.insert(entries, {
                header = header,
                flat_preview = flat_preview,
                preview_text = preview_text,
                json_text = json_text,
                id = decoded.id or msg.id,
              })
            end
          end

          if #entries == 0 then
            return items
          end

          -- Second pass: build display items with a fixed header width so that
          -- the separator and body always start in the same column.
          local separator = "  |  "
          local header_width = 40 -- column where the header area ends

          for idx, entry in ipairs(entries) do
            local header = entry.header or ""
            local preview_text = entry.preview_text or ""
            local flat_preview = entry.flat_preview or ""

            -- Truncate overly long headers so the separator stays fixed.
            --
            -- NOTE: We truncate to exactly `header_width` characters so that the
            -- padding logic below can reliably keep the separator aligned.
            local display_header = header
            if #display_header > header_width then
              display_header = display_header:sub(1, header_width)
            end

            -- Pad headers (or empty ones) up to header_width so the
            -- first character of the separator is always in the same column.
            local padding = math.max(0, header_width - #display_header)
            local padded_header = display_header .. string.rep(" ", padding)

            local text = padded_header
            if flat_preview ~= "" then
              text = padded_header .. separator .. flat_preview
            end

            if text == "" then
              if preview_text ~= "" then
                text = preview_text:gsub("%s+", " ")
              elseif entry.json_text and entry.json_text ~= "" then
                text = entry.json_text
              else
                text = "<empty message>"
              end
            end

            table.insert(items, {
              text = text,
              idx = entry.id or idx,
              preview = {
                text = preview_text,
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
    -- Emergency treesitter fix for chat buffer
    vim.schedule(function()
      local eca = require("eca")
      local sidebar = eca.get()
      if sidebar and sidebar.containers and sidebar.containers.chat then
        local bufnr = sidebar.containers.chat.bufnr
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

  vim.api.nvim_create_user_command("EcaChatSelectModel", function()
    local eca = require("eca")
    local chat = eca.get()

    if not chat or not chat.mediator then
      Logger.notify("No active ECA chat found", vim.log.levels.WARN)
      return
    end

    local models = chat.mediator:models()

    vim.ui.select(models, {
      prompt = "Select ECA Chat Model:",
    }, function(choice)
      if choice then
        chat.mediator:update_selected_model(choice)
        chat.mediator:send("chat/selectedModelChanged", { model = choice, variant = vim.NIL }, nil)
      end
    end)
  end, {
    desc = "Select current ECA Chat model",
  })

  vim.api.nvim_create_user_command("EcaChatSelectBehavior", function()
    local eca = require("eca")
    local chat = eca.get()

    if not chat or not chat.mediator then
      Logger.notify("No active ECA chat found", vim.log.levels.WARN)
      return
    end

    local behaviors = chat.mediator:behaviors()

    vim.ui.select(behaviors, {
      prompt = "Select ECA Chat Behavior:",
    }, function(choice)
      if choice then
        chat.mediator:update_selected_behavior(choice)
      end
    end)
  end, {
    desc = "Select current ECA Chat behavior",
  })

  vim.api.nvim_create_user_command("EcaServerTools", function()
    Picker.pick(
      {
        source = "eca tools",
        finder = function(_, _)
          local items = {}
          local eca = require("eca")
          if not eca or not eca.state then
            Logger.notify("ECA state is not available", vim.log.levels.ERROR)
            return items
          end

          local tools = eca.state.tools or {}
          if not tools or vim.tbl_isempty(tools) then
            Logger.notify("No tools registered in server state", vim.log.levels.INFO)
            return items
          end

          -- Collect and sort tool names for stable ordering
          local names = vim.tbl_keys(tools)
          table.sort(names)

          for _, name in ipairs(names) do
            local tool = tools[name] or {}

            -- Build a human-readable preview string that always includes the
            -- tool name and its primary "kind" field (when available),
            -- followed by a full vim.inspect dump for debugging.
            local preview_text
            if next(tool) ~= nil then
              local kind_value = tool.kind ~= nil and tostring(tool.kind) or "(unknown)"
              preview_text = string.format("name: %s\nkind: %s", name, kind_value)

              local inspected = vim.inspect(tool)
              if inspected and inspected ~= "" then
                preview_text = preview_text .. "\n" .. inspected
              end
            else
              preview_text = string.format("name: %s\n<empty tool>", name)
            end

            table.insert(items, {
              text = name,
              idx = name,
              preview = {
                text = preview_text,
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
    desc = "Display ECA server tools (yank preview on confirm)",
  })

  vim.api.nvim_create_user_command("EcaChatClear", function()
    local sidebar = require("eca").get()
    if sidebar then
      sidebar:clear_chat()
    end
  end, {
    desc = "Clear ECA chat buffer",
  })

  Logger.debug("ECA commands registered")
end

return M
