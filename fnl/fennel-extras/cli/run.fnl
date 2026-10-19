(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.cli.run)

(local table-update (require :fennel-extras.cli.table))
(local config (require :fennel-extras.config))
(local lint-run (require :fennel-extras.lint.run))
(local scan (require :fennel-extras.cli.scan))
(local arg_parser (require :fennel-extras.cli.args))
(local fs (require :fennel-extras.cli.fs))
(local git (require :fennel-extras.cli.git))
(local format (require :fennel-extras.cli.format))

(defn- emit [printer line]
  (printer line))

(defn- default-print [line]
  (io.write (.. (string.gsub line "\n+$" "") "\n"))
  (io.flush))

(defn- config-default [cfg key default]
  (let [value (. cfg key)]
    (if (= value nil) default value)))

(defn- load-parser-result [name ok parser]
  (if ok parser (values nil (.. "could not require parser module: " name))))

(defn- load-parser-result-call [name]
  (let [(ok parser) (pcall require name)]
    (load-parser-result name ok parser)))

(defn- load-parser [name]
  (if name
      (load-parser-result-call name)
      nil))

(defn- config-load-error [printer path error]
  (emit printer (.. path ": " (or (. error :message) (tostring error))))
  (values nil true nil))

(defn- config-loaded [printer path]
  (let [(loaded error) (config.load path)]
    (if error
        (config-load-error printer path error)
        (values loaded nil path))))

(defn- config-for [root printer]
  (let [path (config.find root)]
    (if path
        (config-loaded printer path)
        (values {} nil nil))))

(defn- read-lint-item [file]
  (let [(source error) (fs.read-file file.absolute)]
    (if error
        (values nil error)
        (values source nil))))

(defn- append-lint-source [result file source]
  (table.insert result {:path file.relative :source source})
  result)

(defn- read-lint-item-result [state]
  (let [file           (. state.files state.index)
        (source error) (read-lint-item file)]
    (if error
        (values nil {:path file.relative :error error})
        (values {:files  state.files
                 :index  (+ state.index 1)
                 :result (append-lint-source state.result file source)} nil))))

(defn- read-lint-step-result [state]
  (let [(next-state error) (read-lint-item-result state)]
    (if error
        {:kind :error :error error}
        {:kind :next :state next-state})))

(defn- read-lint-step [state]
  (if (> state.index (length state.files))
      {:kind :done :result state.result}
      (read-lint-step-result state)))

(defn- read-lint-files [state]
  (let [step (read-lint-step state)]
    (case step.kind
      :error (values nil step.error)
      :done (values step.result nil)
      _ (read-lint-files step.state))))

(defn- lint-policy-error [root config-path printer error]
  (emit printer (format.error-line (scan.relative root (or config-path ".fnl-extras.fnl")) error))
  2)

(defn- lint-read-error [printer error]
  (emit printer (format.error-line error.path error.error))
  2)

(defn- lint-run-error [printer error]
  (emit printer (format.error-line error.path error))
  2)

(defn- lint-result [printer result]
  (each [_ line (ipairs result.lines)] (emit printer line))
  result.status)

(defn- run-lint-sources [context policy sources]
  (let [(selected paths) (git.lint-selection context.parsed sources context.git-info)
        root             context.git-info.root
        (result error)   (lint-run.lint-files selected policy
                                               (and context.config-path (scan.relative root context.config-path))
                                               context.parsed.format paths)]
    (if error
        (lint-run-error context.printer error)
        (lint-result context.printer result))))

(defn- run-lint-files [context policy files]
  (let [(sources read-error) (read-lint-files {:files files :index 1 :result []})]
    (if read-error
        (lint-read-error context.printer read-error)
        (run-lint-sources context policy sources))))

(defn- run-lint-policy [context files]
  (let [(policy policy-error) (config.lint-policy context.cfg)]
    (if policy-error
        (lint-policy-error context.root context.config-path context.printer policy-error)
        (run-lint-files context policy files))))

(defn- run-lint-discovery [context]
  (let [inputs                       ((. arg_parser :lint-inputs) context.parsed context.cfg)
        extensions                   (or (. context.cfg :extensions) [".fnl" ".fnlm"])
        skip-dotfiles                (config-default context.cfg :skip-dotfiles true)
        follow-symlinks              (config-default context.cfg :follow-symlinks false)
        (discovered discovery-error) (scan.sorted-files context.git-info.root inputs
                                                   {:excludes        (or (. context.cfg :exclude) [])
                                                    :extensions      extensions
                                                    :skip-dotfiles   skip-dotfiles
                                                    :follow-symlinks follow-symlinks})
        files                        (and discovered (format.without-config-file discovered context.config-path))]
    (if discovery-error
        (git.emit-git-error context.printer discovery-error)
        (run-lint-policy context files))))

(defn- run-lint [context]
  (let [(git-info git-error-value) (git.lint-git-info context.root context.parsed context.require-git)]
    (if git-error-value
        (git.emit-git-error context.printer git-error-value)
        (run-lint-discovery (table-update.update context {:git-info git-info})))))

(defn- run-format-files [context files]
  (let [(parser parser-error) (load-parser (or context.parsed.parser (. context.cfg :parser)))]
    (if parser-error
        (git.emit-git-error context.printer parser-error)
        (format.run-files context parser files))))

(defn- run-format-discovery [root parsed cfg config-path]
  (let [inputs                       ((. arg_parser :lint-inputs) parsed cfg)
        extensions                   (or (. cfg :extensions) [".fnl" ".fnlm"])
        skip-dotfiles                (config-default cfg :skip-dotfiles true)
        follow-symlinks              (config-default cfg :follow-symlinks false)
        (discovered discovery-error) (scan.sorted-files root inputs
                                                   {:excludes        (or (. cfg :exclude) [])
                                                    :extensions      extensions
                                                    :skip-dotfiles   skip-dotfiles
                                                    :follow-symlinks follow-symlinks})]
    (values (and discovered (format.without-config-file discovered config-path)) discovery-error)))

(defn- run-format-files-result [context files]
  (if (= (length files) 0)
      (git.emit-git-error context.printer "no files found")
      (run-format-files context files)))

(defn- run-format-result [context files discovery-error]
  (if discovery-error
      (git.emit-git-error context.printer discovery-error)
      (run-format-files-result context files)))

(defn- run-format [context]
  (let [(files discovery-error) (run-format-discovery context.root context.parsed context.cfg context.config-path)]
    (run-format-result context files discovery-error)))

(defn- run-command-mode [context]
  (case (. context.args 1)
    "lint" (run-lint (table-update.update context {:require-git context.parsed.changed}))
    _ (run-format context)))

(defn- run-command [context]
  (let [(cfg config-error config-path) (config-for context.root context.printer)]
    (if config-error
        2
        (run-command-mode (table-update.update context {:cfg cfg :config-path config-path})))))

(defn run [args opts]
  (let [opts (or opts {}) printer (or (. opts :print) default-print) root (or (. opts :cwd) (scan.cwd))
        (parsed parse-error) ((. arg_parser :parse-args) args)]
    (if parse-error
        (git.emit-git-error printer parse-error)
        (run-command {:root root :args args :parsed parsed :printer printer}))))
