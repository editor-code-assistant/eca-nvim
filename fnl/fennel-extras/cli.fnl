(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.cli)

(local config (require :fennel-extras.config))
(local formatter (require :fennel-extras.format))

(defn- emit [printer line]
  (printer line))

(defn- cwd []
  (or (and vim vim.loop (vim.loop.cwd))
      (and vim vim.uv (vim.uv.cwd))
      "."))

(defn- join [left right]
  (if (= left "/")
      (.. left right)
      (if (= (string.sub left -1) "/")
          (.. left right)
          (.. left "/" right))))

(defn- absolute [root path]
  (if (= (string.sub path 1 1) "/")
      path
      (join root path)))

(defn- relative [root path]
  (let [root (if (= (string.sub root 1 9) "/private/") (string.sub root 9) root)
        path (if (= (string.sub path 1 9) "/private/") (string.sub path 9) path)
        prefix (if (= (string.sub root -1) "/") root (.. root "/"))
        result (if (= (string.sub path 1 (string.len prefix)) prefix)
                   (string.sub path (+ (string.len prefix) 1))
                   path)]
    (if (= (string.sub result 1 2) "./")
        (string.sub result 3)
        result)))

(defn- fnl-file? [path extensions]
  (var result false)
  (each [_ extension (ipairs extensions)]
    (if (= (string.sub path (- (string.len extension))) extension)
        (set result true)))
  result)

(defn- under-prefix? [path prefix]
  (let [clean (if (= (string.sub prefix -1) "/")
                  (string.sub prefix 1 -2)
                  prefix)]
    (or (= path clean)
        (= (string.sub path 1 (+ (string.len clean) 1)) (.. clean "/")))))

(defn- excluded? [path excludes]
  (var result (under-prefix? path ".git"))
  (each [_ prefix (ipairs excludes)]
    (if (under-prefix? path prefix)
        (set result true)))
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

(defn- add-file [root path rel result seen excludes extensions dedupe]
  (if (and (fnl-file? rel extensions)
           (not (excluded? rel excludes))
           (not (. seen dedupe)))
      (do (tset seen dedupe true)
        (table.insert result {:relative rel :absolute path}))))

(defn- walk [root directory prefix result seen excludes extensions skip-dotfiles follow-symlinks error-prefix visited]
  (let [uv (or vim.uv vim.loop)
        (handle scan-error) (uv.fs_scandir directory)]
    (if (not handle)
        (values nil (.. "cannot read directory " (or error-prefix (if (= prefix "") "." prefix))))
        (do
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
                                  (do (tset visited target true)
                                    (let [(walk-result error) (walk root target rel result seen excludes extensions
                                                                    skip-dotfiles follow-symlinks rel visited)]
                                      (if error (set failure error))))
                                  (if (and target-stat (= target-stat.type "file"))
                                      (add-file root target rel result seen excludes extensions
                                                (if follow-symlinks target (relative root path)))))
                              (if (= type "file")
                                  (let [target (if follow-symlinks (realpath uv path) path)
                                        target-stat (and target (uv.fs_stat target))]
                                    (if (and target-stat (= target-stat.type "file"))
                                        (add-file root target rel result seen excludes extensions
                                                  (if follow-symlinks target (relative root path)))))))))))))
          (if failure (values nil failure) (values result nil))))))

(defn- add-path [root input result seen excludes extensions skip-dotfiles follow-symlinks]
  (let [uv (or vim.uv vim.loop)
        abs (absolute root input)
        stat (uv.fs_lstat abs)
        rel (relative root abs)]
    (if stat
        (if (= stat.type "file")
            (add-file root abs rel result seen excludes extensions rel)
            (if (= stat.type "link")
                (if follow-symlinks
                    (let [target (realpath uv abs)
                          target-stat (and target (uv.fs_stat target))]
                      (if (and target-stat (= target-stat.type "file"))
                          (add-file root target rel result seen excludes extensions target)
                          (if (and target-stat (= target-stat.type "directory"))
                              (walk root target rel result seen excludes extensions skip-dotfiles follow-symlinks input {})
                              nil)))
                    (values nil (.. rel ": symlinks are not supported")))
                (if (= stat.type "directory")
                    (let [target (if follow-symlinks (realpath uv abs) abs)
                          visited (if follow-symlinks {target true} {})]
                      (walk root target (walk-prefix root abs) result seen excludes extensions skip-dotfiles follow-symlinks input visited))
                    nil)))
        nil)))

(defn- sorted-files [root inputs excludes extensions skip-dotfiles follow-symlinks]
  (let [result [] seen {}]
    (var failure nil)
    (each [_ input (ipairs inputs)]
      (if (not failure)
          (let [(path-result error) (add-path root input result seen excludes extensions skip-dotfiles follow-symlinks)]
            (if error (set failure error)))))
    (if failure
        (values nil failure)
        (do (table.sort result (fn [a b] (< a.relative b.relative)))
          (values result nil)))))

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

(defn- parse-args [args]
  (let [command (. args 1)]
    (if (not= command "format")
        (values nil (.. "unknown command: " (or command "")))
        (let []
          (var mode nil)
          (var parser-name nil)
          (local paths [])
          (var i 2)
          (var failure nil)
          (while (and (<= i (length args)) (not failure))
            (let [arg (. args i)]
              (if (or (= arg "--check") (= arg "--write"))
                  (if mode
                      (set failure "unknown or duplicate mode flag")
                      (set mode (if (= arg "--check") :check :write)))
                  (if (= arg "--parser")
                      (if (>= i (length args))
                          (set failure "missing argument for --parser")
                          (do (set i (+ i 1)) (set parser-name (. args i))))
                      (if (= (string.sub arg 1 2) "--")
                          (set failure (.. "unknown flag: " arg))
                          (table.insert paths arg)))))
            (set i (+ i 1)))
          (if failure
              (values nil failure)
              (if (not mode)
                  (values nil "missing --check or --write")
                  {:mode mode :parser parser-name :paths paths}))))))

(defn- load-parser [name]
  (if name
      (let [(ok parser) (pcall require name)]
        (if ok parser (values nil (.. "could not require parser module: " name))))
      nil))

(defn- config-for [root printer]
  (let [path (config.find root)]
    (if path
        (let [(loaded error) (config.load path)]
          (if error
              (do (emit printer (.. path ": " (or (. error :message) (tostring error))))
                (values nil true nil))
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
            (do
              (set open-error error)
              (if (not (string.match (tostring error) "EEXIST"))
                  (set attempt max-attempts))))))
    (if (not file)
        (values nil (or open-error "could not open temporary file"))
        (let [(write-ok written write-error) (pcall uv.fs_write file text)
              (close-ok close-result close-error) (pcall uv.fs_close file)]
          (if (or (not write-ok) (not written) write-error (not close-ok) (not close-result) close-error)
              (do (os.remove temp)
                (values nil (or write-error close-error "could not write temporary file")))
              (values temp nil))))))

(defn- run-files [root mode parser cfg files printer]
  (let [formatted [] changed []]
    (var failure nil)
    (each [_ file (ipairs files)]
      (if (not failure)
          (let [(source read-error) (read-file file.absolute)]
            (if read-error
                (set failure {:path file.relative :error read-error})
                (let [(ok output error) (pcall
                                         (fn []
                                           ((. formatter :format-string) source
                                            {:parser parser
                                             :config (formatter-config cfg)})))]
                  (if (not ok)
                      (set failure {:path file.relative :error output})
                      (let []
                        (if error
                            (set failure {:path file.relative :error error})
                            (do
                              (table.insert formatted {:path file.absolute :relative file.relative :source source :text output})
                              (if (not= source output)
                                  (table.insert changed file.relative)))))))))))
    (if failure
        (do (emit printer (error-line failure.path failure.error)) 2)
        (do
          (table.sort changed)
          (if (= mode :check)
              (do (each [_ path (ipairs changed)] (emit printer path)) (if (> (length changed) 0) 1 0))
              (do
                (var write-failure nil)
                (local temps [])
                (each [_ item (ipairs formatted)]
                  (if (and (not write-failure) (not= item.source item.text))
                      (let [(temp error) (temp-write item.path item.text)]
                        (if temp
                            (table.insert temps {:path item.path :relative item.relative :temp temp})
                            (set write-failure {:path item.relative :error error})))))
                (if write-failure
                    (do
                      (each [_ item (ipairs temps)] (os.remove item.temp))
                      (emit printer (.. write-failure.path ": " write-failure.error))
                      2)
                    (do
                      (var rename-failure nil)
                      ;; Cross-file atomicity is limited to the staging phase.
                      (each [_ item (ipairs temps)]
                        (if (not rename-failure)
                            (let [(ok renamed error) (pcall os.rename item.temp item.path)]
                              (if (or (not ok) (not renamed))
                                  (set rename-failure {:path item.relative
                                                       :error (or error "could not rename temporary file")})))))
                      (if rename-failure
                          (do
                            (each [_ item (ipairs temps)] (os.remove item.temp))
                            (emit printer (.. rename-failure.path ": " rename-failure.error))
                            2)
                          (do (each [_ path (ipairs changed)] (emit printer path)) 0))))))))))

(defn run [args opts]
  (let [opts (or opts {}) printer (or (. opts :print) print) root (or (. opts :cwd) (cwd))
        (parsed parse-error) (parse-args args)]
    (if parse-error
        (do (emit printer parse-error) 2)
        (let [(cfg config-error config-path) (config-for root printer)]
          (if config-error
              2
              (let [inputs (if (> (length parsed.paths) 0) parsed.paths (or (. cfg :paths) ["."]))
                    extensions (or (. cfg :extensions) [".fnl" ".fnlm"])
                    skip-dotfiles (if (= (. cfg :skip-dotfiles) nil) true (. cfg :skip-dotfiles))
                    follow-symlinks (if (= (. cfg :follow-symlinks) nil) false (. cfg :follow-symlinks))
                    (discovered discovery-error) (sorted-files root inputs (or (. cfg :exclude) []) extensions
                                                               skip-dotfiles follow-symlinks)
                    files (and discovered (without-config-file discovered config-path))]
                (if discovery-error
                    (do (emit printer discovery-error) 2)
                    (if (= (length files) 0)
                        (do (emit printer "no files found") 2)
                        (let [(parser parser-error) (load-parser (or parsed.parser (. cfg :parser)))]
                          (if parser-error
                              (do (emit printer parser-error) 2)
                              (run-files root parsed.mode parser cfg files printer)))))))))))