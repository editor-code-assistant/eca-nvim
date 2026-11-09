(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)
(local header-bar (require :eca.ui.widgets.header-bar))

(defn- with-cleanup
  [cleanup f]
  (let [(ok result) (pcall f)]
    (cleanup)
    (if ok
      result
      (error result 0))))

(defn- render-scenario
  [f]
  (let [original-option (. vim.api :nvim_set_option_value)
        original-lines  (. vim.api :nvim_buf_set_lines)
        calls           {:options [] :lines []}]
    (set vim.api.nvim_set_option_value
         (fn [name value opts]
           (table.insert (. calls :options) [name value opts])))
    (set vim.api.nvim_buf_set_lines
         (fn [buf-id start end strict lines]
           (table.insert (. calls :lines) [buf-id start end strict lines])))
    (with-cleanup
     (fn []
       (set vim.api.nvim_set_option_value original-option)
       (set vim.api.nvim_buf_set_lines original-lines))
     (fn []
       (let [widget (header-bar.create 1 2 [{:value "x"}])
             result (widget.render)]
         (f calls result (widget.line-count)))))))

(deftest state

         (testing "exposes initial items and fixed line count"
                  (let [options []
                        canvas  {:set-option (fn [_ name value] (table.insert options [name value]))}
                        widget  (header-bar.create 1 2 [{:value "x"}])]
                    (is (= {:items [{:value "x"}] :line-count 1}
                           {:items      (widget.get-state)
                            :line-count (widget.line-count)})))))

(deftest render

         (testing "writes the winbar and spacing line and returns one line"
                  (render-scenario
                   (fn [calls result line-count]
                     (is (= {:options    [[:winbar " %#EcaHeaderValue#x" {:win 2}]]
                             :lines      [[1 0 1 false [""]]]
                             :result     1
                             :line-count 1}
                            {:options    (. calls :options)
                             :lines      (. calls :lines)
                             :result     result
                             :line-count line-count}))))))
