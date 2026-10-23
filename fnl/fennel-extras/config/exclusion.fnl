(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.config.exclusion)

(local core (require :eca.nfnl.core))
(local parse (require :fennel-extras.config.parse))

(local sequence? parse.sequence?)

(defn- blank?
  [text]
  (= (string.match text "^%s*$") text))

(defn- positive-integer?
  [value]
  (and (= (type value) :number)
       (= value (math.floor value))
       (> value 0)))

(defn- known-rule?
  [rules rule]
  (. rules rule))

(defn- known-exclusion-key?
  [key]
  (or (= key :rule)
      (= key :rules)
      (= key :pattern)
      (= key :line)
      (= key :lines)
      (= key :code)
      (= key :form)
      (= key :reason)))

(defn- first-unknown-key-step
  [entry key]
  (let [(next-key) (next entry key)]
    (and next-key
         (or (and (known-exclusion-key? next-key)
                  (first-unknown-key-step entry next-key))
             (and (not (known-exclusion-key? next-key)) next-key)))))

(defn- first-unknown-key
  [entry key]
  (first-unknown-key-step entry key))

(defn- selector-value
  [entry key]
  (if (. entry key)
    1
    0))

(defn- selector-count
  [entry]
  (+ (selector-value entry :pattern)
     (selector-value entry :line)
     (selector-value entry :lines)
     (selector-value entry :code)
     (selector-value entry :form)))

(defn- rule-list-error-value
  [rules index names name]
  (if (not (known-rule? rules name))
    {:message (.. "lint exclusion " index ": unknown rule " name)}
    (and (<= (+ index 1) (length names))
         (rule-list-error-value rules (+ index 1) names (. names (+ index 1))))))

(defn- rule-list-error-step
  [rules index names]
  (if (> index (length names))
    nil
    (rule-list-error-value rules index names (. names index))))

(defn- rule-list-error
  [rules index names]
  (rule-list-error-step rules index names))

(defn- invalid-line-range?
  [lines]
  (or (not= (type lines) :table)
      (not (positive-integer? lines.from))
      (not (positive-integer? lines.to))
      (> lines.from lines.to)))

(defn- line-range-error
  [index entry]
  (let [lines entry.lines]
    (when (and lines (invalid-line-range? lines))
      {:message (.. "lint exclusion " index ": lines must have positive from/to with from <= to")})))

(defn- invalid-line-error
  [index entry]
  (when (and entry.line (not (positive-integer? entry.line)))
    {:message (.. "lint exclusion " index ": line must be a positive integer")}))

(defn- exclusive-selector-error
  [index entry]
  (when (and entry.line entry.lines)
    {:message (.. "lint exclusion " index ": line and lines are mutually exclusive")}))

(defn- missing-selector-error
  [index entry]
  (when (= (selector-count entry) 0)
    {:message (.. "lint exclusion " index ": at least one selector is required")}))

(defn- selector-error
  [index entry]
  (or (invalid-line-error index entry)
      (line-range-error index entry)
      (exclusive-selector-error index entry)
      (missing-selector-error index entry)))

(defn- string-field-error
  [index entry key]
  (let [value (. entry key)]
    (when (and value (not= (type value) :string))
      {:message (.. "lint exclusion " index ": " (tostring key) " must be a string")})))

(defn- rules-field-error
  [rules index entry]
  (let [names entry.rules]
    (when (and names
               (or (not (sequence? names))
                   (= (length names) 0)))
      {:message (.. "lint exclusion " index ": rules must be a non-empty list")})))

(defn- rules-name-error
  [rules index entry]
  (let [names entry.rules]
    (when (and names (sequence? names) (> (length names) 0))
      (rule-list-error rules 1 names))))

(defn- invalid-rule-error
  [index entry]
  (when (and entry.rule (not= (type entry.rule) :string))
    {:message (.. "lint exclusion " index ": rule must be a string")}))

(defn- exclusive-rule-error
  [index entry]
  (when (and entry.rule entry.rules)
    {:message (.. "lint exclusion " index ": rule and rules are mutually exclusive")}))

(defn- unknown-rule-error
  [rules index entry]
  (when (and entry.rule (not (known-rule? rules entry.rule)))
    {:message (.. "lint exclusion " index ": unknown rule " entry.rule)}))

(defn- rule-field-error
  [rules index entry]
  (or (invalid-rule-error index entry)
      (exclusive-rule-error index entry)
      (unknown-rule-error rules index entry)
      (rules-field-error rules index entry)
      (rules-name-error rules index entry)))

(defn- invalid-reason-error
  [index entry]
  (when (and entry.reason (not= (type entry.reason) :string))
    {:message (.. "lint exclusion " index ": reason must be a string")}))

(defn- blank-reason-error
  [index entry]
  (when (and entry.reason (blank? entry.reason))
    {:message (.. "lint exclusion " index ": reason must not be blank")}))

(defn- reason-error
  [index entry]
  (or (invalid-reason-error index entry)
      (blank-reason-error index entry)))

(defn- unknown-entry-key-error
  [index entry]
  (let [unknown (first-unknown-key entry nil)]
    (when unknown
      {:message (.. "lint exclusion " index ": unknown key " (tostring unknown))})))

(defn- entry-error
  [rules index entry]
  (or (unknown-entry-key-error index entry)
      (rule-field-error rules index entry)
      (string-field-error index entry :pattern)
      (string-field-error index entry :code)
      (string-field-error index entry :form)
      (reason-error index entry)
      (selector-error index entry)))

(defn- lines-equal-values?
  [left right]
  (and left right (= left.from right.from) (= left.to right.to)))

(defn- lines-equal?
  [left right]
  (or (= left right) (lines-equal-values? left right)))

(defn- duplicate?
  [candidate entry]
  (and (= candidate.rule entry.rule)
       (= candidate.rules entry.rules)
       (= candidate.form entry.form)
       (= candidate.pattern entry.pattern)
       (= candidate.line entry.line)
       (lines-equal? candidate.lines entry.lines)
       (= candidate.code entry.code)))

(defn- duplicate-index-value
  [exclusions index entry prior candidate]
  (if (duplicate? candidate entry)
    prior
    (and (< (+ prior 1) index)
         (duplicate-index-value exclusions index entry (+ prior 1) (. exclusions (+ prior 1))))))

(defn- duplicate-index-step
  [exclusions index entry prior]
  (if (>= prior index)
    nil
    (duplicate-index-value exclusions index entry prior (. exclusions prior))))

(defn- duplicate-index
  [exclusions index entry prior]
  (duplicate-index-step exclusions index entry prior))

(defn- duplicate-error
  [exclusions index entry]
  (let [duplicate (duplicate-index exclusions index entry 1)]
    (when duplicate
      {:message (.. "lint exclusion " index ": duplicate of exclusion " duplicate)})))

(defn- invalid-entry-error
  [index entry]
  (when (not= (type entry) :table)
    {:message (.. "lint exclusion " index " must be a table")}))

(defn- entry-validation-error
  [rules exclusions index entry]
  (or (invalid-entry-error index entry)
      (entry-error rules index entry)
      (duplicate-error exclusions index entry)))

(defn- first-error
  [rules exclusions index]
  (let [entry (. exclusions index)]
    (if (= entry nil)
      nil
      (or (entry-validation-error rules exclusions index entry)
          (first-error rules exclusions (+ index 1))))))

(defn- validate-list
  [rules exclusions]
  (first-error rules exclusions 1))

(defn- invalid-list-error
  [exclusions]
  (when (not (sequence? exclusions))
    {:message "lint exclusions must be a list"}))

(defn- validate-value
  [rules exclusions]
  (or (invalid-list-error exclusions)
      (validate-list rules exclusions)))

(defn validate
  [rules exclusions]
  (when exclusions
    (validate-value rules exclusions)))

(defn- copy-entry
  [entry rule]
  (let [result {}]
    (each [key value (pairs entry)]
      (tset result key value))
    (if rule
      (core.assoc result :rule rule)
      result)))

(defn- append-rule-exclusions
  [result rule entry]
  (each [_ exclusion (ipairs (or entry.exclusions []))]
    (table.insert result (copy-entry exclusion rule)))
  result)

(defn- normalize-entry
  [result rule entry]
  (when (= (type entry) :table)
    (append-rule-exclusions result rule entry)))

(defn- normalize-rules
  [rules result]
  (each [rule entry (pairs rules)]
    (normalize-entry result rule entry))
  result)

(defn normalize
  [rules]
  (normalize-rules rules []))
