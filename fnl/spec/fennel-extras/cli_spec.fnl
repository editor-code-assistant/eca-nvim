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

(defn- extension-scenario
  [extension]
  (let [root (vim.fn.tempname)
        path (.. root "/source" extension)
        config-path (.. root "/.fnl-extras.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
     (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file config-path (.. "{:extensions [\"" extension "\"]}"))
        (if (= extension ".fnl")
            (do
              (write-file path "(when x\ny)\n")
              (write-file (.. root "/source.fnlm") "(when y\nz)\n"))
            (write-file path "(when x\ny)\n"))
        (let [result (run-cli root ["format" "--check"])]
          {:code (. result :code)
           :lines (. result :lines)})))))

(defn- default-path-scenario []
  (let [root (vim.fn.tempname)
        path (.. root "/source.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
     (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file path "(when x\ny)\n")
        (let [result (run-cli root ["format" "--write"])]
          {:code (. result :code)
           :lines (. result :lines)
           :content (read-file path)})))))

(defn- dotfiles-scenario []
  (let [root (vim.fn.tempname)
        fnl-dir (.. root "/fnl")
        hidden-dir (.. fnl-dir "/.hidden")
        hidden-file (.. fnl-dir "/.hidden.fnl")
        nested-file (.. hidden-dir "/nested.fnl")
        git-dir (.. fnl-dir "/.git")
        git-file (.. git-dir "/ignored.fnl")]
    (vim.fn.mkdir hidden-dir "p")
    (vim.fn.mkdir git-dir "p")
    (with-cleanup
     (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file (.. root "/.fnl-extras.fnl") "{:paths [\"fnl\"] :skip-dotfiles false}")
        (write-file hidden-file "(when x\ny)\n")
        (write-file nested-file "(when x\ny)\n")
        (write-file git-file "(when x\ny)\n")
        (let [result (run-cli root ["format" "--check"])]
          {:code (. result :code)
           :lines (. result :lines)
           :hidden (. (vim.loop.fs_stat hidden-file) :type)
           :nested (. (vim.loop.fs_stat nested-file) :type)
           :git (read-file git-file)})))))

(defn- follow-symlink-scenario []
  (let [root (vim.fn.tempname)
        outside (vim.fn.tempname)
        fnl-dir (.. root "/fnl")
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
        (write-file (.. root "/.fnl-extras.fnl") "{:follow-symlinks true}")
        (write-file target "(when x\ny)\n")
        (assert (vim.loop.fs_symlink target link))
        (let [result (run-cli root ["format" "--write"])]
          {:code (. result :code)
           :lines (. result :lines)
           :link-type (. (vim.loop.fs_lstat link) :type)
           :target (read-file target)})))))

(defn- follow-directory-symlink-scenario
  [mode]
  (let [root (vim.fn.tempname)
        outside (vim.fn.tempname)
        link (.. root "/linkdir")
        target (.. outside "/a.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir outside "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
     (fn []
       (vim.fn.delete root "rf")
       (vim.fn.delete outside "rf"))
      (fn []
        (write-file (.. root "/.fnl-extras.fnl") "{:follow-symlinks true}")
        (write-file target "(when x\ny)\n")
        (assert (vim.loop.fs_symlink outside link))
        (let [result (run-cli root (if (= mode :check)
                                       ["format" "--check"]
                                       ["format" "--write"]))]
          (if (= mode :check)
              {:code (. result :code)
               :lines (. result :lines)
               :target (read-file target)}
              {:code (. result :code)
               :link-type (. (vim.loop.fs_lstat link) :type)
               :target (read-file target)}))))))

(defn- parser-scenario
  [mode]
  (let [root (vim.fn.tempname)
        path (.. root "/a.fnl")
        config-path (.. root "/.fnl-extras.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
     (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file path "(when x\ny)\n")
        (write-file config-path "{:parser \"missing.parser.module\"}")
        (let [result (run-cli root (if (= mode :config)
                                       ["format" "--check" "a.fnl"]
                                       ["format" "--check" "--parser" "eca.nfnl.fennel" "a.fnl"]))]
          {:code (. result :code)
           :lines (. result :lines)})))))

(defn- rule-config-scenario
  [config source expected]
  (let [root (vim.fn.tempname)
        path (.. root "/a.fnl")
        config-path (.. root "/.fnl-extras.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
     (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file config-path config)
        (write-file path source)
        (let [result (run-cli root ["format" "--write" "a.fnl"])]
          {:code (. result :code)
           :lines (. result :lines)
           :content (read-file path)
           :expected expected})))))

(defn- config-discovery-scenario
  [mode]
  (let [root (vim.fn.tempname)
        config-path (.. root "/.fnl-extras.fnl")
        source-path (.. root "/a.fnl")
        config "{:skip-dotfiles false\n:paths [\".\"]}\n"]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
     (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file config-path config)
        (write-file source-path "(when x\ny)\n")
        (let [result (run-cli root (if (= mode :check)
                                       ["format" "--check"]
                                       ["format" "--write"]))]
          {:code (. result :code)
           :lines (. result :lines)
           :config (read-file config-path)
           :source (read-file source-path)})))))

(deftest new-configuration
  (testing "uses only configured extensions during discovery"
    (is (= {:code 1 :lines ["source.fnl"]}
           (extension-scenario ".fnl"))))
  (testing "discovers a configured non-default extension"
    (is (= {:code 1 :lines ["source.fnlx"]}
           (extension-scenario ".fnlx"))))
  (testing "walks the current directory when paths are absent from config and CLI"
    (is (= {:code 0 :lines ["source.fnl"] :content "(when x\n  y)\n"}
           (default-path-scenario))))
  (testing "formats dotfiles and dot-directories when skip-dotfiles is false but never .git"
    (is (= {:code 1
            :lines ["fnl/.hidden.fnl" "fnl/.hidden/nested.fnl"]
            :hidden "file"
            :nested "file"
            :git "(when x\ny)\n"}
           (dotfiles-scenario))))
  (testing "follows file symlinks to real targets and preserves the symlink"
    (is (= {:code 0
            :lines ["fnl/link.fnl"]
            :link-type "link"
            :target "(when x\n  y)\n"}
           (follow-symlink-scenario))))
  (testing "reports files under followed directory symlinks by logical path"
    (is (= {:code 1
            :lines ["linkdir/a.fnl"]
            :target "(when x\ny)\n"}
           (follow-directory-symlink-scenario :check))))
  (testing "writes files under followed directory symlinks to their real targets"
    (is (= {:code 0
            :link-type "link"
            :target "(when x\n  y)\n"}
           (follow-directory-symlink-scenario :write))))
  (testing "uses the parser named by config when no CLI parser is given"
    (is (= {:code 2 :lines ["could not require parser module: missing.parser.module"]}
           (parser-scenario :config))))
  (testing "CLI parser overrides the parser named by config"
    (is (= {:code 1 :lines ["a.fnl"]}
           (parser-scenario :flag)))))

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

(defn- follow-symlink-dedupe-scenario []
  (let [root (vim.fn.tempname)
        target (.. root "/a.fnl")
        link (.. root "/b.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
     (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file (.. root "/.fnl-extras.fnl") "{:follow-symlinks true}")
        (write-file target "(when x\ny)\n")
        (assert (vim.loop.fs_symlink target link))
        (let [result (run-cli root ["format" "--write"])]
          {:code (. result :code)
           :lines (. result :lines)
           :link-type (. (vim.loop.fs_lstat link) :type)
           :target (read-file target)})))))

(defn- follow-symlink-cycle-scenario []
  (let [root (vim.fn.tempname)
        directory (.. root "/d")
        file (.. directory "/x.fnl")
        loop-path (.. directory "/loop")]
    (vim.fn.mkdir directory "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
     (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file (.. root "/.fnl-extras.fnl") "{:follow-symlinks true}")
        (write-file file "(when x\ny)\n")
        (assert (vim.loop.fs_symlink root loop-path))
        (let [result (run-cli root ["format" "--check"])]
          {:code (. result :code)
           :lines (. result :lines)})))))

(defn- follow-symlink-explicit-scenario []
  (let [root (vim.fn.tempname)
        target (.. root "/real.fnl")
        link (.. root "/link.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
     (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file (.. root "/.fnl-extras.fnl") "{:follow-symlinks true}")
        (write-file target "(when x\ny)\n")
        (assert (vim.loop.fs_symlink target link))
        (let [result (run-cli root ["format" "--check" "link.fnl"])]
          {:code (. result :code)
           :lines (. result :lines)})))))

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

(deftest configured-formatting-rules
  (testing "uses configured indent-width"
    (is (= {:code 0 :lines ["a.fnl"] :content "(when x\n    y)\n"
            :expected "(when x\n    y)\n"}
           (rule-config-scenario "{:indent-width 4}" "(when x\ny)\n"
                                 "(when x\n    y)\n"))))
  (testing "disables built-in indentation rules when builtins is false"
    (is (= {:code 0 :lines ["a.fnl"] :content "(let [x 1]\n     x)\n"
            :expected "(let [x 1]\n     x)\n"}
           (rule-config-scenario "{:builtins false}" "(let [x 1]\nx)\n"
                                 "(let [x 1]\n     x)\n"))))
  (testing "disables prefix fallback indentation rules when prefix-fallbacks is false"
    (is (= {:code 0 :lines ["a.fnl"] :content "(defn x\n      y)\n"
            :expected "(defn x\n      y)\n"}
           (rule-config-scenario "{:prefix-fallbacks false}" "(defn x\ny)\n"
                                 "(defn x\n      y)\n")))))

(deftest config-file-discovery
  (testing "does not report the discovered config file as a formatting target"
    (is (= {:code 1 :lines ["a.fnl"]
            :config "{:skip-dotfiles false\n:paths [\".\"]}\n"
            :source "(when x\ny)\n"}
           (config-discovery-scenario :check))))
  (testing "does not rewrite the discovered config file"
    (is (= {:code 0 :lines ["a.fnl"]
            :config "{:skip-dotfiles false\n:paths [\".\"]}\n"
            :source "(when x\n  y)\n"}
           (config-discovery-scenario :write)))))

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
             result))))
  (testing "processes a real file only once when a symlink points to it"
    (is (= {:code 0
            :lines ["a.fnl"]
            :link-type "link"
            :target "(when x\n  y)\n"}
           (follow-symlink-dedupe-scenario))))
  (testing "terminates when a followed directory symlink forms a cycle"
    (is (= {:code 1 :lines ["d/x.fnl"]}
           (follow-symlink-cycle-scenario))))
  (testing "follows an explicitly named symlink file"
    (is (= {:code 1 :lines ["link.fnl"]}
           (follow-symlink-explicit-scenario)))))
