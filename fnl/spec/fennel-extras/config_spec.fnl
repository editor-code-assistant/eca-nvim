(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(defn- load-config []
  (let [(ok result) (pcall require :fennel-extras.config)]
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

(defn- parse-result
  [text]
  (let [config (load-config)]
    (if (. config :module-missing)
        config
        (let [(ok value err) (pcall (fn [] (config.parse-string text)))]
          (if ok
              {:value value :error err}
              {:call-error true :error err})))))

(defn- parse-value
  [text]
  (. (parse-result text) :value))

(defn- parse-error-summary
  [text include-location?]
  (let [result (parse-result text)]
    (if (. result :module-missing)
        result
        (let [value (. result :value)
              err (. result :error)]
          (if include-location?
              {:value? (not= nil value)
               :has-message (and (= nil value) err
                                 (= :table (type err))
                                 (= :string (type (. err :message))))
               :line (and err (. err :line))
               :col (and err (. err :col))}
              {:value? (not= nil value)
               :has-message (and (= nil value) err
                                 (= :table (type err))
                                 (= :string (type (. err :message))))})))))

(defn- validate-summary
  [value]
  (let [config (load-config)]
    (if (. config :module-missing)
        config
        (let [(ok result err) (pcall (fn [] (config.validate value)))]
          {:value? (and ok (not= nil result))
           :has-message (and ok (= nil result) err
                             (= :table (type err))
                             (= :string (type (. err :message))))}))))

(defn- write-file
  [path text]
  (let [file (assert (io.open path :w))]
    (file:write text)
    (file:close)
    path))

(defn- find-load-scenario []
  (let [root (vim.fn.tempname)
        nested (.. root "/one/two")
        root-config (.. root "/.fnl-extras.fnl")
        config-path (.. root "/one/.fnl-extras.fnl")
        stop-root (.. root "/stop")
        stop-nested (.. stop-root "/child")
        stop-git (.. stop-root "/.git")]
    (vim.fn.mkdir nested "p")
    (vim.fn.mkdir stop-nested "p")
    (vim.fn.mkdir stop-git "p")
    (with-cleanup
     (fn [] (vim.fn.delete root "rf"))
      (fn []
        (write-file root-config "{:exclude [\"root\"]}")
        (write-file config-path "{:paths [\"fnl\"]}")
        (write-file (.. root "/valid.fnl-extras.fnl") "{:exclude [\"generated\"]}")
        {:start (let [config (load-config)]
                  (if (. config :module-missing)
                      config
                      (config.find root)))
         :parent (let [config (load-config)]
                   (if (. config :module-missing)
                       config
                       (config.find nested)))
         :stopped (let [config (load-config)]
                    (if (. config :module-missing)
                        config
                        (config.find stop-nested)))
         :root-config root-config
         :config-path config-path
         :loaded (let [config (load-config)]
                   (if (. config :module-missing)
                       config
                       (config.load config-path)))
         :missing (let [config (load-config)]
                    (if (. config :module-missing)
                        config
                        (let [(ok value err)
                              (pcall (fn [] (config.load (.. root "/missing.fnl-extras.fnl"))))]
                          {:value? (and ok (not= nil value))
                           :has-message (and ok (= nil value) err
                                             (= :table (type err))
                                             (= :string (type (. err :message))))})))}))))

(deftest parse-string
  (testing "parses a realistic data-only configuration and converts keywords to strings"
    (is (= {:indents {:deftest [["block" 1]]
                      :testing [["block" 1]]}
            :format-as {:my-let "let"}
            :paths ["fnl"]
            :exclude ["fnl/eca/nfnl"]}
           (parse-value "{:indents {\"deftest\" [[:block 1]] \"testing\" [[:block 1]]} :format-as {\"my-let\" \"let\"} :paths [\"fnl\"] :exclude [\"fnl/eca/nfnl\"]}"))))
  (testing "parses escapes, numbers, booleans, nil, and ignores comments"
    (is (= {:text "quote \" slash \\ line\n tab\t"
            :one 1
            :decimal 2.5
            :negative -3
            :yes true
            :no false
            :nothing nil}
           (parse-value "{:text \"quote \\\" slash \\\\ line\\n tab\\t\" ; comment\n :one 1 :decimal 2.5 :negative -3 :yes true :no false :nothing nil}")))))

(deftest rejection
  (testing "rejects a list and reports line 1 column 5"
    (is (= {:value? false :has-message true :line 1 :col 5}
           (parse-error-summary "{:a (require :x)}" true))))
  (testing "rejects a bare symbol"
    (is (= {:value? false :has-message true}
           (parse-error-summary "{:a foo}" false))))
  (testing "rejects hash reader prefixes"
    (is (= {:value? false :has-message true}
           (parse-error-summary "{:a #(x)}" false))))
  (testing "rejects more than one top-level form"
    (is (= {:value? false :has-message true}
           (parse-error-summary "{} {}" false))))
  (testing "rejects an empty file"
    (is (= {:value? false :has-message true}
           (parse-error-summary "" false))))
  (testing "rejects a non-table top-level form"
    (is (= {:value? false :has-message true}
           (parse-error-summary "[1]" false))))
  (testing "rejects unbalanced input"
    (is (= {:value? false :has-message true}
           (parse-error-summary "{:a 1" false))))
  (testing "validate rejects an unknown top-level key"
    (is (= {:value? false :has-message true}
           (validate-summary {:colour 1}))))
  (testing "validate rejects paths that are not a sequence"
    (is (= {:value? false :has-message true}
           (validate-summary {:paths "fnl"})))))

(deftest find-load
  (testing "find returns a config in the start directory"
    (let [result (find-load-scenario)]
      (is (= (. result :root-config) (. result :start)))))
  (testing "find returns the nearest config in a parent directory"
    (let [result (find-load-scenario)]
      (is (= (. result :config-path) (. result :parent)))))
  (testing "find stops at a .git directory"
    (is (nil? (. (find-load-scenario) :stopped))))
  (testing "load returns the validated table from a file"
    (is (= {:paths ["fnl"]} (. (find-load-scenario) :loaded))))
  (testing "load returns a structured error for a missing path"
    (is (= {:value? false :has-message true}
           (. (find-load-scenario) :missing)))))
