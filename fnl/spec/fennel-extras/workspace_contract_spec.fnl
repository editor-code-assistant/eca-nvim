(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(local config (require :fennel-extras.config))

(defn- write-file
  [path text]
  (let [file (assert (io.open path :w))]
    (file:write text)
    (file:close)
    path))

(defn- run-cli
  [root args]
  (let [lines []
        cli   (require :fennel-extras.cli)]
    {:code  (cli.run args {:cwd root :print (fn [line] (table.insert lines line))})

     :lines lines}))

(defn- validation
  [value]
  (let [(ok result error) (pcall config.validate value)]
    {:ok (and ok result) :value result :error error}))

(defn- error-message
  [result]
  (let [error (. result :error)]
    (if (= :table (type error))
      (. error :message)
      error)))

(defn- legacy-config
  [key]
  (let [value  (if (= key :extensions) [".fnl"] (if (or (= key :dotfiles)
                                                        (= key :symlinks))
                                                  false
                                                  ["fnl"]))
        result {}]
    (tset result key value)
    result))

(local workspace-config
       {:workspace {:paths      ["fnl"]
                    :exclude    ["fnl/generated"]
                    :extensions [".fnl" ".fnlm"]
                    :dotfiles   false
                    :symlinks   false}
        :format    {:indent-width     2
                    :builtins         false
                    :prefix-fallbacks false
                    :parser           false}
        :lint      {:rules {}}})

(deftest workspace-root-contract

  (testing "root configuration is grouped under workspace, format, and lint"
    (let [result (validation workspace-config)]
      (is (and (. result :ok)
               (. result :value)))))

  (testing "workspace owns path and scan settings"
    (let [result (validation workspace-config)
          value  (. result :value)]
      (is (and (. result :ok)
               (vim.deep_equal ["fnl"] (. value :workspace :paths))
               (vim.deep_equal ["fnl/generated"] (. value :workspace :exclude))
               (vim.deep_equal [".fnl" ".fnlm"] (. value :workspace :extensions))
               (= false (. value :workspace :dotfiles))
               (= false (. value :workspace :symlinks))))))

  (testing "old root-level path and scan settings are rejected"
    (each [_ key (ipairs [:paths :exclude :dotfiles :symlinks])]
      (let [result (validation (legacy-config key))]
        (is (and (not (. result :ok))
                 (= (.. "unknown configuration key: " key)
                    (error-message result)))))))

  (testing "root-level scan aliases are rejected"
    (each [_ key (ipairs [:skip-dotfiles :follow-symlinks])]
      (let [result (validation (legacy-config key))]
        (is (and (not (. result :ok))
                 (= (.. "unknown configuration key: " key)
                    (error-message result)))))))

  (testing "root-level extensions remain accepted for format compatibility"
    (let [result (validation (legacy-config :extensions))]
      (is (. result :ok)))))

(deftest workspace-relative-rule-files

  (testing "a workspace path makes rule file patterns workspace-relative"
    (let [root   (vim.fn.tempname)
          config (.. root "/.fnl-extras.fnl")
          path   (.. root "/fnl/spec/example.fnl")
          text   "{:workspace {:paths [\"fnl\"] :exclude [] :extensions [\".fnl\"] :dotfiles false :symlinks false} :format {:indent-width 2 :builtins false :prefix-fallbacks false :parser false} :lint {:rules {:forbidden-form [{:severity :warning :applies-to {:files [\"^fnl/spec/\"]} :options {:forms [\"var\" \"set\" \"while\"]} :exclusions []}]}}}"
          _      (vim.fn.mkdir (.. root "/fnl/spec") "p")
          _      (vim.fn.mkdir (.. root "/.git") "p")
          _      (write-file config text)
          _      (write-file path "(var x 1)\\n")
          result (run-cli root ["lint" "--all"])]
      (vim.fn.delete root "rf")
      (is (= 0 (. result :code))))))

(deftest workspace-public-contract-rejections

  (testing "contexts is not a public applies-to selector"
    (let [value  {:lint {:rules {:forbidden-form [{:severity   "warning"
                                                   :applies-to {:contexts ["source"]}
                                                   :options    {:forms ["var" "set" "while"]}
                                                   :exclusions []}]}}}
          result (validation value)]
      (is (and (not (. result :ok))
               (= "unknown applies-to key: contexts"
                  (error-message result))))))

  (testing "spec-files is not a public lint setting"
    (let [result (validation {:lint {:spec-files ["^spec/"] :rules {}}})]
      (is (and (not (. result :ok))
               (= "unknown lint key: spec-files"
                  (error-message result)))))))
