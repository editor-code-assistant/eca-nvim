# UI Architecture

> This document covers only the **UI layer** of eca-nvim.
> Other parts of the project (server communication, JSONRPC protocol, ECA process
> management, etc.) are not described here and will live outside of `ui/`.

## Directory Structure

The UI code lives under `fnl/eca/ui/`. Files at the `fnl/eca/` root (`api.fnl`,
`init.fnl`, `commands.fnl`) are shared infrastructure used by the UI and future
modules alike.

```
fnl/eca/
├── api.fnl                          # Neovim API adapter (flat functions, shared)
├── init.fnl                         # Entry point: setup(opts)
├── commands.fnl                     # User commands (:EcaChat, :EcaChatSubmit, etc.)
│
└── ui/                              # ← Everything below is UI-specific
    ├── canvas.fnl                   # Canvas protocol (abstract contract)
    ├── builder.fnl                  # Orchestrator: builds canvas, manages widgets
    ├── highlights.fnl               # Highlight group definitions
    │
    ├── components/                  # Stateless pure functions
    │   ├── key-value.fnl            # "key:value" pairs
    │   ├── separator.fnl           # Horizontal separator lines
    │   ├── icon.fnl                 # Unicode icons (⏵ ⏷ ⏳ ✅ ❌ 🚧)
    │   ├── message.fnl             # Chat message blocks
    │   ├── prompt-prefix.fnl       # "> " or "⏳ " prefix
    │   ├── button.fnl              # Action buttons
    │   ├── context-item.fnl        # @file @repoMap @cursor mentions
    │   ├── spinner.fnl             # Loading animation frames
    │   └── usage.fnl               # Token/cost display
    │
    └── widgets/                     # Stateful, compose components
        ├── header-bar.fnl           # Winbar: model, agent, mcps
        ├── message-list.fnl        # Scrollable message list
        ├── expandable-block.fnl    # Collapsible blocks (tool calls, thinking)
        ├── prompt-area.fnl         # Separator + contexts + input
        ├── context-bar.fnl         # Attached @context items
        ├── status-bar.fnl          # Statusline: workspace, usage, trust
        └── tab-bar.fnl             # Multiple chat tabs
```

## Layers

The architecture has four distinct layers, each with a clear responsibility:

### 1. `api.fnl` — Neovim Adapter

A flat module of functions that wrap `vim.api.*`. This is the **only file** in the
project that calls Neovim APIs directly. Everything else goes through it.

```fennel
;; Example usage:
(local api (require :eca.api))
(api.buf-set-lines buf 0 -1 ["hello"])
(api.set-hl 0 "EcaUser" {:fg "#61afef" :bold true})
(api.create-user-command "EcaChat" my-fn {})
```

This keeps the codebase portable and testable — you can mock `api` in tests
without touching Neovim internals.

### 2. Components — Stateless Render Functions

Pure functions that receive props and return **declarative render data**
(text + highlight metadata). They never call any API, never hold state.

```fennel
;; Component signature:
;; (render props) → {: text : hl-group} or {: line : highlights} or {: lines : highlights}

(local icon (require :eca.ui.components.icon))
(icon.render {:name :success})
;; → {:text "✅" :hl-group :EcaToolCallSuccess}
```

### 3. Widgets — Stateful UI Elements

Compose multiple components, maintain local state, and render to the buffer
through an injected **canvas**.

```fennel
;; Widget signature:
;; (create canvas ?initial-state) → {: render : update : get-state ...}

(local header-bar (require :eca.ui.widgets.header-bar))
(local widget (header-bar.create canvas {:model "claude" :agent "coder"}))
(widget.render)
(widget.update {:model "gpt-4o"})
```

Widgets receive the canvas at creation time via dependency injection. They never
import `api.fnl` or `vim.api` directly.

### 4. Builder — Orchestrator

The builder is the integration point. It:

1. Receives the `api` module as a dependency
2. **Builds a canvas** from api functions (binding them to a specific buf/win)
3. Creates and manages all widgets
4. Exposes the public chat-ui API
5. Wires up callbacks (on-submit, on-approve, etc.)

```fennel
(local builder (require :eca.ui.builder))
(local chat-ui (builder.create-chat-ui
  {:api api
   :on-submit (fn [text] ...)
   :opts {:ui {:width 0.4}}}))
(chat-ui.toggle)
```

## Data Flow

```
                    ┌──────────────┐
                    │   init.fnl   │  setup(opts) → creates chat-ui
                    └──────┬───────┘
                           │ injects api + callbacks
                           ▼
                    ┌──────────────┐
                    │ builder.fnl  │  builds canvas from api, creates widgets
                    └──────┬───────┘
                           │ injects canvas
                           ▼
                    ┌──────────────┐
                    │   widgets/   │  stateful, compose components
                    └──────┬───────┘
                           │ calls render()
                           ▼
                    ┌──────────────┐
                    │ components/  │  pure (props) → {text, highlights}
                    └──────────────┘

    Rendering pipeline:
    widget.render() → component.render(props) → canvas.set-lines/add-extmark → api.buf-set-lines → vim.api
```


