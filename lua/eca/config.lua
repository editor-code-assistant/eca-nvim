---@class eca.Config
local M = {}

---@class eca.Config
M._defaults = {
  server_path = "", -- Path to the ECA binary, will download automatically if empty
  server_args = "", -- Extra args for the eca start command
  log = {
    display = "split",
    level = vim.log.levels.INFO,
    file = "",
    max_file_size_mb = 10, -- Maximum log file size in MB before warning
  },
  behavior = {
    auto_set_keymaps = true,
    auto_focus_sidebar = true,
    auto_start_server = false, -- Automatically start server on setup
    auto_download = true, -- Automatically download server if not found
    show_status_updates = true, -- Show status updates in notifications
    preserve_chat_history = false, -- When true, chat history is preserved across sidebar open/close cycles
  },
  context = {
    auto_repo_map = true, -- Automatically add repoMap context when starting new chat
  },
  mappings = {
    chat = "<leader>ec",
    focus = "<leader>ef",
    toggle = "<leader>et",
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
      web_context_max_len = 20, -- Maximum length for web context names in input
    },
    edit = {
      border = "rounded",
      start_insert = true, -- Start insert mode when opening the edit window
    },
    usage = {
      --- Supported placeholders:
      ---   {session_tokens}        - raw session token count (e.g. "30376")
      ---   {limit_tokens}          - raw token limit (e.g. "400000")
      ---   {session_tokens_short}  - shortened session tokens (e.g. "30k")
      ---   {limit_tokens_short}    - shortened token limit (e.g. "400k")
      ---   {session_cost}          - session cost (e.g. "0.09")
      --- Default: "30k / 400k ($0.09)" -> "{session_tokens_short} / {limit_tokens_short} (${session_cost})"
      format = "{session_tokens_short} / {limit_tokens_short} (${session_cost})",
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
      typing = {
        enabled = true,        -- Enable typewriter effect for streaming responses
        chars_per_tick = 1,    -- Number of characters to display per tick (1 = realistic typing)
        tick_delay = 10,       -- Delay in milliseconds between ticks (lower = faster)
      },
      tool_call = {
        icons = {
          success = "✅",   -- Shown when a tool call succeeds
          error = "❌",     -- Shown when a tool call fails
          running = "⏳",   -- Shown while a tool call is running / has no final status yet
          expanded = "▼",   -- Arrow when the tool call details are expanded
          collapsed = "▶",  -- Arrow when the tool call details are collapsed
        },
        diff = {
          collapsed_label = "+ view diff", -- Label when the diff is collapsed
          expanded_label = "- view diff",  -- Label when the diff is expanded
          expanded = false,                -- When true, tool diffs start expanded
        },
        preserve_cursor = true,           -- When true, cursor position is preserved when expanding/collapsing
      },
      reasoning = {
        expanded = false,              -- When true, "Thinking" blocks start expanded
        running_label = "Thinking...", -- Label while reasoning is running
        finished_label = "Thought",    -- Base label when reasoning is finished
      },
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
