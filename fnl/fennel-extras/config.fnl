(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.config)

(local core (require :eca.nfnl.core))
(local reader (require :fennel-extras.reader))
(local parse (require :fennel-extras.config.parse))
(local lint-config (require :fennel-extras.config.lint))
(local lint-rules (require :fennel-extras.lint.rules))
(local lint-options (require :fennel-extras.lint.rules.options))
(local alignment (require :fennel-extras.indent.settings))
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

(defn- boolean?
  [value]
  (or (= value true)
      (= value false)))

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

(defn- alignment-error
  [align-bindings alignment-table]
  (if (and (not= align-bindings nil) (not (boolean? align-bindings)))
    {:message "align-bindings must be a boolean"}
    (and alignment-table (alignment.validate alignment-table))))

(defn- configuration-error
  [tbl]
  (or (format-config.validate tbl false false false)
      (configuration-error-with-lint nil (. tbl :lint))))

(defn- normalize-if-needed
  [tbl]
  (if (or (. tbl :align-bindings) (. tbl :alignment))
    (alignment.normalize tbl)
    tbl))

(defn- path-error
  [tbl]
  (when (and (. tbl :paths) (not (array-of-strings? (. tbl :paths))))
    {:message "paths must be an array of strings"}))

(defn- exclude-error
  [tbl]
  (when (and (. tbl :exclude) (not (array-of-strings? (. tbl :exclude))))
    {:message "exclude must be an array of strings"}))

(defn- content-error
  [tbl]
  (or (path-error tbl)
      (exclude-error tbl)))

(defn- validation-result
  [tbl failure]
  (if failure
    (values nil failure)
    (normalize-if-needed tbl)))

(defn- validation-failure
  [tbl]
  (or (configuration-error tbl)
      (content-error tbl)))

(defn- valid-table
  [tbl]
  (validation-result tbl (validation-failure tbl)))

(defn- unknown-config-key
  [tbl]
  (let [allowed {:indents true :format-as true :indent-patterns true :paths true :exclude true :indent-width true :builtins true :prefix-fallbacks true :extensions true :skip-dotfiles true :follow-symlinks true :alignment true :parser true :lint true}]
    (accumulate [failure nil key _ (pairs tbl)]
      (or (and (not (. allowed key))
               {:message (.. "unknown configuration key: " key)})
          failure))))

(defn- validate-table-result
  [tbl failure]
  (if failure
    (values nil failure)
    (valid-table tbl)))

(defn- validate-table
  [tbl]
  (validate-table-result tbl (unknown-config-key tbl)))

(defn validate
  [tbl]
  (if (not= (type tbl) :table)
    (values nil {:message "configuration must be a table"})
    (validate-table tbl)))

(defn- normalized-options
  [options name entry]
  (if entry.options
    (core.assoc options name entry.options)
    options))

(defn- normalized-table-entry
  [rules options name entry]
  (values (core.assoc rules name entry.severity)
          (normalized-options options name entry)))

(defn- normalized-value-entry
  [rules options name entry]
  (values (core.assoc rules name entry) options))

(defn- normalized-rule-entry
  [rules options name entry]
  (if (= (type entry) :table)
    (normalized-table-entry rules options name entry)
    (normalized-value-entry rules options name entry)))

(defn- normalized-overrides-step
  [overrides next-key state recurse]
  (let [(new-rules new-options) (normalized-rule-entry state.rules state.options next-key state.entry)]
    (recurse overrides next-key new-rules new-options)))

(defn- normalized-rule-overrides
  [overrides key rules options]
  (let [(next-key next-entry) (next overrides key)]
    (if (= next-key nil)
      (values rules options)
      (normalized-overrides-step overrides next-key {:entry next-entry :rules rules :options options} normalized-rule-overrides))))

(defn- lint-policy-result
  [rules options exclusions spec-files]
  {:rules rules :options options :spec-files spec-files :exclusions exclusions})

(defn- lint-policy-defaults
  []
  (lint-rules.defaults))

(defn- valid-lint-policy
  [cfg]
  (let [lint                     (. cfg :lint)
        overrides                (or (and lint (. lint :rules)) {})
        general                  (or (and lint (. lint :exclusions)) [])
        exclusions               (core.concat general (lint-config.exclusions overrides))
        spec-files               (. lint :spec-files)
        defaults                 (lint-policy-defaults)
        (rules explicit-options) (normalized-rule-overrides overrides nil defaults {})
        options                  (lint-options.normalized explicit-options)]
    (lint-policy-result rules options exclusions spec-files)))

(defn- lint-policy-valid
  [valid]
  (if (= valid.lint nil)
    (values nil {:message "missing lint.spec-files"})
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
