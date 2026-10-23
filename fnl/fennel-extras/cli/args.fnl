(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.cli.args)

(local table-update (require :fennel-extras.cli.table))

(defn lint-inputs
  [parsed cfg]
  (if (> (length parsed.paths) 0)
    parsed.paths
    (. cfg :paths)))

(defn- lint-state
  [args index result]
  {:args args :index index :result result})

(defn- lint-update
  [state result]
  (lint-state state.args state.index result))

(defn- lint-advance
  [state offset result]
  (lint-state state.args (+ state.index offset) result))

(defn- append-path
  [paths path]
  (let [result []]
    (each [_ value (ipairs paths)]
      (table.insert result value))
    (table.insert result path)
    result))

(defn- parse-lint-format-value
  [state value]
  (if (and (not= value "text") (not= value "json"))
    (values nil "format must be text or json")
    (values (lint-advance state 2 (table-update.update state.result {:format value :format-seen true})) nil)))

(defn- parse-lint-value-present
  [state key value]
  (case key
    "--format" (parse-lint-format-value state value)
    _          (values (lint-advance state 2 (table-update.update state.result {:base value :changed true})) nil)))

(defn- parse-lint-value
  [state key]
  (if (>= state.index (length state.args))
    (values nil (.. "missing argument for " key))
    (parse-lint-value-present state key (. state.args (+ state.index 1)))))

(defn- parse-lint-path
  [state]
  (values (lint-advance state 1 (table-update.update state.result {:paths (append-path state.result.paths (. state.args state.index))})) nil))

(defn- parse-lint-all
  [state]
  (if (or state.result.all state.result.changed)
    (values nil "unknown or duplicate lint flag: --all")
    (values (lint-advance state 1 (table-update.update state.result {:all true :changed false})) nil)))

(defn- parse-lint-changed
  [state]
  (if (or state.result.changed state.result.all)
    (values nil "unknown or duplicate lint flag: --changed")
    (values (lint-advance state 1 (table-update.update state.result {:changed true})) nil)))

(defn- parse-lint-base
  [state]
  (if state.result.base
    (values nil "unknown or duplicate lint flag: --base")
    (parse-lint-value state "--base")))

(defn- parse-lint-format
  [state]
  (if state.result.format-seen
    (values nil "unknown or duplicate lint flag: --format")
    (parse-lint-value state "--format")))

(defn- parse-lint-unsupported
  [state]
  (values nil (.. "unsupported lint flag: " (. state.args state.index))))

(defn- parse-lint-path-or-unknown
  [state]
  (let [arg (. state.args state.index)]
    (if (= (string.sub arg 1 2) "--")
      (values nil (.. "unknown flag: " arg))
      (parse-lint-path state))))

(defn- parse-lint-arg
  [state]
  (case (. state.args state.index)
    "--all"     (parse-lint-all state)
    "--changed" (parse-lint-changed state)
    "--base"    (parse-lint-base state)
    "--format"  (parse-lint-format state)
    "--write"   (parse-lint-unsupported state)
    "--check"   (parse-lint-unsupported state)
    "--parser"  (parse-lint-unsupported state)
    _           (parse-lint-path-or-unknown state)))

(defn- parse-lint-success
  [result]
  (if (and result.all result.base)
    (values nil "--base cannot be used with --all")
    result))

(defn- parse-lint-result
  [state error]
  (if error
    (values nil error)
    (parse-lint-success state.result)))

(defn- parse-lint-arg-result
  [state]
  (let [(next-state error) (parse-lint-arg state)]
    (if error
      {:kind :error :error error}
      {:kind :next :state next-state})))

(defn- parse-lint-step
  [state]
  (if (> state.index (length state.args))
    {:kind :done :state state}
    (parse-lint-arg-result state)))

(defn- parse-lint-loop
  [state]
  (let [step (parse-lint-step state)]
    (case step.kind
      :error (values nil step.error)
      :done  (values state nil)
      _      (parse-lint-loop step.state))))

(defn- parse-lint-args
  [args]
  (let [result              {:all false :base nil :changed false :format "text" :format-seen false :paths []}
        state               (lint-state args 2 result)
        (final-state error) (parse-lint-loop state)]
    (parse-lint-result final-state error)))

(defn- parse-format-mode-value
  [arg]
  (case arg
    "--check" :check
    _         :write))

(defn- parse-format-mode
  [state]
  (if state.mode
    (values nil "unknown or duplicate mode flag")
    (values {:args state.args :index (+ state.index 1) :mode (parse-format-mode-value (. state.args state.index)) :parser state.parser :paths state.paths}
            nil)))

(defn- parse-format-parser
  [state]
  (if (>= state.index (length state.args))
    (values nil "missing argument for --parser")
    (values {:args state.args :index (+ state.index 2) :mode state.mode :parser (. state.args (+ state.index 1)) :paths state.paths}
            nil)))

(defn- parse-format-path
  [state]
  (let [arg (. state.args state.index)]
    (if (= (string.sub arg 1 2) "--")
      (values nil (.. "unknown flag: " arg))
      (values {:args state.args :index (+ state.index 1) :mode state.mode :parser state.parser :paths (append-path state.paths arg)}
              nil))))

(defn- parse-format-arg
  [state]
  (case (. state.args state.index)
    "--check"  (parse-format-mode state)
    "--write"  (parse-format-mode state)
    "--parser" (parse-format-parser state)
    _          (parse-format-path state)))

(defn- parse-format-success
  [state]
  (if (not state.mode)
    (values nil "missing --check or --write")
    {:mode state.mode :parser state.parser :paths state.paths}))

(defn- parse-format-arg-result
  [state]
  (let [(next-state error) (parse-format-arg state)]
    (if error
      {:kind :error :error error}
      {:kind :next :state next-state})))

(defn- parse-format-step
  [state]
  (if (> state.index (length state.args))
    {:kind :done :state state}
    (parse-format-arg-result state)))

(defn- parse-format-loop
  [state]
  (let [step (parse-format-step state)]
    (case step.kind
      :error (values nil step.error)
      :done  (parse-format-success state)
      _      (parse-format-loop step.state))))

(defn- parse-format-args
  [args]
  (parse-format-loop {:args args :index 2 :mode nil :parser nil :paths []}))

(defn parse-args
  [args]
  (case (. args 1)
    "lint"   (parse-lint-args args)
    "format" (parse-format-args args)
    _        (values nil (.. "unknown command: " (or (. args 1) "")))))
