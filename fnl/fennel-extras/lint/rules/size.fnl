(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.size)

(local reader (require :fennel-extras.reader))
(local ast (require :fennel-extras.lint.rules.ast))
(local registry (require :fennel-extras.lint.rules.registry))
(local code-line-count ast.code-line-count)
(local newline-count ast.newline-count)
(local enabled? registry.enabled?)
(local rule-severity registry.rule-severity)

(defn- file-size-finding-result
  [path policy count limit]
  (if (> count limit)
    [{:kind     "finding"
      :path     path
      :line     1
      :col      1
      :end-line 1
      :end-col  1
      :severity (rule-severity policy "file-size")
      :rule     "file-size"
      :form     (.. path " > file")
      :message  (.. "file has " count " code lines (max " limit "); split it by responsibility into smaller modules")
      :node     nil}]
    []))

(defn- file-size-finding-source
  [path policy source]
  (let [tokens (reader.tokenize source)
        count  (code-line-count tokens 1 (+ (newline-count source 1 0) 1) 0)
        limit  (. (registry.rule-options policy "file-size") :max-code-lines)]
    (file-size-finding-result path policy count limit)))

(defn finding
  [path policy source]
  (if (enabled? policy "file-size")
    (file-size-finding-source path policy source)
    []))
