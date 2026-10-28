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

(defn- normalized-base
  [base]
  (if (or (= base "") (= base "."))
    ""
    base))

(defn- base-prefix
  [base]
  (if (= base "")
    ""
    (.. base "/")))

(defn- workspace-relative-path
  [base path]
  (let [base   (normalized-base base)
        prefix (base-prefix base)
        starts (and (not= base "")
                    (= (string.sub path 1 (string.len prefix)) prefix))]
    (or (and (= base "") path)
        (and (= path base) "")
        (and starts (string.sub path (+ (string.len prefix) 1))))))

(defn- path-match?
  [pattern path base]
  (let [relative (workspace-relative-path base path)]
    (or (matches-pattern? pattern path)
        (and relative (matches-pattern? pattern relative)))))

(defn- path-match-step
  [paths pattern path index]
  (if (> index (length paths))
    false
    (or (path-match? pattern path (. paths index))
        (path-match-step paths pattern path (+ index 1)))))

(defn vim-path-matcher
  [workspace-paths]
  (let [paths (or workspace-paths [])]
    (fn [pattern path]
      (path-match-step paths pattern path 1))))
