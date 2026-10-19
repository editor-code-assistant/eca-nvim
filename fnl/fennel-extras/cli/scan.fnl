(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.cli.scan)


(defn cwd []
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
  (if (= (string.sub root -1) "/")
    root
    (.. root "/")))

(defn- strip-relative-prefix [result]
  (if (= (string.sub result 1 2) "./")
    (string.sub result 3)
    result))

(defn- relative-result [path prefix]
  (if (= (string.sub path 1 (string.len prefix)) prefix)
    (string.sub path (+ (string.len prefix) 1))
    path))

(defn relative [root path]
  (let [root   (strip-private-prefix root)
        path   (strip-private-prefix path)
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
  (accumulate [result false _ extension (ipairs extensions)]
    (or result (extension-matches? path extension))))

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

(defn- excluded-any? [path excludes index result]
  (if (> index (length excludes))
    result
    (excluded-any? path excludes (+ index 1)
                   (excluded-result path (. excludes index) result))))

(defn- excluded? [path excludes]
  (excluded-any? path excludes 1 (under-prefix? path ".git")))

(defn- hidden? [name]
  (= (string.sub name 1 1) "."))

(defn realpath [uv path]
  (let [(ok resolved) (pcall uv.fs_realpath path)]
    (if ok resolved nil)))

(defn- walk-prefix [root path]
  (let [rel (relative root path)]
    (if (= rel ".")
      ""
      rel)))

(defn- scan-acc [acc result]
  {:result result :seen (. acc :seen) :visited (. acc :visited)})

(defn- record-file [acc path rel dedupe]
  (tset acc.seen dedupe true)
  (table.insert acc.result {:relative rel :absolute path})
  (scan-acc acc acc.result))

(defn- add-file [ctx acc path target]
  (if (and (fnl-file? target.rel (. ctx :extensions))
           (not (excluded? target.rel (. ctx :excludes)))
           (not (. acc.seen target.dedupe)))
    (record-file acc path target.rel target.dedupe)
    (scan-acc acc acc.result)))

(defn- walk-target [ctx acc entry]
  (let [visited acc.visited
        _       (tset visited entry.path true)
        target  {:directory entry.path :prefix entry.rel :path entry.path :rel entry.rel
                 :error-prefix entry.rel}]
    ((. ctx :walk) ctx acc target)))

(defn- scan-directory-target [ctx acc entry target-stat]
  (if (and (= target-stat.type "directory")
           (not (excluded? entry.rel (. ctx :excludes)))
           (not (. acc.visited entry.path)))
    (walk-target ctx acc entry)
    (values (scan-acc acc acc.result) nil)))

(defn- scan-file-dedupe [ctx entry target]
  (if (. ctx :follow-symlinks) target (relative (. ctx :root) entry.path)))

(defn- add-scan-file [ctx acc entry target]
  (add-file ctx acc target {:rel entry.rel :dedupe (scan-file-dedupe ctx entry target)}))

(defn- scan-file-target [ctx acc entry target-stat]
  (if (= target-stat.type "file")
    (add-scan-file ctx acc entry entry.target)
    (scan-acc acc acc.result)))

(defn- scan-entry-target-stat [ctx target]
  (let [uv (. ctx :uv)]
    (and target (uv.fs_stat target))))

(defn- scan-target-entry [entry target]
  {:directory entry.directory :prefix entry.prefix :name entry.name :type entry.type
   :path target :target target :rel entry.rel :error-prefix entry.error-prefix})

(defn- scan-target-stat-result [ctx acc entry target-stat]
  (case target-stat.type
    "directory" (scan-directory-target ctx acc entry target-stat)
    "file"      (scan-file-target ctx acc entry target-stat)
    _           (values (scan-acc acc acc.result) nil)))

(defn- scan-target-stat [ctx acc entry target]
  (let [target-stat  (scan-entry-target-stat ctx target)
        target-entry (and target-stat (scan-target-entry entry target))]
    (if target-stat
      (scan-target-stat-result ctx acc target-entry target-stat)
      (values (scan-acc acc acc.result) nil))))

(defn- scan-entry-target-path [ctx entry]
  (if (= entry.type "link") (realpath (. ctx :uv) entry.path) entry.path))

(defn- scan-entry-target [ctx acc entry]
  (let [target (scan-entry-target-path ctx entry)]
    (scan-target-stat ctx acc entry target)))

(defn- scan-entry-rel [prefix name]
  (if (= prefix "") name (.. prefix "/" name)))

(defn- scan-entry-eligible [ctx acc entry]
  (let [eligible (or (and (= entry.type "directory") (not (= entry.name ".git")))
                     (= entry.type "file")
                     (and (. ctx :follow-symlinks) (= entry.type "link")))]
    (if eligible
      (scan-entry-target ctx acc entry)
      (values (scan-acc acc acc.result) nil))))

(defn- scan-entry-path [ctx acc entry]
  (let [path  (join entry.directory entry.name)
        rel   (scan-entry-rel entry.prefix entry.name)
        child {:directory entry.directory :prefix entry.prefix :name entry.name :type entry.type
               :path path :rel rel :error-prefix entry.error-prefix}]
    (scan-entry-eligible ctx acc child)))

(defn- scan-entry [ctx acc entry]
  (if (and (. ctx :skip-dotfiles) (hidden? entry.name))
    (values (scan-acc acc acc.result) nil)
    (scan-entry-path ctx acc entry)))

(defn- scan-entry-data [entry name type]
  {:directory entry.directory :prefix entry.prefix :name name :type type :error-prefix entry.error-prefix})

(defn- walk-scan-step-result [ctx acc entry handle]
  (let [(next-acc error) (scan-entry ctx acc entry)]
    (if error
      (values nil error)
      ((. ctx :step) ctx next-acc entry handle))))

(defn- walk-scan-step [ctx acc entry handle]
  (let [uv          (. ctx :uv)
        (name type) (uv.fs_scandir_next handle)]
    (if (not name)
      (values (scan-acc acc acc.result) nil)
      (walk-scan-step-result ctx acc (scan-entry-data entry name type) handle))))

(defn- walk-scan [ctx acc entry handle]
  (walk-scan-step ctx acc entry handle))

(defn- walk-prefix-or-dot [prefix]
  (if (= prefix "") "." prefix))

(defn- walk-error-prefix [error-prefix prefix]
  (if error-prefix
    error-prefix
    (walk-prefix-or-dot prefix)))

(defn- walk-scan-error [error-prefix prefix]
  (values nil (.. "cannot read directory " (walk-error-prefix error-prefix prefix))))

(defn- walk [ctx acc entry]
  (let [uv           (. ctx :uv)
        (handle err) (uv.fs_scandir entry.directory)
        error-prefix (or entry.error-prefix (. ctx :error-prefix))]
    (if (not handle)
      (walk-scan-error error-prefix entry.prefix)
      (walk-scan ctx acc entry handle))))

(defn- followed-link-entry [entry]
  {:directory entry.target :prefix entry.rel :path entry.target :rel entry.rel
   :error-prefix entry.error-prefix})

(defn- followed-link-directory [ctx acc entry target-stat]
  (if (= target-stat.type "directory")
    (walk ctx acc (followed-link-entry entry))
    nil))

(defn- followed-link-result [ctx acc entry target-stat]
  (if (= target-stat.type "file")
    (add-file ctx acc entry.target {:rel entry.rel :dedupe entry.target})
    (followed-link-directory ctx acc entry target-stat)))

(defn- add-followed-link [ctx acc entry]
  (let [uv           (. ctx :uv)
        target       (realpath uv entry.path)
        target-stat  (and target (uv.fs_stat target))
        target-entry (and target-stat (scan-target-entry entry target))]
    (if target-stat
      (followed-link-result ctx acc target-entry target-stat)
      (values (scan-acc acc acc.result) nil))))

(defn- directory-target [ctx path]
  (if (. ctx :follow-symlinks) (realpath (. ctx :uv) path) path))

(defn- directory-visited [ctx target]
  (if (. ctx :follow-symlinks) {target true} {}))

(defn- add-directory-path [ctx acc entry]
  (let [target          (directory-target ctx entry.path)
        visited         (directory-visited ctx target)
        next-acc        {:result acc.result :seen acc.seen :visited visited}
        directory-entry {:directory target :prefix (walk-prefix (. ctx :root) entry.path)
                         :path target :rel entry.rel :error-prefix entry.error-prefix}]
    (walk ctx next-acc directory-entry)))

(defn- add-path-link [ctx acc entry]
  (if (. ctx :follow-symlinks)
    (add-followed-link ctx acc entry)
    (values nil (.. entry.rel ": symlinks are not supported"))))

(defn- add-path-stat [ctx acc entry stat]
  (case stat.type
    "file"      (add-file ctx acc entry.path {:rel entry.rel :dedupe entry.rel})
    "link"      (add-path-link ctx acc entry)
    "directory" (add-directory-path ctx acc entry)
    _           (values acc nil)))

(defn- add-path [ctx acc input]
  (let [uv    (. ctx :uv)
        abs   (absolute (. ctx :root) input)
        stat  (uv.fs_lstat abs)
        rel   (relative (. ctx :root) abs)
        entry {:directory abs :prefix "" :name input :type (and stat stat.type) :path abs :rel rel
               :error-prefix input}]
    (if stat
      (add-path-stat ctx acc entry stat)
      (values (scan-acc acc acc.result) nil))))

(defn- sorted-files-failure [failure error]
  (or error failure))

(defn- sorted-files-success [result]
  (table.sort result (fn [a b] (< a.relative b.relative)))
  (values result nil))

(defn- sorted-files-result [failure result]
  (case (not failure)
    false (values nil failure)
    true  (sorted-files-success result)))

(defn- sorted-files-add [ctx state input]
  (let [(next-acc error) (add-path ctx state.acc input)
        acc              (or next-acc state.acc)]
    {:acc acc :failure (sorted-files-failure state.failure error)}))

(defn- sorted-files-step [ctx state input]
  (if state.failure
    state
    (sorted-files-add ctx state input)))

(defn- sorted-files-loop [ctx inputs index state]
  (if (> index (length inputs))
    (sorted-files-result state.failure state.acc.result)
    (sorted-files-loop ctx inputs (+ index 1) (sorted-files-step ctx state (. inputs index)))))

(defn sorted-files [root inputs options]
  (let [uv    (or vim.uv vim.loop)
        ctx   {:walk walk :step walk-scan-step :root root :excludes (. options :excludes)
               :extensions (. options :extensions) :skip-dotfiles (. options :skip-dotfiles)
               :follow-symlinks (. options :follow-symlinks) :error-prefix nil :uv uv}
        acc   {:result [] :seen {} :visited {}}
        state {:acc acc :failure nil}]
    (sorted-files-loop ctx inputs 1 state)))
