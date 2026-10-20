(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.rules)

(local built-in-rules
       {:fn         [[:inner 0]] :lambda     [[:inner 0]] :macro      [[:inner 0]] :let        [[:block 1]] :when       [[:block 1]] :when-let   [[:block 1]] :if-let     [[:block 1]] :each       [[:block 1]] :for        [[:block 1]] :icollect   [[:block 1]] :collect    [[:block 1]] :accumulate [[:block 1]] :case       [[:block 1]] :match      [[:block 1]] :case-try   [[:block 1]] :match-try  [[:block 1]] :while      [[:block 1]] :with-open  [[:block 1]] :do         [[:block 0]]})

(local prefix-rules {:def [[:inner 0]] :with- [[:block 1]]})
(local
 allowed-keys
 {:indents          true :format-as        true :indent-patterns  true :indent-width     true :builtins         true :prefix-fallbacks true :align-bindings   true})
(var resolve-name nil)
(var alias-rule nil)

(defn- error
  [message]
  {:message message})

(defn- integer?
  [value]
  (and
   (= (type value) :number)
   (= value (math.floor value))))

(defn- validate-rule
  [rule]
  (if
    (and (= (type rule) :table) (= (type (. rule 1)) :string))
    (let [kind (. rule 1) value (. rule 2) index (. rule 3)]
      (if
        (= kind :block)
        (if (and (integer? value) (>= value 0) (= index nil)) nil (error "invalid block rule"))
        (if
          (= kind :inner)
          (if
            (and (= value 0) (or (= index nil) (and (integer? index) (>= index 0))))
            nil
            (error "invalid inner rule"))
          (error "unknown indentation rule"))))
    (error "invalid indentation rule")))

(defn- validate-rule-items
  [value]
  (var failure nil)
  (each [_ rule (ipairs value)]
    (when
      (= failure nil)
      (set failure (validate-rule rule))))
  failure)
(defn- validate-rule-list
  [value]
  (if
    (= (type value) :table)
    (validate-rule-items value)
    (error "indentation rules must be a list")))

(defn- validate-map-items
  [items rules?]
  (var failure nil)
  (each [name value (pairs items)]
    (when (= failure nil)
      (if
        (not= (type name) :string)
        (set failure (error "indentation names must be strings"))
        (if
          rules?
          (set failure (validate-rule-list value))
          (when (not= (type value) :string)
            (set failure (error "format-as targets must be strings")))))))
  failure)
(defn- validate-map
  [items rules?]
  (if
    (= items nil)
    nil
    (if
      (= (type items) :table)
      (validate-map-items items rules?)
      (error "indentation configuration must be a table"))))

(defn- validate-pattern-items
  [patterns]
  (var failure nil)
  (each [_ entry (ipairs patterns)]
    (when (= failure nil)
      (if
        (and (= (type entry) :table) (= (type (. entry 1)) :string))
        (let [(ok _) (pcall string.match "" (. entry 1))]
          (if
            (not ok)
            (set failure (error "invalid indentation pattern"))
            (set failure (validate-rule-list (. entry 2)))))
        (set failure (error "invalid indentation pattern")))))
  failure)
(defn- validate-patterns
  [patterns]
  (if
    (= patterns nil)
    nil
    (if
      (= (type patterns) :table)
      (validate-pattern-items patterns)
      (error "indentation patterns must be a list"))))

(defn- effective-builtins
  [config]
  (let [setting (. config :builtins)]
    (if
      (= setting nil)
      built-in-rules
      (if
        (= setting true)
        built-in-rules
        (if (= setting false) {} setting)))))

(defn- effective-prefix-rules
  [config]
  (let [setting (. config :prefix-fallbacks)]
    (if
      (= setting nil)
      prefix-rules
      (if (= setting false) {} setting))))

(defn- found-rule
  [rule]
  (values rule true))

(defn- resolve-pattern
  [patterns name]
  (var result nil)
  (var found false)
  (each [_ entry (ipairs patterns)]
    (when (and (not found) (string.match name (. entry 1)))
      (let [(new-result new-found) (found-rule (. entry 2))]
        (set result new-result)
        (set found new-found))))
  (values result found))

(defn- resolve-prefix
  [prefixes name]
  (var result nil)
  (var found false)
  (each [prefix rule (pairs prefixes)]
    (when (and (not found)
               (or (= (string.sub name 1 (string.len prefix)) prefix)
                   (and (= (string.sub prefix -1) "-")
                        (= name (string.sub prefix 1 -2)))))
      (let [(new-result new-found) (found-rule rule)]
        (set result new-result)
        (set found new-found))))
  (values result found))
(set resolve-name
     (fn [config name seen]
       (let
         [indents  (or (. config :indents) {}) aliases  (or (. config :format-as) {}) patterns (or (. config :indent-patterns) {}) builtins (effective-builtins config) prefixes (effective-prefix-rules config)]
         (if
           (. indents name)
           (values (. indents name) nil true)
           (if
             (. aliases name)
             (alias-rule config name seen)
             (let [(result found) (resolve-pattern patterns name)]
               (if
                 found
                 (values result nil true)
                 (if
                   (. builtins name)
                   (values (. builtins name) nil true)
                   (if
                     (= (string.find name "." 1 true) nil)
                     (let [(result found) (resolve-prefix prefixes name)]
                       (if
                         found
                         (values result nil true)
                         (values nil nil false)))
                     (values nil nil false))))))))))

(set alias-rule
     (fn [config name seen]
       (if
         (. seen name)
         (values nil (error "format-as alias cycle"))
         (let [target (. (. config :format-as) name)]
           (tset seen name true)
           (let [(rule err found) (resolve-name config target seen)]
             (tset seen name nil)
             (if
               err
               (values nil err)
               (if
                 found
                 (values rule nil true)
                 (values nil (error "format-as target has no indentation rule")))))))))

(defn- validate-custom-map
  [items prefix]
  (if
    (= (type items) :table)
    (let []
      (var failure nil)
      (each [name value (pairs items)]
        (when (= failure nil)
          (if
            (not= (type name) :string)
            (set failure (error "indentation names must be strings"))
            (when (not= (validate-rule-list value) nil)
              (set failure (error (.. prefix name ": invalid indentation rule")))))))
      failure)
    (error (.. prefix " must be a table of rules"))))

(defn- validate-custom-config
  [config]
  (let [builtins (. config :builtins) fallbacks (. config :prefix-fallbacks)]
    (if
      (and
       (not= builtins nil)
       (not (= builtins true))
       (not (= builtins false))
       (not= (type builtins) :table))
      (error "builtins must be true, false, or a table of rules")
      (if
        (and (= (type builtins) :table) (validate-custom-map builtins "builtins rule "))
        (validate-custom-map builtins "builtins rule ")
        (if
          (and
           (not= fallbacks nil)
           (not (= fallbacks false))
           (not= (type fallbacks) :table))
          (error "prefix-fallbacks must be false or a table of rules")
          (when (and (= (type fallbacks) :table)
                     (validate-custom-map fallbacks "prefix-fallbacks rule "))
            (validate-custom-map fallbacks "prefix-fallbacks rule ")))))))

(defn- validate-align-bindings
  [config]
  (let [align-bindings (. config :align-bindings)]
    (when (and (not= align-bindings nil) (not= (type align-bindings) :boolean))
      (error "align-bindings must be a boolean"))))

(defn- validate-config-table
  [config]
  (var failure nil)
  (each [key _ (pairs config)]
    (when (and (= failure nil) (not (. allowed-keys key)))
      (set failure (error "unknown indentation configuration key"))))
  (when
    (= failure nil)
    (set failure (validate-map (. config :indents) true)))
  (when
    (= failure nil)
    (set failure (validate-map (. config :format-as) false)))
  (when
    (= failure nil)
    (set failure (validate-patterns (. config :indent-patterns))))
  (when (= failure nil)
    (let [width (. config :indent-width)]
      (when (and (not= width nil) (not (and (integer? width) (> width 0))))
        (set failure (error "indent-width must be a positive integer")))))
  (when
    (= failure nil)
    (set failure (validate-align-bindings config)))
  (when
    (= failure nil)
    (set failure (validate-custom-config config)))
  (when (= failure nil)
    (each [name _ (pairs (or (. config :format-as) {}))]
      (when (= failure nil)
        (let [(_ err) (resolve-name config name {})]
          (when
            err
            (set failure err))))))
  (when (= failure nil)
    (each [name _ (pairs (or config.indents {}))]
      (when (and (= failure nil) (. (or (. config :format-as) {}) name))
        (set failure (error "name has both indent and format-as rule")))))
  failure)
(defn validate
  [config]
  (if
    (= config nil)
    nil
    (if
      (= (type config) :table)
      (validate-config-table config)
      (error "indentation configuration must be a table"))))

(defn resolve
  [config name]
  (let [(rule _ found) (resolve-name (or config {}) name {})]
    (when
      found
      rule)))
