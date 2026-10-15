(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)

(module fennel-extras.lint.selection)

(local core (require :eca.nfnl.core))

(defn- append-item [result value]
  (core.concat result [value]))

(defn- add-status [result status path old-path]
  (append-item result {:status status :path path :old-path old-path}))

(defn- split-nul [text]
  (icollect [part (string.gmatch text "[^%z]+")] part))

(defn- status-letter [status]
  (string.sub status 1 1))

(defn- parse-status-parts [parts index result]
  (if (> index (length parts))
      result
      (let [record (. parts index)
            tab (string.find record "\t")
            status (status-letter (string.sub record 1 (or tab 1)))
            rename (or (= status "R") (= status "C"))
            separated? (not= tab nil)
            first-path (if separated? (string.sub record (+ tab 1)) (. parts (+ index 1)))
            old-path (if rename first-path nil)
            destination (if rename (. parts (+ index (if separated? 1 2))) first-path)
            next-index (if rename (+ index (if separated? 2 3)) (+ index (if separated? 1 2)))]
        (parse-status-parts parts
                            next-index
                            (add-status result status destination old-path)))))

(defn parse-name-status [text]
  (let [parts (split-nul text)]
    (if (= (length parts) 0)
        []
        (parse-status-parts parts 1 []))))

(defn parse-untracked [text]
  (split-nul text))

(defn- split-lines [text]
  (icollect [line (string.gmatch text "[^\n]+")] line))

(defn- hunk-line [line]
  (let [(new-start new-count) (string.match line "^@@ %-[0-9]+,?[0-9]* %+(%d+),?(%d*)")
        count (if (= new-count "") 1 (tonumber new-count))]
    (if new-start
        {:start (tonumber new-start) :end (+ (tonumber new-start) (math.max count 1) -1)}
        nil)))

(defn parse-hunks [text]
  (icollect [_ line (ipairs (split-lines text))]
    (hunk-line line)))

(defn- overlaps? [form intervals index]
  (if (> index (length intervals))
      false
      (let [interval (. intervals index)]
        (if (and (<= interval.start form.end-line)
                 (<= form.line interval.end))
            true
            (overlaps? form intervals (+ index 1))))))

(defn form-selected? [form intervals]
  (overlaps? form intervals 1))

(defn- add-unique [items value]
  (if (or (= value nil) (. items value))
      items
      (core.assoc items value true)))

(defn- append-if-new [seen items value]
  (if (. seen value)
      {:seen seen :items items}
      {:seen (core.assoc seen value true)
       :items (append-item items value)}))

(defn- add-record [state record]
  (if (or (= record.status "A") (= record.status "R") (= record.status "C"))
      (if (not (. state.whole-set record.path))
          (let [result (append-if-new state.whole-set state.whole record.path)]
            (core.assoc state :whole-set result.seen :whole result.items))
          state)
      (if (= record.status "D")
          (if (not (. state.deleted-set record.path))
              (let [result (append-if-new state.deleted-set state.deleted record.path)]
                (core.assoc state :deleted-set result.seen :deleted result.items))
              state)
          (if (= record.status "M")
              (if (not (. state.hunks-set record.path))
                  (let [result (append-if-new state.hunks-set state.hunks record.path)]
                    (core.assoc state :hunks-set result.seen :hunks result.items))
                  state)
              state))))

(defn- add-old-path [state record]
  (if (and (or (= record.status "R") (= record.status "C")) record.old-path
           (not (. state.deleted-set record.old-path)))
      (let [result (append-if-new state.deleted-set state.deleted record.old-path)]
        (core.assoc state :deleted-set result.seen :deleted result.items))
      state))

(defn plan [records untracked]
  (let [initial {:whole-set {} :hunks-set {} :deleted-set {}
                 :whole [] :hunks [] :deleted []}
        with-untracked (accumulate [state initial _ path (ipairs untracked)]
                         (if (or (= path nil) (. state.whole-set path))
                             state
                             (let [result (append-if-new state.whole-set state.whole path)]
                               (core.assoc state :whole-set result.seen :whole result.items))))
        with-records (accumulate [state with-untracked _ record (ipairs records)]
                       (add-record state record))
        final-state (accumulate [state with-records _ record (ipairs records)]
                      (add-old-path state record))]
    (table.sort final-state.whole)
    (table.sort final-state.hunks)
    (table.sort final-state.deleted)
    {:whole final-state.whole :hunks final-state.hunks :deleted final-state.deleted}))
