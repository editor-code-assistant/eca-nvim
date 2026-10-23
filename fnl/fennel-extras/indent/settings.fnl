(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.indent.settings)

(local core (require :eca.nfnl.core))
(local parse (require :fennel-extras.config.parse))

(local toggle-keys ["bindings" "maps" "clauses" "split-bindings" "collapse-padding"])
(local list-keys ["binding-forms" "clause-forms"])

(defn- boolean?
  [value]
  (or (= value true) (= value false)))

(defn- string-list-entry?
  [value index]
  (let [item (. value index)]
    (if (= item nil)
      true
      (and (= (type item) :string)
           (string-list-entry? value (+ index 1))))))

(defn- string-list?
  [value]
  (if (parse.sequence? value)
    (string-list-entry? value 1)
    false))

(defn- list-contains-entry?
  [items name index]
  (let [item (. items index)]
    (if (= item nil)
      false
      (or (= item name)
          (list-contains-entry? items name (+ index 1))))))

(defn- list-contains?
  [items name]
  (list-contains-entry? items name 1))

(defn- toggle-key?
  [key]
  (list-contains? toggle-keys key))

(defn- known-key?
  [key]
  (or (toggle-key? key) (list-contains? list-keys key)))

(defn- key-error
  [message key]
  {:message (.. "alignment key " key message)})

(defn- validate-toggle
  [key value]
  (when (not (boolean? value))
    (key-error " must be a boolean" key)))

(defn- validate-list
  [key value]
  (when (not (string-list? value))
    (key-error " must be a list of strings" key)))

(defn- validate-known-entry
  [key value]
  (if (toggle-key? key)
    (validate-toggle key value)
    (validate-list key value)))

(defn- validate-entry
  [key value]
  (if (not (known-key? key))
    {:message (.. "unknown alignment key: " key)}
    (validate-known-entry key value)))

(defn- validate-entries
  [value key]
  (let [(next-key item) (next value key)
        failure         (and next-key (validate-entry next-key item))]
    (if (= next-key nil)
      nil
      (or failure (validate-entries value next-key)))))

(defn- validate-table
  [value]
  (when (= (type value) :table)
    (validate-entries value nil)))

(defn validate
  [value]
  (if (and (not= value nil) (not= (type value) :table))
    {:message "alignment must be a table"}
    (validate-table value)))

(defn- toggle-value
  [alignment key]
  (= (. alignment key) true))

(defn resolve
  [config]
  (let [alignment (or (and config (. config :alignment)) {})]
    {:bindings         (toggle-value alignment "bindings")
     :maps             (toggle-value alignment "maps")
     :clauses          (toggle-value alignment "clauses")
     :split-bindings   (toggle-value alignment "split-bindings")
     :collapse-padding (toggle-value alignment "collapse-padding")
     :binding-forms    (. alignment "binding-forms")
     :clause-forms     (. alignment "clause-forms")}))

(defn- add-binding-forms
  [alignment explicit]
  (if (and explicit (. explicit "binding-forms"))
    (core.assoc alignment "binding-forms" (. explicit "binding-forms"))
    alignment))

(defn- add-clause-forms
  [alignment explicit]
  (if (and explicit (. explicit "clause-forms"))
    (core.assoc alignment "clause-forms" (. explicit "clause-forms"))
    alignment))

(defn normalize
  [config]
  (let [resolved           (resolve config)
        alignment          {:bindings         resolved.bindings
                            :maps             resolved.maps
                            :clauses          resolved.clauses
                            :split-bindings   resolved.split-bindings
                            :collapse-padding resolved.collapse-padding}
        explicit           (. config :alignment)
        with-binding-forms (add-binding-forms alignment explicit)
        normalized         (add-clause-forms with-binding-forms explicit)]
    (core.assoc config :alignment normalized)))

(defn binding-form?
  [alignment name]
  (list-contains? alignment.binding-forms name))

(defn clause-form?
  [alignment name]
  (list-contains? alignment.clause-forms name))
