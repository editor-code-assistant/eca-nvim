(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.indent.comment)

(defn first-code-token-after
  [tokens line-number]
  (accumulate [result nil _ token (ipairs tokens)]
    (or result
        (and (> token.line line-number)
             (not (or (= token.kind :whitespace)
                      (= token.kind :newline)
                      (= token.kind :comment)))
             token))))

(defn- code-before-comment?
  [tokens line-number comment-token]
  (accumulate [before false _ prior (ipairs tokens)]
    (or before
        (and (= prior.line line-number)
             (< prior.col comment-token.col)
             (not (or (= prior.kind :whitespace)
                      (= prior.kind :newline)
                      (= prior.kind :comment)))))))

(defn- code-before-comment-on-line?
  [tokens line-number]
  (accumulate [found false _ token (ipairs tokens)]
    (or found
        (and (= token.kind :comment)
             (= token.line line-number)
             (code-before-comment? tokens line-number token)))))

(defn continuation-indent
  [indent tokens line-number]
  (if (code-before-comment-on-line? tokens (- line-number 1)) (+ indent 1)
    indent))
