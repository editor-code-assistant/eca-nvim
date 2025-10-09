# Installation

This guide covers system requirements and how to install the ECA Neovim plugin with popular plugin managers.

## System Requirements

### Required
- Neovim >= 0.8.0 (Recommended: >= 0.9.0)
- curl (for automatic server download)
- unzip (for server extraction)
- Internet connection (for initial download and ECA functionality)

### Optional
- plenary.nvim — Utility functions used by some distributions

### Tested Systems
- macOS (Intel and Apple Silicon)
- Linux (Ubuntu, Arch, Fedora, etc.)
- Windows (WSL2 recommended)
- FreeBSD

---

## Install with popular plugin managers

### lazy.nvim (recommended)

```lua
{
  "editor-code-assistant/eca-nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",   -- Required: UI framework
    "nvim-lua/plenary.nvim",  -- Optional: Enhanced async operations
  },
  opts = {}
}
```

Advanced setup example:

```lua
{
  "editor-code-assistant/eca-nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",   -- Required: UI framework
    "nvim-lua/plenary.nvim",  -- Optional: Enhanced async operations
  },
  keys = {
    { "<leader>ec", "<cmd>EcaChat<cr>", desc = "Open ECA chat" },
    { "<leader>ef", "<cmd>EcaFocus<cr>", desc = "Focus ECA sidebar" },
    { "<leader>et", "<cmd>EcaToggle<cr>", desc = "Toggle ECA sidebar" },
  },
  opts = {
    debug = false,
    server_path = "",
    behaviour = {
      auto_set_keymaps = true,
      auto_focus_sidebar = true,
    },
  }
}
```

### packer.nvim

```lua
use {
  "editor-code-assistant/eca-nvim",
  requires = {
    "MunifTanjim/nui.nvim",   -- Required: UI framework
    "nvim-lua/plenary.nvim",  -- Optional: Enhanced async operations
  },
  config = function()
    require("eca").setup({
      -- Your configurations here
    })
  end
}
```

### vim-plug

```vim
" In your init.vim or init.lua
Plug 'editor-code-assistant/eca-nvim'

" Required dependencies
Plug 'MunifTanjim/nui.nvim'

" Optional dependencies (enhanced async operations)
Plug 'nvim-lua/plenary.nvim'

" After the plugins, add:
lua << EOF
require("eca").setup({
  -- Your configurations here
})
EOF
```

### dein.vim

```vim
call dein#add('editor-code-assistant/eca-nvim')

" Required dependencies
call dein#add('MunifTanjim/nui.nvim')

" Optional dependencies (enhanced async operations)
call dein#add('nvim-lua/plenary.nvim')

" Configuration
lua << EOF
require("eca").setup({
  -- Your configurations here
})
EOF
```

### rocks.nvim

```toml
# rocks.toml
[plugins]
"eca-nvim" = { git = "editor-code-assistant/eca-nvim" }

# Required dependencies
"nui.nvim" = { git = "MunifTanjim/nui.nvim" }

# Optional dependencies (enhanced async operations)
"plenary.nvim" = { git = "nvim-lua/plenary.nvim" }
```

### mini.deps

```lua
local add = MiniDeps.add

add({
  source = "editor-code-assistant/eca-nvim",
  depends = {
    "MunifTanjim/nui.nvim",   -- Required: UI framework
    "nvim-lua/plenary.nvim",  -- Optional: Enhanced async operations
  }
})

require("eca").setup({
  -- Your configurations here
})
```

---

## Next steps
- See the Usage guide for getting started with chat and context: [docs/usage.md](./usage.md)
- Explore configuration options: [docs/configuration.md](./configuration.md)
