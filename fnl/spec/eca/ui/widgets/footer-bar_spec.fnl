(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(defn- with-cleanup
  [cleanup f]
  (let [(ok result) (pcall f)]
    (cleanup)
    (if ok
        result
        (error result 0))))

(defn- with-api-stub
  [name stub f]
  (let [original (. vim.api name)]
    (tset vim.api name stub)
    (with-cleanup (fn [] (tset vim.api name original)) f)))

(defn- with-footer-bar
  [mocks f]
  (let [original-lualine (. package.loaded :eca.ui.components.lualine)
        original-bar-items (. package.loaded :eca.ui.components.bar-items)
        original-footer-bar (. package.loaded :eca.ui.widgets.footer-bar)]
    (tset package.loaded :eca.ui.components.lualine (or (. mocks :lualine) {}))
    (tset package.loaded :eca.ui.components.bar-items
          (or (. mocks :bar-items) {}))
    (tset package.loaded :eca.ui.widgets.footer-bar nil)
    (with-cleanup (fn []
                    (tset package.loaded :eca.ui.components.lualine
                          original-lualine)
                    (tset package.loaded :eca.ui.components.bar-items
                          original-bar-items)
                    (tset package.loaded :eca.ui.widgets.footer-bar
                          original-footer-bar))
      (fn []
        (with-api-stub :nvim_create_autocmd
          (fn [_ _] nil)
          (fn []
            (f (require :eca.ui.widgets.footer-bar))))))))

(defn- lualine-scenario
  [items]
  (let [setup-calls []]
    {:widget (with-footer-bar {:lualine {:plugin (fn [] true)
                                         :setup (fn [new-items]
                                                  (table.insert setup-calls new-items))}
                               :bar-items {:render (fn [_]
                                                     (error "bar-items.render should not be called"))}}
                (fn [footer-bar]
                  (footer-bar.create 1 2 items)))
     :setup-calls setup-calls}))

(defn- native-scenario
  [items]
  (let [render-calls []]
    {:widget (with-footer-bar {:lualine {:plugin (fn [] false)}
                               :bar-items {:render (fn [opts]
                                                     (table.insert render-calls opts)
                                                     :rendered)}}
                (fn [footer-bar]
                  (footer-bar.create 1 2 items)))
     :render-calls render-calls}))

(defn- capture-set-option
  [f]
  (let [captured {:value nil}]
    (with-api-stub :nvim_set_option_value
      (fn [name value opts] (tset captured :value [name value opts]))
      (fn []
        (f)
        (. captured :value)))))

(defn- create-scenario
  [items]
  (with-footer-bar {}
    (fn [footer-bar]
      (footer-bar.create 1 2 items))))

(deftest create
  (testing "get-state returns the initial items"
           (let [widget (create-scenario [{:value :initial}])]
             (is (= [{:value :initial}] (widget.get-state)))))
  (testing "nil initial items become an empty table"
           (let [widget (create-scenario nil)]
             (is (= [] (widget.get-state))))))

(deftest render
  (testing "returns zero"
           (let [{: widget} (lualine-scenario [{:value :one}])]
             (is (= 0 (widget.render)))))
  (testing "passes the items to lualine.setup when lualine is available"
           (let [{: widget : setup-calls} (lualine-scenario [{:value :one}])]
             (widget.render)
             (is (= [[{:value :one}]] setup-calls))))
  (testing "renders bar-items with the items when lualine is unavailable"
           (let [{: widget : render-calls} (native-scenario [{:value :two}])]
             (capture-set-option widget.render)
             (is (= [{:items [{:value :two}]}] render-calls))))
  (testing "sets the native statusline when lualine is unavailable"
           (let [{: widget} (native-scenario [{:value :two}])]
             (is (= [:statusline :rendered {}] (capture-set-option widget.render))))))

(deftest update
  (testing "before render does not apply"
           (let [{: widget : setup-calls} (lualine-scenario [{:value :initial}])]
             (widget.update [{:value :updated}])
             (is (= [] setup-calls))))
  (testing "before render updates the state"
           (let [{: widget} (lualine-scenario [{:value :initial}])]
             (widget.update [{:value :updated}])
             (is (= [{:value :updated}] (widget.get-state)))))
  (testing "after render applies the new items"
           (let [{: widget : setup-calls} (lualine-scenario [{:value :initial}])]
             (widget.render)
             (widget.update [{:value :later}])
             (is (= [[{:value :initial}] [{:value :later}]] setup-calls))))
  (testing "get-state reflects later updates"
           (let [{: widget} (lualine-scenario [{:value :initial}])]
             (widget.update [{:value :updated}])
             (widget.update [{:value :later}])
             (is (= [{:value :later}] (widget.get-state))))))

