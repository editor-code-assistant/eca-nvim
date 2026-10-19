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
      (or (exclusion-match? (. exclusions index) finding)
          (excluded? exclusions finding (+ index 1)))))

(defn- append-kept-finding [result finding exclusions]
  (if (not (excluded? exclusions finding 1))
      (table.insert result finding))
  result)

(defn- keep-finding-step [findings exclusions index result recurse]
  (let [finding (. findings index)]
    (recurse findings exclusions (+ index 1)
             (append-kept-finding result finding exclusions))))

(defn- keep-finding [findings exclusions index result]
  (if (> index (length findings))
      result
      (keep-finding-step findings exclusions index result keep-finding)))

(defn- matching-exclusion? [exclusion findings index]
  (if (> index (length findings))
      false
      (or (exclusion-match? exclusion (. findings index))
          (matching-exclusion? exclusion findings (+ index 1)))))

(defn- stale-exclusion [exclusion config-path]
  {:kind     "stale-exclusion"
   :path     config-path
   :line     1
   :col      1
   :severity "error"
   :rule     exclusion.rule
   :form     exclusion.form
   :message  (.. "stale exclusion: " exclusion.form)})

(defn- append-stale-item [result exclusion findings config-path]
  (if (not (matching-exclusion? exclusion findings 1))
      (table.insert result (stale-exclusion exclusion config-path)))
  result)

(defn- append-stale-step [exclusions findings config-path index result recurse]
  (let [exclusion (. exclusions index)]
    (recurse exclusions findings config-path (+ index 1)
             (append-stale-item result exclusion findings config-path))))

(defn- append-stale [exclusions findings config-path index result]
  (if (> index (length exclusions))
      result
      (append-stale-step exclusions findings config-path index result append-stale)))

(defn- normalized-testing-form [finding]
  (or (and (string.match finding.form " > top#[0-9]+$")
           (.. finding.form " > testing#1"))
      finding.form))

(defn- normalized-branch-form [finding]
  (let [form (string.gsub finding.form " > (top#[0-9]+) > (then.*)$" " > %1 > if#1 > %2")]
    form))

(defn- normalized-form [finding]
  (if (= finding.rule "one-is-per-testing")
      (normalized-testing-form finding)
      (normalized-branch-form finding)))

(defn- normalized-finding [finding]
  {:kind     finding.kind
   :path     finding.path
   :line     finding.line
   :col      finding.col
   :end-line finding.end-line
   :end-col  finding.end-col
   :severity finding.severity
   :rule     finding.rule
   :form     (normalized-form finding)
   :message  finding.message})

(defn- normalize-findings-step [findings index result recurse]
  (let [finding (. findings index)]
    (table.insert result (normalized-finding finding))
    (recurse findings (+ index 1) result)))

(defn- normalize-findings [findings index result]
  (if (> index (length findings))
      result
      (normalize-findings-step findings index result normalize-findings)))

(defn- lint-file [file policy]
  (let [(findings error) (lint.check file.source {:path           file.path
                                                  :rules          policy.rules
                                                  :max-code-lines policy.max-code-lines
                                                  :selection      file.selection})]
    (if error
        (values nil {:message error.message
                     :line    error.line
                     :col     error.col
                     :path    file.path})
        (values (normalize-findings findings 1 []) nil))))

(defn- append-findings [result findings]
  (each [_ finding (ipairs findings)]
    (table.insert result finding))
  result)

(defn- lint-files-at-step [files policy index result recurse]
  (let [(findings error) (lint-file (. files index) policy)]
    (if error
        (values nil error)
        (recurse files policy (+ index 1)
                 (append-findings result findings)))))

(defn- lint-files-at [files policy index result]
  (if (> index (length files))
      (values result nil)
      (lint-files-at-step files policy index result lint-files-at)))

(defn- exclusion-path [exclusion]
  (or (string.match exclusion.form "^(.-) > ") exclusion.form))

(defn- path-in-scope? [paths path index]
  (if (> index (length paths))
      false
      (or (= path (. paths index))
          (path-in-scope? paths path (+ index 1)))))

(defn- append-scoped-exclusion [result exclusion paths]
  (if (or (= paths nil) (path-in-scope? paths (exclusion-path exclusion) 1))
      (table.insert result exclusion))
  result)

(defn- scoped-exclusions-step [exclusions paths index result recurse]
  (let [exclusion (. exclusions index)]
    (recurse exclusions paths (+ index 1)
             (append-scoped-exclusion result exclusion paths))))

(defn- scoped-exclusions [exclusions paths index result]
  (if (> index (length exclusions))
      result
      (scoped-exclusions-step exclusions paths index result scoped-exclusions)))

(defn- append-non-warning [result finding]
  (if (not (= finding.severity "warning"))
      (table.insert result finding))
  result)

(defn- keep-non-warning-step [findings index result recurse]
  (let [finding (. findings index)]
    (recurse findings (+ index 1)
             (append-non-warning result finding))))

(defn- keep-non-warning [findings index result]
  (if (> index (length findings))
      result
      (keep-non-warning-step findings index result keep-non-warning)))

(defn- diagnostic-source [filtered policy stale scope-paths]
  (if (and (> (length policy.exclusions) 0)
           (or scope-paths (> (length stale) 0)))
      (keep-non-warning filtered 1 [])
      filtered))

(defn- append-stale-findings [source stale]
  (each [_ finding (ipairs stale)]
    (table.insert source finding))
  source)

(defn- diagnostics [findings policy config-path scope-paths]
  (let [exclusions (scoped-exclusions policy.exclusions scope-paths 1 [])
        filtered   (keep-finding findings exclusions 1 [])
        stale      (append-stale exclusions findings config-path 1 [])
        source     (diagnostic-source filtered policy stale scope-paths)]
    (output.sort (append-stale-findings source stale))))

(defn- has-errors? [findings index]
  (if (> index (length findings))
      false
      (or (= (. (. findings index) :severity) "error")
          (has-errors? findings (+ index 1)))))

(defn- render [findings format]
  (if (= format "json")
      (output.json-lines findings)
      (output.text-lines findings)))

(defn- result-status [findings]
  (if (has-errors? findings 1) 1 0))

(defn- result [findings format]
  {:lines  (render findings format)
   :status (result-status findings)})

(defn lint-files [files policy config-path format scope-paths]
  (let [(findings error) (lint-files-at files policy 1 [])]
    (if error
        (values nil error)
        (result (diagnostics findings policy config-path scope-paths) format))))
