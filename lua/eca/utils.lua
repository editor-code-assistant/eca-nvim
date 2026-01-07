local uv = vim.uv or vim.loop

local Logger = require("eca.logger")
local Config = require("eca.config")

local M = {}

local CONSTANTS = {
  SIDEBAR_FILETYPE = "Eca",
  SIDEBAR_BUFFER_NAME = "__ECA__",
}

---@param bufnr integer
---@return boolean
function M.is_sidebar_buffer(bufnr)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  return vim.endswith(bufname, CONSTANTS.SIDEBAR_BUFFER_NAME)
end

---@param mode string|table
---@param lhs string
---@param rhs string|function
---@param opts table
function M.safe_keymap_set(mode, lhs, rhs, opts)
  -- Check if the keymap is already set
  local existing = vim.fn.maparg(lhs, type(mode) == "table" and mode[1] or mode, false, true)
  if existing and existing.rhs then
    Logger.debug("Keymap " .. lhs .. " already exists, skipping")
    return
  end
  vim.keymap.set(mode, lhs, rhs, opts)
end

---@return string
function M.get_project_root()
  local cwd = vim.fn.getcwd()
  local git_root = vim.fn.systemlist("git -C " .. vim.fn.shellescape(cwd) .. " rev-parse --show-toplevel")[1]
  if vim.v.shell_error == 0 and git_root then
    return git_root
  end
  return cwd
end

---@param text string
---@return string[]
function M.split_lines(text)
  return vim.split(text, "\n", { plain = true, trimempty = false })
end

---@param path string
---@return boolean
function M.file_exists(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == "file"
end

---@param dir string
---@return boolean
function M.dir_exists(dir)
  local stat = uv.fs_stat(dir)
  return stat and stat.type == "directory"
end

---@param path string
function M.create_dir(path)
  vim.fn.mkdir(path, "p")
end

---@return string
function M.get_cache_dir()
  local cache_dir = vim.fn.stdpath("cache") .. "/eca"
  if not M.dir_exists(cache_dir) then
    M.create_dir(cache_dir)
  end
  return cache_dir
end

---@return string
function M.get_data_dir()
  local data_dir = vim.fn.stdpath("data") .. "/eca"
  if not M.dir_exists(data_dir) then
    M.create_dir(data_dir)
  end
  return data_dir
end

---@param path string
---@return string?
function M.read_file(path)
  if not M.file_exists(path) then
    return nil
  end

  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local content = file:read("*a")
  file:close()
  return content
end

---@param path string
---@param content string
---@return boolean
function M.write_file(path, content)
  local file = io.open(path, "w")
  if not file then
    return false
  end

  file:write(content)
  file:close()
  return true
end

---@param n number|string
---@return string
function M.shorten_tokens(n)
  n = tonumber(n) or 0
  if n >= 1000 then
    local rounded = math.floor(n / 1000 + 0.5)
    return string.format("%dk", rounded)
  end
  return tostring(n)
end

---Get chat configuration by merging top-level and windows.chat config
---@return table
function M.get_chat_config()
  -- Merge top-level `chat` (backwards compatible) with `windows.chat`.
  -- `windows.chat` provides modern defaults, while a user-provided
  -- `chat.tool_call` block (legacy style) can still override fields
  -- like `diff_label` and `diff_start_expanded`.
  local win_chat = (Config.windows and Config.windows.chat) or {}
  local top_chat = Config.chat or {}

  if next(top_chat) == nil then
    return win_chat
  end

  return vim.tbl_deep_extend("force", win_chat, top_chat)
end

---Get tool call icons configuration
---@return table
function M.get_tool_call_icons()
  local chat_cfg = M.get_chat_config()
  local icons_cfg = (chat_cfg.tool_call and chat_cfg.tool_call.icons) or {}
  return {
    success = icons_cfg.success or "✅",
    error = icons_cfg.error or "❌",
    running = icons_cfg.running or "⏳",
    expanded = icons_cfg.expanded or "▲",
    collapsed = icons_cfg.collapsed or "▶",
  }
end

---Get tool call diff labels configuration
---
---Configuration (under `windows.chat.tool_call`):
---  tool_call = {
---    diff = {
---      collapsed_label = "+ view diff", -- Label when the diff is collapsed
---      expanded_label = "- view diff",  -- Label when the diff is expanded
---      expanded = false,                 -- When true, tool diffs start expanded
---    },
---  }
---@return table
function M.get_tool_call_diff_labels()
  local chat_cfg = M.get_chat_config()
  local cfg = chat_cfg.tool_call or {}
  local diff_cfg = cfg.diff or {}

  return {
    collapsed = diff_cfg.collapsed_label or "+ view diff",
    expanded = diff_cfg.expanded_label or "- view diff",
  }
end

---Check if tool call diffs should start expanded
---@return boolean
function M.should_start_diff_expanded()
  local chat_cfg = M.get_chat_config()
  local cfg = chat_cfg.tool_call or {}
  local diff_cfg = cfg.diff or {}

  return diff_cfg.expanded == true
end

---Check if cursor position should be preserved when expanding/collapsing tool calls
---@return boolean
function M.should_preserve_cursor()
  local chat_cfg = M.get_chat_config()
  local cfg = chat_cfg.tool_call or {}

  return cfg.preserve_cursor == true
end

---Get reasoning labels configuration
---@return table
function M.get_reasoning_labels()
  local chat_cfg = M.get_chat_config()
  local cfg = chat_cfg.reasoning or {}
  local running = cfg.running_label or "Thinking..."
  local finished = cfg.finished_label or "Thought"

  return {
    running = running,
    finished = finished,
  }
end

function M.constants()
  return CONSTANTS
end

return M
