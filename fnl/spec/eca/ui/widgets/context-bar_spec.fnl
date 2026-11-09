(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)
(local context-bar (require :eca.ui.widgets.context-bar))

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
        original-lines  (. vim.api :nvim_buf_set_lines)
        original-mark   (. vim.api :nvim_buf_set_extmark)
        calls           {:namespace [] :lines [] :extmarks []}]
    (set vim.api.nvim_create_namespace
         (fn [name]
           (table.insert (. calls :namespace) name)
           8))
    (set vim.api.nvim_buf_set_lines
         (fn [buf-id start end strict lines]
           (table.insert (. calls :lines) [buf-id start end strict lines])))
    (set vim.api.nvim_buf_set_extmark
         (fn [buf-id ns line col opts]
           (table.insert (. calls :extmarks) [buf-id ns line col opts])))
    (with-cleanup
     (fn []
       (set vim.api.nvim_create_namespace original-create)
       (set vim.api.nvim_buf_set_lines original-lines)
       (set vim.api.nvim_buf_set_extmark original-mark))
     (fn []
       (let [widget (context-bar.create 2)]
         (widget.add {:text "@file" :hl-group :EcaContextFile})
         (widget.render 3)
         (f calls))))))

(deftest state

         (testing "deduplicates and clears context items"
                  (let [widget (context-bar.create 1)]
                    (widget.add {:text "@file" :hl-group :EcaContextFile})
                    (widget.add {:text "@file" :hl-group :EcaContextFile})
                    (widget.clear)
                    (is (= 0 (length (. (widget.get-state) :items)))))))

(deftest render

         (testing "writes the context line and highlight through the public renderer"
                  (render-scenario
                   (fn [calls]
                     (is (= {:namespace ["eca-context-bar"]
                             :lines     [[2 3 4 false ["@file"]]]
                             :extmarks  [[2 8 3 0 {:end_col 5 :hl_group :EcaContextFile}]]}
                            {:namespace (. calls :namespace)
                             :lines     (. calls :lines)
                             :extmarks  (. calls :extmarks)}))))))
