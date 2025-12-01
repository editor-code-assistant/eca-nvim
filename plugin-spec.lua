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
      usage_string_format = "{messageCost} / {sessionCost}",
      log = {
        display = "split", -- "split" or "popup"
        level = vim.log.levels.INFO,
        file = "", -- Empty string uses default path
        max_file_size_mb = 10,
      },
      behavior = {
        auto_set_keymaps = true,
        auto_focus_sidebar = true,
        auto_start_server = false,
        auto_download = true,
        show_status_updates = true,
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
    "EcaChatAddFile",
    "EcaRemoveContext",
    "EcaChatRemoveFile",
    "EcaAddSelection",
    "EcaChatAddSelection",
    "EcaChatAddUrl",
    "EcaListContexts",
    "EcaChatListContexts",
    "EcaClearContexts",
    "EcaChatClearContexts",
    "EcaServerStart",
    "EcaServerStop",
    "EcaServerRestart",
    "EcaServerMessages",
    "EcaSend",
    "EcaLogs",
    "EcaDebugWidth",
    "EcaRedownload",
    "EcaStopResponse",
    "EcaFixTreesitter",
    "EcaChatSelectModel",
    "EcaChatSelectBehavior",
  },
}
