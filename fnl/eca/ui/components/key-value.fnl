;; key-value component — renders "key:value" pairs like "model:claude"
;; Stateless, pure function.

(fn render [{: title : value : hl-title : hl-value}]
  "Render a key:value pair.
   Returns {: line : highlights} where highlights is a list of
   {: hl-group : col-start : col-end}."
  (let [title-str (or title "")
        value-str (or value "")
        separator ":"
        line (.. title-str separator value-str)
        title-end (length title-str)
        value-start (+ title-end (length separator))
        value-end (+ value-start (length value-str))]
    {:line line
     :highlights [{:hl-group (or hl-title :EcaHeaderKey)
                   :col-start 0
                   :col-end title-end}
                  {:hl-group (or hl-value :EcaHeaderValue)
                   :col-start value-start
                   :col-end value-end}]}))

{: render}
