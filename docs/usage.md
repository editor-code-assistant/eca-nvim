# Usage

Everything you need to get productive with ECA inside Neovim.

## What's New

Recent updates include:

- **Expandable tool calls**: Click `Enter` on tool call headers to show/hide arguments, outputs, and diffs
- **Reasoning blocks**: See ECA's "thinking" process with expandable reasoning content
- **Typewriter effect**: Responses stream with a configurable typing animation (can be disabled)
- **Enhanced MCP display**: See active vs. registered MCP server counts with status indicators
- **Debug commands**: `:EcaServerMessages` and `:EcaServerTools` for inspecting server state
- **Better usage display**: Shortened token counts (e.g., "30k / 400k") with customizable format
- **Improved highlights**: New `EcaToolCall`, `EcaHyperlink`, and `EcaLabel` highlight groups

## Quick Start

1. Install the plugin using any package manager
2. Restart Neovim or reload your configuration
3. Open a file you want to analyze
4. Run `:EcaChat` or press `<leader>ec`
5. On first run, the server downloads automatically
6. Type your question and press `Ctrl+S` to send

---

## Available Commands

| Command | Description | Example |
|--------|-------------|---------|
| `:EcaChat` | Open ECA chat sidebar | `:EcaChat` |
| `:EcaToggle` | Toggle sidebar visibility | `:EcaToggle` |
| `:EcaFocus` | Focus ECA sidebar | `:EcaFocus` |
| `:EcaClose` | Close ECA sidebar | `:EcaClose` |
| `:EcaChatAddFile [file]` | Add a file as context for the current chat | `:EcaChatAddFile lua/eca/sidebar.lua` |
| `:EcaChatRemoveFile [file]` | Remove a file context from the current chat | `:EcaChatRemoveFile lua/eca/sidebar.lua` |
| `:EcaChatAddSelection` | Add current visual selection as a file-range context | `:EcaChatAddSelection` |
| `:EcaChatAddUrl` | Add a URL as "web" context | `:EcaChatAddUrl` |
| `:EcaChatListContexts` | List active contexts for the current chat | `:EcaChatListContexts` |
| `:EcaChatClearContexts` | Clear all contexts for the current chat | `:EcaChatClearContexts` |
| `:EcaServerStart` | Start ECA server manually | `:EcaServerStart` |
| `:EcaServerStop` | Stop ECA server | `:EcaServerStop` |
| `:EcaServerRestart` | Restart ECA server | `:EcaServerRestart` |
| `:EcaServerMessages` | Display server messages (for debugging) | `:EcaServerMessages` |
| `:EcaServerTools` | Display registered server tools | `:EcaServerTools` |
| `:EcaSend <message>` | Send message directly (without opening chat) | `:EcaSend Explain this function` |

Deprecated aliases (still available but log a warning): `:EcaAddFile`, `:EcaAddSelection`, `:EcaRemoveContext`, `:EcaListContexts`, `:EcaClearContexts`. Prefer the `:EcaChat*` variants above.

---

## Keyboard Shortcuts

### Global (default)

| Shortcut | Action |
|----------|--------|
| `<leader>ec` | Open/focus chat |
| `<leader>ef` | Focus on sidebar |
| `<leader>et` | Toggle sidebar |

### Chat

| Shortcut | Action | Context |
|----------|--------|---------|
| `Ctrl+S` | Send message | Insert/Normal mode |
| `Enter` | New line | Insert mode |
| `Enter` (in chat buffer) | Toggle tool call/reasoning block | Normal mode on tool call or reasoning header |
| `Esc` | Exit insert mode | Insert mode |

---

## Using the Chat

### Sending messages
- Type in the input line starting with `> `
- Press `Enter` to insert a new line
- Press `Ctrl+S` to send
- Responses stream in real time with a typewriter effect (configurable)

### Interacting with responses

#### Tool calls
When ECA uses tools (like file editing), tool calls appear in the chat with:
- **Header line**: Shows tool name and status icon (⏳ running, ✅ success, ❌ error)
- **Expandable details**: Press `Enter` on the header to show/hide arguments and outputs
- **Diff view**: If a tool modifies files, a "view diff" label appears below the header. Press `Enter` on this label to expand/collapse the diff

#### Reasoning blocks
When ECA is "thinking" (extended reasoning), you'll see:
- **"Thinking..."** label while reasoning is active
- **"Thought X.XX s"** label when complete, showing elapsed time
- Press `Enter` on the header to expand/collapse the reasoning content

These blocks can be configured to start expanded or collapsed (see Configuration)

### Examples

```markdown
Explain what this function does
```

```markdown
Optimize this code:
[code will be added as context]
```

```markdown
How can I improve the performance of this function?
Consider readability and maintainability.
```

---

## Adding Context

### Current file

```vim
:EcaChatAddFile
```

Adds the current buffer as a file context for the active chat.

### Specific file

```vim
:EcaChatAddFile src/main.lua
:EcaChatAddFile /full/path/to/file.js
```

Pass a path to add that file as context. Relative paths are resolved to absolute paths.

### Code selection

1. Select code in visual mode (`v`, `V`, or `Ctrl+v`)
2. Run `:EcaChatAddSelection`
3. The selected lines will be added as a file-range context (file + line range)

### Web URLs

```vim
:EcaChatAddUrl
```

Prompts for a URL and adds it as a `web` context. The URL label in the input is truncated for display, but the full URL is sent to the server.

### Listing and clearing contexts

```vim
:EcaChatListContexts      " show all active contexts
:EcaChatClearContexts     " remove all contexts from the current chat
:EcaChatRemoveFile        " remove the current file from contexts
```

### Multiple files

```vim
:EcaChatAddFile
:EcaChatAddFile src/utils.lua
:EcaChatAddFile src/config.lua
:EcaChatAddFile tests/test_utils.lua
```

### Context area in the input

When the sidebar is open, the chat input buffer has **two parts**:

1. **First line – context area**: shows one label per active context (e.g. `sidebar.lua `, `sidebar.lua:25-50 ` or a truncated URL).
2. **Below that – message input**: your prompt, prefixed by `> ` (configurable via `windows.input.prefix`).

You normally do not need to edit the first line manually, but you can:

- **Remove a single context**: move the cursor to the corresponding label on the first line and delete it; the context is removed from the current chat while your message text is preserved.
- **Clear all contexts**: delete the whole first line; ECA restores an empty context line and clears all contexts.

#### Examples

**No contexts yet**

```text
@
> Explain this code
```

**Single file context**

```text
@sidebar.lua @
> Explain this code
```

**Two contexts (file + line range)**

```text
@sidebar.lua @sidebar.lua:25-50 @
> Explain this selection
```

If you now delete just the `sidebar.lua:25-50 ` label on the first line, only that context is removed:

```text
@sidebar.lua @
> Explain this selection
```

If instead you delete the **entire first line**, all contexts are cleared. ECA recreates an empty context line internally and keeps your input text:

```text
@
> Explain this selection
```

When typing paths directly with `@` to trigger completion, the input might briefly look like:

```text
@lua/eca/sidebar.lua
> Input text
```

After confirming a completion item, that `@...` reference is turned into a context entry and shown as a short label (for example `sidebar.lua `) in the context area.

---

## Model Context Protocol (MCP) Servers

ECA supports MCP servers for extended functionality. The config display line at the bottom of the sidebar shows:

```
model: <model-name>  behavior: <behavior>  mcps: 2/3
```

Where:
- The first number (2) is the count of **active MCPs** (starting + running)
- The second number (3) is the **total registered MCPs**

**Status indicators**:
- Gray text: One or more MCPs are still starting
- Red text: One or more MCPs failed to start
- Normal text: All MCPs are running successfully

Use `:EcaServerTools` to see which tools are available from your MCP servers.

### Context completion and `@` / `#` path shortcuts

Inside the input (filetype `eca-input`):

- Typing `@` or `#` followed by part of a path triggers context completion (via the provided `cmp`/`blink` sources).
- Selecting a completion item in the **context area line** automatically adds that item as a context for the current chat and shows it as a label on the first line.

Semantics of the two prefixes:

- **`@` prefix** – *inline content*:
  - `@path/to/file.lua` means: "resolve this to the file contents and send those contents to the model".
  - The server expands the `@` reference to the actual file content before forming the prompt.
- **`#` prefix** – *path reference*:
  - `#path/to/file.lua` means: "send the full absolute path; the model will fetch and read the file itself".
  - The server keeps it as a path reference in the prompt so the model can look up the file by path.

In both cases, when you send a message any occurrences like:

```text
@relative/path/to/file.lua
#another/path
```

are first expanded to absolute paths on the Neovim side (including `~` expansion). The difference is how the server then interprets `@` (inline file contents) versus `#` (path-only reference that the model resolves).

---

## Common Use Cases

### Code analysis
```markdown
> Analyze this file and tell me if there are performance issues
```

### Debugging
```markdown
> This code is returning an error. Can you help me identify the problem?
[add the file as context first]
```

### Documentation
```markdown
> Generate JSDoc documentation for these functions
```

### Refactoring
```markdown
> How can I refactor this code to use ES6+ features?
```

### Testing
```markdown
> Create unit tests for this function
```

### Optimization
```markdown
> Suggest improvements to optimize this algorithm
```

---

## Recommended Workflow

1. Open the file you want to analyze
2. Add as context: `:EcaChatAddFile`
3. Open chat: `<leader>ec`
4. Ask your question:
   ```markdown
   > Explain what this function does and how I can improve it
   ```
5. Send with `Ctrl+S`
6. Read the response and implement suggestions
7. Continue the conversation for clarifications

---

## Advanced Commands

### Server management

```vim
" Restart if there are issues
:EcaServerRestart

" Stop temporarily
:EcaServerStop

" Start again
:EcaServerStart

" Debug: view server messages
:EcaServerMessages

" Debug: view registered tools
:EcaServerTools
```

### Quick commands

```vim
" Send message directly (without opening chat)
:EcaSend Explain this line of code

" Focus on chat if already open
:EcaFocus

" Toggle chat visibility
:EcaToggle
```

---

## Typewriter Effect

ECA displays streaming responses with a configurable typewriter effect for a more natural reading experience.

### Configuration

```lua
require("eca").setup({
  windows = {
    chat = {
      typing = {
        enabled = true,        -- Enable/disable typewriter effect
        chars_per_tick = 1,    -- Characters per tick (higher = faster)
        tick_delay = 10,       -- Delay in ms between ticks (lower = faster)
      },
    },
  },
})
```

### Presets

**Fast typing (2x speed)**:
```lua
typing = { enabled = true, chars_per_tick = 2, tick_delay = 5 }
```

**Slow/realistic typing**:
```lua
typing = { enabled = true, chars_per_tick = 1, tick_delay = 30 }
```

**Instant display (no effect)**:
```lua
typing = { enabled = false }
```

---

## Tips and Tricks

### Productivity
1. Use `:EcaChatAddFile` before asking about specific code
2. Combine contexts: add multiple related files
3. Be specific: detailed questions generate better responses
4. Use Markdown: ECA understands Markdown formatting

### Workflows

#### Code review
```markdown
> Analyze this code and suggest improvements:
- Performance
- Readability
- Best practices
- Possible bugs
```

#### Test creation
```markdown
> Create comprehensive unit tests for this function, including:
- Success cases
- Error cases
- Edge cases
- Mocks if necessary
```

#### Documentation
```markdown
> Generate complete documentation for this module:
- General description
- Parameters and types
- Usage examples
- Possible exceptions
```

### Custom shortcuts

```lua
-- More convenient shortcuts
vim.keymap.set("n", "<F12>", ":EcaChat<CR>")
vim.keymap.set("n", "<F11>", ":EcaToggle<CR>")
vim.keymap.set("v", "<leader>ea", ":EcaChatAddSelection<CR>")

-- Shortcut to add current file
vim.keymap.set("n", "<leader>ef", function()
  vim.cmd("EcaChatAddFile " .. vim.fn.expand("%"))
end)
```
