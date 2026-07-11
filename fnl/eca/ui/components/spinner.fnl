;; spinner component — animated loading spinner.
;; Stateless, pure function (receives frame index).

(local frames ["⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"])

(fn render [{: frame}]
  "Render a spinner frame.
   frame is a 0-based index, wraps around automatically.
   Returns {: text : hl-group}."
  (let [idx (+ (% (or frame 0) (length frames)) 1)
        char (. frames idx)]
    {:text char
     :hl-group :EcaSpinner}))

(fn frame-count []
  "Returns the total number of spinner frames."
  (length frames))

{: render
 : frame-count}
