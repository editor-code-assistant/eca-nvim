-- Plugin specification for package managers
return {
  name = "eca-nvim",
  description = "ECA (Editor Code Assistant) integration for Neovim",
  dependencies = {
    "MunifTanjim/nui.nvim",   -- UI framework (required)
    "nvim-lua/plenary.nvim",  -- For async operations (optional)
  },
  config = function()
    require("eca").setup({
      -- Default configuration
      server_path = "",
      server_args = "",
      log = {
        display = "split", -- "split" or "popup"
        level = vim.log.levels.INFO,
        file = "", -- Empty string uses default path
        max_file_size_mb = 10,
      },
      behaviour = {
        auto_set_keymaps = true,
        auto_focus_sidebar = true,
      },
      mappings = {
        chat = "<leader>ec",
        focus = "<leader>ef",
        toggle = "<leader>et",
      },
    })
  end,
  keys = {
    { "<leader>ec", "<cmd>EcaChat<cr>", desc = "Open ECA chat" },
    { "<leader>ef", "<cmd>EcaFocus<cr>", desc = "Focus ECA sidebar" },
    { "<leader>et", "<cmd>EcaToggle<cr>", desc = "Toggle ECA sidebar" },
  },
  cmd = {
    "EcaChat",
    "EcaToggle", 
    "EcaFocus",
    "EcaClose",
    "EcaAddFile",
    "EcaAddSelection",
    "EcaServerStart",
    "EcaServerStop",
    "EcaServerRestart",
    "EcaServerStatus",
    "EcaSend",
    "EcaLogs",
  },
}
