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
local canonical_rule = {lint = {rules = {["module-import"] = {{severity = "error", ["applies-to"] = {files = {"^spec/"}, forms = {"require"}, modules = {"plenary.busted"}}, options = {mode = "forbid", modules = {"plenary.busted"}, ["exempt-files"] = {"^spec/eca/macros[.]fnlm$"}}, exclusions = {}}}}}}
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
    local result = validation({lint = {rules = {["module-import"] = {{severity = "error", ["applies-to"] = {contexts = {"spec"}}, options = {mode = "forbid", modules = {"plenary.busted"}, ["exempt-files"] = {"^spec/eca/macros[.]fnlm$"}}, exclusions = {}}}}}})
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
    local value_29_auto = (result.ok and value and (nil == value.lint["spec-files"]) and vim.deep_equal({"^spec/"}, value.lint.rules["module-import"][1]["applies-to"].files))
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") value (= nil (. value \"lint\" \"spec-files\")) (vim.deep_equal [\"^spec/\"] (. value \"lint\" \"rules\" \"module-import\" 1 \"applies-to\" \"files\")))")
    return true
  end
  return require("plenary.busted").it("spec-only behavior uses explicit file regexes", _7_)
end
require("plenary.busted").describe("canonical-spec-file-contract", _5_)
local function _8_()
  local function _9_()
    local result = validation({lint = {rules = {["forbidden-form"] = {{severity = "error", ["applies-to"] = {files = {"^spec/"}}, options = {module = "module"}, exclusions = {}}}, ["module-import"] = {{severity = "error", ["applies-to"] = {files = {"^spec/"}}, options = {mode = "forbid", modules = {"plenary.busted", "luassert"}, ["exempt-files"] = {"^spec/eca/macros[.]fnlm$"}}, exclusions = {}}, {severity = "error", ["applies-to"] = {}, options = {mode = "require", module = "eca.nfnl.core", binding = "core"}, exclusions = {}}}, ["required-form"] = {{severity = "error", ["applies-to"] = {files = {"^spec/"}}, options = {forms = {"module"}}, exclusions = {}}}, ["form-child-count"] = {{severity = "error", ["applies-to"] = {forms = {"testing"}}, options = {children = {"is"}, ["max-count"] = 1}, exclusions = {}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and result.value)
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (. result \"value\"))")
    return true
  end
  require("plenary.busted").it("generic rules and form-child-count validate", _9_)
  local function _10_()
    local result = validation({lint = {rules = {["module-import"] = {{severity = "error", ["applies-to"] = {}, options = {mode = "require", module = "eca.nfn.core", binding = "core"}, exclusions = {}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and ("require" == result.value.lint.rules["module-import"][1].options.mode) and ("core" == result.value.lint.rules["module-import"][1].options.binding))
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (= \"require\" (. result \"value\" \"lint\" \"rules\" \"module-import\" 1 \"options\" \"mode\")) (= \"core\" (. result \"value\" \"lint\" \"rules\" \"module-import\" 1 \"options\" \"binding\")))")
    return true
  end
  return require("plenary.busted").it("the module-import require instance preserves mode and binding", _10_)
end
return require("plenary.busted").describe("generic-rule-contract", _8_)
