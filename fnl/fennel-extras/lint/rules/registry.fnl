(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.registry)

(local rule-name-list ["module-style" "spec-macro-import" "spec-no-module" "spec-direct-require" "one-is-per-testing" "if-branch-call" "if-without-else" "control-layout" "unused-and-or" "defn-args-newline" "function-shape" "no-mutation" "multiline-layout" "file-size" "core-require" "binding-per-line" "call-data-arg"])
(local options (require :fennel-extras.lint.rules.options))

(local rule-properties {:module-style {:scope :file} :spec-macro-import {:scope :file} :file-size {:scope :file}})

(defn defaults
  []
  (let [result {}]
    (each [_ rule (ipairs rule-name-list)]
      (tset result rule "off"))
    result))

(defn rule-names
  []
  rule-name-list)

(defn option-schema
  [rule]
  (options.schema rule))

(defn rule-scope
  [rule]
  (let [properties (. rule-properties rule)]
    (and properties
         (. properties :scope))))

(defn rule-options
  [policy rule]
  (and policy policy.options (. policy.options rule)))

(defn applies-to?
  [policy rule spec?]
  (let [target (. (rule-options policy rule) :applies-to)]
    (or (= target "all")
        (= target "spec")
        (and (= target "source") (not spec?)))))

(defn finding
  [path form severity rule message node]
  {:kind "finding" :path path :line form.line :col form.col :end-line form.end-line :end-col form.end-col :severity severity :rule rule :form form.form :message message :node node})

(defn rule-severity
  [policy rule]
  (or (and policy (. policy rule)) "off"))

(defn enabled?
  [policy rule]
  (not= (rule-severity policy rule) "off"))
