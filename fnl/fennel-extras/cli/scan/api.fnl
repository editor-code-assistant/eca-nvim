(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.cli.scan.api)

(local scan-path (require :fennel-extras.cli.scan.path))

(defn cwd
  []
  (scan-path.cwd))

(defn relative
  [root path]
  (scan-path.relative root path))

(defn realpath
  [uv path]
  (scan-path.realpath uv path))
