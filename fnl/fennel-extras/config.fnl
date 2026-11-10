(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

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
  (or (= (. value index) nil)
      (and (= (type (. value index)) :string)
           (array-of-strings-step value (+ index 1)))))

(defn- array-of-strings?
  [value]
  (and (= (type value) :table)
       (array-of-strings-step value 1)))

(defn- integer?
  [value]
  (and (= (type value) :number)
       (= value (math.floor value))))

(defn- valid-rule?
  [rule]
  (and (= (type rule) :table) (= (type (. rule 1)) :string)
       (let [kind  (. rule 1)
             value (. rule 2)
             index (. rule 3)]
         (if (= kind :block)
           (and (integer? value) (>= value 0) (= index nil))
           (and (= kind :inner)
                (and (= value 0)
                     (or (= index nil) (and (integer? index) (>= index 0)))))))))

(defn- valid-rule-list-step
  [value index]
  (or (> index (length value))
      (and (valid-rule? (. value index))
           (valid-rule-list-step value (+ index 1)))))

(defn- valid-rule-list?
  [value]
  (and (= (type value) :table)
       (valid-rule-list-step value 1)))

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
  (or (> index (length value))
      (and (= (type (. value index)) :string)
           (= (string.sub (. value index) 1 1) ".")
           (extensions-step value (+ index 1)))))

(defn- extensions?
  [value]
  (and (= (type value) :table)
       (> (length value) 0)
       (extensions-step value 1)))

(defn- configuration-error-with-lint
  [failure lint]
  (or failure
      (and lint (lint-config.lint-error lint))))

(defn- configuration-error
  [tbl]
  (or (and (. tbl :format)
           (format-config.validate (. tbl :format) false false false))
      (configuration-error-with-lint nil (. tbl :lint))
      (and (. tbl :design)
           (lint-config.design-error (. tbl :design)))))

(defn- workspace-key-error
  [workspace]
  (when (= (type workspace) :table)
        (let [allowed {:paths true :exclude true :extensions true :dotfiles true :symlinks true :config true}
              key     (accumulate [candidate nil name _ (pairs workspace)]
                                  (if (and (not (. allowed name))
                                           (or (= candidate nil)
                                               (< (tostring name) (tostring candidate))))
                                    name
                                    candidate))]
          (when key
                {:message (.. "unknown workspace key: " key)}))))

(defn- workspace-error
  [tbl]
  (let [workspace (. tbl :workspace)]
    (or (when (and workspace (not= (type workspace) :table))
              {:message "workspace must be a table"})
        (workspace-key-error workspace)
        (when (and workspace workspace.paths (not (array-of-strings? workspace.paths)))
              {:message "workspace.paths must be an array of strings"})
        (when (and workspace workspace.exclude (not (array-of-strings? workspace.exclude)))
              {:message "workspace.exclude must be an array of strings"})
        (when (and workspace workspace.extensions (not (extensions? workspace.extensions)))
              {:message "workspace.extensions must be a non-empty list of strings starting with \".\""})
        (when (and workspace
                   (not= workspace.dotfiles nil)
                   (not (or (= workspace.dotfiles true) (= workspace.dotfiles false))))
              {:message "workspace.dotfiles must be a boolean"})
        (when (and workspace
                   (not= workspace.symlinks nil)
                   (not (or (= workspace.symlinks true) (= workspace.symlinks false))))
              {:message "workspace.symlinks must be a boolean"})
        (when (and workspace
                   (not= workspace.config nil)
                   (not (or (= workspace.config true) (= workspace.config false))))
              {:message "workspace.config must be a boolean"}))))

(defn- content-error
  [tbl]
  (workspace-error tbl))

(defn validate-workspace
  [workspace require-paths?]
  (or (when (not= (type workspace) :table)
            {:message "workspace must be a table"})
      (workspace-key-error workspace)
      (when (and require-paths? (= workspace.paths nil))
            {:message "missing workspace.paths"})
      (when (and workspace.paths (not (array-of-strings? workspace.paths)))
            {:message "workspace.paths must be an array of strings"})
      (when (and workspace.exclude (not (array-of-strings? workspace.exclude)))
            {:message "workspace.exclude must be an array of strings"})
      (when (and workspace.extensions (not (extensions? workspace.extensions)))
            {:message "workspace.extensions must be a non-empty list of strings starting with \".\""})
      (when (and (not= workspace.dotfiles nil)
                 (not (or (= workspace.dotfiles true) (= workspace.dotfiles false))))
            {:message "workspace.dotfiles must be a boolean"})
      (when (and (not= workspace.symlinks nil)
                 (not (or (= workspace.symlinks true) (= workspace.symlinks false))))
            {:message "workspace.symlinks must be a boolean"})
      (when (and (not= workspace.config nil)
                 (not (or (= workspace.config true) (= workspace.config false))))
            {:message "workspace.config must be a boolean"})))

(defn- validation-result
  [tbl failure]
  (if failure
    (values nil failure)
    tbl))

(defn- validation-failure
  [tbl]
  (or (configuration-error tbl)
      (content-error tbl)))

(defn- valid-table
  [tbl]
  (validation-result tbl (validation-failure tbl)))

(defn- unknown-config-key
  [tbl]
  (let [allowed {:workspace true :format true :lint true :design true}]
    (accumulate [candidate nil key _ (pairs tbl)]
                (if (and (not (. allowed key))
                         (or (= candidate nil)
                             (< (tostring key) (tostring candidate))))
                  key
                  candidate))))

(defn- unknown-config-error
  [tbl]
  (let [key (unknown-config-key tbl)]
    (when key
          {:message (.. "unknown configuration key: " key)})))

(defn- format-fragment-key?
  [key]
  (or (= key :indent-width)
      (= key :parser)
      (= key :indents)
      (= key :format-as)
      (= key :alignment)
      (= key :newline)
      (= key :extensions)))

(defn- unknown-format-fragment-key
  [tbl]
  (accumulate [candidate nil key _ (pairs tbl)]
              (if (and (not (format-fragment-key? key))
                       (or (= candidate nil)
                           (< (tostring key) (tostring candidate))))
                key
                candidate)))

(defn- format-fragment-error
  [tbl]
  (let [key (unknown-format-fragment-key tbl)]
    (if key
      {:message (.. "unknown configuration key: " key)}
      (format-config.validate tbl false false false))))

(defn- validate-table-result
  [tbl failure]
  (if failure
    (values nil failure)
    (valid-table tbl)))

(defn- validate-canonical-table
  [tbl]
  (validate-table-result tbl (unknown-config-error tbl)))

(defn validate
  [tbl]
  (if (not= (type tbl) :table)
    (values nil {:message "configuration must be a table"})
    (if (or (. tbl :workspace) (. tbl :format) (. tbl :lint) (. tbl :design))
      (validate-canonical-table tbl)
      (let [failure (format-fragment-error tbl)]
        (validation-result tbl failure)))))

(defn- append-canonical-instance-exclusions
  [result rule index instance]
  (each [_ exclusion (ipairs (or instance.exclusions []))]
        (let [copy {}]
          (each [key value (pairs exclusion)]
                (tset copy key value))
          (table.insert result (core.assoc (core.assoc copy :rule rule) :instance index))))
  result)

(defn- append-canonical-rule-exclusions
  [result rule instances]
  (each [index instance (ipairs (or instances []))]
        (append-canonical-instance-exclusions result rule index instance))
  result)

(defn- canonical-exclusions
  [rules]
  (let [result []]
    (each [rule instances (pairs rules)]
          (append-canonical-rule-exclusions result rule instances))
    result))

(defn- valid-lint-policy
  [cfg]
  (let [rules  (core.merge (or (and cfg.lint cfg.lint.rules) {}))
        design (and cfg.design cfg.design.rules)]
    (each [rule instances (pairs (or design {}))]
          (when (= (. rules rule) nil)
                (tset rules rule instances)))
    (let [normalized (if (and (. rules "form-child-count")
                              (. rules "child-count"))
                       (core.assoc rules "form-child-count" nil)
                       rules)]
      {:rules      normalized
       :design     (and cfg.design {:rules design})
       :exclusions (canonical-exclusions normalized)})))

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

(defn load
  [path]
  (let [file (io.open path :r)]
    (if (not file)
      (values nil {:message (.. "could not read config file: " path)})
      (let [text (file:read "*a")]
        (file:close)
        (let [(ok parsed-or-error) (pcall (fn
                                            []
                                            (parse-string text)))]


          (if (not ok)
            (values nil parsed-or-error)
            (validate parsed-or-error)))))))
