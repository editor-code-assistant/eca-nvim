# Configuration

ECA is highly configurable. This page lists all available options and provides common presets.

## Full configuration reference

```lua
require("eca").setup({
  -- === SERVER ===

  -- Path to the ECA binary
  --   - Empty string: automatically download & manage the binary
  --   - Custom path: use your own binary
  server_path = "",

  -- Extra arguments passed to the ECA server (eca start ...)
  server_args = "",

  -- === LOGGING ===
  log = {
    -- Where to display logs inside Neovim
    --   "split"  - use a split window
    --   "float"  - use a floating window
    --   "none"   - disable the log window
    display = "split",

    -- Minimum log level to record
    --   vim.log.levels.TRACE | DEBUG | INFO | WARN | ERROR
    level = vim.log.levels.INFO,

    -- Optional file path for persistent logs (empty = disabled)
    file = "",

    -- Maximum log file size before ECA warns you (in MB)
    max_file_size_mb = 10,
  },

  -- === BEHAVIOR ===
  behavior = {
    -- Set default keymaps automatically
    auto_set_keymaps = true,

    -- Focus the ECA sidebar when opening it
    auto_focus_sidebar = true,

    -- Automatically start the server on plugin setup
    auto_start_server = false,

    -- Automatically download the server if not found
    auto_download = true,

    -- Show status updates (startup, downloads, errors) as notifications
    show_status_updates = true,
  },

  -- === CONTEXT ===
  context = {
    -- Automatically attach repo context (repoMap) when starting new chats
    auto_repo_map = true,
  },

  -- === KEY MAPPINGS ===
  mappings = {
    chat = "<leader>ec",  -- Open chat
    focus = "<leader>ef", -- Focus sidebar
    toggle = "<leader>et",-- Toggle sidebar
  },

  -- === WINDOWS & UI ===
  windows = {
    -- Automatic line wrapping in ECA buffers
    wrap = true,

    -- Width as percentage of Neovim columns (1–100)
    width = 40,

    -- Sidebar header configuration
    sidebar_header = {
      enabled = true,
      align = "center",   -- "left", "center", "right"
      rounded = true,
    },

    -- Input area configuration
    input = {
      prefix = "> ",     -- Input line prefix
      height = 8,          -- Input window height (lines)

      -- Maximum length for web context names in the input area
      web_context_max_len = 20,
    },

    -- Edit window configuration
    edit = {
      border = "rounded", -- "none", "single", "double", "rounded"
      start_insert = true, -- Start in insert mode
    },

    -- Usage line configuration (token / cost display)
    usage = {
      -- Supported placeholders:
      --   {session_tokens}        - raw session token count (e.g. "30376")
      --   {limit_tokens}          - raw token limit (e.g. "400000")
      --   {session_tokens_short}  - shortened session tokens (e.g. "30k")
      --   {limit_tokens_short}    - shortened token limit (e.g. "400k")
      --   {session_cost}          - session cost (e.g. "0.09")
      -- Default: "30k / 400k ($0.09)" ->
      --   "{session_tokens_short} / {limit_tokens_short} (${session_cost})"
      format = "{session_tokens_short} / {limit_tokens_short} (${session_cost})",
    },

    -- Chat window & behavior
    chat = {
      -- Prefixes for each speaker
      headers = {
        user = "> ",
        assistant = "",
      },

      -- Welcome message configuration
      welcome = {
        -- If non-empty, overrides the server-provided welcome message
        message = "",

        -- Tips appended under the welcome (set {} to disable)
        tips = {
          "Type your message and use CTRL+s to send",
        },
      },

      -- Typewriter effect for streaming responses
      typing = {
        enabled = true,       -- Enable/disable typewriter effect
        chars_per_tick = 1,   -- Characters to display per tick (1 = realistic typing)
        tick_delay = 10,      -- Delay in ms between ticks (lower = faster typing)
      },

      -- Tool call display settings
      tool_call = {
        icons = {
          success = "✅",  -- Shown when a tool call succeeds
          error = "❌",    -- Shown when a tool call fails
          running = "⏳",  -- Shown while a tool call is running
          expanded = "▼",  -- Arrow when the tool call details are expanded
          collapsed = "▶", -- Arrow when the tool call details are collapsed
        },
        diff = {
          collapsed_label = "+ view diff", -- Label when the diff is collapsed
          expanded_label = "- view diff",  -- Label when the diff is expanded
          expanded = false,                -- When true, tool diffs start expanded
        },
      },

      -- Reasoning ("Thinking") block behavior
      reasoning = {
        expanded = false,              -- When true, "Thinking" blocks start expanded
        running_label = "Thinking...", -- Label while reasoning is running
        finished_label = "Thought",    -- Base label when reasoning is finished
      },
    },
  },
})
```

---

## Presets

These examples show how to override just a subset of the configuration.

### Minimalist
```lua
require("eca").setup({
  behavior = {
    show_status_updates = false,
  },
  windows = {
    width = 30,
    chat = {
      headers = {
        user = "> ",
        assistant = "",
      },
    },
  },
})
```

### Visual / UX focused
```lua
require("eca").setup({
  behavior = { auto_focus_sidebar = true },
  windows = {
    width = 50,
    wrap = true,
    sidebar_header = { enabled = true, rounded = true },
    input = { prefix = "💬 ", height = 10 },
    chat = {
      headers = {
        user = "## 👤 You\n\n",
        assistant = "## 🤖 ECA\n\n",
      },
      reasoning = {
        expanded = true,
      },
    },
  },
})
```

### Development
```lua
require("eca").setup({
  server_args = "--log-level debug",
  log = {
    level = vim.log.levels.DEBUG,
    display = "split",
  },
})
```

### Typing Speed Presets

```lua
-- Fast typing (2x speed)
require("eca").setup({
  windows = {
    chat = {
      typing = {
        enabled = true,
        chars_per_tick = 2,  -- 2 characters at a time
        tick_delay = 5,      -- 5ms between ticks
      },
    },
  },
})

-- Slow/realistic typing
require("eca").setup({
  windows = {
    chat = {
      typing = {
        enabled = true,
        chars_per_tick = 1,  -- 1 character at a time
        tick_delay = 30,     -- 30ms between ticks (~33 chars/sec)
      },
    },
  },
})

-- Instant display (no typing effect)
require("eca").setup({
  windows = {
    chat = {
      typing = {
        enabled = false,  -- Disable typing effect
      },
    },
  },
})
```

---

## Notes
- Set `server_path` if you prefer using a local ECA binary.
- Use the `log` block to control verbosity and where logs are written.
- `context.auto_repo_map` controls whether repo context is attached automatically.
- `todos` and `selected_code` can be disabled entirely if you prefer a simpler UI.
- Adjust `windows.width` to fit your layout.
- Keymaps can be set manually by turning off `behavior.auto_set_keymaps` and defining your own mappings.
- The `windows.usage.format` string controls how token and cost usage are displayed.
