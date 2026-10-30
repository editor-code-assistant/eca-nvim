(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

;; Unit 4 output contract decisions:
;; - stale-exclusion JSON records omit :end-line and :end-col because stale
;;   records have no source-form span.
;; - control characters use uppercase hexadecimal in JSON unicode escapes.
;; - output.sort returns a new list; callers may choose to sort before render.

(defn- load-output
  []
  (let [(ok result) (pcall require :fennel-extras.lint.output)]
    (if ok
      result
      {:module-missing true})))



(defn- text-lines
  [diagnostics]
  (let [output (load-output)]
    (if (. output :module-missing)
      output
      (output.text-lines diagnostics))))



(defn- json-lines
  [diagnostics]
  (let [output (load-output)]
    (if (. output :module-missing)
      output
      (output.json-lines diagnostics))))



(defn- sorted
  [diagnostics]
  (let [output (load-output)]
    (if (. output :module-missing)
      output
      (output.sort diagnostics))))



(defn- diagnostic-signatures
  [diagnostics]
  (let [signatures []]
    (each [_ diagnostic (ipairs diagnostics)]
      (table.insert signatures
                    (.. diagnostic.path
                        ":"
                        diagnostic.line
                        ":"
                        diagnostic.rule
                        ":"
                        diagnostic.form
                        ":"
                        diagnostic.message)))
    (table.concat signatures "\n")))



(defn- finding
  [overrides]
  (let [base {:kind     "finding"
              :path     "fnl/app.fnl"
              :line     12
              :col      5
              :end-line 12
              :end-col  18
              :severity "error"
              :rule     "if-branch-call"
              :form     "fnl/app.fnl > module:app > defn:run > if#1 > then"
              :message  "if branch contains multiple expressions; move them to a named helper"}]
    (each [key value (pairs overrides)]
      (tset base key value))
    base))



(defn- json-case
  [message]
  {:message message
   :json    (json-lines [(finding {:message message})])})



(defn- stale-exclusion
  [overrides]
  (let [base {:kind     "stale-exclusion"
              :path     ".fnl-extras.fnl"
              :line     7
              :col      9
              :severity "error"
              :rule     "if-branch-call"
              :form     "fnl/app.fnl > module:app > defn:run > if#1 > then"
              :message  "exclusion does not match any finding"}]
    (each [key value (pairs overrides)]
      (tset base key value))
    base))



(deftest text-output



  (testing "renders an error finding and its valid copyable exclusion suggestion"
    (is (= ["fnl/app.fnl:12:5: error if-branch-call: if branch contains multiple expressions; move them to a named helper"
            "  exclusion: {:rule \"if-branch-call\" :form \"fnl/app.fnl > module:app > defn:run > if#1 > then\" :reason \"explain why this is intentional\"}"]
           (text-lines [(finding {})]))))



  (testing "renders a warning finding with the same text contract"
    (is (= ["fnl/lib.fnl:3:2: warning module-import: use the target-style core binding"
            "  exclusion: {:rule \"module-import\" :form \"fnl/lib.fnl > top#1\" :reason \"explain why this is intentional\"}"]
           (text-lines [(finding {:path     "fnl/lib.fnl"
                                  :line     3
                                  :col      2
                                  :end-line 3
                                  :end-col  31
                                  :severity "warning"
                                  :rule     "module-import"
                                  :form     "fnl/lib.fnl > top#1"
                                  :message  "use the target-style core binding"})]))))



  (testing "escapes a quote and backslash in the text exclusion snippet"
    (is (= ["fnl/quote.fnl:1:1: error custom: bad form"
            "  exclusion: {:rule \"custom\\\"rule\" :form \"fnl/quote.fnl > top#1\\\\ > \\\"quoted\\\"\" :reason \"explain why this is intentional\"}"]
           (text-lines [(finding {:path    "fnl/quote.fnl"
                                  :line    1
                                  :col     1
                                  :rule    "custom\"rule"
                                  :form    "fnl/quote.fnl > top#1\\ > \"quoted\""
                                  :message "bad form"})]))))



  (testing "renders a stale exclusion without a snippet"
    (is (= [".fnl-extras.fnl:7:9: error if-branch-call: exclusion does not match any finding"]
           (text-lines [(stale-exclusion {})])))))

(deftest json-output



  (testing "renders a finding as one exact ordered JSON object"
    (is (= ["{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"if-branch-call\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"if branch contains multiple expressions; move them to a named helper\"}"]
           (json-lines [(finding {})]))))



  (testing "omits end-line and end-col from stale exclusion JSON"
    (is (= ["{\"kind\":\"stale-exclusion\",\"path\":\".fnl-extras.fnl\",\"line\":7,\"col\":9,\"severity\":\"error\",\"rule\":\"if-branch-call\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"exclusion does not match any finding\"}"]
           (json-lines [(stale-exclusion {})]))))



  (testing "escapes quote backslash newline tab carriage return controls and preserves UTF-8"
    (let [slash           (string.char 92)
          control-path    (.. "p\"ath\\" "\n" "\t" "\r" (string.char 1) (string.char 31) "é😀")
          control-message (.. "m\" \\ " "\n" "\t" "\r" (string.char 1) " " (string.char 31) " é 😀")
          expected        (.. "{\"kind\":\"finding\",\"path\":\"p" slash "\"" "ath" slash slash slash "n" slash "t" slash "r" slash "u0001" slash "u001Fé😀\",\"line\":1,\"col\":1,\"end-line\":1,\"end-col\":2,\"severity\":\"error\",\"rule\":\"r\",\"form\":\"f\",\"message\":\"m" slash "\"" " " slash slash " " slash "n" slash "t" slash "r" slash "u0001" " " slash "u001F é 😀\"}")]
      (is (= [expected]
             (json-lines [(finding {:path     control-path
                                    :line     1
                                    :col      1
                                    :end-line 1
                                    :end-col  2
                                    :rule     "r"
                                    :form     "f"
                                    :message  control-message})])))))



  (testing "replaces an invalid UTF-8 byte with U+FFFD in JSON"
    (let [message  (.. "a" (string.char 255) "b")
          expected (.. "{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"if-branch-call\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"a" (string.char 239) (string.char 191) (string.char 189) "b\"}")]
      (is (= [expected]
             (json-lines [(finding {:message message})])))))



  (testing "replaces a truncated UTF-8 sequence with U+FFFD in JSON"
    (let [message  (string.char 195)
          expected (.. "{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"if-branch-call\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"" (string.char 239) (string.char 191) (string.char 189) "\"}")]
      (is (= [expected]
             (json-lines [(finding {:message message})])))))



  (testing "preserves DEL as a raw byte in JSON"
    (let [message  (string.char 127)
          expected (.. "{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"if-branch-call\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"" (string.char 127) "\"}")]
      (is (= [expected]
             (json-lines [(finding {:message message})])))))



  (testing "preserves valid UTF-8 in JSON"
    (let [message  "é😀"
          expected "{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"if-branch-call\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"é😀\"}"]
      (is (= [expected]
             (json-lines [(finding {:message message})])))))



  (testing "preserves U+E000 bytes in JSON"
    (let [message  (.. (string.char 238) (string.char 128) (string.char 128))
          expected (.. "{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"if-branch-call\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"" message "\"}")]
      (is (= [expected]
             (json-lines [(finding {:message message})])))))



  (testing "preserves U+FFFD bytes in JSON"
    (let [message  (.. (string.char 239) (string.char 191) (string.char 189))
          expected (.. "{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"if-branch-call\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"" message "\"}")]
      (is (= [expected]
             (json-lines [(finding {:message message})])))))



  (testing "preserves U+FFFF bytes in JSON"
    (let [message  (.. (string.char 239) (string.char 191) (string.char 191))
          expected (.. "{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"if-branch-call\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"" message "\"}")]
      (is (= [expected]
             (json-lines [(finding {:message message})])))))



  (testing "handles UTF-8 boundary bytes and invalid sequences in JSON"
    (let [replacement (.. (string.char 239) (string.char 191) (string.char 189))
          prefix      "{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"if-branch-call\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\""
          suffix      "\"}"
          cases       {:u007f          (string.char 127)
                       :u0080          (.. (string.char 194) (string.char 128))
                       :u07ff          (.. (string.char 223) (string.char 191))
                       :u0800          (.. (string.char 224) (string.char 160) (string.char 128))
                       :uD7FF          (.. (string.char 237) (string.char 159) (string.char 191))
                       :u10000         (.. (string.char 240) (string.char 144) (string.char 128) (string.char 128))
                       :u10FFFF        (.. (string.char 244) (string.char 143) (string.char 191) (string.char 191))
                       :surrogate      (.. (string.char 237) (string.char 160) (string.char 128))
                       :above-u10FFFF  (.. (string.char 244) (string.char 144) (string.char 128) (string.char 128))
                       :overlong-two   (.. (string.char 192) (string.char 128))
                       :overlong-three (.. (string.char 224) (string.char 128) (string.char 128))}
          actual      {}
          expected    {:u007f          {:message (. cases :u007f) :json [(.. prefix (. cases :u007f) suffix)]}
                       :u0080          {:message (. cases :u0080) :json [(.. prefix (. cases :u0080) suffix)]}
                       :u07ff          {:message (. cases :u07ff) :json [(.. prefix (. cases :u07ff) suffix)]}
                       :u0800          {:message (. cases :u0800) :json [(.. prefix (. cases :u0800) suffix)]}
                       :uD7FF          {:message (. cases :uD7FF) :json [(.. prefix (. cases :uD7FF) suffix)]}
                       :u10000         {:message (. cases :u10000) :json [(.. prefix (. cases :u10000) suffix)]}
                       :u10FFFF        {:message (. cases :u10FFFF) :json [(.. prefix (. cases :u10FFFF) suffix)]}
                       :surrogate      {:message (. cases :surrogate) :json [(.. prefix replacement replacement replacement suffix)]}
                       :above-u10FFFF  {:message (. cases :above-u10FFFF) :json [(.. prefix replacement replacement replacement replacement suffix)]}
                       :overlong-two   {:message (. cases :overlong-two) :json [(.. prefix replacement replacement suffix)]}
                       :overlong-three {:message (. cases :overlong-three) :json [(.. prefix replacement replacement replacement suffix)]}}]
      (each [key message (pairs cases)]
        (tset actual key (json-case message)))
      (is (= expected actual))))



  (testing "preserves invalid UTF-8 bytes in text output"
    (let [message (.. "a" (string.char 255) "b")]
      (is (= [(.. "fnl/app.fnl:12:5: error if-branch-call: " message)
              "  exclusion: {:rule \"if-branch-call\" :form \"fnl/app.fnl > module:app > defn:run > if#1 > then\" :reason \"explain why this is intentional\"}"]
             (text-lines [(finding {:message message})])))))



  (testing "returns one JSON object per diagnostic without embedded newlines"
    (is (= 2 (length (json-lines [(finding {}) (stale-exclusion {})]))))))

(deftest ordering-and-purity



  (testing "sorts by path line column severity rule form and message"
    (is (= [(finding {:path "a.fnl" :line 1 :col 1 :severity "error" :rule "a" :form "a" :message "z"})
            (finding {:path "a.fnl" :line 1 :col 1 :severity "warning" :rule "a" :form "a" :message "a"})
            (finding {:path "b.fnl" :line 1 :col 1 :severity "error" :rule "a" :form "a" :message "a"})]
           (sorted [(finding {:path "b.fnl" :line 1 :col 1 :severity "error" :rule "a" :form "a" :message "a"})
                    (finding {:path "a.fnl" :line 1 :col 1 :severity "warning" :rule "a" :form "a" :message "a"})
                    (finding {:path "a.fnl" :line 1 :col 1 :severity "error" :rule "a" :form "a" :message "z"})]))))



  (testing "does not mutate its input and is deterministic across repeated calls"
    (let [input  [(finding {:path "b.fnl"}) (finding {:path "a.fnl"})]
          before (diagnostic-signatures input)
          first  (sorted input)
          second (sorted input)]
      (is (and (= before (diagnostic-signatures input))
               (= (diagnostic-signatures first) (diagnostic-signatures second))
               (not (= input first))))))



  (testing "returns an empty list for empty input"
    (is (= [] (sorted [])))))
