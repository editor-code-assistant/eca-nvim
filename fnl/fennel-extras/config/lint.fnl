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
      (when (and value.modules
                 (not (or (= (type value.modules) :string)
                          (canonical-sequence-of-strings? value.modules))))
        {:message (.. path ".modules must be a string or list of strings")})))



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



(defn- canonical-legacy-selector-error
  [instance path]
  (let [options instance.options]
    (when (and (= (type options) :table)
               (or (not= options.forms nil)
                   (not= options.module nil)
                   (not= options.modules nil)))
      {:message (.. path ": forms, module, and modules must be under applies-to")})))



(defn- canonical-singleton-module-error
  [name instance path]
  (let [modules  (and (= (type instance.applies-to) :table)
                      instance.applies-to.modules)
        singular (or (= name "forbidden-form")
                     (= name "module-style")
                     (and (= name "module-import")
                          (= (type instance.options) :table)
                          (= instance.options.mode "require")))]
    (when (and singular
               (sequence? modules)
               (> (length modules) 1))
      {:message (.. path ".modules must contain at most one module")})))



(defn- canonical-missing-option-step
  [section name index option-values names option-index]
  (if (> option-index (length names))
    nil
    (let [option-name (. names option-index)]
      (or (and (= (. option-values option-name) nil)
               {:message (.. "missing " section ".rules." name "[" index "].options." option-name)})
          (canonical-missing-option-step section name index option-values names (+ option-index 1))))))



(defn- canonical-missing-applies-step
  [section name index applies options names option-index]
  (if (> option-index (length names))
    nil
    (let [option-name (. names option-index)
          key         (if (= option-name "module") :modules (if (= option-name "modules") :modules :forms))]
      (or (and (= (. applies key) nil)
               {:message (.. "missing " section ".rules." name "[" index "].applies-to." (tostring key))})
          (canonical-missing-applies-step section name index applies options names (+ option-index 1))))))



(defn- canonical-missing-option-error
  [section name index instance]
  (when (not= instance.severity "off")
    (if (= name "module-import")
      (or (canonical-missing-option-step section name index instance.options ["mode"] 1)
          (if (= instance.options.mode "require")
            (if instance.applies-to.forms
              (canonical-missing-applies-step section name index instance.applies-to instance.options ["module"] 1)
              (or (canonical-missing-applies-step section name index instance.applies-to instance.options ["module"] 1)
                  (canonical-missing-option-step section name index instance.options ["binding"] 1)))
            (canonical-missing-applies-step section name index instance.applies-to instance.options ["modules"] 1)))
      (or (canonical-missing-option-step section name index instance.options (registry.required-option-names name) 1)
          (let [names (if (= name "module-style") ["module"] (registry.applies-to-required-names name))]
            (and names
                 (canonical-missing-applies-step section name index instance.applies-to instance.options names 1)))))))



(defn- canonical-instance-error
  [section name index instance]
  (let [path (.. section ".rules." name "[" index "]")]
    (or (when (not= (type instance) :table)
          {:message (.. path " must be a table")})
        (canonical-map-keys-error instance path {:severity true :applies-to true :options true :exclusions true})
        (when (not (or (= instance.severity "error") (= instance.severity "warning") (= instance.severity "off")))
          {:message (.. path ".severity must be error, warning, or off")})
        (canonical-applies-to-error instance.applies-to (.. path ".applies-to"))
        (canonical-singleton-module-error name instance (.. path ".applies-to"))
        (when (not= (type instance.options) :table)
          {:message (.. path ".options must be a table")})
        (canonical-options-error name instance.options (.. path ".options"))
        (canonical-legacy-selector-error instance (.. path ".options"))
        (canonical-missing-option-error section name index instance)
        (canonical-exclusions-error instance.exclusions (.. path ".exclusions")))))



(defn- canonical-rule-error-step
  [rules key candidate]
  (if (or (= candidate nil)
          (< (tostring key) (tostring candidate)))
    key
    candidate))



(defn- canonical-rules-error
  [section rules]
  (or (when (not= (type rules) :table)
        {:message (.. section ".rules must be a table")})
      (let [name (accumulate [candidate nil key _ (pairs rules)]
                   (canonical-rule-error-step rules key candidate))]
        (when name
          (let [instances (. rules name)
                allowed   (if (= section "design")
                            (registry.design-rule-names)
                            (registry.lint-rule-names))]
            (if (not= (type name) :string)
              {:message (.. "unknown " section " rule: " (tostring name))}
              (if (not (accumulate [found false _ allowed-name (ipairs allowed)]
                         (or found (= allowed-name name))))
                {:message (.. "unknown " section " rule: " name)}
                (if (not (and (sequence? instances) (> (length instances) 0)))
                  {:message (.. section ".rules." name " must be a non-empty vector")}
                  (let []
                    (var failure nil)
                    (each [index instance (ipairs instances)]
                      (when (= failure nil)
                        (set failure (canonical-instance-error section name index instance))))
                    failure)))))))))



(defn- canonical-section-error
  [section value]
  (or (when (not= (type value) :table)
        {:message (.. section " must be a table")})
      (canonical-contract-key-error value {:rules true} (.. "unknown " section " key: "))
      (canonical-rules-error section value.rules)))



(defn lint-error
  [lint]
  (canonical-section-error "lint" lint))



(defn design-error
  [design]
  (canonical-section-error "design" design))
