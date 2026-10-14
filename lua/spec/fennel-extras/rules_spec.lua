-- [nfnl] fnl/spec/fennel-extras/rules_spec.fnl
local function load_indent()
  local ok, result = pcall(require, "fennel-extras.indent")
  if ok then
    return result
  else
    return {error = "module missing"}
  end
end
local function reindent_scenario(source, config)
  local indent = load_indent()
  if indent.error then
    return indent
  else
    local ok, result, err
    local function _2_()
      return indent.reindent(source, config)
    end
    ok, result, err = pcall(_2_)
    if ok then
      return {value = result, error = err}
    else
      return {["call-error"] = true, error = err}
    end
  end
end
local function output_for(source, config)
  local result = reindent_scenario(source, config)
  if result.error then
    return result
  else
    return result.value
  end
end
local function error_summary(source, config)
  local indent = load_indent()
  if indent.error then
    return indent
  else
    local ok, value, err
    local function _6_()
      return indent.reindent(source, config)
    end
    ok, value, err = pcall(_6_)
    return {["value?"] = (ok and (nil ~= value)), ["has-message"] = (ok and (nil == value) and (nil ~= err) and ("string" == type(err.message))), ["returned-error"] = (ok and value and (nil == value) and err)}
  end
end
local function _8_()
  local function _9_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn f\n  [x]\n  x)"
    local actual_7_auto = output_for("(defn f\n[x]\nx)", {indents = {defn = {{"inner", 0}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("applies inner zero to every continuation line", _9_)
  local function _10_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(testing \"d\"\n  body)"
    local actual_7_auto = output_for("(testing \"d\"\nbody)", {indents = {testing = {{"block", 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("applies block one to arguments after the first", _10_)
  local function _11_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(deftest t\n  (testing \"d\"\n    (is (= 1\n           1))))"
    local actual_7_auto = output_for("(deftest t\n(testing \"d\"\n(is (= 1\n1))))", {indents = {deftest = {{"block", 1}}, testing = {{"block", 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("applies block rules through nested forms and keeps default inner alignment", _11_)
  local function _12_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(testing\n \"d\"\n  body)"
    local actual_7_auto = output_for("(testing\n\"d\"\nbody)", {indents = {testing = {{"block", 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses default alignment when the first block argument starts on a new line", _12_)
  local function _13_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo a\n  b\n     c)"
    local actual_7_auto = output_for("(foo a\nb\nc)", {indents = {foo = {{"inner", 0, 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("applies inner rules to only the selected argument", _13_)
end
require("plenary.busted").describe("rule-semantics", _8_)
local function _14_()
  local function _15_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(fn [x]\n  x)"
    local actual_7_auto = output_for("(fn [x]\nx)", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses the inner built-in for fn", _15_)
  local function _16_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a 1]\n  a)"
    local actual_7_auto = output_for("(let [a 1]\na)", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses the block built-in for let", _16_)
  local function _17_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when x\n  y)"
    local actual_7_auto = output_for("(when x\ny)", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses the block built-in for when", _17_)
  local function _18_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(do\n  a\n  b)"
    local actual_7_auto = output_for("(do\na\nb)", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses the block zero built-in for do", _18_)
  local function _19_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(if c\n    a\n    b)"
    local actual_7_auto = output_for("(if c\na\nb)", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("keeps if at default alignment", _19_)
  local function _20_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn- g\n  [x]\n  x)"
    local actual_7_auto = output_for("(defn- g\n[x]\nx)", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses the def prefix fallback", _20_)
  local function _21_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(with-foo x\n  y)"
    local actual_7_auto = output_for("(with-foo x\ny)", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses the with prefix fallback", _21_)
  local function _22_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(a.let x\n       y)"
    local actual_7_auto = output_for("(a.let x\ny)", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("does not apply an unqualified fallback to a dotted head", _22_)
end
require("plenary.busted").describe("built-in-rules", _14_)
local function _23_()
  local function _24_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(my-let [a 1]\n  a)"
    local actual_7_auto = output_for("(my-let [a 1]\na)", {["format-as"] = {["my-let"] = "let"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("resolves format-as aliases", _24_)
  local function _25_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when x\n  y\n  z)"
    local actual_7_auto = output_for("(when x\ny\nz)", {indents = {when = {{"inner", 0}}}, ["indent-patterns"] = {{"^when", {{"block", 2}}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("exact indents take precedence over patterns", _25_)
  local function _26_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when x\n      y\n  z)"
    local actual_7_auto = output_for("(when x\ny\nz)", {["indent-patterns"] = {{"^when", {{"block", 2}}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("patterns take precedence over built-ins", _26_)
  local function _27_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto
    do
      local result = error_summary("(when x\ny)", {indents = {when = {{"block", 1}}}, ["format-as"] = {when = "let"}})
      actual_7_auto = {["value?"] = result["value?"], ["has-message"] = result["has-message"]}
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a name present in indents and format-as", _27_)
  local function _28_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto
    do
      local result = error_summary("(a x\ny)", {["format-as"] = {a = "b", b = "a"}})
      actual_7_auto = {["value?"] = result["value?"], ["has-message"] = result["has-message"]}
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects alias cycles", _28_)
  local function _29_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto
    do
      local result = error_summary("(a x\ny)", {["format-as"] = {a = "unknown"}})
      actual_7_auto = {["value?"] = result["value?"], ["has-message"] = result["has-message"]}
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects aliases to unknown targets", _29_)
  local function _30_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto
    do
      local result = error_summary("(foo x\ny)", {indents = {foo = {{"inner", 1}}}})
      actual_7_auto = {["value?"] = result["value?"], ["has-message"] = result["has-message"]}
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects unsupported positive inner depth", _30_)
end
return require("plenary.busted").describe("format-as-and-config-errors", _23_)
