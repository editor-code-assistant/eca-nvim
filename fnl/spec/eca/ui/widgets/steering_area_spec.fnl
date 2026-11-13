(import-macros {: deftest : testing : is} :fennel-extras.macros.test)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)
(local steering-area (require :eca.ui.widgets.steering-area))

(defn- with-cleanup
  [cleanup f]
  (let [(ok result) (pcall f)]
    (cleanup)
    (if ok
      result
      (error result 0))))

(deftest state
  (testing "tracks queued steering items"
    (let [widget (steering-area.create 1)]
      (widget.set-items ["check this"])
      (is (= ["check this"]
             (. (widget.get-state) :items))))))

(deftest render
  (testing "writes the steering line, virtual text, extmarks, and cursor state"
    (let [original-create-namespace vim.api.nvim_create_namespace
          original-clear-namespace  vim.api.nvim_buf_clear_namespace
          original-set-lines        vim.api.nvim_buf_set_lines
          original-set-extmark      vim.api.nvim_buf_set_extmark
          original-get-cursor       vim.api.nvim_win_get_cursor
          namespace-calls           []
          clear-calls               []
          line-calls                []
          extmark-calls             []]
      (set vim.api.nvim_create_namespace
           (fn [name]
             (table.insert namespace-calls name)
                           42))
      (set vim.api.nvim_buf_clear_namespace
           (fn [buf-id ns start end]
             (table.insert clear-calls [buf-id ns start end])))
      (set vim.api.nvim_buf_set_lines
           (fn [buf-id start end strict lines]
             (table.insert line-calls [buf-id start end strict lines])))
      (set vim.api.nvim_buf_set_extmark
           (fn [buf-id ns line col opts]
             (table.insert extmark-calls [buf-id ns line col opts])))
      (set vim.api.nvim_win_get_cursor
           (fn [_] [4 0]))
      (with-cleanup
       (fn []
         (set vim.api.nvim_create_namespace original-create-namespace)
         (set vim.api.nvim_buf_clear_namespace original-clear-namespace)
         (set vim.api.nvim_buf_set_lines original-set-lines)
         (set vim.api.nvim_buf_set_extmark original-set-extmark)
         (set vim.api.nvim_win_get_cursor original-get-cursor))
       (fn []
         (let [widget (steering-area.create 7)]
           (widget.set-items ["check this"])
           (let [rendered-lines    (widget.render 3)
                 on-steering-line? (widget.is-on-steering-line?)]
             (is (= {:namespace      ["eca-steering-area"]
                     :clear          [[7 42 0 -1]]
                     :lines          [[7 3 3 false ["-"]]]
                     :extmarks       [[7 42 3 0
                                       {:virt_text     [["Steering: check this ["
                                                         :EcaSteeringLabel]]
                                        :virt_text_pos :inline}]
                                      [7 42 3 1
                                       {:virt_text     [["]" :EcaStopLabel]]
                                        :virt_text_pos :inline}]
                                      [7 42 3 0
                                       {:end_col 1 :hl_group :EcaStopLabel}]]
                     :cursor-on-line true
                     :rendered-lines 1}
                    {:namespace      namespace-calls
                     :clear          clear-calls
                     :lines          line-calls
                     :extmarks       extmark-calls
                     :cursor-on-line on-steering-line?
                     :rendered-lines rendered-lines})))))))))
