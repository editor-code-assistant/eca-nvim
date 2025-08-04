# eca-nvim

:warning: **Warning: Work In Progress**
`eca-nvim` is currently a work in progress. This project is in its early stages of development, with limited functionality and a basic user interface. Users should expect bugs and potential issues. Contributions and feedback are welcome as we continue to improve and expand the plugin's capabilities.

## Overview

`eca-nvim` is a Neovim plugin designed to integrate with ECA (Editor Code Assistant), a free and open-source tool that connects LLMs (Language Learning Models) with editors. ECA aims to provide the best possible user experience for AI pair programming by utilizing a well-defined protocol, heavily influenced by the successful implementation of the LSP protocol.

## Installation

**Note:** The plugin supports configuration options. See [Configuration Documentation](docs/configuration.md) for detailed information about all available parameters.

### Using Lazy.nvim

Plugin spec to install eca-nvim via [lazy.nvim](https://github.com/folke/lazy.nvim). The spec will lazy load the plugin, loading only when a Clojure related file is opened.

Create an environment variable within your operating system called `OPENAI_API_KEY` and set it to the value of your OpenAI key.

```lua
return {
  "editor-code-assistant/eca-nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  ft = { "clojure" },  -- lazy load, only run when Clojure file type is opened
  opts = {
    server = {
      spawn_args = {
        env = {OPENAI_API_KEY = vim.env.OPENAI_API_KEY},  -- set key from OS Env Var of same name
      }
    },
  },
}
```

### Using Packer

To install `eca-nvim` with Packer, add the following to your Neovim configuration:

```lua
use({
  'editor-code-assistant/eca-nvim',
  requires = {
    { 'nvim-lua/plenary.nvim' },
  },
  config = function()
    require('eca-nvim').setup({
      server = {
        spawn_args = {
          env = { OPENAI_API_KEY = 'api key from https://platform.openai.com/settings/organization/api-keys' }
        }
      },
    })
  end
})
```

### Local Installation

 To use the plugin locally, clone this repository and replace `'editor-code-assistant/eca-nvim'` with the local path to your cloned repo (e.g., `'<path>/eca-nvim'`) in your Packer configuration. After making this change, run `:PackerSync` in to update the plugin location.

### Other Installation Methods

Installation instructions using other package managers are TODO. Please note that this plugin is under active development, and instructions might change.

## Getting Started

To start the `eca-nvim` plugin, run the following command in Neovim:

```lua
:EcaChat
```

This command will:
1. Install `eca` within the plugin directory if it's not already present
2. Start the ECA server using the default Java command (`/usr/bin/java`)
3. Open a chat window for interaction

> **Note:** By default, the plugin uses Java at `/usr/bin/java`. If your Java installation is in a different location, you can [configure it](docs/configuration.md).

In the chat window, type your message and press `<CR>` (Enter) in Normal mode to submit, or `<C-s>` in Insert mode.

---

To change the model, run:

```
:EcaModel
```

To see logs (if enabled in configuration):

```
:EcaLogs
```

## Contribution

Since this project is in the early stages, contributions and feedback are welcome. See [Architecture Documentation](docs/architecture.md) to understand the project structure and be able to contribute. Stay tuned for more updates and improvements as we continue development.
