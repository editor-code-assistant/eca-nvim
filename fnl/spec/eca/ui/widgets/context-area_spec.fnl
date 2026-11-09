(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)
(local context-area (require :eca.ui.widgets.context-area))

(defn- with-cleanup
  [cleanup f]
  (let [(ok result) (pcall f)]
    (cleanup)
    (if ok
      result
      (error result 0))))

(defn- render-scenario
  [f]
  (let [original-create (. vim.api :nvim_create_namespace)
        original-clear  (. vim.api :nvim_buf_clear_namespace)
        original-lines  (. vim.api :nvim_buf_set_lines)
        original-mark   (. vim.api :nvim_buf_set_extmark)
        calls           {:namespace [] :clear [] :lines [] :extmarks []}]
    (set vim.api.nvim_create_namespace
         (fn [name]
           (table.insert (. calls :namespace) name)
           7))
    (set vim.api.nvim_buf_clear_namespace
         (fn [buf-id ns start end]
           (table.insert (. calls :clear) [buf-id ns start end])))
    (set vim.api.nvim_buf_set_lines
         (fn [buf-id start end strict lines]
           (table.insert (. calls :lines) [buf-id start end strict lines])))
    (set vim.api.nvim_buf_set_extmark
         (fn [buf-id ns line col opts]
           (table.insert (. calls :extmarks) [buf-id ns line col opts])))
    (with-cleanup
     (fn []
       (set vim.api.nvim_create_namespace original-create)
       (set vim.api.nvim_buf_clear_namespace original-clear)
       (set vim.api.nvim_buf_set_lines original-lines)
       (set vim.api.nvim_buf_set_extmark original-mark))
     (fn []
       (let [widget (context-area.create 3)]
         (widget.add {:text "@file" :hl-group :EcaContextFile})
         (let [result (widget.render 4)]
           (f calls result (widget.get-end-line))))))))

(deftest state

         (testing "tracks unique context items"
                  (let [widget (context-area.create 1)]
                    (widget.add {:text "@file" :hl-group :EcaContextFile})
                    (widget.remove "@file")
                    (is (= false (widget.has-items?))))))

(deftest render

         (testing "writes the context line and highlight and returns its line count"
                  (render-scenario
                   (fn [calls result end-line]
                     (is (= {:namespace ["eca-context-area"]
                             :clear     [[3 7 0 -1]]
                             :lines     [[3 4 4 false ["@file"]]]
                             :extmarks  [[3 7 4 0 {:end_col 5 :hl_group :EcaContextFile}]]
                             :result    1
                             :end-line  5}
                            {:namespace (. calls :namespace)
                             :clear     (. calls :clear)
                             :lines     (. calls :lines)
                             :extmarks  (. calls :extmarks)
                             :result    result
                             :end-line  end-line}))))))
