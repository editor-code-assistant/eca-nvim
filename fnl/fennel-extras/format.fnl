(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)
(module fennel-extras.format)
(local indent (require :fennel-extras.indent))

(defn- split-lines [source]
  (let [lines []]
    (var start 1)
    (var at (string.find source "\n" start true))
    (while at
      (table.insert lines (string.sub source start (- at 1)))
      (set start (+ at 1))
      (set at (string.find source "\n" start true)))
    (table.insert lines (string.sub source start))
    lines))

(defn- leading-spaces [line]
  (string.len (string.match line "^ *")))

(defn- spaces-only? [line]
  (= line (string.rep " " (string.len line))))

(defn- indentation-lines-equal? [left right]
  (var same true)
  (each [i line (ipairs left)]
    (let [other (. right i)
          body (string.sub line (+ (leading-spaces line) 1))
          spaces (string.sub other 1 (leading-spaces other))]
      (if (not (or (= line other) (= other (.. spaces body))
                   (and (= other "") (spaces-only? line))))
          (set same false))))
  same)
(defn indent-only? [before after]
  (let [left (split-lines before) right (split-lines after)]
    (if (not= (length left) (length right)) false
        (indentation-lines-equal? left right))))

(defn- ignored? [key]
  (or (= key :filename) (= key :line) (= key :col) (= key :bytestart)
      (= key :byteend) (= key :endline) (= key :endcol) (= key :closer)
      (= key "filename") (= key "line") (= key "col") (= key "bytestart")
      (= key "byteend") (= key "endline") (= key "endcol") (= key "closer")))

(defn- symbol? [value]
  (let [meta (and (= (type value) :table) (getmetatable value))]
    (and meta (= (tostring (. meta 1)) "SYMBOL"))))

(defn- equal-key? [a b]
  (if (and (symbol? a) (symbol? b))
      (= (tostring a) (tostring b))
      (= a b)))

(defn- entries [value]
  (let [result []]
    (each [key item (pairs value)]
      (if (not (ignored? key))
          (table.insert result {:key key :value item})))
    result))

(defn- matching-entry [equal parser entry right]
  (var found-index nil)
  (each [index candidate (ipairs right)]
    (if (and (= found-index nil)
             (equal-key? (. entry :key) (. candidate :key))
             (equal parser (. entry :value) (. candidate :value)))
        (set found-index index)))
  found-index)

(defn- remove-and-continue [continue equal parser left right found-index]
  (table.remove right found-index)
  (continue equal parser left right))

(defn- continue-equal-entries [continue equal parser left right found-index]
  (if found-index
      (remove-and-continue continue equal parser left right found-index)
      false))

(defn- equal-entries? [equal parser left right]
  (if (= (length left) 0)
      true
      (let [entry (table.remove left 1)
            found-index (matching-entry equal parser entry right)]
        (continue-equal-entries equal-entries? equal parser left right found-index))))

(defn- equal-table? [equal parser a b]
  (let [left (entries a) right (entries b)]
    (and (= (length left) (length right))
         (equal-entries? equal parser left right))))

(defn- equal-value [parser a b]
  (if (not= (type a) (type b))
      false
      (if (= (type a) :table)
          (if (or (symbol? a) (parser.comment? a))
              (= (tostring a) (tostring b))
              (equal-table? equal-value parser a b))
          (= a b))))

(defn- parse-all [parser source]
  (let [iterator (parser.parser source "fennel-extras" {:comments true}) forms []]
    (var done false)
    (while (not done)
      (let [(ok form) (iterator)]
        (if ok (table.insert forms form) (set done true))))
    forms))

(defn- forms-equal? [parser left right]
  (var same true)
  (each [i form (ipairs left)]
    (if (not (equal-value parser form (. right i)))
        (set same false)))
  same)
(defn ast-equal? [parser a b]
  (let [(ok result) (pcall (fn []
                             (let [left (parse-all parser a) right (parse-all parser b)]
                               (if (not= (length left) (length right)) false
                                   (forms-equal? parser left right)))))]
    (and ok result)))

(defn format-string [source opts]
  (let [config (or (. opts :config) {}) parser (. opts :parser)
        (out error) (indent.reindent source config)]
    (if error (values nil error)
        (if (not (indent-only? source out))
            (values nil {:message "formatter changed more than indentation"})
            (if (and parser (not (ast-equal? parser source out)))
                (values nil {:message "formatter changed the parsed form"})
                out)))))

nil
