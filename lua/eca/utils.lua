local uv = vim.uv or vim.loop

local Logger = require("eca.logger")

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

function M.constants()
  return CONSTANTS
end

return M
