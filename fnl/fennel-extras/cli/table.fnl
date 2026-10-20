(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.cli.table)

(defn update
  [original changes]
  (let [result {}]
    (each [key value (pairs original)]
      (tset result key value))
    (each [key value (pairs changes)]
      (tset result key value))
    result))
