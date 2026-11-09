-- [nfnl] fnl/spec/fennel-extras/formatter_newline_spec.fnl
local format = require("fennel-extras.format")
local parser = require("eca.nfnl.fennel")
local base_config = {["indent-width"] = 2, indents = {defn = {{"block", 1}}, testing = {{"block", 1}}}, newline = {{["applies-to"] = {forms = {"fn", "defn", "defn-"}}, options = {["after-header"] = 1}}, {["applies-to"] = {forms = {"testing"}}, options = {before = 1}}}, parser = false}
local split_config = {["indent-width"] = 2, indents = {}, alignment = {bindings = true, ["split-bindings"] = true, ["binding-forms"] = {"let", "when-let", "if-let", "with-open"}, ["clause-forms"] = {"case", "match", "case-try", "match-try", "if"}, clauses = false, ["collapse-padding"] = false, maps = false}, parser = false}
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
local function formatted_with_config(formatter, source, config)
  local function _2_(pattern, path)
    local regex = vim.regex(pattern)
    return (nil ~= regex:match_str(path))
  end
  return formatter["format-string"](source, {config = config, matcher = _2_, path = config.path})
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
  local config = {["indent-width"] = 2, indents = {fn = {{"inner", 0}}, defn = {{"block", 1}}, ["defn-"] = {{"block", 1}}}, newline = {{["applies-to"] = {forms = {"fn", "defn", "defn-"}}, options = {["after-header"] = 1}}}, parser = false}
  local function _9_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(fn\n\n  []\n  true)"
    local actual_7_auto = formatted_with_config(format, "(fn\n[]\ntrue)", config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("after-header inserts a break before multiline fn arguments", _9_)
  local function _10_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn run\n\n  []\n  true)"
    local actual_7_auto = formatted_with_config(format, "(defn run\n[]\ntrue)", config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("after-header inserts a break before multiline defn arguments", _10_)
  local function _11_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn- run\n\n  []\n  true)"
    local actual_7_auto = formatted_with_config(format, "(defn- run\n[]\ntrue)", config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("after-header inserts a break before multiline defn- arguments", _11_)
  local function _12_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn run [] true)"
    local actual_7_auto = formatted_with_config(format, "(defn run [] true)", config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("after-header does not add a trailing break to one-line defn", _12_)
  local function _13_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn- run [] true)"
    local actual_7_auto = formatted_with_config(format, "(defn- run [] true)", config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("after-header does not add a trailing break to one-line defn-", _13_)
end
require("plenary.busted").describe("header-newline-contract", _8_)
local function _14_()
  local function _15_()
    local config = {["indent-width"] = 2, indents = {fn = {{"inner", 0}}}, newline = {{["applies-to"] = {forms = {"fn"}}, options = {["after-header"] = 0}}}, parser = false}
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(fn\n  []\n  true)"
    local actual_7_auto = formatted_with_config(format, "(fn\n\n\n[]\ntrue)", config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("after-header zero removes contiguous existing blank lines after a selected fn header", _15_)
  local function _16_()
    local config = {["indent-width"] = 2, indents = {fn = {{"inner", 0}}}, newline = {{["applies-to"] = {forms = {"fn"}}, options = {}}}, parser = false}
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(fn\n\n  []\n  true)"
    local actual_7_auto = formatted_with_config(format, "(fn\n\n[]\ntrue)", config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("omitted after-header preserves existing blank lines after a selected fn header", _16_)
end
require("plenary.busted").describe("explicit-zero-header-newline", _14_)
local function _17_()
  local config = {["indent-width"] = 2, indents = {defn = {{"block", 1}}}, newline = {{["applies-to"] = {forms = {"defn"}}, options = {["break-after-args"] = {{1, 1}, {2, 1}}}}}, parser = false}
  local function _18_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn parse-string\n  [text]\n  (parse.parse-string text))"
    local actual_7_auto = formatted_with_config(format, "(defn parse-string [text] (parse.parse-string text))", config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("break-after-args canonicalizes direct defn argument boundaries", _18_)
  local function _19_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn parse-string\n  [text]\n  (parse.parse-string text))"
    local actual_7_auto = formatted_with_config(format, "(defn parse-string\n[text]\n(parse.parse-string text))", config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("break-after-args canonicalizes already-varied input layouts", _19_)
  local function _20_()
    local without_option = {["indent-width"] = 2, indents = {defn = {{"block", 1}}}, parser = false}
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn parse-string [text] (parse.parse-string text))"
    local actual_7_auto = formatted_with_config(format, "(defn parse-string [text] (parse.parse-string text))", without_option)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("break-after-args is opt-in", _20_)
  local function _21_()
    local formatted0 = formatted_with_config(format, "(defn parse-string [text] (parse.parse-string text))", config)
    local assert_5_auto = require("luassert")
    local expected_6_auto = formatted0
    local actual_7_auto = formatted_with_config(format, formatted0, config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("break-after-args canonicalization is idempotent", _21_)
  local function _22_()
    local assert_28_auto = require("luassert")
    local value_29_auto = format["ast-equal?"](parser, "(defn parse-string [text] (parse.parse-string text))", formatted_with_config(format, "(defn parse-string [text] (parse.parse-string text))", config))
    assert_28_auto.is_truthy(value_29_auto, "(format.ast-equal? parser \"(defn parse-string [text] (parse.parse-string text))\" (formatted-with-config format \"(defn parse-string [text] (parse.parse-string text))\" config))")
    return true
  end
  return require("plenary.busted").it("break-after-args preserves parsed forms", _22_)
end
require("plenary.busted").describe("break-after-args", _17_)
local function _23_()
  local function _24_()
    local config = {["indent-width"] = 2, indents = {fn = {{"inner", 0}}}, ["format-as"] = {["my-fn"] = "fn"}, newline = {{["applies-to"] = {forms = {"fn"}}, options = {after = 1}}}, parser = false}
    local source = "(my-fn []\ntrue)\n(foo)"
    local result = formatted_with_config(format, source, config)
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(my-fn []\n  true)\n(foo)"
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("an exact alias formats through its target without inheriting newline membership", _24_)
end
require("plenary.busted").describe("exact-alias-newline-membership", _23_)
local function _25_()
  local config = {["indent-width"] = 2, indents = {defn = {{"block", 1}}, testing = {{"block", 1}}}, newline = {{["applies-to"] = {files = {"^fennel-extras/"}, forms = {"fn", "defn", "defn-"}}, options = {["after-header"] = 1}}}, parser = false}
  local function _26_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn run\n\n  []\n  true)"
    local actual_7_auto
    local function _27_()
      config["path"] = "fennel-extras/format.fnl"
      return config
    end
    actual_7_auto = formatted_with_config(format, "(defn run\n  []\n  true)", _27_())
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("file selector uses workspace-relative paths and ANDs files with forms", _26_)
  local function _28_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(testing \"works\"\n  (is true))"
    local actual_7_auto
    local function _29_()
      config["path"] = "fennel-extras/format.fnl"
      return config
    end
    actual_7_auto = formatted_with_config(format, "(testing \"works\"\n  (is true))", _29_())
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("form selector does not apply outside its forms", _28_)
  local function _30_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn run\n  []\n  true)"
    local actual_7_auto
    local function _31_()
      config["path"] = "eca/format.fnl"
      return config
    end
    actual_7_auto = formatted_with_config(format, "(defn run\n  []\n  true)", _31_())
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("file selector does not apply outside its path", _30_)
end
return require("plenary.busted").describe("file-scoped-newline-membership", _25_)
