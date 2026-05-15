;; footer-bar widget — statusline footer.
;; Applies our statusline when chat is focused.
;; Other plugins handle statusline for non-chat windows naturally.

(local nvim vim.api)
(local bar (require :eca.ui.components.bar-items))

(fn create [buf-id win-id initial-items]
  (var items (or initial-items []))
  (var active false)

  (fn is-global? []
    (= 3 (nvim.nvim_get_option_value :laststatus {})))

  (fn apply []
    (let [str (bar.render {:items items})]
      (if (is-global?)
        (nvim.nvim_set_option_value :statusline str {})
        (when (and win-id (nvim.nvim_win_is_valid win-id))
          (nvim.nvim_set_option_value :statusline str {:win win-id})))))

  (fn render []
    (set active true)
    (apply)
    0)

  ;; Re-apply on focus (needed for global mode after statusline plugin overwrites)
  (nvim.nvim_create_autocmd :WinEnter
    {:callback (fn []
                 (when (and active (nvim.nvim_buf_is_valid buf-id))
                   (when (= (nvim.nvim_get_current_buf) buf-id)
                     (vim.defer_fn (fn [] (apply)) 10))))})

  (fn update [new-items]
    (set items new-items)
    (when active (apply)))

  (fn get-state [] items)

  {: render : update : get-state})

{: create}
