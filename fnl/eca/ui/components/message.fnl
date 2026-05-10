;; message component — renders chat message blocks.
;; Stateless, pure function.

(local role-config
  {:user      {:prefix "  You" :hl-group :EcaUser}
   :assistant {:prefix "  ECA" :hl-group :EcaAssistant}
   :system    {:prefix "  System" :hl-group :EcaSystem}})

(fn split-lines [text]
  "Split text into lines."
  (let [lines []]
    (if (or (= nil text) (= "" text))
      (table.insert lines "")
      (each [line (text:gmatch "([^\n]*)\n?")]
        (table.insert lines line)))
    lines))

(fn render [{: role : content}]
  "Render a chat message.
   Returns {: lines : highlights} where lines is a list of strings
   and highlights is a list of {: line-idx : hl-group : col-start : col-end}."
  (let [cfg (or (. role-config role)
                {:prefix "  ?" :hl-group :EcaAssistant})
        content-lines (split-lines (or content ""))
        lines [cfg.prefix "" ]
        highlights [{:line-idx 0
                     :hl-group cfg.hl-group
                     :col-start 0
                     :col-end (length cfg.prefix)}]]
    ;; Add content lines
    (each [_ line (ipairs content-lines)]
      (table.insert lines line))
    ;; Add trailing empty line
    (table.insert lines "")
    {: lines : highlights}))

(fn render-welcome []
  "Render a welcome message for empty chats.
   Returns {: lines : highlights}."
  (let [lines [""
               "  Welcome to ECA Chat"
               ""
               "  Type your message below and press Enter to send."
               "  Use @ to attach context (files, directories, etc.)"
               ""]]
    {:lines lines
     :highlights [{:line-idx 1
                   :hl-group :EcaWelcome
                   :col-start 0
                   :col-end (length "  Welcome to ECA Chat")}]}))

{: render
 : render-welcome}
