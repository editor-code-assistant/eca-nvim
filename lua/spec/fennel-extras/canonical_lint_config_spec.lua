-- [nfnl] fnl/spec/fennel-extras/canonical_lint_config_spec.fnl
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
local function _2_()
  local function _3_()
    local result = validation({lint = {rules = {}}, design = {rules = {["if-without-else"] = {{severity = "warning", ["applies-to"] = {}, options = {forms = {"if"}, ["nil-else"] = true}, exclusions = {}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and result.value)
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (. result \"value\"))")
    return true
  end
  require("plenary.busted").it("rules use keyword keys and non-empty vectors of instances", _3_)
  local function _4_()
    local result = validation({lint = {["spec-files"] = {"^spec/"}, rules = {}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (not result.ok and ("unknown lint key: spec-files" == error_message(result)))
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. result \"ok\")) (= \"unknown lint key: spec-files\" (error-message result)))")
    return true
  end
  return require("plenary.busted").it("a top-level spec-files key is rejected", _4_)
end
require("plenary.busted").describe("canonical-rule-shape", _2_)
local function _5_()
  local function _6_()
    local result = validation({lint = {rules = {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {files = {"^fnl/"}, forms = {"require"}, modules = {"plenary.busted"}}, options = {module = "require"}, exclusions = {}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and result.value)
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (. result \"value\"))")
    return true
  end
  require("plenary.busted").it("files, forms, and modules are accepted", _6_)
  local function _7_()
    local result = validation({lint = {rules = {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {contexts = {"all"}}, options = {module = "require"}, exclusions = {}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (not result.ok and ("unknown applies-to key: contexts" == error_message(result)))
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. result \"ok\")) (= \"unknown applies-to key: contexts\" (error-message result)))")
    return true
  end
  return require("plenary.busted").it("contexts is rejected", _7_)
end
return require("plenary.busted").describe("canonical-applies-to", _5_)
