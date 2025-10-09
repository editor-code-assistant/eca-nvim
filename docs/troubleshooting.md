# Troubleshooting

Common issues and how to fix them.

## Server won't start

Symptoms: Chat doesn't respond, "server not running" error

Solutions:
- Check if `curl` and `unzip` are installed
- Try setting `server_path` manually with absolute path
- Check logs with `debug = true` in configuration
- Try `:EcaServerRestart`

```lua
-- Debug configuration
require("eca").setup({
  debug = true,
  server_args = "--log-level debug",
})
```

## Connectivity issues

Symptoms: Download fails, timeouts, network errors

Solutions:
- Check your internet connection
- Ensure firewalls are not blocking requests
- Restart with `:EcaServerRestart`
- Configure a proxy if necessary
- Download the server manually and set `server_path`

## Shortcuts not working

Symptoms: `<leader>ec` doesn't open chat

Solutions:
- Ensure `behaviour.auto_set_keymaps = true`
- Confirm your `<leader>` key (default: `\`)
- Configure shortcuts manually:

```lua
vim.keymap.set("n", "<leader>ec", ":EcaChat<CR>", { desc = "ECA Chat" })
vim.keymap.set("n", "<leader>et", ":EcaToggle<CR>", { desc = "ECA Toggle" })
```

## Windows-specific

Symptoms: Path errors, server not found

Solutions:
- Use WSL2 for better compatibility
- Install curl and unzip on Windows
- Use forward slashes `/` in paths
- Configure `server_path` with `.exe` extension

## Performance issues

Symptoms: Lag when typing, slow responses

Solutions:
- Reduce window width: `windows.width = 25`
- Disable visual updates: `behaviour.show_status_updates = false`
- Use the minimalist configuration preset
