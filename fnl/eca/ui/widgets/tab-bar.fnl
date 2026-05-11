;; tab-bar widget — generic tab line.
;; Zero business logic. Receives pre-formatted tab data.

(fn create [canvas initial-state]
  "Create a tab-bar widget.
   initial-state: {: tabs [{: id : label : hl-group}] : active-id}
   Returns {: render : add-tab : remove-tab : select-tab : update-tab : get-state}."
  (local state (vim.tbl_extend :force
                 {:tabs []
                  :active-id nil}
                 (or initial-state {})))

  (fn build-tabline []
    (let [parts []]
      (each [_ tab (ipairs state.tabs)]
        (let [is-active (= tab.id state.active-id)
              hl (or tab.hl-group (if is-active :EcaTabActive :EcaTabInactive))]
          (table.insert parts
            (.. "%#" hl "# " (or tab.label (tostring tab.id)) " "))))
      (table.concat parts "%#Normal#│")))

  (fn render []
    (let [tabline (build-tabline)]
      (canvas:set-option :global :tabline tabline)
      (canvas:set-option :global :showtabline 2)))

  (fn add-tab [tab]
    (table.insert state.tabs tab)
    (when (= nil state.active-id)
      (set state.active-id tab.id)))

  (fn remove-tab [id]
    (let [new-tabs (icollect [_ tab (ipairs state.tabs)]
                     (when (not= tab.id id) tab))]
      (set state.tabs new-tabs)
      (when (= state.active-id id)
        (set state.active-id
          (if (> (length new-tabs) 0)
            (. (. new-tabs 1) :id)
            nil)))))

  (fn select-tab [id]
    (set state.active-id id))

  (fn update-tab [id new-data]
    (each [_ tab (ipairs state.tabs)]
      (when (= tab.id id)
        (each [k v (pairs new-data)]
          (tset tab k v)))))

  (fn get-state []
    state)

  {: render
   : add-tab
   : remove-tab
   : select-tab
   : update-tab
   : get-state})

{: create}
