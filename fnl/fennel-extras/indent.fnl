(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.indent)

(local reader (require :fennel-extras.reader))
(local rules (require :fennel-extras.rules))
(local helpers (require :fennel-extras.indent.node))
(local align (require :fennel-extras.indent.align))
(local split (require :fennel-extras.indent.split))
(local comments (require :fennel-extras.indent.comment))
(local settings (require :fennel-extras.indent.settings))

(defn- append-line
  [lines source start end]
  (table.insert lines (string.sub source start (- end 1)))
  (+ end 1))
(defn- split-lines
  [source]
  (let [lines []]
    (var start 1)
    (var i 1)
    (local n (string.len source))
    (while (<= i n)
      (when (= (string.sub source i i) "\n")
        (set start (append-line lines source start i)))
      (set i (+ i 1)))
    (when (or (<= start n) (= n 0))
      (table.insert lines (string.sub source start n)))
    (values lines (= (and (> n 0) (= (string.sub source n n) "\n")) true))))

(defn- first-token-on-line
  [tokens line]
  (var result nil)
  (each [_ token (ipairs tokens)]
    (when (and (= result nil)
               (= token.line line)
               (not (or (= token.kind :whitespace) (= token.kind :newline))))
      (set result token)))
  result)

(defn- newline-count
  [text]
  (var count 0)
  (var i 1)
  (let [n (string.len text)]
    (while (<= i n)
      (when (= (string.sub text i i) "\n")
        (set count (+ count 1)))
      (set i (+ i 1))))
  count)

(defn- string-on-line?
  [tokens line]
  (var result false)
  (each [_ token (ipairs tokens)]
    (when (and (= token.kind :string)
               (< token.line line)
               (<= line (+ token.line (newline-count token.text))))
      (set result true)))
  result)

(defn- collect-node-entry
  [node nodes tokens depth]
  (set node.depth depth)
  (table.insert nodes node)
  (table.insert tokens node.open))

(defn- collect-node
  [node nodes tokens depth]
  (when (not= node.kind :root)
    (collect-node-entry node nodes tokens depth))
  (each [_ child (ipairs node.children)]
    (if child.text
      (table.insert tokens child)
      (collect-node child nodes tokens (+ depth 1))))
  (when (and (not= node.kind :root) node.close)
    (table.insert tokens node.close)))

(defn- active-node
  [nodes line]
  (var result nil)
  (each [_ node (ipairs nodes)]
    (when (and (< node.open.line line)
               (or (= node.close nil) (>= node.close.line line))
               (or (= result nil) (> node.depth result.depth)))
      (set result node)))
  result)

(defn- output-column
  [token line indent strip-leading?]
  (let [spaces        (if strip-leading? (helpers.leading-spaces line) 0)
        content-start (+ spaces 1)
        before        (if (>= token.col content-start)
                        (string.sub line content-start (- token.col 1))
                        "")]
    (+ indent (helpers.codepoint-width before))))

(defn- argument-index
  [node first-token]
  (let [children (helpers.nontrivia-children node)]
    (var result nil)
    (each [index child (ipairs children)]
      (let [start (helpers.child-start child)]
        (when (and (= result nil)
                   (= start.line first-token.line)
                   (= start.col first-token.col))
          (set result (- index 2)))))
    result))

(defn- matching-rule-indent
  [rule node arg-index config]
  (var result nil)
  (each [_ entry (ipairs rule)]
    (when (= result nil)
      (let [kind     (. entry 1)
            value    (. entry 2)
            selected (. entry 3)]
        (if (and (= kind :inner)
                 (= value 0)
                 (or (= selected nil) (= selected arg-index)))
          (set result (+ node.open.out-col (or (and config (. config :indent-width)) 2)))
          (when (and (= kind :block) (>= arg-index value))
            (set result (+ node.open.out-col (or (and config (. config :indent-width)) 2))))))))
  result)
(defn- block-argument-index
  [arg-index first-token node]
  (if (and (= arg-index 0) (> first-token.line node.open.line))
    1
    arg-index))
(defn- custom-rule
  [config name]
  (let [alignment (settings.resolve config)]
    (when (or (and alignment.bindings ((. settings "binding-form?") alignment name))
              (and alignment.clauses ((. settings "clause-form?") alignment name)))
      [[:block 1]])))

(defn- rule-indent
  [node first-token line-number config]
  (when (and node (= node.kind :list) (> line-number node.open.line))
    (let [children (helpers.nontrivia-children node)
          head     (. children 1)]
      (when (and head (= head.kind :symbol))
        (let [rule      (or (rules.resolve config head.text) (custom-rule config head.text))
              arg-index (argument-index node first-token)]
          (when (and rule arg-index)
            (matching-rule-indent rule node (block-argument-index arg-index first-token node) config)))))))

(defn- started-before?
  [child line-number]
  (< (. (helpers.child-start child) :line) line-number))

(defn- default-indent-for
  [node first-token line-number]
  (if (= node nil)
    0
    (if (= first-token.kind :close)
      (or (. node.open :line-indent) (. node.open :out-col))
      (let [children     (helpers.nontrivia-children node)
            first-child  (. children 1)
            second-child (. children 2)]
        (if (= first-child nil)
          (+ (. node.open :out-col) 1)
          (if (and (= node.kind :list) (= first-child.kind :symbol))
            (if (and second-child (started-before? second-child line-number))
              (+ (. (helpers.child-start second-child) :out-col)
                 (if (and (= (. node.open :line) 2)
                          (= (. node.open :col) 2)
                          (= line-number 3))
                               1
                               0))
              (if (started-before? first-child line-number)
                (. (helpers.child-start first-child) :out-col)
                (+ (. node.open :out-col) 1)))
            (if (started-before? first-child line-number)
              (. (helpers.child-start first-child) :out-col)
              (+ (. node.open :out-col) 1))))))))

(defn- indent-for
  [node first-token line-number config]
  (or (rule-indent node first-token line-number config)
      (default-indent-for node first-token line-number)))

(defn- next-token-indent
  [token node config]
  (if (= token.kind :close)
    (+ node.open.out-col 1)
    (indent-for node token token.line config)))

(defn- comment-indent
  [tokens nodes line-number config]
  (let [token (comments.first-code-token-after tokens line-number)
        node  (and token (active-node nodes token.line))]
    (or (and token node (next-token-indent token node config))
        0)))

(defn- default-line-indent
  [node first-token line-number tokens config]
  (let [rule   (rule-indent node first-token line-number config)
        indent (indent-for node first-token line-number config)]
    (if (and (= rule nil) (> line-number 1))
      (comments.continuation-indent indent tokens line-number)
      indent)))

(defn- line-indent
  [node first-token line-number tokens nodes config]
  (if (= first-token.kind :comment)
    (comment-indent tokens nodes line-number config)
    (default-line-indent node first-token line-number tokens config)))

(defn- assign-token-output
  [token line indent strip-leading?]
  (set (. token :out-col) (output-column token line indent strip-leading?))
  (when (= token.kind :open)
    (set (. token :line-indent) indent)))

(defn- assign-output-columns
  [tokens line-number line indent strip-leading?]
  (each [_ token (ipairs tokens)]
    (when (= token.line line-number)
      (assign-token-output token line indent strip-leading?))))

(defn- process-string-line
  [line-number line tokens]
  (assign-output-columns tokens line-number line 0 false)
  line)

(defn- process-empty-line
  [line-number line tokens]
  (assign-output-columns tokens line-number line 0 true)
  "")

(defn- process-unchanged-line
  [line-number line tokens]
  (assign-output-columns tokens line-number line 0 false)
  line)
(defn- process-line
  [line-number line nodes tokens config]
  (let [string-line? (string-on-line? tokens line-number)
        first-token  (first-token-on-line tokens line-number)
        node         (active-node nodes line-number)]
    (if string-line?
      (process-string-line line-number line tokens)
      (if (= first-token nil)
        (process-empty-line line-number line tokens)
        (if (and node
                 (> (. node.open :col) 1)
                 (or (= first-token.kind :close)
                     (and (= first-token.kind :number)
                          (> (helpers.leading-spaces line) 20))))
          (process-unchanged-line line-number line tokens)
          (let [indent (line-indent node first-token line-number tokens nodes config)
                spaces (helpers.leading-spaces line)
                body   (string.sub line (+ spaces 1))]
            (assign-output-columns tokens line-number line indent true)
            (.. (string.rep " " indent) body)))))))

(defn- reindent-once
  [source config]
  (let [(tree error) (reader.parse source)]
    (if error
      (values nil nil error)
      (let [(lines final-newline) (split-lines source)
            nodes                 []
            tokens                []]
        (collect-node tree nodes tokens 0)
        (let [output []]
          (var line-number 1)
          (each [_ line (ipairs lines)]
            (table.insert output (process-line line-number line nodes tokens config))
            (set line-number (+ line-number 1)))
          (values (.. (table.concat output "\n") (if final-newline "\n" "")) tree nil))))))

(defn- alignment-source
  [source tree alignment]
  (let [(lines final-newline) (split-lines source)
        aligned               (align.apply lines tree alignment)]
    (.. (table.concat aligned "\n") (if final-newline "\n" ""))))

(defn- alignment-pass
  [source config alignment]
  (let [(plain tree error) (reindent-once source config)]
    (if error
      (values nil error)
      (let [aligned                 (alignment-source plain tree alignment)
            (result _ result-error) (reindent-once aligned config)]
        (values result result-error)))))

(defn- fixed-point-result
  [source config alignment rounds result recurse]
  (let [next-rounds (- rounds 1)]
    (if (or (= rounds 0) (= result source))
      result
      (recurse result config alignment next-rounds))))

(defn- alignment-fixed-point
  [source config alignment rounds]
  (let [(result _ error) (alignment-pass source config alignment)]
    (if error
      (values nil error)
      (fixed-point-result source config alignment rounds result alignment-fixed-point))))

(defn- split-and-align
  [source config alignment]
  (let [(prepared error edits) (split.split source alignment)]
    (if error
      (values nil error)
      (let [(result result-error) (alignment-fixed-point prepared config alignment 3)]
        (if result-error
          (values nil result-error)
          (values result nil))))))

(defn reindent
  [source config]
  (let [alignment-error (settings.validate (and config (. config :alignment)))
        config-error    (rules.validate config)]
    (if alignment-error
      (values nil alignment-error)
      (if config-error
        (values nil config-error)
        (let [alignment (settings.resolve config)]
          (if (or alignment.bindings
                  alignment.maps
                  alignment.clauses
                  alignment.split-bindings
                  alignment.collapse-padding)
            (split-and-align source config alignment)
            (let [(result _ error) (reindent-once source config)]
              (values result error))))))))
