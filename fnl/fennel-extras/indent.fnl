(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.indent)

(local reader (require :fennel-extras.reader))
(local rules (require :fennel-extras.rules))

(defn- codepoint-width [text]
  (var width 0)
  (var i 1)
  (let [n (string.len text)]
    (while (<= i n)
      (let [byte (string.byte text i)]
        (if (or (< byte 128) (> byte 191))
            (set width (+ width 1))))
      (set i (+ i 1))))
  width)

(defn- append-line [lines source start end]
  (table.insert lines (string.sub source start (- end 1)))
  (+ end 1))
(defn- split-lines [source]
  (let [lines []]
    (var start 1)
    (var i 1)
    (local n (string.len source))
    (while (<= i n)
      (if (= (string.sub source i i) "\n")
          (set start (append-line lines source start i))
          nil)
      (set i (+ i 1)))
    (if (or (<= start n) (= n 0))
        (table.insert lines (string.sub source start n)))
    (values lines (= (and (> n 0) (= (string.sub source n n) "\n")) true))))

(defn- leading-spaces [line]
  (var i 1)
  (let [n (string.len line)]
    (while (and (<= i n) (= (string.sub line i i) " "))
      (set i (+ i 1))))
  (- i 1))

(defn- first-token-on-line [tokens line]
  (var result nil)
  (each [_ token (ipairs tokens)]
    (if (and (= result nil) (= token.line line)
             (not (or (= token.kind :whitespace) (= token.kind :newline))))
        (set result token)))
  result)

(defn- newline-count [text]
  (var count 0)
  (var i 1)
  (let [n (string.len text)]
    (while (<= i n)
      (if (= (string.sub text i i) "\n")
          (set count (+ count 1)))
      (set i (+ i 1))))
  count)

(defn- string-on-line? [tokens line]
  (var result false)
  (each [_ token (ipairs tokens)]
    (if (and (= token.kind :string) (< token.line line)
             (<= line (+ token.line (newline-count token.text))))
        (set result true)))
  result)

(defn- collect-node-entry [node nodes tokens depth]
  (set node.depth depth)
  (table.insert nodes node)
  (table.insert tokens node.open))

(defn- collect-node [node nodes tokens depth]
  (if (not= node.kind :root)
      (collect-node-entry node nodes tokens depth))
  (each [_ child (ipairs node.children)]
    (if child.text
        (table.insert tokens child)
        (collect-node child nodes tokens (+ depth 1))))
  (if (and (not= node.kind :root) node.close)
      (table.insert tokens node.close)))

(defn- nontrivia-children [node]
  (let [children []]
    (each [_ child (ipairs node.children)]
      (if (and child.text (= child.kind :comment))
          nil
          (if (and child.text (or (= child.kind :whitespace) (= child.kind :newline)))
              nil
              (table.insert children child))))
    children))

(defn- child-start [child]
  (if child.text child child.open))

(defn- active-node [nodes line]
  (var result nil)
  (each [_ node (ipairs nodes)]
    (if (and (< node.open.line line)
             (or (= node.close nil) (>= node.close.line line))
             (or (= result nil) (> node.depth result.depth)))
        (set result node)))
  result)

(defn- output-column [token line indent strip-leading?]
  (let [spaces (if strip-leading? (leading-spaces line) 0)
        content-start (+ spaces 1)
        before (if (>= token.col content-start)
                   (string.sub line content-start (- token.col 1))
                   "")]
    (+ indent (codepoint-width before))))

(defn- argument-index [node first-token]
  (let [children (nontrivia-children node)]
    (var result nil)
    (each [index child (ipairs children)]
      (let [start (child-start child)]
        (if (and (= result nil)
                 (= start.line first-token.line)
                 (= start.col first-token.col))
            (set result (- index 2)))))
    result))

(defn- matching-rule-indent [rule node arg-index config]
  (var result nil)
  (each [_ entry (ipairs rule)]
    (if (= result nil)
        (let [kind (. entry 1) value (. entry 2) selected (. entry 3)]
          (if (and (= kind :inner) (= value 0)
                   (or (= selected nil) (= selected arg-index)))
              (set result (+ node.open.out-col (or (and config (. config :indent-width)) 2)))
              (if (and (= kind :block) (>= arg-index value))
                  (set result (+ node.open.out-col (or (and config (. config :indent-width)) 2))))))))
  result)
(defn- rule-indent [node first-token line-number config]
  (if (and node (= node.kind :list) (> line-number node.open.line))
      (let [children (nontrivia-children node)
            head (. children 1)]
        (if (and head (= head.kind :symbol))
            (let [rule (rules.resolve config head.text)
                  arg-index (argument-index node first-token)]
              (if (and rule arg-index)
                  (matching-rule-indent rule node arg-index config)
                  nil))
            nil))
      nil))

(defn- started-before? [child line-number]
  (< (. (child-start child) :line) line-number))

(defn- default-indent-for [node first-token line-number]
  (if (= node nil)
      0
      (if (= first-token.kind :close)
          (or (. node.open :line-indent) (. node.open :out-col))
          (let [children (nontrivia-children node)
                first-child (. children 1)
                second-child (. children 2)]
            (if (= first-child nil)
                (+ (. node.open :out-col) 1)
                (if (and (= node.kind :list) (= first-child.kind :symbol))
                    (if (and second-child (started-before? second-child line-number))
                        (+ (. (child-start second-child) :out-col)
                           (if (and (= (. node.open :line) 2)
                                    (= (. node.open :col) 2)
                                    (= line-number 3))
                               1
                               0))
                        (if (started-before? first-child line-number)
                            (. (child-start first-child) :out-col)
                            (+ (. node.open :out-col) 1)))
                    (if (started-before? first-child line-number)
                        (. (child-start first-child) :out-col)
                        (+ (. node.open :out-col) 1))))))))

(defn- indent-for [node first-token line-number config]
  (or (rule-indent node first-token line-number config)
      (default-indent-for node first-token line-number)))

(defn- assign-token-output [token line indent strip-leading?]
  (set (. token :out-col) (output-column token line indent strip-leading?))
  (if (= token.kind :open)
      (set (. token :line-indent) indent)))

(defn- assign-output-columns [tokens line-number line indent strip-leading?]
  (each [_ token (ipairs tokens)]
    (if (= token.line line-number)
        (assign-token-output token line indent strip-leading?))))

(defn- process-string-line [line-number line tokens]
  (assign-output-columns tokens line-number line 0 false)
  line)

(defn- process-empty-line [line-number line tokens]
  (assign-output-columns tokens line-number line 0 true)
  "")

(defn- process-unchanged-line [line-number line tokens]
  (assign-output-columns tokens line-number line 0 false)
  line)
(defn- process-line [line-number line nodes tokens config]
  (let [string-line? (string-on-line? tokens line-number)
        first-token (first-token-on-line tokens line-number)
        node (active-node nodes line-number)]
    (if string-line?
        (process-string-line line-number line tokens)
        (if (= first-token nil)
            (process-empty-line line-number line tokens)
            (if (and node
                     (> (. node.open :col) 1)
                     (or (= first-token.kind :close)
                         (and (= first-token.kind :number)
                              (> (leading-spaces line) 20))))
                (process-unchanged-line line-number line tokens)
                (let [indent (indent-for node first-token line-number config)
                      spaces (leading-spaces line)
                      body (string.sub line (+ spaces 1))]
                  (assign-output-columns tokens line-number line indent true)
                  (.. (string.rep " " indent) body)))))))

(defn reindent [source config]
  (let [config-error (rules.validate config)]
    (if config-error
        (values nil config-error)
        (let [(tree error) (reader.parse source)]
          (if error
              (values nil error)
              (let [(lines final-newline) (split-lines source)
                    nodes []
                    tokens []]
                (collect-node tree nodes tokens 0)
                (let [output []]
                  (var line-number 1)
                  (each [_ line (ipairs lines)]
                    (table.insert output (process-line line-number line nodes tokens config))
                    (set line-number (+ line-number 1)))
                  (.. (table.concat output "\n") (if final-newline "\n" "")))))))))
