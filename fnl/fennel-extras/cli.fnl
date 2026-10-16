(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.cli)

(local config (require :fennel-extras.config))
(local formatter (require :fennel-extras.format))
(local lint-run (require :fennel-extras.lint.run))
(local lint-selection (require :fennel-extras.lint.selection))

(defn- emit [printer line]
  (printer line))

(defn- default-print [line]
  (io.write (.. (string.gsub line "\n+$" "") "\n"))
  (io.flush))

(defn- cwd []
  (or (and vim vim.loop (vim.loop.cwd))
      (and vim vim.uv (vim.uv.cwd))
      "."))

(defn- join-with-slash [left right]
  (if (= (string.sub left -1) "/")
      (.. left right)
      (.. left "/" right)))

(defn- join [left right]
  (if (= left "/")
      (.. left right)
      (join-with-slash left right)))

(defn- absolute [root path]
  (if (= (string.sub path 1 1) "/")
      path
      (join root path)))

(defn- strip-private-prefix [path]
  (if (= (string.sub path 1 9) "/private/")
      (string.sub path 9)
      path))

(defn- ensure-trailing-slash [root]
  (if (= (string.sub root -1) "/") root (.. root "/")))

(defn- strip-relative-prefix [result]
  (if (= (string.sub result 1 2) "./")
      (string.sub result 3)
      result))

(defn- relative-result [path prefix]
  (if (= (string.sub path 1 (string.len prefix)) prefix)
      (string.sub path (+ (string.len prefix) 1))
      path))

(defn- relative [root path]
  (let [root (strip-private-prefix root)
        path (strip-private-prefix path)
        prefix (ensure-trailing-slash root)
        result (relative-result path prefix)]
    (strip-relative-prefix result)))

(defn- extension-matches? [path extension]
  (= (string.sub path (- (string.len extension))) extension))

(defn- matched-result [path extension result]
  (if (extension-matches? path extension)
      true
      result))

(defn- fnl-file? [path extensions]
  (var result false)
  (each [_ extension (ipairs extensions)]
    (set result (matched-result path extension result)))
  result)

(defn- clean-prefix [prefix]
  (if (= (string.sub prefix -1) "/")
      (string.sub prefix 1 -2)
      prefix))

(defn- under-prefix? [path prefix]
  (let [clean (clean-prefix prefix)]
    (or (= path clean)
        (= (string.sub path 1 (+ (string.len clean) 1)) (.. clean "/")))))

(defn- excluded-result [path prefix result]
  (if (under-prefix? path prefix)
      true
      result))

(defn- excluded? [path excludes]
  (var result (under-prefix? path ".git"))
  (each [_ prefix (ipairs excludes)]
    (set result (excluded-result path prefix result)))
  result)

(defn- hidden? [name]
  (= (string.sub name 1 1) "."))

(defn- realpath [uv path]
  (let [(resolved error) (pcall uv.fs_realpath path)]
    (if (and resolved error)
        error
        nil)))

(defn- walk-prefix [root path]
  (let [rel (relative root path)]
    (if (= rel ".")
        ""
        rel)))

(defn- record-file [path rel result seen dedupe]
  (tset seen dedupe true)
  (table.insert result {:relative rel :absolute path}))

(defn- add-file [root path rel result seen excludes extensions dedupe]
  (if (and (fnl-file? rel extensions)
           (not (excluded? rel excludes))
           (not (. seen dedupe)))
      (record-file path rel result seen dedupe)))

(defn- walk-target-result [walk-result error]
  (if error (values nil error) (values walk-result nil)))

(defn- walk-target [walk-fn root target rel result seen excludes extensions skip-dotfiles follow-symlinks visited]
  (tset visited target true)
  (walk-target-result (walk-fn root target rel result seen excludes extensions
                               skip-dotfiles follow-symlinks rel visited)))

(defn- walk-scan [walk-fn root directory prefix result seen excludes extensions skip-dotfiles follow-symlinks error-prefix visited uv handle]
  (var scanning true)
  (var failure nil)
  (while (and scanning (not failure))
    (let [(name type) (uv.fs_scandir_next handle)]
      (if (not name)
          (set scanning false)
          (if (and skip-dotfiles (hidden? name))
              nil
              (let [path (join directory name)
                    rel (if (= prefix "") name (.. prefix "/" name))]
                (if (or (and (= type "directory") (not (= name ".git")))
                        (= type "file")
                        (and follow-symlinks (= type "link")))
                    (let [target (if (= type "link") (realpath uv path) path)
                          target-stat (and target (uv.fs_stat target))]
                      (if (and target-stat (= target-stat.type "directory")
                               (not (excluded? rel excludes))
                               (not (. visited target)))
                          (let [(walk-result error) (walk-target walk-fn root target rel result seen excludes extensions
                                                                 skip-dotfiles follow-symlinks visited)]
                            (if error (set failure error)))
                          (if (and target-stat (= target-stat.type "file"))
                              (add-file root target rel result seen excludes extensions
                                        (if follow-symlinks target (relative root path)))))
                      (if (= type "file")
                          (let [target (if follow-symlinks (realpath uv path) path)
                                target-stat (and target (uv.fs_stat target))]
                            (if (and target-stat (= target-stat.type "file"))
                                (add-file root target rel result seen excludes extensions
                                          (if follow-symlinks target (relative root path)))))))))))))
  (if failure (values nil failure) (values result nil)))

(defn- walk-prefix-or-dot [prefix]
  (if (= prefix "") "." prefix))

(defn- walk-error-prefix [error-prefix prefix]
  (if error-prefix
      error-prefix
      (walk-prefix-or-dot prefix)))

(defn- walk-scan-error [error-prefix prefix]
  (values nil (.. "cannot read directory " (walk-error-prefix error-prefix prefix))))

(defn- walk [root directory prefix result seen excludes extensions skip-dotfiles follow-symlinks error-prefix visited]
  (let [uv (or vim.uv vim.loop)
        (handle scan-error) (uv.fs_scandir directory)]
    (if (not handle)
        (walk-scan-error error-prefix prefix)
        (walk-scan walk root directory prefix result seen excludes extensions skip-dotfiles follow-symlinks error-prefix visited uv handle))))

(defn- followed-link-directory [root target target-stat rel result seen excludes extensions skip-dotfiles follow-symlinks input]
  (if (and target-stat (= target-stat.type "directory"))
      (walk root target rel result seen excludes extensions skip-dotfiles follow-symlinks input {})
      nil))

(defn- followed-link-result [root target target-stat rel result seen excludes extensions skip-dotfiles follow-symlinks input]
  (if (and target-stat (= target-stat.type "file"))
      (add-file root target rel result seen excludes extensions target)
      (followed-link-directory root target target-stat rel result seen excludes extensions skip-dotfiles follow-symlinks input)))

(defn- add-followed-link [root uv abs rel result seen excludes extensions skip-dotfiles follow-symlinks input]
  (let [target (realpath uv abs)
        target-stat (and target (uv.fs_stat target))]
    (followed-link-result root target target-stat rel result seen excludes extensions skip-dotfiles follow-symlinks input)))

(defn- directory-target [uv abs follow-symlinks]
  (if follow-symlinks (realpath uv abs) abs))

(defn- directory-visited [target follow-symlinks]
  (if follow-symlinks {target true} {}))

(defn- add-directory-path [root uv abs result seen excludes extensions skip-dotfiles follow-symlinks input]
  (let [target (directory-target uv abs follow-symlinks)
        visited (directory-visited target follow-symlinks)]
    (walk root target (walk-prefix root abs) result seen excludes extensions skip-dotfiles follow-symlinks input visited)))

(defn- add-path-link [root uv abs rel result seen excludes extensions skip-dotfiles follow-symlinks input]
  (if follow-symlinks
      (add-followed-link root uv abs rel result seen excludes extensions skip-dotfiles follow-symlinks input)
      (values nil (.. rel ": symlinks are not supported"))))

(defn- add-path-stat [root uv abs rel stat result seen excludes extensions skip-dotfiles follow-symlinks input]
  (case stat.type
    "file" (add-file root abs rel result seen excludes extensions rel)
    "link" (add-path-link root uv abs rel result seen excludes extensions skip-dotfiles follow-symlinks input)
    "directory" (add-directory-path root uv abs result seen excludes extensions skip-dotfiles follow-symlinks input)
    _ nil))

(defn- add-path [root input result seen excludes extensions skip-dotfiles follow-symlinks]
  (let [uv (or vim.uv vim.loop)
        abs (absolute root input)
        stat (uv.fs_lstat abs)
        rel (relative root abs)]
    (if stat
        (add-path-stat root uv abs rel stat result seen excludes extensions skip-dotfiles follow-symlinks input)
        nil)))

(defn- sorted-files-failure [failure error]
  (or error failure))

(defn- sorted-files-success [result]
  (table.sort result (fn [a b] (< a.relative b.relative)))
  (values result nil))

(defn- sorted-files-result [failure result]
  (case (not failure)
    false (values nil failure)
    true (sorted-files-success result)))

(defn- sorted-files-step [failure input root result seen excludes extensions skip-dotfiles follow-symlinks]
  (case (not failure)
    false failure
    true (let [(path-result error) (add-path root input result seen excludes extensions skip-dotfiles follow-symlinks)]
           (sorted-files-failure failure error))))

(defn- sorted-files [root inputs excludes extensions skip-dotfiles follow-symlinks]
  (let [result [] seen {}]
    (var failure nil)
    (each [_ input (ipairs inputs)]
      (set failure (sorted-files-step failure input root result seen excludes extensions skip-dotfiles follow-symlinks)))
    (sorted-files-result failure result)))

(defn- read-file [path]
  (let [file (io.open path :r)]
    (if file
        (let [text (file:read "*a")] (file:close) (values text nil))
        (values nil {:message (.. "could not read file: " path)}))))

(defn- error-line [path error]
  (let [message (or (. error :message) (tostring error))
        line (. error :line)
        col (or (. error :col) (. error :column))]
    (if (and line col)
        (.. path ":" line ":" col ": " message)
        (.. path ": " message))))

(defn- append-path [paths path]
  (let [result []]
    (each [_ value (ipairs paths)] (table.insert result value))
    (table.insert result path)
    result))

(defn- parse-lint-value [args index state key]
  (if (>= index (length args))
      (values nil (.. "missing argument for " key))
      (let [value (. args (+ index 1))]
        (case key
          "--format"
          (if (and (not= value "text") (not= value "json"))
              (values nil "format must be text or json")
              (values (+ index 2) {:all state.all :base state.base :format value :format-seen true :paths state.paths}))
          _
          (values (+ index 2) {:all state.all :base value :format state.format :format-seen state.format-seen :paths state.paths})))))

(defn- parse-lint-args-step [args index state]
  (if (> index (length args))
      (values state nil)
      (let [arg (. args index)]
        (case arg
          "--all"
          (if state.all
              (values nil "unknown or duplicate lint flag: --all")
              (parse-lint-args-step args (+ index 1) {:all true :base state.base :format state.format :format-seen state.format-seen :paths state.paths}))
          "--base"
          (if state.base
              (values nil "unknown or duplicate lint flag: --base")
              (let [(next-index next-state-or-error) (parse-lint-value args index state "--base")]
                (if next-index
                    (parse-lint-args-step args next-index next-state-or-error)
                    (values nil next-state-or-error))))
          "--format"
          (if state.format-seen
              (values nil "unknown or duplicate lint flag: --format")
              (let [(next-index next-state-or-error) (parse-lint-value args index state "--format")]
                (if next-index
                    (parse-lint-args-step args next-index next-state-or-error)
                    (values nil next-state-or-error))))
          "--write"
          (values nil "unsupported lint flag: --write")
          "--check"
          (values nil "unsupported lint flag: --check")
          "--parser"
          (values nil "unsupported lint flag: --parser")
          _
          (if (= (string.sub arg 1 2) "--")
              (values nil (.. "unknown flag: " arg))
              (parse-lint-args-step args (+ index 1) {:all state.all :base state.base :format state.format :format-seen state.format-seen :paths (append-path state.paths arg)}))))))

(defn- parse-lint-success [state]
  (if (and state.all state.base)
      (values nil "--base cannot be used with --all")
      state))

(defn- parse-lint-result [state failure]
  (if failure
      (values nil failure)
      (parse-lint-success state)))

(defn- parse-lint-args [args]
  (let [(state failure) (parse-lint-args-step args 2 {:all false :base nil :format "text" :format-seen false :paths []})]
    (parse-lint-result state failure)))

(defn- parse-parser-option [args index]
  (values (+ index 1) (. args (+ index 1))))

(defn- parse-format-mode-value [arg]
  (if (= arg "--check") :check :write))

(defn- parse-format-mode [arg index mode parser-name]
  (if mode
      (values mode parser-name index "unknown or duplicate mode flag")
      (values (parse-format-mode-value arg) parser-name index nil)))

(defn- parse-format-parser [args index mode parser-name]
  (if (>= index (length args))
      (values mode parser-name index "missing argument for --parser")
      (let [(next-index next-parser) (parse-parser-option args index)]
        (values mode next-parser next-index nil))))

(defn- parse-format-path-value [arg index mode parser-name paths]
  (table.insert paths arg)
  (values mode parser-name index nil))

(defn- parse-format-path [arg index mode parser-name paths]
  (if (= (string.sub arg 1 2) "--")
      (values mode parser-name index (.. "unknown flag: " arg))
      (parse-format-path-value arg index mode parser-name paths)))

(defn- parse-format-arg [args arg index mode parser-name paths]
  (case arg
    "--check" (parse-format-mode arg index mode parser-name)
    "--write" (parse-format-mode arg index mode parser-name)
    "--parser" (parse-format-parser args index mode parser-name)
    _ (parse-format-path arg index mode parser-name paths)))

(defn- parse-format-success [mode parser-name paths]
  (if (not mode)
      (values nil "missing --check or --write")
      {:mode mode :parser parser-name :paths paths}))

(defn- parse-format-result [failure mode parser-name paths]
  (if failure
      (values nil failure)
      (parse-format-success mode parser-name paths)))

(defn- parse-format-args [args]
  (var mode nil)
  (var parser-name nil)
  (local paths [])
  (var i 2)
  (var failure nil)
  (while (and (<= i (length args)) (not failure))
    (let [arg (. args i)
          (next-mode next-parser next-index next-failure) (parse-format-arg args arg i mode parser-name paths)]
      (set mode next-mode)
      (set parser-name next-parser)
      (set i (+ next-index 1))
      (set failure next-failure)))
  (parse-format-result failure mode parser-name paths))

(defn- parse-args [args]
  (case (. args 1)
    "lint" (parse-lint-args args)
    "format" (parse-format-args args)
    _ (values nil (.. "unknown command: " (or (. args 1) "")))))

(defn- load-parser [name]
  (if name
      (let [(ok parser) (pcall require name)]
        (if ok parser (values nil (.. "could not require parser module: " name))))
      nil))

(defn- config-load-error [printer path error]
  (emit printer (.. path ": " (or (. error :message) (tostring error))))
  (values nil true nil))

(defn- config-for [root printer]
  (let [path (config.find root)]
    (if path
        (let [(loaded error) (config.load path)]
          (if error
              (config-load-error printer path error)
              (values loaded nil path)))
        (values {} nil nil))))

(defn- formatter-config [cfg]
  {:indents (. cfg :indents)
   :format-as (. cfg :format-as)
   :indent-patterns (. cfg :indent-patterns)
   :indent-width (. cfg :indent-width)
   :builtins (. cfg :builtins)
   :prefix-fallbacks (. cfg :prefix-fallbacks)})

(defn- normalized-path [path]
  (if (= (string.sub path 1 9) "/private/")
      (string.sub path 9)
      path))

(defn- same-path? [left right]
  (let [uv (or vim.uv vim.loop)
        left (normalized-path (or (realpath uv left) left))
        right (normalized-path (or (realpath uv right) right))]
    (= left right)))

(defn- without-config-file [files config-path]
  (if config-path
      (let [result []]
        (each [_ file (ipairs files)]
          (if (not (same-path? file.absolute config-path))
              (table.insert result file)))
        result)
      files))

(defn- temp-open-attempt [error max-attempts]
  (if (string.match (tostring error) "EEXIST")
      nil
      max-attempts))

(defn- temp-write-error [temp write-error close-error]
  (os.remove temp)
  (values nil (or write-error close-error "could not write temporary file")))

(defn- temp-write [path text]
  (let [uv (or vim.uv vim.loop)
        max-attempts 10]
    (var attempt 0)
    (var temp nil)
    (var file nil)
    (var open-error nil)
    (while (and (< attempt max-attempts) (not file))
      (set attempt (+ attempt 1))
      (set temp (.. path ".tmp-" (tostring (math.random 1000000000))))
      (let [(ok fd error) (pcall uv.fs_open temp "wx" 420)]
        (if (and ok fd)
            (set file fd)
            (let [next-attempt (temp-open-attempt error max-attempts)]
              (set open-error error)
              (if next-attempt (set attempt next-attempt))))))
    (if (not file)
        (values nil (or open-error "could not open temporary file"))
        (let [(write-ok written write-error) (pcall uv.fs_write file text)
              (close-ok close-result close-error) (pcall uv.fs_close file)]
          (if (or (not write-ok) (not written) write-error (not close-ok) (not close-result) close-error)
              (temp-write-error temp write-error close-error)
              (values temp nil))))))

(defn- record-formatted [formatted changed file source output]
  (table.insert formatted {:path file.absolute :relative file.relative :source source :text output})
  (if (not= source output)
      (table.insert changed file.relative)))

(defn- run-files-error [printer failure]
  (emit printer (error-line failure.path failure.error))
  2)

(defn- check-files [changed printer]
  (each [_ path (ipairs changed)] (emit printer path))
  (if (> (length changed) 0) 1 0))

(defn- write-failure-result [temps write-failure printer]
  (each [_ item (ipairs temps)] (os.remove item.temp))
  (emit printer (.. write-failure.path ": " write-failure.error))
  2)

(defn- rename-step [rename-failure item]
  (case (not rename-failure)
    false rename-failure
    true (let [(ok renamed error) (pcall os.rename item.temp item.path)]
           (case (or (not ok) (not renamed))
             true {:path item.relative
                   :error (or error "could not rename temporary file")}
             false nil))))

(defn- rename-files [temps]
  (var rename-failure nil)
       ;; Cross-file atomicity is limited to the staging phase.
  (each [_ item (ipairs temps)]
    (set rename-failure (or (rename-step rename-failure item) rename-failure)))
  rename-failure)

(defn- rename-failure-result [temps rename-failure printer]
  (each [_ item (ipairs temps)] (os.remove item.temp))
  (emit printer (.. rename-failure.path ": " rename-failure.error))
  2)

(defn- format-file [parser cfg file]
  (let [(source read-error) (read-file file.absolute)]
    (if read-error
        (values nil {:path file.relative :error read-error})
        (let [(ok output error) (pcall
                                 (fn []
                                   ((. formatter :format-string) source
                                    {:parser parser
                                     :config (formatter-config cfg)})))]
          (if (not ok)
              (values nil {:path file.relative :error output})
              (if error
                  (values nil {:path file.relative :error error})
                  (values {:path file.absolute :relative file.relative :source source :text output} nil)))))))

(defn- append-formatted [formatted changed item]
  (table.insert formatted item)
  (if (not= item.source item.text)
      (table.insert changed item.relative)))

(defn- write-success-result [changed printer]
  (each [_ path (ipairs changed)] (emit printer path))
  0)

(defn- write-step [write-failure item temps]
  (case (and (not write-failure) (not= item.source item.text))
    false write-failure
    true (let [(temp error) (temp-write item.path item.text)]
           (case (not temp)
             true {:path item.relative :error error}
             false (table.insert temps {:path item.path :relative item.relative :temp temp})))))

(defn- write-files-result [formatted changed printer]
  (var write-failure nil)
  (local temps [])
  (each [_ item (ipairs formatted)]
    (set write-failure (write-step write-failure item temps)))
  (if write-failure
      (write-failure-result temps write-failure printer)
      (let [rename-failure (rename-files temps)]
        (if rename-failure
            (rename-failure-result temps rename-failure printer)
            (write-success-result changed printer)))))

(defn- process-files-result [mode formatted changed printer]
  (table.sort changed)
  (if (= mode :check)
      (check-files changed printer)
      (write-files-result formatted changed printer)))

(defn- run-files-step [failure file parser cfg formatted changed]
  (case (not failure)
    false failure
    true (let [(item error) (format-file parser cfg file)]
           (case (not error)
             false error
             true (append-formatted formatted changed item)))))

(defn- run-files-result [failure mode formatted changed printer]
  (case (not failure)
    false (run-files-error printer failure)
    true (process-files-result mode formatted changed printer)))

(defn- run-files [root mode parser cfg files printer]
  (let [formatted [] changed []]
    (var failure nil)
    (each [_ file (ipairs files)]
      (set failure (run-files-step failure file parser cfg formatted changed)))
    (run-files-result failure mode formatted changed printer)))

(defn- read-lint-files [files index result]
  (if (> index (length files))
      (values result nil)
      (let [file (. files index)
            (source error) (read-file file.absolute)]
        (if error
            (values nil {:path file.relative :error error})
            (read-lint-files files (+ index 1)
                             (do (table.insert result {:path file.relative :source source})
                               result))))))

(defn- lint-discovery-error [printer error]
  (emit printer error)
  2)

(defn- lint-no-files [printer]
  (emit printer "no files found")
  2)

(defn- lint-policy-error [root config-path printer error]
  (emit printer (error-line (relative root (or config-path ".fnl-extras.fnl")) error))
  2)

(defn- lint-read-error [printer error]
  (emit printer (error-line error.path error.error))
  2)

(defn- lint-run-error [printer error]
  (emit printer (error-line error.path error))
  2)

(defn- lint-result [printer result]
  (each [_ line (ipairs result.lines)] (emit printer line))
  result.status)

(defn- parse-error-result [printer error]
  (emit printer error)
  2)

(defn- discovery-error-result [printer error]
  (emit printer error)
  2)

(defn- no-files-result [printer]
  (emit printer "no files found")
  2)

(defn- parser-error-result [printer error]
  (emit printer error)
  2)

(defn- trim-newlines [text]
  (string.gsub text "\n+$" ""))

(defn- git-command [root args]
  (.. "git -C " (vim.fn.shellescape root) " "
      (table.concat (icollect [_ arg (ipairs args)] (vim.fn.shellescape arg)) " ")))

(defn- git-output [output marker]
  (case (not marker)
    true (values output 2)
    false (values (string.sub output 1 (- marker 1))
                  (tonumber (string.sub output (+ marker 15))))))

(defn- git-read-output [file]
  (if file (file:read "*a") ""))

(defn- git-call [root args]
  (let [file (io.popen (.. (git-command root args) " </dev/null 2>&1; printf '\\n__ECA_STATUS__%s' $?"))
        output (git-read-output file)]
    (and file (file:close))
    (git-output output (string.find output "\n__ECA_STATUS__"))))

(defn- git-root [start]
  (let [(output status) (git-call start ["rev-parse" "--show-toplevel"])]
    (if (= status 0)
        (trim-newlines output)
        nil)))

(defn- git-error [message]
  {:message message})

(defn- git-plan-changed [root parsed]
  (let [base (or parsed.base "HEAD")
        (resolved resolved-status) (git-call root ["rev-parse" "--verify" (.. base "^{commit}")])]
    (if (not= resolved-status 0)
        (values nil (git-error (.. "unknown base ref: " base)))
        (let [(status-text status-code) (git-call root ["diff" "--name-status" "-z" "--find-renames" "--find-copies" base "--"])
              (untracked-text untracked-code) (git-call root ["ls-files" "--others" "--exclude-standard" "-z"])]
          (if (or (not= status-code 0) (not= untracked-code 0))
              (values nil (git-error "could not inspect Git changes"))
              (let [records (lint-selection.parse-name-status status-text)
                    untracked (lint-selection.parse-untracked untracked-text)]
                (values {:root root
                         :records records
                         :untracked untracked
                         :plan (lint-selection.plan records untracked)}
                        nil)))))))

(defn- git-plan [start parsed]
  (let [root (git-root start)]
    (if (= root nil)
        (values nil (git-error "lint requires a Git repository"))
        (let [(shallow shallow-status) (git-call root ["rev-parse" "--is-shallow-repository"])]
          (if (and (= shallow-status 0) (= (trim-newlines shallow) "true"))
              (values nil (git-error "lint requires a full clone; shallow repositories are not supported"))
              (if parsed.all
                  (values {:root root} nil)
                  (git-plan-changed root parsed)))))))

(defn- path-present? [paths path index]
  (if (> index (length paths)) false
      (= path (. paths index)) true
      (path-present? paths path (+ index 1))))

(defn- changed-file [root base file whole?]
  (if whole?
      {:path file.path :source file.source :selection true}
      (let [(patch status) (git-call root ["diff" "--unified=0" "--no-color" "--no-ext-diff" base "--" file.path])]
        (if (= status 0)
            {:path file.path :source file.source
             :selection (lint-selection.parse-hunks patch)}
            nil))))

(defn- append-selected [result selected]
  (table.insert result selected)
  result)

(defn- changed-files [root base files plan index result]
  (if (> index (length files))
      result
      (let [file (. files index)
            whole? (path-present? plan.whole file.path 1)
            hunk? (path-present? plan.hunks file.path 1)]
        (if (or whole? hunk?)
            (let [selected (changed-file root base file whole?)]
              (if selected
                  (changed-files root base files plan (+ index 1)
                                 (append-selected result selected))
                  (changed-files root base files plan (+ index 1) result)))
            (changed-files root base files plan (+ index 1) result)))))

(defn- emit-git-error [printer error]
  (emit printer error.message)
  2)

(defn- scope-paths [plan]
  (let [result []]
    (each [_ path (ipairs plan.whole)] (table.insert result path))
    (each [_ path (ipairs plan.hunks)] (table.insert result path))
    (each [_ path (ipairs plan.deleted)] (table.insert result path))
    result))

(defn- lint-git-info [root parsed require-git?]
  (if require-git?
      (git-plan root parsed)
      (values {:root root} nil)))

(defn- run-lint [root parsed cfg config-path printer require-git?]
  (let [(git-info git-error-value) (lint-git-info root parsed require-git?)]
    (if git-error-value
        (emit-git-error printer git-error-value)
        (let [git-info (or git-info {:root root :plan {:whole [] :hunks [] :deleted []}})
              git-root-path git-info.root
              inputs (if (> (length parsed.paths) 0) parsed.paths (or (. cfg :paths) ["."]))
              extensions (or (. cfg :extensions) [".fnl" ".fnlm"])
              skip-dotfiles (if (= (. cfg :skip-dotfiles) nil) true (. cfg :skip-dotfiles))
              follow-symlinks (if (= (. cfg :follow-symlinks) nil) false (. cfg :follow-symlinks))
              (discovered discovery-error) (sorted-files git-root-path inputs (or (. cfg :exclude) []) extensions
                                                         skip-dotfiles follow-symlinks)
              files (and discovered (without-config-file discovered config-path))]
          (if discovery-error
              (lint-discovery-error printer discovery-error)
              (let [(policy policy-error) (config.lint-policy cfg)]
                (if policy-error
                    (lint-policy-error git-root-path config-path printer policy-error)
                    (let [(sources read-error) (read-lint-files files 1 [])]
                      (if read-error
                          (lint-read-error printer read-error)
                          (let [selected (if parsed.all
                                             sources
                                             (changed-files git-root-path (or parsed.base "HEAD") sources
                                                            git-info.plan 1 []))
                                paths (if parsed.all nil (scope-paths git-info.plan))
                                (result error) (lint-run.lint-files selected policy
                                                                    (and config-path (relative git-root-path config-path))
                                                                    parsed.format paths)]
                            (if error
                                (lint-run-error printer error)
                                (lint-result printer result))))))))))))

(defn run [args opts]
  (let [opts (or opts {}) printer (or (. opts :print) default-print) root (or (. opts :cwd) (cwd))
        (parsed parse-error) (parse-args args)]
    (if parse-error
        (parse-error-result printer parse-error)
        (let [(cfg config-error config-path) (config-for root printer)]
          (if config-error
              2
              (if (= (. args 1) "lint")
                  (run-lint root parsed cfg config-path printer (not (. opts :print)))
                  (let [inputs (if (> (length parsed.paths) 0) parsed.paths (or (. cfg :paths) ["."]))
                        extensions (or (. cfg :extensions) [".fnl" ".fnlm"])
                        skip-dotfiles (if (= (. cfg :skip-dotfiles) nil) true (. cfg :skip-dotfiles))
                        follow-symlinks (if (= (. cfg :follow-symlinks) nil) false (. cfg :follow-symlinks))
                        (discovered discovery-error) (sorted-files root inputs (or (. cfg :exclude) []) extensions
                                                                   skip-dotfiles follow-symlinks)
                        files (and discovered (without-config-file discovered config-path))]
                    (if discovery-error
                        (discovery-error-result printer discovery-error)
                        (if (= (length files) 0)
                            (no-files-result printer)
                            (let [(parser parser-error) (load-parser (or parsed.parser (. cfg :parser)))]
                              (if parser-error
                                  (parser-error-result printer parser-error)
                                  (run-files root parsed.mode parser cfg files printer))))))))))))