(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.cli.fs)

(local table-copy (require :fennel-extras.cli.table))

(defn- read-open-file
  [file]
  (let [text (file:read "*a")]
    (file:close)
    (values text nil)))

(defn read-file
  [path]
  (let [file (io.open path :r)]
    (if file
      (read-open-file file)
      (values nil {:message (.. "could not read file: " path)}))))

(defn- temp-write-error
  [temp write-error close-error]
  (os.remove temp)
  (values nil (or write-error close-error "could not write temporary file")))

(defn- temp-open-error
  [state]
  (if (string.match (tostring state.error) "EEXIST")
    (state.loop-fn (table-copy.update state {:attempt (+ state.attempt 1)}))
    (values nil nil state.error)))

(defn- temp-open-result
  [state]
  (if (and state.ok state.fd)
    (values state.temp state.fd nil)
    (temp-open-error state)))

(defn- temp-open-attempt
  [state]
  (let [temp          (.. state.path ".tmp-" (tostring (math.random 1000000000)))
        (ok fd error) (pcall state.uv.fs_open temp "wx" 420)]
    (temp-open-result (table-copy.update state {:temp temp :ok ok :fd fd :error error}))))

(defn- temp-open-loop
  [state]
  (if (> state.attempt state.max-attempts)
    (values nil nil "could not open temporary file")
    (temp-open-attempt state)))

(defn- temp-write-open
  [uv temp file text]
  (let [(write-ok written write-error)      (pcall uv.fs_write file text)
        (close-ok close-result close-error) (pcall uv.fs_close file)]
    (if (or (not write-ok) (not written) write-error (not close-ok) (not close-result) close-error)
      (temp-write-error temp write-error close-error)
      (values temp nil))))

(defn temp-write
  [path text]
  (let [uv                     (or vim.uv vim.loop)
        (temp file open-error) (temp-open-loop {:loop-fn temp-open-loop :uv uv :path path :attempt 1 :max-attempts 10})]
    (if open-error
      (values nil open-error)
      (temp-write-open uv temp file text))))
