-- [nfnl] fnl/spec/fennel-extras/formatter_newline_spec.fnl
local format = require("fennel-extras.format")
local base_config = {["indent-width"] = 2, indents = {defn = {{"block", 1}}, ["defn-"] = {{"block", 1}}, fn = {{"block", 1}}, testing = {{"block", 1}}}, newline = {{["applies-to"] = {forms = {"fn", "defn", "defn-"}}, options = {after = 1}}, {["applies-to"] = {forms = {"testing"}}, options = {before = 1}}}, builtins = false, parser = false, ["prefix-fallbacks"] = false}
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
local function _2_()
  local function _3_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn run []\n  true)\n\n(foo)"
    local actual_7_auto = formatted("(defn run []\ntrue)\n(foo)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("newline after applies to function forms", _3_)
  local function _4_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo)\n\n(testing \"works\"\n  (is true))"
    local actual_7_auto = formatted("(foo)\n(testing \"works\"\n(is true))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("newline before applies to testing forms", _4_)
end
return require("plenary.busted").describe("formatter-newline-contract", _2_)
