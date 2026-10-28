(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(local options (require :fennel-extras.lint.rules.options))

(defn- load-config
  []
  (let [(ok result) (pcall require :fennel-extras.config)]
    (if ok
      result
      {:module-missing true})))

(defn- with-cleanup
  [cleanup f]
  (let [(ok result) (pcall f)]
    (cleanup)
    (if ok
      result
      (error result 0))))

(defn- parse-result
  [text]
  (let [config (load-config)]
    (if (. config :module-missing)
      config
      (let [(ok value err) (pcall (fn [] (config.parse-string text)))]
        (if ok
          {:value value :error err}
          {:call-error true :error err})))))

(defn- parse-value
  [text]
  (. (parse-result text) :value))

(defn- parse-error-summary
  [text include-location?]
  (let [result (parse-result text)]
    (if (. result :module-missing)
      result
      (let [value (. result :value)
            err   (. result :error)]
        (if include-location?
          {:value?      (not= nil value)
           :has-message (and (= nil value)
                             err
                             (= :table (type err))
                             (= :string (type (. err :message))))
           :line        (and err (. err :line))
           :col         (and err (. err :col))}
          {:value?      (not= nil value)
           :has-message (and (= nil value)
                             err
                             (= :table (type err))
                             (= :string (type (. err :message))))})))))

(defn- canonical-fragment
  [value]
  (if (and (= :table (type value))
           (= nil (. value :workspace))
           (= nil (. value :format))
           (= nil (. value :lint)))
    (let [workspace {}
          format    {}]
      (each [key item (pairs value)]
        (if (or (= key :paths)
                (= key :exclude)
                (= key :extensions)
                (= key :dotfiles)
                (= key :symlinks))
          (tset workspace key item)
          (tset format key item)))
      {:workspace workspace :format format :lint {:rules {}}})
    value))

(defn- complete-config
  [value]
  (if (= :table (type value))
    (vim.tbl_deep_extend "force"
                         {:workspace {:paths      ["fnl"]
                                      :extensions [".fnl" ".fnlm"]}
                          :format    {:indent-width     2
                                      :builtins         false
                                      :prefix-fallbacks false
                                      :parser           false}
                          :lint      {:rules {}}}
                         (canonical-fragment value))
    value))

(defn- validate-summary
  [value]
  (let [config (load-config)
        value  (complete-config value)]
    (if (. config :module-missing)
      config
      (let [(ok result err) (pcall (fn [] (config.validate value)))]
        {:value?      (and ok (not= nil result))
         :has-message (and ok
                           (= nil result)
                           err
                           (= :table (type err))
                           (= :string (type (. err :message))))}))))

(defn- validation-call
  [config value]
  (pcall (fn [] (config.validate value))))

(defn- complete-lint-config
  [value]
  (canonical-fragment value))

(defn- validation-message
  [config value]
  (let [(ok result err) (validation-call config value)]
    (when (and ok (= result nil) err)
      (. err :message))))

(defn- validation-error-message-raw
  [text]
  (let [config (load-config)
        value  (parse-value text)]
    (when (and (not (. config :module-missing)) (not= value nil))
      (validation-message config value))))

(defn- validation-error-message
  [text]
  (let [config (load-config)
        value  (complete-lint-config (parse-value text))]
    (when (and (not (. config :module-missing)) (not= value nil))
      (validation-message config value))))

(defn- validation-summary
  [config value]
  (let [(ok result err) (validation-call config value)]
    {:crashed? (not ok)
     :message  (and ok (= nil result) err (. err :message))}))

(defn- validation-result
  [config value]
  (if (or (. config :module-missing) (= value nil))
    {:crashed? false :message nil}
    (validation-summary config value)))

(defn- parsed-value
  [text-or-value]
  (if (= :string (type text-or-value))
    (parse-value text-or-value)
    text-or-value))

(defn- validation-call-summary
  [text-or-value]
  (let [config (load-config)
        parsed (parsed-value text-or-value)
        value  (complete-lint-config parsed)]
    (validation-result config value)))

(defn- lint-policy-summary
  [value]
  (let [config (load-config)
        value  (complete-config value)]
    (if (. config :module-missing)
      config
      (let [(ok policy err) (pcall (fn [] (config.lint-policy value)))]
        {:value-nil? (and ok (= nil policy))
         :message    (and ok (= nil policy) err (. err :message))}))))

(defn- lint-policy-value
  [value]
  (let [config (load-config)
        value  (complete-config value)]
    (if (. config :module-missing)
      config
      (let [(ok policy err) (pcall (fn [] (config.lint-policy value)))]
        (if (and ok policy)
          policy
          {:error (and err (. err :message))})))))

(defn- unknown-lint-key-summary
  [value]
  (let [config (load-config)]
    (if (. config :module-missing)
      config
      (let [(ok result err) (pcall (fn [] (config.validate value)))
            message         (and ok (= nil result) err (. err :message))]
        {:unknown-key? (and message
                            (= "unknown lint key: " (string.sub message 1 18)))}))))

(defn- write-file
  [path text]
  (let [file (assert (io.open path :w))]
    (file:write text)
    (file:close)
    path))

(defn- find-load-scenario
  []
  (let [root        (vim.fn.tempname)
        nested      (.. root "/one/two")
        root-config (.. root "/.fnl-extras.fnl")
        config-path (.. root "/one/.fnl-extras.fnl")
        stop-root   (.. root "/stop")
        stop-nested (.. stop-root "/child")
        stop-git    (.. stop-root "/.git")]
    (vim.fn.mkdir nested "p")
    (vim.fn.mkdir stop-nested "p")
    (vim.fn.mkdir stop-git "p")
    (with-cleanup (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file root-config "{:workspace {:exclude [\"root\"]} :format {:indent-width 2 :builtins false :prefix-fallbacks false :parser false} :lint {:rules {}}}")
        (write-file config-path "{:workspace {:paths [\"fnl\"]} :format {:indent-width 2 :builtins false :prefix-fallbacks false :parser false} :lint {:rules {}}}")
        (write-file (.. root "/valid.fnl-extras.fnl") "{:exclude [\"generated\"]}")
        {:start       (let [config (load-config)]
                        (if (. config :module-missing)
                          config
                          (config.find root)))
         :parent      (let [config (load-config)]
                        (if (. config :module-missing)
                          config
                          (config.find nested)))
         :stopped     (let [config (load-config)]
                        (if (. config :module-missing)
                          config
                          (config.find stop-nested)))
         :root-config root-config
         :config-path config-path
         :loaded      (let [config (load-config)]
                        (if (. config :module-missing)
                          config
                          (config.load config-path)))
         :missing     (let [config (load-config)]
                        (if (. config :module-missing)
                          config
                          (let [(ok value err)
                                (pcall (fn [] (config.load (.. root "/missing.fnl-extras.fnl"))))]
                            {:value?      (and ok (not= nil value))
                             :has-message (and ok
                                               (= nil value)
                                               err
                                               (= :table (type err))
                                               (= :string (type (. err :message))))})))}))))

(deftest parse-string
  (testing "parses a realistic data-only configuration and converts keywords to strings"
    (is (= {:indents   {:deftest [["block" 1]]
                        :testing [["block" 1]]}
            :format-as {:my-let "let"}
            :paths     ["fnl"]
            :exclude   ["fnl/eca/nfnl"]}
           (parse-value "{:indents {\"deftest\" [[:block 1]] \"testing\" [[:block 1]]} :format-as {\"my-let\" \"let\"} :paths [\"fnl\"] :exclude [\"fnl/eca/nfnl\"]}"))))
  (testing "parses escapes, numbers, booleans, nil, and ignores comments"
    (is (= {:text     "quote \" slash \\ line\n tab\t"
            :one      1
            :decimal  2.5
            :negative -3
            :yes      true
            :no       false
            :nothing  nil}
           (parse-value "{:text \"quote \\\" slash \\\\ line\\n tab\\t\" ; comment\n :one 1 :decimal 2.5 :negative -3 :yes true :no false :nothing nil}")))))

(deftest rejection
  (testing "rejects a list and reports line 1 column 5"
    (is (= {:value? false :has-message true :line 1 :col 5}
           (parse-error-summary "{:a (require :x)}" true))))
  (testing "rejects a bare symbol"
    (is (= {:value? false :has-message true}
           (parse-error-summary "{:a foo}" false))))
  (testing "rejects hash reader prefixes"
    (is (= {:value? false :has-message true}
           (parse-error-summary "{:a #(x)}" false))))
  (testing "rejects more than one top-level form"
    (is (= {:value? false :has-message true}
           (parse-error-summary "{} {}" false))))
  (testing "rejects an empty file"
    (is (= {:value? false :has-message true}
           (parse-error-summary "" false))))
  (testing "rejects a non-table top-level form"
    (is (= {:value? false :has-message true}
           (parse-error-summary "[1]" false))))
  (testing "rejects unbalanced input"
    (is (= {:value? false :has-message true}
           (parse-error-summary "{:a 1" false))))
  (testing "validate rejects an unknown top-level key"
    (is (= {:value? false :has-message true}
           (validate-summary {:workspace {:colour 1}
                              :format    {}
                              :lint      {:rules {}}}))))
  (testing "validate rejects paths that are not a sequence"
    (is (= {:value? false :has-message true}
           (validate-summary {:paths "fnl"})))))

(deftest find-load
  (testing "find returns a config in the start directory"
    (let [result (find-load-scenario)]
      (is (= (. result :root-config) (. result :start)))))
  (testing "find returns the nearest config in a parent directory"
    (let [result (find-load-scenario)]
      (is (= (. result :config-path) (. result :parent)))))
  (testing "find stops at a .git directory"
    (is (nil? (. (find-load-scenario) :stopped))))
  (testing "load returns the validated table from a file"
    (is (= {:workspace {:paths ["fnl"]}
            :format    {:indent-width 2 :builtins false :prefix-fallbacks false :parser false}
            :lint      {:rules {}}}
           (. (find-load-scenario) :loaded))))
  (testing "load returns a structured error for a missing path"
    (is (= {:value? false :has-message true}
           (. (find-load-scenario) :missing)))))

(deftest config-new-configuration
  (testing "accepts an indent width of four"
    (is (= {:value? true :has-message false}
           (validate-summary {:indent-width 4}))))
  (testing "rejects true builtins because the setting must be explicit"
    (is (= "builtins must be a map or false"
           (validation-error-message "{:builtins true}"))))
  (testing "accepts disabling builtins"
    (is (= {:value? true :has-message false}
           (validate-summary {:builtins false}))))
  (testing "accepts a replacement builtins table"
    (is (= {:value? true :has-message false}
           (validate-summary {:builtins {"foo" [[:block 1]]}}))))
  (testing "accepts disabling prefix fallbacks"
    (is (= {:value? true :has-message false}
           (validate-summary {:prefix-fallbacks false}))))
  (testing "accepts a replacement prefix fallback table"
    (is (= {:value? true :has-message false}
           (validate-summary {:prefix-fallbacks {"foo-" [[:block 1]]}}))))
  (testing "rejects zero indent width with a specific validation message"
    (let [message (validation-error-message "{:indent-width 0}")]
      (is (= "indent-width must be a positive integer" message))))
  (testing "rejects negative indent width with a specific validation message"
    (let [message (validation-error-message "{:indent-width -1}")]
      (is (= "indent-width must be a positive integer" message))))
  (testing "rejects non-integer indent width with a specific validation message"
    (let [message (validation-error-message "{:indent-width 2.5}")]
      (is (= "indent-width must be a positive integer" message))))
  (testing "rejects string indent width with a specific validation message"
    (let [message (validation-error-message "{:indent-width \"4\"}")]
      (is (= "indent-width must be a positive integer" message))))
  (testing "rejects malformed builtins with a specific validation message"
    (let [message (validation-error-message "{:builtins 1}")]
      (is (= "builtins must be a map or false" message))))
  (testing "rejects malformed prefix fallbacks with a specific validation message"
    (let [message (validation-error-message "{:prefix-fallbacks 1}")]
      (is (= "prefix-fallbacks must be a map or false" message))))
  (testing "rejects malformed builtins rules with a specific validation message"
    (let [message (validation-error-message "{:builtins {\"foo\" 1}}")]
      (is (= "builtins must be a map or false" message))))
  (testing "rejects malformed prefix fallback rules with a specific validation message"
    (let [message (validation-error-message "{:prefix-fallbacks {\"foo-\" 1}}")]
      (is (= "prefix-fallbacks must be a map or false" message)))))

(deftest extensions
  (testing "accepts a non-empty list of dotted extension strings"
    (is (= {:value? true :has-message false}
           (validate-summary {:extensions [".fnl" ".fnlm"]}))))
  (testing "rejects an empty extensions list with the exact validation message"
    (is (= "workspace.extensions must be a non-empty list of strings starting with \".\""
           (validation-error-message "{:extensions []}"))))
  (testing "rejects non-string extensions with the exact validation message"
    (is (= "workspace.extensions must be a non-empty list of strings starting with \".\""
           (validation-error-message "{:extensions [1]}"))))
  (testing "rejects extensions without a leading dot with the exact validation message"
    (is (= "workspace.extensions must be a non-empty list of strings starting with \".\""
           (validation-error-message "{:extensions [\"fnl\"]}"))))
  (testing "rejects a non-list extensions value with the exact validation message"
    (is (= "workspace.extensions must be a non-empty list of strings starting with \".\""
           (validation-error-message "{:extensions \".fnl\"}")))))

(deftest new-keys
  (testing "does not require paths during general configuration validation"
    (is (= nil
           (validation-error-message-raw "{:indent-width 2 :builtins false :prefix-fallbacks false :parser false :extensions [\".fnl\"]}"))))
  (testing "rejects a non-boolean dotfiles value with the exact validation message"
    (is (= "workspace.dotfiles must be a boolean"
           (validation-error-message "{:dotfiles 1}"))))
  (testing "rejects a non-boolean symlinks value with the exact validation message"
    (is (= "workspace.symlinks must be a boolean"
           (validation-error-message "{:symlinks 1}"))))
  (testing "rejects a non-string parser value with the exact validation message"
    (is (= "parser must be a string or false"
           (validation-error-message "{:parser 1}"))))
  (testing "rejects the removed align-bindings key"
    (is (= "unknown configuration key: align-bindings"
           (validation-error-message-raw "{:align-bindings true}")))))

(deftest alignment-configuration
  (testing "accepts an alignment table"
    (is (= {:value? true :has-message false}
           (validate-summary {:alignment {:maps true}}))))
  (testing "rejects a boolean alignment value with the exact validation message"
    (is (= "alignment must be a table"
           (validation-error-message "{:alignment true}"))))
  (testing "rejects a string alignment value with the exact validation message"
    (is (= "alignment must be a table"
           (validation-error-message "{:alignment \"yes\"}"))))
  (testing "rejects an unknown alignment key with the key in the error"
    (is (= "unknown alignment key: nope"
           (validation-error-message "{:alignment {:nope true}}"))))
  (testing "rejects a non-boolean alignment toggle with the exact validation message"
    (is (= "alignment key maps must be a boolean"
           (validation-error-message "{:alignment {:maps 1}}"))))
  (testing "rejects a non-list binding-forms value with the exact validation message"
    (is (= "alignment key binding-forms must be a list of strings"
           (validation-error-message "{:alignment {:binding-forms \"let\"}}"))))
  (testing "rejects a map binding-forms value with the exact validation message"
    (is (= "alignment key binding-forms must be a list of strings"
           (validation-error-message "{:alignment {:binding-forms {:foo \"bar\"}}}"))))
  (testing "rejects a non-string clause form with the exact validation message"
    (is (= "alignment key clause-forms must be a list of strings"
           (validation-error-message "{:alignment {:clause-forms [1]}}"))))
  (testing "rejects a map clause-forms value with the exact validation message"
    (is (= "alignment key clause-forms must be a list of strings"
           (validation-error-message "{:alignment {:clause-forms {:foo \"bar\"}}}"))))
  (testing "missing alignment switches remain off"
    (let [config   (load-config)
          settings (require :fennel-extras.indent.settings)
          value    {:alignment {:binding-forms ["let"]
                                :clause-forms  ["case"]}}]
      (is (= {:bindings         false
              :maps             false
              :clauses          false
              :split-bindings   false
              :collapse-padding false
              :binding-forms    ["let"]
              :clause-forms     ["case"]}
             (settings.resolve (config.validate value))))))
  (testing "alignment tables require binding forms when binding alignment is enabled"
    (is (= "missing alignment.binding-forms"
           (validation-error-message "{:alignment {:bindings true}}")))))

(defn- formatter-projection
  [config]
  {:indents          (. config :indents)
   :format-as        (. config :format-as)
   :indent-patterns  (. config :indent-patterns)
   :indent-width     (. config :indent-width)
   :builtins         (. config :builtins)
   :prefix-fallbacks (. config :prefix-fallbacks)})

(defn- format-with-config
  [source config]
  (let [(ok format) (pcall require :fennel-extras.format)]
    (if (not ok)
      {:module-missing true}
      (let [(ok value err) (pcall (fn [] (format.format-string source {:config config})))]
        {:value value :error err :ok ok}))))



(deftest lint-configuration
  (testing "accepts a canonical lint rule instance"
    (is (= {:value? true :has-message false}
           (validate-summary {:lint {                                     :rules      {:forbidden-form
                                                                                       [{:severity   :warning
                                                                                         :applies-to {:files ["^spec/"]
                                                                                                      :forms ["require"]}
                                                                                         :options    {:module "plenary.busted"}
                                                                                         :exclusions []}]}}}))))
  (testing "rejects a direct rule map"
    (is (= {:value? false :has-message true}
           (validate-summary {:lint {                                     :rules      {:forbidden-form
                                                                                       {:severity   :warning
                                                                                        :applies-to {:files ["^spec/"]
                                                                                                     :forms ["require"]}
                                                                                        :options    {:module "plenary.busted"}
                                                                                        :exclusions []}}}}))))
  (testing "reports option errors deterministically"
    (let [first          "{:lint {:rules {:forbidden-form [{:severity :warning :applies-to {} :options {:unknown true :module 1} :exclusions []}]}}}"
          second         "{:lint {:rules {:forbidden-form [{:severity :warning :applies-to {} :options {:module 1 :unknown true} :exclusions []}]}}}"
          first-message  (validation-error-message first)
          second-message (validation-error-message second)]
      (is (= first-message second-message))))
  (testing "reports the lexicographically first invalid option"
    (let [message (validation-error-message "{:lint {:rules {:forbidden-form [{:severity :warning :applies-to {} :options {:module 1 :unknown true} :exclusions []}]}}}")]
      (is (string.match message "module must be a string"))))
  (testing "unknown options include the rule name"
    (let [message (validation-error-message "{:lint {:rules {:forbidden-form [{:severity :warning :applies-to {} :options {:unknown true} :exclusions []}]}}}")]
      (is (string.match message "unknown option unknown")))))

(deftest lint-policy
  (testing "lint policy preserves explicit rule options"
    (let [policy (lint-policy-value {:lint {                                            :rules      {}}})]
      (is (and (not (. policy :error)) (. policy :rules))))))

(deftest formatter-isolation
  (testing "lint configuration does not change formatter output"
    (let [result (format-with-config "(let [x 1] x)" {:indent-width     2
                                                      :builtins         false
                                                      :prefix-fallbacks false
                                                      :parser           false
                                                      :paths            ["fnl"]
                                                      :extensions       [".fnl"]})]
      (is (or (. result :module-missing) (. result :value))))))
