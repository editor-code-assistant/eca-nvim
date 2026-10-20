(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.registry)

(local defaults-map
       {:module-style        "error" :spec-macro-import   "error" :spec-no-module      "error" :spec-direct-require "error" :one-is-per-testing  "error" :if-branch-call      "warning" :if-without-else     "warning" :control-layout      "warning" :defn-args-newline   "warning" :function-shape      "warning" :no-mutation         "warning" :multiline-layout    "warning" :file-size           "warning" :core-require        "error"})

(local rule-properties
       {:module-style      {:scope :file} :spec-macro-import {:scope :file} :file-size         {:scope :file}})

(defn defaults
  []
  defaults-map)

(defn rule-scope
  [rule]
  (let [properties (. rule-properties rule)]
    (and properties
         (. properties :scope))))
(defn finding
  [path form severity rule message node]
  {:kind     "finding" :path     path :line     form.line :col      form.col :end-line form.end-line :end-col  form.end-col :severity severity :rule     rule :form     form.form :message  message :node     node})

(defn rule-severity
  [policy rule]
  (let [override (and policy (. policy rule))]
    (or override
        (. defaults-map rule))))

(defn enabled?
  [policy rule]
  (not= (rule-severity policy rule) "off"))
