(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(defn- load-reader []
  (let [(ok result) (pcall require :fennel-extras.reader)]
    (if ok
        result
        {:error "module missing"})))

(defn- read-source [path]
  (let [(ok result) (pcall (fn []
                             (let [file (assert (io.open path :r))
                                   source (file:read "*a")]
                               (file:close)
                               source)))]
    (if ok
        result
        {:error "read failed" :path path})))

(defn- file-paths []
  (let [paths []
        fnl-files (vim.fn.globpath "fnl" "**/*.fnl" false true)
        fnlm-files (vim.fn.globpath "fnl" "**/*.fnlm" false true)]
    (each [_ path (ipairs fnl-files)]
      (table.insert paths path))
    (each [_ path (ipairs fnlm-files)]
      (table.insert paths path))
    paths))

(defn- token-text [tokens]
  (table.concat
   (icollect [_ token (ipairs tokens)]
     (. token :text))))

(defn- token-kinds [tokens]
  (icollect [_ token (ipairs tokens)]
    (. token :kind)))

(defn- round-trip-scenario []
  (let [reader (load-reader)
        failures []]
    (if (. reader :error)
        (each [_ path (ipairs (file-paths))]
          (table.insert failures path))
        (each [_ path (ipairs (file-paths))]
          (let [source (read-source path)]
            (if (. source :error)
                (table.insert failures (.. "read failed: " path))
                (let [(ok parsed) (pcall (fn [] (reader.parse source)))
                      (token-ok tokens) (pcall (fn [] (reader.tokenize source)))]
                  (if (or (not ok)
                          (not token-ok)
                          (= nil parsed)
                          (= nil tokens)
                          (not= source (reader.to-string parsed))
                          (not= source (token-text tokens)))
                      (table.insert failures path)))))))
    failures))

(defn- tokenize-scenario [source]
  (let [reader (load-reader)]
    (if (. reader :error)
        reader
        (let [(ok result) (pcall (fn [] (reader.tokenize source)))]
          (if ok result {:error "tokenize failed"})))))

(defn- parse-scenario [source]
  (let [reader (load-reader)]
    (if (. reader :error)
        reader
        (let [(ok result) (pcall (fn [] (reader.parse source)))]
          (if ok result {:error "parse failed"})))))

(defn- kinds-for [source]
  (let [tokens (tokenize-scenario source)]
    (if (. tokens :error)
        tokens
        (token-kinds tokens))))

(defn- nested-kinds []
  (let [root (parse-scenario "(a [b {:c d}])")]
    (if (. root :error)
        root
        (let [outer (. root.children 1)
              sequence (. outer.children 3)
              table (. sequence.children 3)]
          [(. outer :kind) (. sequence :kind) (. table :kind)]))))

(defn- comment-child-kind []
  (let [parsed (parse-scenario "(a ;; comment\n)")]
    (if (. parsed :error)
        parsed
        (let [list-node (. parsed.children 1)
              child (. list-node.children 3)]
          (. child :kind)))))

(defn- fail-closed-scenario [source]
  (let [reader (load-reader)]
    (if (. reader :error)
        reader
        (let [(ok result err) (pcall (fn [] (reader.parse source)))]
          (if (not ok)
              {:value? true :has-message false}
              {:value? (not= nil result)
               :has-message (and err (= :string (type (. err :message))))
               :line (and err (. err :line))
               :col (and err (. err :col))})))))

(defn- fail-closed-summary [source include-location?]
  (let [result (fail-closed-scenario source)]
    (if (. result :error)
        result
        (if include-location?
            {:value? (. result :value?)
             :has-message (. result :has-message)
             :line (. result :line)
             :col (. result :col)}
            {:value? (. result :value?)
             :has-message (. result :has-message)}))))

(deftest round-trip
  (testing "all Fennel sources round-trip through parsing and tokenization"
           (is (= [] (round-trip-scenario)))))

(deftest structure
  (testing "a string containing delimiters, semicolon, and an escaped quote is one string token"
           (is (= [:string] (kinds-for "\"a) ; \\\" b\""))))
  (testing "a multi-line string is one string token"
           (is (= [:string] (kinds-for "\"line one
line two\""))))
  (testing "a parenthesis in a comment does not open a list"
           (is (= [:comment :newline :open :symbol :close]
                  (kinds-for ";; comment (\n(a)"))))
  (testing "hash prefix is followed by a list"
           (is (= [:prefix :open :symbol :whitespace :symbol :whitespace :symbol :close]
                  (kinds-for "#(+ $1 $2)"))))
  (testing "quote and unquote prefixes are preserved"
           (is (= [:prefix :open :symbol :whitespace :prefix :symbol :close]
                  (kinds-for "`(foo ,bar)"))))
  (testing "keywords, punctuation symbols, and numbers have their respective kinds"
           (is (= [:symbol :whitespace :symbol :whitespace :symbol :whitespace :symbol
                   :whitespace :symbol :whitespace :number :whitespace :number :whitespace
                   :number :whitespace :number]
                  (kinds-for ":kw a.b:c ?. & ... 0x1F 1e3 1_000 -2.5"))))
  (testing "a comment before a close delimiter is a child of that list"
           (is (= :comment (comment-child-kind))))
  (testing "a leading shebang line is one comment token"
           (is (= [:comment :newline :symbol]
                  (kinds-for "#!/usr/bin/env fennel\nfoo"))))
  (testing "nested delimiters produce list, sequence, and table nodes"
           (is (= [:list :sequence :table] (nested-kinds)))))

(deftest fail-closed
  (testing "an extra close delimiter returns an error at line 2 column 5"
           (is (= {:value? false :has-message true :line 2 :col 5}
                  (fail-closed-summary "(ok)\n    )" true))))
  (testing "a missing close delimiter returns an error"
           (is (= {:value? false :has-message true}
                  (fail-closed-summary "(missing"))))
  (testing "an unterminated string returns an error"
           (is (= {:value? false :has-message true}
                  (fail-closed-summary "\"unterminated"))))
  (testing "at-sign reader syntax returns an error"
           (is (= {:value? false :has-message true}
                  (fail-closed-summary "@foo"))))
  (testing "comma-at reader syntax returns an error"
           (is (= {:value? false :has-message true}
                  (fail-closed-summary ",@foo"))))
  (testing "a tab outside strings and comments returns an error"
           (is (= {:value? false :has-message true}
                  (fail-closed-summary "foo\tbar"))))
  (testing "carriage-return line endings return an error"
           (is (= {:value? false :has-message true}
                  (fail-closed-summary "foo\r\nbar"))))
  (testing "an escaped carriage return inside a string returns an error"
           (is (= {:value? false :has-message true}
                  (fail-closed-summary "\"\\\r\"")))))
