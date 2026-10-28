(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.config.format)

(local alignment (require :fennel-extras.indent.settings))

(defn- integer?
  [value]
  (and (= (type value) :number)
       (= value (math.floor value))))



(defn- every-ipairs?
  [predicate value index]
  (let [item (. value index)]
    (if (= item nil)
      true
      (and (predicate item)
           (every-ipairs? predicate value (+ index 1))))))



(defn- string?
  [value]
  (= (type value) :string))



(defn- dotted-string?
  [value]
  (= (string.sub value 1 1) "."))



(defn- array-of-strings?
  [value]
  (and (= (type value) :table)
       (> (length value) 0)
       (every-ipairs? string? value 1)))



(defn- boolean?
  [value]
  (or (= value true)
      (= value false)))



(defn- extensions?
  [value]
  (and (array-of-strings? value)
       (every-ipairs? dotted-string? value 1)))



(defn- block-rule?
  [value]
  (and (= (. value 1) :block)
       (integer? (. value 2))
       (>= (. value 2) 0)
       (= (. value 3) nil)))



(defn- inner-rule?
  [value]
  (and (= (. value 1) :inner)
       (= (. value 2) 0)
       (or (= (. value 3) nil)
           (and (integer? (. value 3)) (>= (. value 3) 0)))))



(defn- rule?
  [value]
  (and (= (type value) :table)
       (= (type (. value 1)) :string)
       (or (block-rule? value)
           (inner-rule? value))))



(defn- rule-list?
  [value]
  (and (= (type value) :table)
       (every-ipairs? rule? value 1)))



(defn- rule-map-entries?
  [value key]
  (let [(next-key next-value) (next value key)]
    (if (= next-key nil)
      true
      (and (= (type next-key) :string)
           (rule-list? next-value)
           (rule-map-entries? value next-key)))))



(defn- rule-map?
  [value]
  (and (= (type value) :table)
       (rule-map-entries? value nil)))



(defn- missing
  [path]
  {:message (.. "missing " path)})



(defn- required
  [config key path]
  (when (= (. config key) nil)
    (missing path)))



(defn- validate-builtins
  [config]
  (let [value (. config :builtins)]
    (when (and (not= value nil)
               (not= value false)
               (not (rule-map? value)))
      {:message "builtins must be a map or false"})))



(defn- validate-prefix-fallbacks
  [config]
  (let [value (. config :prefix-fallbacks)]
    (when (and (not= value nil)
               (not= value false)
               (not (rule-map? value)))
      {:message "prefix-fallbacks must be a map or false"})))



(defn- invalid-width?
  [width strict?]
  (and (or strict? (not= width nil))
       (not (and (integer? width) (> width 0)))))



(defn- invalid-extensions?
  [config require-scan?]
  (and (or require-scan? (not= (. config :extensions) nil))
       (not (extensions? (. config :extensions)))))



(defn- invalid-parser?
  [parser strict?]
  (and (or strict? (not= parser nil))
       (not= parser false)
       (not= (type parser) :string)))



(defn- invalid-boolean?
  [value]
  (and (not= value nil)
       (not (boolean? value))))



(defn- validate-values
  [config require-scan? strict?]
  (let [width           (. config :indent-width)
        parser          (. config :parser)
        skip-dotfiles   (. config :skip-dotfiles)
        follow-symlinks (. config :follow-symlinks)]
    (or (and (invalid-width? width strict?)
             {:message "indent-width must be a positive integer"})
        (and (invalid-extensions? config require-scan?)
             {:message "extensions must be a non-empty list of strings starting with \".\""})
        (and (invalid-parser? parser strict?)
             {:message "parser must be a string or false"})
        (and (invalid-boolean? skip-dotfiles)
             {:message "skip-dotfiles must be a boolean"})
        (and (invalid-boolean? follow-symlinks)
             {:message "follow-symlinks must be a boolean"}))))



(defn- missing-binding-forms
  [value]
  (when (and (or (. value :bindings) (. value :split-bindings))
             (= (. value :binding-forms) nil))
    (missing "alignment.binding-forms")))



(defn- missing-clause-forms
  [value]
  (when (and (. value :clauses)
             (= (. value :clause-forms) nil))
    (missing "alignment.clause-forms")))



(defn- validate-alignment
  [config]
  (let [value (. config :alignment)]
    (or (alignment.validate value)
        (and value
             (or (missing-binding-forms value)
                 (missing-clause-forms value))))))



(defn- newline-instance?
  [value]
  (and (= (type value) :table)
       (= (type (. value :applies-to)) :table)
       (or (= (. value :applies-to :forms) nil)
           (array-of-strings? (. value :applies-to :forms)))
       (= (type (. value :options)) :table)
       (or (= (. value :options :after) nil)
           (and (integer? (. value :options :after)) (>= (. value :options :after) 0)))
       (or (= (. value :options :before) nil)
           (and (integer? (. value :options :before)) (>= (. value :options :before) 0)))))



(defn- validate-newline
  [config]
  (let [value (. config :newline)]
    (when (and (not= value nil)
               (not (and (= (type value) :table)
                         (every-ipairs? newline-instance? value 1))))
      {:message "newline must be a list of instances"})))



(defn- validate-extensions
  [config]
  (or (and (= (. config :extensions) nil)
           (missing "extensions"))
      (and (not= (. config :extensions) nil)
           (not (extensions? (. config :extensions)))
           {:message "extensions must be a non-empty list of strings starting with \".\""})))



(defn- validate-paths
  [config require-paths?]
  (or (and require-paths?
           (= (. config :paths) nil)
           (missing "paths"))
      (and (. config :paths)
           (not (array-of-strings? (. config :paths)))
           {:message "paths must be an array of strings"})))



(defn validate-scan
  [config require-paths?]
  (or (validate-extensions config)
      (validate-paths config require-paths?)))



(defn- validate-table
  [config require-paths? require-scan? strict?]
  (or (and strict? (required config :indent-width "indent-width"))
      (and strict? (required config :builtins "builtins"))
      (and strict? (required config :prefix-fallbacks "prefix-fallbacks"))
      (and strict? (required config :parser "parser"))
      (and require-scan? (required config :extensions "extensions"))
      (and require-paths? (required config :paths "paths"))
      (validate-builtins config)
      (validate-prefix-fallbacks config)
      (validate-values config require-scan? strict?)
      (validate-alignment config)
      (validate-newline config)))



(defn validate
  [config require-paths? require-scan? strict?]
  (if (= (type config) :table)
    (validate-table config require-paths? require-scan? strict?)
    {:message "configuration must be a table"}))
