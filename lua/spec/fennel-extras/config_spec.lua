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
  local function _10_()
    return vim.fn.delete(root, "rf")
  end
  local function _11_()
    write_file(root_config, "{:exclude [\"root\"]}")
    write_file(config_path, "{:paths [\"fnl\"]}")
    write_file((root .. "/valid.fnl-extras.fnl"), "{:exclude [\"generated\"]}")
    local _12_
    do
      local config = load_config()
      if config["module-missing"] then
        _12_ = config
      else
        _12_ = config.find(root)
      end
    end
    local _14_
    do
      local config = load_config()
      if config["module-missing"] then
        _14_ = config
      else
        _14_ = config.find(nested)
      end
    end
    local _16_
    do
      local config = load_config()
      if config["module-missing"] then
        _16_ = config
      else
        _16_ = config.find(stop_nested)
      end
    end
    local _18_
    do
      local config = load_config()
      if config["module-missing"] then
        _18_ = config
      else
        _18_ = config.load(config_path)
      end
    end
    local _20_
    do
      local config = load_config()
      if config["module-missing"] then
        _20_ = config
      else
        local ok, value, err
        local function _22_()
          return config.load((root .. "/missing.fnl-extras.fnl"))
        end
        ok, value, err = pcall(_22_)
        _20_ = {["value?"] = (ok and (nil ~= value)), ["has-message"] = (ok and (nil == value) and err and ("table" == type(err)) and ("string" == type(err.message)))}
      end
    end
    return {start = _12_, parent = _14_, stopped = _16_, ["root-config"] = root_config, ["config-path"] = config_path, loaded = _18_, missing = _20_}
  end
  return with_cleanup(_10_, _11_)
end
local function _24_()
  local function _25_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {indents = {deftest = {{"block", 1}}, testing = {{"block", 1}}}, ["format-as"] = {["my-let"] = "let"}, paths = {"fnl"}, exclude = {"fnl/eca/nfnl"}}
    local actual_7_auto = parse_value("{:indents {\"deftest\" [[:block 1]] \"testing\" [[:block 1]]} :format-as {\"my-let\" \"let\"} :paths [\"fnl\"] :exclude [\"fnl/eca/nfnl\"]}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("parses a realistic data-only configuration and converts keywords to strings", _25_)
  local function _26_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {text = "quote \" slash \\ line\n tab\t", one = 1, decimal = 2.5, negative = -3, yes = true, nothing = nil, no = false}
    local actual_7_auto = parse_value("{:text \"quote \\\" slash \\\\ line\\n tab\\t\" ; comment\n :one 1 :decimal 2.5 :negative -3 :yes true :no false :nothing nil}")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("parses escapes, numbers, booleans, nil, and ignores comments", _26_)
end
require("plenary.busted").describe("parse-string", _24_)
local function _27_()
  local function _28_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, line = 1, col = 5, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a (require :x)}", true)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a list and reports line 1 column 5", _28_)
  local function _29_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a foo}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a bare symbol", _29_)
  local function _30_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a #(x)}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects hash reader prefixes", _30_)
  local function _31_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{} {}", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects more than one top-level form", _31_)
  local function _32_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an empty file", _32_)
  local function _33_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("[1]", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a non-table top-level form", _33_)
  local function _34_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = parse_error_summary("{:a 1", false)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects unbalanced input", _34_)
  local function _35_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = validate_summary({colour = 1})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("validate rejects an unknown top-level key", _35_)
  local function _36_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = validate_summary({paths = "fnl"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("validate rejects paths that are not a sequence", _36_)
end
require("plenary.busted").describe("rejection", _27_)
local function _37_()
  local function _38_()
    local result = find_load_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["root-config"]
    local actual_7_auto = result.start
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("find returns a config in the start directory", _38_)
  local function _39_()
    local result = find_load_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["config-path"]
    local actual_7_auto = result.parent
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("find returns the nearest config in a parent directory", _39_)
  local function _40_()
    local assert_25_auto = require("luassert")
    local value_26_auto = find_load_scenario().stopped
    assert_25_auto.is_nil(value_26_auto)
    return true
  end
  require("plenary.busted").it("find stops at a .git directory", _40_)
  local function _41_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {paths = {"fnl"}}
    local actual_7_auto = find_load_scenario().loaded
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("load returns the validated table from a file", _41_)
  local function _42_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = find_load_scenario().missing
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("load returns a structured error for a missing path", _42_)
end
return require("plenary.busted").describe("find-load", _37_)
