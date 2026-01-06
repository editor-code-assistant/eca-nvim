local Utils = require("eca.utils")
local Logger = require("eca.logger")
local Config = require("eca.config")
local StreamQueue = require("eca.stream_queue")

-- Load nui.nvim components (required dependency)
local Split = require("nui.split")

---@class eca.Sidebar
---@field public id integer The tab ID
---@field public containers table<string, NuiSplit> The nui containers
---@field public extmarks table The extmarks for various UI elements
---@field mediator eca.Mediator mediator to send server requests to
---@field private _initialized boolean Whether the sidebar has been initialized
---@field private _current_response_buffer string Buffer for accumulating streaming response
---@field private _is_streaming boolean Whether we're currently receiving a streaming response
---@field private _usage_info string Current usage information
---@field private _last_user_message string Last user message to avoid duplicates
---@field private _current_tool_call table Current tool call being accumulated
---@field private _is_tool_call_streaming boolean Whether we're currently receiving a streaming tool call
---@field private _force_welcome boolean Whether to force show welcome content on next open
---@field private _current_status string Current processing status message
---@field private _augroup integer Autocmd group ID
---@field private _response_start_time number Timestamp when streaming started
---@field private _max_response_length number Maximum allowed response length
---@field private _headers table Table of headers for the chat
---@field private _welcome_message_applied boolean Whether the welcome message has been applied
---@field private _contexts_placeholder_line string Placeholder line for contexts in input
---@field private _reasons table Map of in-flight reasoning entries keyed by id
---@field private _stream_queue eca.StreamQueue Queue for streaming text display
---@field private _stream_visible_buffer string Accumulated visible text during streaming

local M = {}
M.__index = M

-- Height calculation constants
local MIN_CHAT_HEIGHT = 10 -- Minimum lines for chat container to remain usable
local WINDOW_MARGIN = 3 -- Additional margin for window borders and spacing
local UI_ELEMENTS_HEIGHT = 2 -- Reserve space for statusline and tabline
local SAFETY_MARGIN = 2 -- Extra margin to prevent "Not enough room" errors

local function _format_usage(tokens, limit, costs)
  local usage_cfg = (Config.windows and Config.windows.usage) or {}
  local fmt = usage_cfg.format
    or Config.usage_string_format -- backwards compatibility
    or "{session_tokens_short} / {limit_tokens_short} (${session_cost})"

  local placeholders = {
    session_tokens = tostring(tokens or 0),
    limit_tokens = tostring(limit or 0),
    session_tokens_short = Utils.shorten_tokens(tokens),
    limit_tokens_short = Utils.shorten_tokens(limit),
    session_cost = tostring(costs or "0.00"),
  }

  local result = fmt:gsub("{(.-)}", function(key)
    return placeholders[key] or ""
  end)

  return result
end

---@param id integer Tab ID
---@param mediator eca.Mediator
---@return eca.Sidebar
function M.new(id, mediator)
  local chat_cfg = Utils.get_chat_config()
  local instance = setmetatable({}, M)
  instance.id = id
  instance.mediator = mediator
  instance.containers = {}
  instance.extmarks = {}
  instance._initialized = false
  instance._current_response_buffer = ""
  instance._is_streaming = false
  instance._usage_info = ""
  instance._last_user_message = ""
  instance._current_tool_call = nil
  instance._is_tool_call_streaming = false
  instance._force_welcome = false
  instance._current_status = ""
  instance._augroup = vim.api.nvim_create_augroup("eca_sidebar_" .. id, { clear = true })
  instance._response_start_time = 0
  instance._max_response_length = 50000 -- 50KB max response
  instance._headers = {
    user = (chat_cfg.headers and chat_cfg.headers.user) or "> ",
    assistant = (chat_cfg.headers and chat_cfg.headers.assistant) or "",
  }
  instance._welcome_message_applied = false
  instance._contexts_placeholder_line = ""
  instance._contexts = {}
  instance._tool_calls = {}
  instance._reasons = {}
  instance._stream_visible_buffer = ""

  -- Get typing configuration
  local typing_cfg = chat_cfg.typing or {}
  local typing_enabled = typing_cfg.enabled ~= false  -- Default to true
  local chars_per_tick = typing_enabled and (typing_cfg.chars_per_tick or 1) or 1000  -- Large number = instant
  local tick_delay = typing_enabled and (typing_cfg.tick_delay or 10) or 0

  -- Initialize stream queue with callback to update display
  instance._stream_queue = StreamQueue.new(function(chunk, is_complete)
    instance._stream_visible_buffer = (instance._stream_visible_buffer or "") .. chunk
    instance:_update_streaming_message(instance._stream_visible_buffer)
  end, {
    chars_per_tick = chars_per_tick,
    tick_delay = tick_delay,
    should_continue = function()
      return instance._is_streaming
    end,
  })

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
  self._usage_info = ""
  self._last_user_message = ""
  self._current_tool_call = nil
  self._is_tool_call_streaming = false
  self._force_welcome = false
  self._current_status = ""
  self._welcome_message_applied = false
  self._contexts_placeholder_line = ""
  self._contexts = {}
  self._tool_calls = {}
  self._reasons = {}
  self._stream_visible_buffer = ""
  if self._stream_queue then
    self._stream_queue:clear()
  end
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
  local original_chat_height = self:get_chat_height()
  local chat_height = original_chat_height
  local config_height = 1

  -- Validate total height to prevent "Not enough room" error
  local total_height = chat_height
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

  --  Create and mount main chat container first
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

  -- Create config container in top of chat
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

  -- Create input container (always present)
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

  -- Create usage container (always present) - moved to bottom
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
      winhighlight = "Normal:EcaLabel",
      statusline = " ",
    }),
  })
  self.containers.usage:mount()
  self:_setup_container_events(self.containers.usage, "usage")
  Logger.debug("Mounted container: usage (winid: " .. self.containers.usage.winid .. ")")

  Logger.debug(
    string.format(
      "Created containers: chat=%d, input=%d, usage=%d, config=%d",
      chat_height,
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
  if name == "input" then
    self:_setup_input_events(container)
    self:_setup_input_keymaps(container)
  elseif name == "chat" then
    self:_setup_chat_keymaps(container)
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
function M:_setup_input_events(container)
  vim.api.nvim_create_autocmd("User", {
    pattern = { "CompletionItemSelected" },
    callback = function(event)
      if not event.data or not event.data.context_item or not event.data.label then
        return
      end

      if self._contexts then
        self._contexts.to_add = {
          name = event.data.label,
          type = event.data.context_item.type,
          data = {
            path = event.data.context_item.path
          }
        }
      end
    end,
  })

  -- contexts area and input handler
  vim.api.nvim_buf_attach(container.bufnr, false, {
    on_lines = function(_, buf, _changedtick, first, _last, _new_last, _bytecount)
      vim.schedule(function()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

        -- handle empty buffer
        if not lines or #lines < 1 then
          self:_update_input_display()
          return
        end

        local prefix_extmark = self.extmarks.prefix or nil
        local contexts_extmark = self.extmarks.contexts or nil

        if not prefix_extmark or not contexts_extmark then
          return
        end

        local prefix_ns = prefix_extmark._ns or nil
        local prefix_id = prefix_extmark._id and prefix_extmark._id[1] or nil

        if not prefix_ns or not prefix_id then
          return
        end

        local prefix_mark = vim.api.nvim_buf_get_extmark_by_id(buf, prefix_ns, prefix_id, {})
        local prefix_row = 1
        if prefix_mark and type(prefix_mark) == "table" and prefix_mark[1] ~= nil then
          prefix_row = tonumber(prefix_mark[1]) or 1
        end
        local contexts_row = 0

        local prefix_line = lines[prefix_row + 1] or nil
        local contexts_line = lines[contexts_row + 1] or nil
        local contexts_placeholder_line = self._contexts_placeholder_line or ""

        if prefix_row == contexts_row then
          -- prefix line missing, restore
          if contexts_line == contexts_placeholder_line then
            self:_update_input_display()
            return
          end

          -- we can consider that contexts were deleted
          self.mediator:clear_contexts()
          return
        end

        -- prefix line missing, restore
        if not prefix_line and contexts_line == contexts_placeholder_line then
          self:_update_input_display()
          return
        end

        -- something wrong, restore
        if prefix_row - contexts_row ~= 1 then
          self:_update_input_display()
          return
        end

        local context_to_add = self._contexts.to_add or {}

        if contexts_line ~= contexts_placeholder_line then
          -- a context was removed
          if #contexts_line < #self._contexts_placeholder_line then
            local contexts = self.mediator:contexts()

            local row, col = unpack(vim.api.nvim_win_get_cursor(container.winid))
            local context = contexts[col+1]

            if row == 1 and context then
              self.mediator:remove_context(context)
              return
            end
          end

          -- contexts line modified
          if #contexts_line > #self._contexts_placeholder_line then
            local placeholders = vim.split(contexts_line, "@", { plain = true, trimempty = true })

            for i = 1, #placeholders do
              if context_to_add.name and context_to_add.name == placeholders[i] then
                self.mediator:add_context(context_to_add)
                self._contexts.to_add = {}
              end
            end

            return
          end

          self:_update_input_display()
          return
        end

      end)
    end
  })
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
---@param container NuiSplit
function M:_setup_chat_keymaps(container)
  -- Toggle tool call details when pressing <CR> on a tool call line
  container:map("n", "<CR>", function()
    self:_toggle_tool_call_at_cursor()
  end, { noremap = true, silent = true })
end

---@private
function M:_update_container_sizes()
  if not self:is_open() then
    return
  end

  -- Recalculate heights
  local new_heights = {
    chat = self:get_chat_height(),
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

function M:get_chat_height()
  local total_height = vim.o.lines - vim.o.cmdheight - 1
  local input_height = Config.windows.input.height
  local usage_height = 1
  local config_height = 1

  return math.max(
    MIN_CHAT_HEIGHT,
    total_height
      - input_height
      - usage_height
      - WINDOW_MARGIN
      - config_height
  )
end

-- Placeholder methods for the display and setup functions
-- These will use the same logic as the original sidebar but with nui containers

function M:_setup_containers()
  -- Setup each container's content and behavior
  self:_setup_chat_container()

  self:_update_config_display()
  self:_setup_input_container()
  self:_setup_usage_container()

  self._initialized = true
end

function M:_refresh_container_content()
  -- Refresh content without full setup
  if self.containers.chat then
    self:_set_welcome_content()
  end

  if self.containers.config then
    self:_update_config_display()
  end

  if self.containers.input then
    self:_update_input_display()
  end

  if self.containers.usage then
    self:_update_usage_info()
  end
end

function M:_handle_state_updated(state)
  if state.contexts then
    self:_update_input_display()
  end

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
  self:_update_input_display()
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
end

function M:_update_input_display(opts)
  return vim.schedule(function()
    local input = self.containers.input
    if not input then
      return
    end

    local contexts = (self.mediator and self.mediator:contexts()) or {}
    local contexts_name = {}

    if #contexts > 0 then
      for _, context in ipairs(contexts) do
        local path = context.data.path

        if not path or path == "" then
          break
        end

        local name
        if context.type == "web" then
          name = path
          local max_len = (Config.windows and Config.windows.input and Config.windows.input.web_context_max_len) or 20
          if #name > max_len then
            name = string.sub(name, 1, max_len - 3) .. "..."
          end
        else
          name = vim.fn.fnamemodify(path, ":t")
        end

        local lines_range = context.data.lines_range

        if lines_range and lines_range.line_start and lines_range.line_end then
          name = string.format("%s:%d-%d", name, lines_range.line_start, lines_range.line_end)
        end

        table.insert(contexts_name, name .. " ")
      end
    end

    self._contexts_placeholder_line = "@"
    for _ = 1, #contexts_name do
      self._contexts_placeholder_line = self._contexts_placeholder_line .. "@"
    end

    local prefix_extmark = self.extmarks.prefix or nil
    local prefix_ns = prefix_extmark and prefix_extmark._ns or nil
    local prefix_id = prefix_extmark and prefix_extmark._id and prefix_extmark._id[1] or nil
    local prefix_row = 1

    if prefix_ns and prefix_id then
      local prefix_mark = vim.api.nvim_buf_get_extmark_by_id(input.bufnr, prefix_ns, prefix_id, {})
      prefix_row = prefix_mark and #prefix_mark > 0 and prefix_mark[1] or 1
    end

    -- Get existing lines to preserve user input (lines after the header)
    local existing_lines = vim.api.nvim_buf_get_lines(input.bufnr, prefix_row, -1, false)

    vim.api.nvim_buf_set_lines(input.bufnr, 0, -1, false, { self._contexts_placeholder_line, "" })

    if not self.extmarks.contexts then
      self.extmarks.contexts = {
        _ns = vim.api.nvim_create_namespace('extmarks_contexts'),
      }
    end

    if not self.extmarks.contexts._id then
      self.extmarks.contexts._id = {}
    end

    vim.api.nvim_buf_clear_namespace(input.bufnr, self.extmarks.contexts._ns, 0, -1)

    for i, context_name in ipairs(contexts_name) do
      self.extmarks.contexts._id[i] = vim.api.nvim_buf_set_extmark(
        input.bufnr,
        self.extmarks.contexts._ns,
        0,
        i,
        vim.tbl_extend("force", { virt_text = { { context_name, "EcaLabel" } }, virt_text_pos = "inline", hl_mode = "replace" }, { id = self.extmarks.contexts._id[i] })
      )
    end

    local prefix = Config.windows.input.prefix or "> "

    if not self.extmarks.prefix then
      self.extmarks.prefix = {
        _ns = vim.api.nvim_create_namespace('extmarks_prefix'),
      }
    end

    local clear = opts and opts.clear

    if #existing_lines > 0 and not clear then
      vim.api.nvim_buf_set_lines(input.bufnr, 1, 1 + #existing_lines, false, existing_lines)
    end

    if not self.extmarks.prefix._id then
      self.extmarks.prefix._id = {}
    end

    self.extmarks.prefix._id[1] = vim.api.nvim_buf_set_extmark(
      input.bufnr,
      self.extmarks.prefix._ns,
      1,
      0,
      vim.tbl_extend("force", { virt_text = { { prefix, "Normal" } }, virt_text_pos = "inline", right_gravity = false }, { id = self.extmarks.prefix._id[1] })
    )

    -- Set cursor to end of input line
    if vim.api.nvim_win_is_valid(input.winid) then
      local row = 1 + ((not clear and existing_lines and #existing_lines > 0) and #existing_lines or 1)
      local col = #prefix + ((not clear and existing_lines and #existing_lines > 0)  and #existing_lines[#existing_lines] or 0)

      vim.api.nvim_win_set_cursor(input.winid, { row, col })
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

      local row = 2
      local col = #prefix

      -- Ensure there is at least a header and a prefix line
      if #lines < 2 then
        row = 1
        col = 0
      end

      vim.api.nvim_win_set_cursor(input.winid, { row, col })

      -- Enter insert mode
      if Config.windows and Config.windows.edit and Config.windows.edit.start_insert then
        local mode = vim.api.nvim_get_mode().mode
        if mode == "n" then
          vim.cmd("startinsert!")
        end
      end
    end
  end, 100)
end

function M:_handle_input()
  local input = self.containers.input
  if not input then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(input.bufnr, 0, -1, false)
  if #lines < 2 then
    return
  end

  -- Process input: ignore first line (contexts header) and use second line onwards as input
  local message_lines = {}
  local prefix = Config.windows.input.prefix or "> "

  for i = 2, #lines do
    local line = lines[i]
    local content = line
    if i == 2 and vim.startswith(line, prefix) then
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

  -- Send message
  self:_send_message(message)

  -- Add new input line and focus
  self:_update_input_display({ clear = true })
  self:_focus_input()
end

function M:_update_config_display()
  local config = self.containers.config
  if not config or not config.bufnr or not vim.api.nvim_buf_is_valid(config.bufnr) then
    return
  end

  local model = self.mediator:selected_model() or "unknown"
  local behavior = self.mediator:selected_behavior() or "unknown"
  local mcps = self.mediator:mcps()

  local registered_count = vim.tbl_count(mcps)
  local starting_count = 0
  local running_count = 0
  local has_failed = false

  for _, mcp in pairs(mcps) do
    if mcp.status == "starting" then
      starting_count = starting_count + 1
    elseif mcp.status == "running" then
      running_count = running_count + 1
    end

    if mcp.status == "failed" then
      has_failed = true
    end
  end

  -- Active MCPs include both starting and running
  local active_count = starting_count + running_count

  -- While any MCP is still starting, dim the active count
  local active_hl = "Normal"
  if starting_count > 0 then
    active_hl = "EcaLabel"
  end

  local registered_hl = "Normal"
  if has_failed then
    registered_hl = "Exception" -- highlight registered count in red when any MCP failed
  elseif active_hl == "EcaLabel" then
    -- While MCPs are still starting, dim the total count as well
    registered_hl = "EcaLabel"
  end

  local texts = {
    { "model:",    "EcaLabel" }, { model, "Normal" }, { " " },
    { "behavior:", "EcaLabel" }, { behavior, "Normal" }, { " " },
    { "mcps:", "EcaLabel" }, { tostring(active_count), active_hl }, { "/", "EcaLabel" },
    { tostring(registered_count), registered_hl },
  }

  local virt_opts = { virt_text = texts, virt_text_pos = "overlay", hl_mode = "combine" }

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
  self._usage_info = _format_usage(tokens, limit, costs)

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
  if self._welcome_message_applied then
    return
  end

  local chat = self.containers.chat
  if not chat or not vim.api.nvim_buf_is_valid(chat.bufnr) then
    return
  end

  local chat_cfg = Utils.get_chat_config()
  local cfg = chat_cfg.welcome or {}
  local cfg_msg = (cfg.message and cfg.message ~= "" and cfg.message) or nil
  local welcome_message = cfg_msg or (self.mediator and self.mediator:welcome_message() or nil)

  local lines = { "Waiting for server to start..." }

  if welcome_message and welcome_message ~= "" then
    lines = Utils.split_lines(welcome_message)

    local tips = cfg.tips or {}

    if #tips > 0 then
      for _, tip in ipairs(tips) do
        table.insert(lines, tip)
      end
    end

    self._welcome_message_applied = true
  end

  table.insert(lines, "")
  Logger.debug("Setting welcome content for chat (welcome applied: " .. tostring(self._welcome_message_applied) .. ")")
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
  if not message or type(message) ~= "string" then
    Logger.error("Cannot send empty message")
    return
  end

  -- Add user message to chat
  self:_add_message("user", message)

  local replaced = message:gsub("([@#])([%w%._%-%/\\]+)", function(prefix, path)
    -- expand ~
    if vim.startswith(path, "~") then
      path = vim.fn.expand(path)
    end
    return prefix .. vim.fn.fnamemodify(path, ":p")
  end)

  message = replaced

  -- Store the last user message to avoid duplication
  self._last_user_message = message

  local contexts = self.mediator:contexts()
  self.mediator:send("chat/prompt", {
    chatId = self.mediator:id(),
    requestId = tostring(os.time()),
    message = message,
    contexts = contexts or {},
    model = self.mediator:selected_model(),
    behavior = self.mediator:selected_behavior(),
  }, function(err, result)
    if err then
      Logger.error("Failed to send message to ECA server: " .. vim.inspect(err))
      self:_add_message("assistant", "❌ **Error**: Failed to send message to ECA server: " .. vim.inspect(err))
      return
    end
    -- Response will come through server notification handler
    self:_update_input_display()

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
      self:_update_input_display()
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
    local tool_text = self:_tool_call_text(content)

    -- If this tool call reports a file change, append the basename of the
    -- path to the summary shown in the chat so users can immediately see
    -- which file was touched.
    local details = content.details
    if details and type(details) == "table" and details.type == "fileChange" then
      local path = details.path
      if path and path ~= "" then
        local filename = vim.fn.fnamemodify(path, ":t")
        if filename and filename ~= "" then
          -- Avoid duplicating the filename if it is already present
          if tool_text and tool_text ~= "" then
            if not string.find(tool_text, filename, 1, true) then
              tool_text = string.format("%s %s", tool_text, filename)
            end
          else
            tool_text = filename
          end
        end
      end
    end

    -- Add diff to current tool call if present in toolCalled content
    if self._current_tool_call and content.details then
      self._current_tool_call.details = content.details
    end

    -- Show the tool result in logs only
    local tool_log = string.format("**Tool Result**: %s", content.name or "unknown")
    local outputs_text = nil
    local outputs_type = nil
    if content.outputs and #content.outputs > 0 then
      local pieces = {}
      for _, output in ipairs(content.outputs) do
        if output.type == "text" then
          local txt = output.text or output.content
          if txt and txt ~= "" then
            table.insert(pieces, txt)
            tool_log = tool_log .. "\n" .. txt
            outputs_type = outputs_type or output.type
          end
        else
          -- Even if we don't render non-text payloads directly, remember
          -- their reported type so that any displayed block can still
          -- use an appropriate fence language.
          outputs_type = outputs_type or output.type
        end
      end
      if #pieces > 0 then
        outputs_text = table.concat(pieces, "\n")
      end
    end
    Logger.debug(tool_log)

    -- Determine completion status icon (configurable)
    local icons = Utils.get_tool_call_icons()
    local status_icon = icons.success
    if content.error then
      status_icon = icons.error
    end

    -- Ensure tool calls table exists
    self._tool_calls = self._tool_calls or {}

    -- Try to find an existing tool call entry for this id
    local call = self:_find_tool_call_by_id(content.id)

    if call then
      -- Update details and status for an existing call
      if content.details then
        call.details = content.details
        call.has_diff = self:_has_details_diff(call.details)
        call.diff_lines = self:_build_tool_call_diff_lines(call.details)
        call.details_lines = nil
        call.details_line_count = 0

        -- If this call now has a diff and doesn't yet have a label line, add it
        if call.has_diff and not call.label_line and not call.expanded then
          self:_insert_tool_call_diff_label_line(call)
          if Utils.should_start_diff_expanded() then
            self:_expand_tool_call_diff(call)
          end
        end
      end

      -- Always refresh stored outputs/argument lines when we get a final toolCalled event
      if outputs_text and outputs_text ~= "" then
        call.outputs = outputs_text
        call.outputs_type = outputs_type or call.outputs_type
      end
      call.arguments_lines = self:_build_tool_call_arguments_lines(call.arguments, call.outputs, call.outputs_type)

      call.status = status_icon
      call.title = tool_text or call.title

      -- Update the header line to move the checkmark/error icon to the end
      self:_update_tool_call_header_line(call)
    else
      -- Create a new entry for tool calls that didn't have a running phase
      local details = content.details or {}
      local arguments = self._current_tool_call and self._current_tool_call.arguments or ""
      local outputs = outputs_text or ""
      local outputs_type_value = outputs_type
      local arguments_lines = self:_build_tool_call_arguments_lines(arguments, outputs, outputs_type_value)
      local diff_lines = self:_build_tool_call_diff_lines(details)
      local has_diff = self:_has_details_diff(details)

      call = {
        id = content.id,
        title = tool_text or (content.name or "Tool call"),
        header_line = nil,
        expanded = false, -- controls argument visibility
        diff_expanded = false, -- controls diff visibility
        status = status_icon,
        arguments = arguments,
        details = details,
        outputs = outputs,
        outputs_type = outputs_type_value,
        has_diff = has_diff,
        label_line = nil,
        -- Separate storage for arguments vs diff so each can be toggled independently
        arguments_lines = arguments_lines,
        diff_lines = diff_lines,
        details_lines = nil,
        details_line_count = 0,
      }

      local chat = self.containers.chat
      if chat and vim.api.nvim_buf_is_valid(chat.bufnr) then
        local before_line_count = vim.api.nvim_buf_line_count(chat.bufnr)
        local header_text = self:_build_tool_call_header_text(call)
        self:_add_message("assistant", header_text)
        call.header_line = before_line_count + 1

        if call.has_diff then
          self:_insert_tool_call_diff_label_line(call)
          if Utils.should_start_diff_expanded() then
            self:_expand_tool_call_diff(call)
          end
        end

        table.insert(self._tool_calls, call)
      end
    end

    -- Clean up tool call state
    self:_finalize_tool_call()
  elseif content.type == "reasonStarted" then
    self:_handle_reason_started(content)
  elseif content.type == "reasonText" then
    self:_handle_reason_text(content)
  elseif content.type == "reasonFinished" then
    self:_handle_reason_finished(content)
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
    -- Start streaming with the stream queue
    self._is_streaming = true
    self._current_response_buffer = ""
    self._stream_visible_buffer = ""
    if self._stream_queue then
      self._stream_queue:clear()
    end

    -- Determine insertion point before adding placeholder (works even with empty header)
    local chat = self.containers.chat
    local start_line = 1
    if chat and vim.api.nvim_buf_is_valid(chat.bufnr) then
      start_line = vim.api.nvim_buf_line_count(chat.bufnr) + 1
    end

    -- Add assistant placeholder and track its start line
    self:_add_message("assistant", "")

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

  -- Accumulate the full response for finalization and history
  self._current_response_buffer = (self._current_response_buffer or "") .. text
  -- Enqueue new text to be rendered gradually
  if self._stream_queue then
    self._stream_queue:enqueue(text)
  end

  Logger.debug("DEBUG: Buffer now has " .. #self._current_response_buffer .. " chars (queue size: " .. (self._stream_queue and self._stream_queue:size() or 0) .. ")")
end

---@param content string
function M:_update_streaming_message(content)
  local chat = self.containers.chat
  if not chat then
    Logger.debug("DEBUG: Cannot update - no chat")
    return
  end

  Logger.debug("DEBUG: Updating streaming message with " .. #content .. " chars")

  if not vim.api.nvim_buf_is_valid(chat.bufnr) then
    Logger.notify("Invalid buffer, cannot update", vim.log.levels.ERROR)
    return
  end

  -- Simple and direct buffer update that only rewrites the assistant's
  -- own streaming region. This avoids clobbering content that may have
  -- been appended after it (e.g. tool calls or reasoning blocks).
  local success, err = pcall(function()
    -- Make buffer modifiable
    vim.api.nvim_set_option_value("modifiable", true, { buf = chat.bufnr })

    -- Concat content with header
    content = self._headers.assistant .. content

    -- Get current lines
    local lines = vim.api.nvim_buf_get_lines(chat.bufnr, 0, -1, false)
    local content_lines = Utils.split_lines(content)

    -- Resolve assistant start line using extmark if available
    local start_line = 0
    if self.extmarks and self.extmarks.assistant and self.extmarks.assistant._id then
      local pos = vim.api.nvim_buf_get_extmark_by_id(chat.bufnr, self.extmarks.assistant._ns, self.extmarks.assistant._id, {})
      if pos and pos[1] then
        start_line = pos[1] + 1
      end
    end

    Logger.debug("DEBUG: Start Line: " .. tostring(start_line))
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
    -- Reapply highlights for existing tool calls and reasoning blocks,
    -- since full-buffer updates can drop extmark-based styling.
    self:_reapply_tool_call_highlights()
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

  -- After appending a new message, previously highlighted tool calls and
  -- reasoning blocks may lose their extmark-based styling, so reapply it.
  self:_reapply_tool_call_highlights()
end

function M:_finalize_streaming_response()
  if self._is_streaming then
    Logger.debug("DEBUG: Finalizing streaming response")
    Logger.debug("DEBUG: Final buffer had " .. #(self._current_response_buffer or "") .. " chars")

    -- On finalize, ensure the full response is rendered, regardless of
    -- how many characters are still sitting in the internal queue.
    if self._current_response_buffer and self._current_response_buffer ~= "" then
      self:_update_streaming_message(self._current_response_buffer)
    end

    self._is_streaming = false
    self._current_response_buffer = ""
    self._response_start_time = 0
    self._stream_visible_buffer = ""
    if self._stream_queue then
      self._stream_queue:clear()
    end

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
      id = content.id,
      name = "",
      summary = "",
      arguments = "",
      details = {},
      outputs = "",
    }
  end

  -- Accumulate tool call data
  if content.id then
    self._current_tool_call.id = content.id
  end

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

function M:_tool_call_text(content)
  if content.summary and content.summary ~= "" then
    return content.summary
  end

  if self._current_tool_call and self._current_tool_call.summary and self._current_tool_call.summary ~= "" then
    return self._current_tool_call.summary
  end

  if content.name and content.name ~= "" then
    return content.name
  end

  if self._current_tool_call and self._current_tool_call.name and self._current_tool_call.name ~= "" then
    return self._current_tool_call.name
  end

  return "Tool call"
end

function M:_display_tool_call(content)
  if not self._is_tool_call_streaming or not self._current_tool_call then
    return nil
  end

  local chat = self.containers.chat
  if not chat or not vim.api.nvim_buf_is_valid(chat.bufnr) then
    return nil
  end

  local tool_name = self:_tool_call_text(content)
  local tool_log = string.format("**Tool Call**: %s", tool_name or "unknown")

  if self._current_tool_call.arguments and self._current_tool_call.arguments ~= "" then
    tool_log = tool_log .. "\n```json\n" .. self._current_tool_call.arguments .. "\n```"
  end

  if self._current_tool_call.details and self._current_tool_call.details.diff then
    tool_log = tool_log .. "\n\n**Diff**:\n```diff\n" .. self._current_tool_call.details.diff .. "\n```"
  end

  Logger.debug(tool_log)

  -- Ensure tool calls table exists
  self._tool_calls = self._tool_calls or {}

  -- Try to find an existing entry for this tool call
  local existing_call = nil
  if self._current_tool_call.id then
    existing_call = self:_find_tool_call_by_id(self._current_tool_call.id)
  end

  -- Build detail lines from current state (arguments and diff are controlled separately)
  local arguments_lines = self:_build_tool_call_arguments_lines(
    self._current_tool_call.arguments,
    self._current_tool_call.outputs,
    self._current_tool_call.outputs_type
  )
  local diff_lines = self:_build_tool_call_diff_lines(self._current_tool_call.details)
  local has_diff = self:_has_details_diff(self._current_tool_call.details)

  if existing_call then
    -- Update details for existing call (do not add another header)
    existing_call.arguments = self._current_tool_call.arguments or existing_call.arguments
    existing_call.details = self._current_tool_call.details or existing_call.details
    existing_call.has_diff = has_diff
    existing_call.arguments_lines = arguments_lines
    existing_call.diff_lines = diff_lines
    existing_call.details_lines = nil
    existing_call.details_line_count = 0

    -- Reset diff visibility when we get new diff content
    if not has_diff then
      existing_call.diff_expanded = false
    end

    -- If this call now has a diff and doesn't yet have a label line, add it
    if has_diff and not existing_call.label_line and not existing_call.expanded then
      self:_insert_tool_call_diff_label_line(existing_call)
    end

    return
  end

  -- Create a new tool call entry and header (collapsed by default)
  local header_title = tool_name or "Tool call"
  local call = {
    id = self._current_tool_call.id or content.id,
    title = header_title,
    header_line = nil,
    expanded = false, -- controls argument visibility
    diff_expanded = false, -- controls diff visibility
    status = nil,
    arguments = self._current_tool_call.arguments or "",
    details = self._current_tool_call.details or {},
    outputs = self._current_tool_call.outputs or "",
    has_diff = has_diff,
    label_line = nil,
    -- Store arguments and diff lines separately so they can be toggled independently
    arguments_lines = arguments_lines,
    diff_lines = diff_lines,
    details_lines = nil,
    details_line_count = 0,
  }

  local before_line_count = vim.api.nvim_buf_line_count(chat.bufnr)
  local header_text = self:_build_tool_call_header_text(call)
  self:_add_message("assistant", header_text)
  call.header_line = before_line_count + 1

  -- Apply header highlight (tool call vs reasoning)
  self:_highlight_tool_call_header(call)

          if call.has_diff then
            self:_insert_tool_call_diff_label_line(call)
            if Utils.should_start_diff_expanded() then
              self:_expand_tool_call_diff(call)
            end
          end
  
          table.insert(self._tool_calls, call)
end

function M:_finalize_tool_call()
  self._current_tool_call = nil
  self._is_tool_call_streaming = false
end

-- ===== Reasoning ("Thinking") handling =====

-- Create a new reasoning entry that behaves like a tool call
function M:_handle_reason_started(content)
  local id = content.id
  if not id then
    return
  end

  local chat = self.containers.chat
  if not chat or not vim.api.nvim_buf_is_valid(chat.bufnr) then
    return
  end

  self._reasons = self._reasons or {}
  self._tool_calls = self._tool_calls or {}

  -- If a new reasoning starts while another one is still "running",
  -- mark the previous one as finished so only one active "Thinking"
  -- block is shown at a time.
  local labels = Utils.get_reasoning_labels()
  local running_label = labels.running
  local finished_label = labels.finished

  for existing_id, existing_call in pairs(self._reasons) do
    if existing_id ~= id
      and existing_call
      and existing_call.status == nil
      -- Only auto-convert entries that are *currently* showing
      -- the running label, so we don't clobber completed
      -- entries like "Thought 1.23 s" when a new reasoning
      -- block starts later.
      and existing_call.title == running_label then
      -- For reasoning entries we don't show status icons; instead we just
      -- update the label from the running label to the finished label.
      existing_call.title = finished_label
      existing_call.status = nil
      self:_update_tool_call_header_line(existing_call)
    end
  end

  -- Avoid creating duplicates for the same reasoning id
  if self._reasons[id] then
    return
  end

  -- Whether "Thinking" blocks should start expanded by default
  -- Use the merged chat config so both legacy `chat.reasoning` and
  -- modern `windows.chat.reasoning` can control this behavior.
  local chat_cfg = Utils.get_chat_config()
  local reasoning_cfg = chat_cfg.reasoning or {}
  local expand = reasoning_cfg.expanded == true

  local call = {
    id = id,
    title = running_label, -- summary label while reasoning is running
    header_line = nil,
    expanded = expand, -- controls visibility of reasoning text
    diff_expanded = false,        -- unused for reasoning
    status = nil,                 -- unused for reasoning headers; no status icons
    arguments = "",              -- we reuse arguments as the accumulated reasoning text
    details = {},
    has_diff = false,
    label_line = nil,
    arguments_lines = {},
    diff_lines = {},
    details_lines = nil,
    details_line_count = 0,
    is_reason = true,
  }

  local before_line_count = vim.api.nvim_buf_line_count(chat.bufnr)
  local header_text = self:_build_tool_call_header_text(call)
  self:_add_message("assistant", header_text)
  call.header_line = before_line_count + 1

  -- Apply header highlight (reasoning entries use Comment)
  self:_highlight_tool_call_header(call)

  -- Track this reasoning both in a dedicated map and in the generic tool_calls
  self._reasons[id] = call
  table.insert(self._tool_calls, call)
end

-- Append streamed reasoning text and update the expanded block (if open)
function M:_handle_reason_text(content)
  local id = content.id
  if not id or not content.text then
    return
  end

  self._reasons = self._reasons or {}
  local call = self._reasons[id]
  if not call then
    -- If we somehow receive text without a start, create the entry lazily
    self:_handle_reason_started({ id = id })
    call = self._reasons[id]
    if not call then
      return
    end
  end

  local chat = self.containers.chat
  if not chat or not vim.api.nvim_buf_is_valid(chat.bufnr) then
    return
  end

  -- Accumulate raw reasoning text
  call.arguments = (call.arguments or "") .. content.text

  -- Build plain text block for the reasoning body (no markdown quote prefix).
  -- We keep the first inserted line as the first line of reasoning text rather
  -- than a blank spacer so that navigation from the header lands on the actual content.
  call.arguments_lines = {}

  local lines = Utils.split_lines(call.arguments or "")
  for _, line in ipairs(lines) do
    line = line ~= "" and line or " "
    table.insert(call.arguments_lines, line)
  end

  -- If the reasoning block is expanded, update its region in the buffer in-place
  if call.expanded then
    local prev_count = call._last_arguments_count or 0
    local new_count = #call.arguments_lines

    self:_safe_buffer_update(chat.bufnr, function()
      if prev_count == 0 and new_count > 0 then
        -- Insert for the first time immediately after the header
        vim.api.nvim_buf_set_lines(chat.bufnr, call.header_line, call.header_line, false, call.arguments_lines)
        -- Shift subsequent tool calls down by the inserted line count
        self:_adjust_tool_call_lines(call, new_count)
      else
        -- Replace existing block; adjust subsequent calls only if size changed
        vim.api.nvim_buf_set_lines(chat.bufnr, call.header_line, call.header_line + prev_count, false, call.arguments_lines)
        if new_count ~= prev_count then
          self:_adjust_tool_call_lines(call, new_count - prev_count)
        end
      end
    end)

    call._last_arguments_count = new_count
  end

  -- Ensure the header arrow reflects whether there is body content to show.
  -- This will add the expand/collapse icon once we have streamed some
  -- reasoning text, and it will be omitted while the body is still empty.
  self:_update_tool_call_header_line(call)
end

-- Mark reasoning as finished and update the header icon
function M:_handle_reason_finished(content)
  local id = content.id
  if not id then
    return
  end

  self._reasons = self._reasons or {}
  local call = self._reasons[id]
  if not call then
    return
  end

  local labels = Utils.get_reasoning_labels()
  local finished_label = labels.finished

  -- When reasoning is finished, update the label from running to a
  -- finished label, appending the total time in seconds when available.
  local total_ms = tonumber(content.totalTimeMs)
  if total_ms and total_ms > 0 then
    local seconds = total_ms / 1000
    call.title = string.format("%s %.2f s", finished_label, seconds)
  else
    call.title = finished_label
  end

  call.status = nil
  self:_update_tool_call_header_line(call)
end

-- Find existing tool call entry by id
function M:_find_tool_call_by_id(id)
  if not self._tool_calls or not id then
    return nil
  end

  for _, call in ipairs(self._tool_calls) do
    if call.id == id then
      return call
    end
  end

  return nil
end

-- Find the tool call that owns a given buffer line
function M:_find_tool_call_for_line(line)
  if not self._tool_calls then
    return nil
  end

  for _, call in ipairs(self._tool_calls) do
    if call.header_line then
      local start_line = call.header_line
      local end_line = start_line

      -- Include argument block when expanded
      local arg_count = call.arguments_lines and #call.arguments_lines or 0
      if call.expanded and arg_count > 0 then
        end_line = end_line + arg_count
      end

      -- Include label line and optional diff block when present
      if call.has_diff and call.label_line then
        local label_end = call.label_line
        local diff_count = call.diff_lines and #call.diff_lines or 0
        if call.diff_expanded and diff_count > 0 then
          label_end = label_end + diff_count
        end
        if label_end > end_line then
          end_line = label_end
        end
      end

      if line >= start_line and line <= end_line then
        return call
      end
    end
  end

  return nil
end

-- Build the header text for a tool call like: "▶ summary ⏳" (or "▶ summary ✅" / "▶ summary ❌")
function M:_build_tool_call_header_text(call)
  local icons = Utils.get_tool_call_icons()

  -- Reasoning ("Thinking") entries do not show status icons; they only
  -- display a toggle arrow (when there is body content to show) and a
  -- text label ("Thinking..." / "Thought").
  if call.is_reason then
    local title = call.title or "Thinking..."
    if type(title) ~= "string" then
      title = tostring(title)
    end

    -- Only show the expand/collapse arrow once we actually have some
    -- reasoning text to display. This avoids showing a useless toggle
    -- while the model is still preparing its thoughts.
    local has_body = false
    if call.arguments and type(call.arguments) == "string" and call.arguments:match("%S") then
      has_body = true
    elseif call.arguments_lines and #call.arguments_lines > 0 then
      has_body = true
    end

    if not has_body then
      return title
    end

    local arrow = call.expanded and icons.expanded or icons.collapsed
    if type(arrow) ~= "string" then
      arrow = tostring(arrow)
    end

    return table.concat({ arrow, title }, " ")
  end

  -- Regular tool calls always show an expand/collapse arrow. The arrow
  -- controls the visibility of the arguments block; any diff is toggled
  -- separately via the "view diff" label.
  local arrow = call.expanded and icons.expanded or icons.collapsed

  -- Normalize all pieces to strings to avoid issues when configuration or
  -- status fields accidentally contain non-string values (e.g. userdata).
  if type(arrow) ~= "string" then
    arrow = tostring(arrow)
  end

  local title = call.title or "Tool call"
  local status = call.status or icons.running

  if type(title) ~= "string" then
    title = tostring(title)
  end
  if type(status) ~= "string" then
    status = tostring(status)
  end

  local parts = { arrow, title, status }

  return table.concat(parts, " ")
end

  -- Build the argument and output detail lines for a tool call.
-- Arguments and outputs are shown in separate labeled sections.
function M:_build_tool_call_arguments_lines(arguments, outputs, outputs_type)
  local lines = {}
  local has_content = false

  if arguments and arguments ~= "" then
    table.insert(lines, "Arguments:")
    table.insert(lines, "```json")
    for _, line in ipairs(Utils.split_lines(arguments)) do
      table.insert(lines, line)
    end
    table.insert(lines, "```")
    table.insert(lines, "")
    has_content = true
  end

  if outputs and outputs ~= "" then
    if not has_content then
      -- Add spacer only if this is the first section
      table.insert(lines, "")
    end

    table.insert(lines, "Output:")

    -- Choose fence language based on reported output type. When the tool
    -- says the output type is "text", render it as a plain text fence
    -- instead of JSON. For unknown types we keep using "json" for
    -- backwards compatibility.
    local lang = "json"
    if type(outputs_type) == "string" and outputs_type ~= "" then
      if outputs_type == "text" then
        lang = "text"
      else
        lang = outputs_type
      end
    end

    table.insert(lines, "```" .. lang)
    for _, line in ipairs(Utils.split_lines(outputs)) do
      table.insert(lines, line)
    end
    table.insert(lines, "```")
    table.insert(lines, "")
  end

  -- Remove any trailing blank lines; we keep internal spacing (for example
  -- between the Arguments and Output sections) intact.
  while #lines > 0 and lines[#lines]:match("^%s*$") do
    table.remove(lines)
  end

  return lines
end

-- Build the diff detail lines (tool call diff only)
function M:_build_tool_call_diff_lines(details)
  local lines = {}

  local diff = details and details.diff or nil
  if diff and diff ~= "" then
    -- Start the diff block with the fenced header (no leading newline)
    table.insert(lines, "```diff")
    for _, line in ipairs(Utils.split_lines(diff)) do
      table.insert(lines, line)
    end
    table.insert(lines, "```")
  end

  -- Remove any trailing blank lines just in case
  while #lines > 0 and lines[#lines]:match("^%s*$") do
    table.remove(lines)
  end

  return lines
end

-- Optional helper to build combined detail lines (arguments + diff)
-- NOTE: callers that need independent control over arguments vs diff
-- should prefer _build_tool_call_arguments_lines/_build_tool_call_diff_lines.
function M:_build_tool_call_details_lines(arguments, details, outputs, outputs_type)
  local lines = {}

  local arg_lines = self:_build_tool_call_arguments_lines(arguments, outputs, outputs_type)
  for _, line in ipairs(arg_lines) do
    table.insert(lines, line)
  end

  local diff_lines = self:_build_tool_call_diff_lines(details)
  for _, line in ipairs(diff_lines) do
    table.insert(lines, line)
  end

  return lines
end

-- Check if tool call details contain a diff
function M:_has_details_diff(details)
  return details and type(details) == "table" and details.diff and details.diff ~= ""
end

-- Build the label text shown below the tool call summary when a diff is available
function M:_build_tool_call_diff_label_text(call)
  local labels = Utils.get_tool_call_diff_labels()

  -- Use different texts depending on diff expanded/collapsed state
  if call and call.diff_expanded then
    return labels.expanded
  end

  return labels.collapsed
end

-- Helper to choose sidebar highlight groups in a theme-aware way
local function _eca_sidebar_hl(kind)
  if kind == "tool_header" then
    return "EcaToolCall"
  elseif kind == "reason_header" then
    return "EcaLabel"
  elseif kind == "diff_label" then
    return "EcaHyperlink"
  end

  return "Normal"
end

-- Highlight a tool call header line (summary / reasoning label)
--
-- * Regular tool calls use a dedicated highlight group (EcaToolCall by default)
-- * Reasoning entries ("Thinking..." / "Thought ...") are highlighted differently
--   and adapt to light/dark themes via _eca_sidebar_hl()
function M:_highlight_tool_call_header(call)
  local chat = self.containers.chat
  if not chat or not vim.api.nvim_buf_is_valid(chat.bufnr) then
    return
  end

  if not call or not call.header_line then
    return
  end

  -- Guard against stale header_line values that point past the end of the
  -- buffer (for example after streaming updates that rewrote the chat).
  local line_count = vim.api.nvim_buf_line_count(chat.bufnr)
  if call.header_line < 1 or call.header_line > line_count then
    return
  end

  self.extmarks = self.extmarks or {}
  if not self.extmarks.tool_header then
    self.extmarks.tool_header = {
      _ns = vim.api.nvim_create_namespace("extmarks_tool_header"),
      _id = {},
    }
  end

  local ns = self.extmarks.tool_header._ns
  local key = call.id or tostring(call.header_line)

  -- Clear any previous highlight for this call
  if self.extmarks.tool_header._id[key] then
    pcall(vim.api.nvim_buf_del_extmark, chat.bufnr, ns, self.extmarks.tool_header._id[key])
  end

  local line = vim.api.nvim_buf_get_lines(chat.bufnr, call.header_line - 1, call.header_line, false)[1] or ""
  local end_col = #line

  local hl_group
  if call.is_reason then
    hl_group = _eca_sidebar_hl("reason_header")
  else
    hl_group = _eca_sidebar_hl("tool_header")
  end

  -- Add an extmark that highlights the entire header line
  self.extmarks.tool_header._id[key] = vim.api.nvim_buf_set_extmark(chat.bufnr, ns, call.header_line - 1, 0, {
    hl_group = hl_group,
    end_col = end_col,
    priority = 180,
  })
end

-- Highlight the "view diff" label as a hyperlink-style element
function M:_highlight_tool_call_diff_label_line(call)
  local chat = self.containers.chat
  if not chat or not vim.api.nvim_buf_is_valid(chat.bufnr) then
    return
  end

  if not call or not call.label_line then
    return
  end

  -- Guard against stale label_line values that point past the end of the
  -- buffer (for example after streaming updates that rewrote the chat).
  local line_count = vim.api.nvim_buf_line_count(chat.bufnr)
  if call.label_line < 1 or call.label_line > line_count then
    return
  end

  self.extmarks = self.extmarks or {}
  if not self.extmarks.diff_label then
    self.extmarks.diff_label = {
      _ns = vim.api.nvim_create_namespace("extmarks_diff_label"),
      _id = {},
    }
  end

  local ns = self.extmarks.diff_label._ns
  local key = call.id or tostring(call.header_line)

  -- Clear any previous highlight for this call
  if self.extmarks.diff_label._id[key] then
    pcall(vim.api.nvim_buf_del_extmark, chat.bufnr, ns, self.extmarks.diff_label._id[key])
  end

  -- Determine how much of the line to highlight (the whole label text)
  local line = vim.api.nvim_buf_get_lines(chat.bufnr, call.label_line - 1, call.label_line, false)[1] or ""
  local end_col = #line

  -- Add an extmark that highlights the label text using a theme-aware group
  -- Use a high priority so it wins over Treesitter/markdown highlights.
  self.extmarks.diff_label._id[key] = vim.api.nvim_buf_set_extmark(chat.bufnr, ns, call.label_line - 1, 0, {
    hl_group = _eca_sidebar_hl("diff_label"),
    end_col = end_col,
    priority = 200,
  })
end

-- Reapply header and diff label highlights after full-buffer updates
-- (e.g. when streaming assistant responses or appending new messages).
-- This ensures previously expanded tool calls and reasoning blocks
-- keep their visual styling instead of "resetting".
function M:_reapply_tool_call_highlights()
  if not self._tool_calls or vim.tbl_isempty(self._tool_calls) then
    return
  end

  local chat = self.containers.chat
  if not chat or not vim.api.nvim_buf_is_valid(chat.bufnr) then
    return
  end

  for _, call in ipairs(self._tool_calls) do
    if call.header_line then
      self:_highlight_tool_call_header(call)
    end

    if call.has_diff and call.label_line then
      self:_highlight_tool_call_diff_label_line(call)
    end
  end
end

-- Update the existing "view diff" label line to reflect the current expanded/collapsed state
function M:_update_tool_call_diff_label_line(call)
  local chat = self.containers.chat
  if not chat or not vim.api.nvim_buf_is_valid(chat.bufnr) then
    return
  end

  if not call or not call.label_line then
    return
  end

  local label_text = self:_build_tool_call_diff_label_text(call)

  self:_safe_buffer_update(chat.bufnr, function()
    vim.api.nvim_buf_set_lines(chat.bufnr, call.label_line - 1, call.label_line, false, { label_text })
  end)

  -- Ensure the label is highlighted after updating its text
  self:_highlight_tool_call_diff_label_line(call)
end

-- Insert the "view diff" label line directly below the tool call summary
function M:_insert_tool_call_diff_label_line(call)
  local chat = self.containers.chat
  if not chat or not vim.api.nvim_buf_is_valid(chat.bufnr) then
    return
  end

  if not call or not call.header_line or call.label_line or not call.has_diff then
    return
  end

  local label_text = self:_build_tool_call_diff_label_text(call)

  self:_safe_buffer_update(chat.bufnr, function()
    -- Insert label immediately after the header line
    vim.api.nvim_buf_set_lines(chat.bufnr, call.header_line, call.header_line, false, { label_text })
  end)

  -- Track the label line (1-based)
  call.label_line = call.header_line + 1

  -- Ensure the label is highlighted when first inserted
  self:_highlight_tool_call_diff_label_line(call)

  -- Shift subsequent tool call headers/labels down by one line
  self:_adjust_tool_call_lines(call, 1)
end

-- Update the visual header line for a tool call
function M:_update_tool_call_header_line(call)
  local chat = self.containers.chat
  if not chat or not vim.api.nvim_buf_is_valid(chat.bufnr) or not call.header_line then
    return
  end

  local header_text = self:_build_tool_call_header_text(call)

  self:_safe_buffer_update(chat.bufnr, function()
    vim.api.nvim_buf_set_lines(chat.bufnr, call.header_line - 1, call.header_line, false, { header_text })
  end)

  -- Re-apply header highlight after updating its text/arrow/status
  self:_highlight_tool_call_header(call)
end

-- Adjust header_line (and optional label_line) for tool calls that come after the given one
function M:_adjust_tool_call_lines(changed_call, delta)
  if not self._tool_calls or delta == 0 then
    return
  end

  for _, call in ipairs(self._tool_calls) do
    if call ~= changed_call and call.header_line and changed_call.header_line and call.header_line > changed_call.header_line then
      call.header_line = call.header_line + delta
    end

    if call ~= changed_call and call.label_line and changed_call.header_line and call.label_line > changed_call.header_line then
      call.label_line = call.label_line + delta
    end
  end
end

-- Expand a tool call's arguments, inserting them below the header
function M:_expand_tool_call(call)
  local chat = self.containers.chat
  if not chat or not vim.api.nvim_buf_is_valid(chat.bufnr) then
    return
  end

  if call.expanded then
    return
  end

  -- Reasoning ("Thinking") entries behave slightly differently: we never
  -- wrap them in code fences and the streaming handler is responsible for
  -- keeping the body up to date. Here we just insert the current body once.
  if call.is_reason then
    -- Build a plain text block if we don't have it yet. We keep the
    -- first inserted line as the first line of reasoning text rather
    -- than a blank spacer so that navigation from the header lands on
    -- the actual content.
    if not call.arguments_lines or #call.arguments_lines == 0 then
      call.arguments_lines = {}

      for _, line in ipairs(Utils.split_lines(call.arguments or "")) do
        line = line ~= "" and line or " "
        table.insert(call.arguments_lines, line)
      end
    end

    local count = call.arguments_lines and #call.arguments_lines or 0
    if count > 0 then
      self:_safe_buffer_update(chat.bufnr, function()
        -- Insert reasoning lines immediately after the header line
        vim.api.nvim_buf_set_lines(chat.bufnr, call.header_line, call.header_line, false, call.arguments_lines)
      end)

      -- Track how many lines we inserted so that subsequent streaming
      -- updates (_handle_reason_text) can correctly replace this block.
      call._last_arguments_count = count

      -- Shift subsequent tool call header/label lines down
      self:_adjust_tool_call_lines(call, count)
    end

    call.expanded = true
    self:_update_tool_call_header_line(call)

    if chat.winid and vim.api.nvim_win_is_valid(chat.winid) then
      local last_line = call.header_line + (call._last_arguments_count or 0)
      vim.api.nvim_win_set_cursor(chat.winid, { last_line, 0 })
      vim.api.nvim_win_call(chat.winid, function()
        vim.cmd("normal! zb")
      end)
    end

    return
  end

  -- Regular tool calls: show JSON arguments and output blocks
  call.arguments_lines = call.arguments_lines or self:_build_tool_call_arguments_lines(call.arguments, call.outputs)
  local count = call.arguments_lines and #call.arguments_lines or 0
  if count == 0 then
    return
  end

  self:_safe_buffer_update(chat.bufnr, function()
    -- Insert arguments immediately after the header line
    vim.api.nvim_buf_set_lines(chat.bufnr, call.header_line, call.header_line, false, call.arguments_lines)
  end)

  -- If there is a diff label, it must move down by the number of inserted lines
  if call.has_diff and call.label_line then
    call.label_line = call.label_line + count
  end

  call.expanded = true

  -- Shift subsequent tool call header/label lines down
  self:_adjust_tool_call_lines(call, count)

  -- Update header arrow
  self:_update_tool_call_header_line(call)

  -- Move cursor to show the full arguments block
  if chat.winid and vim.api.nvim_win_is_valid(chat.winid) then
    local last_line = call.header_line + count
    vim.api.nvim_win_set_cursor(chat.winid, { last_line, 0 })
    vim.api.nvim_win_call(chat.winid, function()
      vim.cmd("normal! zb")
    end)
  end
end

-- Collapse a tool call's arguments, removing them from the buffer
function M:_collapse_tool_call(call)
  local chat = self.containers.chat
  if not chat or not vim.api.nvim_buf_is_valid(chat.bufnr) then
    return
  end

  if not call.expanded then
    return
  end

  local count = call.arguments_lines and #call.arguments_lines or 0
  if count == 0 then
    call.expanded = false
    self:_update_tool_call_header_line(call)
    return
  end

  self:_safe_buffer_update(chat.bufnr, function()
    -- Remove the arguments block directly below the header
    vim.api.nvim_buf_set_lines(chat.bufnr, call.header_line, call.header_line + count, false, {})
  end)

  -- If there is a diff label, move it back up
  if call.has_diff and call.label_line then
    call.label_line = call.label_line - count
  end

  call.expanded = false

  -- Shift subsequent tool call header/label lines back up
  self:_adjust_tool_call_lines(call, -count)

  -- Update header arrow
  self:_update_tool_call_header_line(call)
end

-- Expand a tool call's diff, inserting it below the diff label
function M:_expand_tool_call_diff(call)
  local chat = self.containers.chat
  if not chat or not vim.api.nvim_buf_is_valid(chat.bufnr) then
    return
  end

  if not call.has_diff or not call.label_line or call.diff_expanded then
    return
  end

  call.diff_lines = call.diff_lines or self:_build_tool_call_diff_lines(call.details)
  local count = call.diff_lines and #call.diff_lines or 0
  if count == 0 then
    return
  end

  self:_safe_buffer_update(chat.bufnr, function()
    -- Insert diff lines immediately after the diff label line
    vim.api.nvim_buf_set_lines(chat.bufnr, call.label_line, call.label_line, false, call.diff_lines)
  end)

  call.diff_expanded = true

  -- Shift subsequent tool call header/label lines down
  self:_adjust_tool_call_lines(call, count)

  -- Update the diff label to show the collapse indicator
  self:_update_tool_call_diff_label_line(call)
end

-- Collapse a tool call's diff, removing it from the buffer
function M:_collapse_tool_call_diff(call)
  local chat = self.containers.chat
  if not chat or not vim.api.nvim_buf_is_valid(chat.bufnr) then
    return
  end

  if not call.diff_expanded then
    return
  end

  local count = call.diff_lines and #call.diff_lines or 0
  if count == 0 then
    call.diff_expanded = false
    self:_update_tool_call_diff_label_line(call)
    return
  end

  self:_safe_buffer_update(chat.bufnr, function()
    -- Remove the diff block that starts immediately after the label line
    vim.api.nvim_buf_set_lines(chat.bufnr, call.label_line, call.label_line + count, false, {})
  end)

  call.diff_expanded = false

  -- Shift subsequent tool call header/label lines back up
  self:_adjust_tool_call_lines(call, -count)

  -- Update the diff label to show the expand indicator again
  self:_update_tool_call_diff_label_line(call)
end

-- Toggle tool call details at the current cursor position in the chat window
--
-- When a tool call has a diff available, the header toggle (arrow) controls
-- visibility of the tool arguments, while the "view diff" label controls
-- visibility of the diff only.
function M:_toggle_tool_call_at_cursor()
  local chat = self.containers.chat
  if not chat or not vim.api.nvim_win_is_valid(chat.winid) then
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(chat.winid)
  local line = cursor[1]

  local call = self:_find_tool_call_for_line(line)
  if not call then
    return
  end

  -- If we are on or below the diff label for a call that has a diff,
  -- toggle only the diff block.
  if call.has_diff and call.label_line and line >= call.label_line then
    if call.diff_expanded then
      self:_collapse_tool_call_diff(call)
    else
      self:_expand_tool_call_diff(call)
    end
    return
  end

  -- Otherwise toggle the arguments block via the header arrow
  if call.expanded then
    self:_collapse_tool_call(call)
  else
    self:_expand_tool_call(call)
  end
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
        local absolute_line = end_line + idx - 1 -- convert to absolute 1-based line

        -- If replacement contains newlines, split it into proper buffer lines
        if type(replacement) == "string" and replacement:find("\n") then
          local parts = Utils.split_lines(replacement)
          local prefix = line:sub(1, s_idx - 1)
          local suffix = line:sub(e_idx + 1)

          local new_lines = {}
          if #parts > 0 then
            -- First line: prefix + first part
            table.insert(new_lines, prefix .. parts[1])
            -- Middle parts (if any)
            for i = 2, #parts do
              table.insert(new_lines, parts[i])
            end
            -- Append suffix to the last inserted line
            new_lines[#new_lines] = new_lines[#new_lines] .. suffix
          else
            -- Fallback: no parts (shouldn't happen), just replace inline
            table.insert(new_lines, prefix .. suffix)
          end

          vim.api.nvim_buf_set_lines(chat.bufnr, absolute_line - 1, absolute_line, false, new_lines)
          changed = true
          break
        else
          -- Simple single-line replacement
          local new_line = (line:sub(1, s_idx - 1)) .. replacement .. (line:sub(e_idx + 1))
          vim.api.nvim_buf_set_lines(chat.bufnr, absolute_line - 1, absolute_line, false, { new_line })
          changed = true
          break
        end
      end
    end
  end)

  return changed
end

return M
