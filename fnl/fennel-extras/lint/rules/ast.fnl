(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.ast)

(local core (require :eca.nfnl.core))
(local reader (require :fennel-extras.reader))

(defn trivia?
  [node]
  (and (not= node.kind :list)
       (not= node.kind :sequence)
       (not= node.kind :table)
       (or (= node.kind :whitespace)
           (= node.kind :newline)
           (= node.kind :comment))))

(defn- collect-meaningful-child
  [result child]
  (when (not (trivia? child))
    (table.insert result child)))

(defn- collect-meaningful-children
  [children result]
  (each [_ child (ipairs children)]
    (collect-meaningful-child result child)))

(defn meaningful-children
  [node]
  (let [result []]
    (when (and node node.children)
      (collect-meaningful-children node.children result))
    result))

(defn symbol-text
  [node]
  (when (and node (= node.kind :symbol)) node.text))

(defn list-head
  [node]
  (let [children (meaningful-children node)]
    (symbol-text (. children 1))))

(defn literal-text
  [node]
  (and node
       (or (= node.kind :string) (= node.kind :symbol))
       (or (and (= node.kind :string)
                (string.sub node.text 2 (- (string.len node.text) 1)))
           (and (= (string.sub node.text 1 1) ":")
                (string.sub node.text 2))
           node.text)))

(defn spec-file?
  [path]
  (and (= (string.sub path 1 9) "fnl/spec/") true))

(defn- newline-value
  [text index]
  (if (= (string.sub text index index) "\n") 1 0))

(defn newline-count
  [text index count]
  (if (> index (string.len text))
    count
    (newline-count text
                   (+ index 1)
                   (+ count (newline-value text index)))))

(defn- string-token-on-line-value
  [token line]
  (when (and (= token.kind :string)
             (< token.line line)
             (<= line (+ token.line (newline-count token.text 1 0))))
    token))

(defn- string-token-on-line-step
  [tokens line index]
  (let [token (. tokens index)]
    (if (> index (length tokens))
      false
      (or (string-token-on-line-value token line)
          (string-token-on-line-step tokens line (+ index 1))))))

(defn- string-token-on-line?
  [tokens line]
  (string-token-on-line-step tokens line 1))

(defn- first-token-on-line-value
  [token line]
  (when (and (= token.line line)
             (not (or (= token.kind :whitespace) (= token.kind :newline))))
    token))

(defn- first-token-on-line-step
  [tokens line index]
  (let [token (. tokens index)]
    (if (> index (length tokens))
      nil
      (or (first-token-on-line-value token line)
          (first-token-on-line-step tokens line (+ index 1))))))

(defn- first-token-on-line
  [tokens line]
  (first-token-on-line-step tokens line 1))

(defn- code-line?
  [tokens line]
  (let [token (first-token-on-line tokens line)]
    (or (and token (not= token.kind :comment))
        (string-token-on-line? tokens line))))

(defn- code-line-value
  [tokens line]
  (if (code-line? tokens line) 1 0))

(defn code-line-count
  [tokens line total count]
  (if (> line total)
    count
    (code-line-count tokens
                     (+ line 1)
                     total
                     (+ count (code-line-value tokens line)))))

(defn- collect-macro-names-step
  [children index names recurse]
  (let [key   (symbol-text (. children index))
        value (symbol-text (. children (+ index 1)))]
    (if (and (= key ":") value)
      (recurse children (+ index 2) (core.assoc names value true))
      (recurse children (+ index 2) names))))

(defn- collect-macro-names
  [children index names]
  (if (> index (length children))
    names
    (collect-macro-names-step children index names collect-macro-names)))

(defn- macro-binding-children
  [bindings]
  (if (and bindings (= bindings.kind :table))
    (meaningful-children bindings)
    []))

(defn- macro-import-data
  [bindings target]
  (let [binding-children (macro-binding-children bindings)]
    {:target target
     :names  (collect-macro-names binding-children 1 {})}))

(defn macro-import?
  [node]
  (let [children (meaningful-children node)
        bindings (. children 2)
        target   (literal-text (. children 3))]
    (if (= (list-head node) "import-macros")
      (macro-import-data bindings target)
      nil)))

(defn has-all?
  [names]
  (and (. names "deftest") (. names "testing") (. names "is")))

(defn has-module-import?
  [names]
  (and (. names "module") (. names "def") (. names "defn") (. names "defn-")))

(defn previous-meaningful-child
  [children previous-index]
  (let [previous (. children previous-index)]
    (if (<= previous-index 0)
      nil
      (or (and (trivia? previous)
               (previous-meaningful-child children (- previous-index 1)))
          previous))))

(defn- previous-meaningful-index-step
  [children index recurse]
  (let [previous-index (- index 1)]
    (if (trivia? (. children previous-index))
      (recurse children previous-index recurse)
      previous-index)))

(defn previous-meaningful-index
  [children index]
  (if (<= index 1)
    nil
    (previous-meaningful-index-step children index previous-meaningful-index)))

(defn previous-meaningful
  [children index]
  (previous-meaningful-child children (- index 1)))

(defn- prefixed-child?
  [children index]
  (let [previous (previous-meaningful children index)]
    (and previous (= previous.kind :prefix))))

(defn- prefixed-root-child?
  [root index]
  (prefixed-child? root.children index))

(defn- collect-root-forms
  [root forms]
  (each [index child (ipairs root.children)]
    (and (or (= child.kind :list)
             (= child.kind :sequence)
             (= child.kind :table))
         (not (prefixed-root-child? root index))
         (table.insert forms child))))

(defn root-forms
  [source]
  (let [root  (reader.parse source)
        forms []]
    (when root
      (collect-root-forms root forms))
    forms))

(defn require-node?
  [node]
  (= (list-head node) "require"))

(defn do-branch?
  [node]
  (let [children (meaningful-children node)]
    (and (= (symbol-text (. children 1)) "do")
         (>= (length children) 3))))

(defn quoted-child?
  [children index]
  (let [previous (previous-meaningful children index)]
    (and previous
         (= previous.kind :prefix)
         (or (= previous.text "'") (= previous.text "`")))))

(defn- count-is-child
  [node child index count recurse]
  (or (and child
           (or (= child.kind :list) (= child.kind :sequence) (= child.kind :table))
           (not (quoted-child? node.children index))
           (or (and (= (list-head child) "testing")
                    (recurse node (+ index 1) count))
               (and (= (list-head child) "is")
                    (recurse node (+ index 1) (+ count 1)))
               (recurse node (+ index 1) (+ count (recurse child 1 0)))))
      (recurse node (+ index 1) count)))

(defn count-is
  [node index count]
  (let [child (. node.children index)]
    (if (> index (length node.children))
      count
      (count-is-child node child index count count-is))))
(defn append-nodes
  [target nodes]
  (each [_ node (ipairs nodes)]
    (table.insert target node))
  target)
(defn- skip-first-form-step
  [index value]
  (when (> index 1) value))

(defn- forms-without-first
  [forms]
  (icollect [index value (ipairs forms)]
    (skip-first-form-step index value)))

(defn- form-for-node-step
  [forms node fallback recurse]
  (let [form (. forms 1)]
    (if (or (= form.node node)
            (and node.open (= form.line node.open.line) (= form.col node.open.col)))
      form
      (recurse (forms-without-first forms) node fallback))))

(defn form-for-node
  [forms node fallback]
  (if (> (length forms) 0)
    (form-for-node-step forms node fallback form-for-node)
    fallback))
(defn- position-before-or-at?
  [line col other-line other-col]
  (or (< line other-line)
      (and (= line other-line) (<= col other-col))))

(defn- position-after-or-at?
  [line col other-line other-col]
  (or (> line other-line)
      (and (= line other-line) (>= col other-col))))

(defn- form-contains-node?
  [form node]
  (and (position-before-or-at? form.line form.col node.open.line node.open.col)
       (position-after-or-at? form.end-line form.end-col node.close.line (+ node.close.col 1))))

(defn- form-span-size
  [form]
  (+ (* (- form.end-line form.line) 1000000)
     (- form.end-col form.col)))

(defn- narrower-form
  [candidate current]
  (if (or (not current) (< (form-span-size candidate) (form-span-size current)))
    candidate
    current))

(defn- nearest-form-step
  [current form node]
  (if (form-contains-node? form node)
    (narrower-form form current)
    current))

(defn nearest-form
  [forms node]
  (accumulate [current nil _ form (ipairs forms)]
    (nearest-form-step current form node)))
