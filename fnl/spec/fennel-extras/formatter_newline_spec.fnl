(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(local format (require :fennel-extras.format))
(local parser (require :eca.nfnl.fennel))

(local base-config
       {:indent-width 2
        :parser       false
        :indents      {"defn"    [[:block 1]]
                       "testing" [[:block 1]]}
        :newline      [{:applies-to {:forms ["fn" "defn" "defn-"]}
                        :options    {:after-header 1}}
                       {:applies-to {:forms ["testing"]}
                        :options    {:before 1}}]})

(local split-config
       {:indent-width 2
        :parser       false
        :indents      {}
        :alignment    {:bindings         true
                       :maps             false
                       :clauses          false
                       :split-bindings   true
                       :collapse-padding false
                       :binding-forms    ["let" "when-let" "if-let" "with-open"]
                       :clause-forms     ["case" "match" "case-try" "match-try" "if"]}})

(defn- formatted-body
  [format source]
  (format.format-string source {:config base-config}))

(defn- formatted
  [source]
  (let [(ok value) (pcall formatted-body format source)]
    (if ok value (or nil))))

(defn- formatted-split-body
  [formatter source]
  (formatter.format-string source {:config split-config}))

(defn- formatted-with-config
  [formatter source config]
  (formatter.format-string source {:config  config
                                   :matcher (fn [pattern path]
                                              (let [regex (vim.regex pattern)]
                                                (not= nil (regex:match_str path))))
                                   :path    (. config :path)}))

(defn- formatted-split
  [source]
  (let [(ok value) (pcall formatted-split-body format source)]
    (if ok value (or nil))))

(deftest formatter-newline-contract

         (testing "after-header inserts a break before defn arguments"
                  (is (= "(defn run\n\n  []\n  true)\n(foo)"
                         (formatted "(defn run\n[]\ntrue)\n(foo)"))))

         (testing "newline before applies to testing forms"
                  (is (= "(foo)\n\n(testing \"works\"\n  (is true))"
                         (formatted "(foo)\n(testing \"works\"\n(is true))"))))

         (testing "split-bindings separates configured binding pairs"
                  (is (= "(when-let [a 1\n           b 2] a)"
                         (formatted-split "(when-let [a 1 b 2] a)")))))

(deftest header-newline-contract

         (let [config {:indent-width 2
                       :parser       false
                       :indents      {"fn"    [[:inner 0]]
                                      "defn"  [[:block 1]]
                                      "defn-" [[:block 1]]}
                       :newline      [{:applies-to {:forms ["fn" "defn" "defn-"]}
                                       :options    {:after-header 1}}]}]

           (testing "after-header inserts a break before multiline fn arguments"
                    (is (= "(fn\n\n  []\n  true)"
                           (formatted-with-config format "(fn\n[]\ntrue)" config))))

           (testing "after-header inserts a break before multiline defn arguments"
                    (is (= "(defn run\n\n  []\n  true)"
                           (formatted-with-config format "(defn run\n[]\ntrue)" config))))

           (testing "after-header inserts a break before multiline defn- arguments"
                    (is (= "(defn- run\n\n  []\n  true)"
                           (formatted-with-config format "(defn- run\n[]\ntrue)" config))))

           (testing "after-header does not add a trailing break to one-line defn"
                    (is (= "(defn run [] true)"
                           (formatted-with-config format "(defn run [] true)" config))))

           (testing "after-header does not add a trailing break to one-line defn-"
                    (is (= "(defn- run [] true)"
                           (formatted-with-config format "(defn- run [] true)" config))))))

(deftest explicit-zero-header-newline

         (testing "after-header zero removes contiguous existing blank lines after a selected fn header"
                  (let [config {:indent-width 2
                                :parser       false
                                :indents      {"fn" [[:inner 0]]}
                                :newline      [{:applies-to {:forms ["fn"]}
                                                :options    {:after-header 0}}]}]
                    (is (= "(fn\n  []\n  true)"
                           (formatted-with-config format "(fn\n\n\n[]\ntrue)" config)))))

         (testing "omitted after-header preserves existing blank lines after a selected fn header"
                  (let [config {:indent-width 2
                                :parser       false
                                :indents      {"fn" [[:inner 0]]}
                                :newline      [{:applies-to {:forms ["fn"]}
                                                :options    {}}]}]
                    (is (= "(fn\n\n  []\n  true)"
                           (formatted-with-config format "(fn\n\n[]\ntrue)" config))))))

(deftest break-after-args

         (let [config {:indent-width 2
                       :parser       false
                       :indents      {"defn" [[:block 1]]}
                       :newline      [{:applies-to {:forms ["defn"]}
                                       :options    {:break-after-args [[1 1] [2 1]]}}]}]

           (testing "break-after-args canonicalizes direct defn argument boundaries"
                    (is (= "(defn parse-string\n  [text]\n  (parse.parse-string text))"
                           (formatted-with-config format
                                                  "(defn parse-string [text] (parse.parse-string text))"
                                                  config))))

           (testing "break-after-args canonicalizes already-varied input layouts"
                    (is (= "(defn parse-string\n  [text]\n  (parse.parse-string text))"
                           (formatted-with-config format
                                                  "(defn parse-string\n[text]\n(parse.parse-string text))"
                                                  config))))

           (testing "break-after-args is opt-in"
                    (let [without-option {:indent-width 2
                                          :parser       false
                                          :indents      {"defn" [[:block 1]]}}]
                      (is (= "(defn parse-string [text] (parse.parse-string text))"
                             (formatted-with-config format
                                                    "(defn parse-string [text] (parse.parse-string text))"
                                                    without-option)))))

           (testing "break-after-args canonicalization is idempotent"
                    (let [formatted (formatted-with-config format
                                                           "(defn parse-string [text] (parse.parse-string text))"
                                                           config)]
                      (is (= formatted
                             (formatted-with-config format formatted config)))))

           (testing "break-after-args preserves parsed forms"
                    (is (format.ast-equal? parser
                                           "(defn parse-string [text] (parse.parse-string text))"
                                           (formatted-with-config format
                                                                  "(defn parse-string [text] (parse.parse-string text))"
                                                                  config))))))

(deftest exact-alias-newline-membership

         (testing "an exact alias formats through its target without inheriting newline membership"
                  (let [config {:indent-width 2
                                :parser       false
                                :indents      {"fn" [[:inner 0]]}
                                :format-as    {"my-fn" "fn"}
                                :newline      [{:applies-to {:forms ["fn"]}
                                                :options    {:after 1}}]}
                        source "(my-fn []\ntrue)\n(foo)"
                        result (formatted-with-config format source config)]
                    (is (= "(my-fn []\n  true)\n(foo)" result)))))

(deftest file-scoped-newline-membership

         (let [config {:indent-width 2
                       :parser       false
                       :indents      {"defn"    [[:block 1]]
                                      "testing" [[:block 1]]}
                       :newline      [{:applies-to {:files ["^fennel-extras/"]
                                                    :forms ["fn" "defn" "defn-"]}
                                       :options    {:after-header 1}}]}]

           (testing "file selector uses workspace-relative paths and ANDs files with forms"
                    (is (= "(defn run\n\n  []\n  true)"
                           (formatted-with-config format "(defn run\n  []\n  true)"
                                                  (doto config (tset :path "fennel-extras/format.fnl"))))))

           (testing "form selector does not apply outside its forms"
                    (is (= "(testing \"works\"\n  (is true))"
                           (formatted-with-config format "(testing \"works\"\n  (is true))"
                                                  (doto config (tset :path "fennel-extras/format.fnl"))))))

           (testing "file selector does not apply outside its path"
                    (is (= "(defn run\n  []\n  true)"
                           (formatted-with-config format "(defn run\n  []\n  true)"
                                                  (doto config (tset :path "eca/format.fnl"))))))))
