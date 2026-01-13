local M = {}

---@param tool_call eca.ToolCallRun
function M.get_preview_lines(tool_call)
  -- If no details or details without diff, show tool call info
  if not tool_call.details or not tool_call.details.diff then
    local arguments_text = tool_call.arguments or ""
    local arguments = vim.split(vim.inspect(arguments_text), "\n")
    local messages = {}
    if tool_call.summary then
      table.insert(messages, "Summary: " .. tool_call.summary)
    end
    table.insert(messages, "Tool Name: " .. (tool_call.name or "unknown"))
    table.insert(messages, "Tool Type: " .. (tool_call.origin or "unknown"))
    table.insert(messages, "Tool Arguments: ")
    for _, v in pairs(arguments) do
      table.insert(messages, v)
    end
    return messages
  end
  local lines = vim.split(tool_call.details.diff, "\n")
  return { tool_call.details.path or "", unpack(lines) }
end

---@param lines string[]
---@return {row: number, col: number, width: number, height: number}
local function get_position(lines)
  local gheight = math.floor(
    vim.api.nvim_list_uis() and vim.api.nvim_list_uis()[1] and vim.api.nvim_list_uis()[1].height or vim.o.lines
  )
  local gwidth = math.floor(
    vim.api.nvim_list_uis() and vim.api.nvim_list_uis()[1] and vim.api.nvim_list_uis()[1].width or vim.o.columns
  )
  local height = #lines > 10 and 35 or #lines
  local width = 0
  for _, line in ipairs(lines) do
    if #line > width then
      width = #line
    end
  end
  return {
    row = (gheight - height) * 0.5,
    col = (gwidth - width) * 0.5,
    width = math.floor(width * 1.5),
    height = height,
  }
end

---@param tool_call eca.ToolCallRun
---@param on_accept function
---@param on_deny function
function M.display_preview_lines(tool_call, on_accept, on_deny)
  local lines = M.get_preview_lines(tool_call)
  local buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  local position = get_position(lines)
  local title = tool_call.summary or tool_call.name
  local win = vim.api.nvim_open_win(buf, true, {
    border = "single",
    title = "Approve Tool Call(y/n): " .. title,
    relative = "editor",
    row = position.row,
    col = position.col,
    width = position.width,
    height = position.height,
  })
  if tool_call.details then
    vim.api.nvim_set_option_value("filetype", "diff", { buf = buf })
  else
    vim.api.nvim_set_option_value("number", false, { win = win })
    vim.api.nvim_set_option_value("relativenumber", false, { win = win })
  end

  vim.keymap.set({ "n", "i" }, "y", "", {
    buffer = buf,
    callback = function()
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(buf, { force = true })
      if on_accept then
        on_accept()
      end
    end,
  })
  vim.keymap.set({ "n", "i" }, "n", "", {
    buffer = buf,
    callback = function()
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(buf, { force = true })
      if on_deny then
        on_deny()
      end
    end,
  })
end

---@param tool_call eca.ToolCallRun
---@param on_accept function
---@param on_deny function
function M.approve_tool_call(tool_call, on_accept, on_deny)
  M.display_preview_lines(tool_call, on_accept, on_deny)
end
return M
