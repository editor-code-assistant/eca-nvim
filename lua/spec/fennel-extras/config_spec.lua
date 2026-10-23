-- [nfnl] fnl/spec/fennel-extras/config_spec.fnl
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
local function complete_config(value)
  if ("table" == type(value)) then
    return vim.tbl_deep_extend("force", {["indent-width"] = 2, paths = {"fnl"}, extensions = {".fnl", ".fnlm"}, builtins = false, parser = false, ["prefix-fallbacks"] = false}, value)
  else
    return value
  end
end
local function complete_lint_config(value)
  local value0 = complete_config(value)
  if (("table" == type(value0)) and ("table" == type(value0.lint))) then
    return vim.tbl_deep_extend("force", {lint = {["spec-files"] = {"^fnl/spec/"}}}, value0)
  else
    return value0
  end
end
local function validate_summary(value)
  local config = load_config()
  local value0 = complete_lint_config(value)
  if config["module-missing"] then
    return config
  else
    local ok, result, err
    local function _10_()
      return config.validate(value0)
    end
    ok, result, err = pcall(_10_)
    return {["value?"] = (ok and (nil ~= result)), ["has-message"] = (ok and (nil == result) and err and ("table" == type(err)) and ("string" == type(err.message)))}
  end
end
local function validation_call(config, value)
  local function _12_()
    return config.validate(value)
  end
  return pcall(_12_)
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
  local value0 = complete_lint_config(value)
  if config["module-missing"] then
    return config
  else
    local ok, policy, err
    local function _18_()
      return config["lint-policy"](value0)
    end
    ok, policy, err = pcall(_18_)
    return {["value-nil?"] = (ok and (nil == policy)), message = (ok and (nil == policy) and err and err.message)}
  end
end
local function lint_policy_value(value)
  local config = load_config()
  local value0 = complete_lint_config(value)
  if config["module-missing"] then
    return config
  else
    local ok, policy, err
    local function _20_()
      return config["lint-policy"](value0)
    end
    ok, policy, err = pcall(_20_)
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
    local function _23_()
      return config.validate(value)
    end
    ok, result, err = pcall(_23_)
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
  local function _25_()
    return vim.fn.delete(root, "rf")
  end
  local function _26_()
    write_file(root_config, "{:exclude [\"root\"]}")
    write_file(config_path, "{:paths [\"fnl\"]}")
    write_file((root .. "/valid.fnl-extras.fnl"), "{:exclude [\"generated\"]}")
    local _27_
    do
      local config = load_config()
      if config["module-missing"] then
        _27_ = config
      else
        _27_ = config.find(root)
      end
    end
    local _29_
    do
      local config = load_config()
      if config["module-missing"] then
        _29_ = config
      else
        _29_ = config.find(nested)
      end
    end
    local _31_
    do
      local config = load_config()
      if config["module-missing"] then
        _31_ = config
      else
        _31_ = config.find(stop_nested)
      end
    end
    local _33_
    do
      local config = load_config()
      if config["module-missing"] then
        _33_ = config
      else
        _33_ = config.load(config_path)
      end
    end
    local _35_
    do
      local config = load_config()
      if config["module-missing"] then
        _35_ = config
      else
        local ok, value, err
        local function _37_()
          return config.load((root .. "/missing.fnl-extras.fnl"))
        end
        ok, value, err = pcall(_37_)
        _35_ = {["value?"] = (ok and (nil ~= value)), ["has-message"] = (ok and (nil == value) and err and ("table" == type(err)) and ("string" == type(err.message)))}
      end
    end
    return {start = _27_, parent = _29_, stopped = _31_, ["root-config"] = root_config, ["config-path"] = config_path, loaded = _33_, missing = _35_}
  end
  return with_cleanup(_25_, _26_)
end
local function _39_()
  local function _40_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {indents = {deftest = {{"block", 1}}, testing = {{"block", 1}}}, ["format-as"] = {["my-let"] = "let"}, paths = {"fnl"}, exclude = {"fnl/eca/nfnl"}}
    local actual_7_auto = parse_value("{:indents {\"deftest\" [[:block 1]] \"testing\" [[:block 1]]} :format-as {\"my-let\" \"let\"} :paths [\"fnl\"] :exclude [\"fnl/eca/nfnl\"]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("parses a realistic data-only configuration and converts keywords to strings", _40_)
  local function _41_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {text = "quote \" slash \\ line\n tab\t", one = 1, decimal = 2.5, negative = -3, yes = true, nothing = nil, no = false}
    local actual_7_auto = parse_value("{:text \"quote \\\" slash \\\\ line\\n tab\\t\" ; comment\n :one 1 :decimal 2.5 :negative -3 :yes true :no false :nothing nil}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("parses escapes, numbers, booleans, nil, and ignores comments", _41_)
end
require("plenary.busted").describe("parse-string", _39_)
local function _42_()
  local function _43_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, line = 1, col = 5, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a (require :x)}", true)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a list and reports line 1 column 5", _43_)
  local function _44_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a foo}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a bare symbol", _44_)
  local function _45_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a #(x)}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects hash reader prefixes", _45_)
  local function _46_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{} {}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects more than one top-level form", _46_)
  local function _47_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an empty file", _47_)
  local function _48_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("[1]", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-table top-level form", _48_)
  local function _49_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a 1", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects unbalanced input", _49_)
  local function _50_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = validate_summary({colour = 1})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("validate rejects an unknown top-level key", _50_)
  local function _51_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = validate_summary({paths = "fnl"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("validate rejects paths that are not a sequence", _51_)
end
require("plenary.busted").describe("rejection", _42_)
local function _52_()
  local function _53_()
    local result = find_load_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["root-config"]
    local actual_7_auto = result.start
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("find returns a config in the start directory", _53_)
  local function _54_()
    local result = find_load_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["config-path"]
    local actual_7_auto = result.parent
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("find returns the nearest config in a parent directory", _54_)
  local function _55_()
    local assert_25_auto = require("luassert")
    local value_26_auto = find_load_scenario().stopped
    assert_25_auto.is_nil(value_26_auto)
    return true
  end
  require("plenary.busted").it("find stops at a .git directory", _55_)
  local function _56_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {paths = {"fnl"}}
    local actual_7_auto = find_load_scenario().loaded
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("load returns the validated table from a file", _56_)
  local function _57_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = find_load_scenario().missing
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("load returns a structured error for a missing path", _57_)
end
require("plenary.busted").describe("find-load", _52_)
local function _58_()
  local function _59_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({["indent-width"] = 4})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an indent width of four", _59_)
  local function _60_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "builtins must be a map or false"
    local actual_7_auto = validation_error_message("{:builtins true}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects true builtins because the setting must be explicit", _60_)
  local function _61_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({builtins = false})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts disabling builtins", _61_)
  local function _62_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({builtins = {foo = {{"block", 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a replacement builtins table", _62_)
  local function _63_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({["prefix-fallbacks"] = false})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts disabling prefix fallbacks", _63_)
  local function _64_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({["prefix-fallbacks"] = {["foo-"] = {{"block", 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a replacement prefix fallback table", _64_)
  local function _65_()
    local message = validation_error_message("{:indent-width 0}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects zero indent width with a specific validation message", _65_)
  local function _66_()
    local message = validation_error_message("{:indent-width -1}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects negative indent width with a specific validation message", _66_)
  local function _67_()
    local message = validation_error_message("{:indent-width 2.5}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects non-integer indent width with a specific validation message", _67_)
  local function _68_()
    local message = validation_error_message("{:indent-width \"4\"}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects string indent width with a specific validation message", _68_)
  local function _69_()
    local message = validation_error_message("{:builtins 1}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "builtins must be a map or false"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects malformed builtins with a specific validation message", _69_)
  local function _70_()
    local message = validation_error_message("{:prefix-fallbacks 1}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "prefix-fallbacks must be a map or false"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects malformed prefix fallbacks with a specific validation message", _70_)
  local function _71_()
    local message = validation_error_message("{:builtins {\"foo\" 1}}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "builtins must be a map or false"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects malformed builtins rules with a specific validation message", _71_)
  local function _72_()
    local message = validation_error_message("{:prefix-fallbacks {\"foo-\" 1}}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "prefix-fallbacks must be a map or false"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects malformed prefix fallback rules with a specific validation message", _72_)
end
require("plenary.busted").describe("config-new-configuration", _58_)
local function _73_()
  local function _74_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({extensions = {".fnl", ".fnlm"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a non-empty list of dotted extension strings", _74_)
  local function _75_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions []}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an empty extensions list with the exact validation message", _75_)
  local function _76_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions [1]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects non-string extensions with the exact validation message", _76_)
  local function _77_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions [\"fnl\"]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects extensions without a leading dot with the exact validation message", _77_)
  local function _78_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions \".fnl\"}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects a non-list extensions value with the exact validation message", _78_)
end
require("plenary.busted").describe("extensions", _73_)
local function _79_()
  local function _80_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nil
    local actual_7_auto = validation_error_message_raw("{:indent-width 2 :builtins false :prefix-fallbacks false :parser false :extensions [\".fnl\"]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not require paths during general configuration validation", _80_)
  local function _81_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "skip-dotfiles must be a boolean"
    local actual_7_auto = validation_error_message("{:skip-dotfiles 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-boolean skip-dotfiles value with the exact validation message", _81_)
  local function _82_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "follow-symlinks must be a boolean"
    local actual_7_auto = validation_error_message("{:follow-symlinks 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-boolean follow-symlinks value with the exact validation message", _82_)
  local function _83_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "parser must be a string or false"
    local actual_7_auto = validation_error_message("{:parser 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-string parser value with the exact validation message", _83_)
  local function _84_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown configuration key: align-bindings"
    local actual_7_auto = validation_error_message("{:align-bindings true}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects the removed align-bindings key", _84_)
end
require("plenary.busted").describe("new-keys", _79_)
local function _85_()
  local function _86_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({alignment = {maps = true}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an alignment table", _86_)
  local function _87_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment must be a table"
    local actual_7_auto = validation_error_message("{:alignment true}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a boolean alignment value with the exact validation message", _87_)
  local function _88_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment must be a table"
    local actual_7_auto = validation_error_message("{:alignment \"yes\"}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a string alignment value with the exact validation message", _88_)
  local function _89_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown alignment key: nope"
    local actual_7_auto = validation_error_message("{:alignment {:nope true}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown alignment key with the key in the error", _89_)
  local function _90_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment key maps must be a boolean"
    local actual_7_auto = validation_error_message("{:alignment {:maps 1}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-boolean alignment toggle with the exact validation message", _90_)
  local function _91_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment key binding-forms must be a list of strings"
    local actual_7_auto = validation_error_message("{:alignment {:binding-forms \"let\"}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-list binding-forms value with the exact validation message", _91_)
  local function _92_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment key binding-forms must be a list of strings"
    local actual_7_auto = validation_error_message("{:alignment {:binding-forms {:foo \"bar\"}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a map binding-forms value with the exact validation message", _92_)
  local function _93_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment key clause-forms must be a list of strings"
    local actual_7_auto = validation_error_message("{:alignment {:clause-forms [1]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-string clause form with the exact validation message", _93_)
  local function _94_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment key clause-forms must be a list of strings"
    local actual_7_auto = validation_error_message("{:alignment {:clause-forms {:foo \"bar\"}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a map clause-forms value with the exact validation message", _94_)
  local function _95_()
    local config = load_config()
    local value = {alignment = {["binding-forms"] = {"let"}, ["clause-forms"] = {"case"}}}
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["binding-forms"] = {"let"}, ["clause-forms"] = {"case"}, bindings = false, clauses = false, ["collapse-padding"] = false, maps = false, ["split-bindings"] = false}
    local actual_7_auto = config.validate(value).alignment
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("missing alignment switches remain off", _95_)
  local function _96_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "missing alignment.binding-forms"
    local actual_7_auto = validation_error_message("{:alignment {:bindings true}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("alignment tables require binding forms when binding alignment is enabled", _96_)
end
require("plenary.busted").describe("alignment-configuration", _85_)
local function formatter_projection(config)
  return {indents = config.indents, ["format-as"] = config["format-as"], ["indent-patterns"] = config["indent-patterns"], ["indent-width"] = config["indent-width"], builtins = config.builtins, ["prefix-fallbacks"] = config["prefix-fallbacks"]}
end
local function format_with_config(source, config)
  local ok, format = pcall(require, "fennel-extras.format")
  if not ok then
    return {["module-missing"] = true}
  else
    local ok0, value, err
    local function _97_()
      return format["format-string"](source, {config = config})
    end
    ok0, value, err = pcall(_97_)
    return {value = value, error = err, ok = ok0}
  end
end
local function _99_()
  local function _100_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {}}
    local actual_7_auto = parse_value("{:lint {}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an empty lint table from parsed Fennel", _100_)
  local function _101_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {}}}
    local actual_7_auto = parse_value("{:lint {:rules {}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("parses an empty lint rules table from Fennel", _101_)
  local function _102_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {["spec-files"] = {"^fnl/spec/"}, rules = {}}}
    local actual_7_auto
    do
      local config = load_config()
      if config["module-missing"] then
        actual_7_auto = config
      else
        actual_7_auto = config.validate({lint = {["spec-files"] = {"^fnl/spec/"}, rules = {}}})
      end
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an empty lint rules table through validate", _102_)
  local function _104_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["if-branch-call"] = "error"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"if-branch-call\" :error}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a known lint rule from parsed Fennel", _104_)
  local function _105_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["no-mutation"] = "warning"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"no-mutation\" :warning}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the no-mutation lint rule from parsed Fennel", _105_)
  local function _106_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["binding-per-line"] = "warning"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"binding-per-line\" :warning}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the binding-per-line lint rule from parsed Fennel", _106_)
  local function _107_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["call-data-arg"] = "warning"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"call-data-arg\" :warning}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the call-data-arg lint rule from parsed Fennel", _107_)
  local function _108_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["defn-args-newline"] = "error"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"defn-args-newline\" :error}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the defn-args-newline lint rule from parsed Fennel", _108_)
  local function _109_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["control-layout"] = "warning"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"control-layout\" :warning}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the control-layout lint rule from parsed Fennel", _109_)
  local function _110_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["unused-and-or"] = "warning"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"unused-and-or\" :warning}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the unused-and-or lint rule from parsed Fennel", _110_)
  local function _111_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({lint = {["spec-files"] = {"^fnl/spec/"}, rules = {["file-size"] = {severity = "warning", options = {["applies-to"] = "source", ["max-code-lines"] = 10}}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a positive max-code-lines value", _111_)
  local function _112_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "max-code-lines must be a positive integer"
    local actual_7_auto = validation_error_message("{:lint {:spec-files [\"^fnl/spec/\"] :rules {\"file-size\" {:severity :warning :options {:applies-to \"source\" :max-code-lines 0}}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects zero max-code-lines with a specific validation message", _112_)
  local function _113_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "max-code-lines must be a positive integer"
    local actual_7_auto = validation_error_message("{:lint {:spec-files [\"^fnl/spec/\"] :rules {\"file-size\" {:severity :warning :options {:applies-to \"source\" :max-code-lines -1}}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects negative max-code-lines with a specific validation message", _113_)
  local function _114_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "max-code-lines must be a positive integer"
    local actual_7_auto = validation_error_message("{:lint {:spec-files [\"^fnl/spec/\"] :rules {\"file-size\" {:severity :warning :options {:applies-to \"source\" :max-code-lines 1.5}}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects non-integer max-code-lines with a specific validation message", _114_)
  local function _115_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "max-code-lines must be a positive integer"
    local actual_7_auto = validation_error_message("{:lint {:spec-files [\"^fnl/spec/\"] :rules {\"file-size\" {:severity :warning :options {:applies-to \"source\" :max-code-lines \"10\"}}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects string max-code-lines with a specific validation message", _115_)
  local function _116_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["file-size"] = "warning"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"file-size\" :warning}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the file-size lint rule from parsed Fennel", _116_)
  local function _117_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {exclusions = {{rule = "if-branch-call", form = "fnl/a.fnl > top#1", reason = "why"}}}}
    local actual_7_auto = parse_value("{:lint {:exclusions [{:rule \"if-branch-call\" :form \"fnl/a.fnl > top#1\" :reason \"why\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an exclusion from parsed Fennel", _117_)
  local function _118_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {["spec-files"] = {"^fnl/spec/"}}}
    local actual_7_auto
    do
      local config = load_config()
      if config["module-missing"] then
        actual_7_auto = config
      else
        actual_7_auto = config.validate({lint = {["spec-files"] = {"^fnl/spec/"}}})
      end
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an empty lint table through validate", _118_)
  local function _120_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {["spec-files"] = {"^fnl/spec/"}, rules = {["if-branch-call"] = {severity = "error", options = {["applies-to"] = "all", ["if-forms"] = {"if"}}}}}}
    local actual_7_auto
    do
      local config = load_config()
      if config["module-missing"] then
        actual_7_auto = config
      else
        actual_7_auto = config.validate({lint = {["spec-files"] = {"^fnl/spec/"}, rules = {["if-branch-call"] = {severity = "error", options = {["applies-to"] = "all", ["if-forms"] = {"if"}}}}}})
      end
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a lint rule through validate", _120_)
  local function _122_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {["spec-files"] = {"^fnl/spec/"}, exclusions = {{rule = "if-branch-call", form = "fnl/a.fnl > top#1", reason = "why"}}}}
    local actual_7_auto
    do
      local config = load_config()
      if config["module-missing"] then
        actual_7_auto = config
      else
        actual_7_auto = config.validate({lint = {["spec-files"] = {"^fnl/spec/"}, exclusions = {{rule = "if-branch-call", form = "fnl/a.fnl > top#1", reason = "why"}}}})
      end
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an exclusion through validate", _122_)
  local function _124_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint must be a table"
    local actual_7_auto = validation_error_message("{:lint 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-table lint value", _124_)
  local function _125_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "unknown lint key: 1", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {1 true :z 1}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a numeric lint key without crashing", _125_)
  local function _126_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "unknown lint rule: true", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:rules {true :error}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a boolean lint rule key without crashing", _126_)
  local function _127_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "unknown lint key: true", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {true 1}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a boolean lint key without crashing", _127_)
  local function _128_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "lint exclusion 1: unknown key 1", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:exclusions [{1 \"x\" :rule \"if-branch-call\" :form \"f\" :reason \"r\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a numeric lint exclusion key without crashing", _128_)
  local function _129_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "lint exclusion 1: unknown key true", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:exclusions [{true \"x\" :rule \"if-branch-call\" :form \"f\" :reason \"r\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a boolean lint exclusion key without crashing", _129_)
  local function _130_()
    local key = {}
    local exclusion = {rule = "if-branch-call", form = "f", reason = "r"}
    local value = {lint = {exclusions = {exclusion}}}
    exclusion[key] = "x"
    local summary = validation_call_summary(value)
    local message = summary.message
    local prefix = "lint exclusion 1: unknown key table"
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["prefix-ok?"] = (message and (prefix == string.sub(message, 1, 35))), ["crashed?"] = false}
    local actual_7_auto = {["crashed?"] = summary["crashed?"], ["prefix-ok?"] = (message and (prefix == string.sub(message, 1, 35)))}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a table lint exclusion key without crashing", _130_)
  local function _131_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "lint rule if-branch-call must be error, warning, or off", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:rules {\"if-branch-call\" {}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a lint rule with a table severity without crashing", _131_)
  local function _132_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "lint exclusion 1: unknown key 1", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:exclusions [[1 2]]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a list-valued lint exclusion without crashing", _132_)
  local function _133_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "lint exclusion 1: rule must be a string", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:exclusions [{:rule {} :form \"f\" :reason \"r\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a lint exclusion with a table rule without crashing", _133_)
  local function _134_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown lint key: extra"
    local actual_7_auto = validation_error_message("{:lint {:extra true}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint key", _134_)
  local function _135_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown lint key: extra"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [] :extra true}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint key after lint exclusions", _135_)
  local function _136_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown lint key: extra"
    local actual_7_auto = validation_error_message("{:lint {:rules {} :extra true}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint key after lint rules", _136_)
  local function _137_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["unknown-key?"] = true}
    local actual_7_auto = unknown_lint_key_summary({lint = {rules = {}, exclusions = {}, a = 1, b = 2, c = 3}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint key among multiple lint keys", _137_)
  local function _138_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint rules must be a table"
    local actual_7_auto = validation_error_message("{:lint {:rules []}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-table lint rules value", _138_)
  local function _139_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {one = "lint rules must be a table", two = "lint rules must be a table"}
    local actual_7_auto = {one = validation_error_message("{:lint {:rules 1}}"), two = validation_error_message("{:lint {:rules \\\"x\\\"}}")}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects scalar lint rules values without crashing", _139_)
  local function _140_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown lint rule: nope"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"nope\" :error}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint rule", _140_)
  local function _141_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint rule if-branch-call must be error, warning, or off"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"if-branch-call\" :debug}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an invalid lint rule severity", _141_)
  local function _142_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusions must be a list"
    local actual_7_auto = validation_error_message("{:lint {:exclusions {}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-list lint exclusions value", _142_)
  local function _143_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusions must be a list"
    local actual_7_auto = validation_error_message("{:lint {:exclusions {1 {:rule \"if-branch-call\" :form \"x\" :reason \"ok\"}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a numeric-keyed lint exclusions map", _143_)
  local function _144_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusions must be a list"
    local actual_7_auto = validation_error_message("{:lint {:exclusions {1 {:rule \"if-branch-call\" :form \"x\" :reason \"ok\"} 2 {:rule \"if-branch-call\" :form \"y\" :reason \"ok\"}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a lint exclusions map with two numeric keys", _144_)
  local function _145_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary(parse_value("{:lint {:exclusions [{:rule \"if-branch-call\" :form \"x\" :reason \"ok\"}]}}"))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a non-empty lint exclusions list from parsed Fennel", _145_)
  local function _146_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary(parse_value("{:lint {:exclusions []}}"))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an empty lint exclusions list from parsed Fennel", _146_)
  local function _147_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 1 must be a table"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [1]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-table lint exclusion", _147_)
  local function _148_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 1: unknown key fingerprint"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [{:rule \"if-branch-call\" :form \"x\" :reason \"why\" :fingerprint \"old\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint exclusion key", _148_)
  local function _149_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 1: rule must be a string"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [{:rule 1 :form \"x\" :reason \"why\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-string lint exclusion field", _149_)
  local function _150_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 1: reason must not be blank"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [{:rule \"if-branch-call\" :form \"x\" :reason \"\\t\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a blank lint exclusion reason", _150_)
  local function _151_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 1: unknown rule nope"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [{:rule \"nope\" :form \"x\" :reason \"why\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint exclusion rule", _151_)
  local function _152_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 2: duplicate of exclusion 1"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [{:rule \"if-branch-call\" :form \"x\" :reason \"one\"} {:rule \"if-branch-call\" :form \"x\" :reason \"two\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects duplicate lint exclusions", _152_)
end
require("plenary.busted").describe("lint-configuration", _99_)
local function _153_()
  local assert_5_auto = require("luassert")
  local expected_6_auto = {["value?"] = true, ["has-message"] = false}
  local actual_7_auto = validate_summary({lint = {exclusions = {{rule = "if-branch-call", lines = {from = 1, to = 2}}, {rule = "if-branch-call", lines = {from = 3, to = 4}}}}})
  assert_5_auto.same(expected_6_auto, actual_7_auto)
  return true
end
require("plenary.busted").it("accepts duplicate rule exclusions when their line ranges differ", _153_)
local function _154_()
  local assert_5_auto = require("luassert")
  local expected_6_auto = {["value?"] = true, ["has-message"] = false}
  local actual_7_auto = validate_summary({lint = {exclusions = {{rules = {"if-branch-call", "module-style"}, line = 1}, {rules = {"if-branch-call", "no-mutation"}, line = 1}}}})
  assert_5_auto.same(expected_6_auto, actual_7_auto)
  return true
end
require("plenary.busted").it("accepts general exclusions when their rule lists differ", _154_)
local function _155_()
  local function _156_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({lint = {["spec-files"] = {"^fnl/spec/"}, rules = {["if-without-else"] = {severity = "warning", options = {["applies-to"] = "all", ["if-forms"] = {"if"}, ["flag-nil-else"] = true}, exclusions = {{pattern = "^fnl/", line = 1}}}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts per-rule exclusions without a rule selector", _156_)
  local function _157_()
    local assert_12_auto = require("luassert")
    local expected_13_auto = nil
    local actual_14_auto = validation_error_message("{:lint {:rules {\"if-without-else\" {:severity :warning :exclusions [{:rule \"if-without-else\" :line 1}]}}}}")
    assert_12_auto.are_not.same(expected_13_auto, actual_14_auto)
    return true
  end
  require("plenary.busted").it("rejects a rule selector inside a per-rule exclusion", _157_)
  local function _158_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({lint = {exclusions = {{rule = "if-without-else", line = 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a general exclusion with a rule selector", _158_)
  local function _159_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({lint = {exclusions = {{rules = {"if-without-else", "module-style"}, line = 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a general exclusion with multiple rule selectors", _159_)
  local function _160_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({lint = {exclusions = {{line = 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a general exclusion without a rule selector", _160_)
  local function _161_()
    local assert_12_auto = require("luassert")
    local expected_13_auto = nil
    local actual_14_auto = validation_error_message("{:lint {:exclusions [{:rule \"if-without-else\" :rules [\"module-style\"] :line 1}]}}")
    assert_12_auto.are_not.same(expected_13_auto, actual_14_auto)
    return true
  end
  require("plenary.busted").it("rejects both rule selector forms together", _161_)
  local function _162_()
    local assert_12_auto = require("luassert")
    local expected_13_auto = nil
    local actual_14_auto = validation_error_message("{:lint {:exclusions [{:wat true :line 1}]}}")
    assert_12_auto.are_not.same(expected_13_auto, actual_14_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown exclusion key", _162_)
  local function _163_()
    local assert_12_auto = require("luassert")
    local expected_13_auto = nil
    local actual_14_auto = validation_error_message("{:lint {:exclusions [{:rule \"if-without-else\"}]}}")
    assert_12_auto.are_not.same(expected_13_auto, actual_14_auto)
    return true
  end
  require("plenary.busted").it("rejects an exclusion without a selector", _163_)
  local function _164_()
    local assert_12_auto = require("luassert")
    local expected_13_auto = nil
    local actual_14_auto = validation_error_message("{:lint {:exclusions [{:line 1 :lines {:from 1 :to 2}}]}}")
    assert_12_auto.are_not.same(expected_13_auto, actual_14_auto)
    return true
  end
  require("plenary.busted").it("rejects line and lines together", _164_)
  local function _165_()
    local assert_12_auto = require("luassert")
    local expected_13_auto = nil
    local actual_14_auto = validation_error_message("{:lint {:exclusions [{:lines {:from 3 :to 2}}]}}")
    assert_12_auto.are_not.same(expected_13_auto, actual_14_auto)
    return true
  end
  require("plenary.busted").it("rejects invalid line ranges", _165_)
  local function _166_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({lint = {exclusions = {{line = 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an omitted reason", _166_)
  local function _167_()
    local assert_12_auto = require("luassert")
    local expected_13_auto = nil
    local actual_14_auto = validation_error_message("{:lint {:exclusions [{:line 1 :reason \"  \"}]}}")
    assert_12_auto.are_not.same(expected_13_auto, actual_14_auto)
    return true
  end
  require("plenary.busted").it("rejects a blank reason", _167_)
  local function _168_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {exclusions = {{pattern = "\\d\\+", line = 1}}}}
    local actual_7_auto = parse_value("{:lint {:exclusions [{:pattern \\\"\\\\d\\\\+\\\" :line 1}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("parses doubled backslashes in a regex selector", _168_)
end
require("plenary.busted").describe("exclusion-shapes", _155_)
local function _169_()
  local function _170_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value-nil?"] = true, message = "unknown lint rule: true"}
    local actual_7_auto = lint_policy_summary({lint = {rules = {[true] = "error"}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("returns a validation error for a malformed lint rule key", _170_)
  local function _171_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value-nil?"] = true, message = "lint exclusion 1: reason must not be blank"}
    local actual_7_auto = lint_policy_summary({lint = {exclusions = {{rule = "if-branch-call", form = "x", reason = ""}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("returns a validation error for a blank lint exclusion reason", _171_)
  local function _172_()
    local config = load_config()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "missing lint.spec-files"
    local actual_7_auto
    if config["module-missing"] then
      actual_7_auto = nil
    else
      local ok, value, err
      local function _173_()
        return config["lint-policy"]({lint = {}})
      end
      ok, value, err = pcall(_173_)
      actual_7_auto = (ok and (nil == value) and err and err.message)
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("lint policy reports missing spec-files instead of supplying a default", _172_)
  local function _175_()
    local policy = lint_policy_value({lint = {["spec-files"] = {"^fnl/spec/"}, rules = {["file-size"] = {severity = "warning", options = {["applies-to"] = "source", ["max-code-lines"] = 10}}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = 10
    local actual_7_auto = policy.options["file-size"]["max-code-lines"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("normalizes a configured max-code-lines value", _175_)
  local function _176_()
    local function _177_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {rules = {["file-size"] = "warning"}, options = {["file-size"] = {["applies-to"] = "source", ["max-code-lines"] = 25}}}
      local actual_7_auto
      do
        local policy = lint_policy_value({lint = {["spec-files"] = {"^fnl/spec/"}, rules = {["file-size"] = {severity = "warning", options = {["applies-to"] = "source", ["max-code-lines"] = 25}}}}})
        if policy.error then
          actual_7_auto = policy
        else
          actual_7_auto = {rules = {["file-size"] = policy.rules["file-size"]}, options = {["file-size"] = policy.options["file-size"]}}
        end
      end
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a rule map accepts severity and options", _177_)
    local function _179_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = "lint rule file-size severity must be error, warning, or off"
      local actual_7_auto = validation_error_message("{:lint {:rules {\"file-size\" {:options {:max-code-lines 25}}}}}")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a rule map without severity is a configuration error", _179_)
    local function _180_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = "lint rule file-size: unknown key extra"
      local actual_7_auto = validation_error_message("{:lint {:rules {\"file-size\" {:severity :warning :extra true}}}}")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("unknown rule map keys are configuration errors", _180_)
    local function _181_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = "unknown option nope for lint rule file-size"
      local actual_7_auto = validation_error_message("{:lint {:rules {\"file-size\" {:severity :off :options {:nope 1}}}}}")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("unknown options are rejected even when the rule is off", _181_)
    local function _182_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = "unknown lint key: max-code-lines"
      local actual_7_auto = validation_error_message("{:lint {:max-code-lines 10 :rules {\"file-size\" {:severity :warning :options {:applies-to \"source\" :max-code-lines 20}}}}}")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("top-level max-code-lines is rejected", _182_)
    local function _183_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {["value?"] = true, ["has-message"] = false}
      local actual_7_auto = validate_summary(parse_value("{:lint {:spec-files [\"^fnl/spec/\"] :rules {\"file-size\" {:severity :warning :options {:applies-to \"source\" :max-code-lines 10}}}}}"))
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("nested max-code-lines is accepted", _183_)
  end
  return require("plenary.busted").describe("lint-policy-opt-in", _176_)
end
require("plenary.busted").describe("lint-policy", _169_)
local function _184_()
  local function _185_()
    local config = load_config()
    local path = (vim.fn.getcwd() .. "/.fnl-extras.fnl")
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["module-style"] = "error", ["spec-macro-import"] = "error", ["spec-no-module"] = "error", ["spec-direct-require"] = "error", ["one-is-per-testing"] = "error", ["if-branch-call"] = "warning", ["if-without-else"] = "warning", ["control-layout"] = "warning", ["defn-args-newline"] = "warning", ["multiline-layout"] = "warning", ["function-shape"] = "warning", ["no-mutation"] = "warning", ["file-size"] = "warning", ["core-require"] = "error", ["unused-and-or"] = "warning", ["binding-per-line"] = "warning", ["call-data-arg"] = "warning"}
    local actual_7_auto
    if config["module-missing"] then
      actual_7_auto = config
    else
      local ok, loaded
      local function _186_()
        return config.load(path)
      end
      ok, loaded = pcall(_186_)
      if not ok then
        actual_7_auto = {["load-error"] = true}
      else
        local policy = config["lint-policy"](loaded)
        actual_7_auto = policy.rules
      end
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("repository config enables all seventeen rules with approved severities", _185_)
end
require("plenary.busted").describe("repo-policy", _184_)
local function _189_()
  local function _190_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "macro-module must be a string"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"module-style\" {:severity :warning :options {:macro-module 1}}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a string option with the wrong type", _190_)
  local function _191_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "required-macros must be a list of strings"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"module-style\" {:severity :warning :options {:required-macros \"module\"}}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a list option with the wrong type", _191_)
  local function _192_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "count must be a positive integer"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"one-is-per-testing\" {:severity :warning :options {:count 0}}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a positive integer option with the wrong type", _192_)
  local function _193_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "flag-nil-else must be a boolean"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"if-without-else\" {:severity :warning :options {:flag-nil-else \"yes\"}}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a boolean option with the wrong type", _193_)
  local function _194_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown option nope for lint rule module-style"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"module-style\" {:severity :off :options {:nope true}}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown option with the rule and option names", _194_)
  local function _195_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "applies-to must be source, spec, or all"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"module-style\" {:severity :off :options {:applies-to :tests}}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an invalid applies-to value", _195_)
  local function _196_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "spec-files must be a list of strings"
    local actual_7_auto = validation_error_message("{:lint {:spec-files \"^test/\"}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects spec-files when it is not a list", _196_)
  local function _197_()
    local result = lint_policy_value({lint = {["spec-files"] = {"^fnl/spec/"}, rules = {["module-style"] = "warning"}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = "missing lint.rules.module-style.options.applies-to"
    local actual_7_auto = result.error
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("lint policy requires explicit rule options for enabled rules", _197_)
end
require("plenary.busted").describe("lint-rule-option-validation", _189_)
local function _198_()
  local function _199_()
    local source = "(when condition\n(foo)\n(bar))"
    local without_lint = {indents = {when = {{"block", 1}}}}
    local with_lint = {indents = {when = {{"block", 1}}}, lint = {rules = {["if-branch-call"] = "off"}}}
    local plain_result = format_with_config(source, formatter_projection(without_lint))
    local lint_result = format_with_config(source, formatter_projection(with_lint))
    local assert_5_auto = require("luassert")
    local expected_6_auto = plain_result.value
    local actual_7_auto = lint_result.value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("lint configuration does not change formatter output", _199_)
end
require("plenary.busted").describe("formatter-isolation", _198_)
local function _200_()
  local function _201_()
    local policy = lint_policy_value({lint = {["spec-files"] = {"^fnl/spec/"}, rules = {["if-without-else"] = {severity = "warning", options = {["applies-to"] = "all", ["if-forms"] = {"if"}, ["flag-nil-else"] = true}}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["if"] = "warning", mutation = "off"}
    local actual_7_auto = {["if"] = policy.rules["if-without-else"], mutation = policy.rules["no-mutation"]}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a listed rule does not inherit compatibility severities for unlisted rules", _201_)
  local function _202_()
    local policy = lint_policy_value({lint = {["spec-files"] = {"^fnl/spec/"}, rules = {["file-size"] = {severity = "warning", options = {["applies-to"] = "source", ["max-code-lines"] = 3}}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = 3
    local actual_7_auto = policy.options["file-size"]["max-code-lines"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("file-size keeps its nested max-code-lines option", _202_)
end
return require("plenary.busted").describe("lint-policy-regressions", _200_)
