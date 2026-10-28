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



(defn- format-config
  [body]
  (let [workspace? (or (string.find body ":paths")
                       (string.find body ":exclude")
                       (string.find body ":extensions")
                       (string.find body ":dotfiles")
                       (string.find body ":symlinks"))
        workspace  (if workspace?
                     (.. "{" body
                         (if (string.find body ":extensions") "" " :extensions [\".fnl\" \".fnlm\"]")
                         (if (string.find body ":dotfiles") "" " :dotfiles false")
                         (if (string.find body ":symlinks") "" " :symlinks false")
                         (if (string.find body ":paths") "" " :paths [\".\"]")
                         "}")
                     "{:extensions [\".fnl\" \".fnlm\"] :dotfiles false :symlinks false :paths [\".\"]}")
        format     (if workspace?
                     "{:indent-width 2 :builtins {\"fn\" [[:inner 0]] \"let\" [[:block 1]] \"when\" [[:block 1]] \"do\" [[:block 0]]} :prefix-fallbacks {\"def\" [[:inner 0]] \"with-\" [[:block 1]]} :parser false :alignment {:bindings false :maps false :clauses false :split-bindings false :collapse-padding false :binding-forms [\"let\" \"when-let\" \"if-let\" \"with-open\"] :clause-forms [\"case\" \"match\" \"case-try\" \"match-try\" \"if\"]}}"
                     (.. "{:indent-width 2 :builtins {\"fn\" [[:inner 0]] \"let\" [[:block 1]] \"when\" [[:block 1]] \"do\" [[:block 0]]} :prefix-fallbacks {\"def\" [[:inner 0]] \"with-\" [[:block 1]]} :parser false :alignment {:bindings false :maps false :clauses false :split-bindings false :collapse-padding false :binding-forms [\"let\" \"when-let\" \"if-let\" \"with-open\"] :clause-forms [\"case\" \"match\" \"case-try\" \"match-try\" \"if\"]} " body "}"))]
    (.. "{:workspace " workspace " :format " format " :lint {:rules {}}}")))



(defn- run-cli
  [root args]
  (let [lines []
        cli   (load-cli)]
    (if (. cli :module-missing)
      cli
      {:code  (cli.run args
                       {:cwd   root
                        :print (fn [line] (table.insert lines line))})


       :lines lines})))



(defn- check-scenario-result
  [root path expected-code expected-lines]
  (let [result (run-cli root ["format" "--check" "a.fnl"])]
    {:code           (. result :code)
     :lines          (. result :lines)
     :content        (read-file path)
     :expected-code  expected-code
     :expected-lines expected-lines}))



(defn- check-scenario-body
  [root path source expected-code expected-lines]
  (write-file (.. root "/.fnl-extras.fnl") (format-config ""))
  (write-file path source)
  (check-scenario-result root path expected-code expected-lines))



(defn- check-scenario
  [source expected-code expected-lines]
  (let [root (vim.fn.tempname)
        path (.. root "/a.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup (fn [] (vim.fn.delete root "rf"))


      (fn [] (check-scenario-body root path source expected-code expected-lines)))))



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



(defn- write-scenario-body
  [root good bad mode]
  (write-file (.. root "/.fnl-extras.fnl") (format-config ""))
  (or (and (= mode :good) (write-good-scenario root good))
      (and (= mode :formatted) (write-formatted-scenario root good))
      (write-error-scenario root good bad)))



(defn- write-scenario
  [mode]
  (let [root (vim.fn.tempname)
        good (.. root "/good.fnl")
        bad  (.. root "/bad.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup (fn [] (vim.fn.delete root "rf"))


      (fn [] (write-scenario-body root good bad mode)))))



(defn- config-indent-scenario
  [root src-file config-path]
  (let [_      (write-file config-path (format-config ":indents {\"deftest\" [[:block 1]]}"))
        _      (write-file src-file "(deftest t\n(foo))\n")
        result (run-cli root ["format" "--write" "src/a.fnl"])]
    {:code    (. result :code)
     :lines   (. result :lines)
     :content (read-file src-file)}))



(defn- config-exclude-scenario
  [root src-file skip-file config-path]
  (let [_      (write-file config-path (format-config ":exclude [\"skip\"]"))
        _      (write-file src-file "(when x\n  y)\n")
        _      (write-file skip-file "(when x\ny)\n")
        result (run-cli root ["format" "--write"])]
    {:code    (. result :code)
     :lines   (. result :lines)
     :content (read-file skip-file)}))



(defn- config-paths-scenario
  [root src-file skip-file config-path]
  (let [_      (write-file config-path (format-config ":paths [\"src\"]"))
        _      (write-file src-file "(when x\ny)\n")
        _      (write-file skip-file "(when x\ny)\n")
        result (run-cli root ["format" "--write"])]
    {:code  (. result :code)
     :lines (. result :lines)
     :src   (read-file src-file)
     :skip  (read-file skip-file)}))



(defn- config-invalid-scenario
  [root src-file config-path]
  (let [_      (write-file config-path "{:workspace {:paths [\".\"] :extensions [\".fnl\"]} :format {:indent-width 2 :builtins false :prefix-fallbacks false :parser false} :lint {:rules {}} :colour 1}")
        result (run-cli root ["format" "--check" "src/a.fnl"])]
    {:code  (. result :code)
     :lines (. result :lines)}))



(defn- config-scenario-body
  [mode root src-file skip-file config-path]
  (or (and (= mode :indent) (config-indent-scenario root src-file config-path))
      (and (= mode :exclude) (config-exclude-scenario root src-file skip-file config-path))
      (and (= mode :paths) (config-paths-scenario root src-file skip-file config-path))
      (config-invalid-scenario root src-file config-path)))



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
    (with-cleanup (fn [] (vim.fn.delete root "rf"))


      (fn [] (config-scenario-body mode root src-file skip-file config-path)))))



(defn- align-bindings-cli-scenario-result
  [root path expected]
  (let [check-result (run-cli root ["format" "--check" "a.fnl"])
        write-result (run-cli root ["format" "--write" "a.fnl"])]
    {:check-code  (. check-result :code)
     :check-lines (. check-result :lines)
     :write-code  (. write-result :code)
     :write-lines (. write-result :lines)
     :content     (read-file path)
     :expected    expected}))



(defn- align-bindings-cli-scenario-body
  [root path config-path source expected]
  (write-file config-path "{:indent-width 2 :builtins {\"fn\" [[:inner 0]] \"lambda\" [[:inner 0]] \"macro\" [[:inner 0]] \"let\" [[:block 1]] \"when\" [[:block 1]] \"when-let\" [[:block 1]] \"if-let\" [[:block 1]] \"each\" [[:block 1]] \"for\" [[:block 1]] \"icollect\" [[:block 1]] \"collect\" [[:block 1]] \"accumulate\" [[:block 1]] \"case\" [[:block 1]] \"match\" [[:block 1]] \"case-try\" [[:block 1]] \"match-try\" [[:block 1]] \"while\" [[:block 1]] \"with-open\" [[:block 1]] \"do\" [[:block 0]]} :prefix-fallbacks {\"def\" [[:inner 0]] \"with-\" [[:block 1]]} :parser false :alignment {:bindings true :maps true :clauses true :split-bindings true :collapse-padding true :binding-forms [\"let\" \"when-let\" \"if-let\" \"with-open\"] :clause-forms [\"case\" \"match\" \"case-try\" \"match-try\" \"if\"]}}")
  (write-file path source)
  (align-bindings-cli-scenario-result root path expected))



(defn- align-bindings-cli-scenario
  []
  (let [root        (vim.fn.tempname)
        path        (.. root "/a.fnl")
        config-path (.. root "/.fnl-extras.fnl")
        source      "(let [a 1\n      long-name 2]\n  a)"
        expected    "(let [a         1\n      long-name 2]\n  a)"]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup (fn [] (vim.fn.delete root "rf"))


      (fn [] (align-bindings-cli-scenario-body root path config-path source expected)))))



(deftest cli-check



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



(defn- extension-scenario-body
  [extension root path config-path]
  (write-file config-path (format-config (.. ":extensions [\"" extension "\"]")))
  (or (and (= extension ".fnl") (extension-fnl-scenario root path config-path))
      (extension-other-scenario root path config-path)))



(defn- extension-scenario
  [extension]
  (let [root        (vim.fn.tempname)
        path        (.. root "/source" extension)
        config-path (.. root "/.fnl-extras.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup (fn [] (vim.fn.delete root "rf"))


      (fn [] (extension-scenario-body extension root path config-path)))))



(defn- default-path-scenario
  []
  (let [root (vim.fn.tempname)
        path (.. root "/source.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup (fn [] (vim.fn.delete root "rf"))


      (fn []
        (write-file path "(when x\ny)\n")
        (let [result (run-cli root ["format" "--write"])]
          {:code    (. result :code)
           :lines   (. result :lines)
           :content (read-file path)})))))



(defn- dotfiles-scenario-setup
  [root hidden-file nested-file git-file]
  (write-file (.. root "/.fnl-extras.fnl") (format-config ":paths [\"fnl\"] :dotfiles false"))
  (write-file hidden-file "(when x\ny)\n")
  (write-file nested-file "(when x\ny)\n")
  (write-file git-file "(when x\ny)\n"))



(defn- dotfiles-scenario-body
  [root hidden-file nested-file git-file]
  (let [_      (dotfiles-scenario-setup root hidden-file nested-file git-file)
        result (run-cli root ["format" "--check"])]
    {:code   (. result :code)
     :lines  (. result :lines)
     :hidden (. (vim.loop.fs_stat hidden-file) :type)
     :nested (. (vim.loop.fs_stat nested-file) :type)
     :git    (read-file git-file)}))



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
    (with-cleanup (fn [] (vim.fn.delete root "rf"))


      (fn [] (dotfiles-scenario-body root hidden-file nested-file git-file)))))



(defn- follow-symlink-scenario-setup
  [root link target]
  (write-file (.. root "/.fnl-extras.fnl") (format-config ":paths [\"fnl\"] :symlinks true"))
  (write-file target "(when x\ny)\n")
  (assert (vim.loop.fs_symlink target link)))



(defn- follow-symlink-scenario-body
  [root outside link target]
  (let [_      (follow-symlink-scenario-setup root link target)
        result (run-cli root ["format" "--write"])]
    {:code      (. result :code)
     :lines     (. result :lines)
     :link-type (. (vim.loop.fs_lstat link) :type)
     :target    (read-file target)}))



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
    (with-cleanup (fn []
                    (vim.fn.delete root "rf")
                    (vim.fn.delete outside "rf"))


      (fn [] (follow-symlink-scenario-body root outside link target)))))



(defn- follow-directory-symlink-check-result
  [root target]
  (let [result (run-cli root ["format" "--check"])]
    {:code   (. result :code)
     :lines  (. result :lines)
     :target (read-file target)}))



(defn- follow-directory-symlink-write-result
  [root link target]
  (let [result (run-cli root ["format" "--write"])]
    {:code      (. result :code)
     :link-type (. (vim.loop.fs_lstat link) :type)
     :target    (read-file target)}))



(defn- follow-directory-symlink-result
  [mode root link target]
  (or (and (= mode :check) (follow-directory-symlink-check-result root target))
      (follow-directory-symlink-write-result root link target)))



(defn- follow-directory-symlink-scenario-setup
  [root link target outside]
  (write-file (.. root "/.fnl-extras.fnl") (format-config ":symlinks true"))
  (write-file target "(when x\ny)\n")
  (assert (vim.loop.fs_symlink outside link)))



(defn- follow-directory-symlink-scenario-body
  [mode root link target outside]
  (let [_ (follow-directory-symlink-scenario-setup root link target outside)]
    (follow-directory-symlink-result mode root link target)))



(defn- follow-directory-symlink-scenario
  [mode]
  (let [root    (vim.fn.tempname)
        outside (vim.fn.tempname)
        link    (.. root "/linkdir")
        target  (.. outside "/a.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir outside "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup (fn []
                    (vim.fn.delete root "rf")
                    (vim.fn.delete outside "rf"))


      (fn [] (follow-directory-symlink-scenario-body mode root link target outside)))))



(defn- parser-scenario-setup
  [path config-path]
  (write-file path "(when x\ny)\n")
  (write-file config-path (format-config ":parser \"missing.parser.module\"")))



(defn- parser-scenario-args
  [mode]
  (if (= mode :config)
    ["format" "--check" "a.fnl"]
    ["format" "--check" "--parser" "eca.nfnl.fennel" "a.fnl"]))



(defn- parser-scenario-body
  [mode root path config-path]
  (let [_      (parser-scenario-setup path config-path)
        result (run-cli root (parser-scenario-args mode))]
    {:code  (. result :code)
     :lines (. result :lines)}))



(defn- parser-scenario
  [mode]
  (let [root        (vim.fn.tempname)
        path        (.. root "/a.fnl")
        config-path (.. root "/.fnl-extras.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup (fn [] (vim.fn.delete root "rf"))


      (fn [] (parser-scenario-body mode root path config-path)))))



(defn- rule-config-scenario-setup
  [path config-path config source]
  (write-file config-path (format-config config))
  (write-file path source))



(defn- rule-config-scenario-body
  [root path config-path config source expected]
  (let [_      (rule-config-scenario-setup path config-path config source)
        result (run-cli root ["format" "--write" "a.fnl"])]
    {:code     (. result :code)
     :lines    (. result :lines)
     :content  (read-file path)
     :expected expected}))



(defn- rule-config-scenario
  [config source expected]
  (let [root        (vim.fn.tempname)
        path        (.. root "/a.fnl")
        config-path (.. root "/.fnl-extras.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup (fn [] (vim.fn.delete root "rf"))


      (fn [] (rule-config-scenario-body root path config-path config source expected)))))



(defn- config-discovery-scenario-setup
  [config-path source-path]
  (write-file config-path (format-config ":dotfiles false"))
  (write-file source-path "(when x\ny)\n"))



(defn- config-discovery-scenario-args
  [mode]
  (if (= mode :check)
    ["format" "--check"]
    ["format" "--write"]))



(defn- config-discovery-scenario-body
  [mode root config-path source-path]
  (let [_      (config-discovery-scenario-setup config-path source-path)
        result (run-cli root (config-discovery-scenario-args mode))]
    {:code   (. result :code)
     :lines  (. result :lines)
     :config (read-file config-path)
     :source (read-file source-path)}))



(defn- config-discovery-scenario
  [mode]
  (let [root        (vim.fn.tempname)
        config-path (.. root "/.fnl-extras.fnl")
        source-path (.. root "/a.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup (fn [] (vim.fn.delete root "rf"))


      (fn [] (config-discovery-scenario-body mode root config-path source-path)))))



(deftest cli-new-configuration



  (testing "uses only configured extensions during discovery"
    (is (= {:code 1 :lines ["source.fnl"]}
           (extension-scenario ".fnl"))))



  (testing "discovers a configured non-default extension"
    (is (= {:code 1 :lines ["source.fnlx"]}
           (extension-scenario ".fnlx"))))



  (testing "missing paths and config are reported instead of using a current-directory default"
    (is (= {:code 2 :lines ["config: missing .fnl-extras.fnl"] :content "(when x\ny)\n"}
           (default-path-scenario))))



  (testing "skips dotfiles and dot-directories when dotfiles is false and never .git"
    (is (= {:code   2
            :lines  ["no files found"]
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

(defn- symlink-loop-scenario-setup
  [root file loop-path]
  (write-file (.. root "/.fnl-extras.fnl") (format-config ":paths [\"fnl\"]"))
  (write-file file "(when x\ny)\n")
  (assert (vim.loop.fs_symlink root loop-path)))



(defn- symlink-loop-scenario-body
  [root file loop-path script]
  (let [_       (symlink-loop-scenario-setup root file loop-path)
        command (.. "cd "
                    (vim.fn.shellescape root)
                    " && perl -e 'alarm shift; exec @ARGV' 10 "
                    (vim.fn.shellescape script)
                    " format --check")
        lines   (vim.fn.systemlist ["sh" "-c" command])]
    {:code  vim.v.shell_error
     :lines lines}))



(defn- symlink-loop-scenario
  []
  (let [root      (vim.fn.tempname)
        fnl-dir   (.. root "/fnl")
        file      (.. fnl-dir "/a.fnl")
        loop-path (.. fnl-dir "/loop")
        script    (.. (vim.fn.getcwd) "/scripts/fennel-extras")]
    (vim.fn.mkdir fnl-dir "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup (fn [] (vim.fn.delete root "rf"))


      (fn [] (symlink-loop-scenario-body root file loop-path script)))))



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



(defn- two-phase-write-scenario-setup
  [root good blocked read-only]
  (write-file (.. root "/.fnl-extras.fnl") (format-config ":paths [\"fnl\"]"))
  (write-file good "(when x\ny)\n")
  (write-file blocked "(when y\nz)\n")
  (vim.fn.setfperm read-only "r-xr-xr-x"))



(defn- two-phase-write-scenario-body
  [root read-only good blocked probe]
  (let [_          (two-phase-write-scenario-setup root good blocked read-only)
        probe-file (io.open probe :w)]
    (if probe-file
      (two-phase-skipped-scenario probe-file probe)
      (two-phase-write-attempt root good))))



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
    (with-cleanup (fn []
                    (vim.fn.setfperm read-only "rwxr-xr-x")
                    (vim.fn.delete root "rf"))


      (fn [] (two-phase-write-scenario-body root read-only good blocked probe)))))



(defn- dotfile-config-scenario
  [root fnl-dir]
  (let [_      (write-file (.. root "/.fnl-extras.fnl") (format-config ""))
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
    (with-cleanup (fn [] (vim.fn.delete root "rf"))


      (fn []
        (if (= mode :config)
          (dotfile-config-scenario root fnl-dir)
          (dotfile-source-scenario root))))))



(defn- symlink-file-scenario-setup
  [root good link target]
  (write-file (.. root "/.fnl-extras.fnl") (format-config ":paths [\"fnl\"]"))
  (write-file good "(when x\n  y)\n")
  (write-file target "(when x\ny)\n")
  (assert (vim.loop.fs_symlink target link)))



(defn- symlink-file-scenario-args
  [mode]
  (if (= mode :write)
    ["format" "--write"]
    ["format" "--check" "fnl/link.fnl"]))



(defn- symlink-file-scenario-body
  [mode root good link target]
  (let [_      (symlink-file-scenario-setup root good link target)
        result (run-cli root (symlink-file-scenario-args mode))]
    {:code      (. result :code)
     :lines     (. result :lines)
     :link-type (. (vim.loop.fs_lstat link) :type)
     :target    (read-file target)}))



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
    (with-cleanup (fn []
                    (vim.fn.delete root "rf")
                    (vim.fn.delete outside "rf"))


      (fn [] (symlink-file-scenario-body mode root good link target)))))



(defn- follow-symlink-dedupe-scenario-setup
  [root target link]
  (write-file (.. root "/.fnl-extras.fnl") (format-config ":symlinks true"))
  (write-file target "(when x\ny)\n")
  (assert (vim.loop.fs_symlink target link)))



(defn- follow-symlink-dedupe-scenario-body
  [root target link]
  (let [_      (follow-symlink-dedupe-scenario-setup root target link)
        result (run-cli root ["format" "--write"])]
    {:code      (. result :code)
     :lines     (. result :lines)
     :link-type (. (vim.loop.fs_lstat link) :type)
     :target    (read-file target)}))



(defn- follow-symlink-dedupe-scenario
  []
  (let [root   (vim.fn.tempname)
        target (.. root "/a.fnl")
        link   (.. root "/b.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup (fn [] (vim.fn.delete root "rf"))


      (fn [] (follow-symlink-dedupe-scenario-body root target link)))))



(defn- follow-symlink-cycle-scenario-setup
  [root file loop-path]
  (write-file (.. root "/.fnl-extras.fnl") (format-config ":symlinks true"))
  (write-file file "(when x\ny)\n")
  (assert (vim.loop.fs_symlink root loop-path)))



(defn- follow-symlink-cycle-scenario-body
  [root file loop-path]
  (let [_      (follow-symlink-cycle-scenario-setup root file loop-path)
        result (run-cli root ["format" "--check"])]
    {:code  (. result :code)
     :lines (. result :lines)}))



(defn- follow-symlink-cycle-scenario
  []
  (let [root      (vim.fn.tempname)
        directory (.. root "/d")
        file      (.. directory "/x.fnl")
        loop-path (.. directory "/loop")]
    (vim.fn.mkdir directory "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup (fn [] (vim.fn.delete root "rf"))


      (fn [] (follow-symlink-cycle-scenario-body root file loop-path)))))



(defn- follow-symlink-explicit-scenario-setup
  [root target link]
  (write-file (.. root "/.fnl-extras.fnl") (format-config ":symlinks true"))
  (write-file target "(when x\ny)\n")
  (assert (vim.loop.fs_symlink target link)))



(defn- follow-symlink-explicit-scenario-body
  [root target link]
  (let [_      (follow-symlink-explicit-scenario-setup root target link)
        result (run-cli root ["format" "--check" "link.fnl"])]
    {:code  (. result :code)
     :lines (. result :lines)}))



(defn- follow-symlink-explicit-scenario
  []
  (let [root   (vim.fn.tempname)
        target (.. root "/real.fnl")
        link   (.. root "/link.fnl")]
    (vim.fn.mkdir root "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup (fn [] (vim.fn.delete root "rf"))


      (fn [] (follow-symlink-explicit-scenario-body root target link)))))



(defn- unreadable-directory-result
  [root]
  (let [result (run-cli root ["format" "--check"])
        lines  (. result :lines)]
    {:code                (. result :code)
     :mentions-read-error (not (not (string.match (or (. lines 1) "") "cannot read directory")))}))



(defn- unreadable-directory-scenario-setup
  [root locked good]
  (write-file (.. root "/.fnl-extras.fnl") (format-config ":paths [\"fnl\"]"))
  (write-file good "(when x\n  y)\n")
  (vim.fn.setfperm locked "---------"))



(defn- unreadable-directory-scenario-body
  [root locked good]
  (let [_      (unreadable-directory-scenario-setup root locked good)
        handle (vim.loop.fs_scandir locked)]
    (if handle
      {:skipped-root true}
      (unreadable-directory-result root))))



(defn- unreadable-directory-scenario
  []
  (let [root    (vim.fn.tempname)
        fnl-dir (.. root "/fnl")
        locked  (.. fnl-dir "/locked")
        good    (.. fnl-dir "/a.fnl")]
    (vim.fn.mkdir locked "p")
    (vim.fn.mkdir (.. root "/.git") "p")
    (with-cleanup (fn []
                    (vim.fn.setfperm locked "rwxr-xr-x")
                    (vim.fn.delete root "rf"))


      (fn [] (unreadable-directory-scenario-body root locked good)))))



(deftest configured-formatting-rules



  (testing "uses configured indent-width"
    (is (= {:code     0
            :lines    ["a.fnl"]
            :content  "(when x\n    y)\n"
            :expected "(when x\n    y)\n"}
           (rule-config-scenario ":indent-width 4"
                                 "(when x\ny)\n"
                                 "(when x\n    y)\n"))))



  (testing "disables built-in indentation rules when builtins is false"
    (is (= {:code     0
            :lines    ["a.fnl"]
            :content  "(let [x 1]\n     x)\n"
            :expected "(let [x 1]\n     x)\n"}
           (rule-config-scenario ":builtins false"
                                 "(let [x 1]\nx)\n"
                                 "(let [x 1]\n     x)\n"))))



  (testing "disables prefix fallback indentation rules when prefix-fallbacks is false"
    (is (= {:code     0
            :lines    ["a.fnl"]
            :content  "(defn x\n      y)\n"
            :expected "(defn x\n      y)\n"}
           (rule-config-scenario ":prefix-fallbacks false"
                                 "(defn x\ny)\n"
                                 "(defn x\n      y)\n")))))

(deftest config-file-discovery



  (testing "does not report the discovered config file as a formatting target"
    (is (= {:code   1
            :lines  ["a.fnl"]
            :config (format-config ":dotfiles false")
            :source "(when x\ny)\n"}
           (config-discovery-scenario :check))))



  (testing "does not rewrite the discovered config file"
    (is (= {:code   0
            :lines  ["a.fnl"]
            :config (format-config ":dotfiles false")
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



  (testing "a format command without a config file exits two"
    (is (= {:code 2 :lines ["config: missing .fnl-extras.fnl"]} (dotfile-scenario :source))))



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
        command      (.. "cd "
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



(local lint-rule-options
       {"module-style"     ":applies-to {:files [\"^[^s]\"]} :options {:module \"eca.nfnl.macros.aniseed\" :forms [\"module\" \"def\" \"defn\" \"defn-\"]}"
        "macro-import"     ":applies-to {:files [\"^spec/\"]} :options {:module \"spec.eca.macros\" :forms [\"deftest\" \"testing\" \"is\"] :exempt-files [\"^spec/eca/macros[.]fnlm$\"]}"
        "no-module"        ":applies-to {:files [\"^spec/\"]} :options {:module \"module\"}"
        "direct-require"   ":applies-to {:files [\"^spec/\"]} :options {:modules [\"plenary.busted\" \"luassert\"] :exempt-files [\"^spec/eca/macros[.]fnlm$\"]}"
        "form-child-count" ":applies-to {:forms [\"testing\"]} :options {:children [\"is\"] :max-count 1}"
        "if-branch-call"   ":applies-to {} :options {:forms [\"if\"]}"
        "if-without-else"  ":applies-to {} :options {:forms [\"if\"] :nil-else true}"
        "control-layout"   ":applies-to {} :options {:forms [\"if\" \"when\" \"and\" \"or\" \"case\" \"match\"]}"
        "function-shape"   ":applies-to {} :options {:forms [\"defn\" \"defn-\" \"fn\" \"lambda\" \"λ\"]}"
        "no-mutation"      ":applies-to {:files [\"^[^s]\"]} :options {:forms [\"var\" \"set\" \"while\"]}"
        "file-size"        ":applies-to {:files [\"^[^s]\"]} :options {:max-code-lines 300}"
        "direct-require"   ":applies-to {} :options {:module \"eca.nfnl.core\" :binding \"core\"}"
        "unused-and-or"    ":applies-to {} :options {:forms [\"and\" \"or\"]}"
        "binding-per-line" ":applies-to {} :options {:forms [\"let\" \"when-let\" \"if-let\" \"with-open\"]}"
        "call-data-arg"    ":applies-to {:files [\"^[^s]\"]} :options {:forms []}"})

(defn- lint-config-rule
  [normalized rule options]
  (let [escaped-rule        (string.gsub rule "-" "%%-")
        warning-pattern     (.. "\"" escaped-rule "\"%s*:%s*warning")
        warning-replacement (.. "\"" rule "\" [{:severity :warning :applies-to {} :options {" options "} :exclusions []}]")
        error-pattern       (.. "\"" escaped-rule "\"%s*:%s*error")
        error-replacement   (.. "\"" rule "\" [{:severity :error :applies-to {} :options {" options "} :exclusions []}]")
        off-pattern         (.. "\"" escaped-rule "\"%s*:%s*off")
        off-replacement     (.. "\"" rule "\" [{:severity :off :applies-to {} :options {} :exclusions []}]")
        normalized          (string.gsub normalized warning-pattern warning-replacement)
        normalized          (string.gsub normalized error-pattern error-replacement)]
    (string.gsub normalized off-pattern off-replacement)))



(defn- lint-config-rules
  [config]
  (var normalized config)
  (each [rule options (pairs lint-rule-options)]
    (set normalized (lint-config-rule normalized rule options))
    (let [escaped-rule (string.gsub rule "-" "%%-")]
      (set normalized (string.gsub normalized (.. "\"" escaped-rule "\"") (.. ":" rule)))))
  normalized)



(defn- lint-config-finish
  [config]
  config)



(defn- lint-config
  [config]
  (let [config     (string.gsub config
                                "^{%s*"
                                "{:workspace {:extensions [\".fnl\"] :paths [\"\"]} :format {:indent-width 2 :builtins false :prefix-fallbacks false :parser false} ")
        normalized (lint-config-rules config)]
    (lint-config-finish normalized)))



(defn- lint-project-write-file
  [root before path text]
  (let [full (.. root "/" path)]
    (vim.fn.mkdir (vim.fn.fnamemodify full ":h") "p")
    (write-file full text)
    (tset before path (read-file full))))



(defn- lint-project-prepare
  [root config-path config files before]
  (lint-git-init root)
  (write-file config-path (lint-config config))
  (each [path text (pairs files)]
    (lint-project-write-file root before path text)))



(defn- lint-project-result
  [root files args before after]
  (let [result (run-cli root args)]
    (each [path _ (pairs files)]
      (tset after path (read-file (.. root "/" path))))
    {:code   (. result :code)
     :lines  (. result :lines)
     :before before
     :after  after}))



(defn- lint-project-body
  [root config-path before after config files args]
  (lint-project-prepare root config-path config files before)
  (lint-project-result root files args before after))



(defn- lint-project
  [config files args]
  (let [root        (vim.fn.tempname)
        config-path (.. root "/.fnl-extras.fnl")
        before      {}
        after       {}]
    (vim.fn.mkdir root "p")
    (with-cleanup (fn [] (vim.fn.delete root "rf"))


      (fn [] (lint-project-body root config-path before after config files args)))))



(defn- lint-grammar-scenario
  [args]
  (lint-project "{:lint {:rules {:module-style [{:severity :off :applies-to {} :options {} :exclusions []}]}}}"
                {"a.fnl" "(if x 1 2)\n"}
                args))



(defn- lint-opt-in-scenario
  []
  (lint-project "{:lint {:rules {}}}"
                {"a.fnl" "(if x (do (foo) (bar)) nil)\n"}
                ["lint" "--all"]))



(defn- lint-discovery-scenario
  [mode]
  (let [config "{:workspace {:paths [\"src\"] :exclude [\"src/skip\"] :extensions [\".fnl\"]} :lint {:rules {:module-style [{:severity :off :applies-to {} :options {} :exclusions []}]}}}"
        files  {"src/keep.fnl" "(if x 1 2)\n" "src/skip/no.fnl" "(if x 1 2)\n" "other.fnl" "(if x 1 2)\n"}]
    (lint-project config
                  files
                  (if (= mode :default)
                    ["lint" "--all"]
                    ["lint" "--all" "src/keep.fnl"]))))



(defn- lint-output-config
  [mode]
  (or (and (= mode :error)
           "{:lint {:rules {\"module-style\" :off :form-child-count [{:severity :error :applies-to {:forms [\"testing\"]} :options { :children [\"is\"] :max-count 1} :exclusions []}]}}}")
      (and (= mode :warning-error)
           "{:lint {:rules {\"module-style\" :off :if-branch-call [{:severity :error :applies-to {} :options { :forms [\"if\"]} :exclusions []}]}}}")
      (and (= mode :off)
           "{:lint {:rules {\"module-style\" :off \"if-branch-call\" :off}}}")
      "{:lint {:rules {\"module-style\" :off :if-branch-call [{:severity :warning :applies-to {} :options { :forms [\"if\"]} :exclusions []}]}}}"))



(defn- lint-output-source
  [mode]
  (or (and (= mode :error) "(testing \"x\" (is 1) (is 2))\n")
      "(if x (do (foo) (bar)) nil)\n"))



(defn- lint-output-scenario
  [mode]
  (lint-project (lint-output-config mode)
                {"a.fnl" (lint-output-source mode)}
                ["lint" "--all"]))



(defn- lint-exclusion-config
  [mode]
  (or (and (= mode :stale)
           "{:lint {:rules {\"module-style\" :off :if-branch-call [{:severity :warning :applies-to {} :options { :forms [\"if\"]} :exclusions [{:path \"missing[.]fnl\" :reason \"old intentional branch\"}]}]}}}")
      "{:lint {:rules {\"module-style\" :off :if-branch-call [{:severity :warning :applies-to {} :options { :forms [\"if\"]} :exclusions [{:path \"a.fnl\" :reason \"intentional multi-step branch\"}]}]}}}"))



(defn- lint-exclusion-scenario
  [mode]
  (lint-project (lint-exclusion-config mode)
                {"a.fnl" "(if x (do (foo) (bar)) nil)\n"}
                ["lint" "--all"]))



(defn- lint-normalized-testing-exclusion-scenario
  []
  (lint-project "{:lint {:rules {\"module-style\" :off :form-child-count [{:severity :error :applies-to {:forms [\"testing\"]} :options { :children [\"is\"] :max-count 1} :exclusions [{:path \"a.fnl\" :reason \"intentional test shape\"}]}]}}}"
                {"a.fnl" "(testing \"two\" (is true) (is true))\n"}
                ["lint" "--all"]))



(defn- lint-selector-exclusion-config
  [mode]
  (or (and (= mode :per-rule)
           "{:lint {:rules {\"module-style\" :off :if-without-else [{:severity :warning :applies-to {} :options {:forms [\"if\"] :nil-else true} :exclusions [{:path \"a.fnl\" :reason \"intentional per-rule exclusion\"}]}]}}}")
      "{:lint {:rules {:if-without-else [{:severity :warning :applies-to {} :options {:forms [\"if\"] :nil-else true} :exclusions [{:path \"a.fnl\" :reason \"intentional per-instance exclusion\"}]}]}}}"))



(defn- lint-selector-exclusion-scenario
  [mode]
  (lint-project (lint-selector-exclusion-config mode)
                {"a.fnl" "(if ok then)\n"}
                ["lint" "--all"]))



(defn- lint-invalid-regex-scenario
  []
  (lint-project "{:lint {:rules {:module-style [{:severity :off :applies-to {} :options {} :exclusions [{:path \"[\" :reason \"bad regex\"]}]}}}"
                {"a.fnl" "(if\n"}
                ["lint" "--all"]))



(defn- lint-stale-pattern-scenario
  []
  (lint-project "{:lint {:rules {\"module-style\" :off :if-without-else [{:severity :warning :applies-to {} :options { :forms [\"if\"] :nil-else true} :exclusions [{:path \"missing[.]fnl\" :reason \"stale pattern\"]}]}}}"
                {"a.fnl" "(if ok then)\n"}
                ["lint" "--all"]))



(defn- lint-disabled-exclusion-scenario
  []
  (lint-project "{:lint {:rules {:if-without-else [{:severity :off :applies-to {} :options {} :exclusions [{:path \"a.fnl\" :reason \"disabled rule\"]}]}}}"
                {"a.fnl" "(if ok then)\n"}
                ["lint" "--all"]))



(defn- lint-error-config
  [mode]
  (if (= mode :config)
    "{:lint {:rules {:if-without-else [{:severity :warning :applies-to {} :options {:nope true} :exclusions []}]}}}"
    "{:lint {:rules {:module-style [{:severity :off :applies-to {} :options {} :exclusions []}]}}}"))



(defn- lint-error-source
  [mode]
  (or (and (= mode :config) "(if x 1 2)\n")
      "(if x"))



(defn- lint-error-scenario
  [mode]
  (lint-project (lint-error-config mode)
                {"a.fnl" (lint-error-source mode)}
                ["lint" "--all"]))



(deftest lint-grammar



  (testing "omitting lint rules produces no findings"
    (let [result (lint-opt-in-scenario)]
      (is (= {:code 0 :lines []} {:code (. result :code) :lines (. result :lines)}))))



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
      (is (= [] (. (lint-discovery-scenario :explicit) :lines))))


    (deftest lint-output



      (testing "reports one error finding with text output and exit one"
        (is (= 1 (. (lint-output-scenario :error) :code))))



      (testing "prints the exact text line and exclusion suggestion for an error"
        (is (= ["a.fnl:1:1: error form-child-count: each testing form must contain exactly one is"
                "  exclusion: {:rule \"form-child-count\" :form \"a.fnl > top#1 > testing#1\" :reason \"explain why this is intentional\"}"]
               (. (lint-output-scenario :error) :lines))))



      (testing "prints a warning but exits zero"
        (let [result (lint-output-scenario :warning)]
          (is (and (= 0 (. result :code)) (not= nil (. result :lines 1))))))



      (testing "turns the warning into an error when configured"
        (is (= 1 (. (lint-output-scenario :warning-error) :code))))



      (testing "turns the warning off when configured"
        (is (= 0 (. (lint-output-scenario :off) :code))))



      (testing "emits json lines with the same warning status"
        (let [result (lint-project "{:lint {:rules {\"module-style\" :off :if-branch-call [{:severity :warning :applies-to {} :options { :forms [\"if\"]} :exclusions []}]}}}"
                                   {"a.fnl" "(if x (do (foo) (bar)) nil)\n"}
                                   ["lint" "--all" "--format" "json"])]
          (is (and (= 0 (. result :code)) (string.match (or (. result :lines 1) "") "^%{"))))))

    (deftest lint-exclusions



      (testing "suppresses a matching exclusion in all mode"
        (is (= 0 (. (lint-exclusion-scenario :matching) :code))))



      (testing "reports an unmatched exclusion as a stale error in all mode"
        (let [result (lint-exclusion-scenario :stale)]
          (is (= 1 (. result :code)))))



      (testing "suppresses normalized form-child-count identity without stale output"
        (let [result (lint-normalized-testing-exclusion-scenario)]
          (is (= {:code 0 :lines []} {:code (. result :code) :lines (. result :lines)}))))



      (testing "suppresses a per-rule exclusion end to end"
        (is (= 0 (. (lint-selector-exclusion-scenario :per-rule) :code))))



      (testing "suppresses a general exclusion end to end"
        (is (= 0 (. (lint-selector-exclusion-scenario :general) :code))))



      (testing "rejects an invalid regex before scanning source"
        (let [result (lint-invalid-regex-scenario)]
          (is (= 2 (. result :code)))))




      (testing "reports a stale pattern exclusion"
        (let [result (lint-stale-pattern-scenario)]
          (is (= 2 (. result :code)))))



      (testing "reports a disabled-rule exclusion as stale"
        (let [result (lint-disabled-exclusion-scenario)]
          (is (= 2 (. result :code))))) )

    (deftest lint-errors-and-read-only



      (testing "returns exit two with a malformed lint configuration error"
        (let [result (lint-error-scenario :config)]
          (is (= 2 (. result :code)))))



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
          command (.. "cd "
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



  (defn- real-lint-output-setup
    [config first-file second-file config-text first-source second-source]
    (lint-git-init (vim.fn.fnamemodify config ":h"))
    (write-file config (lint-config config-text))
    (write-file first-file first-source)
    (write-file second-file second-source)
    (lint-git-commit (vim.fn.fnamemodify config ":h")))



  (defn- real-lint-output-result
    [root format]
    (let [result (real-cli-lines root ["lint" "--all" "--format" format])
          lines  (. result :lines)]
      {:lines                 (length lines)
       :objects               3
       :each-line-one-object? (one-json-object-per-line? lines)}))



  (defn- real-text-lint-output-result
    [root]
    (let [result (real-cli-lines root ["lint" "--all"])]
      {:lines   (length (. result :lines))
       :objects 3}))



  (defn- real-lint-output-scenario
    [format]
    (let [root          (vim.fn.tempname)
          config        (.. root "/.fnl-extras.fnl")
          first-file    (.. root "/a.fnl")
          second-file   (.. root "/b.fnl")
          config-text   "{:lint {:rules {\"direct-require\" :off \"if-branch-call\" :off \"module-style\" :off :form-child-count [{:severity :error :applies-to {:forms [\"testing\"]} :options { :children [\"is\"] :max-count 1} :exclusions []}] \"direct-require\" :off \"macro-import\" :off \"no-module\" :off}}}"
          first-source  "(testing \"a\" (is 1) (is 2))\\n(testing \"b\" (is 1) (is 2))\\n"
          second-source "(testing \"c\" (is 1) (is 2))\\n"]
      (vim.fn.mkdir root "p")
      (with-cleanup (fn [] (vim.fn.delete root "rf"))


        (fn []
          (real-lint-output-setup config first-file second-file config-text first-source second-source)
          (real-lint-output-result root format)))))



  (defn- real-text-lint-output-scenario
    []
    (let [root          (vim.fn.tempname)
          config        (.. root "/.fnl-extras.fnl")
          first-file    (.. root "/a.fnl")
          second-file   (.. root "/b.fnl")
          config-text   "{:lint {:rules {\"direct-require\" :off \"if-branch-call\" :off \"module-style\" :off :form-child-count [{:severity :error :applies-to {:forms [\"testing\"]} :options { :children [\"is\"] :max-count 1} :exclusions []}] \"direct-require\" :off \"macro-import\" :off \"no-module\" :off}}}"
          first-source  "(testing \"a\" (is 1) (is 2))\\n(testing \"b\" (is 1) (is 2))\\n"
          second-source "(testing \"c\" (is 1) (is 2))\\n"]
      (vim.fn.mkdir root "p")
      (with-cleanup (fn [] (vim.fn.delete root "rf"))


        (fn []
          (real-lint-output-setup config first-file second-file config-text first-source second-source)
          (real-text-lint-output-result root)))))



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
          command (.. "cd "
                      (vim.fn.shellescape root)
                      " && perl -e 'alarm shift; exec @ARGV' 30 "
                      (vim.fn.shellescape script)
                      " "
                      (shell-args args)
                      " </dev/null 2>&1")]
      (bounded-command command)))



  (defn- git-run
    [root args]
    (let [command (.. "cd "
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



  (defn- invalid-git-scenario-args
    [mode]
    (or (and (= mode :all) ["lint" "--all"])
        ["lint" "--changed"]))



  (defn- invalid-git-scenario-body
    [mode root]
    (let [_      (write-file (.. root "/.fnl-extras.fnl") (lint-config "{:lint {:rules {\"direct-require\" :off :if-branch-call [{:severity :warning :applies-to {} :options { :forms [\"if\"]} :exclusions []}] \"module-style\" :off \"form-child-count\" :off \"direct-require\" :off \"macro-import\" :off \"no-module\" :off}}}"))
          _      (write-file (.. root "/a.fnl") "(if x 1 2)\\n")
          result (bounded-cli root (invalid-git-scenario-args mode))
          line   (or (. result :lines 1) "")]
      {:code       (. result :code)
       :line       line
       :lines      (. result :lines)
       :timed-out? (. result :timed-out?)}))



  (defn- invalid-git-scenario
    [mode]
    (let [root (vim.fn.tempname)]
      (vim.fn.mkdir root "p")
      (vim.fn.mkdir (.. root "/.git") "p")
      (with-cleanup (fn [] (vim.fn.delete root "rf"))


        (fn [] (invalid-git-scenario-body mode root)))))



  (defn- unborn-git-scenario-body
    [mode root]
    (let [_      (git-init root)
          _      (write-file (.. root "/.fnl-extras.fnl") (lint-config "{:lint {:rules {\"direct-require\" :off \"if-branch-call\" :off \"module-style\" :off :form-child-count [{:severity :error :applies-to {:forms [\"testing\"]} :options { :children [\"is\"] :max-count 1} :exclusions []}] \"direct-require\" :off \"macro-import\" :off \"no-module\" :off}}}"))
          _      (write-file (.. root "/a.fnl") "(testing \"x\") (import-macros {: testing : is} :spec.eca.macros)\n")
          result (bounded-cli root (invalid-git-scenario-args mode))]
      {:code       (. result :code)
       :lines      (. result :lines)
       :timed-out? (. result :timed-out?)}))



  (defn- unborn-git-scenario
    [mode]
    (let [root (vim.fn.tempname)]
      (vim.fn.mkdir root "p")
      (with-cleanup (fn [] (vim.fn.delete root "rf"))


        (fn [] (unborn-git-scenario-body mode root)))))



  (defn- changed-config
    []
    "{:lint {:rules {\"direct-require\" :off \"function-shape\" :off \"control-layout\" :off :if-branch-call [{:severity :warning :applies-to {} :options { :forms [\"if\"]} :exclusions []}] \"if-without-else\" :off \"module-style\" :off \"form-child-count\" :off \"direct-require\" :off \"macro-import\" :off \"no-module\" :off}}}")



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



  (defn- changed-mode-setup
    [mode root source-path config-path]
    (git-init root)
    (write-file config-path (lint-config (changed-config)))
    (write-file source-path (changed-source :base))
    (git-run root ["add" "."])
    (git-run root ["commit" "-qm" "base"])
    (when (or (= mode :modified) (= mode :subdir))
      (write-file source-path (changed-source :changed)))
    (when (= mode :both)
      (changed-mode-both root source-path))
    (when (= mode :staged)
      (changed-mode-staged root source-path))
    (when (= mode :untracked)
      (write-file (.. root "/new file.fnl") "(defn new [] (if z (do (foo) (bar)) nil))\n"))
    (when (= mode :rename)
      (changed-mode-rename root)))



  (defn- changed-mode-cwd
    [mode root subdir]
    (or (and (= mode :subdir) subdir)
        root))



  (defn- changed-mode-result
    [mode root subdir]
    (let [result (bounded-cli (changed-mode-cwd mode root subdir) ["lint" "--changed"])]
      {:code       (. result :code)
       :lines      (. result :lines)
       :timed-out? (. result :timed-out?)}))



  (defn- changed-mode-scenario-body
    [mode root source-path config-path subdir]
    (let [_ (changed-mode-setup mode root source-path config-path)]
      (changed-mode-result mode root subdir)))



  (defn- changed-mode-scenario
    [mode]
    (let [root        (vim.fn.tempname)
          source-path (.. root "/a.fnl")
          config-path (.. root "/.fnl-extras.fnl")
          subdir      (.. root "/nested")]
      (vim.fn.mkdir root "p")
      (vim.fn.mkdir subdir "p")
      (with-cleanup (fn [] (vim.fn.delete root "rf"))


        (fn [] (changed-mode-scenario-body mode root source-path config-path subdir)))))



  (defn- base-mode-setup
    [root source-path]
    (git-init root)
    (write-file (.. root "/.fnl-extras.fnl") (lint-config (changed-config)))
    (write-file source-path (changed-source :base))
    (git-run root ["add" "."])
    (git-run root ["commit" "-qm" "base"])
    (write-file source-path (changed-source :changed))
    (git-run root ["add" "."])
    (git-run root ["commit" "-qm" "changed"]))



  (defn- base-mode-scenario-body
    [root source-path]
    (let [_      (base-mode-setup root source-path)
          result (bounded-cli root ["lint" "--base" "HEAD~1"])]
      {:code       (. result :code)
       :lines      (. result :lines)
       :timed-out? (. result :timed-out?)}))



  (defn- base-mode-scenario
    []
    (let [root        (vim.fn.tempname)
          source-path (.. root "/a.fnl")]
      (vim.fn.mkdir root "p")
      (with-cleanup (fn [] (vim.fn.delete root "rf"))


        (fn [] (base-mode-scenario-body root source-path)))))



  (defn- file-size-changed-mode-setup
    [root changed-path unchanged-path config base-source changed-source]
    (git-init root)
    (write-file (.. root "/.fnl-extras.fnl") (lint-config config))
    (write-file changed-path base-source)
    (write-file unchanged-path base-source)
    (git-run root ["add" "."])
    (git-run root ["commit" "-qm" "base"])
    (write-file changed-path changed-source))



  (defn- file-size-line
    [line name]
    (when (string.match line name)
      line))



  (defn- file-size-findings
    [findings name]
    (length (icollect [_ line (ipairs findings)]
              (file-size-line line name))))



  (defn- file-size-changed-mode-scenario-body
    [root changed-path unchanged-path config base-source changed-source]
    (let [_        (file-size-changed-mode-setup root changed-path unchanged-path config base-source changed-source)
          result   (bounded-cli root ["lint" "--changed"])
          findings (finding-lines (. result :lines))]
      {:code                (. result :code)
       :changed-file-size   (file-size-findings findings "changed%.fnl:.*file%-size")
       :unchanged-file-size (file-size-findings findings "unchanged%.fnl:.*file%-size")}))



  (defn- file-size-changed-mode-scenario
    []
    (let [root           (vim.fn.tempname)
          changed-path   (.. root "/changed.fnl")
          unchanged-path (.. root "/unchanged.fnl")
          config         "{:lint {:rules {\"direct-require\" :off :file-size [{:severity :warning :applies-to {:files [\"^changed[.]fnl$\"]} :options { :max-code-lines 2} :exclusions []}] \"function-shape\" :off \"if-branch-call\" :off \"module-style\" :off \"no-mutation\" :off \"form-child-count\" :off \"direct-require\" :off \"macro-import\" :off \"no-module\" :off}}}"
          base-source    "(local a 1)\n(local b 2)\n(local c 3)\n"
          changed-source "(local a 9)\n(local b 2)\n(local c 3)\n"]
      (vim.fn.mkdir root "p")
      (with-cleanup (fn [] (vim.fn.delete root "rf"))


        (fn [] (file-size-changed-mode-scenario-body root changed-path unchanged-path config base-source changed-source)))))



  (defn- lint-error-repository-scenario
    [root]
    (write-file (.. root "/.fnl-extras.fnl")
                (lint-config "{:lint {:rules {:module-style [{:severity :off :applies-to {} :options {} :exclusions []}]}}}"))
    (write-file (.. root "/a.fnl") "(if x 1 2)\n"))



  (defn- lint-error-configured-scenario
    [root]
    (let [_ (git-init root)
          _ (write-file (.. root "/.fnl-extras.fnl") (lint-config "{:lint {:rules {\"direct-require\" :off :if-branch-call [{:severity :warning :applies-to {} :options { :forms [\"if\"]} :exclusions []}] \"module-style\" :off \"form-child-count\" :off \"direct-require\" :off \"macro-import\" :off \"no-module\" :off}}}"))
          _ (write-file (.. root "/a.fnl") "(if x 1 2)\n")
          _ (git-run root ["add" "."])]
      (git-run root ["commit" "-qm" "base"])))



  (defn- lint-error-mode-setup
    [mode root]
    (or (and (= mode :git) (lint-error-repository-scenario root))
        (lint-error-configured-scenario root)))



  (defn- lint-error-mode-args
    [mode]
    (or (and (= mode :base) ["lint" "--base" "missing-ref"])
        (and (or (= mode :changed) (= mode :git)) ["lint" "--changed"])
        ["lint"]))



  (defn- lint-error-mode-scenario-body
    [mode root]
    (let [_      (lint-error-mode-setup mode root)
          result (bounded-cli root (lint-error-mode-args mode))
          line   (or (. result :lines 1) "")]
      {:code       (. result :code)
       :line       line
       :lines      (. result :lines)
       :timed-out? (. result :timed-out?)}))



  (defn- lint-error-mode-scenario
    [mode]
    (let [root (vim.fn.tempname)]
      (vim.fn.mkdir root "p")
      (with-cleanup (fn [] (vim.fn.delete root "rf"))


        (fn [] (lint-error-mode-scenario-body mode root)))))



  (defn- stale-exclusion-config
    [mode]
    (or (and (or (= mode :untouched) (= mode :all))
             "{:lint {:rules {\"module-style\" :off :if-branch-call [{:severity :warning :applies-to {} :options { :forms [\"if\"]} :exclusions [{:path \"missing[.]fnl\" :reason \"old intentional branch\"}]}]}}}")
        (and (= mode :modified)
             "{:lint {:rules {\"module-style\" :off :if-branch-call [{:severity :warning :applies-to {} :options { :forms [\"if\"]} :exclusions [{:path \"missing[.]fnl\" :reason \"old intentional branch\"}]}]}}}")
        "{:lint {:rules {\"module-style\" :off :if-branch-call [{:severity :warning :applies-to {} :options { :forms [\"if\"]} :exclusions [{:path \"missing[.]fnl\" :reason \"old intentional branch\"}]}]}}}"))



  (defn- stale-exclusion-setup
    [root config-path a-path b-path gone-path config mode]
    (git-init root)
    (write-file config-path (lint-config config))
    (write-file a-path "(if x (do (foo) (bar)) nil)\n")
    (write-file b-path "(if y (do (baz) (qux)) nil)\n")
    (write-file gone-path "(if z (do (old) (code)) nil)\n")
    (git-run root ["add" "."])
    (git-run root ["commit" "-qm" "base"])
    (or (and (or (= mode :untouched) (= mode :all))
             (write-file a-path "(if changed (do (foo) (bar)) nil)\n"))
        (and (= mode :modified)
             (write-file a-path "(if changed (do (foo) (bar)) nil)\n"))
        (git-run root ["rm" "-q" "gone.fnl"])))



  (defn- stale-exclusion-args
    [mode]
    (or (and (= mode :all) ["lint" "--all"])
        ["lint" "--changed"]))



  (defn- stale-exclusion-scenario-body
    [mode root a-path b-path gone-path config-path config]
    (let [_      (stale-exclusion-setup root config-path a-path b-path gone-path config mode)
          result (bounded-cli root (stale-exclusion-args mode))]
      {:code       (. result :code)
       :lines      (. result :lines)
       :timed-out? (. result :timed-out?)}))



  (defn- stale-exclusion-scenario
    [mode]
    (let [root        (vim.fn.tempname)
          a-path      (.. root "/a.fnl")
          b-path      (.. root "/b.fnl")
          gone-path   (.. root "/gone.fnl")
          config-path (.. root "/.fnl-extras.fnl")
          config      (stale-exclusion-config mode)]
      (vim.fn.mkdir root "p")
      (with-cleanup (fn [] (vim.fn.delete root "rf"))


        (fn [] (stale-exclusion-scenario-body mode root a-path b-path gone-path config-path config)))))



  (defn- shallow-clone-setup
    [source config]
    (git-init source)
    (write-file (.. source "/.fnl-extras.fnl") (lint-config config))
    (write-file (.. source "/a.fnl") "(if x 1 2)\n")
    (git-run source ["add" "."])
    (git-run source ["commit" "-qm" "base"]))



  (defn- shallow-clone-args
    [mode]
    (or (and (= mode :all) ["lint" "--all"])
        ["lint" "--changed"]))



  (defn- shallow-clone-success-result
    [mode clone]
    (let [result (bounded-cli clone (shallow-clone-args mode))]
      {:code       (. result :code)
       :lines      (. result :lines)
       :timed-out? (. result :timed-out?)}))



  (defn- shallow-clone-result
    [mode clone clone-result]
    (if (not= 0 (. clone-result :code))
      {:code       (. clone-result :code)
       :lines      (. clone-result :lines)
       :timed-out? (. clone-result :timed-out?)}
      (shallow-clone-success-result mode clone)))



  (defn- shallow-clone-scenario-body
    [mode source clone config clone-command]
    (let [_            (shallow-clone-setup source config)
          clone-result (bounded-command clone-command)]
      (shallow-clone-result mode clone clone-result)))



  (defn- shallow-clone-scenario
    [mode]
    (let [source        (vim.fn.tempname)
          clone         (vim.fn.tempname)
          config        "{:lint {:rules {\"module-style\" :off :if-branch-call [{:severity :warning :applies-to {} :options { :forms [\"if\"]} :exclusions []}]}}}"
          clone-command (.. "git clone --depth 1 "
                            (vim.fn.shellescape (.. "file://" source))
                            " "
                            (vim.fn.shellescape clone)
                            " </dev/null 2>&1")]
      (vim.fn.mkdir source "p")
      (with-cleanup (fn []
                      (vim.fn.delete source "rf")
                      (vim.fn.delete clone "rf"))


        (fn [] (shallow-clone-scenario-body mode source clone config clone-command)))))



  (defn- default-lint-setup
    [root config warn config-text mode]
    (write-file config (lint-config config-text))
    (write-file warn "(if x (do (foo) (bar)) nil)\n")
    (when (= mode :git)
      (git-init root)
      (git-run root ["add" "."])
      (git-run root ["commit" "-qm" "base"])))



  (defn- default-lint-result
    [root]
    (let [result (bounded-cli root ["lint"])]
      {:code (. result :code) :lines (. result :lines)}))



  (defn- default-lint-scenario
    [mode]
    (let [root        (vim.fn.tempname)
          config      (.. root "/.fnl-extras.fnl")
          warn        (.. root "/warning.fnl")
          config-text "{:lint {:rules {\"direct-require\" :off \"function-shape\" :off :if-branch-call [{:severity :warning :applies-to {} :options { :forms [\"if\"]} :exclusions []}] \"module-style\" :off :form-child-count [{:severity :error :applies-to {:forms [\"testing\"]} :options { :children [\"is\"] :max-count 1} :exclusions []}] \"direct-require\" :off \"macro-import\" :off \"no-module\" :off}}}"]
      (vim.fn.mkdir root "p")
      (with-cleanup (fn [] (vim.fn.delete root "rf"))


        (fn []
          (default-lint-setup root config warn config-text mode)
          (default-lint-result root)))))



  (defn- default-lint-all-files-setup
    [root config warn error config-text]
    (git-init root)
    (write-file config (lint-config config-text))
    (write-file warn "(if x (do (foo) (bar)) nil)\n")
    (write-file error "(testing \"x\" (is 1) (is 2))\n")
    (git-run root ["add" "."])
    (git-run root ["commit" "-qm" "base"]))



  (defn- default-lint-all-files-result
    [root config warn error config-text]
    (let [_      (default-lint-all-files-setup root config warn error config-text)
          result (bounded-cli root ["lint"])]
      {:code (. result :code) :lines (. result :lines)}))



  (defn- default-lint-all-files-scenario
    []
    (let [root        (vim.fn.tempname)
          config      (.. root "/.fnl-extras.fnl")
          warn        (.. root "/warning.fnl")
          error       (.. root "/error.fnl")
          config-text "{:lint {:rules {\"direct-require\" :off \"function-shape\" :off :if-branch-call [{:severity :warning :applies-to {} :options { :forms [\"if\"]} :exclusions []}] \"module-style\" :off :form-child-count [{:severity :error :applies-to {:forms [\"testing\"]} :options { :children [\"is\"] :max-count 1} :exclusions []}] \"direct-require\" :off \"macro-import\" :off \"no-module\" :off}}}"]
      (vim.fn.mkdir root "p")
      (with-cleanup (fn [] (vim.fn.delete root "rf"))


        (fn [] (default-lint-all-files-result root config warn error config-text)))))



  (deftest lint-default-selection



    (testing "default lint reports findings from all committed files"
      (let [result (default-lint-all-files-scenario)
            text   (table.concat (. result :lines) "\n")]
        (is (and (= 1 (. result :code))
                 (string.match text "warning%.fnl:1:7: warning if%-branch%-call")
                 (string.match text "error%.fnl:1:1: error form%-child%-count")))))



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
                 (string.match (table.concat (. result :lines) "\n") "missing%-ref")))))



    (testing "all mode lints an unborn repository without resolving HEAD"
      (is (= {:code       1
              :lines      ["a.fnl:1:1: error form-child-count: each testing form must contain exactly one is"
                           "  exclusion: {:rule \"form-child-count\" :form \"a.fnl > top#1 > testing#1\" :reason \"explain why this is intentional\"}"]
              :timed-out? false}
             (unborn-git-scenario :all))))



    (testing "changed mode reports the unknown unborn HEAD base"
      (is (= {:code 2 :lines ["unknown base ref: HEAD"] :timed-out? false}
             (unborn-git-scenario :changed)))))

  (deftest stale-exclusion-scope



    (testing "an untouched file's stale exclusion does not fail changed mode"
      (is (= {:code 0 :lines [] :timed-out? false}
             (stale-exclusion-scenario :untouched))))



    (testing "a stale exclusion outside the modified file scope does not fail changed mode"
      (is (= {:code 0 :lines [] :timed-out? false}
             (stale-exclusion-scenario :modified))))



    (testing "a deleted file's exclusion outside the changed scope does not fail changed mode"
      (is (= {:code 0 :lines [] :timed-out? false}
             (stale-exclusion-scenario :deleted))))



    (testing "all mode reports stale exclusions regardless of file scope"
      (is (= {:code       1
              :lines      [".fnl-extras.fnl:1:1: error if-branch-call: stale exclusion: missing[.]fnl"]
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

  (defn- alignment-maps-cli-setup
    [config-path path source]
    (write-file config-path "{:indent-width 2 :builtins {\"fn\" [[:inner 0]] \"lambda\" [[:inner 0]] \"macro\" [[:inner 0]] \"let\" [[:block 1]] \"when\" [[:block 1]] \"when-let\" [[:block 1]] \"if-let\" [[:block 1]] \"each\" [[:block 1]] \"for\" [[:block 1]] \"icollect\" [[:block 1]] \"collect\" [[:block 1]] \"accumulate\" [[:block 1]] \"case\" [[:block 1]] \"match\" [[:block 1]] \"case-try\" [[:block 1]] \"match-try\" [[:block 1]] \"while\" [[:block 1]] \"with-open\" [[:block 1]] \"do\" [[:block 0]]} :prefix-fallbacks {\"def\" [[:inner 0]] \"with-\" [[:block 1]]} :parser false :alignment {:bindings false :maps true :clauses false :split-bindings false :collapse-padding false :binding-forms [\"let\" \"when-let\" \"if-let\" \"with-open\"] :clause-forms [\"case\" \"match\" \"case-try\" \"match-try\" \"if\"]}}")
    (write-file path source))



  (defn- alignment-maps-cli-scenario-body
    [root config-path path source expected]
    (let [_            (alignment-maps-cli-setup config-path path source)
          check-result (run-cli root ["format" "--check" "a.fnl"])
          write-result (run-cli root ["format" "--write" "a.fnl"])
          result       {:check-code  (. check-result :code)
                        :check-lines (. check-result :lines)
                        :write-code  (. write-result :code)
                        :write-lines (. write-result :lines)
                        :content     (read-file path)
                        :expected    expected}]
      (vim.fn.delete root "rf")
      result))



  (defn- alignment-maps-cli-scenario
    []
    (let [root        (vim.fn.tempname)
          path        (.. root "/a.fnl")
          config-path (.. root "/.fnl-extras.fnl")
          source      "{:a 1\n :long 2}"
          expected    "{:a    1\n :long 2}"]
      (vim.fn.mkdir root "p")
      (vim.fn.mkdir (.. root "/.git") "p")
      (alignment-maps-cli-scenario-body root config-path path source expected)))



  (deftest alignment-maps-cli



    (testing "check reports missing map alignment and write fixes it from alignment config"
      (let [result (alignment-maps-cli-scenario)]
        (is (and (= 1 (. result :check-code))
                 (vim.deep_equal ["a.fnl"] (. result :check-lines))
                 (= 0 (. result :write-code))
                 (vim.deep_equal ["a.fnl"] (. result :write-lines))
                 (= (. result :expected) (. result :content)))))))

  (deftest lint-policy-cli-regressions



    (testing "listing one rule disables unlisted findings"
      (let [result (lint-project "{:lint {:rules {:if-without-else [{:severity :warning :applies-to {} :options { :forms [\"if\"] :nil-else true} :exclusions []}]}}}"
                                 {"a.fnl" "(if ok then)\n(var x 1)\n"}
                                 ["lint" "--all"])]
        (is (and (= 0 (. result :code))
                 (= 2 (length (. result :lines)))
                 (string.match (. result :lines 1) "if%-without%-else")))))



    (testing "file-size uses the nested max-code-lines option"
      (let [result (lint-project "{:lint {:rules {:file-size [{:severity :warning :applies-to {:files [\"^a[.]fnl$\"]} :options { :max-code-lines 3} :exclusions []}] \"module-style\" :off}}}"
                                 {"a.fnl" "(module a)\n(local a 1)\n(local b 2)\n(local c 3)\n(local d 4)\n"}
                                 ["lint" "--all"])]
        (is (and (= 0 (. result :code))
                 (= 2 (length (. result :lines)))
                 (string.match (. result :lines 1) "file%-size")
                 (string.match (. result :lines 2) "exclusion:"))))))

  (defn- missing-config-cli-scenario-body
    [root path command]
    (let [_      (write-file path "(module a)\n")
          result (run-cli root [command "--check" "a.fnl"])
          output {:code  (. result :code)
                  :lines (. result :lines)}]
      (vim.fn.delete root "rf")
      output))



  (defn- missing-config-cli-scenario
    [command]
    (let [root (vim.fn.tempname)
          path (.. root "/a.fnl")]
      (vim.fn.mkdir root "p")
      (vim.fn.mkdir (.. root "/.git") "p")
      (missing-config-cli-scenario-body root path command)))



  (deftest strict-cli-errors



    (testing "format exits 2 with a clear missing config message"
      (let [result (missing-config-cli-scenario "format")]
        (is (and (= 2 (. result :code))
                 (string.match (or (. result :lines 1) "") "missing .fnl%-extras%.fnl")))))



    (testing "lint exits 2 with a clear missing config message"
      (let [result (missing-config-cli-scenario "lint")]
        (is (and (= 2 (. result :code))
                 (string.match (or (. result :lines 1) "") "missing .fnl%-extras%.fnl"))))))

)