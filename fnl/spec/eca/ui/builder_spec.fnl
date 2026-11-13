(import-macros {: deftest : testing : is} :fennel-extras.macros.test)
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
  (let [originals (icollect [_ stub (ipairs stubs)] [stub.name (. vim.api stub.name)])]
    (each [_ stub (ipairs stubs)]
          (tset vim.api stub.name stub.value))
    (with-cleanup (fn []
                    (each [_ original (ipairs originals)]
                          (tset vim.api (. original 1) (. original 2))))
                  f)))

(defn- fake-widget
  []
  {:render                 (fn [] 0)
   :update                 (fn [_] nil)
   :get-state              (fn [] {})
   :get-end-line           (fn [] 0)
   :set-start-line         (fn [_] nil)
   :set-welcome            (fn [_] nil)
   :has-items?             (fn [] false)
   :render-highlights      (fn [_] nil)
   :is-on-steering-line?   (fn [] false)
   :clear                  (fn [] nil)
   :set-items              (fn [_] nil)
   :save-live-text         (fn [] "")
   :set-text-internal      (fn [_] nil)
   :set-status-anchor-line (fn [_] nil)
   :set-status             (fn [_] nil)
   :get-text               (fn [] "")
   :add-to-history         (fn [_] nil)
   :set-loading            (fn [_] nil)
   :append-message         (fn [_] nil)
   :update-message         (fn [_ _] nil)
   :finish-streaming       (fn [_] nil)
   :abort-streaming        (fn [_] nil)})

(defn- with-builder
  [f]
  (let [module-names [:eca.ui.builder :eca.ui.highlights :eca.ui.widgets.header-bar
                      :eca.ui.widgets.message-list :eca.ui.widgets.context-area
                      :eca.ui.widgets.steering-area :eca.ui.widgets.prompt-area
                      :eca.ui.widgets.footer-bar]
        originals    (icollect [_ name (ipairs module-names)] [name (. package.loaded name)])
        widget       (fake-widget)
        modules      {:eca.ui.highlights            {:setup (fn [] nil)}
                      :eca.ui.widgets.header-bar    {:create (fn [_ _ _] widget)}
                      :eca.ui.widgets.message-list  {:create (fn [_ _] widget)}
                      :eca.ui.widgets.context-area  {:create (fn [_] widget)}
                      :eca.ui.widgets.steering-area {:create (fn [_] widget)}
                      :eca.ui.widgets.prompt-area   {:create (fn [_ _] widget)}
                      :eca.ui.widgets.footer-bar    {:create (fn [_ _ _] widget)}}]
    (each [name module (pairs modules)]
          (tset package.loaded name module))
    (tset package.loaded :eca.ui.builder nil)
    (with-cleanup (fn []
                    (each [_ original (ipairs originals)]
                          (tset package.loaded (. original 1) (. original 2))))
                  (fn []
                    (let [builder (require :eca.ui.builder)]
                      (f builder))))))

(defn- create-chat-ui-scenario
  []
  (with-builder
   (fn [builder]
     (with-api-stubs [{:name  :nvim_create_buf
                       :value (fn [_ _] 11)}
                      {:name  :nvim_open_win
                       :value (fn [_ _ _] 22)}
                      {:name  :nvim_buf_is_valid
                       :value (fn [buf] (= 11
                                           buf))}
                      {:name  :nvim_win_is_valid
                       :value (fn [win] (= 22
                                           win))}
                      {:name  :nvim_win_close
                       :value (fn [_ _] nil)}
                      {:name  :nvim_buf_set_name
                       :value (fn [_ _] nil)}
                      {:name  :nvim_set_option_value
                       :value (fn [_ _ _] nil)}
                      {:name  :nvim_buf_set_lines
                       :value (fn [_ _ _ _ _] nil)}
                      {:name  :nvim_buf_line_count
                       :value (fn [_] 1)}
                      {:name  :nvim_buf_get_lines
                       :value (fn [_ _ _ _] ["> "])}
                      {:name  :nvim_create_namespace
                       :value (fn [_] 1)}
                      {:name  :nvim_buf_clear_namespace
                       :value (fn [_ _ _ _] nil)}
                      {:name  :nvim_buf_set_extmark
                       :value (fn [_ _ _ _ _] 1)}
                      {:name  :nvim_win_get_width
                       :value (fn [_] 80)}
                      {:name  :nvim_win_set_cursor
                       :value (fn [_ _] nil)}
                      {:name  :nvim_buf_attach
                       :value (fn [_ _ _] true)}
                      {:name  :nvim_create_autocmd
                       :value (fn [_ _] nil)}]
                     (fn []
                       (let [ui (builder.create-chat-ui {:on-submit (fn [_])
                                                         :on-stop   (fn [])
                                                         :opts      {}})]
                         (ui.open)
                         (let [opened {:open? (ui.is-open?)
                                       :buf   (ui.get-buf-id)}]
                           (ui.close)
                           {:opened opened
                            :closed (ui.is-open?)})))))))

(deftest create-chat-ui
  (let [state (create-chat-ui-scenario)]

    (testing "opens and exposes its buffer through the public API"
      (is (= {:open? true :buf 11}
             state.opened)))

    (testing "close makes the public open state false"
      (is (= false
             state.closed)))))
