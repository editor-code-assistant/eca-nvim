(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.cli.format)

(local formatter (require :fennel-extras.format))
(local fs (require :fennel-extras.cli.fs))
(local scan (require :fennel-extras.cli.scan))
(local table-copy (require :fennel-extras.cli.table))

(defn error-line
  [path error]
  (let [message (or (. error :message) (tostring error))
        line    (. error :line)
        col     (or (. error :col) (. error :column))]
    (if (and line col)
      (.. path ":" line ":" col ": " message)
      (.. path ": " message))))

(defn- formatter-config
  [cfg]
  {:indents (. cfg :indents) :format-as (. cfg :format-as) :indent-patterns (. cfg :indent-patterns) :indent-width (. cfg :indent-width) :builtins (. cfg :builtins) :prefix-fallbacks (. cfg :prefix-fallbacks) :align-bindings (. cfg :align-bindings)})

(defn- normalized-path
  [path]
  (if (= (string.sub path 1 9) "/private/")
    (string.sub path 9)
    path))

(defn- same-path?
  [left right]
  (let [uv    (or vim.uv vim.loop)
        left  (normalized-path (or (scan.realpath uv left) left))
        right (normalized-path (or (scan.realpath uv right) right))]
    (= left right)))

(defn- config-file-kept?
  [file config-path]
  (not (same-path? file.absolute config-path)))

(defn- without-config-file-item
  [file config-path]
  (when (config-file-kept? file config-path)
    file))

(defn- without-config-file-result
  [files config-path]
  (icollect [_ file (ipairs files)]
    (without-config-file-item file config-path)))

(defn without-config-file
  [files config-path]
  (if config-path
    (without-config-file-result files config-path)
    files))

(defn- record-formatted
  [state file source output]
  (table.insert state.formatted {:path file.absolute :relative file.relative :source source :text output})
  (when (not= source output)
    (table.insert state.changed file.relative))
  state)

(defn- run-files-error
  [printer failure]
  (printer (error-line failure.path failure.error))
  2)

(defn- check-files
  [changed printer]
  (each [_ path (ipairs changed)] (printer path))
  (if (> (length changed) 0)
    1
    0))

(defn- write-failure-result
  [temps write-failure printer]
  (each [_ item (ipairs temps)] (os.remove item.temp))
  (printer (.. write-failure.path ": " write-failure.error))
  2)

(defn- rename-item
  [item]
  (let [(ok renamed error) (pcall os.rename item.temp item.path)]
    (when (or (not ok) (not renamed))
      {:path item.relative :error (or error "could not rename temporary file")})))

(defn- rename-step
  [rename-failure item]
  (if rename-failure
    rename-failure
    (rename-item item)))

(defn- rename-loop
  [temps index failure]
  (if (> index (length temps))
    failure
    (rename-loop temps (+ index 1) (rename-step failure (. temps index)))))

(defn- rename-files
  [temps]
  (rename-loop temps 1 nil))

(defn- rename-failure-result
  [temps rename-failure printer]
  (each [_ item (ipairs temps)] (os.remove item.temp))
  (printer (.. rename-failure.path ": " rename-failure.error))
  2)

(defn- format-source-error
  [file source output error]
  (if error
    (values nil {:path file.relative :error error})
    (values {:path file.absolute :relative file.relative :source source :text output} nil)))

(defn- format-source-result
  [file source result]
  (case (not result.ok)
    true  (values nil {:path file.relative :error result.output})
    false (format-source-error file source result.output result.error)))

(defn- format-string-call
  [parser cfg source]
  ((. formatter :format-string) source {:parser parser :config (formatter-config cfg)}))

(defn- format-file-source
  [parser cfg file source]
  (let [(ok output error) (pcall format-string-call parser cfg source)]
    (format-source-result file source {:ok ok :output output :error error})))

(defn- format-file
  [parser cfg file]
  (let [(source read-error) (fs.read-file file.absolute)]
    (if read-error
      (values nil {:path file.relative :error read-error})
      (format-file-source parser cfg file source))))

(defn- append-formatted
  [state item]
  (table.insert state.formatted item)
  (when (not= item.source item.text)
    (table.insert state.changed item.relative))
  state)

(defn- write-success-result
  [changed printer]
  (each [_ path (ipairs changed)] (printer path))
  0)

(defn- write-item
  [item temps]
  (let [(temp error) (fs.temp-write item.path item.text)]
    (if (not temp)
      {:path item.relative :error error}
      (table.insert temps {:path item.path :relative item.relative :temp temp}))))

(defn- write-step
  [write-failure item temps]
  (if (or write-failure (= item.source item.text))
    write-failure
    (write-item item temps)))

(defn- write-files-loop
  [formatted index temps failure]
  (if (> index (length formatted))
    (values temps failure)
    (write-files-loop formatted (+ index 1) temps (write-step failure (. formatted index) temps))))

(defn- write-files-rename
  [temps changed printer]
  (let [rename-failure (rename-files temps)]
    (if rename-failure
      (rename-failure-result temps rename-failure printer)
      (write-success-result changed printer))))

(defn- write-files-finish
  [formatted changed printer]
  (let [(temps write-failure) (write-files-loop formatted 1 [] nil)]
    (if write-failure
      (write-failure-result temps write-failure printer)
      (write-files-rename temps changed printer))))

(defn- process-files-result
  [mode formatted changed printer]
  (table.sort changed)
  (if (= mode :check)
    (check-files changed printer)
    (write-files-finish formatted changed printer)))

(defn- run-file-item
  [ctx state file]
  (let [(item error) (format-file ctx.parser ctx.cfg file)]
    (if error
      (table-copy.update state {:failure error})
      (append-formatted state item))))

(defn- run-files-step
  [ctx state file]
  (if state.failure
    state
    (run-file-item ctx state file)))

(defn- run-files-result
  [ctx state]
  (if state.failure
    (run-files-error ctx.printer state.failure)
    (process-files-result ctx.mode state.formatted state.changed ctx.printer)))

(defn- run-files-loop
  [ctx state files index]
  (if (> index (length files))
    state
    (run-files-loop ctx (run-files-step ctx state (. files index)) files (+ index 1))))

(defn run-files
  [context parser files]
  (let [ctx   (table-copy.update context {:mode context.parsed.mode :parser parser})
        state {:formatted [] :changed [] :failure nil}]
    (run-files-result ctx (run-files-loop ctx state files 1))))
