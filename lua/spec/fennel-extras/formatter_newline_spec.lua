-- [nfnl] fnl/spec/fennel-extras/formatter_newline_spec.fnl
local format = require("fennel-extras.format")
local base_config = {["indent-width"] = 2, indents = {defn = {{"block", 1}}, testing = {{"block", 1}}}, newline = {{["applies-to"] = {forms = {"fn", "defn", "defn-"}}, options = {after = 1}}, {["applies-to"] = {forms = {"testing"}}, options = {before = 1}}}, builtins = false, parser = false, ["prefix-fallbacks"] = false}
local split_config = {["indent-width"] = 2, indents = {}, alignment = {bindings = true, ["split-bindings"] = true, ["binding-forms"] = {"let", "when-let", "if-let", "with-open"}, ["clause-forms"] = {"case", "match", "case-try", "match-try", "if"}, clauses = false, ["collapse-padding"] = false, maps = false}, builtins = false, parser = false, ["prefix-fallbacks"] = false}
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
local function formatted_split(source)
  local ok, value = pcall(formatted_split_body, format, source)
  if ok then
    return value
  else
    return nil
  end
end
local function _3_()
  local function _4_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn run []\n  true)\n\n(foo)"
    local actual_7_auto = formatted("(defn run []\ntrue)\n(foo)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("newline after applies to function forms", _4_)
  local function _5_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo)\n\n(testing \"works\"\n  (is true))"
    local actual_7_auto = formatted("(foo)\n(testing \"works\"\n(is true))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("newline before applies to testing forms", _5_)
  local function _6_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when-let [a 1\n           b 2] a)"
    local actual_7_auto = formatted_split("(when-let [a 1 b 2] a)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("split-bindings separates configured binding pairs", _6_)
end
return require("plenary.busted").describe("formatter-newline-contract", _3_)
