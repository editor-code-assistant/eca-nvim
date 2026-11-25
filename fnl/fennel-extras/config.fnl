(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)
(import-macros {: cond} :fennel-extras.macros)

(module fennel-extras.config)

(local core (require :eca.nfnl.core))
(local reader (require :fennel-extras.reader))
(local parse (require :fennel-extras.config.parse))
(local lint-config (require :fennel-extras.config.lint))
(local format-config (require :fennel-extras.config.format))
(local find-config (require :fennel-extras.config.find))

(defn parse-string
  [text]
  (parse.parse-string text))

(defn- array-of-strings-step
  [value index]
  (cond
    (= (. value index) nil)
    true

    (= (type (. value index)) :string)
    (array-of-strings-step value (+ index 1))

    :else
    false))

(defn- array-of-strings?
  [value]
  (cond
    (= (type value) :table)
    (array-of-strings-step value 1)

    :else
    false))

(defn- integer?
  [value]
  (cond
    (= (type value) :number)
    (= value (math.floor value))

    :else
    false))

(defn- valid-index?
  [index]
  (cond
    (= index nil)
    true

    (integer? index)
    (>= index 0)

    :else
    false))

(defn- valid-rule-values?
  [rule]
  (let [kind  (. rule 1)
        value (. rule 2)
        index (. rule 3)]
    (cond
      (= kind :block)
      (and (integer? value) (>= value 0) (= index nil))

      (= kind :inner)
      (and (= value 0) (valid-index? index))

      :else
      false)))

(defn- valid-rule?
  [rule]
  (and (= (type rule) :table) (= (type (. rule 1)) :string)
       (valid-rule-values? rule)))

(defn- valid-rule-list-step
  [value index]
  (cond
    (> index (length value))
    true

    (valid-rule? (. value index))
    (valid-rule-list-step value (+ index 1))

    :else
    false))

(defn- valid-rule-list?
  [value]
  (cond
    (= (type value) :table)
    (valid-rule-list-step value 1)

    :else
    false))

(defn- rule-map-error-step
  [value prefix name]
  (let [(next-name rule) (next value name)]
    (when next-name
      (if (valid-rule-list? rule)
        (rule-map-error-step value prefix next-name)
        {:message (.. prefix next-name ": invalid indentation rule")}))))

(defn- rule-map-error
  [value prefix]
  (if (= (type value) :table)
    (rule-map-error-step value prefix nil)
    {:message (.. prefix ": invalid indentation rule")}))

(defn- extensions-step
  [value index]
  (cond
    (> index (length value))
    true

    (and (= (type (. value index)) :string)
         (= (string.sub (. value index) 1 1) "."))
    (extensions-step value (+ index 1))

    :else
    false))

(defn- extensions?
  [value]
  (and (= (type value) :table)
       (> (length value) 0)
       (extensions-step value 1)))

(defn- configuration-error-with-lint
  [failure lint]
  (cond
    failure
    failure

    lint
    (lint-config.lint-error lint)

    :else
    nil))

(defn- configuration-error
  [tbl]
  (let [format-error (and (. tbl :format)
                          (format-config.validate (. tbl :format) false false false))
        lint-error   (configuration-error-with-lint format-error (. tbl :lint))]
    (cond
      lint-error
      lint-error

      (. tbl :design)
      (lint-config.design-error (. tbl :design))

      :else
      nil)))

(defn- workspace-key-candidate?
  [allowed candidate name]
  (cond
    (. allowed name)
    false

    (= candidate nil)
    true

    :else
    (< (tostring name) (tostring candidate))))

(defn- workspace-key
  [workspace]
  (let [allowed {:paths true :exclude true :extensions true :dotfiles true :symlinks true :config true}]
    (accumulate [candidate nil name _ (pairs workspace)]
      (if (workspace-key-candidate? allowed candidate name) name candidate))))

(defn- workspace-key-error
  [workspace]
  (let [key (and (= (type workspace) :table) (workspace-key workspace))]
    (when key
      {:message (.. "unknown workspace key: " key)})))

(defn- workspace-error-message
  [message]
  {:message message})

(defn- boolean?
  [value]
  (or (= value true) (= value false)))

(defn- invalid-optional-boolean?
  [workspace key]
  (and workspace (not= (. workspace key) nil) (not (boolean? (. workspace key)))))

(defn- validate-workspace-value
  [workspace require-workspace? require-paths?]
  (let [table?             (= (type workspace) :table)
        workspace-required (or require-workspace? workspace)
        key-error          (and table? (workspace-key-error workspace))]
    (cond
      (and workspace-required (not table?))
      (workspace-error-message "workspace must be a table")

      key-error
      key-error

      (and table? require-paths? (= workspace.paths nil))
      (workspace-error-message "missing workspace.paths")

      (and table? workspace.paths (not (array-of-strings? workspace.paths)))
      (workspace-error-message "workspace.paths must be an array of strings")

      (and table? workspace.exclude (not (array-of-strings? workspace.exclude)))
      (workspace-error-message "workspace.exclude must be an array of strings")

      (and table? workspace.extensions (not (extensions? workspace.extensions)))
      (workspace-error-message "workspace.extensions must be a non-empty list of strings starting with \".\"")

      (invalid-optional-boolean? workspace :dotfiles)
      (workspace-error-message "workspace.dotfiles must be a boolean")

      (invalid-optional-boolean? workspace :symlinks)
      (workspace-error-message "workspace.symlinks must be a boolean")

      (invalid-optional-boolean? workspace :config)
      (workspace-error-message "workspace.config must be a boolean")

      :else
      nil)))

(defn- workspace-error
  [tbl]
  (validate-workspace-value (. tbl :workspace) false false))

(defn validate-workspace
  [workspace require-paths?]
  (validate-workspace-value workspace true require-paths?))

(defn- validation-result
  [tbl failure]
  (if failure
    (values nil failure)
    tbl))

(defn- validation-failure
  [tbl]
  (or (configuration-error tbl)
      (workspace-error tbl)))

(defn- valid-table
  [tbl]
  (validation-result tbl (validation-failure tbl)))

(defn- unknown-config-key
  [tbl]
  (let [allowed {:workspace true :format true :lint true :design true}]
    (accumulate [candidate nil key _ (pairs tbl)]
      (if (workspace-key-candidate? allowed candidate key) key candidate))))

(defn- unknown-config-error
  [tbl]
  (let [key (unknown-config-key tbl)]
    (when key
      {:message (.. "unknown configuration key: " key)})))

(defn- validate-table-result
  [tbl failure]
  (if failure
    (values nil failure)
    (valid-table tbl)))

(defn- validate-canonical-table
  [tbl]
  (validate-table-result tbl (unknown-config-error tbl)))

(defn- validate-format-fragment
  [tbl]
  (let [failure (format-config.validate-fragment tbl)]
    (validation-result tbl failure)))

(defn validate
  [tbl]
  (cond
    (not= (type tbl) :table)
    (values nil {:message "configuration must be a table"})

    (or (not= (rawget tbl :workspace) nil) (not= (rawget tbl :format) nil) (not= (rawget tbl :lint) nil) (not= (rawget tbl :design) nil))
    (validate-canonical-table tbl)

    :else
    (validate-format-fragment tbl)))

(defn- append-canonical-exclusion
  [result rule index exclusion]
  (table.insert result (core.assoc (core.assoc exclusion :rule rule) :instance index))
  result)

(defn- append-canonical-instance-exclusions
  [result rule index instance]
  (icollect [_ exclusion (ipairs (or instance.exclusions []))]
    (append-canonical-exclusion result rule index exclusion))
  result)

(defn- append-canonical-rule-exclusions
  [result rule instances]
  (icollect [index instance (ipairs (or instances []))]
    (append-canonical-instance-exclusions result rule index instance))
  result)

(defn- canonical-exclusions
  [rules]
  (let [result []]
    (icollect [rule instances (pairs rules)]
      (append-canonical-rule-exclusions result rule instances))
    result))

(defn- normalize-lint-rules
  [rules]
  (let [normalized (if (and (. rules "form-child-count")
                            (. rules "child-count"))
                     (core.assoc rules "form-child-count" nil)
                     rules)]
    normalized))

(defn- valid-lint-policy-result
  [cfg rules design]
  (let [normalized (normalize-lint-rules rules)]
    {:rules      normalized
     :design     (and cfg.design {:rules design})
     :exclusions (canonical-exclusions normalized)}))

(defn- merge-design-rules
  [rules design]
  (accumulate [result (core.merge rules) rule instances (pairs (or design {}))]
    (if (= (. result rule) nil) (core.assoc result rule instances) result)))

(defn- valid-lint-policy
  [cfg]
  (let [rules  (core.merge (or (and cfg.lint cfg.lint.rules) {}))
        design (and cfg.design cfg.design.rules)]
    (valid-lint-policy-result cfg (merge-design-rules rules design) design)))

(defn- lint-policy-valid
  [valid]
  (if (and (= valid.lint nil) (= valid.design nil))
    (values nil {:message "missing lint or design"})
    (valid-lint-policy valid)))

(defn lint-policy
  [cfg]
  (let [(valid error) (validate cfg)]
    (if error
      (values nil error)
      (lint-policy-valid valid))))

(defn find
  [start-dir]
  (find-config.find start-dir))

(defn- parse-loaded-text
  [text]
  (let [(ok parsed-or-error) (pcall (fn [] (parse-string text)))]
    (if (not ok)
      (values nil parsed-or-error)
      (validate parsed-or-error))))

(defn- read-file-text
  [file]
  (let [text (file:read "*a")]
    (file:close)
    text))

(defn load
  [path]
  (let [file (io.open path :r)]
    (if (not file)
      (values nil {:message (.. "could not read config file: " path)})
      (parse-loaded-text (read-file-text file)))))
