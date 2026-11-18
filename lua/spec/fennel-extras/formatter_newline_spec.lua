-- [nfnl] fnl/spec/fennel-extras/formatter_newline_spec.fnl
local config = require("fennel-extras.config")
local format = require("fennel-extras.format")
local parser = require("eca.nfnl.fennel")
local ast_equal_3f = format["ast-equal?"]
local base_config = {["indent-width"] = 2, indents = {defn = {{"block", 1}}, testing = {{"block", 1}}}, newline = {{["applies-to"] = {forms = {"fn", "defn", "defn-"}}, options = {["after-header"] = 1}}, {["applies-to"] = {forms = {"testing"}}, options = {before = 1}}}, parser = false}
local split_config = {["indent-width"] = 2, indents = {}, alignment = {bindings = true, ["split-bindings"] = true, ["binding-forms"] = {"let", "when-let", "if-let", "with-open"}, ["clause-forms"] = {"case", "cond", "match", "case-try", "match-try", "if"}, clauses = false, ["collapse-padding"] = false, maps = false}, parser = false}
local function formatted_body(format0, source)
  return format0["format-string"](source, {config = base_config})
end
local function formatted(source)
  local ok, value = pcall(formatted_body, format, source)
  if ok then
    return value
  else
    return nil
  end
end
local function formatted_split_body(formatter, source)
  return formatter["format-string"](source, {config = split_config})
end
local function formatted_with_config(formatter, source, config0)
  local function _2_(pattern, path)
    local regex = vim.regex(pattern)
    return (nil ~= regex:match_str(path))
  end
  return formatter["format-string"](source, {config = config0, matcher = _2_, path = config0.path})
end
local function repository_format()
  return assert(config.load(".fnl-extras.fnl")).format
end
local function formatted_split(source)
  local ok, value = pcall(formatted_split_body, format, source)
  if ok then
    return value
  else
    return nil
  end
end
local function _4_()
  local function _5_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn run\n\n  []\n  true)\n(foo)"
    local actual_7_auto = formatted("(defn run\n[]\ntrue)\n(foo)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("after-header inserts a break before defn arguments", _5_)
  local function _6_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo)\n\n(testing \"works\"\n  (is true))"
    local actual_7_auto = formatted("(foo)\n(testing \"works\"\n(is true))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("newline before applies to testing forms", _6_)
  local function _7_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when-let [a 1\n           b 2] a)"
    local actual_7_auto = formatted_split("(when-let [a 1 b 2] a)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("split-bindings separates configured binding pairs", _7_)
end
require("plenary.busted").describe("formatter-newline-contract", _4_)
local function _8_()
  local config0 = {["indent-width"] = 2, indents = {fn = {{"inner", 0}}, defn = {{"block", 1}}, ["defn-"] = {{"block", 1}}}, newline = {{["applies-to"] = {forms = {"fn", "defn", "defn-"}}, options = {["after-header"] = 1}}}, parser = false}
  local function _9_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(fn\n\n  []\n  true)"
    local actual_7_auto = formatted_with_config(format, "(fn\n[]\ntrue)", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("after-header inserts a break before multiline fn arguments", _9_)
  local function _10_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn run\n\n  []\n  true)"
    local actual_7_auto = formatted_with_config(format, "(defn run\n[]\ntrue)", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("after-header inserts a break before multiline defn arguments", _10_)
  local function _11_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn- run\n\n  []\n  true)"
    local actual_7_auto = formatted_with_config(format, "(defn- run\n[]\ntrue)", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("after-header inserts a break before multiline defn- arguments", _11_)
  local function _12_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn run [] true)"
    local actual_7_auto = formatted_with_config(format, "(defn run [] true)", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("after-header does not add a trailing break to one-line defn", _12_)
  local function _13_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn- run [] true)"
    local actual_7_auto = formatted_with_config(format, "(defn- run [] true)", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("after-header does not add a trailing break to one-line defn-", _13_)
end
require("plenary.busted").describe("header-newline-contract", _8_)
local function _14_()
  local function _15_()
    local config0 = {["indent-width"] = 2, indents = {fn = {{"inner", 0}}}, newline = {{["applies-to"] = {forms = {"fn"}}, options = {["after-header"] = 0}}}, parser = false}
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(fn\n  []\n  true)"
    local actual_7_auto = formatted_with_config(format, "(fn\n\n\n[]\ntrue)", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("after-header zero removes contiguous existing blank lines after a selected fn header", _15_)
  local function _16_()
    local config0 = {["indent-width"] = 2, indents = {fn = {{"inner", 0}}}, newline = {{["applies-to"] = {forms = {"fn"}}, options = {}}}, parser = false}
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(fn\n\n  []\n  true)"
    local actual_7_auto = formatted_with_config(format, "(fn\n\n[]\ntrue)", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("omitted after-header preserves existing blank lines after a selected fn header", _16_)
end
require("plenary.busted").describe("explicit-zero-header-newline", _14_)
local function _17_()
  local config0 = {["indent-width"] = 2, indents = {defn = {{"block", 1}}, ["defn-"] = {{"block", 1}}}, newline = {{["applies-to"] = {forms = {"defn", "defn-"}}, options = {["break-after-n-args"] = {{1, 1}, {2, 1}}}}}, parser = false}
  local function _18_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn parse-string\n  [text]\n  (parse.parse-string text))"
    local actual_7_auto = formatted_with_config(format, "(defn parse-string [text] (parse.parse-string text))", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("break-after-n-args canonicalizes direct defn argument boundaries", _18_)
  local function _19_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn- parse-string\n  [text]\n  (parse.parse-string text))"
    local actual_7_auto = formatted_with_config(format, "(defn- parse-string [text] (parse.parse-string text))", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("break-after-n-args canonicalizes direct defn- argument boundaries", _19_)
  local function _20_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn parse-string\n  [text]\n  (parse.parse-string text))"
    local actual_7_auto = formatted_with_config(format, "(defn parse-string\n[text]\n(parse.parse-string text))", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("break-after-n-args canonicalizes already-varied input layouts", _20_)
  local function _21_()
    local without_option = {["indent-width"] = 2, indents = {defn = {{"block", 1}}}, parser = false}
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn parse-string [text] (parse.parse-string text))"
    local actual_7_auto = formatted_with_config(format, "(defn parse-string [text] (parse.parse-string text))", without_option)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("break-after-n-args is opt-in", _21_)
  local function _22_()
    local formatted0 = formatted_with_config(format, "(defn parse-string [text] (parse.parse-string text))", config0)
    local assert_5_auto = require("luassert")
    local expected_6_auto = formatted0
    local actual_7_auto = formatted_with_config(format, formatted0, config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("break-after-n-args canonicalization is idempotent", _22_)
  local function _23_()
    local assert_28_auto = require("luassert")
    local value_29_auto = ast_equal_3f(parser, "(defn parse-string [text] (parse.parse-string text))", formatted_with_config(format, "(defn parse-string [text] (parse.parse-string text))", config0))
    assert_28_auto.is_truthy(value_29_auto, "(ast-equal? parser \"(defn parse-string [text] (parse.parse-string text))\" (formatted-with-config format \"(defn parse-string [text] (parse.parse-string text))\" config))")
    return true
  end
  return require("plenary.busted").it("break-after-n-args preserves parsed forms", _23_)
end
require("plenary.busted").describe("break-after-n-args", _17_)
local function _24_()
  local config0
  do
    local tmp_9_ = repository_format()
    tmp_9_["path"] = "fennel-extras/format.fnl"
    config0 = tmp_9_
  end
  local function _25_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [result (pcall (fn [] true))\n      other  2] result)"
    local actual_7_auto = formatted_with_config(format, "(let [result (pcall (fn [] true)) other 2] result)", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("keeps an anonymous fn value inline while aligning let bindings", _25_)
  local function _26_()
    local source = "(let [result (pcall (fn [] true)) other 2] result)"
    local formatted0 = formatted_with_config(format, source, config0)
    local assert_5_auto = require("luassert")
    local expected_6_auto = formatted0
    local actual_7_auto = formatted_with_config(format, formatted0, config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("anonymous fn formatting is idempotent", _26_)
end
require("plenary.busted").describe("anonymous-fn-break-after-n-args", _24_)
local function _27_()
  local config0 = {["indent-width"] = 2, indents = {["="] = {{"inner", 0}}}, newline = {{["applies-to"] = {files = {"^spec/"}, forms = {"="}}, options = {["break-after-args"] = 1}}}, parser = false}
  local path_config
  do
    config0["path"] = "spec/fennel-extras/formatter_newline_spec.fnl"
    path_config = config0
  end
  local function _28_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(= expected\n   actual)"
    local actual_7_auto = formatted_with_config(format, "(= expected actual)", path_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("break-after-args inserts one break between adjacent direct arguments", _28_)
  local function _29_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(= a\n   b\n   c)"
    local actual_7_auto = formatted_with_config(format, "(= a b c)", path_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("break-after-args breaks every adjacent boundary except after the final argument", _29_)
  local function _30_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(= \"\"\n   (. (context-item.render {}) :text))"
    local actual_7_auto = formatted_with_config(format, "(= \"\" (. (context-item.render {}) :text))", path_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("break-after-args breaks after a string first argument", _30_)
  local function _31_()
    local without_option = {["indent-width"] = 2, indents = {["="] = {{"inner", 0}}}, path = "spec/fennel-extras/formatter_newline_spec.fnl", parser = false}
    local source = "(= expected actual)"
    local assert_5_auto = require("luassert")
    local expected_6_auto = source
    local actual_7_auto = formatted_with_config(format, source, without_option)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("omitting break-after-args preserves the source layout", _31_)
end
require("plenary.busted").describe("scalar-break-after-args", _27_)
local function _32_()
  local config0 = {["indent-width"] = 2, indents = {cond = {{"inner", 0}}}, newline = {{["applies-to"] = {forms = {"cond"}}, options = {["group-size"] = 2, ["group-gap"] = 1}}}, parser = false}
  local function _33_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(cond\n  a\n  b\n\n  c\n  d\n\n  e)"
    local actual_7_auto = formatted_with_config(format, "(cond a b c d e)", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("puts the head and every direct argument on separate lines", _33_)
  local function _34_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(cond\n  a\n  (foo b)\n\n  c\n  (bar d)\n\n  e)"
    local actual_7_auto = formatted_with_config(format, "(cond a (foo b) c (bar d) e)", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("treats nested forms as one direct argument and preserves indentation", _34_)
  local function _35_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(cond ;; first\n  a\n  b ;; interior\n  c\n  d\n\n  e)"
    local actual_7_auto = formatted_with_config(format, "(cond ;; first\n a b ;; interior\n c d e)", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("comments are barriers at first and interior boundaries", _35_)
  local function _36_()
    local composed
    do
      config0["newline"] = {{["applies-to"] = {forms = {"cond"}}, options = {["group-size"] = 2, ["group-gap"] = 1}}, {["applies-to"] = {forms = {"cond"}}, options = {["break-after-args"] = 1}}}
      composed = config0
    end
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(cond\n  a\n  b\n\n  c\n  d\n\n  e)"
    local actual_7_auto = formatted_with_config(format, "(cond a b c d e)", composed)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("composes with scalar and indexed argument breaks", _36_)
  local function _37_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(cond\n  'a\n  ~b\n\n  c\n  d)"
    local actual_7_auto = formatted_with_config(format, "(cond 'a ~b c d)", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("keeps quote and unquote prefixes with their argument", _37_)
  local function _38_()
    local source = "(cond a (foo b) c (bar d) e)"
    local formatted0 = formatted_with_config(format, source, config0)
    local assert_5_auto = require("luassert")
    local expected_6_auto = formatted0
    local actual_7_auto = formatted_with_config(format, formatted0, config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("is idempotent", _38_)
  local function _39_()
    local source = "(cond a (foo b) c (bar d) e)"
    local formatted0 = formatted_with_config(format, source, config0)
    local assert_28_auto = require("luassert")
    local value_29_auto = ast_equal_3f(parser, source, formatted0)
    assert_28_auto.is_truthy(value_29_auto, "(ast-equal? parser source formatted)")
    return true
  end
  return require("plenary.busted").it("preserves AST", _39_)
end
require("plenary.busted").describe("grouped-argument-newline", _32_)
local function _40_()
  local config0 = {["indent-width"] = 2, newline = {{["applies-to"] = {forms = {"cond"}}, options = {["group-size"] = 2, ["group-gap"] = 1}}}, parser = false}
  local function _41_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(cond\n  a\n  b\n\n  c\n  d)\n"
    local actual_7_auto = formatted_with_config(format, "(cond a b c d)\n", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("preserves a terminal newline", _41_)
  local function _42_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(cond\n  a\n  b\n\n  c\n  d)"
    local actual_7_auto = formatted_with_config(format, "(cond a b c d)", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("preserves the absence of a terminal newline", _42_)
end
require("plenary.busted").describe("grouped-argument-terminal-newline", _40_)
local function _43_()
  local function _44_()
    local config0 = {["indent-width"] = 2, indents = {fn = {{"inner", 0}}}, ["format-as"] = {["my-fn"] = "fn"}, newline = {{["applies-to"] = {forms = {"fn"}}, options = {after = 1}}}, parser = false}
    local source = "(my-fn []\ntrue)\n(foo)"
    local result = formatted_with_config(format, source, config0)
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(my-fn []\n  true)\n(foo)"
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("an exact alias formats through its target without inheriting newline membership", _44_)
end
require("plenary.busted").describe("exact-alias-newline-membership", _43_)
local function _45_()
  local config0 = {["indent-width"] = 2, indents = {defn = {{"block", 1}}, testing = {{"block", 1}}}, newline = {{["applies-to"] = {files = {"^fennel-extras/"}, forms = {"fn", "defn", "defn-"}}, options = {["after-header"] = 1}}}, parser = false}
  local function _46_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn run\n\n  []\n  true)"
    local actual_7_auto
    local function _47_()
      config0["path"] = "fennel-extras/format.fnl"
      return config0
    end
    actual_7_auto = formatted_with_config(format, "(defn run\n  []\n  true)", _47_())
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("file selector uses workspace-relative paths and ANDs files with forms", _46_)
  local function _48_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(testing \"works\"\n  (is true))"
    local actual_7_auto
    local function _49_()
      config0["path"] = "fennel-extras/format.fnl"
      return config0
    end
    actual_7_auto = formatted_with_config(format, "(testing \"works\"\n  (is true))", _49_())
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("form selector does not apply outside its forms", _48_)
  local function _50_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn run\n  []\n  true)"
    local actual_7_auto
    local function _51_()
      config0["path"] = "eca/format.fnl"
      return config0
    end
    actual_7_auto = formatted_with_config(format, "(defn run\n  []\n  true)", _51_())
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("file selector does not apply outside its path", _50_)
end
require("plenary.busted").describe("file-scoped-newline-membership", _45_)
local function _52_()
  local config0 = {["indent-width"] = 2, indents = {defn = {{"block", 1}}, ["defn-"] = {{"block", 1}}}, newline = {{["applies-to"] = {forms = {"defn", "defn-"}}, options = {["between-same-level"] = 1}}}, parser = false}
  local function _53_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn one [] true)\n\n(defn- two [] true)"
    local actual_7_auto = formatted_with_config(format, "(defn one [] true)\n\n\n\n(defn- two [] true)", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("normalizes excessive blank lines between selected top-level siblings", _53_)
  local function _54_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn one [] true)\n\n(defn- two [] true)"
    local actual_7_auto = formatted_with_config(format, "(defn one [] true)\n(defn- two [] true)", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("adds the requested blank line between adjacent selected top-level siblings", _54_)
  local function _55_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn one [] true)\n\n(defn two [] true)"
    local actual_7_auto = formatted_with_config(format, "(defn one [] true) (defn two [] true)", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("places one blank line between selected siblings that share a physical line", _55_)
  local function _56_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo (defn one [] true)\n\n     (defn- two [] true))"
    local actual_7_auto = formatted_with_config(format, "(foo (defn one [] true)\n\n\n(defn- two [] true))", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("normalizes selected siblings under an unselected nested parent", _56_)
  local function _57_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "; keep this comment\n(foo)\n\n\n(defn one [] true)\n\n(defn- two [] true)"
    local actual_7_auto = formatted_with_config(format, "; keep this comment\n(foo)\n\n\n(defn one [] true)\n(defn- two [] true)", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("does not change unselected top-level forms or comments", _57_)
end
require("plenary.busted").describe("between-same-level-newline", _52_)
local function _58_()
  local config0 = {["indent-width"] = 2, indents = {deftest = {{"block", 1}}, testing = {{"block", 1}}}, newline = {{["applies-to"] = {forms = {"deftest", "testing"}}, options = {["between-same-level"] = 1}}}, parser = false}
  local function _59_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(deftest sample\n  (testing \"one\"\n    (is true))\n\n  (testing \"two\"\n    (is true)))"
    local actual_7_auto = formatted_with_config(format, "(deftest sample\n  (testing \"one\"\n    (is true))\n  (testing \"two\"\n    (is true)))", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("separates sibling testing forms by exactly one blank line", _59_)
  local function _60_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(deftest sample\n\n\n  (testing \"one\"\n    (is true)))"
    local actual_7_auto = formatted_with_config(format, "(deftest sample\n\n\n  (testing \"one\"\n    (is true)))", config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not normalize the gap between a parent deftest and child testing", _60_)
  local function _61_()
    local testing_config = {["indent-width"] = 2, indents = {testing = {{"block", 1}}}, newline = {{["applies-to"] = {forms = {"testing"}}, options = {["between-same-level"] = 1}}}, parser = false}
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo (testing one)\n\n     (testing two))"
    local actual_7_auto = formatted_with_config(format, "(foo (testing one) (testing two))", testing_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("normalizes selected testing siblings under an unselected parent", _61_)
end
require("plenary.busted").describe("between-same-level-nested-newline", _58_)
local function _62_()
  local function _63_()
    local config0 = {["indent-width"] = 2, indents = {defn = {{"block", 1}}, ["defn-"] = {{"block", 1}}}, parser = false}
    local source = "(defn one [] true)\n\n\n(defn- two [] true)"
    local assert_5_auto = require("luassert")
    local expected_6_auto = source
    local actual_7_auto = formatted_with_config(format, source, config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("omitting between-same-level preserves the existing top-level gap", _63_)
end
require("plenary.busted").describe("omitted-between-same-level-newline", _62_)
local function _64_()
  local config0 = {["indent-width"] = 2, indents = {deftest = {{"block", 1}}, testing = {{"block", 1}}}, newline = {{["applies-to"] = {forms = {"deftest"}}, options = {["after-header"] = 0}}, {["applies-to"] = {forms = {"testing"}}, options = {["between-same-level"] = 1}}}, parser = false}
  local source = "(deftest render\n\n  (testing one)\n\n  (testing two))"
  local function _65_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(deftest render\n  (testing one)\n\n  (testing two))"
    local actual_7_auto = formatted_with_config(format, source, config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("after-header zero removes the blank line after the deftest header", _65_)
  local function _66_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(deftest render\n  (testing one)\n\n  (testing two))"
    local actual_7_auto = formatted_with_config(format, source, config0)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("between-same-level leaves no parent-child blank line and one sibling blank line", _66_)
end
require("plenary.busted").describe("configured-deftest-and-testing-spacing", _64_)
local function _67_()
  local config0 = {["indent-width"] = 2, indents = {cond = {{"inner", 0}}}, newline = {{["applies-to"] = {forms = {"cond"}}, options = {["group-size"] = 2, ["group-gap"] = 1}}}, parser = false}
  local assert_5_auto = require("luassert")
  local expected_6_auto = "(cond\n  #\"a\"\n  #_(skip)\n\n  b\n  c\n\n  d)"
  local actual_7_auto = formatted_with_config(format, "(cond #\"a\" #_(skip) b c d)", config0)
  assert_5_auto.same(expected_6_auto, actual_7_auto)
  return true
end
return require("plenary.busted").describe("grouped-reader-prefix-regression", _67_)
