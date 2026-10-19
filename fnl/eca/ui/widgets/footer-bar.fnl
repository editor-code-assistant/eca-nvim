(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module eca.ui.widgets.footer-bar)

(local core (require :eca.nfnl.core))
(local bar-items (require :eca.ui.components.bar-items))
(local lualine (require :eca.ui.components.lualine))

(defn- set-native-statusline
  [items]
  (vim.api.nvim_set_option_value :statusline (bar-items.render {: items}) {}))

(defn- apply [items]
  (if (lualine.plugin)
    (lualine.setup items)
    (set-native-statusline items)))

(defn- render [state]
  (core.assoc state :active true)
  (apply (core.get state :items))
  0)

(defn- update
  [state new-items]
  (core.assoc state :items new-items)
  (when (core.get state :active)
    (apply (core.get state :items))))

(defn- get-state [state]
  (core.get state :items))

(defn create
  [_buf-id _win-id initial-items]
  (let [state {:items (or initial-items []) :active false}]
    (vim.api.nvim_create_autocmd [:WinEnter :ColorScheme]
                                 {:callback (fn []
                                              (when (core.get state :active)
                                                (vim.defer_fn (fn []
                                                                (apply (core.get state
                                                                                 :items)))
                                                  10)))})
    {:render    (fn [] (render state))
     :update    (fn [new-items] (update state new-items))
     :get-state (fn [] (get-state state))}))
