local Logger = require("eca.logger")

local M = {}

--- Wrapper around snacks.picker to provide a common entrypoint
--- for ECA pickers and handle the snacks dependency consistently.
---@param config snacks.picker.Config
function M.pick(config)
  local has_snacks, snacks = pcall(require, "snacks")
  if not has_snacks then
    Logger.notify("snacks.nvim is not available", vim.log.levels.ERROR)
    return
  end

  return snacks.picker(config)
end

return M
