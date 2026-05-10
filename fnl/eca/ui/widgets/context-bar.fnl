;; context-bar widget — horizontal bar of attached @contexts.
;; Stateful: manages list of contexts, renders via canvas.

(local context-item-component (require :eca.ui.components.context-item))

(fn create [canvas]
  "Create a context-bar widget.
   Returns {: render : add : remove : clear : get-state}."
  (local state {:contexts []
              :ns-id nil})

  (fn ensure-ns []
    (when (= nil state.ns-id)
      (set state.ns-id (canvas:create-namespace "eca-context-bar")))
    state.ns-id)

  (fn build-line []
    "Build the context bar line from current state."
    (if (= 0 (length state.contexts))
      {:line "" :parts []}
      (let [result (accumulate [acc {:parts [] :highlights [] :col 0}
                                _ ctx (ipairs state.contexts)]
                     (let [sep-col (if (> acc.col 0)
                                     (do (table.insert acc.parts " ")
                                         (+ acc.col 1))
                                     acc.col)
                           rendered (context-item-component.render ctx)]
                       (table.insert acc.parts rendered.text)
                       (table.insert acc.highlights
                         {:hl-group rendered.hl-group
                          :col-start sep-col
                          :col-end (+ sep-col (length rendered.text))})
                       {:parts acc.parts
                        :highlights acc.highlights
                        :col (+ sep-col (length rendered.text))}))]
        {:line (table.concat result.parts "")
         :highlights result.highlights})))

  (fn render [line-num]
    "Render the context bar at the given line number."
    (let [ns (ensure-ns)
          {: line : highlights} (build-line)]
      (when (and line (not= "" line))
        (canvas:set-lines line-num (+ line-num 1) [line])
        ;; Apply highlights
        (each [_ hl (ipairs (or highlights []))]
          (canvas:add-extmark ns line-num hl.col-start
            {:end_col hl.col-end
             :hl_group hl.hl-group})))))

  (fn add [ctx]
    "Add a context item. ctx: {: type : name : path : detail}."
    (let [exists (accumulate [found false
                              _ existing (ipairs state.contexts)]
                   (or found (= existing.name ctx.name)))]
      (when (not exists)
        (table.insert state.contexts ctx))))

  (fn remove [name]
    "Remove a context item by name."
    (let [new-contexts []]
      (each [_ ctx (ipairs state.contexts)]
        (when (not= ctx.name name)
          (table.insert new-contexts ctx)))
      (set state.contexts new-contexts)))

  (fn clear []
    "Remove all contexts."
    (set state.contexts []))

  (fn get-state []
    state)

  {: render
   : add
   : remove
   : clear
   : get-state})

{: create}
