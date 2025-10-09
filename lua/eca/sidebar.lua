local Utils = require("eca.utils")
local Logger = require("eca.logger")
local Config = require("eca.config")

-- Load nui.nvim components (required dependency)
local Split = require("nui.split")

---@class eca.Sidebar
---@field public id integer The tab ID
---@field public containers table<string, NuiSplit> The nui containers
---@field mediator eca.Mediator mediator to send server requests to
---@field private _initialized boolean Whether the sidebar has been initialized
---@field private _current_response_buffer string Buffer for accumulating streaming response
---@field private _is_streaming boolean Whether we're currently receiving a streaming response
---@field private _last_assistant_line integer Line number of the last assistant message
---@field private _usage_info string Current usage information
---@field private _last_user_message string Last user message to avoid duplicates
---@field private _current_tool_call table Current tool call being accumulated
---@field private _is_tool_call_streaming boolean Whether we're currently receiving a streaming tool call
---@field private _force_welcome boolean Whether to force show welcome content on next open
---@field private _contexts table Active contexts for this chat session
---@field private _selected_code table Current selected code for display
---@field private _todos table List of active todos
---@field private _current_status string Current processing status message
---@field private _augroup integer Autocmd group ID
---@field private _response_start_time number Timestamp when streaming started
---@field private _max_response_length number Maximum allowed response length
---@field private _headers table Table of headers for the chat

local M = {}
M.__index = M

-- Height calculation constants
local MIN_CHAT_HEIGHT = 10 -- Minimum lines for chat container to remain usable
local WINDOW_MARGIN = 3 -- Additional margin for window borders and spacing
local UI_ELEMENTS_HEIGHT = 2 -- Reserve space for statusline and tabline
local SAFETY_MARGIN = 2 -- Extra margin to prevent "Not enough room" errors

---@param id integer Tab ID
---@param mediator eca.Mediator
---@return eca.Sidebar
function M.new(id, mediator)
  local instance = setmetatable({}, M)
  instance.id = id
  instance.mediator = mediator
  instance.containers = {}
  instance.extmarks = {}
  instance._initialized = false
  instance._current_response_buffer = ""
  instance._is_streaming = false
  instance._last_assistant_line = 0
  instance._usage_info = ""
  instance._last_user_message = ""
  instance._current_tool_call = nil
  instance._is_tool_call_streaming = false
  instance._force_welcome = false
  instance._contexts = {}
  instance._selected_code = nil
  instance._todos = {}
  instance._current_status = ""
  instance._augroup = vim.api.nvim_create_augroup("eca_sidebar_" .. id, { clear = true })
  instance._response_start_time = 0
  instance._max_response_length = 50000 -- 50KB max response
  instance._headers = {
    user = (Config.chat and Config.chat.headers and Config.chat.headers.user) or "> ",
    assistant = (Config.chat and Config.chat.headers and Config.chat.headers.assistant) or "",
  }
  instance._welcome_message_applied = false

  require("eca.observer").subscribe("sidebar-" .. id, function(message)
    instance:handle_chat_content(message)
  end)
  return instance
end

---@return boolean
function M:is_open()
  return self.containers.chat and self.containers.chat.winid and vim.api.nvim_win_is_valid(self.containers.chat.winid)
end

---@param opts? table
function M:open(opts)
  opts = opts or {}

  if self:is_open() then
    self:_focus_input()
    return
  end

  -- Clean up any invalid containers
  self:_cleanup_invalid_containers()

  -- Create/recreate containers using nui.split
  self:_create_containers()

  -- Setup containers if not initialized or if we need to refresh content
  if not self._initialized then
    Logger.debug("Setting up containers (first time)")
    self:_setup_containers()
  else
    Logger.debug("Reusing existing containers")
    self:_refresh_container_content()
  end

  -- Always focus input when opening
  self:_focus_input()

  Logger.debug("ECA sidebar opened")
end

function M:close()
  self:_close_windows_only()
end

function M:_close_windows_only()
  for name, container in pairs(self.containers) do
    if container and container.winid and vim.api.nvim_win_is_valid(container.winid) then
      container:unmount()
      -- Keep the container reference but mark window as invalid
      container.winid = nil
    end
  end
  Logger.debug("ECA sidebar windows closed")
end

function M:_close_and_cleanup()
  for name, container in pairs(self.containers) do
    if container then
      if container.winid and vim.api.nvim_win_is_valid(container.winid) then
        container:unmount()
      end
      -- Check if buffer is displayed elsewhere before deleting
      if container.bufnr and vim.api.nvim_buf_is_valid(container.bufnr) then
        local wins = vim.fn.win_findbuf(container.bufnr)
        if #wins == 0 then
          pcall(vim.api.nvim_buf_delete, container.bufnr, { force = true })
        end
      end
    end
  end
  self.containers = {}
  Logger.debug("ECA sidebar closed and cleaned up")
end

---@param opts? table
---@return boolean
function M:toggle(opts)
  if self:is_open() then
    self:close()
    return false
  else
    self:open(opts)
    return true
  end
end

function M:focus()
  if self:is_open() then
    self:_focus_input()
  else
    self:open()
  end
end

function M:resize()
  if not self:is_open() then
    return
  end

  -- Recalculate and update container sizes
  self:_update_container_sizes()
end

function M:reset()
  if self:is_open() then
    self:_close_and_cleanup()
  else
    self:_close_and_cleanup()
  end

  -- Reset all state
  self.containers = {}
  self.extmarks = {}
  self._initialized = false
  self._is_streaming = false
  self._current_response_buffer = ""
  self._last_assistant_line = 0
  self._usage_info = ""
  self._last_user_message = ""
  self._current_tool_call = nil
  self._is_tool_call_streaming = false
  self._force_welcome = false
  self._contexts = {}
  self._selected_code = nil
  self._todos = {}
  self._current_status = ""
  self._welcome_message_applied = false
end

function M:new_chat()
  self:reset()
  self._force_welcome = true
  Logger.debug("New chat initiated - will show welcome content on next open")
end

---@private
function M:_cleanup_invalid_containers()
  for name, container in pairs(self.containers) do
    if container then
      -- Check if window is still valid
      if container.winid and not vim.api.nvim_win_is_valid(container.winid) then
        container.winid = nil
      end
      -- Check if buffer is still valid
      if container.bufnr and not vim.api.nvim_buf_is_valid(container.bufnr) then
        container.bufnr = nil
      end
    end
  end
end

---@private
function M:_create_containers()
  local width = Config.get_window_width()

  -- Calculate dynamic heights using existing methods
  local input_height = Config.windows.input.height
  local usage_height = 1
  local status_height = 1
  local contexts_height = self:get_contexts_height()
  local selected_code_height = self:get_selected_code_height()
  local todos_height = self:get_todos_height()
  local original_chat_height = self:get_chat_height()
  local chat_height = original_chat_height
  local config_height = 1

  -- Validate total height to prevent "Not enough room" error
  local total_height = chat_height
    + selected_code_height
    + todos_height
    + status_height
    + contexts_height
    + input_height
    + usage_height
    + config_height

  -- Always calculate from total screen minus UI elements (more accurate than current window)
  local available_height = vim.o.lines - UI_ELEMENTS_HEIGHT

  if total_height > available_height then
    Logger.debug(
      string.format(
        "Total height (%d) exceeds available height (%d), adjusting chat height",
        total_height,
        available_height
      )
    )
    local extra_height = total_height - (available_height - SAFETY_MARGIN)
    chat_height = math.max(MIN_CHAT_HEIGHT, chat_height - extra_height)
    Logger.debug(string.format("Adjusted chat height from %d to %d", original_chat_height, chat_height))
  end

  -- Base options for all containers
  local base_buf_options = {
    buftype = "nofile",
    bufhidden = "hide",
    swapfile = false,
  }

  local base_win_options = {
    wrap = Config.windows.wrap,
    number = false,
    relativenumber = false,
    signcolumn = "no",
    foldcolumn = "0",
    cursorline = false,
    winfixheight = true,
    winfixwidth = false,
  }

  -- 1. Create and mount main chat container first
  self.containers.chat = Split({
    relative = "editor",
    position = "right",
    size = {
      width = width,
      height = chat_height,
    },
    buf_options = vim.tbl_deep_extend("force", base_buf_options, {
      modifiable = true,
      filetype = "markdown",
    }),
    win_options = base_win_options,
  })
  self.containers.chat:mount()
  self:_setup_container_events(self.containers.chat, "chat")

  -- Track the current container for hierarchical mounting with proper space management
  local current_winid = self.containers.chat.winid
  Logger.debug("Mounted container: chat (winid: " .. current_winid .. ")")

  --2. Create config container in top of chat
  self.containers.config = Split({
    relative = {
      type = "win",
      winid = current_winid,
    },
    position = "top",
    size = { height = config_height },
    buf_options = vim.tbl_deep_extend("force", base_buf_options, {
      modifiable = false,
    }),
    win_options = vim.tbl_deep_extend("force", base_win_options, {
      winhighlight = "Normal:Normal",
    }),
  })
  self.containers.config:mount()
  self:_setup_container_events(self.containers.config, "config")
  Logger.debug("Mounted container: config (winid: " .. self.containers.config.winid .. ")")

  -- 3. Create selected_code container (conditional)
  if selected_code_height > 0 then
    self.containers.selected_code = Split({
      relative = {
        type = "win",
        winid = current_winid,
      },
      position = "bottom",
      size = { height = selected_code_height },
      buf_options = vim.tbl_deep_extend("force", base_buf_options, {
        modifiable = false,
        filetype = self._selected_code and self._selected_code.filetype or "text",
      }),
      win_options = vim.tbl_deep_extend("force", base_win_options, {
        winhighlight = "Normal:Visual",
      }),
    })
    self.containers.selected_code:mount()
    self:_setup_container_events(self.containers.selected_code, "selected_code")
    current_winid = self.containers.selected_code.winid
    Logger.debug("Mounted container: selected_code (winid: " .. current_winid .. ")")
  end

  -- 4. Create todos container (conditional)
  if todos_height > 0 then
    self.containers.todos = Split({
      relative = {
        type = "win",
        winid = current_winid,
      },
      position = "bottom",
      size = { height = todos_height },
      buf_options = vim.tbl_deep_extend("force", base_buf_options, {
        modifiable = false,
      }),
      win_options = vim.tbl_deep_extend("force", base_win_options, {
        winhighlight = "Normal:DiffAdd",
      }),
    })
    self.containers.todos:mount()
    self:_setup_container_events(self.containers.todos, "todos")
    current_winid = self.containers.todos.winid
    Logger.debug("Mounted container: todos (winid: " .. current_winid .. ")")
  end

  -- 5. Create contexts container between chat and input
  self.containers.contexts = Split({
    relative = {
      type = "win",
      winid = current_winid,
    },
    position = "bottom",
    size = { height = contexts_height },
    buf_options = vim.tbl_deep_extend("force", base_buf_options, {
      modifiable = false,
    }),
    win_options = vim.tbl_deep_extend("force", base_win_options, {
      winhighlight = "Normal:Comment",
    }),
  })
  self.containers.contexts:mount()
  self:_setup_container_events(self.containers.contexts, "contexts")
  current_winid = self.containers.contexts.winid
  Logger.debug("Mounted container: contexts (winid: " .. current_winid .. ")")

  --6. Create input container (always present)
  self.containers.input = Split({
    relative = {
      type = "win",
      winid = current_winid,
    },
    position = "bottom",
    size = { height = input_height },
    buf_options = vim.tbl_deep_extend("force", base_buf_options, {
      modifiable = true,
      filetype = "eca-input",
    }),
    win_options = vim.tbl_deep_extend("force", base_win_options, {
      statusline = " ",
    }),
  })
  self.containers.input:mount()
  self:_setup_container_events(self.containers.input, "input")
  current_winid = self.containers.input.winid
  Logger.debug("Mounted container: input (winid: " .. current_winid .. ")")

  -- 7. Create usage container (always present) - moved to bottom
  self.containers.usage = Split({
    relative = {
      type = "win",
      winid = current_winid,
    },
    enter = false,
    position = "bottom",
    size = { height = usage_height },
    buf_options = vim.tbl_deep_extend("force", base_buf_options, {
      modifiable = false,
    }),
    win_options = vim.tbl_deep_extend("force", base_win_options, {
      winhighlight = "Normal:Comment",
      statusline = " ",
    }),
  })
  self.containers.usage:mount()
  self:_setup_container_events(self.containers.usage, "usage")
  Logger.debug("Mounted container: usage (winid: " .. self.containers.usage.winid .. ")")

  Logger.debug(
    string.format(
      "Created containers: contexts=%d, chat=%d, selected_code=%s, todos=%s, status=%d, input=%d, usage=%d, config=%d",
      contexts_height,
      chat_height,
      selected_code_height > 0 and tostring(selected_code_height) or "hidden",
      todos_height > 0 and tostring(todos_height) or "hidden",
      status_height,
      input_height,
      usage_height,
      config_height
    )
  )
end

---@private
---@param container NuiSplit
---@param name string
function M:_setup_container_events(container, name)
  -- Setup container-specific keymaps
  if name == "todos" then
    self:_setup_todos_keymaps(container)
  elseif name == "input" then
    self:_setup_input_keymaps(container)
  elseif name == "status" then
    -- No special keymaps for status container (read-only)
  end
end

---@private
---@param name string
function M:_handle_container_closed(name)
  -- Handle when a container window is closed
  if self.containers[name] then
    self.containers[name].winid = nil
  end
end

---@private
---@param container NuiSplit
function M:_setup_todos_keymaps(container)
  -- Setup keymaps for todos container
  container:map("n", "<Space>", function()
    local line = vim.api.nvim_win_get_cursor(container.winid)[1]
    if line > 0 then
      local header_offset = Config.windows.sidebar_header.enabled and 1 or 0
      local todo_index = line - header_offset
      if todo_index > 0 and todo_index <= #self._todos then
        self:toggle_todo(todo_index)
      end
    end
  end, { noremap = true, silent = true })

  container:map("n", "<Enter>", function()
    local line = vim.api.nvim_win_get_cursor(container.winid)[1]
    if line > 0 then
      local header_offset = Config.windows.sidebar_header.enabled and 1 or 0
      local todo_index = line - header_offset
      if todo_index > 0 and todo_index <= #self._todos then
        self:toggle_todo(todo_index)
      end
    end
  end, { noremap = true, silent = true })
end

---@private
---@param container NuiSplit
function M:_setup_input_keymaps(container)
  -- Setup keymaps for input container
  container:map("n", "<C-s>", function()
    self:_handle_input()
  end, { noremap = true, silent = true })

  container:map("i", "<C-s>", function()
    self:_handle_input()
  end, { noremap = true, silent = true })
end

---@private
function M:_update_container_sizes()
  if not self:is_open() then
    return
  end

  -- Recalculate heights
  local new_heights = {
    contexts = self:get_contexts_height(),
    chat = self:get_chat_height(),
    selected_code = self:get_selected_code_height(),
    todos = self:get_todos_height(),
    status = 1,
    input = Config.windows.input.height,
    usage = 1,
  }

  -- Update container sizes
  for name, height in pairs(new_heights) do
    local container = self.containers[name]
    if container and container.winid and vim.api.nvim_win_is_valid(container.winid) then
      if height > 0 then
        vim.api.nvim_win_set_height(container.winid, height)
      end
    end
  end
end

-- Include all the height calculation methods from the original sidebar
function M:get_selected_code_height()
  if not self._selected_code or not Config.selected_code.enabled then
    return 0
  end

  local lines = vim.split(self._selected_code.content or "", "\n")
  local content_lines = #lines
  local header_lines = Config.windows.sidebar_header.enabled and 1 or 0

  return math.min(Config.selected_code.max_height, content_lines + header_lines + 1)
end

function M:get_todos_height()
  if #self._todos == 0 or not Config.todos.enabled then
    return 0
  end

  local header_lines = Config.windows.sidebar_header.enabled and 1 or 0
  local todo_lines = math.min(#self._todos, Config.todos.max_height - header_lines)

  return math.min(Config.todos.max_height, todo_lines + header_lines)
end

function M:get_contexts_height()
  if #self._contexts == 0 then
    return 1 -- Always show at least "No contexts"
  end

  local header_lines = 1 -- "📂 Contexts (N):"
  local bubble_lines = 1 -- All bubbles on same line as requested

  return header_lines + bubble_lines
end

function M:get_chat_height()
  local total_height = vim.o.lines - vim.o.cmdheight - 1
  local input_height = Config.windows.input.height
  local usage_height = 1
  local status_height = 1
  local contexts_height = self:get_contexts_height()
  local selected_code_height = self:get_selected_code_height()
  local todos_height = self:get_todos_height()
  local config_height = 1

  return math.max(
    MIN_CHAT_HEIGHT,
    total_height
      - input_height
      - usage_height
      - status_height
      - contexts_height
      - selected_code_height
      - todos_height
      - WINDOW_MARGIN
      - config_height
  )
end

-- Include all the context/todo/selected_code management methods from original sidebar
-- (These will be copied from the original implementation)

---@param context table Context object with type, path, content
function M:add_context(context)
  -- Check if context already exists (by path)
  for i, existing in ipairs(self._contexts) do
    if existing.path == context.path then
      -- Update existing context
      self._contexts[i] = context
      self:_update_contexts_display()
      Logger.info("Updated context: " .. context.path)
      return
    end
  end

  -- Add new context
  table.insert(self._contexts, context)
  self:_update_contexts_display()
  Logger.info("Added context: " .. context.path .. " (" .. #self._contexts .. " total)")
end

---@param path string Path to remove from contexts
function M:remove_context(path)
  for i, context in ipairs(self._contexts) do
    if context.path == path then
      table.remove(self._contexts, i)
      self:_update_contexts_display()
      Logger.info("Removed context: " .. path)
      return true
    end
  end
  Logger.warn("Context not found: " .. path)
  return false
end

---@return table List of active contexts
function M:get_contexts()
  return vim.deepcopy(self._contexts)
end

---@return integer Number of active contexts
function M:get_context_count()
  return #self._contexts
end

function M:clear_contexts()
  local count = #self._contexts
  self._contexts = {}
  self:_update_contexts_display()
  Logger.info("Cleared " .. count .. " contexts")
end

---@param code table Selected code object with filepath, content, start_line, end_line
function M:set_selected_code(code)
  self._selected_code = code
  self:_update_selected_code_display()
  Logger.info("Selected code updated: " .. (code and code.filepath or "none"))
end

function M:clear_selected_code()
  self._selected_code = nil
  self:_update_selected_code_display()
  Logger.info("Selected code cleared")
end

---@param todo table Todo object with content, status ("pending", "completed")
function M:add_todo(todo)
  table.insert(self._todos, todo)
  self:_update_todos_display()
  Logger.info("Added TODO: " .. todo.content)
end

---@param index integer Index of todo to toggle
function M:toggle_todo(index)
  if index <= 0 or index > #self._todos then
    Logger.warn("Invalid TODO index: " .. index)
    return false
  end

  local todo = self._todos[index]
  todo.status = todo.status == "completed" and "pending" or "completed"
  self:_update_todos_display()
  Logger.info("Toggled TODO " .. index .. ": " .. todo.content)
  return true
end

function M:clear_todos()
  local count = #self._todos
  self._todos = {}
  self:_update_todos_display()
  Logger.info("Cleared " .. count .. " TODOs")
end

---@return table List of active todos
function M:get_todos()
  return vim.deepcopy(self._todos)
end

-- Placeholder methods for the display and setup functions
-- These will use the same logic as the original sidebar but with nui containers

function M:_setup_containers()
  -- Setup each container's content and behavior
  self:_setup_contexts_container()
  self:_setup_chat_container()

  if self.containers.selected_code then
    self:_setup_selected_code_container()
  end

  if self.containers.todos then
    self:_setup_todos_container()
  end

  self:_update_config_display()
  self:_setup_input_container()
  self:_setup_usage_container()

  self._initialized = true
end

function M:_refresh_container_content()
  -- Refresh content without full setup
  if self.containers.contexts then
    self:_update_contexts_display()
  end

  if self.containers.chat then
    self:_set_welcome_content()
  end

  if self.containers.config then
    self:_update_config_display()
  end

  if self.containers.selected_code then
    self:_update_selected_code_display()
  end

  if self.containers.todos then
    self:_update_todos_display()
  end

  if self.containers.input then
    self:_add_input_line()
  end

  if self.containers.usage then
    self:_update_usage_info()
  end
end

function M:_handle_state_updated(state)
  if state.usage or state.status then
    self:_update_usage_info()
  end

  if state.config or state.tools then
    self:_update_config_display()
    self:_update_welcome_content()
  end
end

-- Placeholder for all the other methods from original sidebar
-- (These would be copied over with minimal modifications to work with nui containers)

function M:_setup_chat_container()
  local chat = self.containers.chat
  if not chat then
    return
  end

  -- Set buffer options for chat
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = chat.bufnr })
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = chat.bufnr })
  vim.api.nvim_set_option_value("swapfile", false, { buf = chat.bufnr })
  vim.api.nvim_set_option_value("modifiable", true, { buf = chat.bufnr })

  -- Disable treesitter initially to prevent highlighting errors during setup
  vim.api.nvim_set_option_value("syntax", "off", { buf = chat.bufnr })

  -- Set initial content first
  self:_set_welcome_content()

  -- Set filetype to markdown for syntax highlighting
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(chat.bufnr) then
      vim.api.nvim_set_option_value("filetype", "markdown", { buf = chat.bufnr })
      vim.api.nvim_set_option_value("syntax", "on", { buf = chat.bufnr })
    end
  end, 200)
end

function M:_setup_selected_code_container()
  local container = self.containers.selected_code
  if not container then
    return
  end

  -- Set initial content
  self:_update_selected_code_display()

  -- Set filetype based on the selected code's language
  if self._selected_code and self._selected_code.filetype then
    vim.api.nvim_set_option_value("filetype", self._selected_code.filetype, { buf = container.bufnr })
  end
end

function M:_setup_todos_container()
  local container = self.containers.todos
  if not container then
    return
  end

  -- Set initial content
  self:_update_todos_display()
end

function M:_setup_contexts_container()
  local contexts = self.containers.contexts
  if not contexts then
    return
  end

  -- Set initial contexts display
  self:_update_contexts_display()
end

function M:_setup_usage_container()
  local usage = self.containers.usage
  if not usage then
    return
  end

  -- Set initial usage info
  self:_update_usage_info()
end

function M:_setup_input_container()
  local input = self.containers.input
  if not input then
    return
  end

  -- Set initial input prompt
  self:_add_input_line()
end

-- Placeholder methods that need to be implemented
-- (These would be copied from the original sidebar with minimal modifications)

function M:_set_welcome_content()
  -- Implementation from original sidebar
  local chat = self.containers.chat
  if not chat then
    return
  end

  -- Check if we should force welcome content (new chat)
  if not self._force_welcome then
    -- Check if buffer already has content (more than just empty lines)
    local existing_lines = vim.api.nvim_buf_get_lines(chat.bufnr, 0, -1, false)
    local has_content = false

    for _, line in ipairs(existing_lines) do
      if line:match("%S") then -- Has non-whitespace content
        has_content = true
        break
      end
    end

    -- Only set welcome content if buffer is empty or has no meaningful content
    if has_content then
      Logger.debug("Preserving existing chat content")
      return
    end
  else
    -- Force welcome content and reset the flag
    Logger.debug("Forcing welcome content for new chat")
    self._force_welcome = false
  end

  self:_update_welcome_content()

  -- Auto-add repoMap context if enabled and not already present
  if Config.options.context.auto_repo_map then
    -- Check if repoMap already exists
    local has_repo_map = false
    for _, context in ipairs(self._contexts) do
      if context.type == "repoMap" then
        has_repo_map = true
        break
      end
    end

    if not has_repo_map then
      self:add_context({
        type = "repoMap",
        path = "repoMap",
        content = "Repository structure and code mapping for better project understanding",
      })
      Logger.debug("Auto-added repoMap context on welcome")
    end
  end
end

function M:_add_input_line()
  return vim.schedule(function()
    local input = self.containers.input
    if not input then
      return
    end

    local prefix = Config.windows.input.prefix or "> "
    vim.api.nvim_buf_set_lines(input.bufnr, 0, -1, false, { prefix })

    -- Set cursor to end of line
    if vim.api.nvim_win_is_valid(input.winid) then
      vim.api.nvim_win_set_cursor(input.winid, { 1, #prefix })
    end
  end)
end

function M:_focus_input()
  local input = self.containers.input
  if not input or not vim.api.nvim_win_is_valid(input.winid) then
    Logger.notify("Cannot focus input: invalid window", vim.log.levels.ERROR)
    return
  end

  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(input.winid) and vim.api.nvim_buf_is_valid(input.bufnr) then
      vim.api.nvim_set_current_win(input.winid)

      local lines = vim.api.nvim_buf_get_lines(input.bufnr, 0, -1, false)
      local prefix = Config.windows.input.prefix or "> "

      if #lines > 0 then
        local first_line = lines[1] or ""
        local cursor_col = math.max(#prefix, #first_line)
        vim.api.nvim_win_set_cursor(input.winid, { 1, cursor_col })
      else
        self:_add_input_line()
      end

      -- Enter insert mode
      local mode = vim.api.nvim_get_mode().mode
      if mode == "n" then
        vim.cmd("startinsert!")
      end
    end
  end, 50)
end

function M:_handle_input()
  local input = self.containers.input
  if not input then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(input.bufnr, 0, -1, false)
  if #lines == 0 then
    return
  end

  -- Process input (remove prefix, concatenate lines)
  local message_lines = {}
  local prefix = Config.windows.input.prefix or "> "

  for _, line in ipairs(lines) do
    local content = line
    if vim.startswith(line, prefix) then
      content = line:sub(#prefix + 1)
    end
    if content ~= "" then
      table.insert(message_lines, content)
    end
  end

  local message = table.concat(message_lines, "\n")
  if message == "" then
    return
  end

  -- Clear input
  vim.api.nvim_buf_set_lines(input.bufnr, 0, -1, false, {})

  -- Send message
  self:_send_message(message)

  -- Add new input line and focus
  self:_add_input_line()
  self:_focus_input()
end

-- Placeholder for the other display update methods
function M:_update_selected_code_display()
  -- Implementation would be similar to original but use nui container
  local container = self.containers.selected_code
  if not container or not vim.api.nvim_buf_is_valid(container.bufnr) then
    return
  end

  local lines = {}

  if not self._selected_code then
    lines = { "📝 No code selected" }
  else
    -- Add header if enabled
    local filename = vim.fn.fnamemodify(self._selected_code.filepath or "unknown", ":t")
    local line_info = ""
    if self._selected_code.start_line and self._selected_code.end_line then
      line_info = string.format(" (lines %d-%d)", self._selected_code.start_line, self._selected_code.end_line)
    end
    local header_text = "📝 " .. filename .. line_info
    local header_lines = self:_render_header("selected_code", header_text)
    for _, line in ipairs(header_lines) do
      table.insert(lines, line)
    end

    -- Add code content
    local code_lines = vim.split(self._selected_code.content or "", "\n")
    for _, line in ipairs(code_lines) do
      table.insert(lines, line)
    end
  end

  -- Update the buffer
  vim.api.nvim_set_option_value("modifiable", true, { buf = container.bufnr })
  vim.api.nvim_buf_set_lines(container.bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = container.bufnr })
end

function M:_update_todos_display()
  -- Similar implementation for todos...
  local container = self.containers.todos
  if not container or not vim.api.nvim_buf_is_valid(container.bufnr) then
    return
  end

  local lines = {}

  if #self._todos == 0 then
    lines = { "✅ No active TODOs" }
  else
    -- Add header if enabled
    local completed_count = 0
    for _, todo in ipairs(self._todos) do
      if todo.status == "completed" then
        completed_count = completed_count + 1
      end
    end
    local header_text = string.format("✅ Tasks (%d/%d completed)", completed_count, #self._todos)
    local header_lines = self:_render_header("todos", header_text)
    for _, line in ipairs(header_lines) do
      table.insert(lines, line)
    end

    -- Add todos
    for i, todo in ipairs(self._todos) do
      local checkbox = todo.status == "completed" and "[x]" or "[ ]"
      local line = string.format("%d. %s %s", i, checkbox, todo.content)
      table.insert(lines, line)
    end
  end

  -- Update the buffer
  vim.api.nvim_set_option_value("modifiable", true, { buf = container.bufnr })
  vim.api.nvim_buf_set_lines(container.bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = container.bufnr })
end

function M:_update_config_display()
  local config = self.containers.config
  if not config or not config.bufnr or not vim.api.nvim_buf_is_valid(config.bufnr) then
    return
  end

  local model = self.mediator:selected_model() or "unknown"
  local behavior = self.mediator:selected_behavior() or "unknown"
  local mcps = self.mediator:mcps()

  local mcps_hl = "Normal"

  for _, mcp in pairs(mcps) do
    if mcp.status == "starting" then
      mcps_hl = "Comment"
      break
    end

    if mcp.status == "failed" then
      mcps_hl = "Exception"
      break
    end
  end

  local texts = {
    { "model:",    "Comment" }, { model, "Normal" }, { "\t" },
    { "behavior:", "Comment" }, { behavior, "Normal" }, { " " },
    { "mcps:", "Comment" }, { tostring(vim.tbl_count(mcps)), mcps_hl },
  }

  local virt_opts = { virt_text = texts, hl_mode = "combine" }

  self.extmarks = self.extmarks or {}

  if not self.extmarks.config then
    self.extmarks.config = {
      _ns = vim.api.nvim_create_namespace('extmarks_config'),
    }
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = config.bufnr })
  vim.api.nvim_buf_set_lines(config.bufnr, 0, -1, false, { "" })
  vim.api.nvim_set_option_value("modifiable", false, { buf = config.bufnr })

  self.extmarks.config._id = vim.api.nvim_buf_set_extmark(
    config.bufnr,
    self.extmarks.config._ns,
    0,
    -1,
    vim.tbl_extend("force", virt_opts, { id = self.extmarks.config._id })
  )
end

function M:_update_contexts_display()
  -- Similar implementation for contexts...
  local contexts = self.containers.contexts
  if not contexts or not vim.api.nvim_buf_is_valid(contexts.bufnr) then
    return
  end

  local lines = {}

  if #self._contexts > 0 then
    -- Create context references with @ prefix (eca-emacs style)
    local context_refs = {}

    for i, context in ipairs(self._contexts) do
      local name = context.type == "repoMap" and "repoMap" or vim.fn.fnamemodify(context.path, ":t") -- Get filename only

      -- Create context reference with @ prefix like eca-emacs
      local ref = "@" .. name
      table.insert(context_refs, ref)
    end

    -- Add all context references to a single line
    local contexts_line = table.concat(context_refs, " ")
    table.insert(lines, contexts_line)
  end

  -- Update the buffer
  vim.api.nvim_set_option_value("modifiable", true, { buf = contexts.bufnr })
  vim.api.nvim_buf_set_lines(contexts.bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = contexts.bufnr })
end

function M:_update_usage_info()
  local usage = self.containers.usage
  if not usage or not usage.bufnr or not vim.api.nvim_buf_is_valid(usage.bufnr) then
    return
  end

  local status_state = self.mediator:status_state()
  local status_text = self.mediator:status_text()

  if status_state == "finished" then
    status_text = "Idle"
  end

  local tokens = self.mediator:tokens_session() or 0
  local limit = self.mediator:tokens_limit() or 0
  local costs = self.mediator:costs_session() or "0.00"

  self._current_status = string.format("%s", status_text)
  self._usage_info = string.format("%d / %d (%s)", tokens, limit, costs)

  self.extmarks = self.extmarks or {}

  if not self.extmarks.usage then
    self.extmarks.usage = {
      _ns = vim.api.nvim_create_namespace('extmarks_usage'),
    }
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = usage.bufnr })
  vim.api.nvim_buf_set_lines(usage.bufnr, 0, -1, false, { "" })
  vim.api.nvim_set_option_value("modifiable", false, { buf = usage.bufnr })

  self.extmarks.usage._id_status = vim.api.nvim_buf_set_extmark(
    usage.bufnr,
    self.extmarks.usage._ns,
    0,
    -1,
    vim.tbl_extend("force",
      {
        virt_text = { { self._current_status, (status_text ~= "Idle") and "WarningMsg" or "Normal" } },
        virt_text_pos = 'eol',
        hl_mode = 'combine',
      },
      { id = self.extmarks.usage._id_status })
  )

  self.extmarks.usage._id_usage = vim.api.nvim_buf_set_extmark(
    usage.bufnr,
    self.extmarks.usage._ns,
    0,
    -1,
    vim.tbl_extend("force",
      {
        virt_text = { { self._usage_info } },
        virt_text_pos = 'right_align',
        hl_mode = 'combine',
      },
      { id = self.extmarks.usage._id_usage })
  )
end

function M:_update_welcome_content()
  if self._welcome_applied then
    return
  end

  local chat = self.containers.chat
  if not chat or not vim.api.nvim_buf_is_valid(chat.bufnr) then
    return
  end

  local cfg = (Config.chat and Config.chat.welcome) or {}
  local cfg_msg = (cfg.message and cfg.message ~= "" and cfg.message) or nil
  local welcome_message = cfg_msg or (self.mediator and self.mediator:welcome_message() or nil)

  local lines = { "Waiting for welcome message from ECA server..." }

  if welcome_message and welcome_message ~= "" then
    lines = Utils.split_lines(welcome_message)

    local tips = cfg.tips or {}

    if #tips > 0 then
      for _, tip in ipairs(tips) do
        table.insert(lines, tip)
      end
    end

    self._welcome_applied = true
  end

  table.insert(lines, "")
  Logger.debug("Setting welcome content for chat (welcome applied: " .. tostring(self._welcome_applied) .. ")")
  vim.api.nvim_buf_set_lines(chat.bufnr, 0, -1, false, lines)
end

function M:_render_header(container_name, header_text)
  if not Config.windows.sidebar_header.enabled then
    return {}
  end

  local align = Config.windows.sidebar_header.align or "center"
  local rounded = Config.windows.sidebar_header.rounded

  if rounded then
    header_text = "『" .. header_text .. "』"
  else
    header_text = " " .. header_text .. " "
  end

  return { header_text }
end

-- ===== Message handling methods (copied from original sidebar) =====

---@param message string
function M:_send_message(message)
  Logger.debug("Sending message: " .. message)

  -- Store the last user message to avoid duplication
  self._last_user_message = message

  -- Add user message to chat
  self:_add_message("user", message)

  local contexts = self:get_contexts()
  self.mediator:send("chat/prompt", {
    chatId = self.id,
    requestId = tostring(os.time()),
    message = message,
    contexts = contexts or {},
  }, function(err, result)
    if err then
      print("err is " .. err)
      Logger.error("Failed to send message to ECA server: " .. err)
      self:_add_message("assistant", "❌ **Error**: Failed to send message to ECA server: " .. err)
      return
    end
    -- Response will come through server notification handler
    self:_add_input_line()

    self:handle_chat_content_received(result.params)
  end)
end

function M:handle_chat_content(message)
  if message.params then
    self:handle_chat_content_received(message.params)
  end

  if message.type == "state/updated" then
    self:_handle_state_updated(message.content)
  end
end

---@param params table Server content notification
function M:handle_chat_content_received(params)
  if not params or not params.content then
    return
  end

  local content = params.content
  local chat_id = params.chatId

  if content.type == "text" then
    -- Handle streaming text content
    self:_handle_streaming_text(content.text)
  elseif content.type == "progress" then
    if content.state == "finished" then
      self:_finalize_streaming_response()
      self:_add_input_line()
    end
  elseif content.type == "toolCallPrepare" then
    self:_finalize_streaming_response()
    self:_handle_tool_call_prepare(content)
    -- IMPORTANT: Return immediately - do NOT display anything for toolCallPrepare
    return
  elseif content.type == "toolCallRun" then
    self:render_tool_call(content, chat_id)
  elseif content.type == "toolCallRunning" then
    -- Show the accumulated tool call
    self:_display_tool_call(content)
  elseif content.type == "toolCalled" then
    local tool_text = (content.summary or "Tool call")

    -- Add diff to current tool call if present in toolCalled content
    if self._current_tool_call and content.details then
      self._current_tool_call.details = content.details
    end

    -- Show the tool result
    local tool_log = string.format("**Tool Result**: %s", content.name or "unknown")
    if content.outputs and #content.outputs > 0 then
      for _, output in ipairs(content.outputs) do
        if output.type == "text" and output.content then
          tool_log = tool_log .. "\n" .. output.content
        end
      end
    end
    Logger.debug(tool_log)

    local tool_text_completed = "✅ "

    if content.error then
      tool_text_completed = "❌ "
    end

    local tool_text_running = "🔧 " .. tool_text
    tool_text_completed = tool_text_completed .. tool_text

    if tool_text == nil or not self:_replace_text(tool_text_running, tool_text_completed) then
      self:_add_message("assistant", tool_text_completed)
    end

    -- Clean up tool call state
    self:_finalize_tool_call()
  end
end

function M:render_tool_call(tool_content, chat_id)
  if tool_content.type == "toolCallRun" and tool_content.manualApproval then
    return require("eca.approve").approve_tool_call(tool_content, function()
      self.mediator:send("chat/toolCallApprove", { chatId = chat_id, toolCallId = tool_content.id }, nil)
    end, function()
      self.mediator:send("chat/toolCallReject", { chatId = chat_id, toolCallId = tool_content.id }, nil)
    end)
  end
end

---@param text string
function M:_handle_streaming_text(text)
  -- Only check for empty text
  if not text or text == "" then
    Logger.debug("Ignoring empty text response")
    return
  end
  Logger.debug("Received text chunk: '" .. text:sub(1, 50) .. (text:len() > 50 and "..." or "") .. "'")

  if vim.trim(text) == vim.trim(self._last_user_message) then
    Logger.debug("Ignoring duplicate user message in response")
    return
  end

  if not self._is_streaming then
    Logger.debug("Starting streaming response")
    -- Start streaming - simple and direct
    self._is_streaming = true
    self._current_response_buffer = ""

    -- Determine insertion point before adding placeholder (works even with empty header)
    local chat = self.containers.chat
    local start_line = 1
    if chat and vim.api.nvim_buf_is_valid(chat.bufnr) then
      start_line = vim.api.nvim_buf_line_count(chat.bufnr) + 1
    end

    -- Add assistant placeholder and track its start line
    self:_add_message("assistant", "")
    self._last_assistant_line = start_line

    -- Track placeholder with an extmark independent of header content
    self.extmarks = self.extmarks or {}
    if not self.extmarks.assistant then
      self.extmarks.assistant = { _ns = vim.api.nvim_create_namespace('extmarks_assistant') }
    end
    if chat and vim.api.nvim_buf_is_valid(chat.bufnr) then
      self.extmarks.assistant._id = vim.api.nvim_buf_set_extmark(
        chat.bufnr,
        self.extmarks.assistant._ns,
        start_line - 1,
        0,
        { id = self.extmarks.assistant._id }
      )
    end
  end

  -- Simple accumulation - no complex checks
  self._current_response_buffer = (self._current_response_buffer or "") .. text

  Logger.debug("DEBUG: Buffer now has " .. #self._current_response_buffer .. " chars")

  -- Update the assistant's message in place
  self:_update_streaming_message(self._current_response_buffer)
end

---@param content string
function M:_update_streaming_message(content)
  local chat = self.containers.chat
  if not chat or self._last_assistant_line == 0 then
    Logger.notify("Cannot update - no chat or no assistant line", vim.log.levels.ERROR)
    return
  end

  Logger.debug("DEBUG: Updating streaming message with " .. #content .. " chars")

  if not vim.api.nvim_buf_is_valid(chat.bufnr) then
    Logger.notify("Invalid buffer, cannot update", vim.log.levels.ERROR)
    return
  end

  -- Simple and direct buffer update
  local success, err = pcall(function()
    -- Make buffer modifiable
    vim.api.nvim_set_option_value("modifiable", true, { buf = chat.bufnr })

    -- Concat content with header
    content = self._headers.assistant .. content

    -- Get current lines
    local lines = vim.api.nvim_buf_get_lines(chat.bufnr, 0, -1, false)
    local content_lines = Utils.split_lines(content)

    -- Resolve assistant start line using extmark if available
    local start_line = self._last_assistant_line
    if self.extmarks and self.extmarks.assistant and self.extmarks.assistant._id then
      local pos = vim.api.nvim_buf_get_extmark_by_id(chat.bufnr, self.extmarks.assistant._ns, self.extmarks.assistant._id, {})
      if pos and pos[1] then
        start_line = pos[1] + 1
      end
    end

    Logger.debug("DEBUG: Assistant line: " .. tostring(self._last_assistant_line) .. ", start_line: " .. tostring(start_line))
    Logger.debug("DEBUG: Content lines: " .. #content_lines)

    -- Replace assistant content directly
    local new_lines = {}

    -- Keep everything before assistant response
    for i = 1, start_line - 1 do
      table.insert(new_lines, lines[i] or "")
    end

    -- Add new content
    for _, line in ipairs(content_lines) do
      table.insert(new_lines, line)
    end

    -- Add empty line after content
    table.insert(new_lines, "")

    -- Set all lines at once
    vim.api.nvim_buf_set_lines(chat.bufnr, 0, -1, false, new_lines)

    -- Re-anchor the assistant extmark at the start line (for subsequent updates)
    self.extmarks = self.extmarks or {}
    if not self.extmarks.assistant then
      self.extmarks.assistant = { _ns = vim.api.nvim_create_namespace('extmarks_assistant') }
    end
    self.extmarks.assistant._id = vim.api.nvim_buf_set_extmark(
      chat.bufnr,
      self.extmarks.assistant._ns,
      start_line - 1,
      0,
      { id = self.extmarks.assistant._id }
    )

    Logger.debug("DEBUG: Buffer updated successfully with " .. #new_lines .. " total lines")
  end)

  if not success then
    Logger.notify("Error updating buffer: " .. tostring(err), vim.log.levels.ERROR)
  else
    -- Auto-scroll to bottom during streaming to follow the text
    self:_scroll_to_bottom()
  end
end

---@param role string
---@param content string
function M:_add_message(role, content)
  local chat = self.containers.chat
  if not chat then
    return
  end

  self:_safe_buffer_update(chat.bufnr, function()
    local lines = vim.api.nvim_buf_get_lines(chat.bufnr, 0, -1, false)
    local header = ""

    if role == "user" then
      header = self._headers.user
    elseif role == "assistant" then
      header = self._headers.assistant
    end

    -- Concat header and content
    content = header .. content

    -- Add content with better markdown formatting
    local content_lines = Utils.split_lines(content)

    -- Check if content looks like code (starts with common programming patterns)
    local is_code = content:match("^%s*function")
      or content:match("^%s*class")
      or content:match("^%s*def ")
      or content:match("^%s*import")
      or content:match("^%s*#include")
      or content:match("^%s*<%?")
      or content:match("^%s*<html")

    if is_code then
      -- Wrap in code block with auto-detection
      table.insert(lines, "```")
      for _, line in ipairs(content_lines) do
        table.insert(lines, line)
      end
      table.insert(lines, "```")
    else
      -- Regular text content
      for _, line in ipairs(content_lines) do
        table.insert(lines, line)
      end
    end

    if content ~= "" then
      table.insert(lines, "")
    end

    -- Update buffer safely
    vim.api.nvim_buf_set_lines(chat.bufnr, 0, -1, false, lines)

    -- Auto-scroll to bottom after adding new message
    self:_scroll_to_bottom()
  end)
  self._last_assistant_line = self:_get_last_message_line()
end

function M:_finalize_streaming_response()
  if self._is_streaming then
    Logger.debug("DEBUG: Finalizing streaming response")
    Logger.debug("DEBUG: Final buffer had " .. #(self._current_response_buffer or "") .. " chars")

    self._is_streaming = false
    self._current_response_buffer = ""
    self._last_assistant_line = 0
    self._response_start_time = 0

    -- Clear assistant placeholder tracking extmark
    local chat = self.containers.chat
    if chat and vim.api.nvim_buf_is_valid(chat.bufnr) and self.extmarks and self.extmarks.assistant then
      pcall(vim.api.nvim_buf_clear_namespace, chat.bufnr, self.extmarks.assistant._ns, 0, -1)
      self.extmarks.assistant._id = nil
    end

    Logger.debug("DEBUG: Streaming state cleared")
  else
    Logger.debug("DEBUG: _finalize_streaming_response called but not streaming")
  end
end

---Auto-scroll to bottom of the chat
function M:_scroll_to_bottom()
  local chat = self.containers.chat
  if not chat or not vim.api.nvim_win_is_valid(chat.winid) then
    return
  end

  -- Get total number of lines in buffer
  local line_count = vim.api.nvim_buf_line_count(chat.bufnr)

  -- Set cursor to the last line and scroll to bottom
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(chat.winid) and vim.api.nvim_buf_is_valid(chat.bufnr) then
      -- Refresh line count in case it changed
      local current_line_count = vim.api.nvim_buf_line_count(chat.bufnr)
      -- Set cursor to last line
      vim.api.nvim_win_set_cursor(chat.winid, { current_line_count, 0 })
      -- Ensure the last line is visible
      vim.api.nvim_win_call(chat.winid, function()
        vim.cmd("normal! zb") -- scroll so cursor line is at bottom of window
      end)
    end
  end, 10) -- Reduced delay for faster streaming response
end

function M:_get_last_message_line()
  local chat = self.containers.chat
  if not chat then
    return 0
  end

  local lines = vim.api.nvim_buf_get_lines(chat.bufnr, 0, -1, false)
  local assistant_header_lines = Utils.split_lines(self._headers.assistant)
  local assistant_header = ""

  for i = #assistant_header_lines, 1, -1 do
    if assistant_header_lines[i] and assistant_header_lines[i] ~= "" then
      assistant_header = assistant_header_lines[i]
      break
    end
  end

  for i = #lines, 1, -1 do
    local line = lines[i]
    if line and line:sub(1, #assistant_header) == assistant_header then
      return i
    end
  end
  return 0
end

---@param bufnr integer
---@param callback function
function M:_safe_buffer_update(bufnr, callback)
  -- if not vim.api.nvim_buf_s_valid(bufnr) then
  --   return
  -- end
  --
  -- -- Simple but effective approach: disable highlighting during updates
  -- local original_eventignore = vim.o.eventignore
  -- local original_syntax = vim.api.nvim_get_option_value("syntax", { buf = bufnr })
  -- local original_modifiable = vim.api.nvim_get_option_value("modifiable", { buf = bufnr })
  --
  -- -- Temporarily disable events and highlighting to prevent treesitter issues
  -- vim.o.eventignore = "all"
  -- pcall(vim.api.nvim_set_option_value, "syntax", "off", { buf = bufnr })
  -- pcall(vim.api.nvim_set_option_value, "modifiable", true, { buf = bufnr })
  --
  -- -- Disable treesitter highlighting for this buffer temporarily
  -- pcall(function()
  --   if vim.treesitter.highlighter.active[bufnr] then
  --     Logger.debug("Temporarily disabling treesitter for buffer " .. bufnr)
  --     vim.treesitter.highlighter.active[bufnr]:destroy()
  --     vim.treesitter.highlighter.active[bufnr] = nil
  --   end
  -- end)
  --
  -- -- Execute the buffer update with maximum protection
  local success, err = pcall(callback)
  if not success then
    Logger.notify("Buffer update failed: " .. tostring(err), vim.log.levels.ERROR)
  end

  -- -- Restore original state immediately (no delay for critical settings)
  -- vim.o.eventignore = original_eventignore
  -- pcall(vim.api.nvim_set_option_value, "modifiable", original_modifiable, { buf = bufnr })
  --
  -- -- Re-enable highlighting with a delay to prevent conflicts
  -- vim.defer_fn(function()
  --   if vim.api.nvim_buf_is_valid(bufnr) then
  --     -- Restore syntax highlighting
  --     if original_syntax and original_syntax ~= "off" then
  --       pcall(vim.api.nvim_set_option_value, "syntax", original_syntax, { buf = bufnr })
  --     end
  --
  --     -- Re-initialize treesitter highlighting carefully
  --     pcall(function()
  --       local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  --       if ok and parser then
  --         -- Only create highlighter if one doesn't exist and buffer is still valid
  --         if not vim.treesitter.highlighter.active[bufnr] and vim.api.nvim_buf_is_valid(bufnr) then
  --           Logger.debug("Re-enabling treesitter for buffer " .. bufnr)
  --           vim.treesitter.highlighter.new(parser, {})
  --         end
  --       else
  --         Logger.debug("No treesitter parser available for buffer " .. bufnr)
  --       end
  --     end)
  --   end
  -- end, 200) -- Longer delay to ensure stability
end

-- ===== Tool call handling methods =====

function M:_handle_tool_call_prepare(content)
  if not self._is_tool_call_streaming then
    self._is_tool_call_streaming = true
    self._current_tool_call = {
      name = "",
      summary = "",
      arguments = "",
      details = {},
    }
  end

  -- Accumulate tool call data
  if content.name then
    self._current_tool_call.name = content.name
  end

  if content.summary then
    self._current_tool_call.summary = content.summary
  end

  if content.argumentsText then
    self._current_tool_call.arguments = (self._current_tool_call.arguments or "") .. content.argumentsText
  end

  if content.details then
    self._current_tool_call.details = content.details
  end
end

function M:_display_tool_call(content)
  if not self._is_tool_call_streaming or not self._current_tool_call then
    return nil
  end

  local diff = ""
  local tool_text = "🔧 " .. (content.summary or self._current_tool_call.summary or "Tool call")
  local tool_log = string.format("**Tool Call**: %s", self._current_tool_call.name or "unknown")

  if self._current_tool_call.arguments and self._current_tool_call.arguments ~= "" then
    tool_log = tool_log .. "\n```json\n" .. self._current_tool_call.arguments .. "\n```"
  end

  if self._current_tool_call.details and self._current_tool_call.details.diff then
    diff = "\n\n**Diff**:\n```diff\n" .. self._current_tool_call.details.diff .. "\n```"
  end

  Logger.debug(tool_log .. diff)
  self:_add_message("assistant", tool_text .. diff)
end

function M:_finalize_tool_call()
  self._current_tool_call = nil
  self._is_tool_call_streaming = false
end

---@param target string
---@param replacement string
---@param opts? table|nil Optional search options: { max_search_lines = number, start_line = number }
---@return boolean changed True if any replacement was made
function M:_replace_text(target, replacement, opts)
  local chat = self.containers.chat

  if not chat or not vim.api.nvim_buf_is_valid(chat.bufnr) then
    Logger.warn("Cannot replace message: chat buffer not available")
    return false
  end

  if not target or target == "" then
    Logger.warn("Cannot replace message: empty target")
    return false
  end

  if not replacement or replacement == "" then
    Logger.warn("Cannot replace message: empty replacement")
    return false
  end

  local changed = false

  self:_safe_buffer_update(chat.bufnr, function()
    local total_lines = vim.api.nvim_buf_line_count(chat.bufnr)
    opts = opts or {}

    -- Limit how many lines to search for performance with large buffers
    local max_search_lines = tonumber(opts.max_search_lines) or 500

    -- If a start line is provided, start searching from there (useful for targeted replacement)
    local start_line = tonumber(opts.start_line) or total_lines
    if start_line < 1 then
      start_line = 1
    end
    if start_line > total_lines then
      start_line = total_lines
    end

    -- Determine the search window [end_line, start_line]
    local end_line = math.max(1, start_line - max_search_lines + 1)

    -- Fetch only the relevant range once (0-based indices for nvim API)
    local range_lines = vim.api.nvim_buf_get_lines(chat.bufnr, end_line - 1, start_line, false)

    -- Iterate from bottom to top within the range
    for idx = #range_lines, 1, -1 do
      local line = range_lines[idx] or ""
      local s_idx, e_idx = line:find(target, 1, true)
      if s_idx then
        local new_line = (line:sub(1, s_idx - 1)) .. replacement .. (line:sub(e_idx + 1))
        local absolute_line = end_line + idx - 1 -- convert to absolute 1-based line
        vim.api.nvim_buf_set_lines(chat.bufnr, absolute_line - 1, absolute_line, false, { new_line })
        changed = true
        break
      end
    end
  end)

  return changed
end

return M
