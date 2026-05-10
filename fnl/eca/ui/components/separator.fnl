;; separator component — renders a horizontal separator line.
;; Stateless, pure function.

(fn render [{: char : width}]
  "Render a separator line.
   char defaults to '─', width defaults to 40.
   Returns {: line : highlights}."
  (let [c (or char "─")
        w (or width 40)
        line (string.rep c w)]
    {:line line
     :highlights [{:hl-group :EcaSeparator
                   :col-start 0
                   :col-end (length line)}]}))

{: render}
