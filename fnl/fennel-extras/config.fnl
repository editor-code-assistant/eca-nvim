(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.config)

(local core (require :eca.nfnl.core))
(local reader (require :fennel-extras.reader))
(local parse (require :fennel-extras.config.parse))
(local lint-config (require :fennel-extras.config.lint))
(local lint-rules (require :fennel-extras.lint.rules))

(defn parse-string
  [text]
  (parse.parse-string text))

(defn- array-of-strings?
  [value]
  (if
    (not= (type value) :table)
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
  (and
   (= (type value) :number)
   (= value (math.floor value))))

(defn- valid-rule?
  [rule]
  (if
    (and (= (type rule) :table) (= (type (. rule 1)) :string))
    (let [kind (. rule 1) value (. rule 2) index (. rule 3)]
      (if
        (= kind :block)
        (and (integer? value) (>= value 0) (= index nil))
        (if
          (= kind :inner)
          (and (= value 0)
               (or (= index nil) (and (integer? index) (>= index 0))))
          false)))
    false))

(defn- valid-rule-list?
  [value]
  (if
    (= (type value) :table)
    (let []
      (var valid true)
      (each [_ rule (ipairs value)]
        (when (not (valid-rule? rule))
          (set valid false)))
      valid)
    false))

(defn- rule-map-error
  [value prefix]
  (if
    (= (type value) :table)
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
  (or
   (= value true)
   (= value false)))

(defn- extensions?
  [value]
  (if
    (and (= (type value) :table) (> (length value) 0))
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
  (or
   failure
   (and lint (lint-config.lint-error lint))))

(defn- configuration-error
  [tbl]
  (let [width           (. tbl :indent-width) builtins        (. tbl :builtins) fallbacks       (. tbl :prefix-fallbacks) extensions      (. tbl :extensions) skip-dotfiles   (. tbl :skip-dotfiles) follow-symlinks (. tbl :follow-symlinks) align-bindings  (. tbl :align-bindings) parser          (. tbl :parser) lint            (. tbl :lint)]
    (var failure nil)
    (when (and
           (= failure nil)
           (not= width nil)
           (not (and (integer? width) (> width 0))))
      (set failure {:message "indent-width must be a positive integer"}))
    (when (and
           (= failure nil)
           (not= builtins nil)
           (not (= builtins true))
           (not (= builtins false))
           (not= (type builtins) :table))
      (set failure {:message "builtins must be true, false, or a table of rules"}))
    (when (and (= failure nil) (= (type builtins) :table))
      (set failure (rule-map-error builtins "builtins rule ")))
    (when (and
           (= failure nil)
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
    (when (and (= failure nil) (not= align-bindings nil) (not (boolean? align-bindings)))
      (set failure {:message "align-bindings must be a boolean"}))
    (when (and (= failure nil) (not= parser nil) (not= (type parser) :string))
      (set failure {:message "parser must be a string"}))
    (configuration-error-with-lint failure lint)))

(defn validate
  [tbl]
  (if
    (not= (type tbl) :table)
    (values nil {:message "configuration must be a table"})
    (let [allowed {:indents          true :format-as        true :indent-patterns  true :paths            true :exclude          true :indent-width     true :builtins         true :prefix-fallbacks true :extensions       true :skip-dotfiles    true :follow-symlinks  true :align-bindings   true :parser           true :lint             true}]
      (var failure nil)
      (each [key _ (pairs tbl)]
        (when (not (. allowed key))
          (set failure {:message (.. "unknown configuration key: " key)})))
      (if
        failure
        (values nil failure)
        (let [new-error (configuration-error tbl)]
          (if
            new-error
            (values nil new-error)
            (if
              (and (. tbl :paths) (not (array-of-strings? (. tbl :paths))))
              (values nil {:message "paths must be an array of strings"})
              (if
                (and (. tbl :exclude) (not (array-of-strings? (. tbl :exclude))))
                (values nil {:message "exclude must be an array of strings"})
                tbl))))))))

(defn- valid-lint-policy
  [cfg]
  (let [lint           (. cfg :lint) overrides      (or (and lint (. lint :rules)) {}) exclusions     (or (and lint (. lint :exclusions)) []) max-code-lines (or (and lint (. lint :max-code-lines)) 300)]
    {:rules          (core.merge (lint-rules.defaults) overrides) :exclusions     exclusions :max-code-lines max-code-lines}))

(defn lint-policy
  [cfg]
  (let [(valid error) (validate cfg)]
    (if
      error
      (values nil error)
      (valid-lint-policy valid))))

(defn- join-path
  [dir name]
  (if
    (= (string.sub dir -1) "/")
    (.. dir name)
    (.. dir "/" name)))

(defn- close-file
  [file]
  (file:close)
  true)

(defn- exists?
  [path]
  (let [uv (or (and vim vim.loop) (and vim vim.uv))]
    (if
      uv
      (not= nil (uv.fs_stat path))
      (let [file (io.open path :r)]
        (if
          file
          (close-file file)
          false)))))

(defn- git-marker?
  [dir]
  (or (exists? (join-path dir ".git"))
      (exists? (join-path (join-path dir ".git") "HEAD"))))

(defn- parent-dir
  [dir]
  (let [trimmed (if
                  (and (> (string.len dir) 1) (= (string.sub dir -1) "/"))
                  (string.sub dir 1 -2)
                  dir)
        parent  (string.match trimmed "^(.*)/[^/]+$")]
    (when parent
      (if (= parent "") "/" parent))))

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
      (if
        (exists? candidate)
        (let [(new-result new-searching) (found-config candidate)]
          (set result new-result)
          (set searching new-searching))
        (if
          (git-marker? dir)
          (set searching false)
          (let [parent (parent-dir dir)]
            (if
              parent
              (set dir parent)
              (set searching false)))))))
  result)

(defn load
  [path]
  (let [file (io.open path :r)]
    (if
      (not file)
      (values nil {:message (.. "could not read config file: " path)})
      (let [text (file:read "*a")]
        (file:close)
        (let [(ok parsed-or-error) (pcall (fn [] (parse-string text)))]
          (if
            (not ok)
            (values nil parsed-or-error)
            (validate parsed-or-error)))))))
