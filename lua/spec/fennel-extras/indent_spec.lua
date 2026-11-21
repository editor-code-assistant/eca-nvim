-- [nfnl] fnl/spec/fennel-extras/indent_spec.fnl
local function load_indent()
  local ok, result = pcall(require, "fennel-extras.indent")
  if ok then
    return result
  else
    return {error = "module missing"}
  end
end
local explicit_indent_config = {["indent-width"] = 2, parser = "eca.nfnl.fennel", indents = {fn = {{"inner", 0}}, lambda = {{"inner", 0}}, macro = {{"inner", 0}}, let = {{"block", 1}}, when = {{"block", 1}}, ["when-let"] = {{"block", 1}}, ["if-let"] = {{"block", 1}}, each = {{"block", 1}}, ["for"] = {{"block", 1}}, icollect = {{"block", 1}}, collect = {{"block", 1}}, accumulate = {{"block", 1}}, case = {{"block", 1}}, match = {{"block", 1}}, ["case-try"] = {{"block", 1}}, ["match-try"] = {{"block", 1}}, ["while"] = {{"block", 1}}, ["with-open"] = {{"block", 1}}, ["do"] = {{"block", 0}}, def = {{"inner", 0}}, defn = {{"inner", 0}}, ["defn-"] = {{"inner", 0}}}, alignment = {["binding-forms"] = {"let", "when-let", "if-let", "with-open"}, ["align-args"] = {"and", "or"}, ["align-pairs"] = {"case", "cond", "match", "case-try", "match-try"}, bindings = false, ["collapse-padding"] = false, maps = false, ["split-bindings"] = false}}
local function reindent_call_body(indent, source)
  return indent.reindent(source, explicit_indent_config)
end
local function reindent_call(indent, source)
  local ok, result, err = pcall(reindent_call_body, indent, source)
  return {ok = ok, value = result, error = err}
end
local function reindent_result(result)
  if result.ok then
    return {value = result.value, error = result.error}
  else
    return {["call-error"] = true, error = result.error}
  end
end
local function reindent_scenario(source)
  local indent = load_indent()
  if indent.error then
    return indent
  else
    return reindent_result(reindent_call(indent, source))
  end
end
local function output_for(source)
  local result = reindent_scenario(source)
  if result.error then
    return result
  else
    return result.value
  end
end
local function output_for_config(source, config)
  local indent = load_indent()
  local config0 = vim.tbl_deep_extend("force", explicit_indent_config, config)
  return indent.reindent(source, config0)
end
local function newline_count(source)
  return select(2, string.gsub(source, "\\n", ""))
end
local function idempotent_3f(source)
  local once = output_for(source)
  return (("string" == type(once)) and (once == output_for(once)))
end
local function error_summary_result(result)
  return {["value?"] = (result.ok and (nil ~= result.value)), ["has-message"] = (result.ok and (nil == result.value) and (nil ~= result.error) and ("string" == type(result.error.message))), ["returned-error"] = (result.ok and result.value and (nil == result.value) and result.error)}
end
local function error_summary(source)
  local indent = load_indent()
  if indent.error then
    return indent
  else
    return error_summary_result(reindent_call(indent, source))
  end
end
local function alignment_error_call_body(indent, alignment)
  return indent.reindent("(x\ny)", vim.tbl_deep_extend("force", explicit_indent_config, {alignment = alignment}))
end
local function alignment_error_call(indent, alignment)
  local ok, value, err = pcall(alignment_error_call_body, indent, alignment)
  return {ok = ok, value = value, error = err}
end
local function alignment_error_result(result)
  local ok = result.ok
  local value = result.value
  local err = result.error
  return {["ok?"] = ok, ["result-nil?"] = (nil == value), ["has-message"] = (ok and (nil == value) and err and ("table" == type(err)) and ("string" == type(err.message))), message = (ok and (nil == value) and err and err.message)}
end
local function alignment_error_summary(alignment)
  local indent = load_indent()
  if indent.error then
    return indent
  else
    return alignment_error_result(alignment_error_call(indent, alignment))
  end
end
local function _7_()
  local function _8_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo a\n  b)"
    local actual_7_auto = output_for("(foo a\n b)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses opener offset for a call continuation", _8_)
  local function _9_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo\n  b)"
    local actual_7_auto = output_for("(foo\nb)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses opener offset for a head-only call continuation", _9_)
  local function _10_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(x\n ;; c\n)"
    local actual_7_auto = output_for("(x\n  ;; c\n)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a comment and closer to their opener", _10_)
  local function _11_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(a\n  b)"
    local actual_7_auto = output_for("(a\nb)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses opener offset for a no-final-newline continuation", _11_)
  local function _12_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "a\nb"
    local actual_7_auto = output_for("a\nb")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("preserves a one-character final line without a final newline", _12_)
  local function _13_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo\n  (bar x\n    y))"
    local actual_7_auto = output_for("(foo\n (bar x\n y))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses each opener offset for nested call continuations", _13_)
  local function _14_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "[a\n  b]"
    local actual_7_auto = output_for("[a\nb]")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses opener offset for sequence continuations", _14_)
  local function _15_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "{:a\n  b}"
    local actual_7_auto = output_for("{:a\nb}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses opener offset for table continuations", _15_)
  local function _16_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "((f) x\n  y)"
    local actual_7_auto = output_for("((f) x\n  y)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses opener offset for a non-symbol head", _16_)
  local function _17_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo a\n  b\n)"
    local actual_7_auto = output_for("(foo a\n b\n  )")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("keeps a closer on its own line matched to its opener", _17_)
  local function _18_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo\n  ;; comment\n  bar)"
    local actual_7_auto = output_for("(foo\n;; comment\nbar)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("indents a comment line like code at that position", _18_)
  local function _19_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo)\n(bar)"
    local actual_7_auto = output_for("(foo)\n  (bar)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("starts each top-level form at column zero", _19_)
end
require("plenary.busted").describe("alignment-goldens", _7_)
local canonical_indent_config = {["indent-width"] = 2, parser = "eca.nfnl.fennel", indents = {fn = {{"inner", 0}}, def = {{"inner", 0}}, ["def-"] = {{"inner", 0}}, defn = {{"inner", 0}}, ["defn-"] = {{"inner", 0}}}, ["format-as"] = {def = "fn", ["def-"] = "fn", defn = "fn", ["defn-"] = "fn"}, alignment = {bindings = true, maps = true, ["split-bindings"] = true, ["collapse-padding"] = true, ["binding-forms"] = {"let", "when-let", "if-let", "with-open"}, ["align-args"] = {"and", "or"}, ["align-pairs"] = {"case", "cond", "match", "case-try", "match-try"}}}
local function output_for_canonical(source, config)
  local indent = load_indent()
  local config0 = vim.tbl_deep_extend("force", canonical_indent_config, (config or {}))
  return indent.reindent(source, config0)
end
local function _20_()
  local function _21_()
    local output = output_for_canonical("(when (and very-long-condition\n another-condition)\n (if ready\n value\n fallback))", {})
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when (and very-long-condition\n           another-condition)\n  (if ready\n    value\n    fallback))"
    local actual_7_auto = output
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("keeps unconfigured when and nested long-condition if form-sensitive", _21_)
  local function _22_()
    for _, width in ipairs({2, 4}) do
      local source = "(cond\n (ready\n (case value\n (:a (handle-a))\n (:b (handle-b))))\n (otherwise\n (fallback)))"
      local expected
      if (width == 2) then
        expected = "(cond\n  (ready\n    (case value\n      (:a (handle-a))\n      (:b (handle-b))))\n  (otherwise\n    (fallback)))"
      else
        expected = "(cond\n    (ready\n        (case value\n            (:a (handle-a))\n            (:b (handle-b))))\n    (otherwise\n        (fallback)))"
      end
      local assert_5_auto = require("luassert")
      local expected_6_auto = expected
      local actual_7_auto = output_for_canonical(source, {["indent-width"] = width})
      assert_5_auto.same(expected_6_auto, actual_7_auto)
    end
    return nil
  end
  return require("plenary.busted").it("keeps cond and case clause arms aligned at widths 2 and 4", _22_)
end
require("plenary.busted").describe("canonical-alignment-fallbacks", _20_)
local function _24_()
  local source = "(cond\n (ready\n (case value\n (:a (handle-a))\n (:b (handle-b))))\n (otherwise\n (fallback)))"
  local once = output_for_canonical(source, {})
  local assert_5_auto = require("luassert")
  local expected_6_auto = once
  local actual_7_auto = output_for_canonical(once, {})
  assert_5_auto.same(expected_6_auto, actual_7_auto)
  return true
end
require("plenary.busted").it("is idempotent", _24_)
local function _25_()
  local function _26_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo a\n    b)"
    local actual_7_auto = output_for_config("(foo a\n b)", {["indent-width"] = 4})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses indent-width for an unconfigured continuation", _26_)
  local function _27_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when condition\n  (if ready\n    value\n    fallback))"
    local actual_7_auto = output_for("(when condition\n (if ready\n value\n fallback))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("uses the active opener column for nested when and if continuations", _27_)
end
require("plenary.busted").describe("universal-fallback-indent", _25_)
local function _28_()
  local function _29_()
    local assert_28_auto = require("luassert")
    local value_29_auto = ((newline_count("(x\n  ;; c\n)") == newline_count(output_for("(x\n  ;; c\n)"))) and (newline_count("(a\nb)") == newline_count(output_for("(a\nb)"))) and (newline_count("a\nb") == newline_count(output_for("a\nb"))))
    assert_28_auto.is_truthy(value_29_auto, "(and (= (newline-count \"(x\n  ;; c\n)\") (newline-count (output-for \"(x\n  ;; c\n)\"))) (= (newline-count \"(a\nb)\") (newline-count (output-for \"(a\nb)\"))) (= (newline-count \"a\nb\") (newline-count (output-for \"a\nb\"))))")
    return true
  end
  require("plenary.busted").it("preserves newline counts for final-line regression inputs", _29_)
  local function _30_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo \"one\n  two\"\n  bar)"
    local actual_7_auto = output_for("(foo \"one\n  two\"\nbar)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("keeps leading spaces inside multi-line strings unchanged", _30_)
  local function _31_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo\n\n  bar)"
    local actual_7_auto = output_for("(foo\n   \nbar)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("turns whitespace-only lines into empty lines", _31_)
  local function _32_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo a\n  b   )"
    local actual_7_auto = output_for("(foo a\n b   )")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("keeps trailing spaces after code", _32_)
  local function _33_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(\206\187 a\n  b)"
    local actual_7_auto = output_for("(\206\187 a\nb)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("counts Unicode codepoints for continuation columns", _33_)
end
require("plenary.busted").describe("preservation", _28_)
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
  local file = assert(io.open(path, "r"))
  local source = file:read("*a")
  file:close()
  return source
end
local function reindent_config(config)
  if config then
    return vim.tbl_deep_extend("force", explicit_indent_config, config)
  else
    return explicit_indent_config
  end
end
local function reindent_direct(source, config)
  local indent = load_indent()
  local config0 = reindent_config(config)
  return indent.reindent(source, config0)
end
local function repo_idempotence_failures()
  local config = {indents = {deftest = {{"block", 1}}, testing = {{"block", 1}}}}
  local failures = {}
  for _, path in ipairs(file_paths()) do
    local source = read_source(path)
    local once = reindent_direct(source, config)
    if (nil == once) then
      table.insert(failures, ("error: " .. path))
    else
      local twice = reindent_direct(once, config)
      if (once ~= twice) then
        table.insert(failures, path)
      else
      end
    end
  end
  return failures
end
local function _39_()
  local function _40_()
    local assert_28_auto = require("luassert")
    local value_29_auto = idempotent_3f("(foo a\n b)")
    assert_28_auto.is_truthy(value_29_auto, "(idempotent? \"(foo a\n b)\")")
    return true
  end
  require("plenary.busted").it("alignment golden is idempotent", _40_)
  local function _41_()
    local assert_28_auto = require("luassert")
    local value_29_auto = idempotent_3f("(foo \"one\n  two\"\nbar)")
    assert_28_auto.is_truthy(value_29_auto, "(idempotent? \"(foo \\\"one\n  two\\\"\nbar)\")")
    return true
  end
  require("plenary.busted").it("preservation golden is idempotent", _41_)
  local function _42_()
    local assert_28_auto = require("luassert")
    local value_29_auto = idempotent_3f("(foo\n (bar x\n y))")
    assert_28_auto.is_truthy(value_29_auto, "(idempotent? \"(foo\n (bar x\n y))\")")
    return true
  end
  require("plenary.busted").it("nested golden is idempotent", _42_)
  local function _43_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_idempotence_failures()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("one direct reindent pass is idempotent for every project source", _43_)
  local function _44_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto
    do
      local result = error_summary("(missing")
      actual_7_auto = {["value?"] = result["value?"], ["has-message"] = result["has-message"]}
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("unbalanced input returns a structured reader error", _44_)
  local function _45_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["ok?"] = true, ["result-nil?"] = true, ["has-message"] = true, message = "alignment must be a table"}
    local actual_7_auto = alignment_error_summary(true)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a boolean alignment value returns the documented validation error", _45_)
  local function _46_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["ok?"] = true, ["result-nil?"] = true, ["has-message"] = true, message = "alignment must be a table"}
    local actual_7_auto = alignment_error_summary("yes")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("a string alignment value returns the documented validation error", _46_)
end
require("plenary.busted").describe("idempotence-and-errors", _39_)
local function _47_()
  local function _48_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn- apply\n  [items]\n  (if (lualine.plugin)\n    (lualine.setup items)\n    (set-native-statusline items)))"
    local actual_7_auto = reindent_direct("(defn- apply\n  [items]\n  (if (lualine.plugin)\n      (lualine.setup items)\n      (set-native-statusline items)))", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("footer-bar apply uses generic fallback offsets for an unconfigured if", _48_)
  local function _49_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn- text\n  [item]\n  (let [title (core.get item :title nil)\n         value (core.get item :value nil)\n         title-str (if title (core.str \"%#EcaHeaderKey#\" title \":\") \"\")\n         value-str (if value (core.str \"%#EcaHeaderValue#\" value) \"\")]\n    (core.str title-str value-str)))"
    local actual_7_auto = reindent_direct("(defn- text\n  [item]\n  (let [title (core.get item :title nil)\n        value (core.get item :value nil)\n        title-str (if title (core.str \"%#EcaHeaderKey#\" title \":\") \"\")\n        value-str (if value (core.str \"%#EcaHeaderValue#\" value) \"\")]\n    (core.str title-str value-str)))", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("lualine text keeps explicit let alignment and uses generic if offsets", _49_)
  local function _50_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(and first\n     second\n     third)"
    local actual_7_auto = reindent_direct("(and first\n second\n third)", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("align-args aligns later direct arguments under the first argument", _50_)
  local function _51_()
    local source = "(or first\n    second\n    third)"
    local assert_5_auto = require("luassert")
    local expected_6_auto = source
    local actual_7_auto = reindent_direct(source, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("align-args preserves already-aligned input", _51_)
  local function _52_()
    local once = reindent_direct("(and first\n second\n third)", nil)
    local assert_5_auto = require("luassert")
    local expected_6_auto = once
    local actual_7_auto = reindent_direct(once, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("align-args is idempotent", _52_)
  local function _53_()
    local result = reindent_direct("(and (foo\n bar)\n baz)", nil)
    local assert_5_auto = require("luassert")
    local expected_6_auto = "string"
    local actual_7_auto = type(result)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("align-args leaves nested composite arguments structurally valid", _53_)
end
return require("plenary.busted").describe("hand-style-fixed-points", _47_)
