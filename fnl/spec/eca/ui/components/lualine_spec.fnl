(local {: describe : it} (require :plenary.busted))
(local assert (require :luassert.assert))
(local lualine (require :eca.ui.components.lualine))

(describe :enabled?
  (fn []
    (let [mock {:setup (fn [])}
          _    (set package.loaded.lualine mock)]

      (it "return true when lualine plugin exists"
        (fn []
          (assert.equals true (lualine.enabled?)))))))

(describe :setup
  (fn []
    (let [captured {}
          mock     {:setup (fn [cfg] (set captured.cfg cfg))}
          _        (set package.loaded.lualine mock)]

      (it "setup lualine extension with correct items order"
        (fn []
          (assert.equals nil
                         (lualine.setup [{:value "~/dev/eca-nvim"}
                                         {:value "⏱ 0s"}
                                         {:value "0/200K ($0.00)"}]))
          (let [ext (. captured.cfg :extensions 1)]
            (assert.same [:eca-chat] ext.filetypes)))))))
