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
    (table.sort result (fn [left right] (> left.start right.start)))


    result))



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

(defn- apply-newline-rules
  [source config]
  (let [lines  (split-lines source)
        spans  (form-spans source)
        breaks {}]
    (each [_ rule (ipairs (newline-rules config))]
      (let [forms  (. rule :applies-to :forms)
            before (or (. rule :options :before) 0)
            after  (or (. rule :options :after) 0)]
        (each [_ span (ipairs spans)]
          (when (form-selected? forms span.head)
            (max-break breaks (preceding-break-index lines (- span.start 1)) before)
            (when (< span.end (length lines))
              (max-break breaks span.end after))))))
    (let [output []
          limit  (if (and (> (length lines) 1)
                          (= (. lines (length lines)) ""))
                   (+ 1 (preceding-break-index lines (- (length lines) 1)))
                   (preceding-break-index lines (length lines)))]
      (each [index line (ipairs lines)]
        (when (<= index limit)
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
  (if (> index (length left))
    true
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
  (if found-index
    (remove-and-continue continue equal parser left right found-index)
    false))



(defn- equal-entries?
  [equal parser left right]
  (if (= (length left) 0)
    true
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
  (if (not= (type a) (type b))
    false
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
  (let [(ok result) (pcall (fn []
                             (let [left  (parse-all parser a)
                                   right (parse-all parser b)]
                               (if (not= (length left) (length right))
                                 false
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
  {:indents          (. config :indents)
   :format-as        (. config :format-as)
   :indent-patterns  (. config :indent-patterns)
   :indent-width     (. config :indent-width)
   :builtins         (or (. config :builtins) false)
   :prefix-fallbacks (or (. config :prefix-fallbacks) false)
   :alignment        (. config :alignment)})



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
  [source parser config]
  (let [alignment   (settings.resolve config)
        (out error) (indent.reindent source config)]
    (if error
      (values nil error)
      (let [output (apply-newline-rules out config)]
        (validated-output source parser alignment output config)))))



(defn format-string
  [source opts]
  (let [config           (or (. opts :config) {})
        parser           (. opts :parser)
        alignment-error  (settings.validate (. config :alignment))
        rule-config      (rules-config config)
        rules-error      (rules.validate rule-config)
        validation-error (format-string-error alignment-error rules-error)]
    (if validation-error
      (values nil validation-error)
      (format-string-valid source parser config))))



nil
