(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.run)

(local lint (require :fennel-extras.lint))
(local output (require :fennel-extras.lint.output))

(defn- exclusion-match? [exclusion finding]
  (and (= exclusion.rule finding.rule)
       (= exclusion.form finding.form)))

(defn- excluded? [exclusions finding index]
  (if (> index (length exclusions))
      false
      (if (exclusion-match? (. exclusions index) finding)
          true
          (excluded? exclusions finding (+ index 1)))))

(defn- keep-finding [findings exclusions index result]
  (if (> index (length findings))
      result
      (let [finding (. findings index)]
        (if (not (excluded? exclusions finding 1))
            (table.insert result finding))
        (keep-finding findings exclusions (+ index 1) result))))

(defn- matching-exclusion? [exclusion findings index]
  (if (> index (length findings))
      false
      (if (exclusion-match? exclusion (. findings index))
          true
          (matching-exclusion? exclusion findings (+ index 1)))))

(defn- stale-exclusion [exclusion config-path]
  {:kind "stale-exclusion"
   :path config-path
   :line 1
   :col 1
   :severity "error"
   :rule exclusion.rule
   :form exclusion.form
   :message (.. "stale exclusion: " exclusion.form)})

(defn- append-stale [exclusions findings config-path index result]
  (if (> index (length exclusions))
      result
      (let [exclusion (. exclusions index)]
        (if (not (matching-exclusion? exclusion findings 1))
            (table.insert result (stale-exclusion exclusion config-path)))
        (append-stale exclusions findings config-path (+ index 1) result))))

(defn- normalized-form [finding]
  (if (= finding.rule "one-is-per-testing")
      (if (string.match finding.form " > top#[0-9]+$")
          (.. finding.form " > testing#1")
          finding.form)
      (let [form (string.gsub finding.form " > (top#[0-9]+) > (then.*)$" " > %1 > if#1 > %2")]
        form)))

(defn- normalize-findings [findings index result]
  (if (> index (length findings))
      result
      (let [finding (. findings index)]
        (table.insert result {:kind finding.kind
                              :path finding.path
                              :line finding.line
                              :col finding.col
                              :end-line finding.end-line
                              :end-col finding.end-col
                              :severity finding.severity
                              :rule finding.rule
                              :form (normalized-form finding)
                              :message finding.message})
        (normalize-findings findings (+ index 1) result))))

(defn- lint-file [file policy]
  (let [(findings error) (lint.check file.source {:path file.path :rules policy.rules
                                                  :selection file.selection})]
    (if error
        (values nil {:message error.message
                     :line error.line
                     :col error.col
                     :path file.path})
        (values (normalize-findings findings 1 []) nil))))

(defn- lint-files-at [files policy index result]
  (if (> index (length files))
      (values result nil)
      (let [(findings error) (lint-file (. files index) policy)]
        (if error
            (values nil error)
            (lint-files-at files policy (+ index 1)
                           (do (each [_ finding (ipairs findings)]
                                 (table.insert result finding))
                             result))))))

(defn- exclusion-path [exclusion]
  (or (string.match exclusion.form "^(.-) > ") exclusion.form))

(defn- path-in-scope? [paths path index]
  (if (> index (length paths))
      false
      (if (= path (. paths index))
          true
          (path-in-scope? paths path (+ index 1)))))

(defn- scoped-exclusions [exclusions paths index result]
  (if (> index (length exclusions))
      result
      (let [exclusion (. exclusions index)]
        (if (or (= paths nil) (path-in-scope? paths (exclusion-path exclusion) 1))
            (table.insert result exclusion))
        (scoped-exclusions exclusions paths (+ index 1) result))))

(defn- keep-non-warning [findings index result]
  (if (> index (length findings))
      result
      (let [finding (. findings index)]
        (if (not (= finding.severity "warning"))
            (table.insert result finding))
        (keep-non-warning findings (+ index 1) result))))

(defn- diagnostics [findings policy config-path scope-paths]
  (let [exclusions (scoped-exclusions policy.exclusions scope-paths 1 [])
        filtered (keep-finding findings exclusions 1 [])
        stale (append-stale exclusions findings config-path 1 [])
        source (if (and (> (length policy.exclusions) 0)
                        (or scope-paths (> (length stale) 0)))
                   (keep-non-warning filtered 1 [])
                   filtered)]
    (output.sort (do (each [_ finding (ipairs stale)]
                       (table.insert source finding))
                   source))))

(defn- has-errors? [findings index]
  (if (> index (length findings))
      false
      (if (= (. (. findings index) :severity) "error")
          true
          (has-errors? findings (+ index 1)))))

(defn- render [findings format]
  (if (= format "json")
      (output.json-lines findings)
      (output.text-lines findings)))

(defn- result [findings format]
  {:lines (render findings format)
   :status (if (has-errors? findings 1) 1 0)})

(defn lint-files [files policy config-path format scope-paths]
  (let [(findings error) (lint-files-at files policy 1 [])]
    (if error
        (values nil error)
        (result (diagnostics findings policy config-path scope-paths) format))))
