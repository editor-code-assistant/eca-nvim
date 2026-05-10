;; context-item component — renders @context mentions.
;; Stateless, pure function.

(local type-config
  {:file      {:prefix "@"  :hl-group :EcaContextFile}
   :dir       {:prefix "@"  :hl-group :EcaContextDir}
   :repo-map  {:prefix "@"  :hl-group :EcaContextRepoMap :label "repoMap"}
   :cursor    {:prefix "@"  :hl-group :EcaContextCursor}
   :mcp       {:prefix "@"  :hl-group :EcaContextMcp}})

(fn render [{: type : name : detail}]
  "Render a context item.
   type: :file, :dir, :repo-map, :cursor, :mcp
   Returns {: text : hl-group}."
  (let [cfg (or (. type-config type)
                {:prefix "@" :hl-group :EcaContextFile})
        display-name (or cfg.label name "")
        text (match type
               :cursor (.. cfg.prefix "cursor(" (or name "") (if detail (.. " " detail) "") ")")
               :repo-map (.. cfg.prefix display-name)
               _ (.. cfg.prefix display-name))]
    {:text text
     :hl-group cfg.hl-group}))

{: render}
