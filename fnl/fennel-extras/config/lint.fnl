(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.config.lint)

(local core (require :eca.nfnl.core))
(local lint-rules (require :fennel-extras.lint.rules))
(local registry (require :fennel-extras.lint.rules.registry))
(local options (require :fennel-extras.lint.rules.options))
(local parse (require :fennel-extras.config.parse))
(local exclusion (require :fennel-extras.config.exclusion))

(local sequence? parse.sequence?)

(defn- parsed-table?
  [value]
  (and (= (type value) :table)
       (let [metadata (getmetatable value)]
         (and metadata
              (. metadata :fennel-extras-table)))))

(defn- lint-rule-known?
  [rule]
  (. (lint-rules.defaults) rule))

(defn- lint-severity?
  [severity]
  (or (= severity "error")
      (= severity "warning")
      (= severity "off")))

(defn- positive-integer?
  [value]
  (and (= (type value) :number)
       (= value (math.floor value))
       (> value 0)))

(defn- option-known?
  [rule option]
  (. (registry.option-schema rule) option))

(defn- option-value-error
  [rule option value]
  (let [error (options.validate rule {option value})]
    (and error
         (not error.unknown)
         error)))

(defn- unknown-option-error
  [rule option]
  {:message (.. "unknown option " (tostring option) " for lint rule " rule)})

(defn- first-option-error-step
  [rule options next-key next-value recurse]
  (if (not (option-known? rule next-key))
    (unknown-option-error rule next-key)
    (or (option-value-error rule next-key next-value)
        (recurse rule options next-key))))

(defn- first-option-error
  [rule options key]
  (let [(next-key next-value) (next options key)]
    (if (= next-key nil)
      nil
      (first-option-error-step rule options next-key next-value first-option-error))))

(defn- first-rule-map-key-step
  [rule key next-key recurse]
  (if (or (= next-key :severity) (= next-key :options) (= next-key :exclusions))
    (recurse rule next-key)
    next-key))

(defn- first-rule-map-key
  [rule key]
  (let [(next-key) (next rule key)]
    (if (= next-key nil)
      nil
      (first-rule-map-key-step rule key next-key first-rule-map-key))))

(defn- lint-rule-severity-error
  [name severity options unknown]
  (if (and (= severity nil) (= options nil) (= unknown nil))
    {:message (.. "lint rule " name " must be error, warning, or off")}
    {:message (.. "lint rule " name " severity must be error, warning, or off")}))

(defn- lint-rule-unknown-key-error
  [name unknown]
  (when unknown
    {:message (.. "lint rule " name ": unknown key " (tostring unknown))}))

(defn- lint-rule-options-type-error
  [name options]
  (when (and options (not= (type options) :table))
    {:message (.. "options for lint rule " name " must be a table")}))

(defn- lint-rule-options-error
  [name options]
  (and options (first-option-error name options nil)))

(defn- lint-rule-severity-option-error
  [name severity options unknown]
  (when (not (lint-severity? severity))
    (lint-rule-severity-error name severity options unknown)))

(defn- per-rule-selector?
  [exclusions index]
  (if (> index (length exclusions))
    false
    (or (. (. exclusions index) :rule)
        (. (. exclusions index) :rules)
        (per-rule-selector? exclusions (+ index 1)))))

(defn- per-rule-exclusions-error
  [name exclusions]
  (when exclusions
    (let [error (exclusion.validate (lint-rules.defaults) exclusions)]
      (or error
          (when (per-rule-selector? exclusions 1)
            {:message (.. "lint rule " name " exclusions cannot select a rule")})))))

(defn- missing-option-step
  [name option-values names index]
  (if (> index (length names))
    nil
    (or (and (= (. option-values (. names index)) nil)
             {:message (.. "missing lint.rules." name ".options." (. names index))})
        (missing-option-step name option-values names (+ index 1)))))

(defn- missing-rule-options-error
  [name severity option-values]
  (when (and (not= severity "off") (= option-values nil))
    {:message (.. "missing lint.rules." name ".options." (or (. (options.names name) 1) "applies-to"))}))

(defn- lint-rule-table-error
  [name entry]
  (let [severity     (. entry :severity)
        rule-options (. entry :options)
        exclusions   (. entry :exclusions)
        unknown      (first-rule-map-key entry nil)]
    (or (lint-rule-unknown-key-error name unknown)
        (lint-rule-severity-option-error name severity rule-options unknown)
        (lint-rule-options-type-error name rule-options)
        (lint-rule-options-error name rule-options)
        (missing-rule-options-error name severity rule-options)
        (and (not= severity "off") rule-options (missing-option-step name rule-options (options.names name) 1))
        (per-rule-exclusions-error name exclusions))))

(defn- lint-rule-missing-options-error
  [name]
  {:message (.. "missing lint.rules." name ".options.applies-to")})

(defn- lint-rule-invalid-entry-options-error
  [name entry]
  (if (= entry "off")
    nil
    (lint-rule-missing-options-error name)))

(defn- lint-rule-invalid-entry-error
  [name entry]
  (if (not (lint-severity? entry))
    {:message (.. "lint rule " name " must be error, warning, or off")}
    (lint-rule-invalid-entry-options-error name entry)))

(defn- lint-rule-entry-error
  [name entry]
  (if (= (type entry) :table)
    (lint-rule-table-error name entry)
    (lint-rule-invalid-entry-error name entry)))

(defn- lint-key-sort-value
  [key]
  (.. (type key) ":" (tostring key)))

(defn- next-unknown-candidate
  [next-key candidate]
  (if (or (= candidate nil)
          (< (lint-key-sort-value next-key) (lint-key-sort-value candidate)))
    next-key
    candidate))

(defn- first-unknown-lint-key-step
  [lint next-key candidate recurse]
  (if (or (= next-key :rules)
          (= next-key :exclusions)
          (= next-key :spec-files))
    (recurse lint next-key candidate)
    (recurse lint next-key (next-unknown-candidate next-key candidate))))

(defn- first-unknown-lint-key
  [lint key candidate]
  (let [(next-key) (next lint key)]
    (if (= next-key nil)
      candidate
      (first-unknown-lint-key-step lint next-key candidate first-unknown-lint-key))))

(defn- unknown-lint-key-error
  [key]
  (when key
    {:message (.. "unknown lint key: " (tostring key))}))

(defn- blank?
  [text]
  (= (string.match text "^%s*$") text))

(defn- first-lint-rule-error-step
  [rules next-key next-value recurse]
  (if (not (lint-rule-known? next-key))
    {:message (.. "unknown lint rule: " (tostring next-key))}
    (or (lint-rule-entry-error next-key next-value)
        (recurse rules next-key))))

(defn- first-lint-rule-error
  [rules key]
  (let [(next-key next-value) (next rules key)]
    (if (= next-key nil)
      nil
      (first-lint-rule-error-step rules next-key next-value first-lint-rule-error))))

(defn- next-exclusion-key-error
  [exclusion index key next-error]
  (next-error exclusion index (next exclusion key)))

(defn- exclusion-keys-error
  [exclusion index key]
  (if (= key nil)
    nil
    (if (or (= key :rule) (= key :form) (= key :reason))
      (next-exclusion-key-error exclusion index key exclusion-keys-error)
      {:message (.. "lint exclusion " index ": unknown key " (tostring key))})))

(defn- duplicate-exclusion-index-entry
  [exclusions index rule form candidate entry next-index]
  (if (and (= (. entry :rule) rule) (= (. entry :form) form))
    index
    (next-index exclusions (+ index 1) rule form candidate)))

(defn- duplicate-exclusion-index
  [exclusions index rule form candidate]
  (if (>= index candidate)
    nil
    (duplicate-exclusion-index-entry exclusions index rule form candidate (. exclusions index) duplicate-exclusion-index)))

(defn- exclusion-duplicate-error
  [exclusions index duplicate next-error]
  (if duplicate
    {:message (.. "lint exclusion " index ": duplicate of exclusion " duplicate)}
    (next-error exclusions (+ index 1))))

(defn- exclusion-rule-known-error
  [exclusions index rule form reason duplicate next-error]
  (if (not (lint-rule-known? rule))
    {:message (.. "lint exclusion " index ": unknown rule " rule)}
    (exclusion-duplicate-error exclusions index duplicate next-error)))

(defn- exclusion-reason-error
  [exclusions index rule form reason duplicate next-error]
  (if (blank? reason)
    {:message (.. "lint exclusion " index ": reason must not be blank")}
    (exclusion-rule-known-error exclusions index rule form reason duplicate next-error)))

(defn- exclusion-form-error
  [exclusions index rule form reason duplicate next-error]
  (if (not= (type reason) :string)
    {:message (.. "lint exclusion " index ": reason must be a string")}
    (exclusion-reason-error exclusions index rule form reason duplicate next-error)))

(defn- exclusion-rule-error
  [exclusions index rule form reason duplicate next-error]
  (if (not= (type form) :string)
    {:message (.. "lint exclusion " index ": form must be a string")}
    (exclusion-form-error exclusions index rule form reason duplicate next-error)))

(defn- first-exclusion-error-entry
  [exclusions index exclusion next-error]
  (let [(unknown-key) (next exclusion nil)
        rule          (. exclusion :rule)
        form          (. exclusion :form)
        reason        (. exclusion :reason)
        duplicate     (duplicate-exclusion-index exclusions 1 rule form index)]
    (or (exclusion-keys-error exclusion index unknown-key)
        (if (not= (type rule) :string)
          {:message (.. "lint exclusion " index ": rule must be a string")}
          (exclusion-rule-error exclusions index rule form reason duplicate next-error)))))

(defn- first-exclusion-error
  [exclusions index]
  (let [exclusion (. exclusions index)]
    (if (= exclusion nil)
      nil
      (if (not= (type exclusion) :table)
        {:message (.. "lint exclusion " index " must be a table")}
        (first-exclusion-error-entry exclusions index exclusion first-exclusion-error)))))

(defn- lint-table-error
  [rules exclusions spec-files unknown-key]
  (or (unknown-lint-key-error unknown-key)
      (when (and rules
                 (or (not= (type rules) :table)
                     (and (sequence? rules)
                          (or (not= (getmetatable rules) nil)
                              (> (length rules) 0)))))
        {:message "lint rules must be a table"})
      (when rules (first-lint-rule-error rules nil))
      (when (= spec-files nil)
        {:message "missing lint.spec-files"})
      (options.spec-files-error spec-files)
      (exclusion.validate (lint-rules.defaults) exclusions)))

(defn- append-exclusions
  [result rule entry]
  (when (and (= (type entry) :table) entry.exclusions)
    (each [_ value (ipairs entry.exclusions)]
      (let [copy {}]
        (each [key item (pairs value)]
          (tset copy key item))
        (table.insert result (core.assoc copy :rule rule)))))
  result)

(defn- collect-exclusions
  [rules result]
  (each [rule entry (pairs rules)]
    (append-exclusions result rule entry))
  result)

(defn exclusions
  [rules]
  (collect-exclusions rules []))

(defn- lint-error-table
  [lint]
  (let [rules       (. lint :rules)
        exclusions  (. lint :exclusions)
        spec-files  (. lint :spec-files)
        unknown-key (first-unknown-lint-key lint nil nil)]
    (lint-table-error rules exclusions spec-files unknown-key)))

(defn lint-error
  [lint]
  (if (not= (type lint) :table)
    {:message "lint must be a table"}
    (lint-error-table lint)))
