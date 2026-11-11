(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.config.find)

(defn- join-path
  [dir name]
  (if (= (string.sub dir -1) "/")
    (.. dir name)
    (.. dir "/" name)))

(defn- close-file
  [file]
  (file:close)
  true)

(defn- exists?
  [path]
  (let [uv (or (and vim vim.loop) (and vim vim.uv))]
    (if uv
      (not= nil (uv.fs_stat path))
      (do (local file (io.open path :r))
        (or (and file (close-file file))
            false)))))

(defn- git-marker?
  [dir]
  (or (exists? (join-path dir ".git"))
      (exists? (join-path (join-path dir ".git") "HEAD"))))

(defn- parent-dir
  [dir]
  (let [trimmed (if (and (> (string.len dir) 1) (= (string.sub dir -1) "/"))
                  (string.sub dir 1 -2)
                  dir)
        parent  (string.match trimmed "^(.*)/[^/]+$")]
    (when parent
          (if (= parent "")
            "/"
            parent))))

(defn- find-in
  [dir]
  (let [candidate (join-path dir ".fnl-extras.fnl")]
    (or (and (exists? candidate) candidate)
        (when (not (git-marker? dir))
              (do (local parent (parent-dir dir))
                (when parent
                      (find-in parent)))))))

(defn find
  [start-dir]
  (find-in start-dir))
