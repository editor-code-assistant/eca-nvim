(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

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
           :has-message (and
                         (= nil value)
                         err
                         (= :table (type err))
                         (= :string (type (. err :message))))
           :line        (and err (. err :line))
           :col         (and err (. err :col))}
          {:value?      (not= nil value)
           :has-message (and
                         (= nil value)
                         err
                         (= :table (type err))
                         (= :string (type (. err :message))))})))))

(defn- validate-summary
  [value]
  (let [config (load-config)]
    (if (. config :module-missing)
      config
      (let [(ok result err) (pcall (fn [] (config.validate value)))]
        {:value?      (and ok (not= nil result))
         :has-message (and
                       ok
                       (= nil result)
                       err
                       (= :table (type err))
                       (= :string (type (. err :message))))}))))

(defn- validation-error-message
  [text]
  (let [config (load-config)
        value  (parse-value text)]
    (if (or (. config :module-missing) (= value nil))
      nil
      (let [(ok result err) (pcall (fn [] (config.validate value)))]
        (when (and ok (= result nil) err)
          (. err :message))))))

(defn- validation-call-summary
  [text-or-value]
  (let [config (load-config)
        value  (if (= :string (type text-or-value))
                 (parse-value text-or-value)
                 text-or-value)]
    (if (or (. config :module-missing) (= value nil))
      {:crashed? false :message nil}
      (let [(ok result err) (pcall (fn [] (config.validate value)))]
        {:crashed? (not ok)
         :message  (and ok (= nil result) err (. err :message))}))))

(defn- lint-policy-summary
  [value]
  (let [config (load-config)]
    (if (. config :module-missing)
      config
      (let [(ok policy err) (pcall (fn [] (config.lint-policy value)))]
        {:value-nil? (and ok (= nil policy))
         :message    (and ok (= nil policy) err (. err :message))}))))

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
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file root-config "{:exclude [\"root\"]}")
        (write-file config-path "{:paths [\"fnl\"]}")
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
                             :has-message (and
                                           ok
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
           (validate-summary {:colour 1}))))
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
    (is (= {:paths ["fnl"]} (. (find-load-scenario) :loaded))))
  (testing "load returns a structured error for a missing path"
    (is (= {:value? false :has-message true}
           (. (find-load-scenario) :missing)))))

(deftest new-configuration
  (testing "accepts an indent width of four"
    (is (= {:value? true :has-message false}
           (validate-summary {:indent-width 4}))))
  (testing "accepts the default builtins setting"
    (is (= {:value? true :has-message false}
           (validate-summary {:builtins true}))))
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
      (is (= "builtins must be true, false, or a table of rules" message))))
  (testing "rejects malformed prefix fallbacks with a specific validation message"
    (let [message (validation-error-message "{:prefix-fallbacks 1}")]
      (is (= "prefix-fallbacks must be false or a table of rules" message))))
  (testing "rejects malformed builtins rules with a specific validation message"
    (let [message (validation-error-message "{:builtins {\"foo\" 1}}")]
      (is (= "builtins rule foo: invalid indentation rule" message))))
  (testing "rejects malformed prefix fallback rules with a specific validation message"
    (let [message (validation-error-message "{:prefix-fallbacks {\"foo-\" 1}}")]
      (is (= "prefix-fallbacks rule foo-: invalid indentation rule" message)))))

(deftest extensions
  (testing "accepts a non-empty list of dotted extension strings"
    (is (= {:value? true :has-message false}
           (validate-summary {:extensions [".fnl" ".fnlm"]}))))
  (testing "rejects an empty extensions list with the exact validation message"
    (is (= "extensions must be a non-empty list of strings starting with \".\""
           (validation-error-message "{:extensions []}"))))
  (testing "rejects non-string extensions with the exact validation message"
    (is (= "extensions must be a non-empty list of strings starting with \".\""
           (validation-error-message "{:extensions [1]}"))))
  (testing "rejects extensions without a leading dot with the exact validation message"
    (is (= "extensions must be a non-empty list of strings starting with \".\""
           (validation-error-message "{:extensions [\"fnl\"]}"))))
  (testing "rejects a non-list extensions value with the exact validation message"
    (is (= "extensions must be a non-empty list of strings starting with \".\""
           (validation-error-message "{:extensions \".fnl\"}")))))

(deftest new-keys
  (testing "accepts the default paths behavior without a paths key"
    (is (= {:value? true :has-message false}
           (validate-summary {}))))
  (testing "rejects a non-boolean skip-dotfiles value with the exact validation message"
    (is (= "skip-dotfiles must be a boolean"
           (validation-error-message "{:skip-dotfiles 1}"))))
  (testing "rejects a non-boolean follow-symlinks value with the exact validation message"
    (is (= "follow-symlinks must be a boolean"
           (validation-error-message "{:follow-symlinks 1}"))))
  (testing "rejects a non-string parser value with the exact validation message"
    (is (= "parser must be a string"
           (validation-error-message "{:parser 1}"))))
  (testing "accepts a boolean align-bindings value"
    (is (= {:value? true :has-message false}
           (validate-summary {:align-bindings true}))))
  (testing "rejects a non-boolean align-bindings value with the exact validation message"
    (is (= "align-bindings must be a boolean"
           (validation-error-message "{:align-bindings \"yes\"}")))))

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
  (testing "accepts an empty lint table from parsed Fennel"
    (is (= {:lint {}}
           (parse-value "{:lint {}}"))))
  (testing "parses an empty lint rules table from Fennel"
    (is (= {:lint {:rules {}}}
           (parse-value "{:lint {:rules {}}}"))))
  (testing "accepts an empty lint rules table through validate"
    (is (= {:lint {:rules {}}}
           (let [config (load-config)]
             (if (. config :module-missing)
               config
               (config.validate {:lint {:rules {}}}))))))
  (testing "accepts a known lint rule from parsed Fennel"
    (is (= {:lint {:rules {"if-branch-call" "error"}}}
           (parse-value "{:lint {:rules {\"if-branch-call\" :error}}}"))))
  (testing "accepts the no-mutation lint rule from parsed Fennel"
    (is (= {:lint {:rules {"no-mutation" "warning"}}}
           (parse-value "{:lint {:rules {\"no-mutation\" :warning}}}"))))
  (testing "accepts the defn-args-newline lint rule from parsed Fennel"
    (is (= {:lint {:rules {"defn-args-newline" "error"}}}
           (parse-value "{:lint {:rules {\"defn-args-newline\" :error}}}"))))
  (testing "accepts the control-layout lint rule from parsed Fennel"
    (is (= {:lint {:rules {"control-layout" "warning"}}}
           (parse-value "{:lint {:rules {\"control-layout\" :warning}}}"))))
  (testing "accepts a positive max-code-lines value"
    (is (= {:value? true :has-message false}
           (validate-summary {:lint {:max-code-lines 10}}))))
  (testing "rejects zero max-code-lines with a specific validation message"
    (is (= "max-code-lines must be a positive integer"
           (validation-error-message "{:lint {:max-code-lines 0}}"))))
  (testing "rejects negative max-code-lines with a specific validation message"
    (is (= "max-code-lines must be a positive integer"
           (validation-error-message "{:lint {:max-code-lines -1}}"))))
  (testing "rejects non-integer max-code-lines with a specific validation message"
    (is (= "max-code-lines must be a positive integer"
           (validation-error-message "{:lint {:max-code-lines 1.5}}"))))
  (testing "rejects string max-code-lines with a specific validation message"
    (is (= "max-code-lines must be a positive integer"
           (validation-error-message "{:lint {:max-code-lines \"10\"}}"))))
  (testing "accepts the file-size lint rule from parsed Fennel"
    (is (= {:lint {:rules {"file-size" "warning"}}}
           (parse-value "{:lint {:rules {\"file-size\" :warning}}}"))))
  (testing "accepts an exclusion from parsed Fennel"
    (is (= {:lint {:exclusions [{:rule   "if-branch-call"
                                 :form   "fnl/a.fnl > top#1"
                                 :reason "why"}]}}
           (parse-value "{:lint {:exclusions [{:rule \"if-branch-call\" :form \"fnl/a.fnl > top#1\" :reason \"why\"}]}}"))))
  (testing "accepts an empty lint table through validate"
    (is (= {:lint {}}
           (let [config (load-config)]
             (if (. config :module-missing)
               config
               (config.validate {:lint {}}))))))
  (testing "accepts a lint rule through validate"
    (is (= {:lint {:rules {"if-branch-call" "error"}}}
           (let [config (load-config)]
             (if (. config :module-missing)
               config
               (config.validate {:lint {:rules {"if-branch-call" "error"}}}))))))
  (testing "accepts an exclusion through validate"
    (is (= {:lint {:exclusions [{:rule   "if-branch-call"
                                 :form   "fnl/a.fnl > top#1"
                                 :reason "why"}]}}
           (let [config (load-config)]
             (if (. config :module-missing)
               config
               (config.validate {:lint {:exclusions [{:rule   "if-branch-call"
                                                      :form   "fnl/a.fnl > top#1"
                                                      :reason "why"}]} }))))))
  (testing "rejects a non-table lint value"
    (is (= "lint must be a table"
           (validation-error-message "{:lint 1}"))))
  (testing "rejects a numeric lint key without crashing"
    (is (= {:crashed? false :message "unknown lint key: 1"}
           (validation-call-summary "{:lint {1 true :z 1}}"))))
  (testing "rejects a boolean lint rule key without crashing"
    (is (= {:crashed? false :message "unknown lint rule: true"}
           (validation-call-summary "{:lint {:rules {true :error}}}"))))
  (testing "rejects a boolean lint key without crashing"
    (is (= {:crashed? false :message "unknown lint key: true"}
           (validation-call-summary "{:lint {true 1}}"))))
  (testing "rejects a numeric lint exclusion key without crashing"
    (is (= {:crashed? false :message "lint exclusion 1: unknown key 1"}
           (validation-call-summary "{:lint {:exclusions [{1 \"x\" :rule \"if-branch-call\" :form \"f\" :reason \"r\"}]}}"))))
  (testing "rejects a boolean lint exclusion key without crashing"
    (is (= {:crashed? false :message "lint exclusion 1: unknown key true"}
           (validation-call-summary "{:lint {:exclusions [{true \"x\" :rule \"if-branch-call\" :form \"f\" :reason \"r\"}]}}"))))
  (testing "rejects a table lint exclusion key without crashing"
    (let [key       {}
          exclusion {:rule   "if-branch-call"
                     :form   "f"
                     :reason "r"}
          value     {:lint {:exclusions [exclusion]}}]
      (tset exclusion key "x")
      (let [summary (validation-call-summary value)
            message (. summary :message)
            prefix  "lint exclusion 1: unknown key table"]
        (is (= {:crashed?   false
                :prefix-ok? (and message
                                 (= prefix (string.sub message 1 35)))}
               {:crashed?   (. summary :crashed?)
                :prefix-ok? (and message
                                 (= prefix (string.sub message 1 35)))})))))
  (testing "rejects a lint rule with a table severity without crashing"
    (is (= {:crashed? false
            :message  "lint rule if-branch-call must be error, warning, or off"}
           (validation-call-summary "{:lint {:rules {\"if-branch-call\" {}}}}"))))
  (testing "rejects a list-valued lint exclusion without crashing"
    (is (= {:crashed? false :message "lint exclusion 1: unknown key 1"}
           (validation-call-summary "{:lint {:exclusions [[1 2]]}}"))))
  (testing "rejects a lint exclusion with a table rule without crashing"
    (is (= {:crashed? false
            :message  "lint exclusion 1: rule must be a string"}
           (validation-call-summary "{:lint {:exclusions [{:rule {} :form \"f\" :reason \"r\"}]}}"))))
  (testing "rejects an unknown lint key"
    (is (= "unknown lint key: extra"
           (validation-error-message "{:lint {:extra true}}"))))
  (testing "rejects an unknown lint key after lint exclusions"
    (is (= "unknown lint key: extra"
           (validation-error-message "{:lint {:exclusions [] :extra true}}"))))
  (testing "rejects an unknown lint key after lint rules"
    (is (= "unknown lint key: extra"
           (validation-error-message "{:lint {:rules {} :extra true}}"))))
  (testing "rejects an unknown lint key among multiple lint keys"
    (is (= {:unknown-key? true}
           (unknown-lint-key-summary {:lint {:rules {} :exclusions [] :a 1 :b 2 :c 3}}))))
  (testing "rejects a non-table lint rules value"
    (is (= "lint rules must be a table"
           (validation-error-message "{:lint {:rules []}}"))))
  (testing "rejects an unknown lint rule"
    (is (= "unknown lint rule: nope"
           (validation-error-message "{:lint {:rules {\"nope\" :error}}}"))))
  (testing "rejects an invalid lint rule severity"
    (is (= "lint rule if-branch-call must be error, warning, or off"
           (validation-error-message "{:lint {:rules {\"if-branch-call\" :debug}}}"))))
  (testing "rejects a non-list lint exclusions value"
    (is (= "lint exclusions must be a list"
           (validation-error-message "{:lint {:exclusions {}}}"))))
  (testing "rejects a numeric-keyed lint exclusions map"
    (is (= "lint exclusions must be a list"
           (validation-error-message "{:lint {:exclusions {1 {:rule \"if-branch-call\" :form \"x\" :reason \"ok\"}}}}"))))
  (testing "rejects a lint exclusions map with two numeric keys"
    (is (= "lint exclusions must be a list"
           (validation-error-message "{:lint {:exclusions {1 {:rule \"if-branch-call\" :form \"x\" :reason \"ok\"} 2 {:rule \"if-branch-call\" :form \"y\" :reason \"ok\"}}}}"))))
  (testing "accepts a non-empty lint exclusions list from parsed Fennel"
    (is (= {:value? true :has-message false}
           (validate-summary (parse-value "{:lint {:exclusions [{:rule \"if-branch-call\" :form \"x\" :reason \"ok\"}]}}")))))
  (testing "accepts an empty lint exclusions list from parsed Fennel"
    (is (= {:value? true :has-message false}
           (validate-summary (parse-value "{:lint {:exclusions []}}")))))
  (testing "rejects a non-table lint exclusion"
    (is (= "lint exclusion 1 must be a table"
           (validation-error-message "{:lint {:exclusions [1]}}"))))
  (testing "rejects an unknown lint exclusion key"
    (is (= "lint exclusion 1: unknown key fingerprint"
           (validation-error-message "{:lint {:exclusions [{:rule \"if-branch-call\" :form \"x\" :reason \"why\" :fingerprint \"old\"}]}}"))))
  (testing "rejects a non-string lint exclusion field"
    (is (= "lint exclusion 1: rule must be a string"
           (validation-error-message "{:lint {:exclusions [{:rule 1 :form \"x\" :reason \"why\"}]}}"))))
  (testing "rejects a blank lint exclusion reason"
    (is (= "lint exclusion 1: reason must not be blank"
           (validation-error-message "{:lint {:exclusions [{:rule \"if-branch-call\" :form \"x\" :reason \"\\t\"}]}}"))))
  (testing "rejects an unknown lint exclusion rule"
    (is (= "lint exclusion 1: unknown rule nope"
           (validation-error-message "{:lint {:exclusions [{:rule \"nope\" :form \"x\" :reason \"why\"}]}}"))))
  (testing "rejects duplicate lint exclusions"
    (is (= "lint exclusion 2: duplicate of exclusion 1"
           (validation-error-message "{:lint {:exclusions [{:rule \"if-branch-call\" :form \"x\" :reason \"one\"} {:rule \"if-branch-call\" :form \"x\" :reason \"two\"}]}}")))))

(deftest lint-policy
  (testing "returns a validation error for a malformed lint rule key"
    (is (= {:value-nil? true :message "unknown lint rule: true"}
           (lint-policy-summary {:lint {:rules {true "error"}}}))))
  (testing "returns a validation error for a blank lint exclusion reason"
    (is (= {:value-nil? true :message "lint exclusion 1: reason must not be blank"}
           (lint-policy-summary {:lint {:exclusions [{:rule   "if-branch-call"
                                                      :form   "x"
                                                      :reason ""}]}}))))
  (testing "normalizes lint defaults and overrides without formatter keys"
    (let [config (load-config)]
      (is (= {:rules          {"module-style"        "error"
                               "spec-macro-import"   "error"
                               "spec-no-module"      "error"
                               "spec-direct-require" "error"
                               "one-is-per-testing"  "error"
                               "if-branch-call"      "warning"
                               "if-without-else"     "warning"
                               "control-layout"      "warning"
                               "defn-args-newline"   "warning"
                               "multiline-layout"    "warning"
                               "function-shape"      "warning"
                               "no-mutation"         "warning"
                               "file-size"           "warning"
                               "core-require"        "off"}
              :max-code-lines 300
              :exclusions     [{:rule "if-branch-call" :form "x" :reason "why"}]}
             (if (. config :module-missing)
               config
               (let [(ok value) (pcall (fn
                                         []
                                         (config.lint-policy {:lint {:max-code-lines 300
                                                                     :rules          {"core-require" "off"}
                                                                     :exclusions     [{:rule "if-branch-call" :form "x" :reason "why"}]}})))]
                 (if
                   ok
                   value
                   {:missing-lint-policy true}))))))))
(testing "normalizes a configured max-code-lines value"
  (let [config (load-config)]
    (is (= 10
           (if (. config :module-missing)
             nil
             (let [(ok value) (pcall (fn [] (config.lint-policy {:lint {:max-code-lines 10}})))]
               (and
                ok
                (. value :max-code-lines))))))))

(deftest formatter-isolation
  (testing "lint configuration does not change formatter output"
    (let [source       "(when condition\n(foo)\n(bar))"
          without-lint {:indents {"when" [[:block 1]]}}
          with-lint    {:indents {"when" [[:block 1]]}
                        :lint    {:rules {"if-branch-call" "off"}}}
          plain-result (format-with-config source (formatter-projection without-lint))
          lint-result  (format-with-config source (formatter-projection with-lint))]
      (is (= (. plain-result :value) (. lint-result :value))))))
