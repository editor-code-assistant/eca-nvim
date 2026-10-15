-- [nfnl] fnl/spec/fennel-extras/lint/identity_spec.fnl
local function load_identity()
  local ok, result = pcall(require, "fennel-extras.lint.identity")
  if ok then
    return result
  else
    return {["module-missing"] = true}
  end
end
local function identity_forms(source, path)
  local identity = load_identity()
  if identity["module-missing"] then
    return identity
  else
    local forms, err = identity.forms(source, path)
    if forms then
      return forms
    else
      return {["reader-error"] = err}
    end
  end
end
local function form_ids(source, path)
  local forms = identity_forms(source, path)
  if (forms["module-missing"] or forms["reader-error"]) then
    return forms
  else
    local tbl_26_ = {}
    local i_27_ = 0
    for _, form in ipairs(forms) do
      local val_28_ = form.form
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    return tbl_26_
  end
end
local function find_form_id(forms, form_id)
  local result = nil
  for _, form in ipairs(forms) do
    if (form_id == form.form) then
      result = form
    else
    end
  end
  return result
end
local function form_by_id(source, path, form_id)
  local forms = identity_forms(source, path)
  if (forms["module-missing"] or forms["reader-error"]) then
    return forms
  else
    return find_form_id(forms, form_id)
  end
end
local function span_summary(source, path, form_id)
  local form = form_by_id(source, path, form_id)
  if (form["module-missing"] or form["reader-error"]) then
    return form
  else
    return {line = form.line, col = form.col, ["end-line"] = form["end-line"], ["end-col"] = form["end-col"]}
  end
end
local function location_summary(source, path, form_id)
  local form = form_by_id(source, path, form_id)
  if form then
    return {line = form.line, col = form.col}
  else
    return nil
  end
end
local function reader_end_summary(source)
  local reader = require("fennel-extras.reader")
  local tokens = reader.tokenize(source)
  local closing = tokens[#tokens]
  return {line = 1, col = 1, ["end-line"] = closing.line, ["end-col"] = (closing.col + 1)}
end
local function failure_summary(source, path)
  local identity = load_identity()
  if identity["module-missing"] then
    return identity
  else
    local value, err = identity.forms(source, path)
    return {["value-nil?"] = (nil == value), message = (err and err.message), line = (err and err.line), col = (err and err.col)}
  end
end
local function _11_()
  local function _12_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/app.fnl > module:app", "fnl/app.fnl > module:app > defn:run", "fnl/app.fnl > module:app > defn:run > if#1"}
    local actual_7_auto = form_ids("(module app)\n(defn run [] (if a b c))", "fnl/app.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("module and named declarations form stable ancestor identities", _12_)
  local function _13_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/names.fnl > module:names", "fnl/names.fnl > module:names > def:value", "fnl/names.fnl > module:names > defn-:hidden", "fnl/names.fnl > module:names > deftest:works"}
    local actual_7_auto = form_ids("(module names)\n(def value 1)\n(defn- hidden [] 1)\n(deftest works (is true))", "fnl/names.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("def, private defn, and deftest declarations use named segments", _13_)
end
require("plenary.busted").describe("named-identities", _11_)
local function _14_()
  local function _15_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/legacy.fnl > fn:run", "fnl/legacy.fnl > fn:run > if#1"}
    local actual_7_auto = form_ids("(fn run [] (if a b c))", "fnl/legacy.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("legacy named fn ancestors are preserved", _15_)
  local function _16_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/legacy.fnl > local:run", "fnl/legacy.fnl > local:run > if#1"}
    local actual_7_auto = form_ids("(local run (fn [] (if a b c)))", "fnl/legacy.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("local fn bindings name the ancestor without an anonymous fn segment", _16_)
end
require("plenary.busted").describe("legacy-identities", _14_)
local function _17_()
  local function _18_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/unnamed.fnl > top#1", "fnl/unnamed.fnl > top#2"}
    local actual_7_auto = form_ids(";; ignored\n(foo)\n\n(bar)", "fnl/unnamed.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("unnamed top-level forms use trivia-independent ordinals", _18_)
  local function _19_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/nested.fnl > defn:run", "fnl/nested.fnl > defn:run > if#1", "fnl/nested.fnl > defn:run > if#2"}
    local actual_7_auto = form_ids("(defn run [] (if a b c) (vector 1) (if d e f))", "fnl/nested.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("unnamed nested siblings count only the same node kind", _19_)
end
require("plenary.busted").describe("unnamed-identities", _17_)
local function _20_()
  local function _21_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/collections.fnl > defn:run", "fnl/collections.fnl > defn:run > sequence#1", "fnl/collections.fnl > defn:run > sequence#1 > if#1", "fnl/collections.fnl > defn:run > table#1", "fnl/collections.fnl > defn:run > table#1 > if#1"}
    local actual_7_auto = form_ids("(defn run [] [1 (if a b c)] {:x (if d e f)})", "fnl/collections.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("sequence and table nodes expose identities and nested if identities", _21_)
  local function _22_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/collections.fnl > top#1", "fnl/collections.fnl > top#1 > if#1", "fnl/collections.fnl > top#2", "fnl/collections.fnl > top#2 > if#1"}
    local actual_7_auto = form_ids("[1 (if a b c)] {:x (if d e f)}", "fnl/collections.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("top-level sequences and tables use top-level ordinals", _22_)
end
require("plenary.busted").describe("collection-identities", _20_)
local function _23_()
  local function _24_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/branches.fnl > defn:run", "fnl/branches.fnl > defn:run > if#1", "fnl/branches.fnl > defn:run > if#1 > then", "fnl/branches.fnl > defn:run > if#1 > else"}
    local actual_7_auto = form_ids("(defn run [] (if a (do b c) (do d e)))", "fnl/branches.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("if branch child forms expose then and else identity segments", _24_)
  local function _25_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/branches.fnl > defn:run", "fnl/branches.fnl > defn:run > if#1", "fnl/branches.fnl > defn:run > if#1 > then", "fnl/branches.fnl > defn:run > if#1 > then#2", "fnl/branches.fnl > defn:run > if#1 > else"}
    local actual_7_auto = form_ids("(defn run [] (if a (do b) c (do d) (do e)))", "fnl/branches.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("multi-clause if bodies use numbered then segments and final else", _25_)
  local function _26_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/branches.fnl > defn:run", "fnl/branches.fnl > defn:run > if#1", "fnl/branches.fnl > defn:run > if#1 > then"}
    local actual_7_auto = form_ids("(defn run [] (if a (do b)))", "fnl/branches.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("if with only a condition has only a then branch", _26_)
end
require("plenary.busted").describe("branch-identities", _23_)
local function _27_()
  local function _28_()
    local before = form_by_id("(module app)\n(defn run [] (if a b c))", "fnl/app.fnl", "fnl/app.fnl > module:app > defn:run > if#1")
    local after = form_by_id("(defn other [] 1)\n(module app)\n(defn run [] (if a b c))", "fnl/app.fnl", "fnl/app.fnl > module:app > defn:run > if#1")
    local assert_28_auto = require("luassert")
    local value_29_auto = (not before["module-missing"] and (before.form == after.form))
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. before \"module-missing\")) (= (. before \"form\") (. after \"form\")))")
    return true
  end
  return require("plenary.busted").it("unrelated named top-level insertion does not change named identities", _28_)
end
require("plenary.busted").describe("stability", _27_)
local function _29_()
  local function _30_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/comments.fnl > top#1"}
    local actual_7_auto = form_ids(";; (if a b c)\n(print \"(if a b c)\")", "fnl/comments.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("comments and strings containing delimiters do not create forms", _30_)
  local function _31_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/quote.fnl > top#1"}
    local actual_7_auto = form_ids("'(if a b)", "fnl/quote.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("quote prefix preserves the quoted list as a form", _31_)
  local function _32_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value-nil?"] = true, message = "missing closing delimiter", line = 1, col = 1}
    local actual_7_auto = failure_summary("(unclosed", "fnl/bad.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("reader failures return nil plus a structured message and location", _32_)
end
require("plenary.busted").describe("reader-boundaries", _29_)
local function _33_()
  local function _34_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {line = 1, col = 1, ["end-line"] = 1, ["end-col"] = 9}
    local actual_7_auto = span_summary("(if a b)", "fnl/span.fnl", "fnl/span.fnl > top#1")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("single-line spans end at the column after the closing delimiter", _34_)
  local function _35_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {line = 1, col = 1, ["end-line"] = 3, ["end-col"] = 5}
    local actual_7_auto = span_summary("(if\n  a\n  b)", "fnl/span.fnl", "fnl/span.fnl > top#1")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("multi-line spans use end-exclusive line and column positions", _35_)
  local function _36_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {line = 1, col = 1, ["end-line"] = 1, ["end-col"] = 9}
    local actual_7_auto = span_summary("(foo \195\169)", "fnl/utf8.fnl", "fnl/utf8.fnl > top#1")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("columns follow the reader's one-based UTF-8 character convention", _36_)
  local function _37_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = reader_end_summary("(foo \226\130\172)")
    local actual_7_auto = span_summary("(foo \226\130\172)", "fnl/utf8.fnl", "fnl/utf8.fnl > top#1")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("three-byte UTF-8 end columns follow the reader closing delimiter", _37_)
  local function _38_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = reader_end_summary("(foo \240\159\152\128)")
    local actual_7_auto = span_summary("(foo \240\159\152\128)", "fnl/utf8.fnl", "fnl/utf8.fnl > top#1")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("four-byte UTF-8 end columns follow the reader closing delimiter", _38_)
  local function _39_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = reader_end_summary("(foo\n  \226\130\172\240\159\152\128)")
    local actual_7_auto = span_summary("(foo\n  \226\130\172\240\159\152\128)", "fnl/utf8.fnl", "fnl/utf8.fnl > top#1")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("multi-line UTF-8 end columns follow the reader closing delimiter", _39_)
end
require("plenary.busted").describe("spans", _33_)
local function file_paths()
  local paths = {}
  local fnl_files = vim.fn.globpath("fnl", "**/*.fnl", false, true)
  local fnlm_files = vim.fn.globpath("fnl", "**/*.fnlm", false, true)
  for _, path in ipairs(fnl_files) do
    if not string.find(path, "^fnl/eca/nfnl/") then
      table.insert(paths, path)
    else
    end
  end
  for _, path in ipairs(fnlm_files) do
    if not string.find(path, "^fnl/eca/nfnl/") then
      table.insert(paths, path)
    else
    end
  end
  return paths
end
local function read_source(path)
  local ok, result
  local function _42_()
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    return source
  end
  ok, result = pcall(_42_)
  if ok then
    return result
  else
    return nil
  end
end
local function report_duplicate(duplicates, reported, form_id)
  table.insert(duplicates, form_id)
  reported[form_id] = true
  return nil
end
local function duplicate_form_ids(forms)
  local seen = {}
  local reported = {}
  local duplicates = {}
  for _, form in ipairs(forms) do
    local form_id = form.form
    if seen[form_id] then
      if not reported[form_id] then
        report_duplicate(duplicates, reported, form_id)
      else
      end
    else
      seen[form_id] = true
    end
  end
  return duplicates
end
local function repo_duplicates()
  local duplicates = {}
  for _, path in ipairs(file_paths()) do
    local source = read_source(path)
    local forms
    if source then
      forms = identity_forms(source, path)
    else
      forms = nil
    end
    if (forms and not forms["module-missing"] and not forms["reader-error"]) then
      local form_duplicates = duplicate_form_ids(forms)
      if (#form_duplicates > 0) then
        table.insert(duplicates, path)
      else
      end
    else
      table.insert(duplicates, path)
    end
  end
  return duplicates
end
local function _49_()
  local function _50_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"src/foo/bar.fnl > top#1"}
    local actual_7_auto = form_ids("(value)", "src/foo/bar.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("paths use slash separators and are passed through verbatim", _50_)
end
require("plenary.busted").describe("paths", _49_)
local function _51_()
  local function _52_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/wrappers.fnl > fn:f", "fnl/wrappers.fnl > fn:f > sequence#1", "fnl/wrappers.fnl > fn:f > sequence#2"}
    local actual_7_auto = form_ids("(fn f [] (foo (bar [1]) (baz [2])))", "fnl/wrappers.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("same-kind forms count through plain wrapper lists", _52_)
  local function _53_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/wrappers.fnl > defn:g", "fnl/wrappers.fnl > defn:g > if#1", "fnl/wrappers.fnl > defn:g > if#2"}
    local actual_7_auto = form_ids("(defn g [] (do (when x (if a b c)) (if d e f)))", "fnl/wrappers.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("if forms count through plain wrapper lists", _53_)
end
require("plenary.busted").describe("segmented-ancestor-ordinals", _51_)
local function _54_()
  local function _55_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/nested-branches.fnl > top#1", "fnl/nested-branches.fnl > top#1 > then", "fnl/nested-branches.fnl > top#1 > then > if#1", "fnl/nested-branches.fnl > top#1 > else", "fnl/nested-branches.fnl > top#1 > else > if#1"}
    local actual_7_auto = form_ids("(if a (if b c d) (if e f g))", "fnl/nested-branches.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("nested if branch roots expose separate branch and inner-if forms", _55_)
end
require("plenary.busted").describe("nested-branch-roots", _54_)
local function _56_()
  local function _57_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/testing.fnl > deftest:run", "fnl/testing.fnl > deftest:run > testing#1", "fnl/testing.fnl > deftest:run > testing#2"}
    local actual_7_auto = form_ids("(deftest run (testing \"one\" (is true)) (testing \"two\" (is true)))", "fnl/testing.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("sibling testing forms expose numbered identities", _57_)
  local function _58_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {first = {line = 1, col = 14}, second = {line = 1, col = 40}}
    local actual_7_auto = {first = location_summary("(deftest run (testing \"one\" (is true)) (testing \"two\" (is true)))", "fnl/testing.fnl", "fnl/testing.fnl > deftest:run > testing#1"), second = location_summary("(deftest run (testing \"one\" (is true)) (testing \"two\" (is true)))", "fnl/testing.fnl", "fnl/testing.fnl > deftest:run > testing#2")}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("sibling testing forms keep their source locations", _58_)
  local function _59_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/testing.fnl > deftest:run", "fnl/testing.fnl > deftest:run > testing#1", "fnl/testing.fnl > deftest:run > testing#2"}
    local actual_7_auto = form_ids("(deftest run (let [x 1] (testing \"a\" (is x))) (testing \"b\" (is true)))", "fnl/testing.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("testing ordinals count through plain wrapper lists", _59_)
  local function _60_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/testing.fnl > deftest:run", "fnl/testing.fnl > deftest:run > testing#1", "fnl/testing.fnl > deftest:run > testing#1 > testing#1"}
    local actual_7_auto = form_ids("(deftest run (testing \"outer\" (testing \"inner\" (is true))))", "fnl/testing.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("nested testing forms restart ordinals under each testing parent", _60_)
  local function _61_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/testing.fnl > deftest:run", "fnl/testing.fnl > deftest:run > testing#1", "fnl/testing.fnl > deftest:run > testing#1 > if#1"}
    local actual_7_auto = form_ids("(deftest run (testing \"outer\" (if true (is true) (is false))))", "fnl/testing.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("testing and if ordinals are tracked independently", _61_)
end
require("plenary.busted").describe("testing-identities", _56_)
local function binding_vector_identities()
  return {let = form_ids("(defn run [] (let [x xs] [1 2]))", "fnl/bindings.fnl"), ["when-let"] = form_ids("(defn run [] (when-let [x xs] [1 2]))", "fnl/bindings.fnl"), ["if-let"] = form_ids("(defn run [] (if-let [x xs] [1 2]))", "fnl/bindings.fnl"), each = form_ids("(defn run [] (each [x (ipairs xs)] [1 2]))", "fnl/bindings.fnl"), ["for"] = form_ids("(defn run [] (for [x (ipairs xs)] [1 2]))", "fnl/bindings.fnl"), icollect = form_ids("(defn run [] (icollect [i x (ipairs xs)] [1 2]))", "fnl/bindings.fnl"), collect = form_ids("(defn run [] (collect [x (ipairs xs)] [1 2]))", "fnl/bindings.fnl"), accumulate = form_ids("(defn run [] (accumulate [acc 0 _ x (ipairs xs)] [1 2]))", "fnl/bindings.fnl"), ["with-open"] = form_ids("(defn run [] (with-open [f (io.open p)] [1 2]))", "fnl/bindings.fnl"), fn = form_ids("(defn run [] (fn [x xs] [1 2]))", "fnl/bindings.fnl"), lambda = form_ids("(defn run [] (lambda [x xs] [1 2]))", "fnl/bindings.fnl"), ["lambda-symbol"] = form_ids("(defn run [] (\206\187 [x xs] [1 2]))", "fnl/bindings.fnl"), defn = form_ids("(defn inner [x xs] [1 2])", "fnl/bindings.fnl"), ["defn-"] = form_ids("(defn- inner [x xs] [1 2])", "fnl/bindings.fnl"), macro = form_ids("(macro inner [x xs] [1 2])", "fnl/bindings.fnl")}
end
local function _62_()
  local function _63_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {let = {"fnl/bindings.fnl > defn:run", "fnl/bindings.fnl > defn:run > sequence#1"}, ["when-let"] = {"fnl/bindings.fnl > defn:run", "fnl/bindings.fnl > defn:run > sequence#1"}, ["if-let"] = {"fnl/bindings.fnl > defn:run", "fnl/bindings.fnl > defn:run > sequence#1"}, each = {"fnl/bindings.fnl > defn:run", "fnl/bindings.fnl > defn:run > sequence#1"}, ["for"] = {"fnl/bindings.fnl > defn:run", "fnl/bindings.fnl > defn:run > sequence#1"}, icollect = {"fnl/bindings.fnl > defn:run", "fnl/bindings.fnl > defn:run > sequence#1"}, collect = {"fnl/bindings.fnl > defn:run", "fnl/bindings.fnl > defn:run > sequence#1"}, accumulate = {"fnl/bindings.fnl > defn:run", "fnl/bindings.fnl > defn:run > sequence#1"}, ["with-open"] = {"fnl/bindings.fnl > defn:run", "fnl/bindings.fnl > defn:run > sequence#1"}, fn = {"fnl/bindings.fnl > defn:run", "fnl/bindings.fnl > defn:run > sequence#1"}, lambda = {"fnl/bindings.fnl > defn:run", "fnl/bindings.fnl > defn:run > sequence#1"}, ["lambda-symbol"] = {"fnl/bindings.fnl > defn:run", "fnl/bindings.fnl > defn:run > sequence#1"}, defn = {"fnl/bindings.fnl > defn:inner", "fnl/bindings.fnl > defn:inner > sequence#1"}, ["defn-"] = {"fnl/bindings.fnl > defn-:inner", "fnl/bindings.fnl > defn-:inner > sequence#1"}, macro = {"fnl/bindings.fnl > top#1", "fnl/bindings.fnl > top#1 > sequence#1"}}
    local actual_7_auto = binding_vector_identities()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("binding and parameter vectors do not get identities", _63_)
  local function _64_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/nested-binding.fnl > defn:run", "fnl/nested-binding.fnl > defn:run > if#1"}
    local actual_7_auto = form_ids("(defn run [] (let [x (if a b c)] x))", "fnl/nested-binding.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("forms nested in binding vectors keep identities in the enclosing namespace", _64_)
end
require("plenary.busted").describe("binding-vector-identities", _62_)
local function _65_()
  local function _66_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/anonymous.fnl > top#1", "fnl/anonymous.fnl > top#1 > sequence#1"}
    local actual_7_auto = form_ids("(fn [x] [x])", "fnl/anonymous.fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("anonymous fn parameter vectors are syntax and body sequences are forms", _66_)
end
require("plenary.busted").describe("anonymous-fn-parameter-vector", _65_)
local function _67_()
  local function _68_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_duplicates()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("identity form values are unique in every project Fennel source", _68_)
end
return require("plenary.busted").describe("repo-properties", _67_)
