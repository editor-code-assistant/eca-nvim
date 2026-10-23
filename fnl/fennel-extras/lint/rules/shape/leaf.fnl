(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.rules.shape.leaf)

(local valid (require :fennel-extras.lint.rules.shape.leaf.valid))
(local call (require :fennel-extras.lint.rules.shape.leaf.call))

(def function-head? valid.function-head?)
(def layer-head? valid.layer-head?)
(def loop-head? valid.loop-head?)
(def function-info valid.function-info)
(def leaf-valid? valid.leaf-valid?)
(def plain-call-one-layer? call.plain-call-one-layer?)
(def leaf-violations call.leaf-violations)
(def expression-violations call.expression-violations)
