(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.run)

(local core (require :eca.nfnl.core))
(local lint (require :fennel-extras.lint))
(local output (require :fennel-extras.lint.output))
(local exclusion-matcher (require :fennel-extras.lint.exclusion))

(defn- matching-exclusion?

  [exclusion findings matcher index]
  (if (> index (length findings))
    false
    (or (exclusion-matcher.matches? exclusion (. findings index) nil matcher)
        (matching-exclusion? exclusion findings matcher (+ index 1)))))

(defn- stale-message

  [exclusion policy]
  (let [instances (or (and exclusion.rule (. policy.rules exclusion.rule))
                      (and exclusion.rule policy.design (. policy.design exclusion.rule)))
        instance  (and instances exclusion.instance (. instances exclusion.instance))]
    (if (or (and instance (= instance.severity "off"))
            (and (= instance nil) (= instances nil)))
      (.. "stale exclusion: rule " exclusion.rule " is not enabled")
      (.. "stale exclusion: " exclusion.path))))

(defn- stale-exclusion

  [exclusion config-path policy]
  (let [rule    (or exclusion.rule "lint")
        message (stale-message exclusion policy)]
    {:kind "stale-exclusion" :path config-path :line 1 :col 1 :severity "error" :rule rule :form exclusion.path :message message}))

(defn- append-stale-item

  [result exclusion findings config-path matcher policy]
  (when (not (matching-exclusion? exclusion findings matcher 1))
        (table.insert result (stale-exclusion exclusion config-path policy)))
  result)

(defn- append-stale-step

  [exclusions findings config-path matcher policy index result recurse]
  (let [entry (. exclusions index)]
    (recurse exclusions findings config-path matcher policy (+ index 1) (append-stale-item result entry findings config-path matcher policy))))

(defn- append-stale

  [exclusions findings config-path matcher policy index result]
  (if (> index (length exclusions))
    result
    (append-stale-step exclusions findings config-path matcher policy index result append-stale)))

(defn- annotate-finding

  [finding source]
  (core.assoc finding :source source))

(defn- annotate-findings-step

  [findings source index recurse]
  (let [finding (annotate-finding (. findings index) source)
        result  (core.assoc findings index finding)]
    (recurse result source (+ index 1) recurse)))

(defn- annotate-findings

  [findings source index recurse]
  (if (> index (length findings))
    findings
    (annotate-findings-step findings source index recurse)))

(defn- lint-file

  [file policy]
  (let [context          {:path             file.path
                          :rules            policy.rules
                          :design           policy.design
                          :selection        file.selection
                          :matcher          policy.matcher
                          :defer-exclusions true}
        (findings error) (lint.check file.source context)]
    (if error
      (values nil
              {:message error.message :line error.line :col error.col :path file.path})
      (values (annotate-findings findings file.source 1 annotate-findings) nil))))

(defn- append-findings

  [result findings]
  (each [_ finding (ipairs findings)]
        (table.insert result finding))
  result)

(defn- lint-files-at-step

  [files policy index result recurse]
  (let [(findings error) (lint-file (. files index) policy)]
    (if error
      (values nil error)
      (recurse files policy (+ index 1) (append-findings result findings)))))

(defn- lint-files-at

  [files policy index result]
  (if (> index (length files))
    (values result nil)
    (lint-files-at-step files policy index result lint-files-at)))

(defn- exclusion-path

  [exclusion]
  exclusion.path)

(defn- path-in-scope?

  [paths path matcher index]
  (if (> index (length paths))
    false
    (or (matcher (. paths index) path)
        (path-in-scope? paths path matcher (+ index 1)))))

(defn- append-scoped-exclusion

  [result exclusion paths matcher]
  (when (or (= paths nil) (path-in-scope? paths (exclusion-path exclusion) matcher 1))
        (table.insert result exclusion))
  result)

(defn- scoped-exclusions-step

  [exclusions paths matcher index result recurse]
  (let [exclusion (. exclusions index)]
    (recurse exclusions paths matcher (+ index 1) (append-scoped-exclusion result exclusion paths matcher))))

(defn- scoped-exclusions

  [exclusions paths matcher index result]
  (if (> index (length exclusions))
    result
    (scoped-exclusions-step exclusions paths matcher index result scoped-exclusions)))

(defn- append-non-warning

  [result finding]
  (when (not (= finding.severity "warning"))
        (table.insert result finding))
  result)

(defn- keep-non-warning-step

  [findings index result recurse]
  (let [finding (. findings index)]
    (recurse findings (+ index 1) (append-non-warning result finding))))

(defn- keep-non-warning

  [findings index result]
  (if (> index (length findings))
    result
    (keep-non-warning-step findings index result keep-non-warning)))

(defn- diagnostic-source

  [filtered policy stale scope-paths]
  (if (and (> (length policy.exclusions) 0)
           (or scope-paths (> (length stale) 0)))
    (keep-non-warning filtered 1 [])
    filtered))

(defn- append-stale-findings

  [source stale]
  (each [_ finding (ipairs stale)]
        (table.insert source finding))
  source)

(defn- diagnostics

  [findings policy config-path scope-paths]
  (let [exclusions   (scoped-exclusions policy.exclusions scope-paths policy.matcher 1 [])
        (filtered _) (exclusion-matcher.apply findings exclusions nil policy.matcher)
        stale        (append-stale exclusions findings config-path policy.matcher policy 1 [])
        source       (diagnostic-source filtered policy stale scope-paths)]
    (output.sort (append-stale-findings source stale))))

(defn- has-errors?

  [findings index]
  (if (> index (length findings))
    false
    (or (= (. (. findings index) :severity) "error")
        (has-errors? findings (+ index 1)))))

(defn- render

  [findings format]
  (if (= format "json")
    (output.json-lines findings)
    (output.text-lines findings)))

(defn- result-status

  [findings]
  (if (has-errors? findings 1)
    1
    0))

(defn- result

  [findings format]
  {:lines (render findings format) :status (result-status findings)})

(defn lint-files

  [files policy config-path format scope-paths]
  (let [(findings error) (lint-files-at files policy 1 [])]
    (if error
      (values nil error)
      (result (diagnostics findings policy config-path scope-paths) format))))
