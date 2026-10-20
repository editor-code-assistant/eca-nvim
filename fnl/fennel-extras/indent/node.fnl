(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.indent.node)

(defn codepoint-width
  [text]
  (select 2 (string.gsub text "[^\128-\191]" "")))

(defn- leading-spaces-step
  [line index]
  (if (and (<= index (string.len line)) (= (string.sub line index index) " "))
    (leading-spaces-step line (+ index 1))
    (- index 1)))

(defn leading-spaces
  [line]
  (leading-spaces-step line 1))

(defn- nontrivia-child?
  [child]
  (not (and child.text
            (or (= child.kind :comment)
                (= child.kind :whitespace)
                (= child.kind :newline)))) )

(defn- insert-nontrivia-child
  [children child]
  (table.insert children child)
  children)

(defn- append-nontrivia-child
  [children child]
  (if (nontrivia-child? child)
    (insert-nontrivia-child children child)
    children))

(defn nontrivia-children
  [node]
  (accumulate [children [] _ child (ipairs node.children)]
    (append-nontrivia-child children child)))

(defn child-start
  [child]
  (
   if
    child.text
    child
    child.open))

(defn child-end
  [child]
  (if child.text
    child
    child.close))
