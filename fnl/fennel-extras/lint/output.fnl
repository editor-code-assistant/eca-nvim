(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.output)

(local slash (string.char 92))
(local double-quote (string.char 34))
(local newline (string.char 10))
(local tab (string.char 9))
(local carriage-return (string.char 13))
(local replacement (.. (string.char 239) (string.char 191) (string.char 189)))

(defn- severity-rank
  [severity]
  (if (= severity "error")
    1
    2))

(defn- finding-less?
  [a b]
  (or (< a.path b.path)
      (and (= a.path b.path)
           (or (< a.line b.line)
               (and (= a.line b.line)
                    (or (< a.col b.col)
                        (and (= a.col b.col)
                             (or (< (severity-rank a.severity) (severity-rank b.severity))
                                 (and (= (severity-rank a.severity) (severity-rank b.severity))
                                      (or (< a.rule b.rule)
                                          (and (= a.rule b.rule)
                                               (or (< a.form b.form)
                                                   (and (= a.form b.form)
                                                        (< a.message b.message))))))))))))))

(defn- insert-finding
  [copied finding]
  (table.insert copied finding)
  copied)

(defn- copy-findings
  [findings index copied]
  (if (> index (length findings))
    copied
    (copy-findings findings (+ index 1) (insert-finding copied (. findings index)))))

(defn sort
  [findings]
  (let [copied (copy-findings findings 1 [])]
    (table.sort copied finding-less?)
    copied))

(defn- escape-control-carriage
  [character]
  (if (= character carriage-return)
    (.. slash "r")
    (string.format (.. slash "u00%02X") (string.byte character))))

(defn- escape-control-whitespace
  [character]
  (if (= character tab)
    (.. slash "t")
    (escape-control-carriage character)))

(defn- escape-control-newline
  [character]
  (if (= character newline)
    (.. slash "n")
    (escape-control-whitespace character)))

(defn- escape-control-tail
  [character]
  (if (= character slash)
    (.. slash slash)
    (escape-control-newline character)))

(defn- escape-control
  [character]
  (if (= character double-quote)
    (.. slash double-quote)
    (escape-control-tail character)))

(defn- valid-continuation?
  [byte]
  (and byte
       (>= byte 128)
       (<= byte 191)))

(defn- valid-two-byte?
  [first second]
  (and (>= first 194)
       (<= first 223)
       (valid-continuation? second)))

(defn- valid-three-byte?
  [first second third]
  (and (valid-continuation? second)
       (valid-continuation? third)
       (or (and (= first 224) (>= second 160) (<= second 191))
           (and (>= first 225) (<= first 236))
           (and (= first 237) (>= second 128) (<= second 159))
           (and (>= first 238) (<= first 239)))))

(defn- valid-four-byte?
  [first second third fourth]
  (and (valid-continuation? second)
       (valid-continuation? third)
       (valid-continuation? fourth)
       (or (and (= first 240) (>= second 144) (<= second 191))
           (and (>= first 241) (<= first 243))
           (and (= first 244) (>= second 128) (<= second 143)))))

(defn- append-replacement
  [chunks]
  (table.insert chunks replacement)
  chunks)

(defn- append-byte
  [chunks value index]
  (table.insert chunks (string.sub value index index))
  chunks)

(defn- append-sequence
  [chunks value index span]
  (table.insert chunks (string.sub value index (+ index span -1)))
  chunks)

(defn- normalize-utf8-step
  [value index chunks first second third fourth recurse]
  (or (and (< first 128)
           (recurse value (+ index 1) (append-byte chunks value index)))
      (and (valid-two-byte? first second)
           (recurse value (+ index 2) (append-sequence chunks value index 2)))
      (and (valid-three-byte? first second third)
           (recurse value (+ index 3) (append-sequence chunks value index 3)))
      (and (valid-four-byte? first second third fourth)
           (recurse value (+ index 4) (append-sequence chunks value index 4)))
      (recurse value (+ index 1) (append-replacement chunks))))

(defn- normalize-utf8-bytes
  [value index chunks recurse]
  (let [first  (string.byte value index)
        second (string.byte value (+ index 1))
        third  (string.byte value (+ index 2))
        fourth (string.byte value (+ index 3))]
    (normalize-utf8-step value index chunks first second third fourth recurse)))

(defn- normalize-utf8-at
  [value index chunks]
  (if (> index (length value))
    (table.concat chunks)
    (normalize-utf8-bytes value index chunks normalize-utf8-at)))

(defn- normalize-utf8
  [value]
  (normalize-utf8-at value 1 []))

(defn- json-string
  [value]
  (.. double-quote (string.gsub (normalize-utf8 value) "[%z\1-\31\\\"]" escape-control) double-quote))

(defn- exclusion-line
  [finding]
  (.. "  exclusion: {:rule " (json-string finding.rule) " :form " (json-string finding.form) " :reason \"explain why this is intentional\"}"))

(defn- text-rule
  [finding]
  (string.match finding.rule "^[^\\\"]+"))

(defn- text-line
  [finding]
  (.. finding.path ":" finding.line ":" finding.col ": " finding.severity " " (text-rule finding) ": " finding.message))

(defn- append-text
  [lines finding]
  (table.insert lines (text-line finding))
  (when (= finding.kind "finding")
    (table.insert lines (exclusion-line finding)))
  lines)

(defn- append-text-lines
  [diagnostics index lines]
  (if (> index (length diagnostics))
    lines
    (append-text-lines diagnostics (+ index 1) (append-text lines (. diagnostics index)))))

(defn text-lines
  [diagnostics]
  (append-text-lines diagnostics 1 []))

(defn- json-field
  [name value]
  (.. double-quote name double-quote ":" value))

(defn- json-string-field
  [name value]
  (json-field name (json-string value)))

(defn- finding-json
  [finding]
  (let [fields [(json-string-field "kind" finding.kind)
                (json-string-field "path" finding.path)
                (json-field "line" (tostring finding.line))
                (json-field "col" (tostring finding.col))
                (json-field "end-line" (tostring finding.end-line))
                (json-field "end-col" (tostring finding.end-col))
                (json-string-field "severity" finding.severity)
                (json-string-field "rule" finding.rule)
                (json-string-field "form" finding.form)
                (json-string-field "message" finding.message)]]
    (table.concat fields ",")))

(defn- stale-json
  [finding]
  (let [fields [(json-string-field "kind" finding.kind)
                (json-string-field "path" finding.path)
                (json-field "line" (tostring finding.line))
                (json-field "col" (tostring finding.col))
                (json-string-field "severity" finding.severity)
                (json-string-field "rule" finding.rule)
                (json-string-field "form" finding.form)
                (json-string-field "message" finding.message)]]
    (table.concat fields ",")))

(defn- diagnostic-json
  [finding]
  (if (= finding.kind "finding")
    (finding-json finding)
    (stale-json finding)))

(defn- append-json
  [lines finding]
  (table.insert lines (.. "{" (diagnostic-json finding) "}"))
  lines)

(defn- append-json-lines
  [diagnostics index lines]
  (if (> index (length diagnostics))
    lines
    (append-json-lines diagnostics (+ index 1) (append-json lines (. diagnostics index)))))

(defn json-lines
  [diagnostics]
  (append-json-lines diagnostics 1 []))
