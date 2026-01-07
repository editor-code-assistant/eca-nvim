# Development and Contribution

## Support
- Issues: https://github.com/editor-code-assistant/eca-nvim/issues
- Discussions: https://github.com/editor-code-assistant/eca-nvim/discussions
- Wiki: https://github.com/editor-code-assistant/eca-nvim/wiki

## Local development

1. Clone the repository
   ```bash
   git clone https://github.com/editor-code-assistant/eca-nvim.git
   ```

2. Configure local path (optional)
   ```lua
   require("eca").setup({
     debug = true,
     -- server_path = "/path/to/eca-binary",
   })
   ```

3. Test changes
   ```vim
   :luafile %
   :EcaServerRestart
   ```

## Contributing

1. Fork the repository
2. Create a branch: `git checkout -b feature/new-functionality`
3. Commit your changes: `git commit -m 'Add new functionality'`
4. Push to your branch: `git push origin feature/new-functionality`
5. Open a Pull Request

## Testing

Run tests before submitting a PR:

```bash
# Run all tests with mini.test
nvim --headless -u scripts/minimal_init.lua -c "lua require('mini.test').setup(); MiniTest.run_file('tests/test_eca.lua')"

# Run specific test files
nvim --headless -u scripts/minimal_init.lua -c "lua require('mini.test').setup(); MiniTest.run_file('tests/test_stream_queue.lua')"
nvim --headless -u scripts/minimal_init.lua -c "lua require('mini.test').setup(); MiniTest.run_file('tests/test_sidebar_usage_and_tools.lua')"

# Manual test
nvim -c "lua require('eca').setup({log = {level = vim.log.levels.DEBUG}})"
```

### Test Coverage

The plugin includes comprehensive tests for:
- Core configuration and utilities (`test_eca.lua`, `test_utils.lua`)
- Stream queue and typewriter effect (`test_stream_queue.lua`)
- Sidebar tool calls and reasoning blocks (`test_sidebar_usage_and_tools.lua`)
- Picker commands (`test_picker.lua`, `test_server_picker_commands.lua`)
- Highlight groups (`test_highlights.lua`)

### Highlight Groups

ECA defines custom highlight groups for UI elements:
- `EcaToolCall` - Tool call headers
- `EcaHyperlink` - Clickable diff labels
- `EcaLabel` - Muted text (context labels, reasoning headers)
- `EcaSuccess`, `EcaWarning`, `EcaInfo` - Status indicators

These can be customized in your colorscheme or via `:highlight` commands.
