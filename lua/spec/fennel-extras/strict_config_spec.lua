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
    local value_29_auto = missing_message_3f(format_error({["indent-width"] = 2}), "builtins")
    assert_28_auto.is_truthy(value_29_auto, "(missing-message? (format-error {:indent-width 2}) \"builtins\")")
    return true
  end
  require("plenary.busted").it("format API reports missing builtins", _9_)
  local function _10_()
    local assert_28_auto = require("luassert")
    local value_29_auto = missing_message_3f(format_error({["indent-width"] = 2, builtins = false}), "prefix-fallbacks")
    assert_28_auto.is_truthy(value_29_auto, "(missing-message? (format-error {:builtins false :indent-width 2}) \"prefix-fallbacks\")")
    return true
  end
  require("plenary.busted").it("format API reports missing prefix-fallbacks", _10_)
  local function _11_()
    local assert_28_auto = require("luassert")
    local value_29_auto = missing_message_3f(format_error({["indent-width"] = 2, builtins = false, ["prefix-fallbacks"] = false}), "parser")
    assert_28_auto.is_truthy(value_29_auto, "(missing-message? (format-error {:builtins false :indent-width 2 :prefix-fallbacks false}) \"parser\")")
    return true
  end
  require("plenary.busted").it("format API reports missing parser", _11_)
  local function _12_()
    local assert_28_auto = require("luassert")
    local value_29_auto = missing_message_3f(indent_error({}), "indent-width")
    assert_28_auto.is_truthy(value_29_auto, "(missing-message? (indent-error {}) \"indent-width\")")
    return true
  end
  require("plenary.busted").it("indent API reports missing indent-width", _12_)
  local function _13_()
    local assert_28_auto = require("luassert")
    local value_29_auto = missing_message_3f(indent_error({["indent-width"] = 2}), "builtins")
    assert_28_auto.is_truthy(value_29_auto, "(missing-message? (indent-error {:indent-width 2}) \"builtins\")")
    return true
  end
  require("plenary.busted").it("indent API reports missing builtins", _13_)
  local function _14_()
    local assert_28_auto = require("luassert")
    local value_29_auto = missing_message_3f(indent_error({["indent-width"] = 2, builtins = false}), "prefix-fallbacks")
    assert_28_auto.is_truthy(value_29_auto, "(missing-message? (indent-error {:builtins false :indent-width 2}) \"prefix-fallbacks\")")
    return true
  end
  require("plenary.busted").it("indent API reports missing prefix-fallbacks", _14_)
  local function _15_()
    local assert_28_auto = require("luassert")
    local value_29_auto = missing_message_3f(indent_error({["indent-width"] = 2, builtins = false, ["prefix-fallbacks"] = false}), "parser")
    assert_28_auto.is_truthy(value_29_auto, "(missing-message? (indent-error {:builtins false :indent-width 2 :prefix-fallbacks false}) \"parser\")")
    return true
  end
  return require("plenary.busted").it("indent API reports missing parser", _15_)
end
require("plenary.busted").describe("strict-config-errors", _7_)
local function _16_()
  local function _17_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown configuration key: align-bindings"
    local actual_7_auto = config_error({["align-bindings"] = true}).message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("align-bindings is rejected as an unknown key", _17_)
  local function _18_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "builtins must be a map or false"
    local actual_7_auto = config_error({builtins = true}).message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("true builtins is rejected", _18_)
  local function _19_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "prefix-fallbacks must be a map or false"
    local actual_7_auto = config_error({["prefix-fallbacks"] = true}).message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("true prefix-fallbacks is rejected", _19_)
  local function _20_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown lint key: max-code-lines"
    local actual_7_auto = config_error({lint = {["max-code-lines"] = 300}}).message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("top-level lint max-code-lines is rejected", _20_)
  local function _21_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "missing alignment.binding-forms"
    local actual_7_auto = config_error({alignment = {bindings = true}}).message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("binding forms are required when binding alignment is enabled", _21_)
  local function _22_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "missing alignment.clause-forms"
    local actual_7_auto = config_error({alignment = {clauses = true}}).message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("clause forms are required when clause alignment is enabled", _22_)
  local function _23_()
    local result = config_error({alignment = {["binding-forms"] = {"let"}, ["clause-forms"] = {"case"}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = result.ok
    assert_28_auto.is_truthy(value_29_auto, "(. result \"ok\")")
    return true
  end
  return require("plenary.busted").it("missing alignment switches are off", _23_)
end
require("plenary.busted").describe("strict-config-shape", _16_)
local function _24_()
  local function _25_()
    local result = lint_error("(module a)", {path = "fnl/a.fnl", rules = {["module-style"] = {{severity = "warning", options = {}, exclusions = {}}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint.rules.module-style[1].applies-to must be a table"
    local actual_7_auto = result.message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an enabled rule reports the canonical applies-to path", _25_)
  local function _26_()
    local assert_28_auto = require("luassert")
    local value_29_auto = missing_message_3f(lint_error("(module a)", {path = "fnl/a.fnl", rules = {["file-size"] = {{severity = "warning", ["applies-to"] = {}, options = {}}}}}), "lint.rules.file-size[1].options.max-code-lines")
    assert_28_auto.is_truthy(value_29_auto, "(missing-message? (lint-error \"(module a)\" {:path \"fnl/a.fnl\"\n :rules {:file-size [{:applies-to {} :options {} :severity \"warning\"}]}}) \"lint.rules.file-size[1].options.max-code-lines\")")
    return true
  end
  require("plenary.busted").it("an enabled rule reports missing option values", _26_)
  local function _27_()
    local result = lint_error("(module a)", {path = "fnl/a.fnl", rules = {["file-size"] = {{severity = "off", ["applies-to"] = {}, options = {}, exclusions = {}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and (0 == #result.findings))
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (= 0 (length (. result \"findings\"))))")
    return true
  end
  return require("plenary.busted").it("an off rule still uses the canonical instance shape", _27_)
end
require("plenary.busted").describe("strict-lint-options", _24_)
local function _28_()
  local function _29_()
    local config = load_module("fennel-extras.config")
    local loaded
    if config["module-missing"] then
      loaded = nil
    else
      loaded = config.load(".fnl-extras.fnl")
    end
    local lint_rules = (loaded and loaded.lint and loaded.lint.rules)
    local design_rules = (loaded and loaded.design and loaded.design.rules)
    local lint_names = {"forbidden-form", "required-form", "module-style", "module-import", "form-child-count", "control-layout", "unused-and-or", "multiline-layout", "file-size", "call-data-arg"}
    local design_names = {"if-branch-call", "if-without-else", "function-shape"}
    local assert_28_auto = require("luassert")
    local value_29_auto = (loaded and loaded.format["indent-width"] and loaded.workspace.extensions and loaded.workspace.paths and loaded.format.builtins and loaded.format["prefix-fallbacks"] and loaded.format.parser and loaded.format.alignment and loaded.lint and loaded.design and complete_rules_3f(lint_rules, lint_names, 1) and complete_rules_3f(design_rules, design_names, 1))
    assert_28_auto.is_truthy(value_29_auto, "(and loaded (. (. loaded \"format\") \"indent-width\") (. (. loaded \"workspace\") \"extensions\") (. (. loaded \"workspace\") \"paths\") (. (. loaded \"format\") \"builtins\") (. (. loaded \"format\") \"prefix-fallbacks\") (. (. loaded \"format\") \"parser\") (. (. loaded \"format\") \"alignment\") (. loaded \"lint\") (. loaded \"design\") (complete-rules? lint-rules lint-names 1) (complete-rules? design-rules design-names 1))")
    return true
  end
  return require("plenary.busted").it("the repository config loads with complete format and lint settings", _29_)
end
return require("plenary.busted").describe("strict-config-property", _28_)
