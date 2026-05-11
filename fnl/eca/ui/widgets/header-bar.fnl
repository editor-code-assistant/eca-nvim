;; header-bar widget — fixed header using winbar.

(local nvim vim.api)

(fn create [buf-id win-id initial-items]
  (var items (or initial-items []))

  (fn build-winbar []
    (let [parts (icollect [_ item (ipairs items)]
                  (.. "%#EcaHeaderKey#" item.title "%#EcaHeaderValue#:" item.value))
          count (length parts)]
      (case count
        0 ""
        1 (.. " " (. parts 1))
        2 (.. " " (. parts 1) "%=" (. parts 2) " ")
        _ (let [left (. parts 1)
                right (. parts count)
                center-parts []
                _ (for [i 2 (- count 1)]
                    (table.insert center-parts (. parts i)))
                center (table.concat center-parts "  ")]
            (.. " " left "%=" center "%=" right " ")))))

  (fn render []
    (nvim.nvim_set_option_value :winbar (build-winbar) {:win win-id})
    (nvim.nvim_buf_set_lines buf-id 0 1 false [""])
    1)

  (fn update [new-items]
    (set items new-items)
    (render))

  (fn get-state [] items)
  (fn line-count [] 1)

  {: render : update : get-state : line-count})

{: create}
