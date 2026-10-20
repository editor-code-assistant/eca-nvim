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
local function unknown_lint_key_summary(value)
  local config = load_config()
  if config["module-missing"] then
    return config
  else
    local ok, result, err
    local function _18_()
      return config.validate(value)
    end
    ok, result, err = pcall(_18_)
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
  local function _20_()
    return vim.fn.delete(root, "rf")
  end
  local function _21_()
    write_file(root_config, "{:exclude [\"root\"]}")
    write_file(config_path, "{:paths [\"fnl\"]}")
    write_file((root .. "/valid.fnl-extras.fnl"), "{:exclude [\"generated\"]}")
    local _22_
    do
      local config = load_config()
      if config["module-missing"] then
        _22_ = config
      else
        _22_ = config.find(root)
      end
    end
    local _24_
    do
      local config = load_config()
      if config["module-missing"] then
        _24_ = config
      else
        _24_ = config.find(nested)
      end
    end
    local _26_
    do
      local config = load_config()
      if config["module-missing"] then
        _26_ = config
      else
        _26_ = config.find(stop_nested)
      end
    end
    local _28_
    do
      local config = load_config()
      if config["module-missing"] then
        _28_ = config
      else
        _28_ = config.load(config_path)
      end
    end
    local _30_
    do
      local config = load_config()
      if config["module-missing"] then
        _30_ = config
      else
        local ok, value, err
        local function _32_()
          return config.load((root .. "/missing.fnl-extras.fnl"))
        end
        ok, value, err = pcall(_32_)
        _30_ = {["value?"] = (ok and (nil ~= value)), ["has-message"] = (ok and (nil == value) and err and ("table" == type(err)) and ("string" == type(err.message)))}
      end
    end
    return {start = _22_, parent = _24_, stopped = _26_, ["root-config"] = root_config, ["config-path"] = config_path, loaded = _28_, missing = _30_}
  end
  return with_cleanup(_20_, _21_)
end
local function _34_()
  local function _35_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {indents = {deftest = {{"block", 1}}, testing = {{"block", 1}}}, ["format-as"] = {["my-let"] = "let"}, paths = {"fnl"}, exclude = {"fnl/eca/nfnl"}}
    local actual_7_auto = parse_value("{:indents {\"deftest\" [[:block 1]] \"testing\" [[:block 1]]} :format-as {\"my-let\" \"let\"} :paths [\"fnl\"] :exclude [\"fnl/eca/nfnl\"]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("parses a realistic data-only configuration and converts keywords to strings", _35_)
  local function _36_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {text = "quote \" slash \\ line\n tab\t", one = 1, decimal = 2.5, negative = -3, yes = true, nothing = nil, no = false}
    local actual_7_auto = parse_value("{:text \"quote \\\" slash \\\\ line\\n tab\\t\" ; comment\n :one 1 :decimal 2.5 :negative -3 :yes true :no false :nothing nil}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("parses escapes, numbers, booleans, nil, and ignores comments", _36_)
end
require("plenary.busted").describe("parse-string", _34_)
local function _37_()
  local function _38_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, line = 1, col = 5, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a (require :x)}", true)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a list and reports line 1 column 5", _38_)
  local function _39_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a foo}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a bare symbol", _39_)
  local function _40_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a #(x)}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects hash reader prefixes", _40_)
  local function _41_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{} {}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects more than one top-level form", _41_)
  local function _42_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an empty file", _42_)
  local function _43_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("[1]", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-table top-level form", _43_)
  local function _44_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a 1", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects unbalanced input", _44_)
  local function _45_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = validate_summary({colour = 1})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("validate rejects an unknown top-level key", _45_)
  local function _46_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = validate_summary({paths = "fnl"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("validate rejects paths that are not a sequence", _46_)
end
require("plenary.busted").describe("rejection", _37_)
local function _47_()
  local function _48_()
    local result = find_load_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["root-config"]
    local actual_7_auto = result.start
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("find returns a config in the start directory", _48_)
  local function _49_()
    local result = find_load_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["config-path"]
    local actual_7_auto = result.parent
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("find returns the nearest config in a parent directory", _49_)
  local function _50_()
    local assert_25_auto = require("luassert")
    local value_26_auto = find_load_scenario().stopped
    assert_25_auto.is_nil(value_26_auto)
    return true
  end
  require("plenary.busted").it("find stops at a .git directory", _50_)
  local function _51_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {paths = {"fnl"}}
    local actual_7_auto = find_load_scenario().loaded
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("load returns the validated table from a file", _51_)
  local function _52_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = find_load_scenario().missing
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("load returns a structured error for a missing path", _52_)
end
require("plenary.busted").describe("find-load", _47_)
local function _53_()
  local function _54_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({["indent-width"] = 4})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an indent width of four", _54_)
  local function _55_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({builtins = true})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the default builtins setting", _55_)
  local function _56_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({builtins = false})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts disabling builtins", _56_)
  local function _57_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({builtins = {foo = {{"block", 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a replacement builtins table", _57_)
  local function _58_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({["prefix-fallbacks"] = false})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts disabling prefix fallbacks", _58_)
  local function _59_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({["prefix-fallbacks"] = {["foo-"] = {{"block", 1}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a replacement prefix fallback table", _59_)
  local function _60_()
    local message = validation_error_message("{:indent-width 0}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects zero indent width with a specific validation message", _60_)
  local function _61_()
    local message = validation_error_message("{:indent-width -1}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects negative indent width with a specific validation message", _61_)
  local function _62_()
    local message = validation_error_message("{:indent-width 2.5}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects non-integer indent width with a specific validation message", _62_)
  local function _63_()
    local message = validation_error_message("{:indent-width \"4\"}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "indent-width must be a positive integer"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects string indent width with a specific validation message", _63_)
  local function _64_()
    local message = validation_error_message("{:builtins 1}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "builtins must be true, false, or a table of rules"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects malformed builtins with a specific validation message", _64_)
  local function _65_()
    local message = validation_error_message("{:prefix-fallbacks 1}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "prefix-fallbacks must be false or a table of rules"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects malformed prefix fallbacks with a specific validation message", _65_)
  local function _66_()
    local message = validation_error_message("{:builtins {\"foo\" 1}}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "builtins rule foo: invalid indentation rule"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects malformed builtins rules with a specific validation message", _66_)
  local function _67_()
    local message = validation_error_message("{:prefix-fallbacks {\"foo-\" 1}}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "prefix-fallbacks rule foo-: invalid indentation rule"
    local actual_7_auto = message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects malformed prefix fallback rules with a specific validation message", _67_)
end
require("plenary.busted").describe("new-configuration", _53_)
local function _68_()
  local function _69_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({extensions = {".fnl", ".fnlm"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a non-empty list of dotted extension strings", _69_)
  local function _70_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions []}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an empty extensions list with the exact validation message", _70_)
  local function _71_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions [1]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects non-string extensions with the exact validation message", _71_)
  local function _72_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions [\"fnl\"]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects extensions without a leading dot with the exact validation message", _72_)
  local function _73_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "extensions must be a non-empty list of strings starting with \".\""
    local actual_7_auto = validation_error_message("{:extensions \".fnl\"}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects a non-list extensions value with the exact validation message", _73_)
end
require("plenary.busted").describe("extensions", _68_)
local function _74_()
  local function _75_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the default paths behavior without a paths key", _75_)
  local function _76_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "skip-dotfiles must be a boolean"
    local actual_7_auto = validation_error_message("{:skip-dotfiles 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-boolean skip-dotfiles value with the exact validation message", _76_)
  local function _77_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "follow-symlinks must be a boolean"
    local actual_7_auto = validation_error_message("{:follow-symlinks 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-boolean follow-symlinks value with the exact validation message", _77_)
  local function _78_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "parser must be a string"
    local actual_7_auto = validation_error_message("{:parser 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-string parser value with the exact validation message", _78_)
  local function _79_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({["align-bindings"] = true})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a boolean align-bindings value", _79_)
  local function _80_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "align-bindings must be a boolean"
    local actual_7_auto = validation_error_message("{:align-bindings \"yes\"}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects a non-boolean align-bindings value with the exact validation message", _80_)
end
require("plenary.busted").describe("new-keys", _74_)
local function formatter_projection(config)
  return {indents = config.indents, ["format-as"] = config["format-as"], ["indent-patterns"] = config["indent-patterns"], ["indent-width"] = config["indent-width"], builtins = config.builtins, ["prefix-fallbacks"] = config["prefix-fallbacks"]}
end
local function format_with_config(source, config)
  local ok, format = pcall(require, "fennel-extras.format")
  if not ok then
    return {["module-missing"] = true}
  else
    local ok0, value, err
    local function _81_()
      return format["format-string"](source, {config = config})
    end
    ok0, value, err = pcall(_81_)
    return {value = value, error = err, ok = ok0}
  end
end
local function _83_()
  local function _84_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {}}
    local actual_7_auto = parse_value("{:lint {}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an empty lint table from parsed Fennel", _84_)
  local function _85_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {}}}
    local actual_7_auto = parse_value("{:lint {:rules {}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("parses an empty lint rules table from Fennel", _85_)
  local function _86_()
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
  require("plenary.busted").it("accepts an empty lint rules table through validate", _86_)
  local function _88_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["if-branch-call"] = "error"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"if-branch-call\" :error}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a known lint rule from parsed Fennel", _88_)
  local function _89_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["no-mutation"] = "warning"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"no-mutation\" :warning}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the no-mutation lint rule from parsed Fennel", _89_)
  local function _90_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["defn-args-newline"] = "error"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"defn-args-newline\" :error}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the defn-args-newline lint rule from parsed Fennel", _90_)
  local function _91_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["control-layout"] = "warning"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"control-layout\" :warning}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the control-layout lint rule from parsed Fennel", _91_)
  local function _92_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary({lint = {["max-code-lines"] = 10}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a positive max-code-lines value", _92_)
  local function _93_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "max-code-lines must be a positive integer"
    local actual_7_auto = validation_error_message("{:lint {:max-code-lines 0}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects zero max-code-lines with a specific validation message", _93_)
  local function _94_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "max-code-lines must be a positive integer"
    local actual_7_auto = validation_error_message("{:lint {:max-code-lines -1}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects negative max-code-lines with a specific validation message", _94_)
  local function _95_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "max-code-lines must be a positive integer"
    local actual_7_auto = validation_error_message("{:lint {:max-code-lines 1.5}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects non-integer max-code-lines with a specific validation message", _95_)
  local function _96_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "max-code-lines must be a positive integer"
    local actual_7_auto = validation_error_message("{:lint {:max-code-lines \"10\"}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects string max-code-lines with a specific validation message", _96_)
  local function _97_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {rules = {["file-size"] = "warning"}}}
    local actual_7_auto = parse_value("{:lint {:rules {\"file-size\" :warning}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts the file-size lint rule from parsed Fennel", _97_)
  local function _98_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lint = {exclusions = {{rule = "if-branch-call", form = "fnl/a.fnl > top#1", reason = "why"}}}}
    local actual_7_auto = parse_value("{:lint {:exclusions [{:rule \"if-branch-call\" :form \"fnl/a.fnl > top#1\" :reason \"why\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an exclusion from parsed Fennel", _98_)
  local function _99_()
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
  require("plenary.busted").it("accepts an empty lint table through validate", _99_)
  local function _101_()
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
  require("plenary.busted").it("accepts a lint rule through validate", _101_)
  local function _103_()
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
  require("plenary.busted").it("accepts an exclusion through validate", _103_)
  local function _105_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint must be a table"
    local actual_7_auto = validation_error_message("{:lint 1}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-table lint value", _105_)
  local function _106_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "unknown lint key: 1", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {1 true :z 1}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a numeric lint key without crashing", _106_)
  local function _107_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "unknown lint rule: true", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:rules {true :error}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a boolean lint rule key without crashing", _107_)
  local function _108_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "unknown lint key: true", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {true 1}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a boolean lint key without crashing", _108_)
  local function _109_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "lint exclusion 1: unknown key 1", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:exclusions [{1 \"x\" :rule \"if-branch-call\" :form \"f\" :reason \"r\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a numeric lint exclusion key without crashing", _109_)
  local function _110_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "lint exclusion 1: unknown key true", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:exclusions [{true \"x\" :rule \"if-branch-call\" :form \"f\" :reason \"r\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a boolean lint exclusion key without crashing", _110_)
  local function _111_()
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
  require("plenary.busted").it("rejects a table lint exclusion key without crashing", _111_)
  local function _112_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "lint rule if-branch-call must be error, warning, or off", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:rules {\"if-branch-call\" {}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a lint rule with a table severity without crashing", _112_)
  local function _113_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "lint exclusion 1: unknown key 1", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:exclusions [[1 2]]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a list-valued lint exclusion without crashing", _113_)
  local function _114_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {message = "lint exclusion 1: rule must be a string", ["crashed?"] = false}
    local actual_7_auto = validation_call_summary("{:lint {:exclusions [{:rule {} :form \"f\" :reason \"r\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a lint exclusion with a table rule without crashing", _114_)
  local function _115_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown lint key: extra"
    local actual_7_auto = validation_error_message("{:lint {:extra true}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint key", _115_)
  local function _116_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown lint key: extra"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [] :extra true}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint key after lint exclusions", _116_)
  local function _117_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown lint key: extra"
    local actual_7_auto = validation_error_message("{:lint {:rules {} :extra true}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint key after lint rules", _117_)
  local function _118_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["unknown-key?"] = true}
    local actual_7_auto = unknown_lint_key_summary({lint = {rules = {}, exclusions = {}, a = 1, b = 2, c = 3}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint key among multiple lint keys", _118_)
  local function _119_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint rules must be a table"
    local actual_7_auto = validation_error_message("{:lint {:rules []}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-table lint rules value", _119_)
  local function _120_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "unknown lint rule: nope"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"nope\" :error}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint rule", _120_)
  local function _121_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint rule if-branch-call must be error, warning, or off"
    local actual_7_auto = validation_error_message("{:lint {:rules {\"if-branch-call\" :debug}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an invalid lint rule severity", _121_)
  local function _122_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusions must be a list"
    local actual_7_auto = validation_error_message("{:lint {:exclusions {}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-list lint exclusions value", _122_)
  local function _123_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusions must be a list"
    local actual_7_auto = validation_error_message("{:lint {:exclusions {1 {:rule \"if-branch-call\" :form \"x\" :reason \"ok\"}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a numeric-keyed lint exclusions map", _123_)
  local function _124_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusions must be a list"
    local actual_7_auto = validation_error_message("{:lint {:exclusions {1 {:rule \"if-branch-call\" :form \"x\" :reason \"ok\"} 2 {:rule \"if-branch-call\" :form \"y\" :reason \"ok\"}}}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a lint exclusions map with two numeric keys", _124_)
  local function _125_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary(parse_value("{:lint {:exclusions [{:rule \"if-branch-call\" :form \"x\" :reason \"ok\"}]}}"))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a non-empty lint exclusions list from parsed Fennel", _125_)
  local function _126_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, ["has-message"] = false}
    local actual_7_auto = validate_summary(parse_value("{:lint {:exclusions []}}"))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an empty lint exclusions list from parsed Fennel", _126_)
  local function _127_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 1 must be a table"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [1]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-table lint exclusion", _127_)
  local function _128_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 1: unknown key fingerprint"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [{:rule \"if-branch-call\" :form \"x\" :reason \"why\" :fingerprint \"old\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint exclusion key", _128_)
  local function _129_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 1: rule must be a string"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [{:rule 1 :form \"x\" :reason \"why\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-string lint exclusion field", _129_)
  local function _130_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 1: reason must not be blank"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [{:rule \"if-branch-call\" :form \"x\" :reason \"\\t\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a blank lint exclusion reason", _130_)
  local function _131_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 1: unknown rule nope"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [{:rule \"nope\" :form \"x\" :reason \"why\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an unknown lint exclusion rule", _131_)
  local function _132_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "lint exclusion 2: duplicate of exclusion 1"
    local actual_7_auto = validation_error_message("{:lint {:exclusions [{:rule \"if-branch-call\" :form \"x\" :reason \"one\"} {:rule \"if-branch-call\" :form \"x\" :reason \"two\"}]}}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects duplicate lint exclusions", _132_)
end
require("plenary.busted").describe("lint-configuration", _83_)
local function _133_()
  local function _134_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value-nil?"] = true, message = "unknown lint rule: true"}
    local actual_7_auto = lint_policy_summary({lint = {rules = {[true] = "error"}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("returns a validation error for a malformed lint rule key", _134_)
  local function _135_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value-nil?"] = true, message = "lint exclusion 1: reason must not be blank"}
    local actual_7_auto = lint_policy_summary({lint = {exclusions = {{rule = "if-branch-call", form = "x", reason = ""}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("returns a validation error for a blank lint exclusion reason", _135_)
  local function _136_()
    local config = load_config()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {rules = {["module-style"] = "error", ["spec-macro-import"] = "error", ["spec-no-module"] = "error", ["spec-direct-require"] = "error", ["one-is-per-testing"] = "error", ["if-branch-call"] = "warning", ["if-without-else"] = "warning", ["control-layout"] = "warning", ["defn-args-newline"] = "warning", ["multiline-layout"] = "warning", ["function-shape"] = "warning", ["no-mutation"] = "warning", ["file-size"] = "warning", ["core-require"] = "off"}, ["max-code-lines"] = 300, exclusions = {{rule = "if-branch-call", form = "x", reason = "why"}}}
    local actual_7_auto
    if config["module-missing"] then
      actual_7_auto = config
    else
      local ok, value
      local function _137_()
        return config["lint-policy"]({lint = {["max-code-lines"] = 300, rules = {["core-require"] = "off"}, exclusions = {{rule = "if-branch-call", form = "x", reason = "why"}}}})
      end
      ok, value = pcall(_137_)
      if ok then
        actual_7_auto = value
      else
        actual_7_auto = {["missing-lint-policy"] = true}
      end
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("normalizes lint defaults and overrides without formatter keys", _136_)
end
require("plenary.busted").describe("lint-policy", _133_)
local function _140_()
  local config = load_config()
  local assert_5_auto = require("luassert")
  local expected_6_auto = 10
  local actual_7_auto
  if config["module-missing"] then
    actual_7_auto = nil
  else
    local ok, value
    local function _141_()
      return config["lint-policy"]({lint = {["max-code-lines"] = 10}})
    end
    ok, value = pcall(_141_)
    actual_7_auto = (ok and value["max-code-lines"])
  end
  assert_5_auto.same(expected_6_auto, actual_7_auto)
  return true
end
require("plenary.busted").it("normalizes a configured max-code-lines value", _140_)
local function _143_()
  local function _144_()
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
  return require("plenary.busted").it("lint configuration does not change formatter output", _144_)
end
return require("plenary.busted").describe("formatter-isolation", _143_)
