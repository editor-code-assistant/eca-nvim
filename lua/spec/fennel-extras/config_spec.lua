-- [nfnl] fnl/spec/fennel-extras/config_spec.fnl
local options = require("fennel-extras.lint.rules.options")
local function load_config()
  local ok, result = pcall(require, "fennel-extras.config")
  if ok then
    return result
  else
    return {["module-missing"] = true}
  end
end
local function with_cleanup(cleanup, f)
  local ok, result = pcall(f)
  cleanup()
  if ok then
    return result
  else
    return error(result, 0)
  end
end
local function parse_result(text)
  local config = load_config()
  if config["module-missing"] then
    return config
  else
    local ok, value, err
    local function _3_()
      return config["parse-string"](text)
    end
    ok, value, err = pcall(_3_)
    if ok then
      return {value = value, error = err}
    else
      return {["call-error"] = true, error = err}
    end
  end
end
local function parse_value(text)
  return parse_result(text).value
end
local function parse_error_summary(text, include_location_3f)
  local result = parse_result(text)
  if result["module-missing"] then
    return result
  else
    local value = result.value
    local err = result.error
    if include_location_3f then
      return {["value?"] = (nil ~= value), ["has-message"] = ((nil == value) and err and ("table" == type(err)) and ("string" == type(err.message))), line = (err and err.line), col = (err and err.col)}
    else
      return {["value?"] = (nil ~= value), ["has-message"] = ((nil == value) and err and ("table" == type(err)) and ("string" == type(err.message)))}
    end
  end
end
local function canonical_fragment(value)
  if (("table" == type(value)) and (nil == value.workspace) and (nil == value.format) and (nil == value.lint)) then
    local workspace = {}
    local format = {}
    for key, item in pairs(value) do
      if ((key == "paths") or (key == "exclude") or (key == "extensions") or (key == "dotfiles") or (key == "symlinks")) then
        workspace[key] = item
      else
        format[key] = item
      end
    end
    return {workspace = workspace, format = format, lint = {rules = {}}}
  else
    return value
  end
end
local function complete_config(value)
  if ("table" == type(value)) then
    return vim.tbl_deep_extend("force", {workspace = {paths = {"fnl"}, extensions = {".fnl", ".fnlm"}}, format = {["indent-width"] = 2, builtins = false, parser = false, ["prefix-fallbacks"] = false}, lint = {rules = {}}}, canonical_fragment(value))
  else
    return value
  end
end
local function validate_summary(value)
  local config = load_config()
  local value0 = complete_config(value)
  if config["module-missing"] then
    return config
  else
    local ok, result, err
    local function _11_()
      return config.validate(value0)
    end
    ok, result, err = pcall(_11_)
    return {["value?"] = (ok and (nil ~= result)), ["has-message"] = (ok and (nil == result) and err and ("table" == type(err)) and ("string" == type(err.message)))}
  end
end
local function validation_call(config, value)
  local function _13_()
    return config.validate(value)
  end
  return pcall(_13_)
end
local function complete_lint_config(value)
  return canonical_fragment(value)
end
local function validation_message(config, value)
  local ok, result, err = validation_call(config, value)
  if (ok and (result == nil) and err) then
    return err.message
  else
    return nil
  end
end
local function validation_error_message_raw(text)
  local config = load_config()
  local value = parse_value(text)
  if (not config["module-missing"] and (value ~= nil)) then
    return validation_message(config, value)
  else
    return nil
  end
end
local function validation_error_message(text)
  local config = load_config()
  local value = complete_lint_config(parse_value(text))
  if (not config["module-missing"] and (value ~= nil)) then
    return validation_message(config, value)
  else
    return nil
  end
end
local function validation_summary(config, value)
  local ok, result, err = validation_call(config, value)
  return {["crashed?"] = not ok, message = (ok and (nil == result) and err and err.message)}
end
local function validation_result(config, value)
  if (config["module-missing"] or (value == nil)) then
    return {message = nil, ["crashed?"] = false}
  else
    return validation_summary(config, value)
  end
end
local function parsed_value(text_or_value)
  if ("string" == type(text_or_value)) then
    return parse_value(text_or_value)
  else
    return text_or_value
  end
end
local function validation_call_summary(text_or_value)
  local config = load_config()
  local parsed = parsed_value(text_or_value)
  local value = complete_lint_config(parsed)
  return validation_result(config, value)
end
local function lint_policy_summary(value)
  local config = load_config()
  local value0 = complete_config(value)
  if config["module-missing"] then
    return config
  else
    local ok, policy, err
    local function _19_()
      return config["lint-policy"](value0)
    end
    ok, policy, err = pcall(_19_)
    return {["value-nil?"] = (ok and (nil == policy)), message = (ok and (nil == policy) and err and err.message)}
  end
end
local function lint_policy_value(value)
  local config = load_config()
  local value0 = complete_config(value)
  if config["module-missing"] then
    return config
  else
    local ok, policy, err
    local function _21_()
      return config["lint-policy"](value0)
    end
    ok, policy, err = pcall(_21_)
    if (ok and policy) then
      return policy
    else
      return {error = (err and err.message)}
    end
  end
end
local function unknown_lint_key_summary(value)
  local config = load_config()
  if config["module-missing"] then
    return config
  else
    local ok, result, err
    local function _24_()
      return config.validate(value)
    end
    ok, result, err = pcall(_24_)
    local message = (ok and (nil == result) and err and err.message)
    return {["unknown-key?"] = (message and ("unknown lint key: " == string.sub(message, 1, 18)))}
  end
end
local function write_file(path, text)
  local file = assert(io.open(path, "w"))
  file:write(text)
  file:close()
  return path
end
local function find_load_scenario()
  local root = vim.fn.tempname()
  local nested = (root .. "/one/two")
  local root_config = (root .. "/.fnl-extras.fnl")
  local config_path = (root .. "/one/.fnl-extras.fnl")
  local stop_root = (root .. "/stop")
  local stop_nested = (stop_root .. "/child")
  local stop_git = (stop_root .. "/.git")
  vim.fn.mkdir(nested, "p")
  vim.fn.mkdir(stop_nested, "p")
  vim.fn.mkdir(stop_git, "p")
  local function _26_()
    return vim.fn.delete(root, "rf")
  end
  local function _27_()
    write_file(root_config, "{:workspace {:exclude [\"root\"]} :format {:indent-width 2 :builtins false :prefix-fallbacks false :parser false} :lint {:rules {}}}")
    write_file(config_path, "{:workspace {:paths [\"fnl\"]} :format {:indent-width 2 :builtins false :prefix-fallbacks false :parser false} :lint {:rules {}}}")
    write_file((root .. "/valid.fnl-extras.fnl"), "{:exclude [\"generated\"]}")
    local _28_
    do
      local config = load_config()
      if config["module-missing"] then
        _28_ = config
      else
        _28_ = config.find(root)
      end
    end
    local _30_
    do
      local config = load_config()
      if config["module-missing"] then
        _30_ = config
      else
        _30_ = config.find(nested)
      end
    end
    local _32_
    do
      local config = load_config()
      if config["module-missing"] then
        _32_ = config
      else
        _32_ = config.find(stop_nested)
      end
    end
    local _34_
    do
      local config = load_config()
      if config["module-missing"] then
        _34_ = config
      else
        _34_ = config.load(config_path)
      end
    end
    local _36_
    do
      local config = load_config()
      if config["module-missing"] then
        _36_ = config
      else
        local ok, value, err
        local function _38_()
          return config.load((root .. "/missing.fnl-extras.fnl"))
        end
        ok, value, err = pcall(_38_)
        _36_ = {["value?"] = (ok and (nil ~= value)), ["has-message"] = (ok and (nil == value) and err and ("table" == type(err)) and ("string" == type(err.message)))}
      end
    end
    return {start = _28_, parent = _30_, stopped = _32_, ["root-config"] = root_config, ["config-path"] = config_path, loaded = _34_, missing = _36_}
  end
  return with_cleanup(_26_, _27_)
end
local function _40_()
  local function _41_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {indents = {deftest = {{"block", 1}}, testing = {{"block", 1}}}, ["format-as"] = {["my-let"] = "let"}, paths = {"fnl"}, exclude = {"fnl/eca/nfnl"}}
    local actual_7_auto = parse_value("{:indents {\"deftest\" [[:block 1]] \"testing\" [[:block 1]]} :format-as {\"my-let\" \"let\"} :paths [\"fnl\"] :exclude [\"fnl/eca/nfnl\"]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("parses a realistic data-only configuration and converts keywords to strings", _41_)
  local function _42_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {text = "quote \" slash \\ line\n tab\t", one = 1, decimal = 2.5, negative = -3, yes = true, nothing = nil, no = false}
    local actual_7_auto = parse_value("{:text \"quote \\\" slash \\\\ line\\n tab\\t\" ; comment\n :one 1 :decimal 2.5 :negative -3 :yes true :no false :nothing nil}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("parses escapes, numbers, booleans, nil, and ignores comments", _42_)
end
require("plenary.busted").describe("parse-string", _40_)
local function _43_()
  local function _44_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, line = 1, col = 5, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a (require :x)}", true)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a list and reports line 1 column 5", _44_)
  local function _45_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a foo}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a bare symbol", _45_)
  local function _46_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a #(x)}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects hash reader prefixes", _46_)
  local function _47_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{} {}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects more than one top-level form", _47_)
  local function _48_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an empty file", _48_)
  local function _49_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("[1]", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-table top-level form", _49_)
  local function _50_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a 1", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects unbalanced input", _50_)
  local function _51_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = validate_summary({workspace = {colour = 1}, format = {}, lint = {rules = {}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("validate rejects an unknown top-level key", _51_)
  local function _52_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = validate_summary({paths = "fnl"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("validate rejects paths that are not a sequence", _52_)
end
require("plenary.busted").describe("rejection", _43_)
local function _53_()
  local function _54_()
    local result = find_load_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["root-config"]
    local actual_7_auto = result.start
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("find returns a config in the start directory", _54_)
  local function _55_()
    local result = find_load_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["config-path"]
    local actual_7_auto = result.parent
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("find returns the nearest config in a parent directory", _55_)
  local function _56_()
    local assert_25_auto = require("luassert")
    local value_26_auto = find_load_scenario().stopped
    assert_25_auto.is_nil(value_26_auto)
    return true
  end
  require("plenary.busted").it("find stops at a .git directory", _56_)
  local function _57_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {workspace = {paths = {"fnl"}}, format = {["indent-width"] = 2, builtins = false, parser = false, ["prefix-fallbacks"] = false}, lint = {rules = {}}}
    local actual_7_auto = find_load_scenario().loaded
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("load returns the validated table from a file", _57_)
  local function _58_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = find_load_scenario().missing
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("load returns a structured error for a missing path", _58_)
end
require("plenary.busted").describe("find-load", _53_)
local function _59_()
  local function _60_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({["indent-width"] = 4})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an indent width of four", _60_)
  local function _61_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "builtins must be a map or false"
    local actual_7_auto = validation_error_message("{:builtins true}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects true builtins because the setting must be explicit", _61_)
  local function _62_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({builtins = false})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts disabling builtins", _62_)
  local function _63_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({builtins = {foo = {{"block", 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a replacement builtins table", _63_)
  local function _64_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({["prefix-fallbacks"] = false})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts disabling prefix fallbacks", _64_)
  local function _65_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({["prefix-fallbacks"] = {["foo-"] = {{"block", 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a replacement prefix fallback table", _65_)
  local function _66_()
    local message = validation_error_message("{:indent-width 0}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects zero indent width with a specific validation message", _66_)
  local function _67_()
    local message = validation_error_message("{:indent-width -1}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects negative indent width with a specific validation message", _67_)
  local function _68_()
    local message = validation_error_message("{:indent-width 2.5}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects non-integer indent width with a specific validation message", _68_)
  local function _69_()
    local message = validation_error_message("{:indent-width \"4\"}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects string indent width with a specific validation message", _69_)
  local function _70_()
    local message = validation_error_message("{:builtins 1}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "builtins must be a map or false"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects malformed builtins with a specific validation message", _70_)
  local function _71_()
    local message = validation_error_message("{:prefix-fallbacks 1}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "prefix-fallbacks must be a map or false"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects malformed prefix fallbacks with a specific validation message", _71_)
  local function _72_()
    local message = validation_error_message("{:builtins {\"foo\" 1}}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "builtins must be a map or false"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects malformed builtins rules with a specific validation message", _72_)
  local function _73_()
    local message = validation_error_message("{:prefix-fallbacks {\"foo-\" 1}}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "prefix-fallbacks must be a map or false"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects malformed prefix fallback rules with a specific validation message", _73_)
end
require("plenary.busted").describe("config-new-configuration", _59_)
local function _74_()
  local function _75_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({extensions = {".fnl", ".fnlm"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a non-empty list of dotted extension strings", _75_)
  local function _76_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "workspace.extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions []}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an empty extensions list with the exact validation message", _76_)
  local function _77_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "workspace.extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions [1]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects non-string extensions with the exact validation message", _77_)
  local function _78_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "workspace.extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions [\"fnl\"]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects extensions without a leading dot with the exact validation message", _78_)
  local function _79_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "workspace.extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions \".fnl\"}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects a non-list extensions value with the exact validation message", _79_)
end
require("plenary.busted").describe("extensions", _74_)
local function _80_()
  local function _81_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nil
    local actual_7_auto = validation_error_message_raw("{:indent-width 2 :builtins false :prefix-fallbacks false :parser false :extensions [\".fnl\"]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not require paths during general configuration validation", _81_)
  local function _82_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "workspace.dotfiles must be a boolean"
    local actual_7_auto = validation_error_message("{:dotfiles 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-boolean dotfiles value with the exact validation message", _82_)
  local function _83_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "workspace.symlinks must be a boolean"
    local actual_7_auto = validation_error_message("{:symlinks 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-boolean symlinks value with the exact validation message", _83_)
  local function _84_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "parser must be a string or false"
    local actual_7_auto = validation_error_message("{:parser 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-string parser value with the exact validation message", _84_)
  local function _85_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown configuration key: align-bindings"
    local actual_7_auto = validation_error_message_raw("{:align-bindings true}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects the removed align-bindings key", _85_)
end
require("plenary.busted").describe("new-keys", _80_)
local function _86_()
  local function _87_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({alignment = {maps = true}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an alignment table", _87_)
  local function _88_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment must be a table"
    local actual_7_auto = validation_error_message("{:alignment true}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a boolean alignment value with the exact validation message", _88_)
  local function _89_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment must be a table"
    local actual_7_auto = validation_error_message("{:alignment \"yes\"}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a string alignment value with the exact validation message", _89_)
  local function _90_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown alignment key: nope"
    local actual_7_auto = validation_error_message("{:alignment {:nope true}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown alignment key with the key in the error", _90_)
  local function _91_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment key maps must be a boolean"
    local actual_7_auto = validation_error_message("{:alignment {:maps 1}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-boolean alignment toggle with the exact validation message", _91_)
  local function _92_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment key binding-forms must be a list of strings"
    local actual_7_auto = validation_error_message("{:alignment {:binding-forms \"let\"}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-list binding-forms value with the exact validation message", _92_)
  local function _93_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment key binding-forms must be a list of strings"
    local actual_7_auto = validation_error_message("{:alignment {:binding-forms {:foo \"bar\"}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a map binding-forms value with the exact validation message", _93_)
  local function _94_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment key clause-forms must be a list of strings"
    local actual_7_auto = validation_error_message("{:alignment {:clause-forms [1]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-string clause form with the exact validation message", _94_)
  local function _95_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment key clause-forms must be a list of strings"
    local actual_7_auto = validation_error_message("{:alignment {:clause-forms {:foo \"bar\"}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a map clause-forms value with the exact validation message", _95_)
  local function _96_()
    local config = load_config()
    local settings = require("fennel-extras.indent.settings")
    local value = {alignment = {["binding-forms"] = {"let"}, ["clause-forms"] = {"case"}}}
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["binding-forms"] = {"let"}, ["clause-forms"] = {"case"}, bindings = false, clauses = false, ["collapse-padding"] = false, maps = false, ["split-bindings"] = false}
    local actual_7_auto = settings.resolve(config.validate(value))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("missing alignment switches remain off", _96_)
  local function _97_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "missing alignment.binding-forms"
    local actual_7_auto = validation_error_message("{:alignment {:bindings true}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("alignment tables require binding forms when binding alignment is enabled", _97_)
end
require("plenary.busted").describe("alignment-configuration", _86_)
local function formatter_projection(config)
  return {indents = config.indents, ["format-as"] = config["format-as"], ["indent-patterns"] = config["indent-patterns"], ["indent-width"] = config["indent-width"], builtins = config.builtins, ["prefix-fallbacks"] = config["prefix-fallbacks"]}
end
local function format_with_config(source, config)
  local ok, format = pcall(require, "fennel-extras.format")
  if not ok then
    return {["module-missing"] = true}
  else
    local ok0, value, err
    local function _98_()
      return format["format-string"](source, {config = config})
    end
    ok0, value, err = pcall(_98_)
    return {value = value, error = err, ok = ok0}
  end
end
local function _100_()
  local function _101_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({lint = {rules = {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {files = {"^spec/"}, forms = {"require"}, modules = "plenary.busted"}, options = {}, exclusions = {}}}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a canonical lint rule instance", _101_)
  local function _102_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = validate_summary({lint = {rules = {["forbidden-form"] = {severity = "warning", ["applies-to"] = {files = {"^spec/"}, forms = {"require"}}, options = {module = "plenary.busted"}, exclusions = {}}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a direct rule map", _102_)
  local function _103_()
    local first = "{:lint {:rules {:forbidden-form [{:severity :warning :applies-to {} :options {:unknown true :module 1} :exclusions []}]}}}"
    local second = "{:lint {:rules {:forbidden-form [{:severity :warning :applies-to {} :options {:module 1 :unknown true} :exclusions []}]}}}"
    local first_message = validation_error_message(first)
    local second_message = validation_error_message(second)
    local assert_5_auto = require("luassert")
    local expected_6_auto = first_message
    local actual_7_auto = second_message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("reports option errors deterministically", _103_)
  local function _104_()
    local message = validation_error_message("{:lint {:rules {:forbidden-form [{:severity :warning :applies-to {} :options {:module 1 :unknown true} :exclusions []}]}}}")
    local assert_28_auto = require("luassert")
    local value_29_auto = string.match(message, "module must be a string")
    assert_28_auto.is_truthy(value_29_auto, "(string.match message \"module must be a string\")")
    return true
  end
  require("plenary.busted").it("reports the lexicographically first invalid option", _104_)
  local function _105_()
    local message = validation_error_message("{:lint {:rules {:forbidden-form [{:severity :warning :applies-to {} :options {:unknown true} :exclusions []}]}}}")
    local assert_28_auto = require("luassert")
    local value_29_auto = string.match(message, "unknown option unknown")
    assert_28_auto.is_truthy(value_29_auto, "(string.match message \"unknown option unknown\")")
    return true
  end
  return require("plenary.busted").it("unknown options include the rule name", _105_)
end
require("plenary.busted").describe("lint-configuration", _100_)
local function _106_()
  local function _107_()
    local policy = lint_policy_value({lint = {rules = {}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (not policy.error and policy.rules)
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. policy \"error\")) (. policy \"rules\"))")
    return true
  end
  return require("plenary.busted").it("lint policy preserves explicit rule options", _107_)
end
require("plenary.busted").describe("lint-policy", _106_)
local function _108_()
  local function _109_()
    local result = format_with_config("(let [x 1] x)", {["indent-width"] = 2, paths = {"fnl"}, extensions = {".fnl"}, builtins = false, parser = false, ["prefix-fallbacks"] = false})
    local assert_28_auto = require("luassert")
    local value_29_auto = (result["module-missing"] or result.value)
    assert_28_auto.is_truthy(value_29_auto, "(or (. result \"module-missing\") (. result \"value\"))")
    return true
  end
  return require("plenary.busted").it("lint configuration does not change formatter output", _109_)
end
return require("plenary.busted").describe("formatter-isolation", _108_)
