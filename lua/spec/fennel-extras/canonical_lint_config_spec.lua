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
    local result = validation({lint = {rules = {["form-chain"] = {{severity = "warning", ["applies-to"] = {files = {"^fnl/"}, forms = {"require"}, modules = {"plenary.busted"}}, options = {["allowed-chains"] = {{"<form>"}}}, exclusions = {}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and result.value)
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (. result \"value\"))")
    return true
  end
  require("plenary.busted").it("files, forms, and modules are accepted", _5_)
  local function _6_()
    local result = validation({lint = {rules = {["form-chain"] = {{severity = "warning", ["applies-to"] = {contexts = {"all"}}, options = {module = "require"}, exclusions = {}}}}}})
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
    local result = validation({lint = {rules = {["form-chain"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {["allowed-chains"] = {{"<form>"}}}, exclusions = {{path = "^spec/"}}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and result.value)
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (. result \"value\"))")
    return true
  end
  require("plenary.busted").it("path-only exclusions are accepted", _8_)
  local function _9_()
    local base = {severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {["allowed-chains"] = {{"<form>"}}}}
    local keys = {"reason", "code", "form"}
    local rejected
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, key in ipairs(keys) do
        local val_28_
        do
          local exclusion = {path = "^spec/"}
          exclusion[key] = "old contract"
          local result = validation({lint = {rules = {["form-chain"] = {{severity = base.severity, ["applies-to"] = base["applies-to"], options = base.options, exclusions = {exclusion}}}}}})
          val_28_ = (not result.ok and error_message(result))
        end
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      rejected = tbl_26_
    end
    local assert_5_auto = require("luassert")
    local expected_6_auto = 3
    local actual_7_auto = #rejected
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("old exclusion keys are rejected", _9_)
  local function _11_()
    local result = validation({lint = {rules = {["form-chain"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {["allowed-chains"] = {{"<form>"}}}, exclusions = {{path = {"^spec/"}}}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = not result.ok
    assert_28_auto.is_truthy(value_29_auto, "(not (. result \"ok\"))")
    return true
  end
  require("plenary.busted").it("non-string path values are rejected", _11_)
  local function _12_()
    local old_result = validation({lint = {rules = {["module-import"] = {{severity = "error", ["applies-to"] = {modules = {"fennel-extras.macros.test"}}, options = {mode = "require", binding = "macros", ["exempt-files"] = {"^spec/"}}, exclusions = {}}}}}})
    local new_result = validation({lint = {rules = {["module-import"] = {{severity = "error", ["applies-to"] = {modules = {"fennel-extras.macros.test"}}, options = {mode = "require", binding = "macros"}, exclusions = {{path = "^fennel-extras/macros/test[.]fnlm$"}}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (not old_result.ok and new_result.ok and new_result.value)
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. old-result \"ok\")) (. new-result \"ok\") (. new-result \"value\"))")
    return true
  end
  return require("plenary.busted").it("module-import rejects exempt-files and accepts a path-only exclusion", _12_)
end
return require("plenary.busted").describe("canonical-exclusions", _7_)
