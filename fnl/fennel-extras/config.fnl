(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.config)

(local core (require :eca.nfnl.core))
(local reader (require :fennel-extras.reader))
(local parse (require :fennel-extras.config.parse))
(local lint-config (require :fennel-extras.config.lint))
(local format-config (require :fennel-extras.config.format))

(defn parse-string
  [text]
  (parse.parse-string text))



(defn- array-of-strings?
  [value]
  (if (not= (type value) :table)
    false
    (let []
      (var valid true)
      (var index 1)
      (while (and valid (not= (. value index) nil))
        (when (not= (type (. value index)) :string)
          (set valid false))
        (set index (+ index 1)))
      valid)))



(defn- integer?
  [value]
  (and (= (type value) :number)
       (= value (math.floor value))))



(defn- valid-rule?
  [rule]
  (if (and (= (type rule) :table) (= (type (. rule 1)) :string))
    (let [kind  (. rule 1)
          value (. rule 2)
          index (. rule 3)]
      (if (= kind :block)
        (and (integer? value) (>= value 0) (= index nil))
        (if (= kind :inner)
          (and (= value 0)
               (or (= index nil) (and (integer? index) (>= index 0))))
          false)))
    false))



(defn- valid-rule-list?
  [value]
  (if (= (type value) :table)
    (let []
      (var valid true)
      (each [_ rule (ipairs value)]
        (when (not (valid-rule? rule))
          (set valid false)))
      valid)
    false))



(defn- rule-map-error
  [value prefix]
  (if (= (type value) :table)
    (let []
      (var failure nil)
      (each [name rule (pairs value)]
        (when (= failure nil)
          (when (not (valid-rule-list? rule))
            (set failure {:message (.. prefix name ": invalid indentation rule")}))))
      failure)
    {:message (.. prefix ": invalid indentation rule")}))



(defn- extensions?
  [value]
  (if (and (= (type value) :table) (> (length value) 0))
    (let []
      (var valid true)
      (each [_ extension (ipairs value)]
        (when (or (not= (type extension) :string)
                  (not (= (string.sub extension 1 1) ".")))
          (set valid false)))
      valid)
    false))



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
      (= key :builtins)
      (= key :prefix-fallbacks)
      (= key :parser)
      (= key :indents)
      (= key :format-as)
      (= key :indent-patterns)
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
  (let [rules  (or (and cfg.lint cfg.lint.rules) {})
        design (and cfg.design cfg.design.rules)]
    {:rules      rules
     :design     design
     :exclusions (core.concat (canonical-exclusions rules)
                              (canonical-exclusions (or design {})))}))



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



(defn- join-path
  [dir name]
  (if (= (string.sub dir -1) "/")
    (.. dir name)
    (.. dir "/" name)))



(defn- close-file
  [file]
  (file:close)
  true)



(defn- exists?
  [path]
  (let [uv (or (and vim vim.loop) (and vim vim.uv))]
    (if uv
      (not= nil (uv.fs_stat path))
      (let [file (io.open path :r)]
        (if file
          (close-file file)
          false)))))



(defn- git-marker?
  [dir]
  (or (exists? (join-path dir ".git"))
      (exists? (join-path (join-path dir ".git") "HEAD"))))



(defn- parent-dir
  [dir]
  (let [trimmed (if (and (> (string.len dir) 1) (= (string.sub dir -1) "/"))
                  (string.sub dir 1 -2)
                  dir)
        parent  (string.match trimmed "^(.*)/[^/]+$")]
    (when parent
      (if (= parent "")
        "/"
        parent))))



(defn- found-config
  [candidate]
  (values candidate false))



(defn find
  [start-dir]
  (var dir start-dir)
  (var result nil)
  (var searching true)
  (while searching
    (let [candidate (join-path dir ".fnl-extras.fnl")]
      (if (exists? candidate)
        (let [(new-result new-searching) (found-config candidate)]
          (set result new-result)
          (set searching new-searching))
        (if (git-marker? dir)
          (set searching false)
          (let [parent (parent-dir dir)]
            (if parent
              (set dir parent)
              (set searching false)))))))
  result)



(defn load
  [path]
  (let [file (io.open path :r)]
    (if (not file)
      (values nil {:message (.. "could not read config file: " path)})
      (let [text (file:read "*a")]
        (file:close)
        (let [(ok parsed-or-error) (pcall (fn [] (parse-string text)))]


          (if (not ok)
            (values nil parsed-or-error)
            (validate parsed-or-error)))))))
