(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(defn- load-cli
  []
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
        cli   (load-cli)]
    (if (. cli :module-missing)
      cli
      {:code  (cli.run
               args
               {:cwd   root
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
          {:code           (. result :code)
           :lines          (. result :lines)
           :content        (read-file path)
           :expected-code  expected-code
           :expected-lines expected-lines})))))

(defn- write-good-scenario
  [root good]
  (let [_      (write-file good "(when x\ny)\n")
        result (run-cli root ["format" "--write" "--parser" "eca.nfnl.fennel" "good.fnl"])]
    {:code  (. result :code)
     :lines (. result :lines)
     :good  (read-file good)}))

(defn- write-formatted-scenario
  [root good]
  (let [_      (write-file good "(when x\n  y)\n")
        result (run-cli root ["format" "--write" "good.fnl"])]
    {:code        (. result :code)
     :lines       (. result :lines)
     :good        (read-file good)
     :entry-count (length (vim.fn.globpath root "*" false true))}))

(defn- write-error-scenario
  [root good bad]
  (let [_      (write-file good "(when x\ny)\n")
        _      (write-file bad "(x")
        result (run-cli root ["format" "--write" "good.fnl" "bad.fnl"])]
    {:code  (. result :code)
     :lines (. result :lines)
     :good  (read-file good)
     :bad   (read-file bad)}))

(defn- write-scenario
  [mode]
  (let [root (vim.fn.tempname)
        good (.. root "/good.fnl")
        bad  (.. root "/bad.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (if (= mode :good)
          (write-good-scenario root good)
          (if (= mode :formatted)
            (write-formatted-scenario root good)
            (write-error-scenario root good bad)))))))

(defn- config-indent-scenario
  [root src-file config-path]
  (let [_      (write-file config-path "{:indents {\"deftest\" [[:block 1]]}}")
        _      (write-file src-file "(deftest t\n(foo))\n")
        result (run-cli root ["format" "--write" "src/a.fnl"])]
    {:code    (. result :code)
     :lines   (. result :lines)
     :content (read-file src-file)}))

(defn- config-exclude-scenario
  [root src-file skip-file config-path]
  (let [_      (write-file config-path "{:exclude [\"skip\"]}\n")
        _      (write-file src-file "(when x\n  y)\n")
        _      (write-file skip-file "(when x\ny)\n")
        result (run-cli root ["format" "--write"])]
    {:code    (. result :code)
     :lines   (. result :lines)
     :content (read-file skip-file)}))

(defn- config-paths-scenario
  [root src-file skip-file config-path]
  (let [_      (write-file config-path "{:paths [\"src\"]}")
        _      (write-file src-file "(when x\ny)\n")
        _      (write-file skip-file "(when x\ny)\n")
        result (run-cli root ["format" "--write"])]
    {:code  (. result :code)
     :lines (. result :lines)
     :src   (read-file src-file)
     :skip  (read-file skip-file)}))

(defn- config-invalid-scenario
  [root src-file config-path]
  (let [_      (write-file config-path "{:colour 1}")
        result (run-cli root ["format" "--check" "src/a.fnl"])]
    {:code  (. result :code)
     :lines (. result :lines)}))

(defn- config-scenario
  [mode]
  (let [root        (vim.fn.tempname)
        src         (.. root "/src")
        skip        (.. root "/skip")
        src-file    (.. src "/a.fnl")
        skip-file   (.. skip "/x.fnl")
        config-path (.. root "/.fnl-extras.fnl")]
    (vim.fn.mkdir src "p")
    (vim.fn.mkdir skip "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (if (= mode :indent)
          (config-indent-scenario root src-file config-path)
          (if (= mode :exclude)
            (config-exclude-scenario root src-file skip-file config-path)
            (if (= mode :paths)
              (config-paths-scenario root src-file skip-file config-path)
              (config-invalid-scenario root src-file config-path))))))))

(defn- align-bindings-cli-scenario
  []
  (let [root        (vim.fn.tempname)
        path        (.. root "/a.fnl")
        config-path (.. root "/.fnl-extras.fnl")
        source      "(let [a 1\n      long-name 2]\n  a)"
        expected    "(let [a         1\n      long-name 2]\n  a)"]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file config-path "{:align-bindings true}")
        (write-file path source)
        (let [check-result (run-cli root ["format" "--check" "a.fnl"])
              write-result (run-cli root ["format" "--write" "a.fnl"])]
          {:check-code  (. check-result :code)
           :check-lines (. check-result :lines)
           :write-code  (. write-result :code)
           :write-lines (. write-result :lines)
           :content     (read-file path)
           :expected    expected})))))

(deftest check
  (testing "returns zero and no lines for an already-formatted project"
    (is (= {:code           0
            :lines          []
            :content        "(when x\n  y)\n"
            :expected-code  0
            :expected-lines []}
           (check-scenario "(when x\n  y)\n" 0 []))))
  (testing "returns one and leaves an unformatted file unchanged"
    (is (= {:code           1
            :lines          ["a.fnl"]
            :content        "(when x\ny)\n"
            :expected-code  1
            :expected-lines ["a.fnl"]}
           (check-scenario "(when x\ny)\n" 1 ["a.fnl"])))))

(deftest write
  (testing "rewrites an unformatted file and reports its relative path"
    (is (= {:code 0 :lines ["good.fnl"] :good "(when x\n  y)\n"}
           (write-scenario :good))))
  (testing "does not rewrite an already-formatted file or leave a temp file"
    (is (= {:code        0
            :lines       []
            :good        "(when x\n  y)\n"
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
    (is (= {:code  0
            :lines ["src/a.fnl"]
            :src   "(when x\n  y)\n"
            :skip  "(when x\ny)\n"}
           (config-scenario :paths))))
  (testing "returns one config error line for an invalid configuration"
    (is (= {:code 2 :line-count 1 :mentions-config true}
           (let [result (config-scenario :invalid)
                 lines  (or (. result :lines) [])
                 line   (or (. lines 1) "")]
             {:code            (. result :code)
              :line-count      (length lines)
              :mentions-config (not (not (string.match line "fnl%-extras")))})))))

(defn- extension-fnl-scenario
  [root path config-path]
  (let [_      (write-file path "(when x\ny)\n")
        _      (write-file (.. root "/source.fnlm") "(when y\nz)\n")
        result (run-cli root ["format" "--check"])]
    {:code  (. result :code)
     :lines (. result :lines)}))

(defn- extension-other-scenario
  [root path config-path]
  (let [_      (write-file path "(when x\ny)\n")
        result (run-cli root ["format" "--check"])]
    {:code  (. result :code)
     :lines (. result :lines)}))

(defn- extension-scenario
  [extension]
  (let [root        (vim.fn.tempname)
        path        (.. root "/source" extension)
        config-path (.. root "/.fnl-extras.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file config-path (.. "{:extensions [\"" extension "\"]}"))
        (if (= extension ".fnl")
          (extension-fnl-scenario root path config-path)
          (extension-other-scenario root path config-path))))))

(defn- default-path-scenario
  []
  (let [root (vim.fn.tempname)
        path (.. root "/source.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file path "(when x\ny)\n")
        (let [result (run-cli root ["format" "--write"])]
          {:code    (. result :code)
           :lines   (. result :lines)
           :content (read-file path)})))))

(defn- dotfiles-scenario
  []
  (let [root        (vim.fn.tempname)
        fnl-dir     (.. root "/fnl")
        hidden-dir  (.. fnl-dir "/.hidden")
        hidden-file (.. fnl-dir "/.hidden.fnl")
        nested-file (.. hidden-dir "/nested.fnl")
        git-dir     (.. fnl-dir "/.git")
        git-file    (.. git-dir "/ignored.fnl")]
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
          {:code   (. result :code)
           :lines  (. result :lines)
           :hidden (. (vim.loop.fs_stat hidden-file) :type)
           :nested (. (vim.loop.fs_stat nested-file) :type)
           :git    (read-file git-file)})))))

(defn- follow-symlink-scenario
  []
  (let [root    (vim.fn.tempname)
        outside (vim.fn.tempname)
        fnl-dir (.. root "/fnl")
        link    (.. fnl-dir "/link.fnl")
        target  (.. outside "/outside.fnl")]
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
          {:code      (. result :code)
           :lines     (. result :lines)
           :link-type (. (vim.loop.fs_lstat link) :type)
           :target    (read-file target)})))))

(defn- follow-directory-symlink-scenario
  [mode]
  (let [root    (vim.fn.tempname)
        outside (vim.fn.tempname)
        link    (.. root "/linkdir")
        target  (.. outside "/a.fnl")]
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
        (let [result (run-cli
                      root
                      (if (= mode :check)
                        ["format" "--check"]
                        ["format" "--write"]))]
          (if (= mode :check)
            {:code   (. result :code)
             :lines  (. result :lines)
             :target (read-file target)}
            {:code      (. result :code)
             :link-type (. (vim.loop.fs_lstat link) :type)
             :target    (read-file target)}))))))

(defn- parser-scenario
  [mode]
  (let [root        (vim.fn.tempname)
        path        (.. root "/a.fnl")
        config-path (.. root "/.fnl-extras.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file path "(when x\ny)\n")
        (write-file config-path "{:parser \"missing.parser.module\"}")
        (let [result (run-cli
                      root
                      (if (= mode :config)
                        ["format" "--check" "a.fnl"]
                        ["format" "--check" "--parser" "eca.nfnl.fennel" "a.fnl"]))]
          {:code  (. result :code)
           :lines (. result :lines)})))))

(defn- rule-config-scenario
  [config source expected]
  (let [root        (vim.fn.tempname)
        path        (.. root "/a.fnl")
        config-path (.. root "/.fnl-extras.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file config-path config)
        (write-file path source)
        (let [result (run-cli root ["format" "--write" "a.fnl"])]
          {:code     (. result :code)
           :lines    (. result :lines)
           :content  (read-file path)
           :expected expected})))))

(defn- config-discovery-scenario
  [mode]
  (let [root        (vim.fn.tempname)
        config-path (.. root "/.fnl-extras.fnl")
        source-path (.. root "/a.fnl")
        config      "{:skip-dotfiles false\n:paths [\".\"]}\n"]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file config-path config)
        (write-file source-path "(when x\ny)\n")
        (let [result (run-cli
                      root
                      (if (= mode :check)
                        ["format" "--check"]
                        ["format" "--write"]))]
          {:code   (. result :code)
           :lines  (. result :lines)
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
    (is (= {:code   1
            :lines  ["fnl/.hidden.fnl" "fnl/.hidden/nested.fnl"]
            :hidden "file"
            :nested "file"
            :git    "(when x\ny)\n"}
           (dotfiles-scenario))))
  (testing "follows file symlinks to real targets and preserves the symlink"
    (is (= {:code      0
            :lines     ["fnl/link.fnl"]
            :link-type "link"
            :target    "(when x\n  y)\n"}
           (follow-symlink-scenario))))
  (testing "reports files under followed directory symlinks by logical path"
    (is (= {:code   1
            :lines  ["linkdir/a.fnl"]
            :target "(when x\ny)\n"}
           (follow-directory-symlink-scenario :check))))
  (testing "writes files under followed directory symlinks to their real targets"
    (is (= {:code      0
            :link-type "link"
            :target    "(when x\n  y)\n"}
           (follow-directory-symlink-scenario :write))))
  (testing "uses the parser named by config when no CLI parser is given"
    (is (= {:code 2 :lines ["could not require parser module: missing.parser.module"]}
           (parser-scenario :config))))
  (testing "CLI parser overrides the parser named by config"
    (is (= {:code 1 :lines ["a.fnl"]}
           (parser-scenario :flag)))))

(defn- symlink-loop-scenario
  []
  (let [root      (vim.fn.tempname)
        fnl-dir   (.. root "/fnl")
        file      (.. fnl-dir "/a.fnl")
        loop-path (.. fnl-dir "/loop")
        script    (.. (vim.fn.getcwd) "/scripts/fennel-extras")]
    (vim.fn.mkdir fnl-dir "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file file "(when x\ny)\n")
        (assert (vim.loop.fs_symlink root loop-path))
        (let [command (..
                       "cd "
                       (vim.fn.shellescape root)
                       " && perl -e 'alarm shift; exec @ARGV' 10 "
                       (vim.fn.shellescape script)
                       " format --check")
              lines   (vim.fn.systemlist ["sh" "-c" command])]
          {:code  vim.v.shell_error
           :lines lines})))))

(defn- two-phase-skipped-scenario
  [probe-file probe]
  (let [_ (probe-file:close)
        _ (vim.fn.delete probe)]
    {:skipped-root true}))

(defn- two-phase-write-attempt
  [root good]
  (let [result (run-cli root ["format" "--write"])]
    {:code        (. result :code)
     :a-unchanged (= (read-file good) "(when x\ny)\n")}))

(defn- two-phase-write-scenario
  []
  (let [root      (vim.fn.tempname)
        fnl-dir   (.. root "/fnl")
        read-only (.. fnl-dir "/ro")
        good      (.. fnl-dir "/a.fnl")
        blocked   (.. read-only "/b.fnl")
        probe     (.. read-only "/probe")]
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
            (two-phase-skipped-scenario probe-file probe)
            (two-phase-write-attempt root good)))))))

(defn- dotfile-config-scenario
  [root fnl-dir]
  (let [_      (write-file (.. root "/.fnl-extras.fnl") "{}\n")
        _      (write-file (.. fnl-dir "/a.fnl") "(when x\n  y)\n")
        result (run-cli root ["format" "--check" "."])]
    {:code (. result :code) :lines (. result :lines)}))

(defn- dotfile-source-scenario
  [root]
  (let [_      (write-file (.. root "/.x.fnl") "(when x\n  y)\n")
        result (run-cli root ["format" "--check" "."])]
    {:code (. result :code) :lines (. result :lines)}))

(defn- dotfile-scenario
  [mode]
  (let [root    (vim.fn.tempname)
        fnl-dir (.. root "/fnl")]
    (vim.fn.mkdir fnl-dir "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (if (= mode :config)
          (dotfile-config-scenario root fnl-dir)
          (dotfile-source-scenario root))))))

(defn- symlink-file-scenario
  [mode]
  (let [root    (vim.fn.tempname)
        outside (vim.fn.tempname)
        fnl-dir (.. root "/fnl")
        good    (.. fnl-dir "/a.fnl")
        link    (.. fnl-dir "/link.fnl")
        target  (.. outside "/outside.fnl")]
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
        (let [result (run-cli
                      root
                      (if (= mode :write)
                        ["format" "--write"]
                        ["format" "--check" "fnl/link.fnl"]))]
          {:code      (. result :code)
           :lines     (. result :lines)
           :link-type (. (vim.loop.fs_lstat link) :type)
           :target    (read-file target)})))))

(defn- follow-symlink-dedupe-scenario
  []
  (let [root   (vim.fn.tempname)
        target (.. root "/a.fnl")
        link   (.. root "/b.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file (.. root "/.fnl-extras.fnl") "{:follow-symlinks true}")
        (write-file target "(when x\ny)\n")
        (assert (vim.loop.fs_symlink target link))
        (let [result (run-cli root ["format" "--write"])]
          {:code      (. result :code)
           :lines     (. result :lines)
           :link-type (. (vim.loop.fs_lstat link) :type)
           :target    (read-file target)})))))

(defn- follow-symlink-cycle-scenario
  []
  (let [root      (vim.fn.tempname)
        directory (.. root "/d")
        file      (.. directory "/x.fnl")
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
          {:code  (. result :code)
           :lines (. result :lines)})))))

(defn- follow-symlink-explicit-scenario
  []
  (let [root   (vim.fn.tempname)
        target (.. root "/real.fnl")
        link   (.. root "/link.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file (.. root "/.fnl-extras.fnl") "{:follow-symlinks true}")
        (write-file target "(when x\ny)\n")
        (assert (vim.loop.fs_symlink target link))
        (let [result (run-cli root ["format" "--check" "link.fnl"])]
          {:code  (. result :code)
           :lines (. result :lines)})))))

(defn- unreadable-directory-scenario
  []
  (let [root    (vim.fn.tempname)
        fnl-dir (.. root "/fnl")
        locked  (.. fnl-dir "/locked")
        good    (.. fnl-dir "/a.fnl")]
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
                  lines  (. result :lines)]
              {:code                (. result :code)
               :mentions-read-error (not (not (string.match (or (. lines 1) "") "cannot read directory")))})))))))

(deftest configured-formatting-rules
  (testing "uses configured indent-width"
    (is (= {:code     0
            :lines    ["a.fnl"]
            :content  "(when x\n    y)\n"
            :expected "(when x\n    y)\n"}
           (rule-config-scenario
            "{:indent-width 4}"
            "(when x\ny)\n"
            "(when x\n    y)\n"))))
  (testing "disables built-in indentation rules when builtins is false"
    (is (= {:code     0
            :lines    ["a.fnl"]
            :content  "(let [x 1]\n     x)\n"
            :expected "(let [x 1]\n     x)\n"}
           (rule-config-scenario
            "{:builtins false}"
            "(let [x 1]\nx)\n"
            "(let [x 1]\n     x)\n"))))
  (testing "disables prefix fallback indentation rules when prefix-fallbacks is false"
    (is (= {:code     0
            :lines    ["a.fnl"]
            :content  "(defn x\n      y)\n"
            :expected "(defn x\n      y)\n"}
           (rule-config-scenario
            "{:prefix-fallbacks false}"
            "(defn x\ny)\n"
            "(defn x\n      y)\n")))))

(deftest config-file-discovery
  (testing "does not report the discovered config file as a formatting target"
    (is (= {:code   1
            :lines  ["a.fnl"]
            :config "{:skip-dotfiles false\n:paths [\".\"]}\n"
            :source "(when x\ny)\n"}
           (config-discovery-scenario :check))))
  (testing "does not rewrite the discovered config file"
    (is (= {:code   0
            :lines  ["a.fnl"]
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
          lines  (. result :lines)]
      (is (= {:code             2
              :line-count       1
              :mentions-symlink true}
             {:code             (. result :code)
              :line-count       (length lines)
              :mentions-symlink (not (not (string.match (or (. lines 1) "") "symlink")))}))))
  (testing "reports an unreadable directory"
    (let [result (unreadable-directory-scenario)]
         ;; Root can read mode-000 directories, so this environment cannot exercise the failure.
      (is (= (if (. result :skipped-root)
               {:skipped-root true}
               {:code 2 :mentions-read-error true})
             result))))
  (testing "processes a real file only once when a symlink points to it"
    (is (= {:code      0
            :lines     ["a.fnl"]
            :link-type "link"
            :target    "(when x\n  y)\n"}
           (follow-symlink-dedupe-scenario))))
  (testing "terminates when a followed directory symlink forms a cycle"
    (is (= {:code 1 :lines ["d/x.fnl"]}
           (follow-symlink-cycle-scenario))))
  (testing "follows an explicitly named symlink file"
    (is (= {:code 1 :lines ["link.fnl"]}
           (follow-symlink-explicit-scenario)))))

(defn- lint-git-command
  [root args]
  (let [escaped-args (table.concat (icollect [_ arg (ipairs args)] (vim.fn.shellescape arg)) " ")
        command      (..
                      "cd "
                      (vim.fn.shellescape root)
                      " && perl -e 'alarm shift; exec @ARGV' 30 git "
                      escaped-args
                      " </dev/null 2>&1")]
    (vim.fn.systemlist ["sh" "-c" command])
    vim.v.shell_error))

(defn- lint-git-init
  [root]
  (lint-git-command root ["init" "-q"])
  (lint-git-command root ["config" "user.email" "a@b"])
  (lint-git-command root ["config" "user.name" "t"])
  (lint-git-command root ["config" "commit.gpgsign" "false"])
  (lint-git-command root ["config" "tag.gpgsign" "false"])
  root)

(defn- lint-git-commit
  [root]
  (lint-git-command root ["add" "."])
  (lint-git-command root ["commit" "-qm" "base"])
  root)

(defn- lint-project
  [config files args]
  (let [root        (vim.fn.tempname)
        config-path (.. root "/.fnl-extras.fnl")
        before      {}
        after       {}]
    (vim.fn.mkdir root "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (lint-git-init root)
        (write-file config-path config)
        (each [path text (pairs files)]
          (let [full (.. root "/" path)]
            (vim.fn.mkdir (vim.fn.fnamemodify full ":h") "p")
            (write-file full text)
            (tset before path (read-file full))))
        (let [result (run-cli root args)]
          (each [path _ (pairs files)]
            (tset after path (read-file (.. root "/" path))))
          {:code   (. result :code)
           :lines  (. result :lines)
           :before before
           :after  after})))))

(defn- lint-grammar-scenario
  [args]
  (lint-project
   "{:lint {:rules {\"module-style\" :off}}}"
   {"a.fnl" "(if x 1 2)\n"}
   args))

(defn- lint-discovery-scenario
  [mode]
  (let [config "{:paths [\"src\"] :exclude [\"src/skip\"] :extensions [\".fnl\"] :lint {:rules {\"module-style\" :off}}}"
        files  {"src/keep.fnl" "(if x 1 2)\n" "src/skip/no.fnl" "(if x 1 2)\n" "other.fnl" "(if x 1 2)\n"}]
    (lint-project
     config
     files
     (if (= mode :default)
       ["lint" "--all"]
       ["lint" "--all" "src/keep.fnl"]))))

(defn- lint-output-scenario
  [mode]
  (let [config (if (= mode :error)
                 "{:lint {:rules {\"module-style\" :off}}}"
                 (if (= mode :warning-error)
                   "{:lint {:rules {\"module-style\" :off \"if-branch-call\" :error}}}"
                   (if (= mode :off)
                     "{:lint {:rules {\"module-style\" :off \"if-branch-call\" :off}}}"
                     "{:lint {:rules {\"module-style\" :off}}}")))
        source (if (= mode :error)
                 "(testing \"x\" (is 1) (is 2))\n"
                 "(if x (do (foo) (bar)) nil)\n")]
    (lint-project config {"a.fnl" source} ["lint" "--all"])))

(defn- lint-exclusion-scenario
  [mode]
  (let [config (if (= mode :stale)
                 "{:lint {:rules {\"module-style\" :off} :exclusions [{:rule \"if-branch-call\" :form \"a.fnl > missing\" :reason \"old intentional branch\"}]}}"
                 "{:lint {:rules {\"module-style\" :off} :exclusions [{:rule \"if-branch-call\" :form \"a.fnl > top#1 > if#1 > then\" :reason \"intentional multi-step branch\"}]}}")]
    (lint-project config {"a.fnl" "(if x (do (foo) (bar)) nil)\n"} ["lint" "--all"])))

(defn- lint-error-scenario
  [mode]
  (let [config (if (= mode :config)
                 "{:lint {:rules {\"not-a-rule\" :error}}}"
                 "{:lint {:rules {\"module-style\" :off}}}")
        source (if (= mode :config) "(if x 1 2)\n" "(if x")]
    (lint-project config {"a.fnl" source} ["lint" "--all"])))

(deftest lint-grammar
  (testing "accepts lint all with text output"
    (is (= 0 (. (lint-grammar-scenario ["lint" "--all"]) :code))))
  (testing "accepts lint all with json output"
    (is (= 0 (. (lint-grammar-scenario ["lint" "--all" "--format" "json"]) :code))))
  (testing "rejects base together with all with exit two and a clear message"
    (let [result (lint-grammar-scenario ["lint" "--all" "--base" "HEAD"])]
      (is (and (= 2 (. result :code)) (string.match (or (. result :lines 1) "") "base")))))
  (testing "rejects changed together with all with exit two"
    (is (= 2 (. (lint-grammar-scenario ["lint" "--changed" "--all"]) :code))))
  (testing "rejects unknown flags with exit two"
    (is (= 2 (. (lint-grammar-scenario ["lint" "--wat"]) :code))))
  (testing "rejects duplicate flags with exit two"
    (is (= 2 (. (lint-grammar-scenario ["lint" "--all" "--all"]) :code))))
  (testing "rejects a missing format value with exit two"
    (is (= 2 (. (lint-grammar-scenario ["lint" "--format"]) :code))))
  (testing "rejects an invalid format value with exit two"
    (is (= 2 (. (lint-grammar-scenario ["lint" "--format" "yaml"]) :code))))
  (testing "rejects formatter-only flags for lint"
    (is (= 2 (. (lint-grammar-scenario ["lint" "--write"]) :code))))

  (deftest lint-discovery
    (testing "uses configured paths exclusions extensions and omits its config file"
      (is (= [] (. (lint-discovery-scenario :default) :lines))))
    (testing "optional path arguments restrict lint all discovery"
      (is (= [] (. (lint-discovery-scenario :explicit) :lines)))))

  (deftest lint-output
    (testing "reports one error finding with text output and exit one"
      (is (= 1 (. (lint-output-scenario :error) :code))))
    (testing "prints the exact text line and exclusion suggestion for an error"
      (is (= ["a.fnl:1:1: error one-is-per-testing: each testing form must contain exactly one is"
              "  exclusion: {:rule \"one-is-per-testing\" :form \"a.fnl > top#1 > testing#1\" :reason \"explain why this is intentional\"}"]
             (. (lint-output-scenario :error) :lines))))
    (testing "prints a warning but exits zero"
      (let [result (lint-output-scenario :warning)]
        (is (and (= 0 (. result :code)) (not= nil (. result :lines 1))))))
    (testing "turns the warning into an error when configured"
      (is (= 1 (. (lint-output-scenario :warning-error) :code))))
    (testing "turns the warning off when configured"
      (is (= 0 (. (lint-output-scenario :off) :code))))
    (testing "emits json lines with the same warning status"
      (let [result (lint-project "{:lint {:rules {\"module-style\" :off}}}"
                                 {"a.fnl" "(if x (do (foo) (bar)) nil)\n"}
                                 ["lint" "--all" "--format" "json"])]
        (is (and (= 0 (. result :code)) (string.match (or (. result :lines 1) "") "^%{"))))))

  (deftest lint-exclusions
    (testing "suppresses a matching exclusion in all mode"
      (is (= 0 (. (lint-exclusion-scenario :matching) :code))))
    (testing "reports an unmatched exclusion as a stale error in all mode"
      (let [result (lint-exclusion-scenario :stale)]
        (is (and (= 1 (. result :code))
                 (string.match (or (. result :lines 1) "") "^%.fnl%-extras%.fnl:1:1: error if%-branch%-call: stale exclusion: a%.fnl > missing$"))))))

  (deftest lint-errors-and-read-only
    (testing "returns exit two with a malformed lint configuration error"
      (let [result (lint-error-scenario :config)]
        (is (and (= 2 (. result :code)) (string.match (or (. result :lines 1) "") "not%-a%-rule")))))
    (testing "returns exit two with a source parse diagnostic"
      (let [result (lint-error-scenario :source)]
        (is (and (= 2 (. result :code)) (string.match (or (. result :lines 1) "") "a%.fnl:[0-9]+:[0-9]+:")))))
    (testing "does not change any file in all mode"
      (let [result (lint-output-scenario :warning)]
        (is (= (. result :before) (. result :after)))))))

(defn- shell-args
  [args]
  (table.concat (icollect [_ arg (ipairs args)] (vim.fn.shellescape arg)) " "))

(defn- real-cli-lines
  [root args]
  (let [script  (.. (vim.fn.getcwd) "/scripts/fennel-extras")
        command (..
                 "cd "
                 (vim.fn.shellescape root)
                 " && "
                 (vim.fn.shellescape script)
                 " "
                 (shell-args args))]
    {:code  vim.v.shell_error
     :lines (vim.fn.systemlist ["sh" "-c" (.. command " 2>/dev/null")])}))

(defn- occurrence-count
  [text needle start]
  (let [index (string.find text needle start true)]
    (if index
      (+ 1 (occurrence-count text needle (+ index 1)))
      0)))

(defn- one-json-object-per-line?
  [lines]
  (var valid true)
  (each [_ line (ipairs lines)]
    (when (or (not (string.match line "^%{.*%}$"))
              (not= 1 (occurrence-count line "{\"kind\":" 1)))
      (set valid false)))
  valid)

(defn- real-lint-output-scenario
  [format]
  (let [root          (vim.fn.tempname)
        config        (.. root "/.fnl-extras.fnl")
        first-file    (.. root "/a.fnl")
        second-file   (.. root "/b.fnl")
        config-text   "{:lint {:rules {\"core-require\" :off \"if-branch-call\" :off \"module-style\" :off \"one-is-per-testing\" :error \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}"
        first-source  "(testing \"a\" (is 1) (is 2))\\n(testing \"b\" (is 1) (is 2))\\n"
        second-source "(testing \"c\" (is 1) (is 2))\\n"]
    (vim.fn.mkdir root "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (lint-git-init root)
        (write-file config config-text)
        (write-file first-file first-source)
        (write-file second-file second-source)
        (lint-git-commit root)
        (let [result (real-cli-lines root ["lint" "--all" "--format" format])
              lines  (. result :lines)]
          {:lines                 (length lines)
           :objects               3
           :each-line-one-object? (one-json-object-per-line? lines)})))))

(defn- real-text-lint-output-scenario
  []
  (let [root          (vim.fn.tempname)
        config        (.. root "/.fnl-extras.fnl")
        first-file    (.. root "/a.fnl")
        second-file   (.. root "/b.fnl")
        config-text   "{:lint {:rules {\"core-require\" :off \"if-branch-call\" :off \"module-style\" :off \"one-is-per-testing\" :error \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}"
        first-source  "(testing \"a\" (is 1) (is 2))\\n(testing \"b\" (is 1) (is 2))\\n"
        second-source "(testing \"c\" (is 1) (is 2))\\n"]
    (vim.fn.mkdir root "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (lint-git-init root)
        (write-file config config-text)
        (write-file first-file first-source)
        (write-file second-file second-source)
        (lint-git-commit root)
        (let [result (real-cli-lines root ["lint" "--all"])]
          {:lines   (length (. result :lines))
           :objects 3})))))

(deftest default-printer
  (testing "prints one JSON object per physical line"
    (is (= {:lines 3 :objects 3 :each-line-one-object? true}
           (real-lint-output-scenario "json"))))
  (testing "prints each text finding and exclusion suggestion on its own line"
    (is (= {:lines 6 :objects 3}
           (real-text-lint-output-scenario)))))

(defn- bounded-command
  [command]
  (let [lines (vim.fn.systemlist ["sh" "-c" command])
        code  vim.v.shell_error]
    {:code       code
     :lines      lines
     :timed-out? (= code 142)}))

(defn- bounded-cli
  [root args]
  (let [script  (.. (vim.fn.getcwd) "/scripts/fennel-extras")
        command (..
                 "cd "
                 (vim.fn.shellescape root)
                 " && perl -e 'alarm shift; exec @ARGV' 30 "
                 (vim.fn.shellescape script)
                 " "
                 (shell-args args)
                 " </dev/null 2>&1")]
    (bounded-command command)))

(defn- git-run
  [root args]
  (let [command (..
                 "cd "
                 (vim.fn.shellescape root)
                 " && perl -e 'alarm shift; exec @ARGV' 30 git "
                 (shell-args args)
                 " </dev/null 2>&1")]
    (. (bounded-command command) :code)))

(defn- git-init
  [root]
  (git-run root ["init" "-q"])
  (git-run root ["config" "user.email" "a@b"])
  (git-run root ["config" "user.name" "t"])
  (git-run root ["config" "commit.gpgsign" "false"])
  (git-run root ["config" "tag.gpgsign" "false"])
  root)

(defn- invalid-git-scenario
  [mode]
  (let [root (vim.fn.tempname)]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file (.. root "/.fnl-extras.fnl") "{:lint {:rules {\"core-require\" :off \"if-branch-call\" :warning \"module-style\" :off \"one-is-per-testing\" :off \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}")
        (write-file (.. root "/a.fnl") "(if x 1 2)\\n")
        (let [result (bounded-cli
                      root
                      (if (= mode :all)
                        ["lint" "--all"]
                        ["lint" "--changed"]))
              line   (or (. result :lines 1) "")]
          {:code       (. result :code)
           :line       line
           :timed-out? (. result :timed-out?)})))))

(defn- unborn-git-scenario
  [mode]
  (let [root (vim.fn.tempname)]
    (vim.fn.mkdir root "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (git-init root)
        (write-file (.. root "/.fnl-extras.fnl") "{:lint {:rules {\"core-require\" :off \"if-branch-call\" :off \"module-style\" :off \"one-is-per-testing\" :error \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}")
        (write-file (.. root "/a.fnl") "(testing \"x\") (import-macros {: testing : is} :spec.eca.macros)\n")
        (let [result (bounded-cli
                      root
                      (if (= mode :all)
                        ["lint" "--all"]
                        ["lint" "--changed"]))]
          {:code       (. result :code)
           :lines      (. result :lines)
           :timed-out? (. result :timed-out?)})))))

(defn- changed-config
  []
  "{:lint {:rules {\"core-require\" :off \"defn-args-newline\" :off \"function-shape\" :off \"if-branch-call\" :warning \"module-style\" :off \"one-is-per-testing\" :off \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}")

(defn- changed-source
  [which]
  (if (= which :changed)
    "(defn first []\n  (if z\n      (do\n        (foo)\n        (bar))\n      nil))\n\n(defn second []\n  (if y\n      (do\n        (baz)\n        (qux))\n      nil))\n"
    "(defn first []\n  (if x\n      (do\n        (foo)\n        (bar))\n      nil))\n\n(defn second []\n  (if y\n      (do\n        (baz)\n        (qux))\n      nil))\n"))

(defn- finding-lines
  [lines]
  (let [result []]
    (each [_ line (ipairs lines)]
      (when (not (string.match line "^  "))
        (table.insert result line)))
    result))

(defn- both-source
  []
  "(defn first []\n  (if z\n      (do\n        (foo)\n        (bar))\n      nil))\n\n(defn second []\n  (if q\n      (do\n        (baz)\n        (qux))\n      nil))\n")

(defn- changed-mode-both
  [root source-path]
  (let [_ (write-file source-path (changed-source :changed))
        _ (git-run root ["add" "a.fnl"])]
    (write-file source-path (both-source))))

(defn- changed-mode-staged
  [root source-path]
  (let [_ (write-file source-path (changed-source :changed))]
    (git-run root ["add" "a.fnl"])))

(defn- changed-mode-rename
  [root]
  (let [_ (git-run root ["mv" "a.fnl" "renamed file.fnl"])]
    (write-file (.. root "/renamed file.fnl") (changed-source :changed))))

(defn- changed-mode-scenario
  [mode]
  (let [root        (vim.fn.tempname)
        source-path (.. root "/a.fnl")
        config-path (.. root "/.fnl-extras.fnl")
        subdir      (.. root "/nested")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir subdir "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (git-init root)
        (write-file config-path (changed-config))
        (write-file source-path (changed-source :base))
        (git-run root ["add" "."])
        (git-run root ["commit" "-qm" "base"])
        (if (or (= mode :modified) (= mode :subdir))
          (write-file source-path (changed-source :changed))
          (if (= mode :both)
            (changed-mode-both root source-path)
            (when (= mode :staged)
              (changed-mode-staged root source-path))))
        (when (= mode :untracked)
          (write-file (.. root "/new file.fnl") "(defn new [] (if z (do (foo) (bar)) nil))\n"))
        (when (= mode :rename)
          (changed-mode-rename root))
        (let [cwd    (if (= mode :subdir) subdir root)
              result (bounded-cli cwd ["lint" "--changed"])]
          {:code       (. result :code)
           :lines      (. result :lines)
           :timed-out? (. result :timed-out?)})))))

(defn- base-mode-scenario
  []
  (let [root        (vim.fn.tempname)
        source-path (.. root "/a.fnl")]
    (vim.fn.mkdir root "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (git-init root)
        (write-file (.. root "/.fnl-extras.fnl") (changed-config))
        (write-file source-path (changed-source :base))
        (git-run root ["add" "."])
        (git-run root ["commit" "-qm" "base"])
        (write-file source-path (changed-source :changed))
        (git-run root ["add" "."])
        (git-run root ["commit" "-qm" "changed"])
        (let [result (bounded-cli root ["lint" "--base" "HEAD~1"])]
          {:code       (. result :code)
           :lines      (. result :lines)
           :timed-out? (. result :timed-out?)})))))

(defn- file-size-changed-mode-scenario
  []
  (let [root           (vim.fn.tempname)
        changed-path   (.. root "/changed.fnl")
        unchanged-path (.. root "/unchanged.fnl")
        config         "{:lint {:max-code-lines 2 :rules {\"core-require\" :off \"function-shape\" :off \"if-branch-call\" :off \"module-style\" :off \"no-mutation\" :off \"one-is-per-testing\" :off \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}"
        base-source    "(local a 1)\n(local b 2)\n(local c 3)\n"
        changed-source "(local a 9)\n(local b 2)\n(local c 3)\n"]
    (vim.fn.mkdir root "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (git-init root)
        (write-file (.. root "/.fnl-extras.fnl") config)
        (write-file changed-path base-source)
        (write-file unchanged-path base-source)
        (git-run root ["add" "."])
        (git-run root ["commit" "-qm" "base"])
        (write-file changed-path changed-source)
        (let [result   (bounded-cli root ["lint" "--changed"])
              findings (finding-lines (. result :lines))]
          {:code                (. result :code)
           :changed-file-size   (length (icollect [_ line (ipairs findings)]
                                          (when (string.match line "changed%.fnl:.*file%-size")
                                            line)))
           :unchanged-file-size (length (icollect [_ line (ipairs findings)]
                                          (when (string.match line "unchanged%.fnl:.*file%-size")
                                            line)))})))))

(defn- lint-error-repository-scenario
  [root]
  (write-file (.. root "/a.fnl") "(if x 1 2)\n"))

(defn- lint-error-configured-scenario
  [root]
  (let [_ (git-init root)
        _ (write-file (.. root "/.fnl-extras.fnl") "{:lint {:rules {\"core-require\" :off \"if-branch-call\" :warning \"module-style\" :off \"one-is-per-testing\" :off \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}")
        _ (write-file (.. root "/a.fnl") "(if x 1 2)\n")
        _ (git-run root ["add" "."])]
    (git-run root ["commit" "-qm" "base"])))

(defn- lint-error-mode-scenario
  [mode]
  (let [root (vim.fn.tempname)]
    (vim.fn.mkdir root "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (if (= mode :git)
          (lint-error-repository-scenario root)
          (lint-error-configured-scenario root))
        (let [args   (if (= mode :base)
                       ["lint" "--base" "missing-ref"]
                       (if (or (= mode :changed) (= mode :git))
                         ["lint" "--changed"]
                         ["lint"]))
              result (bounded-cli root args)
              line   (or (. result :lines 1) "")]
          {:code       (. result :code)
           :line       line
           :timed-out? (. result :timed-out?)})))))

(defn- stale-exclusion-scenario
  [mode]
  (let [root        (vim.fn.tempname)
        a-path      (.. root "/a.fnl")
        b-path      (.. root "/b.fnl")
        gone-path   (.. root "/gone.fnl")
        config-path (.. root "/.fnl-extras.fnl")
        config      (if (or (= mode :untouched) (= mode :all))
                      "{:lint {:rules {\"module-style\" :off} :exclusions [{:rule \"if-branch-call\" :form \"b.fnl > missing\" :reason \"old intentional branch\"}]}}"
                      (if (= mode :modified)
                        "{:lint {:rules {\"module-style\" :off} :exclusions [{:rule \"if-branch-call\" :form \"a.fnl > missing\" :reason \"old intentional branch\"}]}}"
                        "{:lint {:rules {\"module-style\" :off} :exclusions [{:rule \"if-branch-call\" :form \"gone.fnl > missing\" :reason \"old intentional branch\"}]}}"))]
    (vim.fn.mkdir root "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (git-init root)
        (write-file config-path config)
        (write-file a-path "(if x (do (foo) (bar)) nil)\n")
        (write-file b-path "(if y (do (baz) (qux)) nil)\n")
        (write-file gone-path "(if z (do (old) (code)) nil)\n")
        (git-run root ["add" "."])
        (git-run root ["commit" "-qm" "base"])
        (if (or (= mode :untouched) (= mode :all))
          (write-file a-path "(if changed (do (foo) (bar)) nil)\n")
          (if (= mode :modified)
            (write-file a-path "(if changed (do (foo) (bar)) nil)\n")
            (git-run root ["rm" "-q" "gone.fnl"])))
        (let [result (bounded-cli
                      root
                      (if (= mode :all)
                        ["lint" "--all"]
                        ["lint" "--changed"]))]
          {:code       (. result :code)
           :lines      (. result :lines)
           :timed-out? (. result :timed-out?)})))))

(defn- shallow-clone-scenario
  [mode]
  (let [source        (vim.fn.tempname)
        clone         (vim.fn.tempname)
        config        "{:lint {:rules {\"module-style\" :off}}}"
        clone-command (..
                       "git clone --depth 1 "
                       (vim.fn.shellescape (.. "file://" source)
                       )
                       " "
                       (vim.fn.shellescape clone)
                       " </dev/null 2>&1")]
    (vim.fn.mkdir source "p")
    (with-cleanup
      (fn []
        (vim.fn.delete source "rf")
        (vim.fn.delete clone "rf"))
      (fn []
        (git-init source)
        (write-file (.. source "/.fnl-extras.fnl") config)
        (write-file (.. source "/a.fnl") "(if x 1 2)\n")
        (git-run source ["add" "."])
        (git-run source ["commit" "-qm" "base"])
        (let [clone-result (bounded-command clone-command)]
          (if (not= 0 (. clone-result :code))
            {:code       (. clone-result :code)
             :lines      (. clone-result :lines)
             :timed-out? (. clone-result :timed-out?)}
            (let [result (bounded-cli
                          clone
                          (if (= mode :all)
                            ["lint" "--all"]
                            ["lint" "--changed"]))]
              {:code       (. result :code)
               :lines      (. result :lines)
               :timed-out? (. result :timed-out?)})))))))

(defn- default-lint-scenario
  [mode]
  (let [root        (vim.fn.tempname)
        config      (.. root "/.fnl-extras.fnl")
        warn        (.. root "/warning.fnl")
        config-text "{:lint {:rules {\"core-require\" :off \"function-shape\" :off \"if-branch-call\" :warning \"module-style\" :off \"one-is-per-testing\" :error \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}"]
    (vim.fn.mkdir root "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file config config-text)
        (write-file warn "(if x (do (foo) (bar)) nil)\n")
        (if (= mode :git)
          (let [_      (git-init root)
                _      (git-run root ["add" "."])
                _      (git-run root ["commit" "-qm" "base"])
                result (bounded-cli root ["lint"])]
            {:code (. result :code) :lines (. result :lines)})
          (let [result (bounded-cli root ["lint"])]
            {:code (. result :code) :lines (. result :lines)}))))))

(defn- default-lint-all-files-scenario
  []
  (let [root        (vim.fn.tempname)
        config      (.. root "/.fnl-extras.fnl")
        warn        (.. root "/warning.fnl")
        error       (.. root "/error.fnl")
        config-text "{:lint {:rules {\"core-require\" :off \"function-shape\" :off \"if-branch-call\" :warning \"module-style\" :off \"one-is-per-testing\" :error \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}"]
    (vim.fn.mkdir root "p")
    (with-cleanup
      (fn [] (vim.fn.delete root "rf"))
      (fn []
        (git-init root)
        (write-file config config-text)
        (write-file warn "(if x (do (foo) (bar)) nil)\n")
        (write-file error "(testing \"x\" (is 1) (is 2))\n")
        (git-run root ["add" "."])
        (git-run root ["commit" "-qm" "base"])
        (let [result (bounded-cli root ["lint"])]
          {:code (. result :code) :lines (. result :lines)})))))

(deftest lint-default-selection
  (testing "default lint reports findings from all committed files"
    (let [result (default-lint-all-files-scenario)
          text   (table.concat (. result :lines) "\n")]
      (is (and (= 1 (. result :code))
               (string.match text "warning%.fnl:1:7: warning if%-branch%-call")
               (string.match text "error%.fnl:1:1: error one%-is%-per%-testing")))))
  (testing "default lint works without a Git repository"
    (let [result (default-lint-scenario :no-git)
          text   (table.concat (. result :lines) "\n")]
      (is (and (= 0 (. result :code))
               (string.match text "warning%.fnl:1:7: warning if%-branch%-call")
               (not (string.match text "lint requires a Git repository")))))))

(deftest git-changed-selection
  (testing "clean repositories produce no changed-mode findings"
    (is (= {:code 0 :lines [] :timed-out? false} (changed-mode-scenario :clean))))
  (testing "modified files report only the warning whose form intersects changed lines"
    (let [result   (changed-mode-scenario :modified)
          findings (finding-lines (. result :lines))]
      (is (and (= 0 (. result :code))
               (= 1 (length findings))
               (= 2 (length (. result :lines)))
               (string.match (. result :lines 2) "defn:first")))))
  (testing "staged-only changes are selected"
    (let [result (changed-mode-scenario :staged)]
      (is (= 1 (length (finding-lines (. result :lines)))))))
  (testing "staged and unstaged changes are unioned against HEAD"
    (let [result (changed-mode-scenario :both)]
      (is (= 2 (length (finding-lines (. result :lines)))))))
  (testing "untracked files are selected as whole files"
    (let [result (changed-mode-scenario :untracked)]
      (is (= 1 (length (finding-lines (. result :lines)))))))
  (testing "renamed destinations are selected as whole files and paths with spaces survive"
    (let [result   (changed-mode-scenario :rename)
          findings (finding-lines (. result :lines))]
      (is (and (= 2 (length findings))
               (string.match (. result :lines 1) "renamed file%.fnl")))))
  (testing "subdirectory invocation matches root changed-mode selection without timing out"
    (let [root-result   (changed-mode-scenario :modified)
          subdir-result (changed-mode-scenario :subdir)
          root          (finding-lines (. root-result :lines))
          subdir        (finding-lines (. subdir-result :lines))]
      (is (and (not (. root-result :timed-out?))
               (not (. subdir-result :timed-out?))
               (= (length root) (length subdir))))))
  (testing "changed oversized files report exactly one file-size finding"
    (is (= 1 (. (file-size-changed-mode-scenario) :changed-file-size))))
  (testing "unchanged oversized files do not report file-size findings in changed mode"
    (is (= 0 (. (file-size-changed-mode-scenario) :unchanged-file-size)))))

(deftest git-base-and-errors
  (testing "base ref includes committed changes since the selected base"
    (is (= 1 (length (finding-lines (. (base-mode-scenario) :lines))))))
  (testing "changed lint outside a Git repository exits two with the repository message"
    (let [result (lint-error-mode-scenario :git)]
      (is (and (= 2 (. result :code))
               (string.match (. result :line) "lint requires a Git repository")))))
  (testing "lint all works in an empty Git directory without resolving Git state"
    (let [result (invalid-git-scenario :all)]
      (is (and (= 0 (. result :code))
               (= "" (. result :line))))))
  (testing "changed lint rejects an empty Git directory with the repository message"
    (let [result (invalid-git-scenario :changed)]
      (is (and (= 2 (. result :code))
               (string.match (. result :line) "lint requires a Git repository")))))
  (testing "an unknown base ref exits two and names the ref"
    (let [result (lint-error-mode-scenario :base)]
      (is (and (= 2 (. result :code))
               (string.match (. result :line) "missing%-ref")))))
  (testing "all mode lints an unborn repository without resolving HEAD"
    (is (= {:code       1
            :lines      ["a.fnl:1:1: error one-is-per-testing: each testing form must contain exactly one is"
                         "  exclusion: {:rule \"one-is-per-testing\" :form \"a.fnl > top#1 > testing#1\" :reason \"explain why this is intentional\"}"]
            :timed-out? false}
           (unborn-git-scenario :all))))
  (testing "changed mode reports the unknown unborn HEAD base"
    (is (= {:code 2 :lines ["unknown base ref: HEAD"] :timed-out? false}
           (unborn-git-scenario :changed)))))

(deftest stale-exclusion-scope
  (testing "an untouched file's stale exclusion does not fail changed mode"
    (is (= {:code 0 :lines [] :timed-out? false}
           (stale-exclusion-scenario :untouched))))
  (testing "a stale exclusion in a modified file fails changed mode with its stale line"
    (is (= {:code       1
            :lines      [".fnl-extras.fnl:1:1: error if-branch-call: stale exclusion: a.fnl > missing"]
            :timed-out? false}
           (stale-exclusion-scenario :modified))))
  (testing "a deleted file's exclusion is stale in changed mode"
    (is (= {:code       1
            :lines      [".fnl-extras.fnl:1:1: error if-branch-call: stale exclusion: gone.fnl > missing"]
            :timed-out? false}
           (stale-exclusion-scenario :deleted))))
  (testing "all mode reports stale exclusions regardless of file scope"
    (is (= {:code       1
            :lines      [".fnl-extras.fnl:1:1: error if-branch-call: stale exclusion: b.fnl > missing"]
            :timed-out? false}
           (stale-exclusion-scenario :all)))))

(deftest shallow-clone
  (testing "a shallow clone exits two with the full-clone message"
    (let [result (shallow-clone-scenario :changed)
          line   (or (. result :lines 1) "")]
      (is (and (not (. result :timed-out?))
               (= 2 (. result :code))
               (string.match line "full clone")))))
  (testing "all mode lints a shallow clone without requiring a full clone"
    (let [result (shallow-clone-scenario :all)]
      (is (and (not (. result :timed-out?))
               (= 0 (. result :code))
               (= 0 (length (. result :lines))))))))

(deftest lint-all-git-boundary
  (testing "default all mode does not require a Git repository"
    (is (= 0 (. (default-lint-scenario :no-git) :code)))))

(deftest align-bindings-cli
  (testing "check reports missing binding alignment and write fixes it"
    (let [result (align-bindings-cli-scenario)]
      (is (and (= 1 (. result :check-code))
               (vim.deep_equal ["a.fnl"] (. result :check-lines))
               (= 0 (. result :write-code))
               (vim.deep_equal ["a.fnl"] (. result :write-lines))
               (= (. result :expected) (. result :content)))))))
