;; message component — renders a text block with optional prefix.
;; Stateless, pure function.

(fn split-lines [text]
  "Split text into lines."
  (let [lines []]
    (if (or (= nil text) (= "" text))
      (table.insert lines "")
      (each [line (text:gmatch "([^\n]*)\n?")]
        (table.insert lines line)))
    lines))

(fn render [{: content : prefix : hl-group : collapsed? : collapse-prefix}]
  "Render a text block.
   content: text string (may contain newlines)
   prefix: optional string prepended to first line (e.g. '> ')
   hl-group: optional highlight group
   collapsed?: if true, render single line with collapse-prefix
   collapse-prefix: prefix for collapsed view (e.g. '▸ ')
   Returns {: lines : highlights}."
  (let [pfx (or prefix "")
        hl (or hl-group (when (and prefix (> (length prefix) 0)) :EcaMessagePrefix))
        content-lines (split-lines (or content ""))
        lines []
        highlights []]
    (if collapsed?
      ;; Collapsed: single line with collapse-prefix + first line of content
      (let [cpfx (or collapse-prefix "▸ ")
            first-content (or (. content-lines 1) "")
            line (.. cpfx first-content)]
        (table.insert lines line)
        (table.insert highlights
          {:line-idx 0 :hl-group (or hl :EcaExpandableLabel)
           :col-start 0 :col-end (length cpfx)})
        (table.insert lines ""))
      ;; Expanded: full content with prefix
      (do
        (each [i line (ipairs content-lines)]
          (let [full (if (= i 1) (.. pfx line) line)]
            (table.insert lines full)
            (when hl
              (table.insert highlights
                {:line-idx (- (length lines) 1)
                 :hl-group hl
                 :col-start 0
                 :col-end (length full)}))))
        (table.insert lines "")))
    {: lines : highlights}))

{: render}
