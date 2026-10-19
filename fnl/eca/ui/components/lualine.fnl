(import-macros {: module : def : def- : defn : defn-} :eca.nfnl.macros.aniseed)
(import-macros {: when-let} :eca.nfnl.macros)

(module eca.ui.components.lualine)

(local core (require :eca.nfnl.core))

(def- filetype :eca-chat)
(def- tail-slots [:lualine_x :lualine_y :lualine_z :lualine_c :lualine_b])

(defn plugin
  []
  (let [(ok lualine) (pcall require :lualine)]
    (when ok
      lualine)))

(defn- text
  [item]
  (let [title     (core.get item :title nil)
        value     (core.get item :value nil)
        title-str (if title (core.str "%#EcaHeaderKey#" title ":") "")
        value-str (if value (core.str "%#EcaHeaderValue#" value) "")]
    (core.str title-str value-str)))

(defn- add-item
  [sections [i item]]
  (let [slot    (core.get tail-slots (math.min i (core.count tail-slots)))
        current (core.get sections slot [])]
    (core.assoc sections slot (core.concat current [(text item)]))))

(defn- build-sections
  [items]
  (core.reduce add-item {:lualine_a [(text (core.first items))]}
               (core.map-indexed core.identity (core.rest items))))

(defn- eca-extension
  [items]
  {:filetypes [filetype] :sections (build-sections items)})

(defn- eca?
  [ext]
  (core.contains? (core.get ext :filetypes []) filetype))

(defn- register
  [extensions ext]
  (core.concat (core.filter (core.complement eca?) extensions) [ext]))

(defn- register-eca-extension
  [p items]
  (let [config         (p.get_config)
        extensions     (core.get config :extensions [])
        extensions+eca (register extensions (eca-extension items))]
    (p.setup (core.assoc config :extensions extensions+eca))))

(defn setup
  [items]
  (when-let [p (plugin)] (register-eca-extension p items)))
