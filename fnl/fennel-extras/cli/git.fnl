(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.cli.git)

(local lint-selection (require :fennel-extras.lint.selection))
(local table-copy (require :fennel-extras.cli.table))

(defn- trim-newlines
  [text]
  (string.gsub text "\n+$" ""))

(defn- git-arguments
  [args]
  (icollect [_ arg (ipairs args)] (vim.fn.shellescape arg)))

(defn- git-command
  [root args]
  (let [escaped (git-arguments args)]
    (.. "git -C " (vim.fn.shellescape root) " " (table.concat escaped " "))))

(defn- git-output
  [output marker]
  (case (not marker)
    true  (values output 2)
    false (values (string.sub output 1 (- marker 1)) (tonumber (string.sub output (+ marker 15))))))

(defn- git-read-output
  [file]
  (if file
    (file:read "*a")
    ""))

(defn- git-call
  [root args]
  (let [file   (io.popen (.. (git-command root args) " </dev/null 2>&1; printf '\\n__ECA_STATUS__%s' $?"))
        output (git-read-output file)]
    (when file (file:close))
    (git-output output (string.find output "\n__ECA_STATUS__"))))

(defn- git-root
  [start]
  (let [(output status) (git-call start ["rev-parse" "--show-toplevel"])]
    (when (= status 0)
      (trim-newlines output))))

(defn- git-plan-change-success
  [ctx status-text untracked-text]
  (let [records   (lint-selection.parse-name-status status-text)
        untracked (lint-selection.parse-untracked untracked-text)]
    (values {:root ctx.root :records records :untracked untracked :plan (lint-selection.plan records untracked)}
            nil)))

(defn- git-plan-change-data
  [ctx status]
  (if (or (not= status.status-code 0) (not= status.untracked-code 0))
    (values nil {:message "could not inspect Git changes"})
    (git-plan-change-success ctx status.status-text status.untracked-text)))

(defn- git-plan-changed-data
  [ctx]
  (let [(status-text status-code)       (git-call ctx.root ["diff" "--name-status" "-z" "--find-renames" "--find-copies" ctx.base "--"])
        (untracked-text untracked-code) (git-call ctx.root ["ls-files" "--others" "--exclude-standard" "-z"])
        status                          {:status-text status-text :status-code status-code :untracked-text untracked-text :untracked-code untracked-code}]
    (git-plan-change-data ctx status)))

(defn- git-plan-changed
  [ctx]
  (let [(_ resolved-status) (git-call ctx.root ["rev-parse" "--verify" (.. ctx.base "^{commit}")])]
    (if (= resolved-status 0)
      (git-plan-changed-data ctx)
      (values nil {:message (.. "unknown base ref: " ctx.base)}))))

(defn- git-plan-root-mode
  [ctx]
  (if ctx.parsed.all
    (values {:root ctx.root} nil)
    (git-plan-changed ctx)))

(defn- git-plan-root
  [ctx shallow shallow-status]
  (if (and (= shallow-status 0) (= (trim-newlines shallow) "true"))
    (values nil {:message "lint requires a full clone; shallow repositories are not supported"})
    (git-plan-root-mode ctx)))

(defn- git-plan-root-check
  [ctx]
  (let [(shallow shallow-status) (git-call ctx.root ["rev-parse" "--is-shallow-repository"])]
    (git-plan-root ctx shallow shallow-status)))

(defn- git-plan
  [start parsed]
  (let [root (git-root start)
        ctx  {:root root :parsed parsed :base (or parsed.base "HEAD")}]
    (if (= root nil)
      (values nil {:message "lint requires a Git repository"})
      (git-plan-root-check ctx))))

(defn- path-present?
  [paths path index]
  (if (> index (length paths)) false
    (= path (. paths index)) true
    (path-present? paths path (+ index 1))))

(defn- changed-file-result
  [file patch status]
  (when (= status 0)
    {:path file.path :source file.source :selection (lint-selection.parse-hunks patch)}))

(defn- changed-file-hunks
  [root base file]
  (let [(patch status) (git-call root ["diff" "--unified=0" "--no-color" "--no-ext-diff" base "--" file.path])]
    (changed-file-result file patch status)))

(defn- changed-file
  [root base file whole?]
  (if whole?
    {:path file.path :source file.source :selection true}
    (changed-file-hunks root base file)))

(defn- append-selected
  [result selected]
  (table.insert result selected)
  result)

(defn- changed-result
  [result selected]
  (if selected
    (append-selected result selected)
    result))

(defn- changed-file-selection
  [ctx file]
  (let [whole? (path-present? ctx.plan.whole file.path 1)
        hunk?  (path-present? ctx.plan.hunks file.path 1)]
    (and (or whole? hunk?)
         (changed-file ctx.root ctx.base file whole?))))

(defn- changed-files-next
  [ctx state]
  (let [file     (. ctx.files state.index)
        selected (changed-file-selection ctx file)
        result   (changed-result state.result selected)]
    {:index (+ state.index 1) :result result}))

(defn- changed-files-step
  [ctx state]
  (if (> state.index (length ctx.files))
    state.result
    (changed-files-step ctx (changed-files-next ctx state))))

(defn emit-git-error
  [printer error]
  (printer (or (. error :message) error))
  2)

(defn- scope-paths
  [plan]
  (let [result []]
    (each [_ path (ipairs plan.whole)] (table.insert result path))
    (each [_ path (ipairs plan.hunks)] (table.insert result path))
    (each [_ path (ipairs plan.deleted)] (table.insert result path))
    result))

(defn lint-git-info
  [root parsed require-git?]
  (if require-git?
    (git-plan root parsed)
    (values {:root root :plan {:whole [] :hunks [] :deleted []}} nil)))

(defn lint-selection
  [parsed sources git-info]
  (if parsed.changed
    (values (changed-files-step {:root git-info.root :base (or parsed.base "HEAD") :files sources :plan git-info.plan}
                                {:index 1 :result []})
            (scope-paths git-info.plan))
    (values sources nil)))
