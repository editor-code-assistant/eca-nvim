(import-macros {: deftest : testing : is} :spec.eca.macros)
(import-macros {: defn-} :eca.nfnl.macros.aniseed)

(defn- load-selection
  []
  (let [(ok result) (pcall require :fennel-extras.lint.selection)]
    (if ok
      result
      {:module-missing true})))

(defn- parse-name-status
  [text]
  (let [selection (load-selection)]
    (if (. selection :module-missing)
      selection
      (selection.parse-name-status text))))

(defn- parse-untracked
  [text]
  (let [selection (load-selection)]
    (if (. selection :module-missing)
      selection
      (selection.parse-untracked text))))

(defn- parse-hunks
  [text]
  (let [selection (load-selection)]
    (if (. selection :module-missing)
      selection
      (selection.parse-hunks text))))

(defn- form-selected?
  [form intervals]
  (let [selection (load-selection)]
    (if (. selection :module-missing)
      selection
      (selection.form-selected? form intervals))))

(defn- plan
  [records untracked]
  (let [selection (load-selection)]
    (if (. selection :module-missing)
      selection
      (selection.plan records untracked))))

(deftest name-status
  (testing "parses modified and added paths from NUL-separated name-status output"
    (is (= [{:status "M" :path "fnl/a file.fnl" :old-path nil}
            {:status "A" :path "fnl/new\tfile.fnl" :old-path nil}]
           (parse-name-status "M\tfnl/a file.fnl\0A\tfnl/new\tfile.fnl\0"))))
  (testing "parses rename and copy scores with destination and old paths"
    (is (= [{:status "R" :path "fnl/new.fnl" :old-path "fnl/old.fnl"}
            {:status "C" :path "fnl/copy.fnl" :old-path "fnl/source.fnl"}]
           (parse-name-status "R100\tfnl/old.fnl\0fnl/new.fnl\0C75\tfnl/source.fnl\0fnl/copy.fnl\0"))))
  (testing "returns an empty list for empty name-status output"
    (is (= [] (parse-name-status "")))))

(deftest untracked
  (testing "parses NUL-separated untracked paths including spaces and tabs"
    (is (= ["fnl/new file.fnl" "fnl/tab\tfile.fnl"]
           (parse-untracked "fnl/new file.fnl\0fnl/tab\tfile.fnl\0"))))
  (testing "returns an empty list for empty untracked output"
    (is (= [] (parse-untracked "")))))

(deftest hunks
  (testing "parses added and changed new-side line intervals"
    (is (= [{:start 4 :end 5} {:start 10 :end 12}]
           (parse-hunks "@@ -3,2 +4,2 @@\n@@ -9 +10,3 @@\n"))))
  (testing "treats a pure deletion as the new-side point at the deletion location"
    (is (= [{:start 7 :end 7}]
           (parse-hunks "@@ -7,2 +7,0 @@\n"))))
  (testing "uses one line when an omitted hunk count is present"
    (is (= [{:start 12 :end 12}]
           (parse-hunks "@@ -11 +12 @@\n")))))

(deftest form-selection
  (testing "selects a form when its inclusive span overlaps a changed interval"
    (is (= true
           (form-selected? {:line 8 :end-line 12} [{:start 12 :end 14}]))))
  (testing "does not select a form outside all changed intervals"
    (is (= false
           (form-selected? {:line 8 :end-line 11} [{:start 12 :end 14}])))))

(deftest planning
  (testing "classifies additions untracked files and rename destinations as whole-file scope"
    (is (= {:whole   ["a.fnl" "new.fnl" "renamed.fnl"]
            :hunks   []
            :deleted ["old.fnl"]}
           (plan [{:status "A" :path "a.fnl" :old-path nil}
                  {:status "R" :path "renamed.fnl" :old-path "old.fnl"}]
                 ["new.fnl"]))))
  (testing "classifies modifications as hunk scope and deletions as deleted paths"
    (is (= {:whole [] :hunks ["changed.fnl"] :deleted ["gone.fnl"]}
           (plan [{:status "M" :path "changed.fnl" :old-path nil}
                  {:status "D" :path "gone.fnl" :old-path nil}]
                 []))))
  (testing "classifies copied destinations as whole-file scope and old paths as deleted"
    (is (= {:whole ["copy.fnl"] :hunks [] :deleted ["source.fnl"]}
           (plan [{:status "C" :path "copy.fnl" :old-path "source.fnl"}] [])))))
