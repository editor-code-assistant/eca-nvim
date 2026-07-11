(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module eca.ui.components.lualine)

(defn enabled?
  []
  (let [(ok _) (pcall require :lualine)]
    ok))

(defn- build-sections
  [items]
  (let [head :lualine_a
        tail [:lualine_z :lualine_y :lualine_x]]
    {:lualine_a ["%#EcaHeaderValue#Teste"]}))

(defn setup
  [items]
  (let [(_ m) (pcall require :lualine)
        sections (build-sections items)]
    (m.setup {:extensions [{:filetypes [:eca-chat]
                            : sections}]})))
