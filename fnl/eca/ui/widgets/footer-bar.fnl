;; footer-bar widget — statusline footer.
;; laststatus=2: per-window statusline.
;; laststatus=3: sets global statusline on focus, restores on blur.

(local nvim vim.api)

(fn create [buf-id win-id initial-items]
  (var items (or initial-items []))
  (var saved-statusline nil)

  (fn build-statusline-str []
    (let [parts (icollect [_ item (ipairs items)]
                  (if item.title
                    (.. "%#EcaHeaderKey#" item.title "%#EcaHeaderValue#:" item.value)
                    (.. "%#EcaHeaderValue#" item.value)))
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

  (fn is-global? []
    (= 3 (nvim.nvim_get_option_value :laststatus {})))

  (fn apply-statusline []
    (let [str (build-statusline-str)]
      (if (is-global?)
        (nvim.nvim_set_option_value :statusline str {})
        (when (and win-id (nvim.nvim_win_is_valid win-id))
          (nvim.nvim_set_option_value :statusline str {:win win-id})))))

  (fn restore-statusline []
    (when (and (is-global?) saved-statusline)
      (nvim.nvim_set_option_value :statusline saved-statusline {})))

  (fn render []
    (apply-statusline)
    0)

  ;; Save original global statusline and manage focus
  (set saved-statusline (nvim.nvim_get_option_value :statusline {}))

  (nvim.nvim_create_autocmd :BufEnter
    {:buffer buf-id
     :callback (fn []
                 ;; Defer to run AFTER statusline plugins have set theirs
                 (vim.defer_fn (fn [] (apply-statusline)) 10))})

  (nvim.nvim_create_autocmd :BufLeave
    {:buffer buf-id
     :callback (fn [] (restore-statusline))})

  (nvim.nvim_create_autocmd :OptionSet
    {:pattern :laststatus
     :callback (fn []
                 (when (nvim.nvim_buf_is_valid buf-id)
                   (apply-statusline)))})

  (fn update [new-items]
    (set items new-items)
    (render))

  (fn get-state [] items)

  {: render : update : get-state})

{: create}
