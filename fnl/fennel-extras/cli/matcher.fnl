(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.cli.matcher)

(defn- matches-pattern?
  [pattern text]
  (let [regex (vim.regex pattern)]
    (not= nil (regex:match_str text))))

(defn compile-pattern
  [pattern]
  (vim.regex pattern)
  true)

(defn vim-matcher
  []
  matches-pattern?)
