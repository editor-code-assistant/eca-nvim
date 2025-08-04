local Chat = {}

function Chat.new(config)
  local instance = {
    name = 'eca-chat',
    input_name = 'model',
    input_filetype = 'behavior',
    bufnr = nil,
    input_bufnr = nil,
    config = {
      auto_focus_mode = config.auto_focus_mode or true,
      auto_follow_cursor = config.auto_follow_cursor or true,
      auto_insert_mode = config.auto_insert_mode or true,
      -- TODO remove headers
      headers = config.headers or {
        user = '',  -- Header to use for user questions
        assistant = '', -- Header to use for AI answers
      },
      prefixes = config.prefixes or {
        user = '> ',
        assistant = '',
      },
      highlight_headers = true,
      separator = config.separator or '---',
      window = config.window or {
        layout = 'horizontal', -- 'vertical' or 'horizontal'
        width = 0.4,           -- fractional width of parent, or absolute width in columns when > 1
        height = 0.4,          -- fractional height of parent, or absolute height in rows when > 1
      },
    },
    messages_ns = vim.api.nvim_create_namespace('eca-chat-messages'),
    prompt_ns = vim.api.nvim_create_namespace('eca-chat-prompt'),
    messages = {},
    winnr = nil,
    input_winnr = nil,
    last_win = nil,
  }

  setmetatable(instance, { __index = Chat })

  return instance
end

function Chat:setup_focus_autocmd()
  if not self.config.auto_focus_mode then
    return
  end

  local group = vim.api.nvim_create_augroup('ECAChatFocus', { clear = true })

  vim.api.nvim_create_autocmd('WinEnter', {
    callback = function()
      local cur_win = vim.api.nvim_get_current_win()

      if cur_win == self.winnr and self.last_win ~= self.input_winnr then
        if self.input_winnr and vim.api.nvim_win_is_valid(self.input_winnr) then
          vim.api.nvim_set_current_win(self.input_winnr)
          if self.config.auto_insert_mode then
            vim.cmd("startinsert")
          end
        end
      end

      self.last_win = vim.api.nvim_get_current_win()
    end,
    group = group,
    pattern = '*',
  })
end

function Chat.open(config)
  local chat = Chat.new(config)

  chat:create_input_buffer()
  chat:create_buffer()

  chat:input_window()
  chat:window()

  chat:setup_focus_autocmd()

  return chat
end

function Chat:create_buffer()
  self.bufnr = vim.api.nvim_create_buf(false, true)

  vim.bo[self.bufnr].syntax = 'markdown'
  vim.bo[self.bufnr].textwidth = 0

  vim.bo[self.bufnr].filetype = self.name
  vim.bo[self.bufnr].modifiable = false

  vim.api.nvim_buf_set_name(self.bufnr, self.name)

  return self.bufnr
end

function Chat:create_input_buffer()
  self.input_bufnr = vim.api.nvim_create_buf(false, true)

  vim.bo[self.input_bufnr].syntax = 'markdown'
  vim.bo[self.input_bufnr].textwidth = 0

  vim.bo[self.input_bufnr].filetype = self.input_filetype
  vim.bo[self.input_bufnr].modifiable = true

  vim.api.nvim_buf_set_name(self.input_bufnr, self.input_name)

  return self.input_bufnr
end

function Chat:set_input_name(name)
  if not name or type(name) ~= "string" then return end

  name = vim.trim(name)

  self.input_name = name
  if self.input_bufnr and vim.api.nvim_buf_is_valid(self.input_bufnr) then
    vim.api.nvim_buf_set_name(self.input_bufnr, name)
  end
end

function Chat:set_input_filetype(filetype)
  if not filetype or type(filetype) ~= "string" then return end

  filetype = vim.trim(filetype)

  self.input_filetype = filetype
  if self.input_bufnr and vim.api.nvim_buf_is_valid(self.input_bufnr) then
    vim.bo[self.input_bufnr].filetype = filetype
  end
end

function Chat:window()
  if self:visible() then
    return
  end

  local window = { height = 0.9 }

  local height = window.height > 1 and window.height or math.floor(vim.o.lines * window.height)


  local orig = vim.api.nvim_get_current_win()
  local cmd = 'split'

  if height ~= 0 then
    cmd = height .. cmd
  end

  vim.api.nvim_set_current_win(self.input_winnr)
  vim.cmd(cmd)

  self.winnr = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(orig)

  vim.wo[self.winnr].wrap = true
  vim.wo[self.winnr].linebreak = true
  vim.wo[self.winnr].cursorline = true
  vim.wo[self.winnr].conceallevel = 2
  vim.wo[self.winnr].foldlevel = 99
  vim.wo[self.winnr].foldcolumn = '0'

  vim.api.nvim_win_set_buf(self.winnr, self.bufnr)
  self:render()
end

function Chat:input_window()
  if self:input_visible(self.input_winnr, self.input_bufnr) then
    return
  end

  local window = self.config.window or {}

  local width = window.width > 1 and window.width or math.floor(vim.o.columns * window.width)

  local orig = vim.api.nvim_get_current_win()
  local cmd = 'vsplit'

  if width ~= 0 then
    cmd = width .. cmd
  end

  if vim.api.nvim_get_option_value('splitright', {}) then
    cmd = 'botright ' .. cmd
  else
    cmd = 'topleft ' .. cmd
  end

  vim.cmd(cmd)

  self.input_winnr = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(orig)

  vim.wo[self.input_winnr].wrap = true
  vim.wo[self.input_winnr].linebreak = true
  vim.wo[self.input_winnr].cursorline = true
  vim.wo[self.input_winnr].conceallevel = 2
  vim.wo[self.input_winnr].foldlevel = 99
  vim.wo[self.input_winnr].foldcolumn = '0'

  vim.api.nvim_win_set_buf(self.input_winnr, self.input_bufnr)
end

function Chat:input_visible(winnr, bufnr)
  return winnr and vim.api.nvim_win_is_valid(winnr) and vim.api.nvim_win_get_buf(winnr) == bufnr
      or false
end

function Chat:visible()
  return self.winnr and vim.api.nvim_win_is_valid(self.winnr) and vim.api.nvim_win_get_buf(self.winnr) == self.bufnr
      or false
end

function Chat:validate()
  if self.winnr and vim.api.nvim_win_is_valid(self.winnr) and vim.api.nvim_win_get_buf(self.winnr) ~= self.bufnr then
    vim.api.nvim_win_set_buf(self.winnr, self.bufnr)
  end
end

function Chat:render()
  self:validate()
  vim.api.nvim_buf_clear_namespace(self.bufnr, self.messages_ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)

  local new_messages = {}
  local current_message = nil

  local function parse_header(header, line)
    return line:match('^' .. vim.pesc(header) .. '%(([^)]+)%)' .. vim.pesc(self.config.separator) .. '$')
  end

  for l, line in ipairs(lines) do
    -- Detect section header with ID
    for header_name, header_value in pairs(self.config.headers) do
      local id = parse_header(header_value, line)
      if id then
        -- Finish previous message
        if current_message then
          current_message.section.end_line = l - 1
          current_message.content = vim.trim(
            table.concat(
              vim.list_slice(lines, current_message.section.start_line, current_message.section.end_line),
              '\n'
            )
          )
        end

        -- Find existing message by id or create new
        local old_msg = nil
        for _, msg in ipairs(self.messages) do
          if msg.id == id then
            old_msg = msg
            break
          end
        end
        if not old_msg then
          old_msg = { id = id, role = header_name }
        end

        -- Attach section info
        old_msg.section = {
          role = header_name,
          start_line = l + 1,
          blocks = {},
        }
        table.insert(new_messages, old_msg)
        current_message = old_msg
        break
      end
    end

    if l == #lines and current_message then
      current_message.section.end_line = l
      current_message.content = vim.trim(
        table.concat(vim.list_slice(lines, current_message.section.start_line, current_message.section.end_line), '\n')
      )
    end
  end

  self.messages = new_messages
end

function Chat:add_message(message, replace)
  local current_message = self.messages[#self.messages]
  local is_new = not current_message
      or current_message.role ~= message.role
      or (message.id and current_message.id ~= message.id)

  if is_new then
    local prefix = self.config.prefixes[message.role]

    table.insert(self.messages, message)
    self:append('\n')
    self:append(prefix .. message.content)
  elseif replace and current_message then
    -- Replace the content of the current message
    self:render()
    current_message.content = message.content
    local section = current_message.section

    if section then
      vim.bo[self.bufnr].modifiable = true
      vim.api.nvim_buf_set_lines(
        self.bufnr,
        section.start_line - 1,
        section.end_line,
        false,
        vim.split(message.content, '\n')
      )
      vim.bo[self.bufnr].modifiable = false
      self:append('')
    end
  else
    -- Append to the current message
    current_message.content = current_message.content .. message.content
    self:append(message.content)
  end
end

--- Append text to the chat window.
---@param str string
function Chat:append(str)
  self:validate()

  -- Decide if we should follow cursor after appending text.
  local should_follow_cursor = self.config.auto_follow_cursor
  if should_follow_cursor and self:visible() then
    local current_pos = vim.api.nvim_win_get_cursor(self.winnr)
    local line_count = vim.api.nvim_buf_line_count(self.bufnr)
    -- Follow only if the cursor is currently at the last line.
    should_follow_cursor = current_pos[1] >= line_count - 1
  end

  local last_line, last_column, _ = self:last()

  vim.bo[self.bufnr].modifiable = true
  vim.api.nvim_buf_set_text(self.bufnr, last_line, last_column, last_line, last_column, vim.split(str, '\n'))
  vim.bo[self.bufnr].modifiable = false

  if should_follow_cursor then
    self:follow()
  end
end

--- Follow the cursor to the last line of the chat window.
function Chat:follow()
  if not self:visible() then
    return
  end

  local last_line, last_column, line_count = self:last()
  if line_count == 0 then
    return
  end

  vim.api.nvim_win_set_cursor(self.winnr, { last_line + 1, last_column })
end

function Chat:last()
  self:validate()
  local line_count = vim.api.nvim_buf_line_count(self.bufnr)
  local last_line = line_count - 1
  if last_line < 0 then
    return 0, 0, line_count
  end
  local last_line_content = vim.api.nvim_buf_get_lines(self.bufnr, -2, -1, false)
  if not last_line_content or #last_line_content == 0 then
    return last_line, 0, line_count
  end
  local last_column = #last_line_content[1]
  return last_line, last_column, line_count
end

function Chat:is_locked()
  self:validate()
  return vim.bo[self.bufnr].modifiable == false
end

function Chat:lock()
  self:validate()
  vim.bo[self.bufnr].modifiable = false
end

function Chat:unlock()
  vim.bo[self.bufnr].modifiable = true

  if self.config.auto_insert_mode and self:focused() then
    vim.cmd('startinsert')
  end
end

function Chat:focused()
  return self:visible() and vim.api.nvim_get_current_win() == self.winnr
end

function Chat:get_closest_message(role)
  if not self:visible() then
    return nil
  end

  self:render()

  local cursor_pos = vim.api.nvim_win_get_cursor(self.winnr)
  local cursor_line = cursor_pos[1]
  local closest_message = nil
  local max_line_below_cursor = -1

  for _, message in ipairs(self.messages) do
    local section = message.section
    local matches_role = not role or message.role == role
    if matches_role and section.start_line <= cursor_line and section.start_line > max_line_below_cursor then
      max_line_below_cursor = section.start_line
      closest_message = message
    end
  end

  return closest_message
end

function Chat:close()
  if self.winnr and vim.api.nvim_win_is_valid(self.winnr) then
    vim.api.nvim_win_close(self.winnr, true)
    self.winnr = nil
  end

  if self.input_winnr and vim.api.nvim_win_is_valid(self.input_winnr) then
    vim.api.nvim_win_close(self.input_winnr, true)
    self.input_winnr = nil
  end

  if self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr) then
    vim.api.nvim_buf_delete(self.bufnr, { force = true })
    self.bufnr = nil
  end

  if self.input_bufnr and vim.api.nvim_buf_is_valid(self.input_bufnr) then
    vim.api.nvim_buf_delete(self.input_bufnr, { force = true })
    self.input_bufnr = nil
  end
end

return Chat
