(import-macros {: deftest : testing : is} :fennel-extras.macros.test)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)
(local prompt-area (require :eca.ui.widgets.prompt-area))

(defn- with-cleanup
  [cleanup f]
  (let [(ok result) (pcall f)]
    (cleanup)
    (if ok
      result
      (error result 0))))

(defn- with-api-stubs
  [stubs f]
  (let [originals (icollect [_ stub (ipairs stubs)] [stub.name (. vim.api stub.name)])]
    (each [_ stub (ipairs stubs)]
          (tset vim.api stub.name stub.value))
    (with-cleanup (fn []
                    (each [_ original (ipairs originals)]
                          (tset vim.api (. original 1) (. original 2))))
                  f)))

(deftest get-text
  (testing "preserves multiline prompt text from zero-based buffer ranges"
    (let [lines ["> first" "second"]]
      (with-api-stubs [{:name  :nvim_buf_line_count
                        :value (fn [_] 2)}
                       {:name  :nvim_buf_get_lines
                        :value (fn [_ start end _]
                                 (icollect [i line (ipairs lines)]
                                           (when (and (>= (- i 1) start) (< (- i 1) end)) line)))}
                       {:name  :nvim_create_namespace
                        :value (fn [_] 1)}
                       {:name  :nvim_buf_clear_namespace
                        :value (fn [_ _ _ _] nil)}
                       {:name  :nvim_buf_set_extmark
                        :value (fn [_ _ _ _] 1)}
                       {:name  :nvim_buf_set_lines
                        :value (fn [_ _ _ _ _] nil)}
                       {:name  :nvim_create_autocmd
                        :value (fn [_ _] nil)}]
                      (fn []
                        (let [widget (prompt-area.create 1)
                              result (do (widget.set-text-internal "first\nsecond")
                                         (widget.render 0)
                                         (widget.get-text))]
                          (is (= "first\nsecond"
                                 result))))))))
