# Configuration

ECA is highly configurable. This page lists all available options and provides common presets.

## Full configuration reference

```lua
require("eca").setup({
  -- === BASIC SETTINGS ===

  -- Enable debug mode (shows detailed logs)
  debug = false,

  -- Path to ECA binary (empty = automatic download)
  server_path = "",

  -- Extra arguments for ECA server
  server_args = "--log-level info",

  -- Usage string format (tokens/cost)
  usage_string_format = "{messageCost} / {sessionCost}",

  -- === BEHAVIOR ===
  behavior = {
    -- Set keymaps automatically
    auto_set_keymaps = true,

    -- Focus sidebar automatically when opening
    auto_focus_sidebar = true,

    -- Start server automatically
    auto_start_server = false,

    -- Download server automatically if not found
    auto_download = true,

    -- Show status updates in notifications
    show_status_updates = true,
  },

  -- === KEY MAPPINGS ===
  mappings = {
    chat = "<leader>ec",      -- Open chat
    focus = "<leader>ef",     -- Focus sidebar
    toggle = "<leader>et",    -- Toggle sidebar
  },

  -- === CHAT ===
  chat = {
    headers = {
      user = "> ",
      assistant = "",
    },
    welcome = {
      -- If non-empty, overrides server-provided welcome message
      message = "",
      -- Tips appended under the welcome (set {} to disable)
      tips = {
        "Type your message and use CTRL+s to send",
      },
    },
    tool_call = {
      icons = {
        success = "✅",   -- Shown when a tool call succeeds
        error = "❌",     -- Shown when a tool call fails
        running = "⏳",   -- Shown while a tool call is running / has no final status yet
        expanded = "▲",   -- Arrow when the tool call details are expanded
        collapsed = "▶",  -- Arrow when the tool call details are collapsed
      },
      diff_label = {
        collapsed = "+ view diff", -- Label when the diff is collapsed
        expanded = "- view diff",  -- Label when the diff is expanded
      },
    },
    reasoning = {
      -- When true, "Thinking" blocks are expanded by default
      expanded = false,
      -- Customize the labels used for the reasoning block
      running_label = "Thinking...",
      finished_label = "Thought",
    },
  },

  -- === WINDOW SETTINGS ===
  windows = {
    -- Automatic line wrapping
    wrap = true,

    -- Width as percentage of screen (1-100)
    width = 40,

    -- Sidebar header configuration
    sidebar_header = {
      enabled = true,
      align = "center",     -- "left", "center", "right"
      rounded = true,
    },

    -- Input area configuration
    input = {
      prefix = "> ",        -- Input line prefix
      height = 8,           -- Input window height
    },

    -- Edit window configuration
    edit = {
      border = "rounded",   -- "none", "single", "double", "rounded"
      start_insert = true,  -- Start in insert mode
    },

    -- Ask window configuration
    ask = {
      floating = false,     -- Use floating window
      start_insert = true,  -- Start in insert mode
      border = "rounded",
      focus_on_apply = "ours", -- "ours" or "theirs"
    },
  },

  -- === HIGHLIGHTS AND COLORS ===
  highlights = {
    diff = {
      current = "DiffText",   -- Highlight for current diff
      incoming = "DiffAdd",   -- Highlight for incoming diff
    },
  },
})
```

---

## Presets

### Minimalist
```lua
require("eca").setup({
  behavior = { show_status_updates = false },
  windows = { width = 30 },
  chat = {
    headers = {
      user = "> ",
      assistant = "",
    },
  },
})
```

### Visual/UX focused
```lua
require("eca").setup({
  behavior = { auto_focus_sidebar = true },
  windows = {
    width = 50,
    wrap = true,
    sidebar_header = { enabled = true, rounded = true },
    input = { prefix = "💬 ", height = 10 },
  },
  chat = {
    headers = {
      user = "## 👤 You\n\n",
      assistant = "## 🤖 ECA\n\n",
    },
  },
})
```

### Development
```lua
require("eca").setup({
  debug = true,
  server_args = "--log-level debug",
  behavior = {
    auto_start_server = true,
    show_status_updates = true,
  },
  mappings = {
    chat = "<F12>",
    toggle = "<F11>",
    focus = "<F10>",
  },
})
```

### Performance-oriented
```lua
require("eca").setup({
  behavior = {
    auto_focus_sidebar = false,
    show_status_updates = false,
  },
  windows = { width = 25 },
})
```

---

## Notes
- Set `server_path` if you prefer using a local ECA binary.
- For noisy environments, disable `show_status_updates`.
- Adjust `windows.width` to fit your layout.
- Keymaps can be set manually by turning off `auto_set_keymaps`.
