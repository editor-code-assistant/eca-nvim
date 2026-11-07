-- [nfnl] fnl/spec/fennel-extras/canonical_lint_contract_spec.fnl
local config = require("fennel-extras.config")
local registry = require("fennel-extras.lint.rules.registry")
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
local canonical_rule = {lint = {rules = {["module-import"] = {{severity = "error", ["applies-to"] = {files = {"^spec/"}, forms = {"require"}, modules = {"plenary.busted"}}, options = {mode = "forbid"}, exclusions = {{path = "^spec/eca/macros[.]fnlm$"}}}}}}}
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
    local result = validation({lint = {rules = {["module-import"] = {{severity = "error", ["applies-to"] = {contexts = {"spec"}}, options = {mode = "forbid", modules = {"plenary.busted"}}, exclusions = {{path = "^spec/eca/macros[.]fnlm$"}}}}}}})
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
    local result = validation({lint = {rules = {["forbidden-form"] = {{severity = "error", ["applies-to"] = {files = {"^spec/"}}, options = {}, exclusions = {}}}, ["module-import"] = {{severity = "error", ["applies-to"] = {files = {"^spec/"}, modules = {"plenary.busted", "luassert"}}, options = {mode = "forbid"}, exclusions = {}}, {severity = "error", ["applies-to"] = {modules = "eca.nfnl.core"}, options = {mode = "require", binding = "core"}, exclusions = {}}}, ["required-form"] = {{severity = "error", ["applies-to"] = {files = {"^spec/"}, forms = {"module"}}, options = {}, exclusions = {}}}, ["form-child-count"] = {{severity = "error", ["applies-to"] = {forms = {"testing"}}, options = {children = {"is"}, ["max-count"] = 1}, exclusions = {}}}}}})
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
    local result = validation({lint = {rules = {["module-import"] = {{severity = "error", ["applies-to"] = {forms = {"require"}, modules = {"plenary.busted"}}, options = {mode = "forbid"}, exclusions = {{path = "^spec/"}}}}}}})
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
  local file = assert(io.open(".fnl-extras.fnl", "r"))
  local source = file:read("*a")
  file:close()
  local assert_28_auto = require("luassert")
  local value_29_auto = not string.find(source, "\n\n$")
  assert_28_auto.is_truthy(value_29_auto, "(not (string.find source \"\n\n$\"))")
  return true
end
require("plenary.busted").it("the canonical source has no trailing blank lines", _15_)
local function _16_()
  local loaded = config.load(".fnl-extras.fnl")
  local rules = loaded.lint.rules
  local assert_28_auto = require("luassert")
  local value_29_auto = (vim.deep_equal({"module"}, rules["forbidden-form"][1]["applies-to"].modules) and vim.deep_equal({"eca.nfnl.core"}, rules["module-import"][1]["applies-to"].modules) and vim.deep_equal({"spec.eca.macros"}, rules["module-import"][2]["applies-to"].modules) and vim.deep_equal({"plenary.busted", "luassert"}, rules["module-import"][3]["applies-to"].modules) and true)
  assert_28_auto.is_truthy(value_29_auto, "(and (vim.deep_equal [\"module\"] (. rules \"forbidden-form\" 1 \"applies-to\" \"modules\")) (vim.deep_equal [\"eca.nfnl.core\"] (. rules \"module-import\" 1 \"applies-to\" \"modules\")) (vim.deep_equal [\"spec.eca.macros\"] (. rules \"module-import\" 2 \"applies-to\" \"modules\")) (vim.deep_equal [\"plenary.busted\" \"luassert\"] (. rules \"module-import\" 3 \"applies-to\" \"modules\")) true)")
  return true
end
require("plenary.busted").describe("canonical-module-selectors-are-vectors", _16_)
local function _17_()
  local function _18_()
    local result = validation({lint = {rules = {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {modules = {"one", "two"}}, options = {}, exclusions = {}}}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint.rules.forbidden-form[1].applies-to.modules must contain at most one module"
    local actual_7_auto = error_message(result)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("forbidden-form rejects multiple semantic singleton modules", _18_)
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
    local result = validation({lint = {rules = {["module-import"] = {{severity = "error", ["applies-to"] = {modules = {"one", "two"}}, options = {mode = "forbid"}, exclusions = {}}}}}})
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
require("plenary.busted").describe("canonical-module-selector-cardinality", _17_)
local function _23_()
  local function _24_()
    for _, rule in ipairs({"child-count", "form-child-count"}) do
      local rules = {}
      local _0
      rules[rule] = {{severity = "error", ["applies-to"] = {forms = {"testing"}}, options = {children = {"is"}, ["max-count"] = 1}, exclusions = {}}}
      _0 = nil
      local result = validation({lint = {rules = rules}})
      local assert_28_auto = require("luassert")
      local value_29_auto = result.ok
      assert_28_auto.is_truthy(value_29_auto, "(. result \"ok\")")
    end
    return nil
  end
  return require("plenary.busted").it("child-count is canonical and form-child-count remains an accepted alias", _24_)
end
require("plenary.busted").describe("migrated-rule-names", _23_)
local function _25_()
  local loaded = config.load(".fnl-extras.fnl")
  local rules = loaded.lint.rules
  local instance = rules["child-count"][2]
  local assert_28_auto = require("luassert")
  local value_29_auto = (instance and vim.deep_equal({forms = {"if"}}, instance["applies-to"]) and (2 == instance.options["min-count"]) and (2 == instance.options["max-count"]) and (false == instance.options["nil-count"]))
  assert_28_auto.is_truthy(value_29_auto, "(and instance (vim.deep_equal {:forms [\"if\"]} (. instance \"applies-to\")) (= 2 (. instance \"options\" \"min-count\")) (= 2 (. instance \"options\" \"max-count\")) (= false (. instance \"options\" \"nil-count\")))")
  return true
end
require("plenary.busted").it("canonical config uses direct child-count for if arity", _25_)
local removed_rules = {"call-data-arg", "module-style", "unused-and-or", "function-shape", "if-branch-call", "nested-forms", "leading-bindings", "no-mutation"}
local retained_rules = {"forbidden-form", "child-count", "module-import", "required-form", "file-size"}
local function removed_rule_instance()
  return {severity = "warning", ["applies-to"] = {}, options = {}, exclusions = {}}
end
local function _26_()
  local function _27_()
    local rules = config.load(".fnl-extras.fnl").lint.rules
    local assert_28_auto = require("luassert")
    local value_29_auto
    do
      local absent = true
      for _, rule in ipairs(removed_rules) do
        absent = (absent and (nil == rules[rule]))
      end
      value_29_auto = absent
    end
    assert_28_auto.is_truthy(value_29_auto, "(accumulate [absent true _ rule (ipairs removed-rules)] (and absent (= nil (. rules rule))))")
    return true
  end
  return require("plenary.busted").it("canonical config omits every removed rule", _27_)
end
require("plenary.busted").describe("canonical-config-removed-rules", _26_)
local function _28_()
  local function _29_()
    local assert_28_auto = require("luassert")
    local value_29_auto
    do
      local valid = true
      for _, rule in ipairs(removed_rules) do
        local rules = {}
        local _0
        rules[rule] = {removed_rule_instance()}
        _0 = nil
        local result = validation({lint = {rules = rules}})
        valid = (valid and not result.ok and (("unknown lint rule: " .. rule) == error_message(result)))
      end
      value_29_auto = valid
    end
    assert_28_auto.is_truthy(value_29_auto, "(accumulate [valid true _ rule (ipairs removed-rules)] (let [rules\n {}\n _\n (tset rules rule [(removed-rule-instance)])\n result\n (validation {:lint {:rules rules}})] (and valid (not (. result \"ok\")) (= (.. \"unknown lint rule: \" rule) (error-message result)))))")
    return true
  end
  return require("plenary.busted").it("canonical lint config rejects every removed rule name", _29_)
end
require("plenary.busted").describe("lint-validation-removed-rules", _28_)
local function _30_()
  local function _31_()
    local assert_28_auto = require("luassert")
    local value_29_auto
    do
      local valid = true
      for _, rule in ipairs(removed_rules) do
        local rules = {}
        local _0
        rules[rule] = {removed_rule_instance()}
        _0 = nil
        local result = validation({design = {rules = rules}})
        valid = (valid and not result.ok and (("unknown design rule: " .. rule) == error_message(result)))
      end
      value_29_auto = valid
    end
    assert_28_auto.is_truthy(value_29_auto, "(accumulate [valid true _ rule (ipairs removed-rules)] (let [rules\n {}\n _\n (tset rules rule [(removed-rule-instance)])\n result\n (validation {:design {:rules rules}})] (and valid (not (. result \"ok\")) (= (.. \"unknown design rule: \" rule) (error-message result)))))")
    return true
  end
  return require("plenary.busted").it("canonical design config rejects every removed rule name", _31_)
end
require("plenary.busted").describe("design-validation-removed-rules", _30_)
local function _32_()
  local function _33_()
    local names = registry["rule-names"]()
    local defaults = registry.defaults()
    local assert_28_auto = require("luassert")
    local value_29_auto
    local _34_
    do
      local absent = true
      for _, rule in ipairs(removed_rules) do
        absent = (absent and (nil == defaults[rule]) and not vim.tbl_contains(names, rule))
      end
      _34_ = absent
    end
    local and_35_ = _34_
    if and_35_ then
      local present = true
      for _, rule in ipairs(retained_rules) do
        present = (present and vim.tbl_contains(names, rule))
      end
      and_35_ = present
    end
    value_29_auto = and_35_
    assert_28_auto.is_truthy(value_29_auto, "(and (accumulate [absent true _ rule (ipairs removed-rules)] (and absent (= nil (. defaults rule)) (not (vim.tbl_contains names rule)))) (accumulate [present true _ rule (ipairs retained-rules)] (and present (vim.tbl_contains names rule))))")
    return true
  end
  return require("plenary.busted").it("the runtime registry omits removed rules and retains supported rules", _33_)
end
return require("plenary.busted").describe("runtime-registry-removed-rules", _32_)
