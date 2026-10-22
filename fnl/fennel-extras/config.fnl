(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.config)

(local core (require :eca.nfnl.core))
(local reader (require :fennel-extras.reader))
(local parse (require :fennel-extras.config.parse))
(local lint-config (require :fennel-extras.config.lint))
(local lint-rules (require :fennel-extras.lint.rules))
(local lint-options (require :fennel-extras.lint.rules.options))
(local alignment (require :fennel-extras.indent.settings))

(local compatibility-policy {:module-style "error" :spec-macro-import "error" :spec-no-module "error" :spec-direct-require "error" :one-is-per-testing "error" :if-branch-call "warning" :if-without-else "warning" :control-layout "warning" :unused-and-or "warning" :defn-args-newline "warning" :function-shape "warning" :no-mutation "warning" :multiline-layout "warning" :file-size "warning" :core-require "error" :binding-per-line "warning" :call-data-arg "warning"})

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
  (let [width           (. tbl :indent-width)
        builtins        (. tbl :builtins)
        fallbacks       (. tbl :prefix-fallbacks)
        extensions      (. tbl :extensions)
        skip-dotfiles   (. tbl :skip-dotfiles)
        follow-symlinks (. tbl :follow-symlinks)
        align-bindings  (. tbl :align-bindings)
        alignment-table (. tbl :alignment)
        parser          (. tbl :parser)
        lint            (. tbl :lint)]
    (var failure nil)
    (when (and (= failure nil)
               (not= width nil)
               (not (and (integer? width) (> width 0))))
      (set failure {:message "indent-width must be a positive integer"}))
    (when (and (= failure nil)
               (not= builtins nil)
               (not (= builtins true))
               (not (= builtins false))
               (not= (type builtins) :table))
      (set failure {:message "builtins must be true, false, or a table of rules"}))
    (when (and (= failure nil) (= (type builtins) :table))
      (set failure (rule-map-error builtins "builtins rule ")))
    (when (and (= failure nil)
               (not= fallbacks nil)
               (not (= fallbacks false))
               (not= (type fallbacks) :table))
      (set failure {:message "prefix-fallbacks must be false or a table of rules"}))
    (when (and (= failure nil) (= (type fallbacks) :table))
      (set failure (rule-map-error fallbacks "prefix-fallbacks rule ")))
    (when (and (= failure nil) (not= extensions nil) (not (extensions? extensions)))
      (set failure {:message "extensions must be a non-empty list of strings starting with \".\""}))
    (when (and (= failure nil) (not= skip-dotfiles nil) (not (boolean? skip-dotfiles)))
      (set failure {:message "skip-dotfiles must be a boolean"}))
    (when (and (= failure nil) (not= follow-symlinks nil) (not (boolean? follow-symlinks)))
      (set failure {:message "follow-symlinks must be a boolean"}))
    (when (= failure nil)
      (set failure (alignment-error align-bindings alignment-table)))
    (when (and (= failure nil) (not= parser nil) (not= (type parser) :string))
      (set failure {:message "parser must be a string"}))
    (configuration-error-with-lint failure lint)))

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

(defn validate
  [tbl]
  (if (not= (type tbl) :table)
    (values nil {:message "configuration must be a table"})
    (let [allowed {:indents true :format-as true :indent-patterns true :paths true :exclude true :indent-width true :builtins true :prefix-fallbacks true :extensions true :skip-dotfiles true :follow-symlinks true :align-bindings true :alignment true :parser true :lint true}]
      (var failure nil)
      (each [key _ (pairs tbl)]
        (when (not (. allowed key))
          (set failure {:message (.. "unknown configuration key: " key)})))
      (if failure
        (values nil failure)
        (valid-table tbl)))))

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
  [rules options exclusions max-code-lines spec-files]
  {:rules rules :options options :spec-files spec-files :exclusions exclusions :max-code-lines max-code-lines})

(defn- lint-policy-defaults
  [overrides]
  (if (= (next overrides nil) nil)
    (lint-rules.defaults)
    compatibility-policy))

(defn- valid-lint-policy
  [cfg]
  (let [lint                     (. cfg :lint)
        overrides                (or (and lint (. lint :rules)) {})
        general                  (or (and lint (. lint :exclusions)) [])
        exclusions               (core.concat general (lint-config.exclusions overrides))
        max-code-lines           (or (and lint (. lint :max-code-lines)) 300)
        spec-files               (or (and lint (. lint :spec-files)) (lint-options.spec-files))
        defaults                 (lint-policy-defaults overrides)
        (rules explicit-options) (normalized-rule-overrides overrides nil defaults {})
        options                  (lint-options.normalized explicit-options)]
    (lint-policy-result rules options exclusions max-code-lines spec-files)))

(defn lint-policy
  [cfg]
  (let [(valid error) (validate cfg)]
    (if error
      (values nil error)
      (valid-lint-policy valid))))

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
