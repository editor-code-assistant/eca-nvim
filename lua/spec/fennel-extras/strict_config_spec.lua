-- [nfnl] fnl/spec/fennel-extras/strict_config_spec.fnl
local function load_module(name)
  local ok, result = pcall(require, name)
  if ok then
    return result
  else
    return {["module-missing"] = true}
  end
end
local function error_result(ok, value, err)
  return {ok = ok, value = value, message = (err and err.message)}
end
local function config_validation_error(config, value)
  local ok, result, err = pcall(config.validate, value)
  return error_result(ok, result, err)
end
local function config_error(value)
  local config = load_module("fennel-extras.config")
  if config["module-missing"] then
    return config
  else
    return config_validation_error(config, value)
  end
end
local function format_validation_error(format, config)
  local ok, result, err = pcall(format["format-string"], "(x)", {config = config})
  return error_result(ok, result, err)
end
local function format_error(config)
  local format = load_module("fennel-extras.format")
  if format["module-missing"] then
    return format
  else
    return format_validation_error(format, config)
  end
end
local function indent_validation_error(indent, config)
  local ok, result, err = pcall(indent.reindent, "(x)", config)
  return error_result(ok, result, err)
end
local function indent_error(config)
  local indent = load_module("fennel-extras.indent")
  if indent["module-missing"] then
    return indent
  else
    return indent_validation_error(indent, config)
  end
end
local function error_value(value)
  if ("table" == type(value)) then
    return value.message
  else
    return value
  end
end
local function lint_error_message(ok, findings, err)
  return ((ok and err and error_value(err)) or (not ok and error_value(findings)))
end
local function lint_check(lint, matcher, source, context)
  local options = vim.tbl_extend("force", context, {matcher = matcher["vim-matcher"]()})
  local ok, findings, err = pcall(lint.check, source, options)
  return {ok = ok, findings = findings, message = lint_error_message(ok, findings, err)}
end
local function lint_error(source, context)
  local lint = load_module("fennel-extras.lint")
  local matcher = load_module("fennel-extras.cli.matcher")
  if (lint["module-missing"] or matcher["module-missing"]) then
    return {["module-missing"] = true}
  else
    return lint_check(lint, matcher, source, context)
  end
end
local function missing_message_3f(result, path)
  return ((result.ok and (nil == result.findings) and (("missing " .. path) == result.message)) or (not result.ok and (("missing " .. path) == result.message)))
end
local function complete_rule_3f(entry, rules, names, index, recurse)
  local instance = entry[1]
  return ((type(entry) == "table") and (#entry > 0) and (type(instance) == "table") and (instance.severity ~= nil) and (instance.options ~= nil) and (instance["applies-to"] ~= nil) and recurse(rules, names, (index + 1)))
end
local function complete_rules_3f(rules, names, index)
  return ((index > #names) or complete_rule_3f(rules[names[index]], rules, names, index, complete_rules_3f))
end
local function _7_()
  local function _8_()
    local assert_28_auto = require("luassert")
    local value_29_auto = missing_message_3f(format_error({}), "indent-width")
    assert_28_auto.is_truthy(value_29_auto, "(missing-message? (format-error {}) \"indent-width\")")
    return true
  end
  require("plenary.busted").it("format API reports missing indent-width", _8_)
  local function _9_()
    local assert_28_auto = require("luassert")
    local value_29_auto = missing_message_3f(format_error({["indent-width"] = 2, indents = {}}), "parser")
    assert_28_auto.is_truthy(value_29_auto, "(missing-message? (format-error {:indent-width 2 :indents {}}) \"parser\")")
    return true
  end
  require("plenary.busted").it("format API reports missing parser", _9_)
  local function _10_()
    local assert_28_auto = require("luassert")
    local value_29_auto = missing_message_3f(indent_error({}), "indent-width")
    assert_28_auto.is_truthy(value_29_auto, "(missing-message? (indent-error {}) \"indent-width\")")
    return true
  end
  require("plenary.busted").it("indent API reports missing indent-width", _10_)
  local function _11_()
    local assert_28_auto = require("luassert")
    local value_29_auto = missing_message_3f(indent_error({["indent-width"] = 2, indents = {}}), "parser")
    assert_28_auto.is_truthy(value_29_auto, "(missing-message? (indent-error {:indent-width 2 :indents {}}) \"parser\")")
    return true
  end
  return require("plenary.busted").it("indent API reports missing parser", _11_)
end
require("plenary.busted").describe("strict-config-errors", _7_)
local function _12_()
  local function _13_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown configuration key: align-bindings"
    local actual_7_auto = config_error({["align-bindings"] = true}).message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("align-bindings is rejected as an unknown key", _13_)
  local function _14_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown lint key: max-code-lines"
    local actual_7_auto = config_error({lint = {["max-code-lines"] = 300}}).message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("top-level lint max-code-lines is rejected", _14_)
  local function _15_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "missing alignment.binding-forms"
    local actual_7_auto = config_error({alignment = {bindings = true}}).message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("binding forms are required when binding alignment is enabled", _15_)
  local function _16_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "missing alignment.clause-forms"
    local actual_7_auto = config_error({alignment = {clauses = true}}).message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("clause forms are required when clause alignment is enabled", _16_)
  local function _17_()
    local result = config_error({alignment = {["binding-forms"] = {"let"}, ["clause-forms"] = {"case"}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = result.ok
    assert_28_auto.is_truthy(value_29_auto, "(. result \"ok\")")
    return true
  end
  return require("plenary.busted").it("missing alignment switches are off", _17_)
end
require("plenary.busted").describe("strict-config-shape", _12_)
local function _18_()
  local function _19_()
    local result = lint_error("(module a)", {path = "fnl/a.fnl", rules = {["form-chain"] = {{severity = "warning", options = {["allowed-chains"] = {}}, exclusions = {}}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint.rules.form-chain[1].applies-to must be a table"
    local actual_7_auto = result.message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an enabled rule reports the canonical applies-to path", _19_)
  local function _20_()
    local assert_28_auto = require("luassert")
    local value_29_auto = missing_message_3f(lint_error("(module a)", {path = "fnl/a.fnl", rules = {["file-size"] = {{severity = "warning", ["applies-to"] = {}, options = {}}}}}), "lint.rules.file-size[1].options.max-code-lines")
    assert_28_auto.is_truthy(value_29_auto, "(missing-message? (lint-error \"(module a)\" {:path \"fnl/a.fnl\"\n :rules {:file-size [{:applies-to {} :options {} :severity \"warning\"}]}}) \"lint.rules.file-size[1].options.max-code-lines\")")
    return true
  end
  require("plenary.busted").it("an enabled rule reports missing option values", _20_)
  local function _21_()
    local result = lint_error("(module a)", {path = "fnl/a.fnl", rules = {["file-size"] = {{severity = "off", ["applies-to"] = {}, options = {}, exclusions = {}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and (0 == #result.findings))
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (= 0 (length (. result \"findings\"))))")
    return true
  end
  return require("plenary.busted").it("an off rule still uses the canonical instance shape", _21_)
end
require("plenary.busted").describe("strict-lint-options", _18_)
local function _22_()
  local function _23_()
    local result = lint_error("(if ok value fallback)", {path = "fnl/app.fnl", rules = {["child-count"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {["min-count"] = 2, ["max-count"] = 2, ["not-counted"] = {"nil", "true", "false"}}, exclusions = {}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = result.ok
    assert_28_auto.is_truthy(value_29_auto, "(. result \"ok\")")
    return true
  end
  require("plenary.busted").it("accepts a non-empty not-counted string list", _23_)
  local function _24_()
    local result = lint_error("(if ok value fallback)", {path = "fnl/app.fnl", rules = {["child-count"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {["min-count"] = 2, ["max-count"] = 2, ["not-counted"] = {}}, exclusions = {}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = not result.ok
    assert_28_auto.is_truthy(value_29_auto, "(not (. result \"ok\"))")
    return true
  end
  require("plenary.busted").it("rejects an empty not-counted list", _24_)
  local function _25_()
    local result = lint_error("(if ok value fallback)", {path = "fnl/app.fnl", rules = {["child-count"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {["min-count"] = 2, ["max-count"] = 2, ["not-counted"] = {"nil"}, ["nil-count"] = false}, exclusions = {}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = not result.ok
    assert_28_auto.is_truthy(value_29_auto, "(not (. result \"ok\"))")
    return true
  end
  return require("plenary.busted").it("rejects nil-count together with not-counted", _25_)
end
require("plenary.busted").describe("child-count-not-counted-validation", _22_)
local function _26_()
  local function _27_()
    local result = config_error({lint = {rules = {["form-chain"] = {{severity = "warning", description = "explain this rule", ["applies-to"] = {}, options = {["allowed-chains"] = {}}, exclusions = {}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = result.ok
    assert_28_auto.is_truthy(value_29_auto, "(. result \"ok\")")
    return true
  end
  require("plenary.busted").it("accepts a non-empty string description", _27_)
  local function _28_()
    local result = config_error({lint = {rules = {["form-chain"] = {{severity = "warning", description = 42, ["applies-to"] = {}, options = {["allowed-chains"] = {}}, exclusions = {}}}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint.rules.form-chain[1].description must be a non-empty string"
    local actual_7_auto = result.message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-string description", _28_)
  local function _29_()
    local result = config_error({lint = {rules = {["form-chain"] = {{severity = "warning", description = "", ["applies-to"] = {}, options = {["allowed-chains"] = {}}, exclusions = {}}}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint.rules.form-chain[1].description must be a non-empty string"
    local actual_7_auto = result.message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects an empty description", _29_)
end
require("plenary.busted").describe("rule-instance-description-validation", _26_)
local function _30_()
  local function _31_()
    local config = load_module("fennel-extras.config")
    local loaded = (not config["module-missing"] and config.load(".fnl-extras.fnl"))
    local lint_rules = (loaded and loaded.lint and loaded.lint.rules)
    local design_rules = (loaded and loaded.design and loaded.design.rules)
    local lint_names = {"required-form", "module-import", "child-count", "file-size", "form-chain"}
    local design_names = {}
    local assert_28_auto = require("luassert")
    local value_29_auto = (loaded and loaded.format["indent-width"] and loaded.workspace.extensions and loaded.workspace.paths and loaded.format.indents and loaded.format["format-as"] and loaded.format.parser and loaded.format.alignment and loaded.lint and (nil == loaded.design) and complete_rules_3f(lint_rules, lint_names, 1))
    assert_28_auto.is_truthy(value_29_auto, "(and loaded (. (. loaded \"format\") \"indent-width\") (. (. loaded \"workspace\") \"extensions\") (. (. loaded \"workspace\") \"paths\") (. (. loaded \"format\") \"indents\") (. (. loaded \"format\") \"format-as\") (. (. loaded \"format\") \"parser\") (. (. loaded \"format\") \"alignment\") (. loaded \"lint\") (= nil (. loaded \"design\")) (complete-rules? lint-rules lint-names 1))")
    return true
  end
  return require("plenary.busted").it("the repository config loads with complete format and lint settings", _31_)
end
require("plenary.busted").describe("strict-config-property", _30_)
local function _32_()
  local function _33_()
    local result = config_error({lint = {rules = {["control-layout"] = {{severity = "warning", ["applies-to"] = {forms = {"if", "when", "and", "or", "case", "match"}}, options = {["allowed-chains"] = {}}, exclusions = {}}}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown lint rule: control-layout"
    local actual_7_auto = result.message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("strict config rejects removed control-layout", _33_)
  local function _34_()
    local result = config_error({lint = {rules = {["multiline-layout"] = {{severity = "warning", ["applies-to"] = {}, options = {clauses = {"case", "match", "case-try", "match-try"}, bindings = {"let", "when-let", "if-let", "with-open"}}, exclusions = {}}}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown lint rule: multiline-layout"
    local actual_7_auto = result.message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("strict config rejects removed multiline-layout", _34_)
end
require("plenary.busted").describe("removed-layout-rule-config-errors", _32_)
local function _35_()
  local function _36_()
    local config = load_module("fennel-extras.config")
    local loaded = (not config["module-missing"] and config.load(".fnl-extras.fnl"))
    local instances = (loaded and loaded.lint.rules["child-count"])
    local exclusions = (instances and instances[2].exclusions)
    local assert_28_auto = require("luassert")
    local value_29_auto = ((1 == #exclusions) and ("^spec/eca/macros[.]fnlm$" == exclusions[1].path))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 1 (length exclusions)) (= \"^spec/eca/macros[.]fnlm$\" (. (. exclusions 1) \"path\")))")
    return true
  end
  require("plenary.busted").it("child-count macro exclusions consolidate to one path-only entry", _36_)
  local function _37_()
    local config = load_module("fennel-extras.config")
    local loaded = (not config["module-missing"] and config.load(".fnl-extras.fnl"))
    local instances = (loaded and loaded.lint.rules["module-import"])
    local assert_28_auto = require("luassert")
    local value_29_auto = (instances and (nil == instances[2].options["exempt-files"]) and (0 == #instances[2].exclusions) and (nil == instances[3].options["exempt-files"]) and (0 == #instances[3].exclusions))
    assert_28_auto.is_truthy(value_29_auto, "(and instances (= nil (. (. instances 2) \"options\" \"exempt-files\")) (= 0 (length (. (. instances 2) \"exclusions\"))) (= nil (. (. instances 3) \"options\" \"exempt-files\")) (= 0 (length (. (. instances 3) \"exclusions\"))))")
    return true
  end
  return require("plenary.busted").it("module-import has empty exclusions after removing stale macro entries", _37_)
end
return require("plenary.busted").describe("repository-exclusion-contract", _35_)
