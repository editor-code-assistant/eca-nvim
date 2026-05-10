;; Neovim API adapter — flat functions wrapping vim.api.*
;; This is the ONLY file that touches vim.api.* directly.
;; Every other module uses these functions instead of calling Neovim directly.

(local nvim vim.api)

;; ── Buffer ──────────────────────────────────────────────

(fn buf-set-lines [buf start end lines]
  (nvim.nvim_buf_set_lines buf start end false lines))

(fn buf-get-lines [buf start end]
  (nvim.nvim_buf_get_lines buf start end false))

(fn buf-line-count [buf]
  (nvim.nvim_buf_line_count buf))

(fn buf-is-valid [buf]
  (and (not= nil buf) (nvim.nvim_buf_is_valid buf)))

(fn buf-create [opts]
  "Create a new buffer. opts: {: listed : scratch}"
  (let [o (or opts {})]
    (nvim.nvim_create_buf
      (if (not= nil o.listed) o.listed false)
      (if (not= nil o.scratch) o.scratch true))))

(fn buf-set-keymap [buf mode lhs rhs opts]
  (nvim.nvim_buf_set_keymap buf mode lhs rhs (or opts {})))

;; ── Window ──────────────────────────────────────────────

(fn win-open [buf opts]
  "Open a new window. Returns win-id."
  (nvim.nvim_open_win buf true (or opts {})))

(fn win-close [win]
  (when (and win (nvim.nvim_win_is_valid win))
    (nvim.nvim_win_close win true)))

(fn win-is-valid [win]
  (and (not= nil win) (nvim.nvim_win_is_valid win)))

(fn win-get-cursor [win]
  (when win (nvim.nvim_win_get_cursor win)))

(fn win-set-cursor [win pos]
  (when win (nvim.nvim_win_set_cursor win pos)))

;; ── Extmarks ────────────────────────────────────────────

(fn create-namespace [name]
  (nvim.nvim_create_namespace name))

(fn buf-set-extmark [buf ns-id line col opts]
  (nvim.nvim_buf_set_extmark buf ns-id line col (or opts {})))

(fn buf-del-extmark [buf ns-id id]
  (nvim.nvim_buf_del_extmark buf ns-id id))

(fn buf-get-extmarks [buf ns-id start end opts]
  (nvim.nvim_buf_get_extmarks buf ns-id start end (or opts {})))

;; ── Options ─────────────────────────────────────────────

(fn set-option [scope id key value]
  "Set an option. scope: :win or :buf. id: win-id or buf-id."
  (match scope
    :win (nvim.nvim_set_option_value key value {:win id})
    :buf (nvim.nvim_set_option_value key value {:buf id})))

(fn get-option [scope id key]
  "Get an option. scope: :win or :buf."
  (match scope
    :win (nvim.nvim_get_option_value key {:win id})
    :buf (nvim.nvim_get_option_value key {:buf id})))

;; ── Highlights ──────────────────────────────────────────

(fn set-hl [ns group opts]
  (nvim.nvim_set_hl ns group opts))

;; ── Commands ────────────────────────────────────────────

(fn create-user-command [name f opts]
  (nvim.nvim_create_user_command name f (or opts {})))

(fn create-autocmd [event opts]
  (nvim.nvim_create_autocmd event opts))

;; ── Keymaps (global) ────────────────────────────────────

(fn set-keymap [mode lhs rhs opts]
  (vim.keymap.set mode lhs rhs (or opts {})))

;; ── Scheduling ──────────────────────────────────────────

(fn schedule [f]
  (vim.schedule f))

(fn defer [f ms]
  (vim.defer_fn f ms))

;; ── Editor info ─────────────────────────────────────────

(fn editor-width []
  (. vim.o :columns))

(fn editor-height []
  (. vim.o :lines))

{;; Buffer
 : buf-set-lines
 : buf-get-lines
 : buf-line-count
 : buf-is-valid
 : buf-create
 : buf-set-keymap
 ;; Window
 : win-open
 : win-close
 : win-is-valid
 : win-get-cursor
 : win-set-cursor
 ;; Extmarks
 : create-namespace
 : buf-set-extmark
 : buf-del-extmark
 : buf-get-extmarks
 ;; Options
 : set-option
 : get-option
 ;; Highlights
 : set-hl
 ;; Commands
 : create-user-command
 : create-autocmd
 ;; Keymaps
 : set-keymap
 ;; Scheduling
 : schedule
 : defer
 ;; Editor
 : editor-width
 : editor-height}
