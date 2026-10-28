-- [nfnl] fnl/spec/fennel-extras/canonical_lint_contract_spec.fnl
local config = require("fennel-extras.config")
local function validation(value)
  local ok, result, error = pcall(config.validate, value)
  return {ok = (ok and result), value = result, error = error}
end
local function error_message(result)
  local error = result.error
  if ("table" == type(error)) then
    return error.message
  else
    return error
  end
end
local canonical_rule = {lint = {rules = {["spec-direct-require"] = {{severity = "error", ["applies-to"] = {files = {"^spec/"}, forms = {"require"}, modules = {"plenary.busted"}}, options = {modules = {"plenary.busted"}, ["exempt-files"] = {"^spec/eca/macros[.]fnlm$"}}, exclusions = {}}}}}}
local function _2_()
  local function _3_()
    local result = validation(canonical_rule)
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and (nil ~= result.value))
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (not= nil (. result \"value\")))")
    return true
  end
  require("plenary.busted").it("rule instances with files, forms, and modules validate", _3_)
  local function _4_()
    local result = validation({lint = {rules = {["spec-direct-require"] = {{severity = "error", ["applies-to"] = {contexts = {"spec"}}, options = {modules = {"plenary.busted"}, ["exempt-files"] = {"^spec/eca/macros[.]fnlm$"}}, exclusions = {}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (not result.ok and (nil == result.value) and ("unknown applies-to key: contexts" == error_message(result)))
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. result \"ok\")) (= nil (. result \"value\")) (= \"unknown applies-to key: contexts\" (error-message result)))")
    return true
  end
  return require("plenary.busted").it("contexts is rejected as an unknown applies-to key", _4_)
end
require("plenary.busted").describe("canonical-applies-to-contract", _2_)
local function _5_()
  local function _6_()
    local result = validation({lint = {["spec-files"] = {"^spec/"}, rules = {}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (not result.ok and (nil == result.value) and ("unknown lint key: spec-files" == error_message(result)))
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. result \"ok\")) (= nil (. result \"value\")) (= \"unknown lint key: spec-files\" (error-message result)))")
    return true
  end
  require("plenary.busted").it("top-level lint spec-files is absent from the canonical contract", _6_)
  local function _7_()
    local result = validation(canonical_rule)
    local value = result.value
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and value and (nil == value.lint["spec-files"]) and vim.deep_equal({"^spec/"}, value.lint.rules["spec-direct-require"][1]["applies-to"].files))
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") value (= nil (. value \"lint\" \"spec-files\")) (vim.deep_equal [\"^spec/\"] (. value \"lint\" \"rules\" \"spec-direct-require\" 1 \"applies-to\" \"files\")))")
    return true
  end
  return require("plenary.busted").it("spec-only behavior uses explicit file regexes", _7_)
end
return require("plenary.busted").describe("canonical-spec-file-contract", _5_)
