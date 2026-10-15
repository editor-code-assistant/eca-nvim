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

(defn- collect-meaningful-children [children result]
  (each [_ child (ipairs children)]
    (if (not (trivia? child))
        (table.insert result child))))

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
  (if (and node (or (= node.kind :string) (= node.kind :symbol)))
      (if (= node.kind :string)
          (string.sub node.text 2 (- (string.len node.text) 1))
          (if (= (string.sub node.text 1 1) ":")
              (string.sub node.text 2)
              node.text))))

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

(defn- macro-import-data [bindings target]
  (let [binding-children (if (and bindings (= bindings.kind :table))
                             (meaningful-children bindings)
                             [])]
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

(defn- previous-meaningful [children index]
  (let [previous-index (- index 1)
        previous (. children previous-index)]
    (if (<= previous-index 0)
        nil
        (if (trivia? previous)
            (previous-meaningful children previous-index)
            previous))))

(defn- prefixed-child? [children index]
  (let [previous (previous-meaningful children index)]
    (and previous (= previous.kind :prefix))))

(defn- prefixed-root-child? [root index]
  (prefixed-child? root.children index))

(defn- collect-root-forms [root forms]
  (each [index child (ipairs root.children)]
    (if (and (or (= child.kind :list)
                 (= child.kind :sequence)
                 (= child.kind :table))
             (not (prefixed-root-child? root index)))
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

(defn- count-is [node index count]
  (let [child (. node.children index)]
    (if (> index (length node.children))
        count
        (if (and child
                 (or (= child.kind :list) (= child.kind :sequence) (= child.kind :table))
                 (not (quoted-child? node.children index)))
            (if (= (list-head child) "testing")
                (count-is node (+ index 1) count)
                (if (= (list-head child) "is")
                    (count-is node (+ index 1) (+ count 1))
                    (count-is node (+ index 1) (+ count (count-is child 1 0)))))
            (count-is node (+ index 1) count)))))

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

(defn- add-core-finding [findings path form head children node policy]
  (let [finding-form (if (= head "local")
                         {:line form.line
                          :col form.col
                          :end-line form.end-line
                          :end-col form.end-col
                          :form (.. path " > local:" (symbol-text (. children 2)))}
                         form)]
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

(defn- add-core-require-finding [findings path form head node policy]
  (let [children (meaningful-children node)
        require-form (if (= head "local") (. children 3) node)
        require-children (if require-form (meaningful-children require-form) [])
        target (if (= (list-head require-form) "require")
                   (literal-text (. require-children 2)))
        canonical (if (= head "local")
                      (and (= (length children) 3)
                           (= (symbol-text (. children 2)) "core")
                           (= (length require-children) 2))
                      (= (length children) 2))]
    (if (and (= target "eca.nfnl.core") (not canonical))
        (add-core-finding findings path form head children node policy))))

(defn- evaluate-form [path form policy]
  (let [node form.node
        head (if node (list-head node))
        findings []]
    (if (and (spec-file? path) (= head "module") (enabled? policy "spec-no-module"))
        (table.insert findings (finding path form (rule-severity policy "spec-no-module")
                                        "spec-no-module" "specs must not declare a module" node)))
    (if (and (spec-file? path) (not (direct-require? path)) (require-node? node))
        (add-spec-direct-require-finding findings path form policy node))
    (if (= head "testing")
        (add-testing-finding findings path form policy node))
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

(defn- update-check-state [state import-info head]
  (let [module-import (if (and import-info (= import-info.target "eca.nfnl.macros.aniseed"))
                          (has-module-import? import-info.names)
                          state.module-import)
        module-form (or state.module-form (= head "module"))
        spec-import (if (and import-info (= import-info.target "spec.eca.macros"))
                        (has-all? import-info.names)
                        state.spec-import)]
    {:module-import module-import
     :module-form module-form
     :spec-import spec-import}))

(defn- check-state [nodes index state]
  (let [node (. nodes index)
        import-info (macro-import? node)]
    (if (> index (length nodes))
        state
        (check-state nodes (+ index 1)
                     (update-check-state state import-info (list-head node))))))

(defn check [path forms policy source]
  (let [state (check-state (root-forms source) 1
                           {:module-import false :module-form false :spec-import false})
        all (module-finding path forms policy (and state.module-import state.module-form))]
    (each [_ f (ipairs (spec-import-finding path forms policy state.spec-import))]
      (table.insert all f))
    (each [_ form (ipairs forms)]
      (each [_ f (ipairs (or (evaluate-form path form policy) []))]
        (table.insert all f)))
    all))
