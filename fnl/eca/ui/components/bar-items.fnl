;; bar component — formats key-value items into a statusline/winbar string.
;; Stateless, pure function. Used by header-bar and footer-bar widgets.

(fn render [{: items : hl-key : hl-value}]
  "Render items into a statusline-format string.
   items: [{: title : value}] — title is optional
   hl-key: highlight group for titles (default EcaHeaderKey)
   hl-value: highlight group for values (default EcaHeaderValue)
   Layout: 1 item left, 2 items left+right, 3+ left+center+right.
   Returns string with %#HlGroup# formatting."
  (let [hk (or hl-key :EcaHeaderKey)
        hv (or hl-value :EcaHeaderValue)
        parts (icollect [_ item (ipairs (or items []))]
                (if item.title
                  (.. "%#" hk "#" item.title "%#" hv "#:" item.value)
                  (.. "%#" hv "#" item.value)))
        count (length parts)]
    (case count
      0 ""
      1 (.. " " (. parts 1))
      2 (.. " " (. parts 1) "%=" (. parts 2) " ")
      _ (let [left (. parts 1)
              right (. parts count)
              center-parts []
              _ (for [i 2 (- count 1)]
                  (table.insert center-parts (. parts i)))
              center (table.concat center-parts "  ")]
          (.. " " left "%=" center "%=" right " ")))))

{: render}
