local M = {}

function M.open(list, opts, callback)
  vim.ui.select(list, opts, callback)
end

return M
