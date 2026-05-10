;; usage component — renders token usage and cost display.
;; Stateless, pure function.

(fn format-tokens [n]
  "Format token count: 1500 → '1.5K', 150000 → '150K'."
  (if (= nil n) "0"
      (>= n 1000000) (string.format "%.1fM" (/ n 1000000))
      (>= n 1000) (string.format "%.0fK" (/ n 1000))
      (tostring n)))

(fn format-cost [cost]
  "Format cost as dollar amount."
  (if (= nil cost) nil
      (string.format "$%.2f" cost)))

(fn render [{: tokens-in : tokens-out : max-tokens : cost}]
  "Render usage display.
   Returns {: text : hl-group}.
   Format: '31K/200K ($0.03)' or '31K/200K' if no cost."
  (let [used (format-tokens (+ (or tokens-in 0) (or tokens-out 0)))
        max (format-tokens max-tokens)
        base (if max-tokens
               (.. used "/" max)
               used)
        cost-str (format-cost cost)
        text (if cost-str
               (.. base " (" cost-str ")")
               base)]
    {:text text
     :hl-group :EcaUsage}))

{: render
 : format-tokens
 : format-cost}
