(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(defn- with-cleanup
  [cleanup f]
  (let [(ok result) (pcall f)]
    (cleanup)
    (if ok
        result
        (error result 0))))

(defn- with-api-stubs
  [stubs f]
  (let [originals {}]
    (each [name stub (pairs stubs)]
      (tset originals name (. vim.api name))
      (tset vim.api name stub))
    (with-cleanup
     (fn []
       (each [name original (pairs originals)]
         (tset vim.api name original)))
      f)))

(defn- with-message-list
  [f]
  (let [original-message (. package.loaded :eca.ui.components.message)
        original-widget (. package.loaded :eca.ui.widgets.message-list)
        original-defer-fn vim.defer_fn]
    (set (. package.loaded :eca.ui.components.message)
         {:render (fn [_] {:lines [""] :highlights []})})
    (set (. package.loaded :eca.ui.widgets.message-list) nil)
    (with-cleanup
     (fn []
       (set (. package.loaded :eca.ui.components.message) original-message)
       (set (. package.loaded :eca.ui.widgets.message-list) original-widget)
       (set vim.defer_fn original-defer-fn))
      (fn []
        (with-api-stubs
         {:nvim_create_namespace (fn [_] 1)
          :nvim_buf_clear_namespace (fn [_ _ _ _] nil)
          :nvim_buf_set_extmark (fn [_ _ _ _ _] nil)
          :nvim_buf_set_lines (fn [_ _ _ _ _] nil)
          :nvim_buf_line_count (fn [_] 2)
          :nvim_buf_set_text (fn [_ _ _ _ _ _ _] nil)}
          (fn []
            (f (require :eca.ui.widgets.message-list))))))))

(defn- append-after-streaming-scenario []
  (let [defer-calls []]
    (with-message-list
     (fn [message-list]
       (set vim.defer_fn
            (fn [callback _]
              (table.insert defer-calls callback)
              :timer))
       (let [widget (message-list.create 1)]
         (widget.append-message {:id :first :content "abc" :streaming? true})
         (let [(ok result) (pcall (fn []
                                    (widget.append-message
                                     {:id :second :content "done" :streaming? true})))]
           {:ok ok
            :result result
            :streaming-id (. (widget.get-state) :streaming-id)
            :defer-calls defer-calls}))))))

(deftest append-message
  (testing "finishes an active stream before starting the next stream"
    (is (= true (. (append-after-streaming-scenario) :ok)))))
