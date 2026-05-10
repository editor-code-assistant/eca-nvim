;; Canvas protocol — abstract contract for rendering operations.
;; Any canvas implementation must provide all functions listed here.
;; The UI layer (components, widgets, builder) depends ONLY on this contract.

(local protocol-keys
  [:set-lines        ;; (canvas start end lines) — replace lines in buffer
   :get-lines        ;; (canvas start end) — read lines from buffer
   :add-extmark      ;; (canvas ns-id line col opts) — add extmark, returns id
   :del-extmark      ;; (canvas ns-id id) — remove extmark
   :get-extmarks     ;; (canvas ns-id start end opts) — get extmarks in range
   :create-namespace ;; (canvas name) — create namespace for extmarks, returns ns-id
   :set-option       ;; (canvas scope key value) — set option (scope: :win or :buf)
   :get-option       ;; (canvas scope key) — get option value
   :line-count       ;; (canvas) — total line count in buffer
   :get-cursor       ;; (canvas) — returns [line col]
   :set-cursor       ;; (canvas line col) — move cursor
   :buf-valid?       ;; (canvas) — is buffer still valid?
   :win-valid?       ;; (canvas) — is window still valid?
   :close-win        ;; (canvas) — close window
   :set-hl           ;; (canvas ns group opts) — define highlight group
   :buf-id           ;; (canvas) — returns the underlying buffer id
   :win-id           ;; (canvas) — returns the underlying window id
   ])

(fn validate [canvas]
  "Validate that a canvas implementation satisfies the protocol.
   Returns true if valid, or (false missing-keys) if not."
  (let [missing (icollect [_ key (ipairs protocol-keys)]
                   (when (= nil (. canvas key)) key))]
    (if (= 0 (length missing))
      true
      (values false missing))))

(fn describe []
  "Returns the list of protocol keys for documentation/introspection."
  protocol-keys)

{: validate
 : describe
 : protocol-keys}
