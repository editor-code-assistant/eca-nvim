(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.exclusion)

(local core (require :eca.nfnl.core))

(defn- source-lines
  [source]
  (icollect [value (string.gmatch source "([^\n]*)\n?")] value))

(defn- line-text
  [source line]
  (or (. (source-lines source) line) ""))

(defn- span-start
  [index state]
  (if (= index state.first)
    state.start
    1))

(defn- span-end
  [index state]
  (if (= index state.last)
    (- state.end 1)
    -1))

(defn- span-line
  [text index state]
  (let [start (span-start index state)
        end   (span-end index state)]
    (string.sub text start end)))

(defn- append-span-line
  [result text]
  (table.insert result text)
  result)

(defn- append-span-line-at
  [lines state recurse]
  (let [text   (. lines state.index)
        result (append-span-line state.result (span-line text state.index state))]
    (recurse lines (core.assoc state :index (+ state.index 1) :result result) recurse)))

(defn- multiline-source-step
  [lines state recurse]
  (if (> state.index state.last)
    (table.concat state.result "\n")
    (append-span-line-at lines state recurse)))

(defn- multiline-source
  [source finding]
  (let [lines (source-lines source)
        state {:first  finding.line
               :last   finding.end-line
               :start  finding.col
               :end    finding.end-col
               :index  finding.line
               :result []}]
    (multiline-source-step lines state multiline-source-step)))

(defn- finding-source
  [source finding]
  (let [first-line (line-text source finding.line)]
    (if (= finding.line finding.end-line)
      (string.sub first-line finding.col (- finding.end-col 1))
      (multiline-source source finding))))

(defn- rule-list-selected?
  [names rule index]
  (if (> index (length names))
    false
    (or (= (. names index) rule)
        (rule-list-selected? names rule (+ index 1)))))

(defn- rule-selected?
  [exclusion rule]
  (or (= exclusion.rule nil)
      (= exclusion.rule rule)
      (and exclusion.rules
           (rule-list-selected? exclusion.rules rule 1))))

(defn- line-selected?
  [exclusion finding]
  (or (and exclusion.line
           (<= finding.line exclusion.line)
           (<= exclusion.line finding.end-line))
      (and exclusion.lines
           (<= finding.line exclusion.lines.to)
           (<= exclusion.lines.from finding.end-line))))

(defn- selector-selected?
  [exclusion finding source matcher]
  (and (or (not exclusion.pattern) (matcher exclusion.pattern finding.path))
       (or (not (or exclusion.line exclusion.lines)) (line-selected? exclusion finding))
       (or (not exclusion.code)
           (and finding.node
                (matcher exclusion.code (finding-source (or source finding.source) finding))))
       (or (not exclusion.form) (= exclusion.form finding.form))))

(defn matches?
  [exclusion finding source matcher]
  (and (rule-selected? exclusion finding.rule)
       (selector-selected? exclusion finding source matcher)))

(defn- mark-match
  [finding exclusion source matcher index matched]
  (when (matches? exclusion finding source matcher)
    (tset matched index true))
  matched)

(defn- mark-matches-step
  [finding exclusions source matcher index matched excluded recurse]
  (let [exclusion (. exclusions index)
        matched   (mark-match finding exclusion source matcher index matched)
        excluded  (or excluded (matches? exclusion finding source matcher))]
    (recurse finding exclusions source matcher (+ index 1) matched excluded recurse)))

(defn- mark-matches
  [finding exclusions source matcher index matched excluded recurse]
  (if (> index (length exclusions))
    (values excluded matched)
    (mark-matches-step finding exclusions source matcher index matched excluded recurse)))

(defn- append-finding
  [result finding]
  (table.insert result finding)
  result)

(defn- apply-finding
  [finding exclusions source matcher result matched]
  (let [(excluded next-matched) (mark-matches finding exclusions source matcher 1 matched false mark-matches)]
    (if excluded
      (values result next-matched)
      (values (append-finding result finding) next-matched))))

(defn- apply-findings-step
  [findings exclusions source matcher index result matched recurse]
  (let [finding                    (. findings index)
        (next-result next-matched) (apply-finding finding exclusions source matcher result matched)]
    (recurse findings exclusions source matcher (+ index 1) next-result next-matched recurse)))

(defn- apply-findings
  [findings exclusions source matcher index result matched recurse]
  (if (> index (length findings))
    (values result matched)
    (apply-findings-step findings exclusions source matcher index result matched recurse)))

(defn apply
  [findings exclusions source matcher]
  (let [matched {}]
    (each [index _ (ipairs exclusions)]
      (tset matched index false))
    (apply-findings findings exclusions source matcher 1 [] matched apply-findings)))
