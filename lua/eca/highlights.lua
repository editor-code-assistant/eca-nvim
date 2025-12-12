local M = {}

function M.setup()
  -- Define highlight groups for ECA
  vim.api.nvim_set_hl(0, "EcaTitle", { fg = "#7aa2f7", bold = true })
  vim.api.nvim_set_hl(0, "EcaUserMessage", { fg = "#9ece6a", bold = true })
  vim.api.nvim_set_hl(0, "EcaAssistantMessage", { fg = "#7dcfff", bold = true })
  vim.api.nvim_set_hl(0, "EcaPrompt", { fg = "#f7768e", bold = true })
  vim.api.nvim_set_hl(0, "EcaCode", { fg = "#bb9af7" })
  vim.api.nvim_set_hl(0, "EcaSeparator", { fg = "#414868" })
  vim.api.nvim_set_hl(0, "EcaError", { fg = "#f7768e", bg = "#3d2b2e" })
  vim.api.nvim_set_hl(0, "EcaSuccess", { fg = "#9ece6a", bg = "#2b3b2e" })
  vim.api.nvim_set_hl(0, "EcaWarning", { fg = "#e0af68", bg = "#3d3a2b" })
  vim.api.nvim_set_hl(0, "EcaInfo", { fg = "#7dcfff", bg = "#2b3a3d" })
  vim.api.nvim_set_hl(0, "EcaToolCall", { link = "Title" })
  vim.api.nvim_set_hl(0, "EcaHyperlink", { link = "Underlined", underline = true })
  vim.api.nvim_set_hl(0, "EcaUsage", { link = "Comment" })
end

return M
