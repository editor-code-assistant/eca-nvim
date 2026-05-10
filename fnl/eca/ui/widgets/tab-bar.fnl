;; tab-bar widget — tab line for multiple chats.
;; Stateful: tracks open chats, renders tabline.

(fn create [canvas initial-state]
  "Create a tab-bar widget.
   initial-state: {: tabs [{: id : title : loading? : approval?}] : active-id}
   Returns {: render : add-tab : remove-tab : select-tab : update-tab : get-state}."
  (local state (vim.tbl_extend :force
               {:tabs []
                :active-id nil}
               (or initial-state {})))

  (fn build-tabline []
    "Build tabline format string."
    (let [parts []]
      (each [_ tab (ipairs state.tabs)]
        (let [is-active (= tab.id state.active-id)
              hl-group (if tab.approval? :EcaTabLoading
                           tab.loading? :EcaTabLoading
                           is-active :EcaTabActive
                           :EcaTabInactive)
              prefix (if tab.approval? "🚧 "
                         tab.loading? "⏳ "
                         "")
              title (or tab.title (tostring tab.id))]
          (table.insert parts
            (.. "%#" hl-group "# " prefix title " "))))
      ;; Add new chat button
      (table.insert parts "%#EcaButtonAccept# + ")
      ;; Add close button
      (table.insert parts "%#EcaButtonReject# × ")
      (table.concat parts "%#Normal#│")))

  (fn render []
    (let [tabline (build-tabline)]
      (canvas:set-option :global :tabline tabline)
      (canvas:set-option :global :showtabline 2)))

  (fn add-tab [tab]
    "Add a new tab. tab: {: id : title : loading? : approval?}."
    (table.insert state.tabs tab)
    (when (= nil state.active-id)
      (set state.active-id tab.id)))

  (fn remove-tab [id]
    "Remove a tab by id."
    (let [new-tabs []]
      (each [_ tab (ipairs state.tabs)]
        (when (not= tab.id id)
          (table.insert new-tabs tab)))
      (set state.tabs new-tabs)
      ;; If active tab was removed, select first available
      (when (= state.active-id id)
        (set state.active-id
          (if (> (length new-tabs) 0)
            (. (. new-tabs 1) :id)
            nil)))))

  (fn select-tab [id]
    "Select active tab."
    (set state.active-id id))

  (fn update-tab [id new-state]
    "Update a tab's state."
    (each [_ tab (ipairs state.tabs)]
      (when (= tab.id id)
        (each [k v (pairs new-state)]
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
