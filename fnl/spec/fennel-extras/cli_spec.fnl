(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(defn- load-cli []
  (let [(ok result) (pcall require :fennel-extras.cli)]
    (if ok
        result
        {:module-missing true})))

(defn- with-cleanup
  [cleanup f]
  (let [(ok result) (pcall f)]
    (cleanup)
    (if ok
        result
        (error result 0))))

(defn- write-file
  [path text]
  (let [file (assert (io.open path :w))]
    (file:write text)
    (file:close)
    path))

(defn- read-file
  [path]
  (let [file (assert (io.open path :r))
        text (file:read "*a")]
    (file:close)
    text))

(defn- run-cli
  [root args]
  (let [lines []
        cli (load-cli)]
    (if (. cli :module-missing)
        cli
        {:code (cli.run args {:cwd root
                              :print (fn [line] (table.insert lines line))})
         :lines lines})))

(defn- check-scenario
  [source expected-code expected-lines]
  (let [root (vim.fn.tempname)
        path (.. root "/a.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
     (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file path source)
        (let [result (run-cli root ["format" "--check" "a.fnl"])]
          {:code (. result :code)
           :lines (. result :lines)
           :content (read-file path)
           :expected-code expected-code
           :expected-lines expected-lines})))))

(defn- write-scenario
  [mode]
  (let [root (vim.fn.tempname)
        good (.. root "/good.fnl")
        bad (.. root "/bad.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
     (fn [] (vim.fn.delete root "rf"))
      (fn []
        (if (= mode :good)
            (do
              (write-file good "(when x\ny)\n")
              (let [result (run-cli root ["format" "--write" "--parser" "eca.nfnl.fennel" "good.fnl"])]
                {:code (. result :code)
                 :lines (. result :lines)
                 :good (read-file good)}))
            (if (= mode :formatted)
                (do
                  (write-file good "(when x\n  y)\n")
                  (let [result (run-cli root ["format" "--write" "good.fnl"])]
                    {:code (. result :code)
                     :lines (. result :lines)
                     :good (read-file good)
                     :entry-count (length (vim.fn.globpath root "*" false true))}))
                (do
                  (write-file good "(when x\ny)\n")
                  (write-file bad "(x")
                  (let [result (run-cli root ["format" "--write" "good.fnl" "bad.fnl"])]
                    {:code (. result :code)
                     :lines (. result :lines)
                     :good (read-file good)
                     :bad (read-file bad)}))))))))

(defn- config-scenario
  [mode]
  (let [root (vim.fn.tempname)
        src (.. root "/src")
        skip (.. root "/skip")
        src-file (.. src "/a.fnl")
        skip-file (.. skip "/x.fnl")
        config-path (.. root "/.fnl-extras.fnl")]
    (vim.fn.mkdir src "p")
    (vim.fn.mkdir skip "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
     (fn [] (vim.fn.delete root "rf"))
      (fn []
        (if (= mode :indent)
            (do
              (write-file config-path "{:indents {\"deftest\" [[:block 1]]}}")
              (write-file src-file "(deftest t\n(foo))\n")
              (let [result (run-cli root ["format" "--write" "src/a.fnl"])]
                {:code (. result :code)
                 :lines (. result :lines)
                 :content (read-file src-file)}))
            (if (= mode :exclude)
                (do
                  (write-file config-path "{:exclude [\"skip\"]}\n")
                  (write-file src-file "(when x\n  y)\n")
                  (write-file skip-file "(when x\ny)\n")
                  (let [result (run-cli root ["format" "--write"])]
                    {:code (. result :code)
                     :lines (. result :lines)
                     :content (read-file skip-file)}))
                (if (= mode :paths)
                    (do
                      (write-file config-path "{:paths [\"src\"]}")
                      (write-file src-file "(when x\ny)\n")
                      (write-file skip-file "(when x\ny)\n")
                      (let [result (run-cli root ["format" "--write"])]
                        {:code (. result :code)
                         :lines (. result :lines)
                         :src (read-file src-file)
                         :skip (read-file skip-file)}))
                    (do
                      (write-file config-path "{:colour 1}")
                      (let [result (run-cli root ["format" "--check" "src/a.fnl"])]
                        {:code (. result :code)
                         :lines (. result :lines)})))))))))

(deftest check
  (testing "returns zero and no lines for an already-formatted project"
    (is (= {:code 0 :lines [] :content "(when x\n  y)\n"
            :expected-code 0 :expected-lines []}
           (check-scenario "(when x\n  y)\n" 0 []))))
  (testing "returns one and leaves an unformatted file unchanged"
    (is (= {:code 1 :lines ["a.fnl"] :content "(when x\ny)\n"
            :expected-code 1 :expected-lines ["a.fnl"]}
           (check-scenario "(when x\ny)\n" 1 ["a.fnl"])))))

(deftest write
  (testing "rewrites an unformatted file and reports its relative path"
    (is (= {:code 0 :lines ["good.fnl"] :good "(when x\n  y)\n"}
           (write-scenario :good))))
  (testing "does not rewrite an already-formatted file or leave a temp file"
    (is (= {:code 0 :lines [] :good "(when x\n  y)\n"
            :entry-count 1}
           (write-scenario :formatted))))
  (testing "formats all files before writing and leaves the good file unchanged on error"
    (let [result (write-scenario :error)]
      (is (and (= 2 (. result :code))
               (= "(when x\ny)\n" (. result :good))
               (= "(x" (. result :bad))
               (= 1 (length (. result :lines)))
               (string.match (. result :lines 1) "^bad%.fnl:[0-9]+:[0-9]+: .*"))))))

(deftest config
  (testing "uses configured indentation rules"
    (is (= {:code 0 :lines ["src/a.fnl"] :content "(deftest t\n  (foo))\n"}
           (config-scenario :indent))))
  (testing "skips files under configured exclude prefixes"
    (is (= {:code 0 :lines [] :content "(when x\ny)\n"}
           (config-scenario :exclude))))
  (testing "uses configured paths for a no-argument run"
    (is (= {:code 0 :lines ["src/a.fnl"]
            :src "(when x\n  y)\n"
            :skip "(when x\ny)\n"}
           (config-scenario :paths))))
  (testing "returns one config error line for an invalid configuration"
    (is (= {:code 2 :line-count 1 :mentions-config true}
           (let [result (config-scenario :invalid)
                 lines (or (. result :lines) [])
                 line (or (. lines 1) "")]
             {:code (. result :code)
              :line-count (length lines)
              :mentions-config (not (not (string.match line "fnl%-extras")))})))))

(defn- symlink-loop-scenario []
  (let [root (vim.fn.tempname)
        fnl-dir (.. root "/fnl")
        file (.. fnl-dir "/a.fnl")
        loop-path (.. fnl-dir "/loop")
        script (.. (vim.fn.getcwd) "/scripts/fennel-extras")]
    (vim.fn.mkdir fnl-dir "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
     (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file file "(when x\ny)\n")
        (assert (vim.loop.fs_symlink root loop-path))
        (let [command (.. "cd " (vim.fn.shellescape root)
                          " && perl -e 'alarm shift; exec @ARGV' 10 "
                          (vim.fn.shellescape script) " format --check")
              lines (vim.fn.systemlist ["sh" "-c" command])]
          {:code vim.v.shell_error
           :lines lines})))))

(defn- two-phase-write-scenario []
  (let [root (vim.fn.tempname)
        fnl-dir (.. root "/fnl")
        read-only (.. fnl-dir "/ro")
        good (.. fnl-dir "/a.fnl")
        blocked (.. read-only "/b.fnl")
        probe (.. read-only "/probe")]
    (vim.fn.mkdir read-only "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
     (fn []
       (vim.fn.setfperm read-only "rwxr-xr-x")
       (vim.fn.delete root "rf"))
      (fn []
        (write-file good "(when x\ny)\n")
        (write-file blocked "(when y\nz)\n")
        (vim.fn.setfperm read-only "r-xr-xr-x")
        (let [probe-file (io.open probe :w)]
          (if probe-file
              (do
                (probe-file:close)
                (vim.fn.delete probe)
                {:skipped-root true})
              (let [result (run-cli root ["format" "--write"])]
                {:code (. result :code)
                 :a-unchanged (= (read-file good) "(when x\ny)\n")})))))))

(defn- dotfile-scenario
  [mode]
  (let [root (vim.fn.tempname)
        fnl-dir (.. root "/fnl")]
    (vim.fn.mkdir fnl-dir "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
     (fn [] (vim.fn.delete root "rf"))
      (fn []
        (if (= mode :config)
            (do
              (write-file (.. root "/.fnl-extras.fnl") "{}\n")
              (write-file (.. fnl-dir "/a.fnl") "(when x\n  y)\n")
              (let [result (run-cli root ["format" "--check" "."])]
                {:code (. result :code) :lines (. result :lines)}))
            (do
              (write-file (.. root "/.x.fnl") "(when x\n  y)\n")
              (let [result (run-cli root ["format" "--check" "."])]
                {:code (. result :code) :lines (. result :lines)})))))))

(defn- symlink-file-scenario
  [mode]
  (let [root (vim.fn.tempname)
        outside (vim.fn.tempname)
        fnl-dir (.. root "/fnl")
        good (.. fnl-dir "/a.fnl")
        link (.. fnl-dir "/link.fnl")
        target (.. outside "/outside.fnl")]
    (vim.fn.mkdir fnl-dir "p")
    (vim.fn.mkdir outside "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
     (fn []
       (vim.fn.delete root "rf")
       (vim.fn.delete outside "rf"))
      (fn []
        (write-file good "(when x\n  y)\n")
        (write-file target "(when x\ny)\n")
        (assert (vim.loop.fs_symlink target link))
        (let [result (run-cli root (if (= mode :write)
                                       ["format" "--write"]
                                       ["format" "--check" "fnl/link.fnl"]))]
          {:code (. result :code)
           :lines (. result :lines)
           :link-type (. (vim.loop.fs_lstat link) :type)
           :target (read-file target)})))))

(defn- unreadable-directory-scenario []
  (let [root (vim.fn.tempname)
        fnl-dir (.. root "/fnl")
        locked (.. fnl-dir "/locked")
        good (.. fnl-dir "/a.fnl")]
    (vim.fn.mkdir locked "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
     (fn []
       (vim.fn.setfperm locked "rwxr-xr-x")
       (vim.fn.delete root "rf"))
      (fn []
        (write-file good "(when x\n  y)\n")
        (vim.fn.setfperm locked "---------")
        (let [handle (vim.loop.fs_scandir locked)]
          (if handle
              {:skipped-root true}
              (let [result (run-cli root ["format" "--check"])
                    lines (. result :lines)]
                {:code (. result :code)
                 :mentions-read-error (not (not (string.match (or (. lines 1) "") "cannot read directory")))})))))))

(deftest edge-cases
  (testing "does not recurse through directory symlinks"
    (is (= {:code 1 :lines ["fnl/a.fnl"]} (symlink-loop-scenario))))
  (testing "does not partially write files when a later write fails"
    (let [result (two-phase-write-scenario)]
         ;; Root can write through read-only directories, so this environment cannot exercise the failure.
      (is (= (if (. result :skipped-root)
                 {:skipped-root true}
                 {:code 2 :a-unchanged true})
             result))))
  (testing "does not discover a dotfile config as source"
           ;; This documents the decision that configuration is data, not source; current glob behavior already passes it.
    (is (= {:code 0 :lines []} (dotfile-scenario :config))))
  (testing "does not discover a dotfile with a Fennel extension"
    (is (= {:code 2 :lines ["no files found"]} (dotfile-scenario :source))))
  (testing "skips symlinked files during no-argument writes"
    (is (= {:code 0 :lines [] :link-type "link" :target "(when x\ny)\n"}
           (symlink-file-scenario :write))))
  (testing "rejects an explicit symlink file argument"
    (let [result (symlink-file-scenario :check)
          lines (. result :lines)]
      (is (= {:code 2
              :line-count 1
              :mentions-symlink true}
             {:code (. result :code)
              :line-count (length lines)
              :mentions-symlink (not (not (string.match (or (. lines 1) "") "symlink")))}))))
  (testing "reports an unreadable directory"
    (let [result (unreadable-directory-scenario)]
         ;; Root can read mode-000 directories, so this environment cannot exercise the failure.
      (is (= (if (. result :skipped-root)
                 {:skipped-root true}
                 {:code 2 :mentions-read-error true})
             result)))))
