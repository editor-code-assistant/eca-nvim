(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)
(module fennel-extras.format)
(local indent (require :fennel-extras.indent))
(local reader (require :fennel-extras.reader))
(local settings (require :fennel-extras.indent.settings))
(local rules (require :fennel-extras.rules))

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
                    (let [top (. stack (length stack))]
                      (when (and top (= top.head nil))
                            (set top.head token.text)))
                    (when (= token.kind :close)
                          (let [top (table.remove stack)]
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
                  (let [parent (or (. stack (length stack)) root)
                        form   {:start     token.line
                                :start-col token.col
                                :head      nil
                                :parent    parent
                                :children  []}]
                    (table.insert stack form)
                    (table.insert groups form))
                  (if (= token.kind :symbol)
                    (let [top (. stack (length stack))]
                      (when (and top (= top.head nil))
                            (set top.head token.text)))
                    (when (= token.kind :close)
                          (let [top (table.remove stack)]
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
                  (let [parent (. stack (length stack))]
                    (when (and parent parent.head)
                          (table.insert parent.children {:line token.line :col token.col}))
                    (table.insert stack {:start token.line :head nil :children []}))
                  (if (= token.kind :close)
                    (let [top (table.remove stack)]
                      (when (and top
                                 (= top.start span.start)
                                 (= top.head span.head))
                            (each [_ entry (ipairs entries)]
                                  (let [offset (if (or (= span.head "defn") (= span.head "defn-")) 1 0)
                                        child  (. top.children (+ (. entry 1) offset))]
                                    (when child
                                          (table.insert positions {:line  child.line
                                                                   :col   child.col
                                                                   :count (. entry 2)}))))))
                    (let [top-index (length stack)
                          top       (. stack top-index)]
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
                  (let [parent (. stack (length stack))]
                    (when (and parent parent.head)
                          (table.insert parent.children {:line token.line :col token.col}))
                    (table.insert stack {:start token.line :head nil :children []}))
                  (if (= token.kind :close)
                    (let [top (table.remove stack)]
                      (when (and top
                                 (= top.start span.start)
                                 (= top.head span.head))
                            (for [index 2 (length top.children)]
                                 (let [child (. top.children index)]
                                   (table.insert positions {:line   child.line
                                                            :col    child.col
                                                            :indent (- (. (. top.children 1) :col) 1)
                                                            :count  count})))))
                    (let [top-index (length stack)
                          top       (. stack top-index)]
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
          (let [line   (. lines position.line)
                prefix (string.sub line 1 (- position.col 1))
                suffix (.. (string.rep " " (or position.indent 0))
                           (string.sub line position.col))]
            (when (and line
                       (> (string.len (string.gsub prefix "%s+$" "")) 0)
                       (> (string.len suffix) 0))
                  (tset lines position.line (string.gsub prefix "%s+$" ""))
                  (for [offset 1 (- position.count 1)]
                       (table.insert lines (+ position.line offset) ""))
                  (table.insert lines (+ position.line position.count) suffix))))
    (table.concat lines "\n")))

(defn- apply-argument-break-rules
  [source config path matcher]
  (accumulate [result source _ rule (ipairs (newline-rules config))]
              (let [entries (. rule :options :break-after-n-args)]
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
              (let [count (. rule :options :break-after-args)]
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
        (let [existing (- right left 1)]
          (if (> existing count)
            (for [_ 1 (- existing count)]
                 (table.remove lines (+ left 1)))
            (for [_ 1 (- count existing)]
                 (table.insert lines (+ left 1) ""))))))

(defn- normalize-same-line-gap
  [lines left right count]
  (when (> count 0)
        (let [line   (. lines right.start)
              prefix (string.gsub (string.sub line 1 (- right.start-col 1)) "%s+$" "")
              suffix (string.sub line right.start-col)
              indent (string.rep " " (- left.start-col 1))]
          (tset lines right.start prefix)
          (for [offset 1 count]
               (table.insert lines (+ right.start offset) ""))
          (tset lines (+ right.start count 1) (.. indent suffix)))))

(defn- normalize-same-level-gaps
  [source config path matcher]
  (accumulate [result source _ rule (ipairs (newline-rules config))]
              (let [count (. rule :options :between-same-level)]
                (if (= count nil)
                  result
                  (let [lines (split-lines result)
                        pairs []]
                    (each [_ group (ipairs (same-level-form-groups result))]
                          (let [children group.children]
                            (for [index 1 (- (length children) 1)]
                                 (let [left  (. children index)
                                       right (. children (+ index 1))]
                                   (when (and (rule-selected? rule path matcher left.head)
                                              (rule-selected? rule path matcher right.head))
                                         (table.insert pairs {:left  left
                                                              :right right}))))))
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
          (let [before       (or (. rule :options :before) 0)
                after        (or (. rule :options :after) 0)
                after-header (or (. rule :options :after-header) 0)]
            (each [_ span (ipairs spans)]
                  (when (rule-selected? rule path matcher span.head)
                        (max-break breaks (preceding-break-index lines (- span.start 1)) before)
                        (when (< span.end (length lines))
                              (max-break breaks span.end after))
                        (let [header-line (form-header-line lines span)]
                          (when (and header-line (< header-line span.end))
                                (if (and (not= (. rule :options :after-header) nil)
                                         (= after-header 0))
                                  (for [offset 1 (blank-run-after lines header-line)]
                                       (tset removals (+ header-line offset) true))
                                  (max-break breaks header-line after-header))))))))
    (let [output []
          limit  (if (and (> (length lines) 1)
                          (= (. lines (length lines)) ""))
                   (+ 1 (preceding-break-index lines (- (length lines) 1)))
                   (preceding-break-index lines (length lines)))]
      (each [index line (ipairs lines)]
            (when (and (<= index limit)
                       (not (. removals index)))
                  (table.insert output line)
                  (let [count    (or (. breaks index) 0)
                        existing (blank-run-after lines index)
                        needed   (- count existing)]
                    (when (> needed 0)
                          (for [_ 1 needed]
                               (table.insert output ""))))))
      (table.concat output "\n"))))

(defn- spaces-only?
  [line]
  (= line (string.rep " " (string.len line))))

(defn- indentation-lines-equal?
  [left right]
  (var same true)
  (each [i line (ipairs left)]
        (let [other  (. right i)
              body   (string.sub line (+ (leading-spaces line) 1))
              spaces (string.sub other 1 (leading-spaces other))]
          (when (not (or (= line other)
                         (= other (.. spaces body))
                         (and (= other "") (spaces-only? line))))
                (set same false))))
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
                   (let [token (. left offset)
                         other (. right offset)]
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
      (let [entry       (table.remove left 1)
            found-index (matching-entry equal parser entry right)]
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
           (let [(ok form) (iterator)]
             (if ok
               (table.insert forms form)
               (set done true))))
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

                             (let [left  (parse-all parser a)
                                   right (parse-all parser b)]
                               (and (= (length left) (length right))
                                    (forms-equal? parser left right)))))]


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

(defn- format-string-valid
  [source parser config path matcher]
  (let [alignment     (settings.resolve config)
        broken-source (apply-argument-break-rules source config path matcher)
        (out error)   (indent.reindent broken-source config)]
    (if error
      (values nil error)
      (let [scalar-broken (apply-scalar-argument-break-rules out config path matcher)
            normalized    (normalize-same-level-gaps scalar-broken config path matcher)
            newlines      (apply-newline-rules normalized config path matcher)
            output        (normalize-same-level-gaps newlines config path matcher)]
        (validated-output source parser alignment output config)))))

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
