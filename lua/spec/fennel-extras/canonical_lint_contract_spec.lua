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
local canonical_rule = {lint = {rules = {["module-import"] = {{severity = "error", ["applies-to"] = {files = {"^spec/"}, forms = {"require"}, modules = {"plenary.busted"}}, options = {mode = "forbid", ["exempt-files"] = {"^spec/eca/macros[.]fnlm$"}}, exclusions = {}}}}}}
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
    local result = validation({lint = {rules = {["forbidden-form"] = {{severity = "error", ["applies-to"] = {files = {"^spec/"}}, options = {}, exclusions = {}}}, ["module-import"] = {{severity = "error", ["applies-to"] = {files = {"^spec/"}, modules = {"plenary.busted", "luassert"}}, options = {mode = "forbid", ["exempt-files"] = {"^spec/eca/macros[.]fnlm$"}}, exclusions = {}}, {severity = "error", ["applies-to"] = {modules = "eca.nfnl.core"}, options = {mode = "require", binding = "core"}, exclusions = {}}}, ["required-form"] = {{severity = "error", ["applies-to"] = {files = {"^spec/"}, forms = {"module"}}, options = {}, exclusions = {}}}, ["form-child-count"] = {{severity = "error", ["applies-to"] = {forms = {"testing"}}, options = {children = {"is"}, ["max-count"] = 1}, exclusions = {}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and result.value)
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (. result \"value\"))")
    return true
  end
  require("plenary.busted").it("generic rules and form-child-count validate", _9_)
  local function _10_()
    local result = validation({lint = {rules = {["module-import"] = {{severity = "error", ["applies-to"] = {modules = "eca.nfnl.core"}, options = {mode = "require", binding = "core"}, exclusions = {}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and ("require" == result.value.lint.rules["module-import"][1].options.mode) and ("core" == result.value.lint.rules["module-import"][1].options.binding))
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (= \"require\" (. result \"value\" \"lint\" \"rules\" \"module-import\" 1 \"options\" \"mode\")) (= \"core\" (. result \"value\" \"lint\" \"rules\" \"module-import\" 1 \"options\" \"binding\")))")
    return true
  end
  return require("plenary.busted").it("the module-import require instance preserves mode and binding", _10_)
end
require("plenary.busted").describe("generic-rule-contract", _8_)
local function _11_()
  local function _12_()
    local result = validation({lint = {rules = {["module-import"] = {{severity = "error", ["applies-to"] = {forms = {"require"}, modules = {"plenary.busted"}}, options = {mode = "forbid", ["exempt-files"] = {"^spec/"}}, exclusions = {}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and vim.deep_equal({"require"}, result.value.lint.rules["module-import"][1]["applies-to"].forms) and vim.deep_equal({"plenary.busted"}, result.value.lint.rules["module-import"][1]["applies-to"].modules) and (nil == result.value.lint.rules["module-import"][1].options.forms) and (nil == result.value.lint.rules["module-import"][1].options.modules))
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (vim.deep_equal [\"require\"] (. result \"value\" \"lint\" \"rules\" \"module-import\" 1 \"applies-to\" \"forms\")) (vim.deep_equal [\"plenary.busted\"] (. result \"value\" \"lint\" \"rules\" \"module-import\" 1 \"applies-to\" \"modules\")) (= nil (. result \"value\" \"lint\" \"rules\" \"module-import\" 1 \"options\" \"forms\")) (= nil (. result \"value\" \"lint\" \"rules\" \"module-import\" 1 \"options\" \"modules\")))")
    return true
  end
  require("plenary.busted").it("selector values live under applies-to and not under options", _12_)
  local function _13_()
    for _, options in ipairs({{forms = {"if"}}, {module = "module"}, {modules = {"luassert"}}}) do
      local result = validation({lint = {rules = {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {}, options = options, exclusions = {}}}}}})
      local assert_28_auto = require("luassert")
      local value_29_auto = not result.ok
      assert_28_auto.is_truthy(value_29_auto, "(not (. result \"ok\"))")
    end
    return nil
  end
  return require("plenary.busted").it("the old selector option locations are rejected", _13_)
end
require("plenary.busted").describe("migrated-canonical-config-contract", _11_)
local function _14_()
  local file = assert(io.open(".fnl-extras.fnl", "r"))
  local source = file:read("*a")
  file:close()
  local assert_28_auto = require("luassert")
  local value_29_auto = (string.find(source, ":lint") and string.find(source, ":rules") and string.find(source, ":forbidden%-form%s+%[%{") and not string.find(source, ":forbidden%-form%s+%[%{:%s*severity%s+:%s*off%s+%}%]"))
  assert_28_auto.is_truthy(value_29_auto, "(and (string.find source \":lint\") (string.find source \":rules\") (string.find source \":forbidden%-form%s+%[%{\") (not (string.find source \":forbidden%-form%s+%[%{:%s*severity%s+:%s*off%s+%}%]\")))")
  return true
end
require("plenary.busted").it("the canonical source keeps rule vectors inline and has no empty forbidden-form placeholder", _14_)
local function _15_()
  local loaded = config.load(".fnl-extras.fnl")
  local rules = loaded.lint.rules
  local assert_28_auto = require("luassert")
  local value_29_auto = (vim.deep_equal({"module"}, rules["forbidden-form"][1]["applies-to"].modules) and vim.deep_equal({"eca.nfnl.core"}, rules["module-import"][1]["applies-to"].modules) and vim.deep_equal({"spec.eca.macros"}, rules["module-import"][2]["applies-to"].modules) and vim.deep_equal({"plenary.busted", "luassert"}, rules["module-import"][3]["applies-to"].modules) and vim.deep_equal({"eca.nfnl.macros.aniseed"}, rules["module-style"][1]["applies-to"].modules))
  assert_28_auto.is_truthy(value_29_auto, "(and (vim.deep_equal [\"module\"] (. rules \"forbidden-form\" 1 \"applies-to\" \"modules\")) (vim.deep_equal [\"eca.nfnl.core\"] (. rules \"module-import\" 1 \"applies-to\" \"modules\")) (vim.deep_equal [\"spec.eca.macros\"] (. rules \"module-import\" 2 \"applies-to\" \"modules\")) (vim.deep_equal [\"plenary.busted\" \"luassert\"] (. rules \"module-import\" 3 \"applies-to\" \"modules\")) (vim.deep_equal [\"eca.nfnl.macros.aniseed\"] (. rules \"module-style\" 1 \"applies-to\" \"modules\")))")
  return true
end
require("plenary.busted").describe("canonical-module-selectors-are-vectors", _15_)
local function _16_()
  local function _17_()
    local result = validation({lint = {rules = {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {modules = {"one", "two"}}, options = {}, exclusions = {}}}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint.rules.forbidden-form[1].applies-to.modules must contain at most one module"
    local actual_7_auto = error_message(result)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("forbidden-form rejects multiple semantic singleton modules", _17_)
  local function _18_()
    local result = validation({lint = {rules = {["module-style"] = {{severity = "warning", ["applies-to"] = {modules = {"one", "two"}}, options = {}, exclusions = {}}}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint.rules.module-style[1].applies-to.modules must contain at most one module"
    local actual_7_auto = error_message(result)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("module-style rejects multiple semantic singleton modules", _18_)
  local function _19_()
    local result = validation({lint = {rules = {["module-import"] = {{severity = "error", ["applies-to"] = {modules = {"one", "two"}}, options = {mode = "require", binding = "one"}, exclusions = {}}}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint.rules.module-import[1].applies-to.modules must contain at most one module"
    local actual_7_auto = error_message(result)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("module-import require rejects multiple semantic singleton modules", _19_)
  local function _20_()
    local result = validation({lint = {rules = {["module-import"] = {{severity = "error", ["applies-to"] = {modules = {"one", "two"}}, options = {mode = "forbid", ["exempt-files"] = {}}, exclusions = {}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = result.ok
    assert_28_auto.is_truthy(value_29_auto, "(. result \"ok\")")
    return true
  end
  require("plenary.busted").it("module-import forbid accepts multiple module selectors", _20_)
  local function _21_()
    local result = validation({lint = {rules = {["module-import"] = {{severity = "error", ["applies-to"] = {modules = {"one", "two"}}, exclusions = {}}}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint.rules.module-import[1].options must be a table"
    local actual_7_auto = error_message(result)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("module-import missing options returns a structured validation error", _21_)
  local function _22_()
    local result = validation({lint = {rules = {["module-import"] = {{severity = "error", ["applies-to"] = {modules = {"one", "two"}}, options = "require", exclusions = {}}}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint.rules.module-import[1].options must be a table"
    local actual_7_auto = error_message(result)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("module-import non-map options returns a structured validation error", _22_)
end
return require("plenary.busted").describe("canonical-module-selector-cardinality", _16_)
