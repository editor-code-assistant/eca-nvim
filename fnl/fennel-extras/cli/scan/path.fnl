(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.cli.scan.path)

(defn cwd
  []
  (or (and vim vim.loop (vim.loop.cwd))
      (and vim vim.uv (vim.uv.cwd))
      "."))

(defn- join-with-slash
  [left right]
  (if (= (string.sub left -1) "/")
    (.. left right)
    (.. left "/" right)))

(defn join
  [left right]
  (if (= left "/")
    (.. left right)
    (join-with-slash left right)))

(defn absolute
  [root path]
  (if (= (string.sub path 1 1) "/")
    path
    (join root path)))

(defn- strip-private-prefix
  [path]
  (if (= (string.sub path 1 9) "/private/")
    (string.sub path 9)
    path))

(defn- ensure-trailing-slash
  [root]
  (if (= (string.sub root -1) "/")
    root
    (.. root "/")))

(defn- strip-relative-prefix
  [result]
  (if (= (string.sub result 1 2) "./")
    (string.sub result 3)
    result))

(defn- relative-result
  [path prefix]
  (if (= (string.sub path 1 (string.len prefix)) prefix)
    (string.sub path (+ (string.len prefix) 1))
    path))

(defn relative
  [root path]
  (let [root   (strip-private-prefix root) path   (strip-private-prefix path) prefix (ensure-trailing-slash root) result (relative-result path prefix)]
    (strip-relative-prefix result)))

(defn- extension-matches?
  [path extension]
  (= (string.sub path (- (string.len extension))) extension))

(defn fnl-file?
  [path extensions]
  (accumulate [result false _ extension (ipairs extensions)]
    (or result
        (extension-matches? path extension))))

(defn- clean-prefix
  [prefix]
  (if (= (string.sub prefix -1) "/")
    (string.sub prefix 1 -2)
    prefix))

(defn- under-prefix?
  [path prefix]
  (let [clean (clean-prefix prefix)]
    (or (= path clean)
        (= (string.sub path 1 (+ (string.len clean) 1)) (.. clean "/")))))

(defn- excluded-result
  [path prefix result]
  (if (under-prefix? path prefix)
    true
    result))

(defn- excluded-any?
  [path excludes index result]
  (if (> index (length excludes))
    result
    (excluded-any? path excludes (+ index 1) (excluded-result path (. excludes index) result))))

(defn excluded?
  [path excludes]
  (excluded-any? path excludes 1 (under-prefix? path ".git")))

(defn hidden?
  [name]
  (= (string.sub name 1 1) "."))

(defn realpath
  [uv path]
  (let [(ok resolved) (pcall uv.fs_realpath path)]
    (when ok
      resolved)))

(defn walk-prefix
  [root path]
  (let [rel (relative root path)]
    (if (= rel ".")
      ""
      rel)))
