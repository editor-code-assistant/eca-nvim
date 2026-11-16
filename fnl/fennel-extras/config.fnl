(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.config)

(local core (require :eca.nfnl.core))
(local reader (require :fennel-extras.reader))
(local parse (require :fennel-extras.config.parse))
(local lint-config (require :fennel-extras.config.lint))
(local format-config (require :fennel-extras.config.format))
(local find-config (require :fennel-extras.config.find))

(defn- branch
  [condition then else]
  ((or (and condition then) else)))

(defn- noop
  []
  nil)

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

(defn- valid-rule-values?
  [rule]
  (let [kind  (. rule 1)
        value (. rule 2)
        index (. rule 3)]
    (branch (= kind :block)
            (fn [] (and (integer? value) (>= value 0) (= index nil)))

            (fn [] (and (= kind :inner)
                        (and (= value 0)
                             (or (= index nil) (and (integer? index) (>= index 0)))))))))

(defn- valid-rule?
  [rule]
  (and (= (type rule) :table) (= (type (. rule 1)) :string)
       (valid-rule-values? rule)))

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
    (branch next-name
            (fn []
              (branch (valid-rule-list? rule)
                      (fn [] (rule-map-error-step value prefix next-name))

                      (fn [] {:message (.. prefix next-name ": invalid indentation rule")})))
            noop)))

(defn- rule-map-error
  [value prefix]
  (branch (= (type value) :table)
          (fn [] (rule-map-error-step value prefix nil))

          (fn [] {:message (.. prefix ": invalid indentation rule")})))

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

(defn- workspace-key
  [workspace]
  (let [allowed {:paths true :exclude true :extensions true :dotfiles true :symlinks true :config true}]
    (accumulate [candidate nil name _ (pairs workspace)]
                (branch (and (not (. allowed name))
                             (or (= candidate nil) (< (tostring name) (tostring candidate))))
                        (fn [] name)

                        (fn [] candidate)))))

(defn- workspace-key-error-result
  [workspace]
  (let [key (workspace-key workspace)]
    (branch key
            (fn [] {:message (.. "unknown workspace key: " key)})
            noop)))

(defn- workspace-key-error
  [workspace]
  (and (= (type workspace) :table)
       (workspace-key-error-result workspace)))

(defn- workspace-error
  [tbl]
  (let [workspace (. tbl :workspace)]
    (or (branch (and workspace (not= (type workspace) :table))
                (fn [] {:message "workspace must be a table"})
                noop)
        (workspace-key-error workspace)
        (branch (and workspace workspace.paths (not (array-of-strings? workspace.paths))) (fn [] {:message "workspace.paths must be an array of strings"}) noop)
        (branch (and workspace workspace.exclude (not (array-of-strings? workspace.exclude))) (fn [] {:message "workspace.exclude must be an array of strings"}) noop)
        (branch (and workspace workspace.extensions (not (extensions? workspace.extensions))) (fn [] {:message "workspace.extensions must be a non-empty list of strings starting with \".\""}) noop)
        (branch (and workspace (not= workspace.dotfiles nil)
                     (not (or (= workspace.dotfiles true) (= workspace.dotfiles false))))
                (fn [] {:message "workspace.dotfiles must be a boolean"}) noop)
        (branch (and workspace (not= workspace.symlinks nil)
                     (not (or (= workspace.symlinks true) (= workspace.symlinks false))))
                (fn [] {:message "workspace.symlinks must be a boolean"}) noop)
        (branch (and workspace (not= workspace.config nil)
                     (not (or (= workspace.config true) (= workspace.config false))))
                (fn [] {:message "workspace.config must be a boolean"}) noop))))

(defn- content-error
  [tbl]
  (workspace-error tbl))

(defn validate-workspace
  [workspace require-paths?]
  (or (branch (not= (type workspace) :table)
              (fn [] {:message "workspace must be a table"})
              noop)
      (workspace-key-error workspace)
      (branch (and require-paths? (= workspace.paths nil))
              (fn [] {:message "missing workspace.paths"})
              noop)
      (branch (and workspace.paths (not (array-of-strings? workspace.paths))) (fn [] {:message "workspace.paths must be an array of strings"}) noop)
      (branch (and workspace.exclude (not (array-of-strings? workspace.exclude))) (fn [] {:message "workspace.exclude must be an array of strings"}) noop)
      (branch (and workspace.extensions (not (extensions? workspace.extensions))) (fn [] {:message "workspace.extensions must be a non-empty list of strings starting with \".\""}) noop)
      (branch (and (not= workspace.dotfiles nil)
                   (not (or (= workspace.dotfiles true) (= workspace.dotfiles false))))
              (fn [] {:message "workspace.dotfiles must be a boolean"}) noop)
      (branch (and (not= workspace.symlinks nil)
                   (not (or (= workspace.symlinks true) (= workspace.symlinks false))))
              (fn [] {:message "workspace.symlinks must be a boolean"}) noop)
      (branch (and (not= workspace.config nil)
                   (not (or (= workspace.config true) (= workspace.config false))))
              (fn [] {:message "workspace.config must be a boolean"}) noop)))

(defn- validation-result
  [tbl failure]
  (branch failure
          (fn [] (values nil failure))

          (fn [] tbl)))

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
                (branch (and (not (. allowed key))
                             (or (= candidate nil) (< (tostring key) (tostring candidate))))
                        (fn [] key)

                        (fn [] candidate)))))

(defn- unknown-config-error
  [tbl]
  (let [key (unknown-config-key tbl)]
    (branch key
            (fn [] {:message (.. "unknown configuration key: " key)})
            noop)))

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
              (branch (and (not (format-fragment-key? key))
                           (or (= candidate nil) (< (tostring key) (tostring candidate))))
                      (fn [] key)

                      (fn [] candidate))))

(defn- format-fragment-error
  [tbl]
  (let [key (unknown-format-fragment-key tbl)]
    (branch key
            (fn [] {:message (.. "unknown configuration key: " key)})

            (fn [] (format-config.validate tbl false false false)))))

(defn- validate-table-result
  [tbl failure]
  (branch failure
          (fn [] (values nil failure))

          (fn [] (valid-table tbl))))

(defn- validate-canonical-table
  [tbl]
  (validate-table-result tbl (unknown-config-error tbl)))

(defn- validate-format-fragment
  [tbl]
  (let [failure (format-fragment-error tbl)]
    (validation-result tbl failure)))

(defn validate
  [tbl]
  (branch (not= (type tbl) :table)
          (fn [] (values nil {:message "configuration must be a table"}))

          (fn []
            (branch (or (. tbl :workspace) (. tbl :format) (. tbl :lint) (. tbl :design))
                    (fn [] (validate-canonical-table tbl))

                    (fn [] (validate-format-fragment tbl))))))

(defn- append-canonical-exclusion
  [result rule index exclusion]
  (let [copy {}]
    (each [key value (pairs exclusion)]
          (tset copy key value))
    (table.insert result (core.assoc (core.assoc copy :rule rule) :instance index)))
  result)

(defn- append-canonical-instance-exclusions
  [result rule index instance]
  (each [_ exclusion (ipairs (or instance.exclusions []))]
        (append-canonical-exclusion result rule index exclusion))
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

(defn- normalize-lint-rules
  [rules]
  (let [normalized (branch (and (. rules "form-child-count")
                                (. rules "child-count"))
                           (fn [] (core.assoc rules "form-child-count" nil))

                           (fn [] rules))]
    normalized))

(defn- valid-lint-policy-result
  [cfg rules design]
  (let [normalized (normalize-lint-rules rules)]
    {:rules      normalized
     :design     (and cfg.design {:rules design})
     :exclusions (canonical-exclusions normalized)}))

(defn- valid-lint-policy
  [cfg]
  (let [rules  (core.merge (or (and cfg.lint cfg.lint.rules) {}))
        design (and cfg.design cfg.design.rules)]
    (each [rule instances (pairs (or design {}))]
          (branch (= (. rules rule) nil)
                  (fn [] (tset rules rule instances))
                  noop))
    (valid-lint-policy-result cfg rules design)))

(defn- lint-policy-valid
  [valid]
  (branch (and (= valid.lint nil) (= valid.design nil))
          (fn [] (values nil {:message "missing lint or design"}))

          (fn [] (valid-lint-policy valid))))

(defn lint-policy
  [cfg]
  (let [(valid error) (validate cfg)]
    (branch error
            (fn [] (values nil error))

            (fn [] (lint-policy-valid valid)))))

(defn find
  [start-dir]
  (find-config.find start-dir))

(defn- parse-loaded-text
  [text]
  (let [(ok parsed-or-error) (pcall (fn
                                      []
                                      (parse-string text)))]
    (branch (not ok)
            (fn [] (values nil parsed-or-error))

            (fn [] (validate parsed-or-error)))))

(defn- read-file-text
  [file]
  (let [text (file:read "*a")]
    (file:close)
    text))

(defn load
  [path]
  (let [file (io.open path :r)]
    (branch (not file)
            (fn [] (values nil {:message (.. "could not read config file: " path)}))

            (fn [] (parse-loaded-text (read-file-text file))))))
