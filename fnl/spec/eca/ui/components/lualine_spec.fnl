(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(local lualine (require :eca.ui.components.lualine))

(defn- with-cleanup
  [cleanup f]
  (let [(ok result) (pcall f)]
    (cleanup)
    (if ok
      result
      (error result 0))))

(defn- with-lualine-plugin
  [plugin f]
  (let [original (. package.loaded :lualine)]
    (set (. package.loaded :lualine) plugin)
    (with-cleanup (fn [] (set (. package.loaded :lualine) original)) f)))

(defn- installed-plugin-scenario
  []
  (let [lualine-mock {:setup (fn [])}]

    (with-lualine-plugin lualine-mock
      (fn [] {:expected lualine-mock
              :actual   (lualine.plugin)}))))

(defn- missing-plugin-scenario
  []
  (with-lualine-plugin false
    (fn [] (lualine.plugin))))

(defn- setup-scenario
  []
  (var captured nil)
  (let [plugin {:get_config (fn []
                              {:options    {:theme :gruvbox}
                               :extensions [{:filetypes [:other]}]})

                :setup      (fn [cfg]
                              (set captured cfg))}]

    (with-lualine-plugin plugin
      (fn []
        (lualine.setup [{:value "~/dev/eca-nvim"}
                        {:value "⏱ 0s"}
                        {:value "0/200K ($0.00)"}])
        captured))))

(deftest plugin

  (testing "returns the lualine module when the plugin is installed"
    (let [{: expected : actual} (installed-plugin-scenario)]
      (is (identical? expected actual))))

  (testing "returns nil when the plugin is missing"
    (is (nil? (missing-plugin-scenario)))))

(deftest setup

  (testing "registers the eca-chat extension without touching other config"
    (let [captured (setup-scenario)]
      (is (= {:extensions [{:filetypes [:other]}
                           {:filetypes [:eca-chat]
                            :sections  {:lualine_a ["%#EcaHeaderValue#~/dev/eca-nvim"]
                                        :lualine_x ["%#EcaHeaderValue#⏱ 0s"]
                                        :lualine_y ["%#EcaHeaderValue#0/200K ($0.00)"]}}]
              :options    {:theme :gruvbox}}
             captured)))))
