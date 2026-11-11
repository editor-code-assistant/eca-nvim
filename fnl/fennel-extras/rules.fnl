(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.rules)

(local alignment (require :fennel-extras.indent.settings))

(local allowed-keys
       {:indents true :format-as true :indent-width true :alignment true})
(var resolve-name nil)
(var alias-rule nil)

(defn- capture-values
  [f]
  (let [(a b c) (f)] [a b c]))

(defn- error
  [message]
  {:message message})

(defn- integer?
  [value]
  (and (= (type value) :number)
       (= value (math.floor value))))

(defn- validate-rule
  [rule]
  (if (and (= (type rule) :table) (= (type (. rule 1)) :string))
    (do (local kind (. rule 1))
          (local value (. rule 2))
          (local index (. rule 3))
      (if (= kind :block)
        (when (not (and (integer? value) (>= value 0) (= index nil)))
              (error "invalid block rule"))
        (if (= kind :inner)
          (when (not (and (= value 0) (or (= index nil) (and (integer? index) (>= index 0)))))
                (error "invalid inner rule"))
          (error "unknown indentation rule"))))
    (error "invalid indentation rule")))

(defn- validate-rule-items
  [value]
  (var failure nil)
  (each [_ rule (ipairs value)]
        (when (= failure nil)
              (set failure (validate-rule rule))))
  failure)

(defn- validate-rule-list
  [value]
  (if (= (type value) :table)
    (validate-rule-items value)
    (error "indentation rules must be a list")))

(defn- validate-map-items
  [items rules?]
  (var failure nil)
  (each [name value (pairs items)]
        (when (= failure nil)
              (if (not= (type name) :string)
                (set failure (error "indentation names must be strings"))
                (if rules?
                  (set failure (validate-rule-list value))
                  (when (not= (type value) :string)
                        (set failure (error "format-as targets must be strings")))))))
  failure)

(defn- validate-map
  [items rules?]
  (when items
        (if (= (type items) :table)
          (validate-map-items items rules?)
          (error "indentation configuration must be a table"))))

(set resolve-name
     (fn
       [config name seen]

       (local indents (or (. config :indents) {}))
       (local aliases (or (. config :format-as) {}))
       (if (. indents name)
         (values (. indents name) nil true)
         (if (. aliases name)
           (alias-rule config name seen)
           (values nil nil false)))))

(set alias-rule
     (fn
       [config name seen]

       (if (. seen name)
         (values nil (error "format-as alias cycle"))
                  (do (local target (. (. config :format-as) name))
                    (tset seen name true)
                    (local captured-values (capture-values (fn [] (resolve-name config target seen))))
                    (local rule (. captured-values 1))
                    (local err (. captured-values 2))
                    (local found (. captured-values 3))
                    (tset seen name nil)
                    (if err
                      (values nil err)
                      (if found
                        (values rule nil true)
                        (values nil (error "format-as target has no indentation rule"))))))))

(defn- validate-alignment
  [config]
  (alignment.validate (. config :alignment)))

(defn- validate-config-table
  [config]
  (var failure nil)
  (each [key _ (pairs config)]
        (when (and (= failure nil) (not (. allowed-keys key)))
              (set failure (error "unknown indentation configuration key"))))
  (when (= failure nil)
        (set failure (validate-map (. config :indents) true)))
  (when (= failure nil)
        (set failure (validate-map (. config :format-as) false)))
  (when (= failure nil)
        (do (local width (. config :indent-width))
          (when (and (not= width nil) (not (and (integer? width) (> width 0))))
                (set failure (error "indent-width must be a positive integer")))))
  (when (= failure nil)
        (set failure (validate-alignment config)))
  (when (= failure nil)
        (each [name _ (pairs (or (. config :format-as) {}))]
              (when (= failure nil)
                    (do (local captured-values (capture-values (fn [] (resolve-name config name {})))) (local _ (. captured-values 1)) (local err (. captured-values 2))
                      (when err
                            (set failure err))))))
  (when (= failure nil)
        (each [name _ (pairs (or config.indents {}))]
              (when (and (= failure nil) (. (or (. config :format-as) {}) name))
                    (set failure (error "name has both indent and format-as rule")))))
  failure)

(defn validate
  [config]
  (when config
        (if (= (type config) :table)
          (validate-config-table config)
          (error "indentation configuration must be a table"))))

(defn resolve
  [config name]
  (let [(rule _ found) (resolve-name (or config {}) name {})]
    (when found
          rule)))
