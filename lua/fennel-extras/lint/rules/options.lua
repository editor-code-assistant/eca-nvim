-- [nfnl] fnl/fennel-extras/lint/rules/options.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.options"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.options"]
end
local parse = require("fennel-extras.config.parse")
local option_names = {["module-style"] = {"applies-to", "macro-module", "required-macros"}, ["spec-macro-import"] = {"applies-to", "macro-module", "required-macros", "exempt-files"}, ["spec-no-module"] = {"applies-to", "module-form"}, ["spec-direct-require"] = {"applies-to", "forbidden-modules", "exempt-files"}, ["one-is-per-testing"] = {"applies-to", "testing-form", "assertion-form", "count"}, ["if-branch-call"] = {"applies-to", "if-forms"}, ["if-without-else"] = {"applies-to", "if-forms", "flag-nil-else"}, ["control-layout"] = {"applies-to", "control-forms"}, ["unused-and-or"] = {"applies-to", "forms"}, ["defn-args-newline"] = {"applies-to", "forms"}, ["function-shape"] = {"applies-to", "function-forms"}, ["no-mutation"] = {"applies-to", "forms"}, ["multiline-layout"] = {"applies-to", "clause-forms", "binding-forms"}, ["file-size"] = {"applies-to", "max-code-lines"}, ["core-require"] = {"applies-to", "module", "binding"}, ["binding-per-line"] = {"applies-to", "forms"}, ["call-data-arg"] = {"applies-to", "ignore-forms"}}
local option_types = {["applies-to"] = "enum", ["macro-module"] = "string", ["required-macros"] = "strings", ["exempt-files"] = "strings", ["module-form"] = "string", ["forbidden-modules"] = "strings", ["testing-form"] = "string", ["assertion-form"] = "string", count = "positive-integer", ["if-forms"] = "strings", ["flag-nil-else"] = "boolean", ["control-forms"] = "strings", forms = "strings", ["function-forms"] = "strings", ["clause-forms"] = "strings", ["binding-forms"] = "strings", ["max-code-lines"] = "positive-integer", module = "string", binding = "string", ["ignore-forms"] = "strings"}
local schema
do
  local function schema0(rule)
    local result = {}
    for _, name in ipairs((option_names[rule] or {})) do
      result[name] = option_types[name]
    end
    return result
  end
  _2amodule_2a["schema"] = schema0
  schema = _2amodule_2a.schema
end
local names
do
  local function names0(rule)
    return option_names[rule]
  end
  _2amodule_2a["names"] = names0
  names = _2amodule_2a.names
end
local defaults
do
  local function defaults0()
    return {}
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
local function known_option_error(rule, options, key, value, kind, recurse)
  if not option_type_valid_3f(kind, value) then
    return {message = option_type_message(kind, key)}
  else
    return recurse(rule, options, key)
  end
end
local function first_option_error_step(rule, options, key, value, recurse)
  local kind = schema(rule)[key]
  if (kind == nil) then
    return {unknown = true, message = ("unknown option " .. tostring(key))}
  else
    return known_option_error(rule, options, key, value, kind, recurse)
  end
end
local function first_option_error(rule, options, key)
  local next_key, next_value = next(options, key)
  if (next_key == nil) then
    return nil
  else
    return first_option_error_step(rule, options, next_key, next_value, first_option_error)
  end
end
local function unknown_option_result(rule, error)
  return {message = (error.message .. " for lint rule " .. rule)}
end
local function table_validation_result(rule, error)
  if error.unknown then
    return unknown_option_result(rule, error)
  else
    return error
  end
end
local function table_validation_error(rule, options)
  local error = first_option_error(rule, options, nil)
  return (error and table_validation_result(rule, error))
end
local function validate_present(rule, options)
  if (type(options) == "table") then
    return table_validation_error(rule, options)
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
      return validate_present(rule, options)
    end
  end
  _2amodule_2a["validate"] = validate0
  validate = _2amodule_2a.validate
end
local normalized
do
  local function normalized0(overrides)
    return (overrides or {})
  end
  _2amodule_2a["normalized"] = normalized0
  normalized = _2amodule_2a.normalized
end
local spec_files_error
do
  local function spec_files_error0(value)
    if ((value ~= nil) and not parse["sequence?"](value)) then
      return {message = "spec-files must be a list of strings"}
    else
      return nil
    end
  end
  _2amodule_2a["spec-files-error"] = spec_files_error0
  spec_files_error = _2amodule_2a["spec-files-error"]
end
return nil
