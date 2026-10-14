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

(defn indent-only? [before after]
  (let [left (split-lines before) right (split-lines after)]
    (if (not= (length left) (length right)) false
        (do
          (var same true)
          (each [i line (ipairs left)]
            (let [other (. right i)
                  body (string.sub line (+ (leading-spaces line) 1))
                  spaces (string.sub other 1 (leading-spaces other))]
              (if (not (or (= line other) (= other (.. spaces body))
                           (and (= other "") (spaces-only? line))))
                  (set same false))))
          same))))

(defn- ignored? [key]
  (or (= key :filename) (= key :line) (= key :col) (= key :bytestart)
      (= key :byteend) (= key :endline) (= key :endcol) (= key :closer)
      (= key "filename") (= key "line") (= key "col") (= key "bytestart")
      (= key "byteend") (= key "endline") (= key "endcol") (= key "closer")))

(defn- equal-value [parser a b]
  (if (not= (type a) (type b))
      false
      (if (= (type a) :table)
          (if (or (parser.sym? a) (parser.comment? a))
              (= (tostring a) (tostring b))
              (do
                (var same true)
                (each [key value (pairs a)]
                  (if (not (ignored? key))
                      (if (not (equal-value parser value (. b key)))
                          (set same false))))
                same))
          (= a b))))

(defn- parse-all [parser source]
  (let [iterator (parser.parser source "fennel-extras" {:comments true}) forms []]
    (var done false)
    (while (not done)
      (let [(ok form) (iterator)]
        (if ok (table.insert forms form) (set done true))))
    forms))

(defn ast-equal? [parser a b]
  (let [(ok result) (pcall (fn []
                             (let [left (parse-all parser a) right (parse-all parser b)]
                               (if (not= (length left) (length right)) false
                                   (do
                                     (var same true)
                                     (each [i form (ipairs left)]
                                       (if (not (equal-value parser form (. right i)))
                                           (set same false)))
                                     same)))))]
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
