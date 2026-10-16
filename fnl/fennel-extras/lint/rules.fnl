(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules)

(local core (require :eca.nfnl.core))
(local reader (require :fennel-extras.reader))

(local defaults-map
       {:module-style "error"
        :spec-macro-import "error"
        :spec-no-module "error"
        :spec-direct-require "error"
        :one-is-per-testing "error"
        :if-branch-call "warning"
        :function-shape "warning"
        :core-require "error"})

(defn defaults []
  defaults-map)

(defn- trivia? [node]
  (and (not= node.kind :list)
       (not= node.kind :sequence)
       (not= node.kind :table)
       (or (= node.kind :whitespace)
           (= node.kind :newline)
           (= node.kind :comment))))

(defn- collect-meaningful-child [result child]
  (if (not (trivia? child))
      (table.insert result child)))

(defn- collect-meaningful-children [children result]
  (each [_ child (ipairs children)]
    (collect-meaningful-child result child)))

(defn- meaningful-children [node]
  (let [result []]
    (if (and node node.children)
        (collect-meaningful-children node.children result))
    result))

(defn- symbol-text [node]
  (if (and node (= node.kind :symbol)) node.text))

(defn- list-head [node]
  (let [children (meaningful-children node)]
    (symbol-text (. children 1))))

(defn- literal-text [node]
  (and node
       (or (= node.kind :string) (= node.kind :symbol))
       (or (and (= node.kind :string)
                (string.sub node.text 2 (- (string.len node.text) 1)))
           (and (= (string.sub node.text 1 1) ":")
                (string.sub node.text 2))
           node.text)))

(defn- spec-file? [path]
  (and (= (string.sub path 1 9) "fnl/spec/") true))

(defn- collect-macro-names [children index names]
  (if (> index (length children))
      names
      (let [key (symbol-text (. children index))
            value (symbol-text (. children (+ index 1)))]
        (if (and (= key ":") value)
            (collect-macro-names children (+ index 2) (core.assoc names value true))
            (collect-macro-names children (+ index 2) names)))))

(defn- macro-binding-children [bindings]
  (if (and bindings (= bindings.kind :table))
      (meaningful-children bindings)
      []))

(defn- macro-import-data [bindings target]
  (let [binding-children (macro-binding-children bindings)]
    {:target target
     :names (collect-macro-names binding-children 1 {})}))

(defn- macro-import? [node]
  (let [children (meaningful-children node)
        bindings (. children 2)
        target (literal-text (. children 3))]
    (if (= (list-head node) "import-macros")
        (macro-import-data bindings target)
        nil)))

(defn- has-all? [names]
  (and (. names "deftest") (. names "testing") (. names "is")))

(defn- has-module-import? [names]
  (and (. names "module") (. names "def") (. names "defn") (. names "defn-")))

(defn- previous-meaningful-child [children previous-index]
  (let [previous (. children previous-index)]
    (if (<= previous-index 0)
        nil
        (or (and (trivia? previous)
                 (previous-meaningful-child children (- previous-index 1)))
            previous))))

(defn- previous-meaningful [children index]
  (previous-meaningful-child children (- index 1)))

(defn- prefixed-child? [children index]
  (let [previous (previous-meaningful children index)]
    (and previous (= previous.kind :prefix))))

(defn- prefixed-root-child? [root index]
  (prefixed-child? root.children index))

(defn- collect-root-forms [root forms]
  (each [index child (ipairs root.children)]
    (and (or (= child.kind :list)
             (= child.kind :sequence)
             (= child.kind :table))
         (not (prefixed-root-child? root index))
         (table.insert forms child))))

(defn- root-forms [source]
  (let [root (reader.parse source)
        forms []]
    (if root
        (collect-root-forms root forms))
    forms))

(defn- require-node? [node]
  (= (list-head node) "require"))

(defn- do-branch? [node]
  (let [children (meaningful-children node)]
    (and (= (symbol-text (. children 1)) "do")
         (>= (length children) 3))))

(defn- quoted-child? [children index]
  (let [previous (previous-meaningful children index)]
    (and previous (= previous.kind :prefix)
         (or (= previous.text "'") (= previous.text "`")))))

(defn- count-is-child [node child index count recurse]
  (or (and child
           (or (= child.kind :list) (= child.kind :sequence) (= child.kind :table))
           (not (quoted-child? node.children index))
           (or (and (= (list-head child) "testing")
                    (recurse node (+ index 1) count))
               (and (= (list-head child) "is")
                    (recurse node (+ index 1) (+ count 1)))
               (recurse node (+ index 1) (+ count (recurse child 1 0)))))
      (recurse node (+ index 1) count)))

(defn- count-is [node index count]
  (let [child (. node.children index)]
    (if (> index (length node.children))
        count
        (count-is-child node child index count count-is))))

(defn- finding [path form severity rule message node]
  {:kind "finding"
   :path path
   :line form.line
   :col form.col
   :end-line form.end-line
   :end-col form.end-col
   :severity severity
   :rule rule
   :form form.form
   :message message
   :node node})

(defn- rule-severity [policy rule]
  (let [override (and policy (. policy rule))]
    (or override (. defaults-map rule))))

(defn- enabled? [policy rule]
  (not= (rule-severity policy rule) "off"))

(defn- module-finding [path forms policy module-ok]
  (if (and (not (spec-file? path)) (enabled? policy "module-style") (not module-ok))
      [{:kind "finding" :path path :line 1 :col 1 :end-line 1 :end-col 1
        :severity (rule-severity policy "module-style") :rule "module-style"
        :form (.. path " > file")
        :message "file must use the module style"
        :node nil}]
      []))

(defn- spec-import-finding [path forms policy valid]
  (if (and (spec-file? path) (not= path "fnl/spec/eca/macros.fnlm")
           (enabled? policy "spec-macro-import") (not valid))
      [{:kind "finding" :path path :line 1 :col 1 :end-line 1 :end-col 1
        :severity (rule-severity policy "spec-macro-import") :rule "spec-macro-import"
        :form (.. path " > spec")
        :message "specs must import deftest, testing, and is from spec.eca.macros"
        :node nil}]
      []))

(defn- direct-require? [path]
  (= path "fnl/spec/eca/macros.fnlm"))

(defn- core-finding-form [path form head children]
  (if (= head "local")
      {:line form.line
       :col form.col
       :end-line form.end-line
       :end-col form.end-col
       :form (.. path " > local:" (symbol-text (. children 2)))}
      form))

(defn- add-core-finding [findings path form head children node policy]
  (let [finding-form (core-finding-form path form head children)]
    (table.insert findings (finding path finding-form (rule-severity policy "core-require")
                                    "core-require"
                                    "bind eca.nfnl.core as core" node)))
  nil)

(defn- add-spec-direct-require-finding [findings path form policy node]
  (let [children (meaningful-children node)
        target (literal-text (. children 2))]
    (if (and (or (= target "plenary.busted") (= target "luassert"))
             (enabled? policy "spec-direct-require"))
        (table.insert findings (finding path form (rule-severity policy "spec-direct-require")
                                        "spec-direct-require"
                                        "specs must use the shared macro import" node)))))

(defn- add-testing-finding [findings path form policy node]
  (let [count (count-is node 1 0)]
    (if (and (not= count 1) (enabled? policy "one-is-per-testing"))
        (table.insert findings (finding path form (rule-severity policy "one-is-per-testing")
                                        "one-is-per-testing"
                                        "each testing form must contain exactly one is"
                                        node)))))

(defn- core-require-form [head children node]
  (or (and (= head "local") (. children 3)) node))

(defn- core-require-target [require-form require-children]
  (and (= (list-head require-form) "require")
       (literal-text (. require-children 2))))

(defn- canonical-core-require? [head children require-children]
  (or (and (= head "local")
           (= (length children) 3)
           (= (symbol-text (. children 2)) "core")
           (= (length require-children) 2))
      (and (= head "require") (= (length children) 2))))

(defn- maybe-add-core-require-finding [findings path form head children node policy target canonical]
  (if (and (= target "eca.nfnl.core") (not canonical))
      (add-core-finding findings path form head children node policy)))

(defn- core-require-children [require-form]
  (if require-form (meaningful-children require-form) []))

(defn- add-core-require-finding [findings path form head node policy]
  (let [children (meaningful-children node)
        require-form (core-require-form head children node)
        require-children (core-require-children require-form)
        target (core-require-target require-form require-children)
        canonical (canonical-core-require? head children require-children)]
    (maybe-add-core-require-finding findings path form head children node policy target canonical)))

(defn- function-head? [head]
  (or (= head "defn") (= head "defn-") (= head "fn")
      (= head "lambda") (= head "λ")))

(defn- layer-head? [head]
  (or (= head "if") (= head "when") (= head "case") (= head "match")
      (= head "each") (= head "for") (= head "icollect")
      (= head "collect") (= head "accumulate") (= head "while")
      (function-head? head)))

(defn- loop-head? [head]
  (or (= head "each") (= head "for") (= head "icollect")
      (= head "collect") (= head "accumulate") (= head "while")))

(defn- append-nodes [target nodes]
  (each [_ node (ipairs nodes)]
    (table.insert target node))
  target)

(defn- parameter-index [children head index]
  (if (> index (length children))
      nil
      (or (and (not= head "defn") (not= head "defn-")
               (= (. (. children index) :kind) :sequence)
               index)
          (parameter-index children head (+ index 1)))))

(defn- docstring-adjusted-index [children index]
  (if (and index (. children index)
           (= (. (. children index) :kind) :string))
      (+ index 1)
      index))

(defn- function-body-child [children body-start index child]
  (if (and body-start (>= index body-start)
           (not (quoted-child? children index)))
      child))

(defn- function-body [children body-start]
  (icollect [index child (ipairs children)]
    (function-body-child children body-start index child)))

(defn- function-parameter [children head]
  (if (or (= head "defn") (= head "defn-"))
      3
      (parameter-index children head 2)))

(defn- function-body-index [parameter]
  (and parameter (+ parameter 1)))

(defn- function-body-start [children parameter]
  (docstring-adjusted-index children (function-body-index parameter)))

(defn- function-info [node]
  (let [children (meaningful-children node)
        head (symbol-text (. children 1))
        parameter (function-parameter children head)
        body-start (function-body-start children parameter)
        body (function-body children body-start)]
    (and (function-head? head) parameter
         {:head head :children children :parameter parameter :body body})))

(defn- marker? [node text]
  (and node (= node.kind :symbol) (= node.text text)))

(defn- direct-layer? [children index]
  (and (not (quoted-child? children index))
       (or (loop-head? (list-head (. children index)))
           (function-head? (list-head (. children index))))))

(defn- direct-layer-value [children index]
  (if (direct-layer? children index) 1 0))

(defn- layer-value [layer?]
  (if layer? 1 0))

(defn- direct-layer-count [children index]
  (or (and (> index (length children)) 0)
      (+ (direct-layer-value children index)
         (direct-layer-count children (+ index 1)))))

(defn- leaf-valid-sequence-step [state children child index valid?]
  (and state
       (or (quoted-child? children index)
           (valid? child))))

(defn- leaf-valid-sequence? [node valid?]
  (let [children (meaningful-children node)]
    (accumulate [state true
                 index child (ipairs children)]
      (leaf-valid-sequence-step state children child index valid?))))

(defn- leaf-valid-binding-step [state children child index valid?]
  (and state
       (or (< index 2)
           (quoted-child? children index)
           (valid? child))))

(defn- leaf-valid-binding-list? [children valid?]
  (accumulate [state true
               index child (ipairs children)]
    (leaf-valid-binding-step state children child index valid?)))

(defn- leaf-valid-call-state-update [state child valid?]
  (let [child-head (list-head child)
        layer? (or (loop-head? child-head)
                   (function-head? child-head))]
    {:valid (or layer? (valid? child))
     :layers (+ state.layers (layer-value layer?))}))

(defn- leaf-valid-call-state-step [children state child index valid?]
  (if (and state.valid (>= index 2)
           (not (quoted-child? children index)))
      (leaf-valid-call-state-update state child valid?)
      state))

(defn- leaf-valid-call-state [children valid?]
  (accumulate [state {:valid true :layers 0}
               index child (ipairs children)]
    (leaf-valid-call-state-step children state child index valid?)))

(defn- leaf-valid-call? [children valid?]
  (let [result (leaf-valid-call-state children valid?)]
    (and result.valid (<= result.layers 1))))

(defn- leaf-valid-list? [children head valid?]
  (and (not (or (loop-head? head) (function-head? head)))
       (or (and (or (= head "var") (= head "set") (= head "local")
                    (= head "tset"))
                (leaf-valid-binding-list? children valid?))
           (and (not (or (= head "var") (= head "set") (= head "local")
                         (= head "tset")))
                (leaf-valid-call? children valid?)))))

(defn- leaf-node-kind [node]
  (or (and (or (not node) (= node.kind :prefix)
               (= node.kind :whitespace) (= node.kind :newline)
               (= node.kind :comment) (= node.kind :string)
               (= node.kind :symbol) (= node.kind :number)
               (= node.kind :boolean))
           "atomic")
      (and (= node.kind :sequence) "sequence")
      (and (= node.kind :table) "table")
      (and (= node.kind :list) "list")
      "other"))

(defn- leaf-valid-list-node? [node valid?]
  (let [children (meaningful-children node)
        head (symbol-text (. children 1))]
    (case head
      "do" (and (= (length children) 2)
                (or (quoted-child? children 2)
                    (valid? (. children 2))))
      "if" false
      "when" false
      "case" false
      "match" false
      "let" false
      _ (leaf-valid-list? children head valid?))))

(defn- leaf-valid? [node]
  (case (leaf-node-kind node)
    "atomic" true
    "sequence" (leaf-valid-sequence? node leaf-valid?)
    "table" (leaf-valid-sequence? node leaf-valid?)
    "list" (leaf-valid-list-node? node leaf-valid?)
    "other" true))

(defn- plain-call-one-layer? [node]
  (let [children (meaningful-children node)
        result (accumulate [state {:valid true :layers 0}
                            index child (ipairs children)]
                 (if (and state.valid (>= index 2)
                          (not (quoted-child? children index)))
                     (let [child-head (list-head child)
                           layer? (or (loop-head? child-head)
                                      (function-head? child-head))]
                       {:valid (or layer? (leaf-valid? child))
                        :layers (+ state.layers (if layer? 1 0))})
                     state))]
    (and result.valid (= result.layers 1))))

(defn- leaf-violations [node]
  (if (leaf-valid? node) [] [node]))

(defn- expression-violations [node]
  (let [head (list-head node)]
    (or (and (= head "do") [])
        (and (= head "let") [])
        (and (= node.kind :list)
             (or (loop-head? head) (function-head? head))
             [])
        (and (= node.kind :list) (plain-call-one-layer? node) [])
        (leaf-violations node))))

(defn- explicit-if? [children index]
  (if (> index (length children))
      false
      (or (marker? (. children index) "then")
          (marker? (. children index) "elseif")
          (marker? (. children index) "else")
          (explicit-if? children (+ index 1)))))

(defn- validate-if-explicit [children index result]
  (if (> index (length children))
      result
      (let [child (. children index)]
        (if (or (marker? child "then") (marker? child "elseif") (marker? child "else"))
            (if (. children (+ index 1))
                (validate-if-explicit children (+ index 2)
                                      (append-nodes result (expression-violations (. children (+ index 1)))))
                (validate-if-explicit children (+ index 1) result))
            (validate-if-explicit children (+ index 1)
                                  (append-nodes result (expression-violations child)))))))

(defn- implicit-branch-values [children index]
  (append-nodes
   (or (and (. children (+ index 1))
            (expression-violations (. children (+ index 1))))
       [])
   (expression-violations (. children index))))

(defn- append-implicit-branch [children index result]
  (append-nodes result (implicit-branch-values children index)))

(defn- validate-if-implicit [children index result]
  (if (> index (length children))
      result
      (or (and (= index (length children)) (= (% index 2) 0)
               (append-nodes result (expression-violations (. children index))))
          (validate-if-implicit children (+ index 2)
                                (append-implicit-branch children index result)))))

(defn- validate-if-children [children]
  (if (explicit-if? children 2)
      (validate-if-explicit children 2 [])
      (validate-if-implicit children 2 [])))

(defn- validate-if [node]
  (validate-if-children (meaningful-children node)))

(defn- validate-when-head [children result]
  (if (. children 2)
      (append-nodes result (expression-violations (. children 2)))
      result))

(defn- append-if-index [result index threshold value]
  (if (>= index threshold)
      (append-nodes result (expression-violations value))))

(defn- validate-when-body [children result]
  (each [index child (ipairs children)]
    (append-if-index result index 3 child))
  result)

(defn- validate-when [node]
  (let [children (meaningful-children node)]
    (validate-when-body children (validate-when-head children []))))

(defn- loop-bindings [children]
  (if (and (. children 2) (= (. (. children 2) :kind) :sequence))
      (meaningful-children (. children 2))
      []))

(defn- loop-start [bindings]
  (if (> (length bindings) 0) 3 2))

(defn- append-if-unquoted [bindings result index value]
  (if (not (quoted-child? bindings index))
      (append-nodes result (expression-violations value))))

(defn- validate-loop-bindings [bindings result]
  (each [index child (ipairs bindings)]
    (append-if-unquoted bindings result index child))
  result)

(defn- validate-loop-body [children start result]
  (each [index child (ipairs children)]
    (append-if-index result index start child))
  result)

(defn- validate-loop [node]
  (let [children (meaningful-children node)
        bindings (loop-bindings children)
        start (loop-start bindings)]
    (validate-loop-body children start
                        (validate-loop-bindings bindings []))))

(defn- validate-case [node]
  (let [result []]
    (each [index child (ipairs (meaningful-children node))]
      (append-if-index result index 2 child))
    result))

(defn- validate-layer-by-head [node head]
  (or (and (= head "if") (validate-if node))
      (and (= head "when") (validate-when node))
      (and (or (= head "case") (= head "match")) (validate-case node))
      (and (loop-head? head) (validate-loop node))
      []))

(defn- validate-layer [node]
  (validate-layer-by-head node (list-head node)))

(defn- body-expression-result [node head]
  (or (and (= head "let") [node])
      (and (= head "do")
           (or (and (not (leaf-valid? node)) [node]) []))
      (and (layer-head? head) (validate-layer node))
      (expression-violations node)))

(defn- body-expression-violations [node]
  (body-expression-result node (list-head node)))

(defn- validate-let-bindings [bindings result]
  (if (and bindings (= bindings.kind :sequence))
      (let [binding-children (meaningful-children bindings)]
        (each [index child (ipairs binding-children)]
          (if (and (= (% index 2) 0) (not (quoted-child? binding-children index)))
              (append-nodes result (expression-violations child))))))
  result)

(defn- validate-let-body [children result]
  (each [index child (ipairs children)]
    (and (>= index 3)
         (append-nodes result (body-expression-violations child))))
  result)

(defn- validate-let [node]
  (let [children (meaningful-children node)
        bindings (. children 2)]
    (validate-let-body children
                       (validate-let-bindings bindings []))))

(defn- function-first-let? [body]
  (and (. body 1) (= (list-head (. body 1)) "let")))

(defn- function-body-start-index [first-let?]
  (if first-let? 2 1))

(defn- function-body-initial [body result first-let?]
  (if first-let?
      (append-nodes result (validate-let (. body 1)))
      result))

(defn- validate-function-body [body result]
  (let [first-let? (function-first-let? body)
        start (function-body-start-index first-let?)
        initial (function-body-initial body result first-let?)]
    (each [index child (ipairs body)]
      (and (>= index start)
           (append-nodes initial (body-expression-violations child))))
    initial))

(defn- function-violations [node]
  (let [info (function-info node)
        body (or (and info info.body) [])]
    (validate-function-body body [])))

(defn- form-for-node [forms node fallback]
  (if (> (length forms) 0)
      (let [form (. forms 1)]
        (if (or (= form.node node)
                (and node.open (= form.line node.open.line) (= form.col node.open.col)))
            form
            (form-for-node (icollect [index value (ipairs forms)]
                             (if (> index 1) value)) node fallback)))
      fallback))

(defn- function-target [base offending]
  (if (and (= (list-head offending) "if")
           (or (string.match base.form " > then$")
               (string.match base.form " > else$")))
      (core.assoc base :form (.. base.form " > if#1"))
      base))

(defn- add-function-findings-for-node [findings path form forms policy node]
  (each [_ offending (ipairs (function-violations node))]
    (let [base (form-for-node forms offending form)
          target (function-target base offending)]
      (table.insert findings (finding path target (rule-severity policy "function-shape")
                                      "function-shape"
                                      "function body is too deep; move this into a named private function"
                                      offending)))))

(defn- add-function-findings [findings path form forms policy node]
  (if (enabled? policy "function-shape")
      (add-function-findings-for-node findings path form forms policy node)))

(defn- form-head [node]
  (if node (list-head node)))

(defn- evaluate-form [path form forms policy]
  (let [node form.node
        head (form-head node)
        findings []]
    (if (and (spec-file? path) (= head "module") (enabled? policy "spec-no-module"))
        (table.insert findings (finding path form (rule-severity policy "spec-no-module")
                                        "spec-no-module" "specs must not declare a module" node)))
    (if (and (spec-file? path) (not (direct-require? path)) (require-node? node))
        (add-spec-direct-require-finding findings path form policy node))
    (if (= head "testing")
        (add-testing-finding findings path form policy node))
    (if (and node (function-head? head))
        (add-function-findings findings path form forms policy node))
    (if (and (= head "do") (do-branch? node)
             (or (string.match form.form " > then$")
                 (string.match form.form " > else$")
                 (string.match form.form " > then#[0-9]+$"))
             (enabled? policy "if-branch-call"))
        (table.insert findings (finding path form (rule-severity policy "if-branch-call")
                                        "if-branch-call"
                                        "if branch contains multiple expressions; move them to a named helper"
                                        node)))
    (if (and (or (= head "local") (= head "require")) node
             (enabled? policy "core-require"))
        (add-core-require-finding findings path form head node policy))
    findings))

(defn- collect-function-children [node result walker]
  (each [index child (ipairs (or node.children []))]
    (and (or (= child.kind :list) (= child.kind :sequence) (= child.kind :table))
         (not (quoted-child? node.children index))
         (walker child result)))
  result)

(defn- collect-function-nodes [node result]
  (if (and node (= node.kind :list)
           (or (= (list-head node) "fn") (= (list-head node) "lambda") (= (list-head node) "λ")))
      (table.insert result node))
  (and node (collect-function-children node result collect-function-nodes))
  result)

(defn- synthetic-form [path node]
  {:line node.open.line :col node.open.col
   :end-line node.close.line :end-col (+ node.close.col 1)
   :form (.. path " > function-shape") :node node})

(defn- module-import-state [state import-info]
  (if (and import-info (= import-info.target "eca.nfnl.macros.aniseed"))
      (has-module-import? import-info.names)
      state.module-import))

(defn- spec-import-state [state import-info]
  (if (and import-info (= import-info.target "spec.eca.macros"))
      (has-all? import-info.names)
      state.spec-import))

(defn- update-check-state [state import-info head]
  {:module-import (module-import-state state import-info)
   :module-form (or state.module-form (= head "module"))
   :spec-import (spec-import-state state import-info)})

(defn- check-state [nodes index state]
  (let [node (. nodes index)
        import-info (macro-import? node)]
    (if (> index (length nodes))
        state
        (check-state nodes (+ index 1)
                     (update-check-state state import-info (list-head node))))))

(defn- append-evaluated-form [all path forms policy form]
  (each [_ f (ipairs (or (evaluate-form path form forms policy) []))]
    (table.insert all f)))

(defn- append-form-findings [all path forms policy spec-import]
  (each [_ f (ipairs (spec-import-finding path forms policy spec-import))]
    (table.insert all f))
  (each [_ form (ipairs forms)]
    (append-evaluated-form all path forms policy form))
  all)

(defn- function-nodes [source]
  (let [functions []]
    (each [_ root (ipairs (root-forms source))]
      (collect-function-nodes root functions))
    functions))

(defn- append-synthetic-node [all path forms policy node]
  (and (not (form-for-node forms node nil))
       (add-function-findings all path (synthetic-form path node) forms policy node)))

(defn- append-synthetic-nodes [all path forms policy source]
  (each [_ node (ipairs (function-nodes source))]
    (append-synthetic-node all path forms policy node))
  all)

(defn- append-synthetic-findings [all path forms policy source]
  (append-synthetic-nodes all path forms policy source))

(defn- check-result [path forms policy source state]
  (append-synthetic-findings
   (append-form-findings
    (module-finding path forms policy (and state.module-import state.module-form))
    path forms policy state.spec-import)
   path forms policy source))

(defn check [path forms policy source]
  (let [state (check-state (root-forms source) 1
                           {:module-import false :module-form false :spec-import false})]
    (check-result path forms policy source state)))
