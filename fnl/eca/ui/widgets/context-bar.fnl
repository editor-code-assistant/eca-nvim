;; context-bar widget — horizontal bar of attached @contexts.
;; Stateful: manages list of contexts, renders via canvas.

(local context-item-component (require :eca.ui.components.context-item))

(fn create [canvas]
  "Create a context-bar widget.
   Returns {: render : add : remove : clear : get-state}."
  (var state {:contexts []
              :ns-id nil})

  (fn ensure-ns []
    (when (= nil state.ns-id)
      (set state.ns-id (canvas:create-namespace "eca-context-bar")))
    state.ns-id)

  (fn build-line []
    "Build the context bar line from current state."
    (if (= 0 (length state.contexts))
      {:line "" :parts []}
      (let [parts []
            highlights []]
        (var col 0)
        (each [i ctx (ipairs state.contexts)]
          (when (> i 1)
            (table.insert parts " ")
            (set col (+ col 1)))
          (let [rendered (context-item-component.render ctx)]
            (table.insert parts rendered.text)
            (table.insert highlights
              {:hl-group rendered.hl-group
               :col-start col
               :col-end (+ col (length rendered.text))})
            (set col (+ col (length rendered.text)))))
        {:line (table.concat parts "")
         :highlights highlights})))

  (fn render [line-num]
    "Render the context bar at the given line number."
    (let [ns (ensure-ns)
          {: line : highlights} (build-line)]
      (when (and line (not= "" line))
        (canvas:set-modifiable true)
        (canvas:set-lines line-num (+ line-num 1) [line])
        ;; Apply highlights
        (each [_ hl (ipairs (or highlights []))]
          (canvas:add-extmark ns line-num hl.col-start
            {:end_col hl.col-end
             :hl_group hl.hl-group}))
        (canvas:set-modifiable false))))

  (fn add [ctx]
    "Add a context item. ctx: {: type : name : path : detail}."
    ;; Avoid duplicates by name
    (var exists false)
    (each [_ existing (ipairs state.contexts)]
      (when (= existing.name ctx.name)
        (set exists true)))
    (when (not exists)
      (table.insert state.contexts ctx)))

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
