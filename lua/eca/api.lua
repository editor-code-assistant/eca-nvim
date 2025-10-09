local Utils = require("eca.utils")
local Logger = require("eca.logger")

-- Load nui.nvim components for floating windows
local Popup = require("nui.popup")

---@class eca.Api
local M = {}

---@param opts? table
function M.chat(opts)
  opts = opts or {}
  local eca = require("eca")
  eca.open_sidebar(opts)
end

function M.focus()
  local eca = require("eca")
  local sidebar = eca.get()
  if sidebar then
    sidebar:focus()
  else
    M.chat()
  end
end

function M.toggle()
  local eca = require("eca")
  return eca.toggle_sidebar()
end

function M.close()
  local eca = require("eca")
  local sidebar = eca.get()
  if sidebar then
    sidebar:new_chat() -- This will reset and force welcome content on next open
  else
    eca.close_sidebar()
  end
end

---@param message string
function M.send_message(message)
  local eca = require("eca")
  local sidebar = eca.get()
  if not sidebar or not sidebar:is_open() then
    M.chat()
    sidebar = eca.get()
  end

  if sidebar then
    sidebar:_send_message(message)
  else
    Logger.notify("Could not open ECA sidebar", vim.log.levels.ERROR)
  end
end

---@param file_path string
function M.add_file_context(file_path)
  Logger.info("Adding file context: " .. file_path)
  
  local eca = require("eca")

  if not eca.server or not eca.server:is_running() then
    Logger.notify("ECA server is not running", vim.log.levels.ERROR)
    return
  end

  -- Read file content
  local content = Utils.read_file(file_path)
  if not content then
    Logger.notify("Could not read file: " .. file_path, vim.log.levels.ERROR)
    return
  end

  -- Create context object
  local context = {
    type = "file",
    path = file_path,
    content = content,
  }

  -- Get current sidebar and add context
  local sidebar = eca.get()
  if not sidebar then
    Logger.info("Opening ECA sidebar to add context...")
    M.chat()
    sidebar = eca.get()
  end

  if sidebar then
    sidebar:add_context(context)
  else
    Logger.notify("Failed to create ECA sidebar", vim.log.levels.ERROR)
  end
end

---@param directory_path string
function M.add_directory_context(directory_path)
  Logger.info("Adding directory context: " .. directory_path)
  local eca = require("eca")

  if not eca.server or not eca.server:is_running() then
    Logger.notify("ECA server is not running", vim.log.levels.ERROR)
    return
  end

  -- Create context object for directory
  local context = {
    type = "directory",
    path = directory_path,
  }

  -- For now, store it for next message
  -- TODO: Implement context management
  Logger.debug("Directory context added: " .. directory_path)
end

function M.add_current_file_context()
  local current_file = vim.api.nvim_buf_get_name(0)
  if current_file and current_file ~= "" then
    M.add_file_context(current_file)
  else
    Logger.notify("No current file to add as context", vim.log.levels.WARN)
  end
end

function M.add_selection_context()
  -- Get visual selection marks (should be set by the command before calling this)
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  if start_pos[2] == 0 or end_pos[2] == 0 then
    Logger.notify("No selection to add as context. Please make a visual selection first.", vim.log.levels.WARN)
    return
  end

  -- Ensure we have the right line order
  local start_line = math.min(start_pos[2], end_pos[2])
  local end_line = math.max(start_pos[2], end_pos[2])

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines > 0 then
    local selection_text = table.concat(lines, "\n")
    local current_file = vim.api.nvim_buf_get_name(0)
    local context_path = current_file .. ":" .. start_line .. "-" .. end_line

    -- Create context object
    local context = {
      type = "file",
      path = context_path,
      lines_range = {
        start = start_line,
        End = end_line
      }
    }

    -- Get current sidebar and add context
    local eca = require("eca")
    local sidebar = eca.get()
    if not sidebar then
      Logger.info("Opening ECA sidebar to add context...")
      M.chat()
      sidebar = eca.get()
    end

    if sidebar then
      sidebar:add_context(context)

      -- Also set as selected code for visual display
      local selected_code = {
        filepath = current_file,
        content = selection_text,
        start_line = start_line,
        end_line = end_line,
        filetype = vim.api.nvim_get_option_value("filetype", { buf = 0 }),
      }
      sidebar:set_selected_code(selected_code)

      Logger.info("Added selection context (" .. #lines .. " lines from lines " .. start_line .. "-" .. end_line .. ")")
    else
      Logger.notify("Failed to create ECA sidebar", vim.log.levels.ERROR)
    end
  else
    Logger.notify("No lines found in selection", vim.log.levels.WARN)
  end
end

function M.list_contexts()
  local eca = require("eca")
  local sidebar = eca.get()
  if not sidebar then
    Logger.notify("No active ECA sidebar", vim.log.levels.WARN)
    return
  end

  local contexts = sidebar:get_contexts()
  if #contexts == 0 then
    Logger.notify("No active contexts", vim.log.levels.INFO)
    return
  end

  Logger.info("Active contexts (" .. #contexts .. "):")
  for i, context in ipairs(contexts) do
    local size_info = ""
    if context.content then
      local lines = vim.split(context.content, "\n")
      size_info = " (" .. #lines .. " lines)"
    end
    Logger.info(i .. ". " .. context.type .. ": " .. context.path .. size_info)
  end
end

function M.clear_contexts()
  local eca = require("eca")
  local sidebar = eca.get()
  if not sidebar then
    Logger.notify("No active ECA sidebar", vim.log.levels.WARN)
    return
  end

  sidebar:clear_contexts()
end

function M.remove_context(path)
  local eca = require("eca")
  local sidebar = eca.get()
  if not sidebar then
    Logger.notify("No active ECA sidebar", vim.log.levels.WARN)
    return
  end

  sidebar:remove_context(path)
end

function M.add_repo_map_context()
  local eca = require("eca")
  local sidebar = eca.get()
  if not sidebar then
    Logger.info("Opening ECA sidebar to add repoMap context...")
    M.chat()
    sidebar = eca.get()
  end

  if sidebar then
    -- Check if repoMap already exists
    local contexts = sidebar:get_contexts()
    for _, context in ipairs(contexts) do
      if context.type == "repoMap" then
        Logger.notify("RepoMap context already added", vim.log.levels.INFO)
        return
      end
    end

    -- Add repoMap context
    sidebar:add_context({
      type = "repoMap",
      path = "repoMap",
      content = "Repository structure and code mapping for better project understanding",
    })
    Logger.info("Added repoMap context")
  else
    Logger.notify("Failed to create ECA sidebar", vim.log.levels.ERROR)
  end
end

---@return boolean
function M.is_server_running()
  local eca = require("eca")
  return eca.server and eca.server:is_running()
end

function M.start_server()
  local eca = require("eca")
  if eca.server then
    eca.server:start()
  else
    Logger.notify("ECA server not initialized", vim.log.levels.ERROR)
  end
end

function M.stop_server()
  local eca = require("eca")
  if eca.server then
    eca.server:stop()
  end
end

function M.restart_server()
  M.stop_server()
  vim.defer_fn(function()
    M.start_server()
  end, 1000)
end

function M.server_status()
  local eca = require("eca")
  if eca.server then
    return eca.server:status()
  else
    return "Not initialized"
  end
end

-- ===== Selected Code Management =====

function M.show_selected_code()
  local eca = require("eca")
  local sidebar = eca.get()
  if sidebar then
    local selected_code = sidebar._selected_code
    if selected_code then
      Logger.notify(
        "Selected code: "
          .. selected_code.filepath
          .. " (lines "
          .. (selected_code.start_line or "?")
          .. "-"
          .. (selected_code.end_line or "?")
          .. ")",
        vim.log.levels.INFO
      )
    else
      Logger.notify("No code currently selected", vim.log.levels.INFO)
    end
  else
    Logger.notify("ECA sidebar not available", vim.log.levels.WARN)
  end
end

function M.clear_selected_code()
  local eca = require("eca")
  local sidebar = eca.get()
  if sidebar then
    sidebar:clear_selected_code()
  else
    Logger.notify("ECA sidebar not available", vim.log.levels.WARN)
  end
end

-- ===== TODOs Management =====

function M.add_todo(content)
  local eca = require("eca")
  local sidebar = eca.get()
  if not sidebar then
    Logger.info("Opening ECA sidebar to add TODO...")
    M.chat()
    sidebar = eca.get()
  end

  if sidebar then
    local todo = {
      content = content,
      status = "pending",
    }
    sidebar:add_todo(todo)
  else
    Logger.notify("Failed to create ECA sidebar", vim.log.levels.ERROR)
  end
end

function M.list_todos()
  local eca = require("eca")
  local sidebar = eca.get()
  if sidebar then
    local todos = sidebar:get_todos()
    if #todos == 0 then
      Logger.notify("No active TODOs", vim.log.levels.INFO)
      return
    end

    Logger.notify("Active TODOs:", vim.log.levels.INFO)
    for i, todo in ipairs(todos) do
      local status_icon = todo.status == "completed" and "✓" or "○"
      Logger.notify(string.format("%d. %s %s", i, status_icon, todo.content), vim.log.levels.INFO)
    end
  else
    Logger.notify("ECA sidebar not available", vim.log.levels.WARN)
  end
end

function M.toggle_todo(index)
  local eca = require("eca")
  local sidebar = eca.get()
  if sidebar then
    return sidebar:toggle_todo(index)
  else
    Logger.notify("ECA sidebar not available", vim.log.levels.WARN)
    return false
  end
end

function M.clear_todos()
  local eca = require("eca")
  local sidebar = eca.get()
  if sidebar then
    sidebar:clear_todos()
  else
    Logger.notify("ECA sidebar not available", vim.log.levels.WARN)
  end
end

-- Keep reference to logs popup globally to reuse it
local logs_popup = nil

function M.show_logs()
  -- File logging is always enabled now
  local display = Logger.get_display()
  if display == "popup" then
    M._show_logs_in_popup()
  else
    M._show_logs_in_buffer()
  end
end

--- Show logs in a regular Neovim buffer (when file logging is enabled)
function M._show_logs_in_buffer()
  local log_path = Logger.get_log_path()

  if vim.fn.filereadable(log_path) ~= 1 then
    Logger.info("Log file does not exist yet: " .. log_path)
    return
  end

  vim.cmd("edit " .. vim.fn.fnameescape(log_path))
  local bufnr = vim.fn.bufnr("%")

  -- Set buffer options for log viewing
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
  vim.cmd("normal! G")

  Logger.debug("Opened ECA log file: " .. log_path)
end

--- Show logs in a popup window
function M._show_logs_in_popup()
  local log_path = Logger.get_log_path()

  -- Helper function to read latest log content
  local function get_latest_log_content()
    if vim.fn.filereadable(log_path) == 1 then
      local content = vim.fn.readfile(log_path)
      return #content > 0 and content or { "No log entries found" }
    else
      return { "Log file does not exist yet: " .. log_path }
    end
  end

  -- Helper function to setup popup close keymaps
  local function setup_popup_keymaps(popup)
    popup:map("n", "q", function()
      popup:unmount()
    end, { noremap = true, silent = true })

    popup:map("n", "<Esc>", function()
      popup:unmount()
    end, { noremap = true, silent = true })

    -- Clean up reference when popup is closed
    popup:on("BufWinLeave", function()
      logs_popup = nil
    end)
  end

  -- Helper function to get responsive popup size
  local function get_popup_size()
    return {
      width = math.floor(vim.o.columns * 0.8),
      height = math.floor(vim.o.lines * 0.7),
    }
  end

  local function set_popup_content(popup, lines)
    vim.api.nvim_set_option_value("modifiable", true, { buf = popup.bufnr })
    vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = popup.bufnr })
    vim.api.nvim_win_set_cursor(popup.winid, { #lines, 0 })
  end

  if logs_popup and logs_popup.winid and vim.api.nvim_win_is_valid(logs_popup.winid) then
    set_popup_content(logs_popup, get_latest_log_content())
    return
  end

  logs_popup = Popup({
    enter = true,
    focusable = true,
    border = {
      style = "rounded",
      text = {
        top = " 📋 ECA Logs ",
        top_align = "center",
      },
    },
    position = "50%",
    size = get_popup_size(),
    buf_options = {
      buftype = "nofile",
      bufhidden = "hide",
      swapfile = false,
      modifiable = true,
      filetype = "log",
    },
    win_options = {
      wrap = false,
      number = true,
      signcolumn = "no",
      cursorline = true,
    },
  })
  logs_popup:mount()

  set_popup_content(logs_popup, get_latest_log_content())
  setup_popup_keymaps(logs_popup)
end

return M
