(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.config.lint)

(local core (require :eca.nfnl.core))
(local lint-rules (require :fennel-extras.lint.rules))
(local parse (require :fennel-extras.config.parse))

(local sequence? parse.sequence?)

(defn- parsed-table?
  [value]
  (and (= (type value) :table)
       (let [metadata (getmetatable value)]
         (and metadata (. metadata :fennel-extras-table)))))

(defn- lint-rule-known?
  [rule]
  (. (lint-rules.defaults) rule))

(defn- lint-severity?
  [severity]
  (or (= severity "error") (= severity "warning") (= severity "off")))

(defn- lint-key-sort-value
  [key]
  (.. (type key) ":" (tostring key)))

(defn- first-unknown-lint-key
  [lint key candidate]
  (let [(next-key) (next lint key)]
    (if (= next-key nil)
      candidate
      (if (or (= next-key :rules)
              (= next-key :exclusions)
              (= next-key :max-code-lines))
        (first-unknown-lint-key lint next-key candidate)
        (if (or (= candidate nil)
                (< (lint-key-sort-value next-key) (lint-key-sort-value candidate)))
          (first-unknown-lint-key lint next-key next-key)
          (first-unknown-lint-key lint next-key candidate))))))

(defn- unknown-lint-key-error
  [key]
  (if key
    {:message (.. "unknown lint key: " (tostring key))}
    nil))

(defn- blank?
  [text]
  (= (string.match text "^%s*$") text))

(defn- first-lint-rule-error
  [rules key]
  (let [(next-key next-value) (next rules key)]
    (if (= next-key nil)
      nil
      (if (not (lint-rule-known? next-key))
        {:message (.. "unknown lint rule: " (tostring next-key))}
        (if (not (lint-severity? next-value))
          {:message (.. "lint rule " (tostring next-key) " must be error, warning, or off")}
          (first-lint-rule-error rules next-key))))))

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

(defn- lint-max-code-lines-error
  [max-code-lines]
  (when (and (not= max-code-lines nil)
             (not (and (= (type max-code-lines) :number)
                       (= max-code-lines (math.floor max-code-lines))
                       (> max-code-lines 0))))
    {:message "max-code-lines must be a positive integer"}))

(defn- lint-table-error
  [rules exclusions max-code-lines unknown-key]
  (or (unknown-lint-key-error unknown-key)
      (when (and rules
                 (or (not= (type rules) :table)
                     (and (sequence? rules)
                          (or (not= (getmetatable rules) nil)
                              (> (length rules) 0)))))
        {:message "lint rules must be a table"})
      (when rules (first-lint-rule-error rules nil))
      (lint-max-code-lines-error max-code-lines)
      (when (and exclusions (not (sequence? exclusions)))
        {:message "lint exclusions must be a list"})
      (when exclusions (first-exclusion-error exclusions 1))))

(defn lint-error
  [lint]
  (if (not= (type lint) :table)
    {:message "lint must be a table"}
    (let [rules          (. lint :rules)
          exclusions     (. lint :exclusions)
          max-code-lines (. lint :max-code-lines)
          unknown-key    (first-unknown-lint-key lint nil nil)]
      (lint-table-error rules exclusions max-code-lines unknown-key))))
