-- [nfnl] fnl/spec/fennel-extras/indent_spec.fnl
local function load_indent()
  local ok, result = pcall(require, "fennel-extras.indent")
  if ok then
    return result
  else
    return {error = "module missing"}
  end
end
local function reindent_scenario(source)
  local indent = load_indent()
  if indent.error then
    return indent
  else
    local ok, result, err
    local function _2_()
      return indent.reindent(source)
    end
    ok, result, err = pcall(_2_)
    if ok then
      return {value = result, error = err}
    else
      return {["call-error"] = true, error = err}
    end
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
local function newline_count(source)
  return select(2, string.gsub(source, "\\n", ""))
end
local function idempotent_3f(source)
  local once = output_for(source)
  if ("string" ~= type(once)) then
    return false
  else
    return (once == output_for(once))
  end
end
local function error_summary(source)
  local indent = load_indent()
  if indent.error then
    return indent
  else
    local ok, value, err
    local function _7_()
      return indent.reindent(source)
    end
    ok, value, err = pcall(_7_)
    return {["value?"] = (ok and (nil ~= value)), ["has-message"] = (ok and (nil == value) and (nil ~= err) and ("string" == type(err.message))), ["returned-error"] = (ok and value and (nil == value) and err)}
  end
end
local function _9_()
  local function _10_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo a\n     b)"
    local actual_7_auto = output_for("(foo a\n b)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a call continuation to the first argument on the head line", _10_)
  local function _11_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo\n b)"
    local actual_7_auto = output_for("(foo\nb)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a head-only call continuation to the head symbol", _11_)
  local function _12_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(x\n ;; c\n)"
    local actual_7_auto = output_for("(x\n  ;; c\n)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a comment and closer to their opener", _12_)
  local function _13_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(a\n b)"
    local actual_7_auto = output_for("(a\nb)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a no-final-newline continuation", _13_)
  local function _14_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "a\nb"
    local actual_7_auto = output_for("a\nb")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("preserves a one-character final line without a final newline", _14_)
  local function _15_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo\n (bar x\n       y))"
    local actual_7_auto = output_for("(foo\n (bar x\n y))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns nested call continuations from each call's own head", _15_)
  local function _16_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "[a\n b]"
    local actual_7_auto = output_for("[a\nb]")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns sequences to their first element", _16_)
  local function _17_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "{:a\n b}"
    local actual_7_auto = output_for("{:a\nb}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns tables to their first element", _17_)
  local function _18_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "((f) x\n y)"
    local actual_7_auto = output_for("((f) x\n  y)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a non-symbol head to its first element", _18_)
  local function _19_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo a\n     b\n)"
    local actual_7_auto = output_for("(foo a\n b\n  )")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a closer on its own line to its matching opener", _19_)
  local function _20_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo\n ;; comment\n bar)"
    local actual_7_auto = output_for("(foo\n;; comment\nbar)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("indents a comment line like code at that position", _20_)
  local function _21_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo)\n(bar)"
    local actual_7_auto = output_for("(foo)\n  (bar)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("starts each top-level form at column zero", _21_)
end
require("plenary.busted").describe("alignment-goldens", _9_)
local function _22_()
  local function _23_()
    local assert_28_auto = require("luassert")
    local value_29_auto = ((newline_count("(x\n  ;; c\n)") == newline_count(output_for("(x\n  ;; c\n)"))) and (newline_count("(a\nb)") == newline_count(output_for("(a\nb)"))) and (newline_count("a\nb") == newline_count(output_for("a\nb"))))
    assert_28_auto.is_truthy(value_29_auto, "(and (= (newline-count \"(x\n  ;; c\n)\") (newline-count (output-for \"(x\n  ;; c\n)\"))) (= (newline-count \"(a\nb)\") (newline-count (output-for \"(a\nb)\"))) (= (newline-count \"a\nb\") (newline-count (output-for \"a\nb\"))))")
    return true
  end
  require("plenary.busted").it("preserves newline counts for final-line regression inputs", _23_)
  local function _24_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo \"one\n  two\"\n     bar)"
    local actual_7_auto = output_for("(foo \"one\n  two\"\nbar)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("keeps leading spaces inside multi-line strings unchanged", _24_)
  local function _25_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo\n\n bar)"
    local actual_7_auto = output_for("(foo\n   \nbar)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("turns whitespace-only lines into empty lines", _25_)
  local function _26_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo a\n     b   )"
    local actual_7_auto = output_for("(foo a\n b   )")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("keeps trailing spaces after code", _26_)
  local function _27_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(\206\187 a\n   b)"
    local actual_7_auto = output_for("(\206\187 a\nb)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("counts Unicode codepoints for continuation columns", _27_)
end
require("plenary.busted").describe("preservation", _22_)
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
local function reindent_direct(source, config)
  local indent = load_indent()
  return indent.reindent(source, config)
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
local function _32_()
  local function _33_()
    local assert_28_auto = require("luassert")
    local value_29_auto = idempotent_3f("(foo a\n b)")
    assert_28_auto.is_truthy(value_29_auto, "(idempotent? \"(foo a\n b)\")")
    return true
  end
  require("plenary.busted").it("alignment golden is idempotent", _33_)
  local function _34_()
    local assert_28_auto = require("luassert")
    local value_29_auto = idempotent_3f("(foo \"one\n  two\"\nbar)")
    assert_28_auto.is_truthy(value_29_auto, "(idempotent? \"(foo \\\"one\n  two\\\"\nbar)\")")
    return true
  end
  require("plenary.busted").it("preservation golden is idempotent", _34_)
  local function _35_()
    local assert_28_auto = require("luassert")
    local value_29_auto = idempotent_3f("(foo\n (bar x\n y))")
    assert_28_auto.is_truthy(value_29_auto, "(idempotent? \"(foo\n (bar x\n y))\")")
    return true
  end
  require("plenary.busted").it("nested golden is idempotent", _35_)
  local function _36_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_idempotence_failures()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("one direct reindent pass is idempotent for every project source", _36_)
  local function _37_()
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
  return require("plenary.busted").it("unbalanced input returns a structured reader error", _37_)
end
require("plenary.busted").describe("idempotence-and-errors", _32_)
local function _38_()
  local function _39_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn- apply\n  [items]\n  (if (lualine.plugin)\n      (lualine.setup items)\n      (set-native-statusline items)))"
    local actual_7_auto = reindent_direct("(defn- apply\n  [items]\n  (if (lualine.plugin)\n      (lualine.setup items)\n      (set-native-statusline items)))", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("footer-bar apply keeps the hand-written default if alignment", _39_)
  local function _40_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn- text\n  [item]\n  (let [title (core.get item :title nil)\n        value (core.get item :value nil)\n        title-str (if title (core.str \"%#EcaHeaderKey#\" title \":\") \"\")\n        value-str (if value (core.str \"%#EcaHeaderValue#\" value) \"\")]\n    (core.str title-str value-str)))"
    local actual_7_auto = reindent_direct("(defn- text\n  [item]\n  (let [title (core.get item :title nil)\n        value (core.get item :value nil)\n        title-str (if title (core.str \"%#EcaHeaderKey#\" title \":\") \"\")\n        value-str (if value (core.str \"%#EcaHeaderValue#\" value) \"\")]\n    (core.str title-str value-str)))", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("lualine text keeps the hand-written let binding alignment", _40_)
end
return require("plenary.busted").describe("hand-style-fixed-points", _38_)
