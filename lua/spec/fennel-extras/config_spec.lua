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
local function validate_summary(value)
  local config = load_config()
  if config["module-missing"] then
    return config
  else
    local ok, result, err
    local function _8_()
      return config.validate(value)
    end
    ok, result, err = pcall(_8_)
    return {["value?"] = (ok and (nil ~= result)), ["has-message"] = (ok and (nil == result) and err and ("table" == type(err)) and ("string" == type(err.message)))}
  end
end
local function validation_error_message(text)
  local config = load_config()
  local value = parse_value(text)
  if (config["module-missing"] or (value == nil)) then
    return nil
  else
    local ok, result, err
    local function _10_()
      return config.validate(value)
    end
    ok, result, err = pcall(_10_)
    if (ok and (result == nil) and err) then
      return err.message
    else
      return nil
    end
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
  local function _13_()
    return vim.fn.delete(root, "rf")
  end
  local function _14_()
    write_file(root_config, "{:exclude [\"root\"]}")
    write_file(config_path, "{:paths [\"fnl\"]}")
    write_file((root .. "/valid.fnl-extras.fnl"), "{:exclude [\"generated\"]}")
    local _15_
    do
      local config = load_config()
      if config["module-missing"] then
        _15_ = config
      else
        _15_ = config.find(root)
      end
    end
    local _17_
    do
      local config = load_config()
      if config["module-missing"] then
        _17_ = config
      else
        _17_ = config.find(nested)
      end
    end
    local _19_
    do
      local config = load_config()
      if config["module-missing"] then
        _19_ = config
      else
        _19_ = config.find(stop_nested)
      end
    end
    local _21_
    do
      local config = load_config()
      if config["module-missing"] then
        _21_ = config
      else
        _21_ = config.load(config_path)
      end
    end
    local _23_
    do
      local config = load_config()
      if config["module-missing"] then
        _23_ = config
      else
        local ok, value, err
        local function _25_()
          return config.load((root .. "/missing.fnl-extras.fnl"))
        end
        ok, value, err = pcall(_25_)
        _23_ = {["value?"] = (ok and (nil ~= value)), ["has-message"] = (ok and (nil == value) and err and ("table" == type(err)) and ("string" == type(err.message)))}
      end
    end
    return {start = _15_, parent = _17_, stopped = _19_, ["root-config"] = root_config, ["config-path"] = config_path, loaded = _21_, missing = _23_}
  end
  return with_cleanup(_13_, _14_)
end
local function _27_()
  local function _28_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {indents = {deftest = {{"block", 1}}, testing = {{"block", 1}}}, ["format-as"] = {["my-let"] = "let"}, paths = {"fnl"}, exclude = {"fnl/eca/nfnl"}}
    local actual_7_auto = parse_value("{:indents {\"deftest\" [[:block 1]] \"testing\" [[:block 1]]} :format-as {\"my-let\" \"let\"} :paths [\"fnl\"] :exclude [\"fnl/eca/nfnl\"]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("parses a realistic data-only configuration and converts keywords to strings", _28_)
  local function _29_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {text = "quote \" slash \\ line\n tab\t", one = 1, decimal = 2.5, negative = -3, yes = true, nothing = nil, no = false}
    local actual_7_auto = parse_value("{:text \"quote \\\" slash \\\\ line\\n tab\\t\" ; comment\n :one 1 :decimal 2.5 :negative -3 :yes true :no false :nothing nil}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("parses escapes, numbers, booleans, nil, and ignores comments", _29_)
end
require("plenary.busted").describe("parse-string", _27_)
local function _30_()
  local function _31_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, line = 1, col = 5, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a (require :x)}", true)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a list and reports line 1 column 5", _31_)
  local function _32_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a foo}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a bare symbol", _32_)
  local function _33_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a #(x)}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects hash reader prefixes", _33_)
  local function _34_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{} {}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects more than one top-level form", _34_)
  local function _35_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an empty file", _35_)
  local function _36_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("[1]", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-table top-level form", _36_)
  local function _37_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a 1", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects unbalanced input", _37_)
  local function _38_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = validate_summary({colour = 1})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("validate rejects an unknown top-level key", _38_)
  local function _39_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = validate_summary({paths = "fnl"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("validate rejects paths that are not a sequence", _39_)
end
require("plenary.busted").describe("rejection", _30_)
local function _40_()
  local function _41_()
    local result = find_load_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["root-config"]
    local actual_7_auto = result.start
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("find returns a config in the start directory", _41_)
  local function _42_()
    local result = find_load_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["config-path"]
    local actual_7_auto = result.parent
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("find returns the nearest config in a parent directory", _42_)
  local function _43_()
    local assert_25_auto = require("luassert")
    local value_26_auto = find_load_scenario().stopped
    assert_25_auto.is_nil(value_26_auto)
    return true
  end
  require("plenary.busted").it("find stops at a .git directory", _43_)
  local function _44_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {paths = {"fnl"}}
    local actual_7_auto = find_load_scenario().loaded
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("load returns the validated table from a file", _44_)
  local function _45_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = find_load_scenario().missing
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("load returns a structured error for a missing path", _45_)
end
require("plenary.busted").describe("find-load", _40_)
local function _46_()
  local function _47_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({["indent-width"] = 4})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an indent width of four", _47_)
  local function _48_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({builtins = true})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the default builtins setting", _48_)
  local function _49_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({builtins = false})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts disabling builtins", _49_)
  local function _50_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({builtins = {foo = {{"block", 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a replacement builtins table", _50_)
  local function _51_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({["prefix-fallbacks"] = false})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts disabling prefix fallbacks", _51_)
  local function _52_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({["prefix-fallbacks"] = {["foo-"] = {{"block", 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a replacement prefix fallback table", _52_)
  local function _53_()
    local message = validation_error_message("{:indent-width 0}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects zero indent width with a specific validation message", _53_)
  local function _54_()
    local message = validation_error_message("{:indent-width -1}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects negative indent width with a specific validation message", _54_)
  local function _55_()
    local message = validation_error_message("{:indent-width 2.5}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects non-integer indent width with a specific validation message", _55_)
  local function _56_()
    local message = validation_error_message("{:indent-width \"4\"}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects string indent width with a specific validation message", _56_)
  local function _57_()
    local message = validation_error_message("{:builtins 1}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "builtins must be true, false, or a table of rules"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects malformed builtins with a specific validation message", _57_)
  local function _58_()
    local message = validation_error_message("{:prefix-fallbacks 1}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "prefix-fallbacks must be false or a table of rules"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects malformed prefix fallbacks with a specific validation message", _58_)
  local function _59_()
    local message = validation_error_message("{:builtins {\"foo\" 1}}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "builtins rule foo: invalid indentation rule"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects malformed builtins rules with a specific validation message", _59_)
  local function _60_()
    local message = validation_error_message("{:prefix-fallbacks {\"foo-\" 1}}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "prefix-fallbacks rule foo-: invalid indentation rule"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects malformed prefix fallback rules with a specific validation message", _60_)
end
require("plenary.busted").describe("new-configuration", _46_)
local function _61_()
  local function _62_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({extensions = {".fnl", ".fnlm"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a non-empty list of dotted extension strings", _62_)
  local function _63_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions []}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an empty extensions list with the exact validation message", _63_)
  local function _64_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions [1]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects non-string extensions with the exact validation message", _64_)
  local function _65_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions [\"fnl\"]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects extensions without a leading dot with the exact validation message", _65_)
  local function _66_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions \".fnl\"}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects a non-list extensions value with the exact validation message", _66_)
end
require("plenary.busted").describe("extensions", _61_)
local function _67_()
  local function _68_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the default paths behavior without a paths key", _68_)
  local function _69_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "skip-dotfiles must be a boolean"
    local actual_7_auto = validation_error_message("{:skip-dotfiles 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-boolean skip-dotfiles value with the exact validation message", _69_)
  local function _70_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "follow-symlinks must be a boolean"
    local actual_7_auto = validation_error_message("{:follow-symlinks 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-boolean follow-symlinks value with the exact validation message", _70_)
  local function _71_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "parser must be a string"
    local actual_7_auto = validation_error_message("{:parser 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects a non-string parser value with the exact validation message", _71_)
end
return require("plenary.busted").describe("new-keys", _67_)
