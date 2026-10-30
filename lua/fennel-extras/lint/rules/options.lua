-- [nfnl] fnl/fennel-extras/lint/rules/options.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.rules.options"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.rules.options"]
end
local parse = require("fennel-extras.config.parse")
local option_names = {["forbidden-form"] = {"module", "forms"}, ["required-form"] = {"forms"}, ["module-style"] = {"module", "forms"}, ["module-import"] = {"mode", "modules", "exempt-files", "module", "binding", "forms"}, ["form-child-count"] = {"children", "max-count"}, ["if-branch-call"] = {"forms"}, ["if-without-else"] = {"forms", "nil-else"}, ["control-layout"] = {"forms"}, ["unused-and-or"] = {"forms"}, ["function-shape"] = {"forms", "max-depth"}, ["multiline-layout"] = {"clauses", "bindings"}, ["file-size"] = {"max-code-lines"}, ["call-data-arg"] = {"forms"}, ["nested-forms"] = {"forms", "max-depth"}, ["leading-bindings"] = {"forms"}, ["no-mutation"] = {"forms"}}
local required_option_names = {["forbidden-form"] = {}, ["required-form"] = {}, ["module-style"] = {}, ["module-import"] = {"mode"}, ["form-child-count"] = {"children", "max-count"}, ["if-branch-call"] = {}, ["if-without-else"] = {}, ["control-layout"] = {}, ["unused-and-or"] = {}, ["function-shape"] = {}, ["multiline-layout"] = {"clauses", "bindings"}, ["file-size"] = {"max-code-lines"}, ["call-data-arg"] = {}, ["nested-forms"] = {}, ["leading-bindings"] = {}, ["no-mutation"] = {}}
local option_types = {module = "string", mode = "string", modules = "strings", forms = "strings", ["exempt-files"] = "strings", children = "strings", ["max-count"] = "positive-integer", ["nil-else"] = "boolean", clauses = "strings", bindings = "strings", ["max-depth"] = "positive-integer", ["max-code-lines"] = "positive-integer", binding = "string"}
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
local required_names
do
  local function required_names0(rule)
    return required_option_names[rule]
  end
  _2amodule_2a["required-names"] = required_names0
  required_names = _2amodule_2a["required-names"]
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
validators = {string = _2_, strings = strings_3f, ["positive-integer"] = positive_integer_3f, boolean = boolean_3f}
local type_messages = {strings = " must be a list of strings", ["positive-integer"] = " must be a positive integer", boolean = " must be a boolean", string = " must be a string"}
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
  return (option .. message)
end
local function first_option_error_step(rule, options, keys, index)
  local key = keys[index]
  local value = (key and options[key])
  local kind = (key and schema(rule)[key])
  if (key == nil) then
    return nil
  else
    return (((kind == nil) and {unknown = true, message = ("unknown option " .. tostring(key))}) or (not option_type_valid_3f(kind, value) and {message = option_type_message(kind, key)}) or first_option_error_step(rule, options, keys, (index + 1)))
  end
end
local function first_option_error(rule, options)
  local keys = vim.tbl_keys(options)
  table.sort(keys)
  return first_option_error_step(rule, options, keys, 1)
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
  local error = first_option_error(rule, options)
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
return nil
