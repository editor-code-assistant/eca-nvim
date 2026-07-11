(import-macros {: if-let} :eca.nfnl.macros)

(local {: assoc : constantly : get : vals : concat} (require :eca.nfnl.core))
(local bar-items (require :eca.ui.components.bar-items))
(local lualine (require :eca.ui.components.lualine))

(comment ; ; (fn lualine-extension [lualine] ;   (let [; config (lualine.get_config) ;         ; extensions (get config :extensions {}) ;         sections {:lualine_a ["~/dev/eca-nvim"] ;                   :lualine_y ["⏱ 0s"] ;                   :lualine_z ["0/200K ($0.00)"]} ;         eca-chat-extension {:init (fn [] (print :hi)) ;                             :filetypes [:eca-chat] ;                             : sections ;                             :inactive_sections sections} ;         ; extensions+eca-chat (assoc extensions :eca-chat eca-chat-extension)
  ;         ] ;     {:extensions [{:filetypes [:eca-chat] ;                    :sections {:lualine_a ["%#EcaHeaderValue#Teste"]}}]}))
  (if ;
      (lualine.enabled?)
      (lualine.setup [{:value "~/dev/eca-nvim"}
                      {:value "⏱ 0s"}
                      {:value "0/200K ($0.00)"}])
      (vim.notify "no lualine"))
  ;
  )

(fn create [buf-id win-id initial-items]
  (var items (or initial-items []))
  (var active false)

  (fn apply []
    (if-let [(ok lualine) (pcall require :lualine)]
            (let [my-extension {:sections {:lualine_a [:mode]}}]
              (constantly nil))
            (let [str (bar-items.render {: items})]
              (vim.api.nvim_set_option_value :statusline str {}))))

  (vim.api.nvim_create_autocmd [:WinEnter :ColorScheme]
                               {:callback (fn []
                                            (when active
                                              (vim.defer_fn apply 10)))})

  (fn render []
    (set active true)
    (apply)
    0)

  (fn update [new-items]
    (set items new-items)
    (when active (apply)))

  (fn get-state [] items)

  {: render : update : get-state})

{: create}
