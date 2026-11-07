(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.exclusion)

(defn matches?

  [exclusion finding _source matcher]
  (and matcher
       (matcher exclusion.path finding.path)))

(defn- mark-match

  [finding exclusion matcher index matched]
  (when (matches? exclusion finding nil matcher)
    (tset matched index true))
  matched)

(defn- mark-matches-step

  [finding exclusions matcher index matched excluded recurse]
  (let [exclusion (. exclusions index)
        matched   (mark-match finding exclusion matcher index matched)
        excluded  (or excluded (matches? exclusion finding nil matcher))]
    (recurse finding exclusions matcher (+ index 1) matched excluded recurse)))

(defn- mark-matches

  [finding exclusions matcher index matched excluded recurse]
  (if (> index (length exclusions))
    (values excluded matched)
    (mark-matches-step finding exclusions matcher index matched excluded recurse)))

(defn- append-finding

  [result finding]
  (table.insert result finding)
  result)

(defn- apply-finding

  [finding exclusions matcher result matched]
  (let [(excluded next-matched) (mark-matches finding exclusions matcher 1 matched false mark-matches)]
    (if excluded
      (values result next-matched)
      (values (append-finding result finding) next-matched))))

(defn- apply-findings-step

  [findings exclusions matcher index result matched recurse]
  (let [finding                    (. findings index)
        (next-result next-matched) (apply-finding finding exclusions matcher result matched)]
    (recurse findings exclusions matcher (+ index 1) next-result next-matched recurse)))

(defn- apply-findings

  [findings exclusions matcher index result matched recurse]
  (if (> index (length findings))
    (values result matched)
    (apply-findings-step findings exclusions matcher index result matched recurse)))

(defn apply

  [findings exclusions _source matcher]
  (let [matched {}]
    (each [index _ (ipairs exclusions)]
      (tset matched index false))
    (apply-findings findings exclusions matcher 1 [] matched apply-findings)))
