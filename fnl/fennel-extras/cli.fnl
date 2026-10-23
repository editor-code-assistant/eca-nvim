(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.cli)

(local runner (require :fennel-extras.cli.run))

(def run runner.run)
