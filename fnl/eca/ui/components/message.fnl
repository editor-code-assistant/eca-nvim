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

(fn render [{: content : prefix : hl-group}]
  "Render a text block.
   content: text string (may contain newlines)
   prefix: optional string prepended to first line (e.g. '> ')
   hl-group: optional highlight group for the block
   Returns {: lines : highlights}."
  (let [pfx (or prefix "")
        ;; If prefix is set and no explicit hl-group, use EcaMessagePrefix
        hl (or hl-group (when (and prefix (> (length prefix) 0)) :EcaMessagePrefix))
        content-lines (split-lines (or content ""))
        lines []
        highlights []]
    (each [i line (ipairs content-lines)]
      (let [full (if (= i 1) (.. pfx line) line)]
        (table.insert lines full)
        (when hl
          (table.insert highlights
            {:line-idx (- (length lines) 1)
             :hl-group hl
             :col-start 0
             :col-end (length full)}))))
    (table.insert lines "")
    {: lines : highlights}))

{: render}
