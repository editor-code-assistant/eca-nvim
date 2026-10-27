(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.config.lint)

(local registry (require :fennel-extras.lint.rules.registry))
(local options (require :fennel-extras.lint.rules.options))
(local parse (require :fennel-extras.config.parse))

(local sequence? parse.sequence?)

(defn- canonical-sequence-of-strings?
  [value]
  (and (sequence? value)
       (let []
         (var valid true)
         (each [_ item (ipairs value)]
           (when (not= (type item) :string)
             (set valid false)))
         valid)))

(defn- sorted-unknown-key
  [value allowed]
  (accumulate [candidate nil key _ (pairs value)]
    (if (and (not (. allowed key))
             (or (= candidate nil)
                 (< (tostring key) (tostring candidate))))
      key
      candidate)))

(defn- canonical-map-keys-error
  [value path allowed]
  (when (= (type value) :table)
    (let [key (sorted-unknown-key value allowed)]
      (when key
        {:message (.. path "." (tostring key) ": unknown key")}))))

(defn- canonical-contract-key-error
  [value allowed prefix]
  (when (= (type value) :table)
    (let [key (sorted-unknown-key value allowed)]
      (when key
        {:message (.. prefix (tostring key))}))))

(defn- canonical-applies-to-error
  [value path]
  (or (when (not= (type value) :table)
        {:message (.. path " must be a table")})
      (canonical-contract-key-error value {:files true :forms true :modules true} "unknown applies-to key: ")
      (when (and value.files (not (canonical-sequence-of-strings? value.files)))
        {:message (.. path ".files must be a list of strings")})
      (when (and value.forms (not (canonical-sequence-of-strings? value.forms)))
        {:message (.. path ".forms must be a list of strings")})
      (when (and value.modules (not (canonical-sequence-of-strings? value.modules)))
        {:message (.. path ".modules must be a list of strings")})))

(defn- canonical-exclusions-error
  [value path]
  (or (when (not (sequence? value))
        {:message (.. path " must be a list")})
      (let []
        (var failure nil)
        (each [index exclusion (ipairs value)]
          (when (= failure nil)
            (if (not= (type exclusion) :table)
              (set failure {:message (.. path "[" index "] must be a table")})
              (let [unknown (canonical-map-keys-error exclusion (.. path "[" index "]") {:path true :reason true})]
                (if unknown
                  (set failure unknown)
                  (when (or (not= (type exclusion.path) :string)
                            (not= (type exclusion.reason) :string))
                    (set failure {:message (.. path "[" index "] requires string path and reason")})))))))
        failure)))

(defn- canonical-options-error
  [name option-values path]
  (when (= (type option-values) :table)
    (let [error (options.validate name option-values)]
      (when error
        {:message (.. path ": " error.message)}))))

(defn- canonical-missing-option-step
  [name index option-values names option-index]
  (if (> option-index (length names))
    nil
    (let [option-name (. names option-index)]
      (or (and (= (. option-values option-name) nil)
               {:message (.. "missing lint.rules." name "[" index "].options." option-name)})
          (canonical-missing-option-step name index option-values names (+ option-index 1))))))

(defn- canonical-missing-option-error
  [name index instance]
  (when (not= instance.severity "off")
    (canonical-missing-option-step name index instance.options (registry.required-option-names name) 1)))

(defn- canonical-instance-error
  [name index instance]
  (let [path (.. "lint.rules." name "[" index "]")]
    (or (when (not= (type instance) :table)
          {:message (.. path " must be a table")})
        (canonical-map-keys-error instance path {:severity true :applies-to true :options true :exclusions true})
        (when (not (or (= instance.severity "error") (= instance.severity "warning") (= instance.severity "off")))
          {:message (.. path ".severity must be error, warning, or off")})
        (canonical-applies-to-error instance.applies-to (.. path ".applies-to"))
        (when (not= (type instance.options) :table)
          {:message (.. path ".options must be a table")})
        (canonical-options-error name instance.options (.. path ".options"))
        (canonical-missing-option-error name index instance)
        (canonical-exclusions-error instance.exclusions (.. path ".exclusions")))))

(defn- canonical-rule-error-step
  [rules key candidate]
  (if (or (= candidate nil)
          (< (tostring key) (tostring candidate)))
    key
    candidate))

(defn- canonical-rules-error
  [rules]
  (or (when (not= (type rules) :table)
        {:message "lint.rules must be a table"})
      (let [name (accumulate [candidate nil key _ (pairs rules)]
                   (canonical-rule-error-step rules key candidate))]
        (when name
          (let [instances (. rules name)]
            (if (not= (type name) :string)
              {:message (.. "lint.rules." (tostring name) ": rule key must be a keyword")}
              (if (= (. (registry.defaults) name) nil)
                {:message (.. "unknown lint rule: " name)}
                (if (not (and (sequence? instances) (> (length instances) 0)))
                  {:message (.. "lint.rules." name " must be a non-empty vector")}
                  (let []
                    (var failure nil)
                    (each [index instance (ipairs instances)]
                      (when (= failure nil)
                        (set failure (canonical-instance-error name index instance))))
                    failure)))))))))

(defn- canonical-lint-error
  [lint]
  (or (when (not= (type lint) :table)
        {:message "lint must be a table"})
      (canonical-contract-key-error lint {:rules true} "unknown lint key: ")
      (canonical-rules-error lint.rules)))

(defn lint-error
  [lint]
  (canonical-lint-error lint))
