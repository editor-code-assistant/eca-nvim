(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.reader)

(defn- token [kind text line col]
  {:kind kind :text text :line line :col col})

(defn- fail [message line col]
  (values nil {:message message :line line :col col}))

(defn- classify [c]
  (case c
    "\"" :string
    ";" :comment
    " " :whitespace
    "\n" :newline
    "(" :open
    ")" :close
    "[" :open
    "]" :close
    "{" :open
    "}" :close
    "`" :prefix
    "'" :prefix
    "," :prefix
    "#" :prefix
    "\t" :tab
    "\r" :cr
    "@" :at
    _ :atom))

(defn- close-string [j]
  (values true (+ j 1)))
(defn- scan-string [source i]
  (let [n (string.len source)]
    (var j (+ i 1))
    (var closed false)
    (var error nil)
    (while (and (<= j n) (not closed) (not error))
      (let [c (string.sub source j j)]
        (if (= c "\\")
            (if (= j n)
                (set error {:message "unterminated string" :line nil :col nil})
                (if (= (string.sub source (+ j 1) (+ j 1)) "\r")
                    (set error {:message "carriage return is not allowed" :offset (+ j 1)})
                    (set j (+ j 2))))
            (if (= c "\"")
                (let [(new-closed new-j) (close-string j)]
                  (set closed new-closed)
                  (set j new-j))
                (if (= c "\r")
                    (set error {:message "carriage return is not allowed" :offset j})
                    (set j (+ j 1)))))))
    (if error
        (values nil error)
        (if closed
            (- j 1)
            (values nil {:message "unterminated string" :offset i})))))

(defn- scan-comment [source i]
  (let [n (string.len source)]
    (var j i)
    (while (and (<= j n) (not (= (string.sub source j j) "\n")))
      (set j (+ j 1)))
    (- j 1)))

(defn- scan-whitespace [source i]
  (let [n (string.len source)]
    (var j i)
    (while (and (<= j n) (= (string.sub source j j) " "))
      (set j (+ j 1)))
    (- j 1)))

(defn- scan-atom [source i]
  (let [n (string.len source)]
    (var j i)
    (while (and (<= j n) (= (classify (string.sub source j j)) :atom))
      (set j (+ j 1)))
    (- j 1)))

(defn- number? [text]
  (or (string.match text "^[0-9][0-9_]*$")
      (string.match text "^%-[0-9][0-9_]*$")
      (string.match text "^[0-9][0-9_]*%.[0-9][0-9_]*$")
      (string.match text "^%-[0-9][0-9_]*%.[0-9][0-9_]*$")
      (string.match text "^[0-9][0-9_]*%.[0-9][0-9_]*[eE][0-9][0-9_]*$")
      (string.match text "^%-[0-9][0-9_]*%.[0-9][0-9_]*[eE][0-9][0-9_]*$")
      (string.match text "^[0-9][0-9_]*%.[0-9][0-9_]*[eE][+-][0-9][0-9_]*$")
      (string.match text "^%-[0-9][0-9_]*%.[0-9][0-9_]*[eE][+-][0-9][0-9_]*$")
      (string.match text "^0[xX][0-9A-Fa-f][0-9A-Fa-f_]*$")
      (string.match text "^%-0[xX][0-9A-Fa-f][0-9A-Fa-f_]*$")
      (string.match text "^[0-9][0-9_]*[eE][0-9][0-9_]*$")
      (string.match text "^%-[0-9][0-9_]*[eE][0-9][0-9_]*$")
      (string.match text "^[0-9][0-9_]*[eE][+-][0-9][0-9_]*$")
      (string.match text "^%-[0-9][0-9_]*[eE][+-][0-9][0-9_]*$")))

(defn- advance-line [line col]
  (values (+ line 1) 1))
(defn- advance-position [text line col]
  (var j 1)
  (var current-line line)
  (var current-col col)
  (let [n (string.len text)]
    (while (<= j n)
      (if (= (string.sub text j j) "\n")
          (let [(new-line new-col) (advance-line current-line current-col)]
            (set current-line new-line)
            (set current-col new-col))
          (set current-col (+ current-col 1)))
      (set j (+ j 1))))
  (values current-line current-col))

(defn- next-token [source i line col]
  (let [shebang? (and (= i 1) (= (string.sub source 1 1) "#") (= (string.sub source 2 2) "!"))
        kind     (if shebang? :comment (classify (string.sub source i i)))]
    (case kind
      :string
      (let [(end result) (scan-string source i)]
        (if end
            (values (token :string (string.sub source i end) line col) (+ end 1))
            (values nil {:message result.message :line line :col col})))
      :comment
      (let [end (scan-comment source i)]
        (values (token :comment (string.sub source i end) line col) (+ end 1)))
      :whitespace
      (let [end (scan-whitespace source i)]
        (values (token :whitespace (string.sub source i end) line col) (+ end 1)))
      :atom
      (let [end  (scan-atom source i)
            text (string.sub source i end)]
        (values (token (if (number? text) :number :symbol) text line col) (+ end 1)))
      :open
      (values (token :open (string.sub source i i) line col) (+ i 1))
      :close
      (values (token :close (string.sub source i i) line col) (+ i 1))
      :newline
      (values (token :newline "\n" line col) (+ i 1))
      :tab
      (fail "tab is not allowed" line col)
      :cr
      (fail "carriage return is not allowed" line col)
      :at
      (fail "invalid at reader syntax" line col)
      :prefix
      (if (and (= (string.sub source i i) ",")
               (= (string.sub source (+ i 1) (+ i 1)) "@"))
          (fail "invalid comma-at reader syntax" line col)
          (values (token :prefix (string.sub source i i) line col) (+ i 1))))))

(defn- push-open-node [node stack tok]
  (let [child {:kind (case tok.text "(" :list "[" :sequence "{" :table) :open tok :children []}]
    (table.insert node.children child)
    (table.insert stack {:node child :open tok})))

(defn- advance-token [tokens tok line col]
  (table.insert tokens tok)
  (advance-position tok.text line col))

(defn- close-matching-node [stack tok]
  (let [top (. stack (length stack))]
    (set top.node.close tok)
    (table.remove stack)))
(defn tokenize [source]
  (let [tokens []
        n      (string.len source)]
    (var i 1)
    (var line 1)
    (var col 1)
    (var error nil)
    (while (and (<= i n) (not error))
      (let [old-i              i
            (tok end-or-error) (next-token source i line col)]
        (if tok
            (if (<= end-or-error old-i)
                (set error {:message "tokenizer made no progress" :line line :col col})
                (let [(new-line new-col) (advance-token tokens tok line col)]
                  (set line new-line)
                  (set col new-col)
                  (set i end-or-error)))
            (set error end-or-error))))
    (if error
        (values nil error)
        tokens)))

(defn- matching-close [open]
  (case open
    "(" ")"
    "[" "]"
    "{" "}"))

(defn- node-kind [open]
  (case open
    "(" :list
    "[" :sequence
    "{" :table))

(defn parse [source]
  (let [(tokens error) (tokenize source)]
    (if error
        (values nil error)
        (let [root  {:kind :root :children []}
              stack [{:node root :open nil}]]
          (var failure nil)
          (each [_ tok (ipairs tokens)]
            (if (not failure)
                (let [frame (. stack (length stack))
                      node  frame.node]
                  (if (= tok.kind :open)
                      (push-open-node node stack tok)
                      (if (= tok.kind :close)
                          (if (= (length stack) 1)
                              (set failure {:message "unexpected closing delimiter" :line tok.line :col tok.col})
                              (let [top (. stack (length stack))]
                                (if (= tok.text (matching-close top.open.text))
                                    (close-matching-node stack tok)
                                    (set failure {:message "mismatched closing delimiter" :line tok.line :col tok.col}))))
                          (table.insert node.children tok))))))
          (if failure
              (values nil failure)
              (if (> (length stack) 1)
                  (let [top (. stack (length stack))]
                    (fail "missing closing delimiter" top.open.line top.open.col))
                  root))))))

(defn- stringify-container [stringify node buffer]
  (table.insert buffer node.open.text)
  (each [_ child (ipairs node.children)]
    (stringify child buffer))
  (table.insert buffer node.close.text))

(defn- stringify [node buffer]
  (if (= node.kind :root)
      (each [_ child (ipairs node.children)]
        (stringify child buffer))
      (if node.text
          (table.insert buffer node.text)
          (stringify-container stringify node buffer))))

(defn to-string [node]
  (let [buffer []]
    (stringify node buffer)
    (table.concat buffer)))
