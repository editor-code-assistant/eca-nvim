---@class eca.Config
local M = {}

---@class eca.Config
M._defaults = {
  ---@type string
  server_path = "", -- Path to the ECA binary, will download automatically if empty
  ---@type string
  server_args = "", -- Extra args for the eca start command
  ---@type string
  usage_string_format = "{messageCost} / {sessionCost}",
  ---@class eca.LogConfig
  ---@field display 'popup'|'split'
  ---@field level integer
  ---@field file string
  ---@field max_file_size_mb number
  log = {
    display = "split",
    level = vim.log.levels.INFO,
    file = "",
    max_file_size_mb = 10, -- Maximum log file size in MB before warning
  },
  behaviour = {
    auto_set_keymaps = true,
    auto_focus_sidebar = true,
    auto_start_server = true, -- Automatically start server on setup
    auto_download = true, -- Automatically download server if not found
    show_status_updates = true, -- Show status updates in notifications
  },
  context = {
    auto_repo_map = true, -- Automatically add repoMap context when starting new chat
  },
  todos = {
    enabled = true, -- Enable todos functionality
    max_height = 5, -- Maximum height for todos container
  },
  selected_code = {
    enabled = true, -- Enable selected code display
    max_height = 8, -- Maximum height for selected code container
  },
  mappings = {
    chat = "<leader>ec",
    focus = "<leader>ef",
    toggle = "<leader>et",
  },
  chat = {
    headers = {
      user = "> ",
      assistant = "",
    },
    welcome = {
      message = "", -- If non-empty, overrides server-provided welcome message
      tips = {
        "Type your message and use CTRL+s to send", -- Tips appended under the welcome (set empty list {} to disable)
      },
    },
  },
  windows = {
    wrap = true,
    width = 40, -- Window width as percentage (40 = 40% of screen width)
    sidebar_header = {
      enabled = true,
      align = "center",
      rounded = true,
    },
    input = {
      prefix = "> ",
      height = 8, -- Height of the input window
    },
    edit = {
      border = "rounded",
      start_insert = true, -- Start insert mode when opening the edit window
    },
  },
}

---@type eca.Config
M.options = M._defaults

---@param opts eca.Config
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M._defaults, opts or {})
end

---@param override eca.Config
function M.override(override)
  M.options = vim.tbl_deep_extend("force", M.options, override)
end

function M.get_window_width()
  return math.ceil(vim.o.columns * (M.options.windows.width / 100))
end

function M.get_input_height()
  return M.options.windows.input.height
end

return setmetatable(M, {
  __index = function(_, k)
    if M.options[k] ~= nil then
      return M.options[k]
    end
    return M._defaults[k]
  end,
})
