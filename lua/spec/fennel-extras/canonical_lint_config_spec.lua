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
    local result = validation({lint = {["spec-files"] = {"^spec/"}, rules = {}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (not result.ok and ("unknown lint key: spec-files" == error_message(result)))
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. result \"ok\")) (= \"unknown lint key: spec-files\" (error-message result)))")
    return true
  end
  return require("plenary.busted").it("a top-level spec-files key is rejected", _3_)
end
require("plenary.busted").describe("canonical-rule-shape", _2_)
local function _4_()
  local function _5_()
    local result = validation({lint = {rules = {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {files = {"^fnl/"}, forms = {"require"}, modules = {"plenary.busted"}}, options = {}, exclusions = {}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and result.value)
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (. result \"value\"))")
    return true
  end
  require("plenary.busted").it("files, forms, and modules are accepted", _5_)
  local function _6_()
    local result = validation({lint = {rules = {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {contexts = {"all"}}, options = {module = "require"}, exclusions = {}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (not result.ok and ("unknown applies-to key: contexts" == error_message(result)))
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. result \"ok\")) (= \"unknown applies-to key: contexts\" (error-message result)))")
    return true
  end
  return require("plenary.busted").it("contexts is rejected", _6_)
end
require("plenary.busted").describe("canonical-applies-to", _4_)
local function _7_()
  local function _8_()
    local result = validation({lint = {rules = {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {}, exclusions = {{path = "^spec/", code = "^[(]if", form = "spec/app.fnl > if#1", reason = "intentional"}}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and result.value)
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (. result \"value\"))")
    return true
  end
  require("plenary.busted").it("path, code, form, and reason selectors are accepted as strings", _8_)
  local function _9_()
    local result = validation({lint = {rules = {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {}, exclusions = {{path = {"^spec/"}, code = true, form = 1, reason = "intentional"}}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (not result.ok and ("lint.rules.forbidden-form[1].exclusions[1] requires string path and reason; optional code and form must be strings" == error_message(result)))
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. result \"ok\")) (= \"lint.rules.forbidden-form[1].exclusions[1] requires string path and reason; optional code and form must be strings\" (error-message result)))")
    return true
  end
  return require("plenary.busted").it("exclusion selectors require string values", _9_)
end
return require("plenary.busted").describe("canonical-exclusions", _7_)
