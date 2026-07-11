;; header-bar widget — fixed header using winbar.

(local nvim vim.api)
(local bar-items (require :eca.ui.components.bar-items))

(fn create [buf-id win-id initial-items]
  (var items (or initial-items []))

  (fn render []
    (nvim.nvim_set_option_value :winbar
      (bar-items.render {:items items}) {:win win-id})
    ;; Blank line for spacing
    (nvim.nvim_buf_set_lines buf-id 0 1 false [""])
    1)

  (fn update [new-items]
    (set items new-items)
    (render))

  (fn get-state [] items)
  (fn line-count [] 1)

  {: render : update : get-state : line-count})

{: create}
