(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)
(module fennel-extras.format)
(local indent (require :fennel-extras.indent))
(local reader (require :fennel-extras.reader))
(local settings (require :fennel-extras.indent.settings))
(local rules (require :fennel-extras.rules))

(defn- capture-values
  [f]
  (let [(a b c) (f)] [a b c]))

(defn- split-lines
  [source]
  (let [lines []]
    (var start 1)
    (var at (string.find source "\n" start true))
    (while at (table.insert lines (string.sub source start (- at 1))) (set start (+ at 1)) (set at (string.find source "\n" start true)))
    (table.insert lines (string.sub source start))
    lines))

(defn- leading-spaces
  [line]
  (string.len (string.match line "^ *")))

(defn- newline-rules
  [config]
  (or (. config :newline) []))

(defn- form-selected?
  [forms head]
  (or (= forms nil)
      (accumulate [result false _ value (ipairs forms)]
                  (or result (= value head)))))

(defn- file-selected?
  [files path matcher]
  (or (= files nil)
      (and path
           matcher
           (accumulate [result false _ pattern (ipairs files)]
                       (or result (matcher pattern path))))))

(defn- rule-selected?
  [rule path matcher head]
  (and (file-selected? (. rule :applies-to :files) path matcher)
       (form-selected? (. rule :applies-to :forms) head)))

(defn- named-definition-header?
  [line head]
  (or (and (or (= head "defn") (= head "defn-"))
           (string.match line "^%s*%(defn%-?%s+[^%s%(]+")
           true)
      (and (= head "deftest")
           (string.match line "^%s*%(deftest%s+[^%s%(]+")
           true)))

(defn- form-header-line
  [lines span]
  (and (. lines span.start)
       (or (= span.head "fn")
           (named-definition-header? (. lines span.start) span.head))
       span.start))

(defn- form-spans
  [source]
  (let [(tokens error) (reader.tokenize source)
        stack          []
        result         []]
    (when (not error)
          (each [index token (ipairs tokens)]
                (if (= token.kind :open)
                  (table.insert stack {:start token.line :head nil})
                  (if (= token.kind :symbol)
                    (do (local top (. stack (length stack)))
                        (when (and top (= top.head nil))
                              (set top.head token.text)))
                    (when (= token.kind :close)
                          (do (local top (table.remove stack))
                              (when (and top top.head)
                                    (table.insert result {:head top.head :start top.start :end token.line}))))))))
    (table.sort result (fn
                         [left right]
                         (> left.start right.start)))


    result))

(defn- same-level-form-groups
  [source]
  (let [(tokens error) (reader.tokenize source)
        root           {:root true :children []}
        stack          []
        groups         [root]]
    (when (not error)
          (each [_ token (ipairs tokens)]
                (if (= token.kind :open)
                  (do (local parent (or (. stack (length stack)) root))
                      (local form {:start     token.line
                                   :start-col token.col
                                   :head      nil
                                   :parent    parent
                                   :children  []})
                      (table.insert stack form)
                      (table.insert groups form))
                  (if (= token.kind :symbol)
                    (do (local top (. stack (length stack)))
                        (when (and top (= top.head nil))
                              (set top.head token.text)))
                    (when (= token.kind :close)
                          (do (local top (table.remove stack))
                              (when (and top top.head)
                                    (set top.end token.line)
                                    (set top.end-col token.col)
                                    (table.insert top.parent.children top))))))))
    groups))

(defn- max-break
  [breaks index count]
  (when (> count (or (. breaks index) 0))
        (tset breaks index count)))

(defn- blank-run-after
  [lines index]
  (let [next-index (+ index 1)]
    (if (and (. lines next-index) (= (. lines next-index) ""))
      (+ 1 (blank-run-after lines next-index))
      0)))

(defn- preceding-break-index
  [lines index]
  (if (and (> index 0) (= (. lines index) ""))
    (preceding-break-index lines (- index 1))
    index))

(defn- break-after-n-args-positions
  [source span entries]
  (let [(tokens error) (reader.tokenize source)
        stack          []
        positions      []]
    (when (not error)
          (each [_ token (ipairs tokens)]
                (if (= token.kind :open)
                  (do (local parent (. stack (length stack)))
                      (when (and parent parent.head)
                            (table.insert parent.children {:line token.line :col token.col}))
                      (table.insert stack {:start token.line :head nil :children []}))
                  (if (= token.kind :close)
                    (do (local top (table.remove stack))
                        (when (and top
                                   (= top.start span.start)
                                   (= top.head span.head))
                              (each [_ entry (ipairs entries)]
                                    (local offset (if (or (= span.head "defn") (= span.head "defn-")) 1 0))
                                    (local child (. top.children (+ (. entry 1) offset)))
                                    (when child
                                          (table.insert positions {:line  child.line
                                                                   :col   child.col
                                                                   :count (. entry 2)})))))
                    (do (local top-index (length stack))
                        (local top (. stack top-index))
                        (when (and top (= token.kind :symbol))
                              (if (= top.head nil)
                                (do
                                 (table.remove stack top-index)
                                 (table.insert stack {:start    top.start
                                                      :head     token.text
                                                      :children top.children}))
                                (table.insert top.children {:line token.line :col token.col}))))))))
    positions))

(defn- break-after-args-positions
  [source span count]
  (let [(tokens error) (reader.tokenize source)
        stack          []
        positions      []]
    (when (not error)
          (each [_ token (ipairs tokens)]
                (if (= token.kind :open)
                  (do (local parent (. stack (length stack)))
                      (when (and parent parent.head)
                            (table.insert parent.children {:line token.line :col token.col}))
                      (table.insert stack {:start token.line :head nil :children []}))
                  (if (= token.kind :close)
                    (do (local top (table.remove stack))
                        (when (and top
                                   (= top.start span.start)
                                   (= top.head span.head))
                              (for [index 2 (length top.children)]
                                   (local child (. top.children index))
                                   (table.insert positions {:line   child.line
                                                            :col    child.col
                                                            :indent (- (. (. top.children 1) :col) 1)
                                                            :count  count}))))
                    (do (local top-index (length stack))
                        (local top (. stack top-index))
                        (when (and top
                                   (or (= token.kind :symbol)
                                       (= token.kind :string)
                                       (= token.kind :number)))
                              (if (= top.head nil)
                                (do
                                 (table.remove stack top-index)
                                 (table.insert stack {:start    top.start
                                                      :head     token.text
                                                      :children top.children}))
                                (table.insert top.children {:line token.line :col token.col}))))))))
    positions))

(defn- insert-breaks
  [source positions]
  (let [lines (split-lines source)]
    (table.sort positions
                (fn
                  [left right]
                  (if (= left.line right.line)
                    (> left.col right.col)
                    (> left.line right.line))))
    (each [_ position (ipairs positions)]
          (local line (. lines position.line))
          (local prefix (string.sub line 1 (- position.col 1)))
          (local suffix (.. (string.rep " " (or position.indent 0))
                            (string.sub line position.col)))
          (when (and line
                     (> (string.len (string.gsub prefix "%s+$" "")) 0)
                     (> (string.len suffix) 0))
                (tset lines position.line (string.gsub prefix "%s+$" ""))
                (for [offset 1 (- position.count 1)]
                     (table.insert lines (+ position.line offset) ""))
                (table.insert lines (+ position.line position.count) suffix)))
    (table.concat lines "\n")))

(defn- append-value
  [items value]
  (let [result []]
    (each [_ item (ipairs items)]
          (table.insert result item))
    (table.insert result value)
    result))

(defn- replace-last
  [items value]
  (let [result     []
        last-index (length items)]
    (each [index item (ipairs items)]
          (table.insert result (if (= index last-index) value item)))
    result))

(defn- remove-last
  [items]
  (let [result     []
        last-index (length items)]
    (each [index item (ipairs items)]
          (when (< index last-index)
                (table.insert result item)))
    result))

(defn- frame-with
  [frame key value]
  (let [result {}]
    (each [name item (pairs frame)]
          (tset result name item))
    (tset result key value)
    result))

(defn- grouped-child-state
  [state child open-col group-size group-gap indent-width]
  (let [since    (if child.barrier 0 (. state :since))
        count    (+ 1 (if (and (> since 0)
                               (= (math.fmod since group-size) 0))
                        group-gap
                     0))
        position {:line   child.line
                  :col    child.col
                  :indent (- (+ open-col indent-width) 1)
                  :count  count}]
    {:since     (+ since 1)
     :positions (append-value (. state :positions) position)}))

(defn- grouped-children
  [children open-col group-size group-gap indent-width since-barrier positions]
  (. (accumulate [state {:since since-barrier :positions positions}
                  _ child (ipairs children)]
                 (grouped-child-state state child open-col group-size group-gap indent-width))
     :positions))

(defn- grouped-open-state
  [state token]
  (let [stack      (. state :stack)
        top        (and (> (length stack) 0) (. stack (length stack)))
        child      (and top
                        top.head
                        (or top.prefix
                            {:line    token.line
                             :col     token.col
                             :barrier top.barrier}))
        next-top   (if child
                     (frame-with (frame-with (frame-with top
                                                         :children
                                                         (append-value top.children child))
                                             :prefix nil)
                                 :barrier false)
                     top)
        next-stack (if top (replace-last stack next-top) stack)]
    {:stack     (append-value next-stack {:start    token.line
                                          :open-col token.col
                                          :head     nil
                                          :children []
                                          :barrier  false
                                          :prefix   nil})
     :positions (. state :positions)}))

(defn- grouped-close-state
  [state token span group-size group-gap indent-width]
  (let [stack     (. state :stack)
        top       (and (> (length stack) 0) (. stack (length stack)))
        positions (if (and top
                           (= top.start span.start)
                           (= top.head span.head))
                    (grouped-children top.children
                                      top.open-col
                                      group-size
                                      group-gap
                                      indent-width
                                       0
                                      (. state :positions))
                    (. state :positions))]
    {:stack (remove-last stack) :positions positions}))

(defn- grouped-value-state
  [state token]
  (let [stack    (. state :stack)
        top      (and (> (length stack) 0) (. stack (length stack)))
        child    (or top.prefix
                     {:line    token.line
                      :col     token.col
                      :barrier top.barrier})
        next-top (if (= top.head nil)
                   (frame-with (frame-with top :head token.text) :prefix nil)
                   (frame-with (frame-with (frame-with top
                                                       :children
                                                       (append-value top.children child))
                                           :prefix nil)
                               :barrier false))]
    {:stack     (replace-last stack next-top)
     :positions (. state :positions)}))

(defn- grouped-prefix-state
  [state stack top token]
  (let [prefix      (or top.prefix
                        {:line token.line
                         :col  token.col
                         :text ""})
        next-prefix (frame-with prefix
                                :text
                                (.. prefix.text token.text))]
    {:stack     (replace-last stack (frame-with top :prefix next-prefix))
     :positions (. state :positions)}))

(defn- grouped-token-state
  [state token span group-size group-gap indent-width]
  (let [stack (. state :stack)
        top   (and (> (length stack) 0) (. stack (length stack)))]
    (case token.kind
      :open       (grouped-open-state state token)
      :close      (grouped-close-state state token span group-size group-gap indent-width)
      :comment    (if top
                    {:stack     (replace-last stack (frame-with top :barrier true))
                     :positions (. state :positions)}
                    state)
      :whitespace state
      :newline    state
      :prefix     (if top
                    (grouped-prefix-state state stack top token)
                    state)
      _           (if (or (not top)
                          (and top.prefix
                               (= top.prefix.text "#")
                               (= token.text "_")))
                    state
                    (grouped-value-state state token)))))

(defn- grouped-argument-positions
  [source span group-size group-gap indent-width]
  (let [(tokens error) (reader.tokenize source)]
    (if error
      []
      (. (accumulate [state {:stack [] :positions []}
                      _ token (ipairs tokens)]
                     (grouped-token-state state token span group-size group-gap indent-width))
         :positions))))

(defn- replace-line
  [lines index value]
  (let [result []]
    (each [line-number line (ipairs lines)]
          (table.insert result (if (= line-number index) value line)))
    result))

(defn- insert-after
  [lines index items]
  (let [result []]
    (each [line-number line (ipairs lines)]
          (table.insert result line)
          (when (= line-number index)
                (each [_ item (ipairs items)]
                      (table.insert result item))))
    result))

(defn- insert-before
  [lines index count]
  (let [result []]
    (each [line-number line (ipairs lines)]
          (when (= line-number index)
                (for [_ 1 count]
                     (table.insert result "")))
          (table.insert result line))
    (if (= index (+ (length lines) 1))
      (for [_ 1 count]
           (table.insert result ""))
      result)))

(defn- preceding-blank-count
  [lines index]
  (if (and (> index 0) (= (. lines index) ""))
    (+ 1 (preceding-blank-count lines (- index 1)))
    0))

(defn- group-break-lines
  [count continuation]
  (let [result []]
    (for [_ 1 (- count 1)]
         (table.insert result ""))
    (append-value result continuation)))

(defn- apply-group-position-with-prefix
  [lines position trimmed-prefix continuation]
  (insert-after (replace-line lines position.line trimmed-prefix)
                position.line
                (group-break-lines position.count continuation)))

(defn- apply-group-position-without-prefix
  [lines position continuation]
  (let [wanted (- position.count 1)
        blanks (preceding-blank-count lines (- position.line 1))]
    (insert-before (replace-line lines position.line continuation)
                   position.line
                   (if (> wanted blanks) (- wanted blanks) 0))))

(defn- apply-group-position
  [lines position indent-width]
  (let [line           (. lines position.line)
        prefix         (and line (string.sub line 1 (- position.col 1)))
        suffix         (and line (string.sub line position.col))
        trimmed-prefix (and prefix (string.gsub prefix "%s+$" ""))
        trimmed-suffix (and suffix (string.gsub suffix "^%s+" ""))
        continuation   (and trimmed-suffix
                            (.. (string.rep " " (or position.indent indent-width))
                                trimmed-suffix))]
    (case (not (and line suffix (> (string.len suffix) 0)))
      true  lines
      false (if (> (string.len trimmed-prefix) 0)
              (apply-group-position-with-prefix lines position trimmed-prefix continuation)
              (apply-group-position-without-prefix lines position continuation)))))

(defn- trim-trailing-empty-lines
  [lines]
  (if (and (> (length lines) 1)
           (= (. lines (length lines)) ""))
    (trim-trailing-empty-lines (remove-last lines))
    lines))

(defn- sorted-group-positions
  [positions]
  (let [result []]
    (each [_ position (ipairs positions)]
          (table.insert result position))
    (table.sort result
                (fn
                  [left right]
                  (if (= left.line right.line)
                    (> left.col right.col)
                    (> left.line right.line))))
    result))

(defn- grouped-lines
  [source positions indent-width]
  (accumulate [result (split-lines source)
               _ position (ipairs (sorted-group-positions positions))]
              (apply-group-position result position indent-width)))

(defn- insert-group-breaks
  [source positions indent-width]
  (let [lines  (grouped-lines source positions indent-width)
        output (table.concat (trim-trailing-empty-lines lines) "\n")]
    (if (= (string.sub source -1) "\n")
      (.. output "\n")
      output)))

(defn- apply-grouped-spans
  [source config path matcher rule]
  (let [group-size   (. rule :options :group-size)
        indent-width (or (. config :indent-width) 2)]
    (if group-size
      (accumulate [result source _ span (ipairs (form-spans source))]
                  (if (rule-selected? rule path matcher span.head)
                    (insert-group-breaks result
                                         (grouped-argument-positions result
                                                                     span
                                                                     group-size
                                                                     (or (. rule :options :group-gap) 0)
                                                                     indent-width)
                                         indent-width)
                    result))
      source)))

(defn- apply-grouped-argument-break-rules
  [source config path matcher]
  (accumulate [result source _ rule (ipairs (newline-rules config))]
              (apply-grouped-spans result config path matcher rule)))

(defn- apply-argument-break-rules
  [source config path matcher]
  (accumulate [result source _ rule (ipairs (newline-rules config))]
              (do (local entries (. rule :options :break-after-n-args))
                  (if entries
                    (accumulate [result result _ span (ipairs (form-spans result))]
                                (if (rule-selected? rule path matcher span.head)
                                  (insert-breaks result
                                                 (break-after-n-args-positions result span entries))
                                  result))
                    result))))

(defn- apply-scalar-argument-break-rules
  [source config path matcher]
  (accumulate [result source _ rule (ipairs (newline-rules config))]
              (do (local count (. rule :options :break-after-args))
                  (if count
                    (accumulate [result result _ span (ipairs (form-spans result))]
                                (if (rule-selected? rule path matcher span.head)
                                  (insert-breaks result
                                                 (break-after-args-positions result span count))
                                  result))
                    result))))

(defn- blank-lines-between?
  [lines start end]
  (or (>= start end)
      (and (= (. lines start) "")
           (blank-lines-between? lines (+ start 1) end))))

(defn- normalize-gap
  [lines left right count]
  (when (blank-lines-between? lines (+ left 1) right)
        (do (local existing (- right left 1))
            (if (> existing count)
              (for [_ 1 (- existing count)]
                   (table.remove lines (+ left 1)))
              (for [_ 1 (- count existing)]
                   (table.insert lines (+ left 1) ""))))))

(defn- normalize-same-line-gap
  [lines left right count]
  (when (> count 0)
        (do (local line (. lines right.start))
            (local prefix (string.gsub (string.sub line 1 (- right.start-col 1)) "%s+$" ""))
            (local suffix (string.sub line right.start-col))
            (local indent (string.rep " " (- left.start-col 1)))
            (tset lines right.start prefix)
            (for [offset 1 count]
                 (table.insert lines (+ right.start offset) ""))
            (tset lines (+ right.start count 1) (.. indent suffix)))))

(defn- normalize-same-level-gaps
  [source config path matcher]
  (accumulate [result source _ rule (ipairs (newline-rules config))]
              (do (local count (. rule :options :between-same-level))
                  (if (= count nil)
                    result
                    (do (local lines (split-lines result))
                        (local pairs [])
                        (each [_ group (ipairs (same-level-form-groups result))]
                              (local children group.children)
                              (for [index 1 (- (length children) 1)]
                                   (local left (. children index))
                                   (local right (. children (+ index 1)))
                                   (when (and (rule-selected? rule path matcher left.head)
                                              (rule-selected? rule path matcher right.head))
                                         (table.insert pairs {:left  left
                                                              :right right}))))
                        (table.sort pairs
                                    (fn
                                      [left right]
                                      (> left.left.end right.left.end)))
                        (each [_ pair (ipairs pairs)]
                              (if (= pair.left.end pair.right.start)
                                (normalize-same-line-gap lines pair.left pair.right count)
                                (normalize-gap lines pair.left.end pair.right.start count)))
                        (table.concat lines "\n"))))))

(defn- apply-newline-rules
  [source config path matcher]
  (let [lines    (split-lines source)
        spans    (form-spans source)
        breaks   {}
        removals {}]
    (each [_ rule (ipairs (newline-rules config))]
          (local before (or (. rule :options :before) 0))
          (local after (or (. rule :options :after) 0))
          (local after-header (or (. rule :options :after-header) 0))
          (each [_ span (ipairs spans)]
                (when (rule-selected? rule path matcher span.head)
                      (max-break breaks (preceding-break-index lines (- span.start 1)) before)
                      (when (< span.end (length lines))
                            (max-break breaks span.end after))
                      (do (local header-line (form-header-line lines span))
                          (when (and header-line (< header-line span.end))
                                (if (and (not= (. rule :options :after-header) nil)
                                         (= after-header 0))
                                  (for [offset 1 (blank-run-after lines header-line)]
                                       (tset removals (+ header-line offset) true))
                                  (max-break breaks header-line after-header)))))))
    (local output [])
    (local limit (if (and (> (length lines) 1)
                          (= (. lines (length lines)) ""))
                   (+ 1 (preceding-break-index lines (- (length lines) 1)))
                   (preceding-break-index lines (length lines))))
    (each [index line (ipairs lines)]
          (when (and (<= index limit)
                     (not (. removals index)))
                (table.insert output line)
                (do (local count (or (. breaks index) 0))
                    (local existing (blank-run-after lines index))
                    (local needed (- count existing))
                    (when (> needed 0)
                          (for [_ 1 needed]
                               (table.insert output ""))))))
    (table.concat output "\n")))

(defn- spaces-only?
  [line]
  (= line (string.rep " " (string.len line))))

(defn- indentation-lines-equal?
  [left right]
  (var same true)
  (each [i line (ipairs left)]
        (local other (. right i))
        (local body (string.sub line (+ (leading-spaces line) 1)))
        (local spaces (string.sub other 1 (leading-spaces other)))
        (when (not (or (= line other)
                       (= other (.. spaces body))
                       (and (= other "") (spaces-only? line))))
              (set same false)))
  same)

(defn- whitespace-kind?
  [kind]
  (or (= kind :whitespace) (= kind :newline)))

(defn- token-kind-equal?
  [left right]
  (or (= left.kind right.kind)
      (and (whitespace-kind? left.kind) (whitespace-kind? right.kind))))

(defn- non-whitespace-token-equal?
  [left right]
  (= left.text right.text))

(defn- newline-count
  [text]
  (let [count (select 2 (string.gsub text "\n" ""))]
    count))

(defn- whitespace-token-equal?
  [left right]
  (and (> (string.len left.text) 0)
       (> (string.len right.text) 0)
       (>= (newline-count right.text) (newline-count left.text))))

(defn- token-text-equal?
  [left right]
  (if (whitespace-kind? left.kind)
    (whitespace-token-equal? left right)
    (non-whitespace-token-equal? left right)))

(defn- token-sequences-equal?
  [left right index]
  (and (= (length left) (length right))
       (accumulate [result true offset (ipairs left)]
                   (do (local token (. left offset))
                       (local other (. right offset))
                       (and result
                            (token-kind-equal? token other)
                            (token-text-equal? token other))))))

(defn- binding-whitespace-equal?
  [left right]
  (let [left-body                  (string.gsub left "^ *" "")
        right-body                 (string.gsub right "^ *" "")
        (left-tokens left-error)   (reader.tokenize left-body)
        (right-tokens right-error) (reader.tokenize right-body)]
    (and (not left-error)
         (not right-error)
         (not= left-body right-body)
         (token-sequences-equal? left-tokens right-tokens 1))))

(defn- line-equal?
  [line other allow-binding-whitespace?]
  (or (= line other)
      (= other
         (.. (string.sub other 1 (leading-spaces other)) (string.sub line (+ (leading-spaces line) 1))))
      (and allow-binding-whitespace?
           (binding-whitespace-equal? line other))
      (and (= other "") (spaces-only? line))))

(defn- lines-equal?
  [left right index allow-binding-whitespace?]
  (or (> index (length left))
      (and (line-equal? (. left index) (. right index) allow-binding-whitespace?)
           (lines-equal? left right (+ index 1) allow-binding-whitespace?))))

(defn- replace-last-token
  [tokens token]
  (table.remove tokens)
  (table.insert tokens token))

(defn- merged-whitespace-token
  [previous token]
  {:kind :whitespace :text (.. previous.text token.text)})

(defn- merge-whitespace-token
  [tokens token]
  (let [previous (. tokens (length tokens))]
    (if (and previous
             (whitespace-kind? previous.kind)
             (whitespace-kind? token.kind))
      (replace-last-token tokens (merged-whitespace-token previous token))
      (table.insert tokens token))))

(defn- normalized-tokens
  [tokens]
  (let [result []]
    (each [_ token (ipairs tokens)]
          (merge-whitespace-token result token))
    result))

(defn- token-whitespace-only?
  [before after]
  (let [(left left-error)   (reader.tokenize before)
        (right right-error) (reader.tokenize after)
        left-normalized     (normalized-tokens left)
        right-normalized    (normalized-tokens right)]
    (and (not left-error)
         (not right-error)
         (= (length left-normalized) (length right-normalized))
         (token-sequences-equal? left-normalized right-normalized 1))))

(defn indent-only?
  [before after allow-binding-whitespace?]
  (let [left  (split-lines before)
        right (split-lines after)]
    (or (and (= (length left) (length right))
             (lines-equal? left right 1 allow-binding-whitespace?))
        (and allow-binding-whitespace?
             (token-whitespace-only? before after)))))

(defn- ignored?
  [key]
  (or (= key :filename)
      (= key :line)
      (= key :col)
      (= key :bytestart)
      (= key :byteend)
      (= key :endline)
      (= key :endcol)
      (= key :closer)
      (= key "filename")
      (= key "line")
      (= key "col")
      (= key "bytestart")
      (= key "byteend")
      (= key "endline")
      (= key "endcol")
      (= key "closer")))

(defn- symbol?
  [value]
  (let [meta (and (= (type value) :table) (getmetatable value))]
    (and meta
         (= (tostring (. meta 1)) "SYMBOL"))))

(defn- equal-key?
  [a b]
  (if (and (symbol? a) (symbol? b))
    (= (tostring a) (tostring b))
    (= a b)))

(defn- entries
  [value]
  (let [result []]
    (each [key item (pairs value)]
          (when (not (ignored? key))
                (table.insert result {:key key :value item})))
    result))

(defn- matching-entry
  [equal parser entry right]
  (var found-index nil)
  (each [index candidate (ipairs right)]
        (when (and (= found-index nil)
                   (equal-key? (. entry :key) (. candidate :key))
                   (equal parser (. entry :value) (. candidate :value)))
              (set found-index index)))
  found-index)

(defn- remove-and-continue
  [continue equal parser left right found-index]
  (table.remove right found-index)
  (continue equal parser left right))

(defn- continue-equal-entries
  [continue equal parser left right found-index]
  (and found-index
       (remove-and-continue continue equal parser left right found-index)))

(defn- equal-entries?
  [equal parser left right]
  (or (= (length left) 0)
      (do (local entry (table.remove left 1))
          (local found-index (matching-entry equal parser entry right))
          (continue-equal-entries equal-entries? equal parser left right found-index))))

(defn- equal-table?
  [equal parser a b]
  (let [left  (entries a)
        right (entries b)]
    (and (= (length left) (length right))
         (equal-entries? equal parser left right))))

(defn- equal-value
  [parser a b]
  (and (= (type a) (type b))
       (if (= (type a) :table)
         (if (or (symbol? a) (parser.comment? a))
           (= (tostring a) (tostring b))
           (equal-table? equal-value parser a b))
         (= a b))))

(defn- parse-all
  [parser source]
  (let [iterator (parser.parser source "fennel-extras" {:comments true})
        forms    []]
    (var done false)
    (while (not done)
           (local captured-values (capture-values (fn
                                                    []
                                                    (iterator))))
           (local ok (. captured-values 1))
           (local form (. captured-values 2))
           (if ok
             (table.insert forms form)
             (set done true)))
    forms))

(defn- forms-equal?
  [parser left right]
  (var same true)
  (each [i form (ipairs left)]
        (when (not (equal-value parser form (. right i)))
              (set same false)))
  same)

(defn ast-equal?
  [parser a b]
  (let [(ok result) (pcall (fn
                             []

                             (local left (parse-all parser a))
                             (local right (parse-all parser b))
                             (and (= (length left) (length right))
                                  (forms-equal? parser left right))))]


    (and ok
         result)))

(defn- alignment-enabled?
  [alignment]
  (or alignment.bindings
      alignment.maps
      alignment.clauses
      alignment.split-bindings
      alignment.collapse-padding))

(defn- rules-config
  [config]
  {:indents      (. config :indents)
   :format-as    (. config :format-as)
   :indent-width (. config :indent-width)
   :alignment    (. config :alignment)})

(defn- indentation-output-error
  [source alignment out config]
  (when (not (or (indent-only? source out (alignment-enabled? alignment))
                 (. config :newline)))
        {:message "formatter changed more than indentation"}))

(defn- parser-output-error
  [source parser out]
  (when (and parser (not (ast-equal? parser source out)))
        {:message "formatter changed the parsed form"}))

(defn- formatted-output-error
  [source parser alignment out config]
  (or (indentation-output-error source alignment out config)
      (parser-output-error source parser out)))

(defn- validated-output
  [source parser alignment out config]
  (let [output-error (formatted-output-error source parser alignment out config)]
    (if output-error
      (values nil output-error)
      out)))

(defn- format-string-error
  [alignment-error rules-error]
  (or alignment-error rules-error))

(defn- format-string-output
  [source parser alignment out config path matcher]
  (let [scalar-broken (apply-scalar-argument-break-rules out config path matcher)
        normalized    (normalize-same-level-gaps scalar-broken config path matcher)
        newlines      (apply-newline-rules normalized config path matcher)
        grouped       (apply-grouped-argument-break-rules newlines config path matcher)
        output        (normalize-same-level-gaps grouped config path matcher)]
    (validated-output source parser alignment output config)))

(defn- format-string-valid
  [source parser config path matcher]
  (let [alignment     (settings.resolve config)
        broken-source (apply-argument-break-rules source config path matcher)
        (out error)   (indent.reindent broken-source config)]
    (if error
      (values nil error)
      (format-string-output source parser alignment out config path matcher))))

(defn format-string
  [source opts]
  (let [config           (or (. opts :config) {})
        parser           (. opts :parser)
        path             (. opts :path)
        matcher          (. opts :matcher)
        alignment-error  (settings.validate (. config :alignment))
        rule-config      (rules-config config)
        rules-error      (rules.validate rule-config)
        validation-error (format-string-error alignment-error rules-error)]
    (if validation-error
      (values nil validation-error)
      (format-string-valid source parser config path matcher))))



nil
