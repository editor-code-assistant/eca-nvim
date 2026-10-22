-- [nfnl] fnl/fennel-extras/lint/rules/options.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.options"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.options"]
end
local parse = require("fennel-extras.config.parse")
local rule_options = {["module-style"] = {["applies-to"] = "source", ["macro-module"] = "eca.nfnl.macros.aniseed", ["required-macros"] = {"module", "def", "defn", "defn-"}}, ["spec-macro-import"] = {["applies-to"] = "spec", ["macro-module"] = "spec.eca.macros", ["required-macros"] = {"deftest", "testing", "is"}, ["exempt-files"] = {"^fnl/spec/eca/macros[.]fnlm$"}}, ["spec-no-module"] = {["applies-to"] = "spec", ["module-form"] = "module"}, ["spec-direct-require"] = {["applies-to"] = "spec", ["forbidden-modules"] = {"plenary.busted", "luassert"}, ["exempt-files"] = {"^fnl/spec/eca/macros[.]fnlm$"}}, ["one-is-per-testing"] = {["applies-to"] = "all", ["testing-form"] = "testing", ["assertion-form"] = "is", count = 1}, ["if-branch-call"] = {["applies-to"] = "all", ["if-forms"] = {"if"}}, ["if-without-else"] = {["applies-to"] = "all", ["if-forms"] = {"if"}, ["flag-nil-else"] = true}, ["control-layout"] = {["applies-to"] = "all", ["control-forms"] = {"if", "when", "and", "or", "case", "match"}}, ["unused-and-or"] = {["applies-to"] = "all", forms = {"and", "or"}}, ["defn-args-newline"] = {["applies-to"] = "all", forms = {"defn", "defn-"}}, ["function-shape"] = {["applies-to"] = "all", ["function-forms"] = {"defn", "defn-", "fn", "lambda", "\206\187"}}, ["no-mutation"] = {["applies-to"] = "source", forms = {"var", "set", "while"}}, ["multiline-layout"] = {["applies-to"] = "all", ["clause-forms"] = {"case", "match", "case-try", "match-try"}, ["binding-forms"] = {"let", "when-let", "if-let", "with-open"}}, ["file-size"] = {["applies-to"] = "source", ["max-code-lines"] = 300}, ["core-require"] = {["applies-to"] = "all", module = "eca.nfnl.core", binding = "core"}, ["binding-per-line"] = {["applies-to"] = "all", forms = {"let", "when-let", "if-let", "with-open"}}, ["call-data-arg"] = {["applies-to"] = "source", ["ignore-forms"] = {}}}
local option_types = {["applies-to"] = "enum", ["macro-module"] = "string", ["required-macros"] = "strings", ["exempt-files"] = "strings", ["module-form"] = "string", ["forbidden-modules"] = "strings", ["testing-form"] = "string", ["assertion-form"] = "string", count = "positive-integer", ["if-forms"] = "strings", ["flag-nil-else"] = "boolean", ["control-forms"] = "strings", forms = "strings", ["function-forms"] = "strings", ["clause-forms"] = "strings", ["binding-forms"] = "strings", ["max-code-lines"] = "positive-integer", module = "string", binding = "string", ["ignore-forms"] = "strings"}
local schema
do
  local function schema0(rule)
    local defaults = rule_options[rule]
    local schema1 = {}
    for key, _ in pairs(defaults) do
      schema1[key] = (option_types[key] or "string")
    end
    return schema1
  end
  _2amodule_2a["schema"] = schema0
  schema = _2amodule_2a.schema
end
local defaults
do
  local function defaults0()
    return rule_options
  end
  _2amodule_2a["defaults"] = defaults0
  defaults = _2amodule_2a.defaults
end
local function boolean_3f(value)
  return ((value == true) or (value == false))
end
local function positive_integer_3f(value)
  return ((type(value) == "number") and (value == math.floor(value)) and (value > 0))
end
local function strings_step(value, index)
  if (index > #value) then
    return true
  else
    return ((type(value[index]) == "string") and strings_step(value, (index + 1)))
  end
end
local function strings_3f(value)
  return (parse["sequence?"](value) and strings_step(value, 1))
end
local validators
local function _2_(value)
  return (type(value) == "string")
end
local function _3_(value)
  return ((value == "source") or (value == "spec") or (value == "all"))
end
validators = {string = _2_, strings = strings_3f, ["positive-integer"] = positive_integer_3f, boolean = boolean_3f, enum = _3_}
local type_messages = {strings = " must be a list of strings", ["positive-integer"] = " must be a positive integer", boolean = " must be a boolean", enum = "applies-to must be source, spec, or all", string = " must be a string"}
local function option_type_valid_3f(kind, value)
  local validator = validators[kind]
  if validator then
    return validator(value)
  else
    return true
  end
end
local function option_type_message(kind, option)
  local message = type_messages[kind]
  if (kind == "enum") then
    return message
  else
    return (option .. message)
  end
end
local function known_option_error(schema0, options, key, value, kind, recurse)
  if not option_type_valid_3f(kind, value) then
    return {message = option_type_message(kind, key)}
  else
    return recurse(schema0, options, key)
  end
end
local function first_option_error_step(schema0, options, key, value, recurse)
  local kind = schema0[key]
  if (kind == nil) then
    return {unknown = true, message = ("unknown option " .. tostring(key))}
  else
    return known_option_error(schema0, options, key, value, kind, recurse)
  end
end
local function first_option_error(schema0, options, key)
  local next_key, next_value = next(options, key)
  if (next_key == nil) then
    return nil
  else
    return first_option_error_step(schema0, options, next_key, next_value, first_option_error)
  end
end
local function unknown_option_result(rule, error)
  return {message = (error.message .. " for lint rule " .. rule)}
end
local function option_error_known(rule, error)
  if error.unknown then
    return unknown_option_result(rule, error)
  else
    return error
  end
end
local function option_error_result(rule, error)
  return (error and option_error_known(rule, error))
end
local function validate_table(rule, options)
  return option_error_result(rule, first_option_error(schema(rule), options, nil))
end
local function validate_value(rule, options)
  if (type(options) == "table") then
    return validate_table(rule, options)
  else
    return {message = "options must be a table"}
  end
end
local validate
do
  local function validate0(rule, options)
    if (options == nil) then
      return nil
    else
      return validate_value(rule, options)
    end
  end
  _2amodule_2a["validate"] = validate0
  validate = _2amodule_2a.validate
end
local function merge_rule_options(result, name, overrides)
  local merged = {}
  for key, value in pairs(rule_options[name]) do
    merged[key] = value
  end
  for key, value in pairs((overrides or {})) do
    merged[key] = value
  end
  result[name] = merged
  return result
end
local normalized
do
  local function normalized0(overrides)
    local result = {}
    for name, _ in pairs(rule_options) do
      merge_rule_options(result, name, (overrides or {})[name])
    end
    return result
  end
  _2amodule_2a["normalized"] = normalized0
  normalized = _2amodule_2a.normalized
end
local spec_files
do
  local function spec_files0()
    return {"^fnl/spec/"}
  end
  _2amodule_2a["spec-files"] = spec_files0
  spec_files = _2amodule_2a["spec-files"]
end
local spec_files_error
do
  local function spec_files_error0(value)
    if ((value ~= nil) and not strings_3f(value)) then
      return {message = "spec-files must be a list of strings"}
    else
      return nil
    end
  end
  _2amodule_2a["spec-files-error"] = spec_files_error0
  spec_files_error = _2amodule_2a["spec-files-error"]
end
return nil
