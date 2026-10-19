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
  (let [spaces        (if strip-leading? (leading-spaces line) 0)
        content-start (+ spaces 1)
        before        (if (>= token.col content-start)
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
            head     (. children 1)]
        (if (and head (= head.kind :symbol))
            (let [rule      (rules.resolve config head.text)
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
          (let [children     (nontrivia-children node)
                first-child  (. children 1)
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
(defn- alignment-form-name? [head]
  (and head (= head.kind :symbol)
       (or (= head.text "let") (= head.text "when-let")
           (= head.text "if-let") (= head.text "with-open"))))

(defn- alignment-form? [node parent]
  (and parent (= node.kind :sequence) (= parent.kind :list)
       (alignment-form-name? (. (nontrivia-children parent) 1))))

(defn- alignment-node? [node parent]
  (or (= node.kind :table) (alignment-form? node parent)))

(defn- append-alignment-node [result node]
  (table.insert result node)
  result)

(defn- alignment-node-result [result node parent]
  (if (alignment-node? node parent)
      (append-alignment-node result node)
      result))

(defn- collect-alignment-nodes [node parent result]
  (let [next-result (alignment-node-result result node parent)]
    (accumulate [state next-result _ child (ipairs node.children)]
      (or (and child.text state)
          (collect-alignment-nodes child node state)))))

(defn- child-end [child]
  (if child.text
      child
      child.close))

(defn- single-line-name? [name-start name-end]
  (and name-end (= name-start.line name-end.line)))

(defn- append-pair-candidate [result name-start name-end value-start value parent-kind]
  (table.insert result {:name name-start :name-end name-end :value value-start :value-node value
                        :parent-kind parent-kind :line name-start.line})
  result)

(defn- adjacent-token? [left right]
  (= (+ left.out-col (codepoint-width left.text)) right.out-col))

(defn- name-end-index [children index]
  (let [name      (. children index)
        candidate (. children (+ index 1))]
    (if (and candidate (= candidate.kind :prefix)
             (adjacent-token? (child-end name) candidate))
        (name-end-index children (+ index 1))
        index)))

(defn- value-index [children index]
  (let [candidate (. children index)]
    (if (and candidate (= candidate.kind :prefix))
        (value-index children (+ index 1))
        index)))

(defn- pair-candidate [children index result parent-kind]
  (let [name-end-position (name-end-index children index)
        name              (. children index)
        name-end          (child-end (. children name-end-position))
        value-start-child (. children (+ name-end-position 1))
        value-position    (value-index children (+ name-end-position 1))
        value             (. children value-position)
        name-start        (child-start name)
        value-start       (and value-start-child (child-start value-start-child))]
    (if (and value value-start
             (= name-start.line value-start.line)
             (single-line-name? name-start name-end))
        (append-pair-candidate result name-start name-end value-start value parent-kind)
        result)))

(defn- pair-candidates-step [children index result parent-kind next]
  (let [name-end-position (name-end-index children index)
        next-index        (+ (value-index children (+ name-end-position 1)) 1)]
    (next children next-index
          (pair-candidate children index result parent-kind)
          parent-kind)))

(defn- pair-candidates [children index result parent-kind]
  (if (> index (length children))
      result
      (pair-candidates-step children index result parent-kind pair-candidates)))

(defn- pair-count-step [count pair line]
  (if (= pair.line line) (+ count 1) count))

(defn- pair-count [pairs line]
  (accumulate [count 0 _ pair (ipairs pairs)]
    (pair-count-step count pair line)))

(defn- candidate? [pairs pair]
  (= (pair-count pairs pair.line) 1))

(defn- single-pair [pairs pair]
  (if (candidate? pairs pair) pair))

(defn- single-pairs [pairs]
  (icollect [_ pair (ipairs pairs)]
    (single-pair pairs pair)))

(defn- pair-name-width [pair]
  (- (+ pair.name-end.out-col (codepoint-width pair.name-end.text))
     pair.name.out-col))

(defn- pair-target [pair width]
  (if (and (= pair.parent-kind :table) (= pair.name.text "("))
      (+ pair.name.out-col width)
      (+ pair.name.out-col width 1)))

(defn- alignment-width [pairs]
  (accumulate [width 0 _ pair (ipairs pairs)]
    (math.max width (pair-name-width pair))))

(defn- alignment-plan-for-pairs [pairs]
  (if (> (length pairs) 1)
      {:pairs pairs :width (alignment-width pairs)}
      nil))

(defn- alignment-plan [node]
  (let [children (nontrivia-children node)
        pairs    (single-pairs (pair-candidates children 1 [] node.kind))]
    (alignment-plan-for-pairs pairs)))

(defn- alignment-plans [nodes]
  (icollect [_ node (ipairs nodes)]
    (alignment-plan node)))

(defn- value-end-line [pair]
  (or (and pair.value-node pair.value-node.close pair.value-node.close.line)
      pair.line))

(defn- alignment-shift-extra [pair end-line]
  (if (> end-line pair.line) 3 0))

(defn- alignment-shift-delta [pair delta end-line]
  (+ delta (alignment-shift-extra pair end-line)))

(defn- alignment-shift [pair delta]
  (let [end-line (value-end-line pair)]
    {:start (+ pair.line 1)
     :end   end-line
     :delta (alignment-shift-delta pair delta end-line)}))

(defn- append-alignment-shift [shifts pair delta]
  (if (> delta 0)
      (table.insert shifts (alignment-shift pair delta))))

(defn- append-alignment-edit [edits shifts plan pair]
  (let [name-width      (pair-name-width pair)
        name-end-column (+ pair.name.out-col name-width)
        target          (pair-target pair plan.width)
        delta           (- target pair.value.out-col)]
    (table.insert edits {:line pair.line :start (+ name-end-column 1) :finish (+ pair.value.out-col 1)
                         :spaces (- target name-end-column)})
    (append-alignment-shift shifts pair delta)))

(defn- append-alignment-edits [edits shifts plan]
  (each [_ pair (ipairs plan.pairs)]
    (append-alignment-edit edits shifts plan pair))
  (values edits shifts))

(defn- append-plan-edits [edits shifts plan]
  (if plan
      (append-alignment-edits edits shifts plan)
      (values edits shifts)))

(defn- alignment-state-step [state plan]
  (let [(edits shifts) (append-plan-edits state.edits state.shifts plan)]
    {:edits edits :shifts shifts}))

(defn- alignment-edits-state [plans]
  (accumulate [state {:edits [] :shifts []} _ plan (ipairs plans)]
    (alignment-state-step state plan)))

(defn- alignment-edits [plans]
  (let [state (alignment-edits-state plans)]
    (values state.edits state.shifts)))

(defn- apply-edit [line edit]
  (.. (string.sub line 1 (- edit.start 1))
      (string.rep " " edit.spaces)
      (string.sub line edit.finish)))

(defn- line-edit [line-number edit]
  (if (= edit.line line-number) edit))

(defn- line-edits [edits line-number]
  (icollect [_ edit (ipairs edits)]
    (line-edit line-number edit)))

(defn- apply-edits [line edits]
  (table.sort edits (fn [left right] (> left.start right.start)))
  (accumulate [result line _ edit (ipairs edits)]
    (apply-edit result edit)))

(defn- line-shift-step [result shift line-number]
  (if (and (>= line-number shift.start) (<= line-number shift.end))
      (+ result shift.delta)
      result))

(defn- line-shift [shifts line-number]
  (accumulate [result 0 _ shift (ipairs shifts)]
    (line-shift-step result shift line-number)))

(defn- positive-shift-line [line delta]
  (.. (string.rep " " delta) line))

(defn- negative-shift-line [line delta]
  (let [spaces (leading-spaces line)]
    (string.sub line (+ (math.min spaces (- delta)) 1))))

(defn- shift-nonzero-line [line delta]
  (if (> delta 0)
      (positive-shift-line line delta)
      (negative-shift-line line delta)))

(defn- shift-line [line delta]
  (if (= delta 0)
      line
      (shift-nonzero-line line delta)))

(defn- normalize-leading [line source-line]
  (.. (string.rep " " (leading-spaces source-line))
      (string.sub line (+ (leading-spaces line) 1))))

(defn- apply-alignment [lines source-lines plans]
  (let [(edits shifts) (alignment-edits plans)]
    (icollect [line-number line (ipairs lines)]
      (shift-line (normalize-leading (apply-edits line (line-edits edits line-number))
                                     (. source-lines line-number))
                  (line-shift shifts line-number)))))

(defn- process-line [line-number line nodes tokens config]
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
                              (> (leading-spaces line) 20))))
                (process-unchanged-line line-number line tokens)
                (let [indent (indent-for node first-token line-number config)
                      spaces (leading-spaces line)
                      body   (string.sub line (+ spaces 1))]
                  (assign-output-columns tokens line-number line indent true)
                  (.. (string.rep " " indent) body)))))))

(defn- aligned-output [output lines tree config]
  (if (and config (. config :align-bindings))
      (apply-alignment output lines (alignment-plans (collect-alignment-nodes tree nil [])))
      output))

(defn reindent [source config]
  (let [config-error (rules.validate config)]
    (if config-error
        (values nil config-error)
        (let [(tree error) (reader.parse source)]
          (if error
              (values nil error)
              (let [(lines final-newline) (split-lines source)
                    nodes                 []
                    tokens                []]
                (collect-node tree nodes tokens 0)
                (let [output []]
                  (var line-number 1)
                  (each [_ line (ipairs lines)]
                    (table.insert output (process-line line-number line nodes tokens config))
                    (set line-number (+ line-number 1)))
                  (let [aligned (aligned-output output lines tree config)]
                    (.. (table.concat aligned "\n") (if final-newline "\n" ""))))))))))
