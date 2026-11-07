(import-macros {: defn-} :eca.nfnl.macros.aniseed)
(import-macros {: deftest : testing : is} :spec.eca.macros)

(defn- load-module
  [name]
  (let [(ok result) (pcall require name)]
    (if ok
      result
      {:module-missing true})))



(defn- error-result
  [ok value err]
  {:ok      ok
   :value   value
   :message (and err (. err :message))})



(defn- config-validation-error
  [config value]
  (let [(ok result err) (pcall config.validate value)]
    (error-result ok result err)))



(defn- config-error
  [value]
  (let [config (load-module :fennel-extras.config)]
    (if (. config :module-missing)
      config
      (config-validation-error config value))))



(defn- format-validation-error
  [format config]
  (let [(ok result err) (pcall format.format-string "(x)" {:config config})]
    (error-result ok result err)))



(defn- format-error
  [config]
  (let [format (load-module :fennel-extras.format)]
    (if (. format :module-missing)
      format
      (format-validation-error format config))))



(defn- indent-validation-error
  [indent config]
  (let [(ok result err) (pcall indent.reindent "(x)" config)]
    (error-result ok result err)))



(defn- indent-error
  [config]
  (let [indent (load-module :fennel-extras.indent)]
    (if (. indent :module-missing)
      indent
      (indent-validation-error indent config))))



(defn- error-value
  [value]
  (if (= :table (type value))
    (. value :message)
    value))



(defn- lint-error-message
  [ok findings err]
  (or (and ok err (error-value err))
      (and (not ok) (error-value findings))))



(defn- lint-check
  [lint matcher source context]
  (let [options           (vim.tbl_extend "force" context {:matcher (matcher.vim-matcher)})
        (ok findings err) (pcall lint.check source options)]
    {:ok       ok
     :findings findings
     :message  (lint-error-message ok findings err)}))



(defn- lint-error
  [source context]
  (let [lint    (load-module :fennel-extras.lint)
        matcher (load-module :fennel-extras.cli.matcher)]
    (if (or (. lint :module-missing) (. matcher :module-missing))
      {:module-missing true}
      (lint-check lint matcher source context))))



(defn- missing-message?
  [result path]
  (or (and (. result :ok)
           (= nil (. result :findings))
           (= (.. "missing " path) (. result :message)))
      (and (not (. result :ok))
           (= (.. "missing " path) (. result :message)))))



(defn- complete-rule?
  [entry rules names index recurse]
  (let [instance (. entry 1)]
    (and (= (type entry) :table)
         (> (length entry) 0)
         (= (type instance) :table)
         (not= (. instance :severity) nil)
         (not= (. instance :options) nil)
         (not= (. instance :applies-to) nil)
         (recurse rules names (+ index 1)))))



(defn- complete-rules?
  [rules names index]
  (or (> index (length names))
      (complete-rule? (. rules (. names index)) rules names index complete-rules?)))



(deftest strict-config-errors



         (testing "format API reports missing indent-width"
                  (is (missing-message? (format-error {}) "indent-width")))



         (testing "format API reports missing parser"
                  (is (missing-message? (format-error {:indent-width 2 :indents {}}) "parser")))



         (testing "indent API reports missing indent-width"
                  (is (missing-message? (indent-error {}) "indent-width")))



         (testing "indent API reports missing parser"
                  (is (missing-message? (indent-error {:indent-width 2 :indents {}}) "parser"))))

(deftest strict-config-shape



         (testing "align-bindings is rejected as an unknown key"
                  (is (= "unknown configuration key: align-bindings"
                         (. (config-error {:align-bindings true}) :message))))



         (testing "top-level lint max-code-lines is rejected"
                  (is (= "unknown lint key: max-code-lines"
                         (. (config-error {:lint {:max-code-lines 300}}) :message))))



         (testing "binding forms are required when binding alignment is enabled"
                  (is (= "missing alignment.binding-forms"
                         (. (config-error {:alignment {:bindings true}}) :message))))



         (testing "clause forms are required when clause alignment is enabled"
                  (is (= "missing alignment.clause-forms"
                         (. (config-error {:alignment {:clauses true}}) :message))))



         (testing "missing alignment switches are off"
                  (let [result (config-error {:alignment {:binding-forms ["let"]
                                                          :clause-forms  ["case"]}})]
                    (is (. result :ok)))))

(deftest strict-lint-options



         (testing "an enabled rule reports the canonical applies-to path"
                  (let [result (lint-error "(module a)"
                                           {:path  "fnl/a.fnl"
                                            :rules {:forbidden-form [{:severity   "warning"
                                                                      :options    {}
                                                                      :exclusions []}]}})]
                    (is (= "lint.rules.forbidden-form[1].applies-to must be a table"
                           (. result :message)))))



         (testing "an enabled rule reports missing option values"
                  (is (missing-message? (lint-error "(module a)"
                                                    {:path  "fnl/a.fnl"
                                                     :rules {:file-size [{:severity   "warning"
                                                                          :applies-to {}
                                                                          :options    {}}]}})
                                        "lint.rules.file-size[1].options.max-code-lines")))



         (testing "an off rule still uses the canonical instance shape"
                  (let [result (lint-error "(module a)"
                                           {:path  "fnl/a.fnl"
                                            :rules {:file-size [{:severity   "off"
                                                                 :applies-to {}
                                                                 :options    {}
                                                                 :exclusions []}]}})]
                    (is (and (. result :ok) (= 0 (length (. result :findings))))))))

(deftest rule-instance-description-validation

         (testing "accepts a non-empty string description"
                  (let [result (config-error {:lint {:rules {:forbidden-form [{:severity    "warning"
                                                                               :description "explain this rule"
                                                                               :applies-to  {}
                                                                               :options     {}
                                                                               :exclusions  []}]}}})]
                    (is (. result :ok))))

         (testing "rejects a non-string description"
                  (let [result (config-error {:lint {:rules {:forbidden-form [{:severity    "warning"
                                                                               :description 42
                                                                               :applies-to  {}
                                                                               :options     {}
                                                                               :exclusions  []}]}}})]
                    (is (= "lint.rules.forbidden-form[1].description must be a non-empty string"
                           (. result :message)))))

         (testing "rejects an empty description"
                  (let [result (config-error {:lint {:rules {:forbidden-form [{:severity    "warning"
                                                                               :description ""
                                                                               :applies-to  {}
                                                                               :options     {}
                                                                               :exclusions  []}]}}})]
                    (is (= "lint.rules.forbidden-form[1].description must be a non-empty string"
                           (. result :message))))))

(deftest strict-config-property



         (testing "the repository config loads with complete format and lint settings"
                  (let [config       (load-module :fennel-extras.config)
                        loaded       (if (. config :module-missing)
                                       nil
                                       (config.load ".fnl-extras.fnl"))
                        lint-rules   (and loaded (. loaded :lint) (. (. loaded :lint) :rules))
                        design-rules (and loaded (. loaded :design) (. (. loaded :design) :rules))
                        lint-names   ["forbidden-form"
                                      "required-form"
                                      "module-import"
                                      "child-count"
                                      "file-size"
                        ]
                        design-names []]
                    (is (and loaded
                             (. (. loaded :format) :indent-width)
                             (. (. loaded :workspace) :extensions)
                             (. (. loaded :workspace) :paths)
                             (. (. loaded :format) :indents)
                             (. (. loaded :format) :parser)
                             (. (. loaded :format) :alignment)
                             (. loaded :lint)
                             (= nil (. loaded :design))
                             (complete-rules? lint-rules lint-names 1))))))

(deftest removed-layout-rule-config-errors

         (testing "strict config rejects removed control-layout"
                  (let [result (config-error {:lint {:rules {"control-layout" [{:severity   "warning"
                                                                                :applies-to {:forms ["if" "when" "and" "or" "case" "match"]}
                                                                                :options    {}
                                                                                :exclusions []}]}}})]
                    (is (= "unknown lint rule: control-layout" (. result :message)))))

         (testing "strict config rejects removed multiline-layout"
                  (let [result (config-error {:lint {:rules {"multiline-layout" [{:severity   "warning"
                                                                                  :applies-to {}
                                                                                  :options    {:clauses  ["case" "match" "case-try" "match-try"]
                                                                                               :bindings ["let" "when-let" "if-let" "with-open"]}
                                                                                  :exclusions []}]}}})]
                    (is (= "unknown lint rule: multiline-layout" (. result :message))))))

(deftest repository-exclusion-contract

         (testing "child-count macro exclusions consolidate to one path-only entry"
                  (let [config     (load-module :fennel-extras.config)
                        loaded     (if (. config :module-missing)
                                     nil
                                     (config.load ".fnl-extras.fnl"))
                        instances  (and loaded (. (. (. loaded :lint) :rules) :child-count))
                        exclusions (and instances (. (. instances 2) :exclusions))]
                    (is (and (= 1 (length exclusions))
                             (= "^spec/eca/macros[.]fnlm$" (. (. exclusions 1) :path))))))

         (testing "module-import uses exclusions for the macro file and has no exempt-files option"
                  (let [config    (load-module :fennel-extras.config)
                        loaded    (if (. config :module-missing)
                                    nil
                                    (config.load ".fnl-extras.fnl"))
                        instances (and loaded (. (. (. loaded :lint) :rules) :module-import))]
                    (is (and instances
                             (= nil (. (. instances 2) :options :exempt-files))
                             (= "^spec/eca/macros[.]fnlm$"
                                (. (. (. instances 2) :exclusions 1) :path))
                             (= nil (. (. instances 3) :options :exempt-files))
                             (= "^spec/eca/macros[.]fnlm$"
                                (. (. (. instances 3) :exclusions 1) :path)))))))
