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
local function validation_call_summary(text_or_value)
  local config = load_config()
  local value
  if ("string" == type(text_or_value)) then
    value = parse_value(text_or_value)
  else
    value = text_or_value
  end
  if (config["module-missing"] or (value == nil)) then
    return {message = nil, ["crashed?"] = false}
  else
    local ok, result, err
    local function _14_()
      return config.validate(value)
    end
    ok, result, err = pcall(_14_)
    return {["crashed?"] = not ok, message = (ok and (nil == result) and err and err.message)}
  end
end
local function lint_policy_summary(value)
  local config = load_config()
  if config["module-missing"] then
    return config
  else
    local ok, policy, err
    local function _16_()
      return config["lint-policy"](value)
    end
    ok, policy, err = pcall(_16_)
    return {["value-nil?"] = (ok and (nil == policy)), message = (ok and (nil == policy) and err and err.message)}
  end
end
local function lint_policy_value(value)
  local config = load_config()
  if config["module-missing"] then
    return config
  else
    local ok, policy, err
    local function _18_()
      return config["lint-policy"](value)
    end
    ok, policy, err = pcall(_18_)
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
    local function _21_()
      return config.validate(value)
    end
    ok, result, err = pcall(_21_)
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
  local function _23_()
    return vim.fn.delete(root, "rf")
  end
  local function _24_()
    write_file(root_config, "{:exclude [\"root\"]}")
    write_file(config_path, "{:paths [\"fnl\"]}")
    write_file((root .. "/valid.fnl-extras.fnl"), "{:exclude [\"generated\"]}")
    local _25_
    do
      local config = load_config()
      if config["module-missing"] then
        _25_ = config
      else
        _25_ = config.find(root)
      end
    end
    local _27_
    do
      local config = load_config()
      if config["module-missing"] then
        _27_ = config
      else
        _27_ = config.find(nested)
      end
    end
    local _29_
    do
      local config = load_config()
      if config["module-missing"] then
        _29_ = config
      else
        _29_ = config.find(stop_nested)
      end
    end
    local _31_
    do
      local config = load_config()
      if config["module-missing"] then
        _31_ = config
      else
        _31_ = config.load(config_path)
      end
    end
    local _33_
    do
      local config = load_config()
      if config["module-missing"] then
        _33_ = config
      else
        local ok, value, err
        local function _35_()
          return config.load((root .. "/missing.fnl-extras.fnl"))
        end
        ok, value, err = pcall(_35_)
        _33_ = {["value?"] = (ok and (nil ~= value)), ["has-message"] = (ok and (nil == value) and err and ("table" == type(err)) and ("string" == type(err.message)))}
      end
    end
    return {start = _25_, parent = _27_, stopped = _29_, ["root-config"] = root_config, ["config-path"] = config_path, loaded = _31_, missing = _33_}
  end
  return with_cleanup(_23_, _24_)
end
local function _37_()
  local function _38_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {indents = {deftest = {{"block", 1}}, testing = {{"block", 1}}}, ["format-as"] = {["my-let"] = "let"}, paths = {"fnl"}, exclude = {"fnl/eca/nfnl"}}
    local actual_7_auto = parse_value("{:indents {\"deftest\" [[:block 1]] \"testing\" [[:block 1]]} :format-as {\"my-let\" \"let\"} :paths [\"fnl\"] :exclude [\"fnl/eca/nfnl\"]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("parses a realistic data-only configuration and converts keywords to strings", _38_)
  local function _39_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {text = "quote \" slash \\ line\n tab\t", one = 1, decimal = 2.5, negative = -3, yes = true, nothing = nil, no = false}
    local actual_7_auto = parse_value("{:text \"quote \\\" slash \\\\ line\\n tab\\t\" ; comment\n :one 1 :decimal 2.5 :negative -3 :yes true :no false :nothing nil}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("parses escapes, numbers, booleans, nil, and ignores comments", _39_)
end
require("plenary.busted").describe("parse-string", _37_)
local function _40_()
  local function _41_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, line = 1, col = 5, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a (require :x)}", true)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a list and reports line 1 column 5", _41_)
  local function _42_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a foo}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a bare symbol", _42_)
  local function _43_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a #(x)}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects hash reader prefixes", _43_)
  local function _44_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{} {}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects more than one top-level form", _44_)
  local function _45_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an empty file", _45_)
  local function _46_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("[1]", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-table top-level form", _46_)
  local function _47_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a 1", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects unbalanced input", _47_)
  local function _48_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = validate_summary({colour = 1})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("validate rejects an unknown top-level key", _48_)
  local function _49_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = validate_summary({paths = "fnl"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("validate rejects paths that are not a sequence", _49_)
end
require("plenary.busted").describe("rejection", _40_)
local function _50_()
  local function _51_()
    local result = find_load_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["root-config"]
    local actual_7_auto = result.start
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("find returns a config in the start directory", _51_)
  local function _52_()
    local result = find_load_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["config-path"]
    local actual_7_auto = result.parent
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("find returns the nearest config in a parent directory", _52_)
  local function _53_()
    local assert_25_auto = require("luassert")
    local value_26_auto = find_load_scenario().stopped
    assert_25_auto.is_nil(value_26_auto)
    return true
  end
  require("plenary.busted").it("find stops at a .git directory", _53_)
  local function _54_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {paths = {"fnl"}}
    local actual_7_auto = find_load_scenario().loaded
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("load returns the validated table from a file", _54_)
  local function _55_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = find_load_scenario().missing
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("load returns a structured error for a missing path", _55_)
end
require("plenary.busted").describe("find-load", _50_)
local function _56_()
  local function _57_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({["indent-width"] = 4})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an indent width of four", _57_)
  local function _58_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({builtins = true})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the default builtins setting", _58_)
  local function _59_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({builtins = false})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts disabling builtins", _59_)
  local function _60_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({builtins = {foo = {{"block", 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a replacement builtins table", _60_)
  local function _61_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({["prefix-fallbacks"] = false})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts disabling prefix fallbacks", _61_)
  local function _62_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({["prefix-fallbacks"] = {["foo-"] = {{"block", 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a replacement prefix fallback table", _62_)
  local function _63_()
    local message = validation_error_message("{:indent-width 0}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects zero indent width with a specific validation message", _63_)
  local function _64_()
    local message = validation_error_message("{:indent-width -1}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects negative indent width with a specific validation message", _64_)
  local function _65_()
    local message = validation_error_message("{:indent-width 2.5}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects non-integer indent width with a specific validation message", _65_)
  local function _66_()
    local message = validation_error_message("{:indent-width \"4\"}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects string indent width with a specific validation message", _66_)
  local function _67_()
    local message = validation_error_message("{:builtins 1}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "builtins must be true, false, or a table of rules"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects malformed builtins with a specific validation message", _67_)
  local function _68_()
    local message = validation_error_message("{:prefix-fallbacks 1}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "prefix-fallbacks must be false or a table of rules"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects malformed prefix fallbacks with a specific validation message", _68_)
  local function _69_()
    local message = validation_error_message("{:builtins {\"foo\" 1}}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "builtins rule foo: invalid indentation rule"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects malformed builtins rules with a specific validation message", _69_)
  local function _70_()
    local message = validation_error_message("{:prefix-fallbacks {\"foo-\" 1}}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "prefix-fallbacks rule foo-: invalid indentation rule"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects malformed prefix fallback rules with a specific validation message", _70_)
end
require("plenary.busted").describe("new-configuration", _56_)
local function _71_()
  local function _72_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({extensions = {".fnl", ".fnlm"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a non-empty list of dotted extension strings", _72_)
  local function _73_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions []}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an empty extensions list with the exact validation message", _73_)
  local function _74_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions [1]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects non-string extensions with the exact validation message", _74_)
  local function _75_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions [\"fnl\"]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects extensions without a leading dot with the exact validation message", _75_)
  local function _76_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions \".fnl\"}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects a non-list extensions value with the exact validation message", _76_)
end
require("plenary.busted").describe("extensions", _71_)
local function _77_()
  local function _78_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the default paths behavior without a paths key", _78_)
  local function _79_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "skip-dotfiles must be a boolean"
    local actual_7_auto = validation_error_message("{:skip-dotfiles 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-boolean skip-dotfiles value with the exact validation message", _79_)
  local function _80_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "follow-symlinks must be a boolean"
    local actual_7_auto = validation_error_message("{:follow-symlinks 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-boolean follow-symlinks value with the exact validation message", _80_)
  local function _81_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "parser must be a string"
    local actual_7_auto = validation_error_message("{:parser 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-string parser value with the exact validation message", _81_)
  local function _82_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({["align-bindings"] = true})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a boolean align-bindings value", _82_)
  local function _83_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "align-bindings must be a boolean"
    local actual_7_auto = validation_error_message("{:align-bindings \"yes\"}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects a non-boolean align-bindings value with the exact validation message", _83_)
end
require("plenary.busted").describe("new-keys", _77_)
local function _84_()
  local function _85_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({alignment = {maps = true}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an alignment table", _85_)
  local function _86_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment must be a table"
    local actual_7_auto = validation_error_message("{:alignment true}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a boolean alignment value with the exact validation message", _86_)
  local function _87_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment must be a table"
    local actual_7_auto = validation_error_message("{:alignment \"yes\"}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a string alignment value with the exact validation message", _87_)
  local function _88_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown alignment key: nope"
    local actual_7_auto = validation_error_message("{:alignment {:nope true}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown alignment key with the key in the error", _88_)
  local function _89_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment key maps must be a boolean"
    local actual_7_auto = validation_error_message("{:alignment {:maps 1}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-boolean alignment toggle with the exact validation message", _89_)
  local function _90_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment key binding-forms must be a list of strings"
    local actual_7_auto = validation_error_message("{:alignment {:binding-forms \"let\"}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-list binding-forms value with the exact validation message", _90_)
  local function _91_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment key binding-forms must be a list of strings"
    local actual_7_auto = validation_error_message("{:alignment {:binding-forms {:foo \"bar\"}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a map binding-forms value with the exact validation message", _91_)
  local function _92_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment key clause-forms must be a list of strings"
    local actual_7_auto = validation_error_message("{:alignment {:clause-forms [1]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-string clause form with the exact validation message", _92_)
  local function _93_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "alignment key clause-forms must be a list of strings"
    local actual_7_auto = validation_error_message("{:alignment {:clause-forms {:foo \"bar\"}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a map clause-forms value with the exact validation message", _93_)
  local function _94_()
    local config = load_config()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {bindings = true, maps = true, clauses = true, ["split-bindings"] = true, ["collapse-padding"] = true}
    local actual_7_auto = config.validate({["align-bindings"] = true}).alignment
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("expands align-bindings true into all alignment toggles", _94_)
  local function _95_()
    local config = load_config()
    local value = {["align-bindings"] = true, alignment = {["split-bindings"] = false}}
    local assert_5_auto = require("luassert")
    local expected_6_auto = {bindings = true, maps = true, clauses = true, ["collapse-padding"] = true, ["split-bindings"] = false}
    local actual_7_auto = config.validate(value).alignment
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("explicit alignment toggles override the shorthand expansion", _95_)
end
require("plenary.busted").describe("alignment-configuration", _84_)
local function formatter_projection(config)
  return {indents = config.indents, ["format-as"] = config["format-as"], ["indent-patterns"] = config["indent-patterns"], ["indent-width"] = config["indent-width"], builtins = config.builtins, ["prefix-fallbacks"] = config["prefix-fallbacks"]}
end
local function format_with_config(source, config)
  local ok, format = pcall(require, "fennel-extras.format")
  if not ok then
    return {["module-missing"] = true}
  else
    local ok0, value, err
    local function _96_()
      return format["format-string"](source, {config = config})
    end
    ok0, value, err = pcall(_96_)
    return {value = value, error = err, ok = ok0}
  end
end
local function _98_()
  local function _99_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {}}
    local actual_7_auto = parse_value("{:lint {}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an empty lint table from parsed Fennel", _99_)
  local function _100_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {}}}
    local actual_7_auto = parse_value("{:lint {:rules {}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("parses an empty lint rules table from Fennel", _100_)
  local function _101_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {}}}
    local actual_7_auto
    do
      local config = load_config()
      if config["module-missing"] then
        actual_7_auto = config
      else
        actual_7_auto = config.validate({lint = {rules = {}}})
      end
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an empty lint rules table through validate", _101_)
  local function _103_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["if-branch-call"] = "error"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"if-branch-call\" :error}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a known lint rule from parsed Fennel", _103_)
  local function _104_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["no-mutation"] = "warning"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"no-mutation\" :warning}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the no-mutation lint rule from parsed Fennel", _104_)
  local function _105_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["binding-per-line"] = "warning"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"binding-per-line\" :warning}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the binding-per-line lint rule from parsed Fennel", _105_)
  local function _106_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["call-data-arg"] = "warning"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"call-data-arg\" :warning}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the call-data-arg lint rule from parsed Fennel", _106_)
  local function _107_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["defn-args-newline"] = "error"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"defn-args-newline\" :error}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the defn-args-newline lint rule from parsed Fennel", _107_)
  local function _108_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["control-layout"] = "warning"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"control-layout\" :warning}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the control-layout lint rule from parsed Fennel", _108_)
  local function _109_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["unused-and-or"] = "warning"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"unused-and-or\" :warning}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the unused-and-or lint rule from parsed Fennel", _109_)
  local function _110_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({lint = {["max-code-lines"] = 10}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a positive max-code-lines value", _110_)
  local function _111_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "max-code-lines must be a positive integer"
    local actual_7_auto = validation_error_message("{:lint {:max-code-lines 0}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects zero max-code-lines with a specific validation message", _111_)
  local function _112_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "max-code-lines must be a positive integer"
    local actual_7_auto = validation_error_message("{:lint {:max-code-lines -1}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects negative max-code-lines with a specific validation message", _112_)
  local function _113_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "max-code-lines must be a positive integer"
    local actual_7_auto = validation_error_message("{:lint {:max-code-lines 1.5}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects non-integer max-code-lines with a specific validation message", _113_)
  local function _114_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "max-code-lines must be a positive integer"
    local actual_7_auto = validation_error_message("{:lint {:max-code-lines \"10\"}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects string max-code-lines with a specific validation message", _114_)
  local function _115_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["file-size"] = "warning"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"file-size\" :warning}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the file-size lint rule from parsed Fennel", _115_)
  local function _116_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {exclusions = {{rule = "if-branch-call", form = "fnl/a.fnl > top#1", reason = "why"}}}}
    local actual_7_auto = parse_value("{:lint {:exclusions [{:rule \"if-branch-call\" :form \"fnl/a.fnl > top#1\" :reason \"why\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an exclusion from parsed Fennel", _116_)
  local function _117_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {}}
    local actual_7_auto
    do
      local config = load_config()
      if config["module-missing"] then
        actual_7_auto = config
      else
        actual_7_auto = config.validate({lint = {}})
      end
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an empty lint table through validate", _117_)
  local function _119_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["if-branch-call"] = "error"}}}
    local actual_7_auto
    do
      local config = load_config()
      if config["module-missing"] then
        actual_7_auto = config
      else
        actual_7_auto = config.validate({lint = {rules = {["if-branch-call"] = "error"}}})
      end
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a lint rule through validate", _119_)
  local function _121_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {exclusions = {{rule = "if-branch-call", form = "fnl/a.fnl > top#1", reason = "why"}}}}
    local actual_7_auto
    do
      local config = load_config()
      if config["module-missing"] then
        actual_7_auto = config
      else
        actual_7_auto = config.validate({lint = {exclusions = {{rule = "if-branch-call", form = "fnl/a.fnl > top#1", reason = "why"}}}})
      end
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an exclusion through validate", _121_)
  local function _123_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint must be a table"
    local actual_7_auto = validation_error_message("{:lint 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-table lint value", _123_)
  local function _124_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "unknown lint key: 1", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {1 true :z 1}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a numeric lint key without crashing", _124_)
  local function _125_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "unknown lint rule: true", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:rules {true :error}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a boolean lint rule key without crashing", _125_)
  local function _126_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "unknown lint key: true", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {true 1}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a boolean lint key without crashing", _126_)
  local function _127_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "lint exclusion 1: unknown key 1", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:exclusions [{1 \"x\" :rule \"if-branch-call\" :form \"f\" :reason \"r\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a numeric lint exclusion key without crashing", _127_)
  local function _128_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "lint exclusion 1: unknown key true", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:exclusions [{true \"x\" :rule \"if-branch-call\" :form \"f\" :reason \"r\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a boolean lint exclusion key without crashing", _128_)
  local function _129_()
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
  require("plenary.busted").it("rejects a table lint exclusion key without crashing", _129_)
  local function _130_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "lint rule if-branch-call must be error, warning, or off", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:rules {\"if-branch-call\" {}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a lint rule with a table severity without crashing", _130_)
  local function _131_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "lint exclusion 1: unknown key 1", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:exclusions [[1 2]]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a list-valued lint exclusion without crashing", _131_)
  local function _132_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "lint exclusion 1: rule must be a string", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:exclusions [{:rule {} :form \"f\" :reason \"r\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a lint exclusion with a table rule without crashing", _132_)
  local function _133_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown lint key: extra"
    local actual_7_auto = validation_error_message("{:lint {:extra true}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint key", _133_)
  local function _134_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown lint key: extra"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [] :extra true}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint key after lint exclusions", _134_)
  local function _135_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown lint key: extra"
    local actual_7_auto = validation_error_message("{:lint {:rules {} :extra true}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint key after lint rules", _135_)
  local function _136_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["unknown-key?"] = true}
    local actual_7_auto = unknown_lint_key_summary({lint = {rules = {}, exclusions = {}, a = 1, b = 2, c = 3}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint key among multiple lint keys", _136_)
  local function _137_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint rules must be a table"
    local actual_7_auto = validation_error_message("{:lint {:rules []}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-table lint rules value", _137_)
  local function _138_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown lint rule: nope"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"nope\" :error}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint rule", _138_)
  local function _139_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint rule if-branch-call must be error, warning, or off"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"if-branch-call\" :debug}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an invalid lint rule severity", _139_)
  local function _140_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusions must be a list"
    local actual_7_auto = validation_error_message("{:lint {:exclusions {}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-list lint exclusions value", _140_)
  local function _141_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusions must be a list"
    local actual_7_auto = validation_error_message("{:lint {:exclusions {1 {:rule \"if-branch-call\" :form \"x\" :reason \"ok\"}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a numeric-keyed lint exclusions map", _141_)
  local function _142_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusions must be a list"
    local actual_7_auto = validation_error_message("{:lint {:exclusions {1 {:rule \"if-branch-call\" :form \"x\" :reason \"ok\"} 2 {:rule \"if-branch-call\" :form \"y\" :reason \"ok\"}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a lint exclusions map with two numeric keys", _142_)
  local function _143_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary(parse_value("{:lint {:exclusions [{:rule \"if-branch-call\" :form \"x\" :reason \"ok\"}]}}"))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a non-empty lint exclusions list from parsed Fennel", _143_)
  local function _144_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary(parse_value("{:lint {:exclusions []}}"))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an empty lint exclusions list from parsed Fennel", _144_)
  local function _145_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 1 must be a table"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [1]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-table lint exclusion", _145_)
  local function _146_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 1: unknown key fingerprint"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [{:rule \"if-branch-call\" :form \"x\" :reason \"why\" :fingerprint \"old\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint exclusion key", _146_)
  local function _147_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 1: rule must be a string"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [{:rule 1 :form \"x\" :reason \"why\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-string lint exclusion field", _147_)
  local function _148_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 1: reason must not be blank"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [{:rule \"if-branch-call\" :form \"x\" :reason \"\\t\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a blank lint exclusion reason", _148_)
  local function _149_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 1: unknown rule nope"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [{:rule \"nope\" :form \"x\" :reason \"why\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint exclusion rule", _149_)
  local function _150_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 2: duplicate of exclusion 1"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [{:rule \"if-branch-call\" :form \"x\" :reason \"one\"} {:rule \"if-branch-call\" :form \"x\" :reason \"two\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects duplicate lint exclusions", _150_)
end
require("plenary.busted").describe("lint-configuration", _98_)
local function _151_()
  local assert_5_auto = require("luassert")
  local expected_6_auto = {["value?"] = true, ["has-message"] = false}
  local actual_7_auto = validate_summary({lint = {exclusions = {{rule = "if-branch-call", lines = {from = 1, to = 2}}, {rule = "if-branch-call", lines = {from = 3, to = 4}}}}})
  assert_5_auto.same(expected_6_auto, actual_7_auto)
  return true
end
require("plenary.busted").it("accepts duplicate rule exclusions when their line ranges differ", _151_)
local function _152_()
  local assert_5_auto = require("luassert")
  local expected_6_auto = {["value?"] = true, ["has-message"] = false}
  local actual_7_auto = validate_summary({lint = {exclusions = {{rules = {"if-branch-call", "module-style"}, line = 1}, {rules = {"if-branch-call", "no-mutation"}, line = 1}}}})
  assert_5_auto.same(expected_6_auto, actual_7_auto)
  return true
end
require("plenary.busted").it("accepts general exclusions when their rule lists differ", _152_)
local function _153_()
  local function _154_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({lint = {rules = {["if-without-else"] = {severity = "warning", exclusions = {{pattern = "^fnl/", line = 1}}}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts per-rule exclusions without a rule selector", _154_)
  local function _155_()
    local assert_12_auto = require("luassert")
    local expected_13_auto = nil
    local actual_14_auto = validation_error_message("{:lint {:rules {\"if-without-else\" {:severity :warning :exclusions [{:rule \"if-without-else\" :line 1}]}}}}")
    assert_12_auto.are_not.same(expected_13_auto, actual_14_auto)
    return true
  end
  require("plenary.busted").it("rejects a rule selector inside a per-rule exclusion", _155_)
  local function _156_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({lint = {exclusions = {{rule = "if-without-else", line = 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a general exclusion with a rule selector", _156_)
  local function _157_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({lint = {exclusions = {{rules = {"if-without-else", "module-style"}, line = 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a general exclusion with multiple rule selectors", _157_)
  local function _158_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({lint = {exclusions = {{line = 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a general exclusion without a rule selector", _158_)
  local function _159_()
    local assert_12_auto = require("luassert")
    local expected_13_auto = nil
    local actual_14_auto = validation_error_message("{:lint {:exclusions [{:rule \"if-without-else\" :rules [\"module-style\"] :line 1}]}}")
    assert_12_auto.are_not.same(expected_13_auto, actual_14_auto)
    return true
  end
  require("plenary.busted").it("rejects both rule selector forms together", _159_)
  local function _160_()
    local assert_12_auto = require("luassert")
    local expected_13_auto = nil
    local actual_14_auto = validation_error_message("{:lint {:exclusions [{:wat true :line 1}]}}")
    assert_12_auto.are_not.same(expected_13_auto, actual_14_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown exclusion key", _160_)
  local function _161_()
    local assert_12_auto = require("luassert")
    local expected_13_auto = nil
    local actual_14_auto = validation_error_message("{:lint {:exclusions [{:rule \"if-without-else\"}]}}")
    assert_12_auto.are_not.same(expected_13_auto, actual_14_auto)
    return true
  end
  require("plenary.busted").it("rejects an exclusion without a selector", _161_)
  local function _162_()
    local assert_12_auto = require("luassert")
    local expected_13_auto = nil
    local actual_14_auto = validation_error_message("{:lint {:exclusions [{:line 1 :lines {:from 1 :to 2}}]}}")
    assert_12_auto.are_not.same(expected_13_auto, actual_14_auto)
    return true
  end
  require("plenary.busted").it("rejects line and lines together", _162_)
  local function _163_()
    local assert_12_auto = require("luassert")
    local expected_13_auto = nil
    local actual_14_auto = validation_error_message("{:lint {:exclusions [{:lines {:from 3 :to 2}}]}}")
    assert_12_auto.are_not.same(expected_13_auto, actual_14_auto)
    return true
  end
  require("plenary.busted").it("rejects invalid line ranges", _163_)
  local function _164_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({lint = {exclusions = {{line = 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an omitted reason", _164_)
  local function _165_()
    local assert_12_auto = require("luassert")
    local expected_13_auto = nil
    local actual_14_auto = validation_error_message("{:lint {:exclusions [{:line 1 :reason \"  \"}]}}")
    assert_12_auto.are_not.same(expected_13_auto, actual_14_auto)
    return true
  end
  require("plenary.busted").it("rejects a blank reason", _165_)
  local function _166_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {exclusions = {{pattern = "\\d\\+", line = 1}}}}
    local actual_7_auto = parse_value("{:lint {:exclusions [{:pattern \\\"\\\\d\\\\+\\\" :line 1}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("parses doubled backslashes in a regex selector", _166_)
end
require("plenary.busted").describe("exclusion-shapes", _153_)
local function _167_()
  local function _168_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value-nil?"] = true, message = "unknown lint rule: true"}
    local actual_7_auto = lint_policy_summary({lint = {rules = {[true] = "error"}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("returns a validation error for a malformed lint rule key", _168_)
  local function _169_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value-nil?"] = true, message = "lint exclusion 1: reason must not be blank"}
    local actual_7_auto = lint_policy_summary({lint = {exclusions = {{rule = "if-branch-call", form = "x", reason = ""}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("returns a validation error for a blank lint exclusion reason", _169_)
  local function _170_()
    local policy = lint_policy_value({lint = {}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {rules = {["module-style"] = "off", ["spec-macro-import"] = "off", ["spec-no-module"] = "off", ["spec-direct-require"] = "off", ["one-is-per-testing"] = "off", ["if-branch-call"] = "off", ["if-without-else"] = "off", ["control-layout"] = "off", ["defn-args-newline"] = "off", ["multiline-layout"] = "off", ["function-shape"] = "off", ["no-mutation"] = "off", ["file-size"] = "off", ["core-require"] = "off", ["unused-and-or"] = "off", ["binding-per-line"] = "off", ["call-data-arg"] = "off"}, options = policy.options, ["spec-files"] = {"^fnl/spec/"}, ["max-code-lines"] = 300, exclusions = {}}
    local actual_7_auto = policy
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("normalizes lint defaults to every rule off without formatter keys", _170_)
  local function _171_()
    local config = load_config()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 10
    local actual_7_auto
    if config["module-missing"] then
      actual_7_auto = nil
    else
      local ok, value
      local function _172_()
        return config["lint-policy"]({lint = {["max-code-lines"] = 10}})
      end
      ok, value = pcall(_172_)
      actual_7_auto = (ok and value["max-code-lines"])
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("normalizes a configured max-code-lines value", _171_)
  local function _174_()
    local function _175_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {rules = {["file-size"] = "warning"}, options = {["file-size"] = {["applies-to"] = "source", ["max-code-lines"] = 25}}}
      local actual_7_auto
      do
        local policy = lint_policy_value({lint = {rules = {["file-size"] = {severity = "warning", options = {["max-code-lines"] = 25}}}}})
        if policy.error then
          actual_7_auto = policy
        else
          actual_7_auto = {rules = {["file-size"] = policy.rules["file-size"]}, options = {["file-size"] = policy.options["file-size"]}}
        end
      end
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a rule map accepts severity and options", _175_)
    local function _177_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = "lint rule file-size severity must be error, warning, or off"
      local actual_7_auto = validation_error_message("{:lint {:rules {\"file-size\" {:options {:max-code-lines 25}}}}}")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a rule map without severity is a configuration error", _177_)
    local function _178_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = "lint rule file-size: unknown key extra"
      local actual_7_auto = validation_error_message("{:lint {:rules {\"file-size\" {:severity :warning :extra true}}}}")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("unknown rule map keys are configuration errors", _178_)
    local function _179_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = "unknown option nope for lint rule file-size"
      local actual_7_auto = validation_error_message("{:lint {:rules {\"file-size\" {:severity :off :options {:nope 1}}}}}")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("unknown options are rejected even when the rule is off", _179_)
    local function _180_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = "lint max-code-lines conflicts with file-size option max-code-lines"
      local actual_7_auto = validation_error_message("{:lint {:max-code-lines 10 :rules {\"file-size\" {:severity :warning :options {:max-code-lines 20}}}}}")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("legacy and nested max-code-lines values must agree", _180_)
    local function _181_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {["value?"] = true, ["has-message"] = false}
      local actual_7_auto = validate_summary(parse_value("{:lint {:max-code-lines 10 :rules {\"file-size\" {:severity :warning :options {:max-code-lines 10}}}}}"))
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("equal legacy and nested max-code-lines values are accepted", _181_)
  end
  return require("plenary.busted").describe("lint-policy-opt-in", _174_)
end
require("plenary.busted").describe("lint-policy", _167_)
local function _182_()
  local function _183_()
    local config = load_config()
    local path = (vim.fn.getcwd() .. "/.fnl-extras.fnl")
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["module-style"] = "error", ["spec-macro-import"] = "error", ["spec-no-module"] = "error", ["spec-direct-require"] = "error", ["one-is-per-testing"] = "error", ["if-branch-call"] = "warning", ["if-without-else"] = "warning", ["control-layout"] = "warning", ["defn-args-newline"] = "warning", ["multiline-layout"] = "warning", ["function-shape"] = "warning", ["no-mutation"] = "warning", ["file-size"] = "warning", ["core-require"] = "error", ["unused-and-or"] = "warning", ["binding-per-line"] = "warning", ["call-data-arg"] = "warning"}
    local actual_7_auto
    if config["module-missing"] then
      actual_7_auto = config
    else
      local ok, loaded
      local function _184_()
        return config.load(path)
      end
      ok, loaded = pcall(_184_)
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
  return require("plenary.busted").it("repository config enables all seventeen rules with approved severities", _183_)
end
require("plenary.busted").describe("repo-policy", _182_)
local function _187_()
  local function _188_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "macro-module must be a string"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"module-style\" {:severity :warning :options {:macro-module 1}}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a string option with the wrong type", _188_)
  local function _189_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "required-macros must be a list of strings"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"module-style\" {:severity :warning :options {:required-macros \"module\"}}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a list option with the wrong type", _189_)
  local function _190_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "count must be a positive integer"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"one-is-per-testing\" {:severity :warning :options {:count 0}}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a positive integer option with the wrong type", _190_)
  local function _191_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "flag-nil-else must be a boolean"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"if-without-else\" {:severity :warning :options {:flag-nil-else \"yes\"}}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a boolean option with the wrong type", _191_)
  local function _192_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown option nope for lint rule module-style"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"module-style\" {:severity :off :options {:nope true}}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown option with the rule and option names", _192_)
  local function _193_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "applies-to must be source, spec, or all"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"module-style\" {:severity :off :options {:applies-to :tests}}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an invalid applies-to value", _193_)
  local function _194_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "spec-files must be a list of strings"
    local actual_7_auto = validation_error_message("{:lint {:spec-files \"^test/\"}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects spec-files when it is not a list", _194_)
  local function _195_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["spec-files"] = {"^fnl/spec/"}, rules = {["module-style"] = "off", ["spec-macro-import"] = "off", ["spec-no-module"] = "off", ["spec-direct-require"] = "off", ["one-is-per-testing"] = "off", ["if-branch-call"] = "off", ["if-without-else"] = "off", ["control-layout"] = "off", ["unused-and-or"] = "off", ["defn-args-newline"] = "off", ["function-shape"] = "off", ["no-mutation"] = "off", ["multiline-layout"] = "off", ["file-size"] = "off", ["core-require"] = "off", ["binding-per-line"] = "off", ["call-data-arg"] = "off"}, options = {["module-style"] = {["applies-to"] = "source", ["macro-module"] = "eca.nfnl.macros.aniseed", ["required-macros"] = {"module", "def", "defn", "defn-"}}, ["spec-macro-import"] = {["applies-to"] = "spec", ["macro-module"] = "spec.eca.macros", ["required-macros"] = {"deftest", "testing", "is"}, ["exempt-files"] = {"^fnl/spec/eca/macros[.]fnlm$"}}, ["spec-no-module"] = {["applies-to"] = "spec", ["module-form"] = "module"}, ["spec-direct-require"] = {["applies-to"] = "spec", ["forbidden-modules"] = {"plenary.busted", "luassert"}, ["exempt-files"] = {"^fnl/spec/eca/macros[.]fnlm$"}}, ["one-is-per-testing"] = {["applies-to"] = "all", ["testing-form"] = "testing", ["assertion-form"] = "is", count = 1}, ["if-branch-call"] = {["applies-to"] = "all", ["if-forms"] = {"if"}}, ["if-without-else"] = {["applies-to"] = "all", ["if-forms"] = {"if"}, ["flag-nil-else"] = true}, ["control-layout"] = {["applies-to"] = "all", ["control-forms"] = {"if", "when", "and", "or", "case", "match"}}, ["unused-and-or"] = {["applies-to"] = "all", forms = {"and", "or"}}, ["defn-args-newline"] = {["applies-to"] = "all", forms = {"defn", "defn-"}}, ["function-shape"] = {["applies-to"] = "all", ["function-forms"] = {"defn", "defn-", "fn", "lambda", "\206\187"}}, ["no-mutation"] = {["applies-to"] = "source", forms = {"var", "set", "while"}}, ["multiline-layout"] = {["applies-to"] = "all", ["clause-forms"] = {"case", "match", "case-try", "match-try"}, ["binding-forms"] = {"let", "when-let", "if-let", "with-open"}}, ["file-size"] = {["applies-to"] = "source", ["max-code-lines"] = 300}, ["core-require"] = {["applies-to"] = "all", module = "eca.nfnl.core", binding = "core"}, ["binding-per-line"] = {["applies-to"] = "all", forms = {"let", "when-let", "if-let", "with-open"}}, ["call-data-arg"] = {["applies-to"] = "source", ["ignore-forms"] = {}}}, ["max-code-lines"] = 300, exclusions = {}}
    local actual_7_auto = lint_policy_value({lint = {}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("normalizes defaults for every rule option", _195_)
end
require("plenary.busted").describe("lint-rule-option-validation", _187_)
local function _196_()
  local function _197_()
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
  return require("plenary.busted").it("lint configuration does not change formatter output", _197_)
end
return require("plenary.busted").describe("formatter-isolation", _196_)
