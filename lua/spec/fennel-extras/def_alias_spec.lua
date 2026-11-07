-- [nfnl] fnl/spec/fennel-extras/def_alias_spec.fnl
local config = require("fennel-extras.config")
local format = require("fennel-extras.format")
local rules = require("fennel-extras.rules")
local aliases = {def = "fn", ["def-"] = "fn", defn = "fn", ["defn-"] = "fn"}
local fn_config = {["indent-width"] = 2, parser = "eca.nfnl.fennel", indents = {fn = {{"inner", 0}}}, ["format-as"] = aliases}
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
    local expected_6_auto = {indents = {fn = {{"inner", 0}}}, ["format-as"] = aliases}
    local actual_7_auto = {indents = format_config.indents, ["format-as"] = vim.tbl_extend("force", {}, aliases)}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("keeps only fn as the declaration indentation base and aliases definitions to it", _2_)
end
require("plenary.busted").describe("canonical-configuration", _1_)
local function _3_()
  local function _4_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(def value\n  1)"
    local actual_7_auto = format_with("(def value\n1)", fn_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("def indents its value", _4_)
  local function _5_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(def- value\n  1)"
    local actual_7_auto = format_with("(def- value\n1)", fn_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("def- indents its value", _5_)
  local function _6_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn value\n  [x]\n  body)"
    local actual_7_auto = format_with("(defn value\n[x]\nbody)", fn_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("defn indents arguments and body", _6_)
  local function _7_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn- value\n  [x]\n  body)"
    local actual_7_auto = format_with("(defn- value\n[x]\nbody)", fn_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("defn- indents arguments and body", _7_)
end
require("plenary.busted").describe("root-declarations", _3_)
local function _8_()
  local function _9_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(def outer\n  (defn inner\n    [x]\n    body)\n  (def value\n    1))"
    local actual_7_auto = format_with("(def outer\n(defn inner\n[x]\nbody)\n(def value\n1))", fn_config)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("nested declarations use parent indentation while preserving declaration shape", _9_)
end
require("plenary.busted").describe("nested-declarations", _8_)
local function _10_()
  local function _11_()
    local first = {indents = {fn = {{"inner", 0}}}, ["format-as"] = aliases}
    local second = {indents = {other = {{"block", 1}}}, ["format-as"] = {def = "other", ["def-"] = "other", defn = "other", ["defn-"] = "other"}}
    local assert_5_auto = require("luassert")
    local expected_6_auto = {def = {{"block", 1}}, ["def-"] = {{"block", 1}}, defn = {{"block", 1}}, ["defn-"] = {{"block", 1}}}
    local actual_7_auto = {def = rules.resolve(second, "def"), ["def-"] = rules.resolve(second, "def-"), defn = rules.resolve(second, "defn"), ["defn-"] = rules.resolve(second, "defn-")}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("changing the fn target changes every aliased definition", _11_)
end
return require("plenary.busted").describe("target-propagation", _10_)
