(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.rules)

(local built-ins
       {:fn [[:inner 0]] :lambda [[:inner 0]] :macro [[:inner 0]]
        :let [[:block 1]] :when [[:block 1]] :when-let [[:block 1]] :if-let [[:block 1]]
        :each [[:block 1]] :for [[:block 1]] :icollect [[:block 1]] :collect [[:block 1]]
        :accumulate [[:block 1]] :case [[:block 1]] :match [[:block 1]] :while [[:block 1]]
        :with-open [[:block 1]] :do [[:block 0]]})

(local allowed-keys {:indents true :format-as true :indent-patterns true})
(var resolve-name nil)
(var alias-rule nil)

(defn- error [message]
  {:message message})

(defn- integer? [value]
  (and (= (type value) :number) (= value (math.floor value))))

(defn- validate-rule [rule]
  (if (and (= (type rule) :table) (= (type (. rule 1)) :string))
      (let [kind (. rule 1) value (. rule 2) index (. rule 3)]
        (if (= kind :block)
            (if (and (integer? value) (>= value 0) (= index nil)) nil (error "invalid block rule"))
            (if (= kind :inner)
                (if (and (= value 0) (or (= index nil) (and (integer? index) (>= index 0))))
                    nil
                    (error "invalid inner rule"))
                (error "unknown indentation rule"))))
      (error "invalid indentation rule")))

(defn- validate-rule-list [value]
  (if (= (type value) :table)
      (do
        (var failure nil)
        (each [_ rule (ipairs value)]
          (if (= failure nil) (set failure (validate-rule rule))))
        failure)
      (error "indentation rules must be a list")))

(defn- validate-map [items rules?]
  (if (= items nil)
      nil
      (if (= (type items) :table)
          (do
            (var failure nil)
            (each [name value (pairs items)]
              (if (= failure nil)
                  (if (not= (type name) :string)
                      (set failure (error "indentation names must be strings"))
                      (if rules?
                          (set failure (validate-rule-list value))
                          (if (not= (type value) :string)
                              (set failure (error "format-as targets must be strings")))))))
            failure)
          (error "indentation configuration must be a table"))))

(defn- validate-patterns [patterns]
  (if (= patterns nil)
      nil
      (if (= (type patterns) :table)
          (do
            (var failure nil)
            (each [_ entry (ipairs patterns)]
              (if (= failure nil)
                  (if (and (= (type entry) :table) (= (type (. entry 1)) :string))
                      (let [(ok _) (pcall string.match "" (. entry 1))]
                        (if (not ok)
                            (set failure (error "invalid indentation pattern"))
                            (set failure (validate-rule-list (. entry 2)))))
                      (set failure (error "invalid indentation pattern")))))
            failure)
          (error "indentation patterns must be a list"))))

(set resolve-name
     (fn [config name seen]
       (let [indents (or (. config :indents) {}) aliases (or (. config :format-as) {}) patterns (or (. config :indent-patterns) {})]
         (if (. indents name)
             (values (. indents name) nil true)
             (if (. aliases name)
                 (alias-rule config name seen)
                 (do
                   (var result nil)
                   (var found false)
                   (each [_ entry (ipairs patterns)]
                     (if (and (not found) (string.match name (. entry 1)))
                         (do (set result (. entry 2)) (set found true))))
                   (if found
                       (values result nil true)
                       (if (. built-ins name)
                           (values (. built-ins name) nil true)
                           (if (and (= (string.find name "." 1 true) nil) (string.match name "^def"))
                               (values [[:inner 0]] nil true)
                               (if (and (= (string.find name "." 1 true) nil) (string.match name "^with-"))
                                   (values [[:block 1]] nil true)
                                   (values nil nil false)))))))))))

(set alias-rule
     (fn [config name seen]
       (if (. seen name)
           (values nil (error "format-as alias cycle"))
           (let [target (. (. config :format-as) name)]
             (tset seen name true)
             (let [(rule err found) (resolve-name config target seen)]
               (tset seen name nil)
               (if err
                   (values nil err)
                   (if found
                       (values rule nil true)
                       (values nil (error "format-as target has no indentation rule")))))))))

(defn validate [config]
  (if (= config nil)
      nil
      (if (= (type config) :table)
          (do
            (var failure nil)
            (each [key _ (pairs config)]
              (if (and (= failure nil) (not (. allowed-keys key)))
                  (set failure (error "unknown indentation configuration key"))))
            (if (= failure nil) (set failure (validate-map (. config :indents) true)))
            (if (= failure nil) (set failure (validate-map (. config :format-as) false)))
            (if (= failure nil) (set failure (validate-patterns (. config :indent-patterns))))
            (if (= failure nil)
                (each [name _ (pairs (or (. config :format-as) {}))]
                  (if (= failure nil)
                      (let [(_ err) (resolve-name config name {})]
                        (if err (set failure err))))))
            (if (= failure nil)
                (each [name _ (pairs (or config.indents {}))]
                  (if (and (= failure nil) (. (or (. config :format-as) {}) name))
                      (set failure (error "name has both indent and format-as rule")))))
            failure)
          (error "indentation configuration must be a table"))))

(defn resolve [config name]
  (let [(rule _ found) (resolve-name (or config {}) name {})]
    (if found rule nil)))
