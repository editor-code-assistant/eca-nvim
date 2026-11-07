-- [nfnl] fnl/spec/fennel-extras/def_alias_spec.fnl
local config = require("fennel-extras.config")
local format = require("fennel-extras.format")
local rules = require("fennel-extras.rules")
local aliases = {def = "fn", ["def-"] = "fn", defn = "fn", ["defn-"] = "fn"}
local fn_config = {["indent-width"] = 2, parser = "eca.nfnl.fennel", indents = {fn = {{"inner", 0}}}, ["format-as"] = aliases}
local default_config = {["indent-width"] = 2, parser = "eca.nfnl.fennel"}
local function repository_format()
  return assert(config.load(".fnl-extras.fnl")).format
end
local function format_with(source, settings)
  local format_string = format["format-string"]
  local value, error = format_string(source, {config = settings})
  assert(value, error)
  return value
end
local function _1_()
  local function _2_()
    local format_config = repository_format()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {indents = {fn = {{"inner", 0}}}, ["format-as"] = nil}
    local actual_7_auto = {indents = format_config.indents, ["format-as"] = format_config["format-as"]}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("keeps only fn as the explicit declaration indentation base", _2_)
end
require("plenary.busted").describe("canonical-configuration", _1_)
local function _3_()
  local function _4_()
    local format_config = repository_format()
    local format_as = format_config["format-as"]
    local assert_5_auto = require("luassert")
    local expected_6_auto = nil
    local actual_7_auto = (format_as and (format_as.def or format_as["def-"] or format_as.defn or format_as["defn-"]))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("the canonical config does not require definition aliases in format-as", _4_)
end
require("plenary.busted").describe("canonical-defaults", _3_)
local function _5_()
  local function _6_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(def value\n  1)"
    local actual_7_auto = format_with("(def value\n1)", fn_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("def indents its value", _6_)
  local function _7_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(def- value\n  1)"
    local actual_7_auto = format_with("(def- value\n1)", fn_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("def- indents its value", _7_)
  local function _8_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn value\n  [x]\n  body)"
    local actual_7_auto = format_with("(defn value\n[x]\nbody)", fn_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("defn indents arguments and body", _8_)
  local function _9_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn- value\n  [x]\n  body)"
    local actual_7_auto = format_with("(defn- value\n[x]\nbody)", fn_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("defn- indents arguments and body", _9_)
end
require("plenary.busted").describe("root-declarations", _5_)
local function _10_()
  local function _11_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(def value\n  1)"
    local actual_7_auto = format_with("(def value\n1)", default_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("def uses formatter defaults for its continuation indentation", _11_)
  local function _12_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(def- value\n  1)"
    local actual_7_auto = format_with("(def- value\n1)", default_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("def- uses formatter defaults for its continuation indentation", _12_)
  local function _13_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn value\n  [x]\n  body)"
    local actual_7_auto = format_with("(defn value\n[x]\nbody)", default_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("defn uses formatter defaults for its arguments and body", _13_)
  local function _14_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn- value\n  [x]\n  body)"
    local actual_7_auto = format_with("(defn- value\n[x]\nbody)", default_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("defn- uses formatter defaults for its arguments and body", _14_)
end
require("plenary.busted").describe("root-declarations-with-defaults", _10_)
local function _15_()
  local function _16_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(def outer\n  (defn inner\n    [x]\n    body)\n  (def value\n    1))"
    local actual_7_auto = format_with("(def outer\n(defn inner\n[x]\nbody)\n(def value\n1))", fn_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("nested declarations use parent indentation while preserving declaration shape", _16_)
end
require("plenary.busted").describe("nested-declarations", _15_)
local function _17_()
  local function _18_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(def outer\n  (defn inner\n    [x]\n    body)\n  (def value\n    1))"
    local actual_7_auto = format_with("(def outer\n(defn inner\n[x]\nbody)\n(def value\n1))", default_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("nested declarations preserve shape and generic parent indentation with formatter defaults", _18_)
end
require("plenary.busted").describe("nested-declarations-with-defaults", _17_)
local function _19_()
  local function _20_()
    local source = "(def value 1)\n(def- value 2)\n(defn value [x] body)\n(defn- value [x] body)"
    local assert_5_auto = require("luassert")
    local expected_6_auto = source
    local actual_7_auto = format_with(source, default_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("one-line declarations remain unchanged without automatic splitting", _20_)
end
require("plenary.busted").describe("one-line-declarations", _19_)
local function _21_()
  local function _22_()
    local first = {indents = {fn = {{"inner", 0}}}, ["format-as"] = aliases}
    local second = {indents = {other = {{"block", 1}}}, ["format-as"] = {def = "other", ["def-"] = "other", defn = "other", ["defn-"] = "other"}}
    local assert_5_auto = require("luassert")
    local expected_6_auto = {def = {{"block", 1}}, ["def-"] = {{"block", 1}}, defn = {{"block", 1}}, ["defn-"] = {{"block", 1}}}
    local actual_7_auto = {def = rules.resolve(second, "def"), ["def-"] = rules.resolve(second, "def-"), defn = rules.resolve(second, "defn"), ["defn-"] = rules.resolve(second, "defn-")}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("changing the fn target changes every aliased definition", _22_)
end
return require("plenary.busted").describe("target-propagation", _21_)
