-- [nfnl] fnl/spec/fennel-extras/lint/rules_spec.fnl
local identity = require("fennel-extras.lint.identity")
local rules = require("fennel-extras.lint.rules")
local function findings_for(source, path, policy)
  local forms, error = identity.forms(source, path)
  if error then
    return {}
  else
    return rules.check(path, forms, policy, source)
  end
end
local function identities(findings)
  local tbl_26_ = {}
  local i_27_ = 0
  for _, finding in ipairs(findings) do
    local val_28_ = {finding.rule, finding.form, finding.severity}
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function _3_()
  local function _4_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 13
    local actual_7_auto = #vim.tbl_keys(rules.defaults())
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("all thirteen lint rules are off by default", _4_)
end
require("plenary.busted").describe("defaults", _3_)
local function _5_()
  local function _6_()
    local policy = {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {modules = "plenary.busted"}, options = {}, exclusions = {}}}}
    local result = identities(findings_for("(require :plenary.busted)\n(local value 1)", "fnl/spec/one.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"forbidden-form", "fnl/spec/one.fnl > top#1", "warning"}}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("forbids a selected module target", _6_)
  local function _7_()
    local policy = {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {forms = {"var", "set", "while"}}, options = {}, exclusions = {}}}}
    local result = identities(findings_for("(var x 1)", "fnl/app.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"forbidden-form", "fnl/app.fnl > top#1", "warning"}}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("forbids selected executable forms", _7_)
end
require("plenary.busted").describe("forbidden-form", _5_)
local function _8_()
  local function _9_()
    local policy = {["module-import"] = {{severity = "error", ["applies-to"] = {modules = "eca.nfnl.core"}, options = {mode = "require", binding = "core"}, exclusions = {}}}}
    local result = identities(findings_for("(local c (require :eca.nfnl.core))", "fnl/app.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-import", "fnl/app.fnl > local:c", "error"}}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("requires the canonical core binding", _9_)
  local function _10_()
    local policy = {["module-import"] = {{severity = "error", ["applies-to"] = {modules = {"plenary.busted"}}, options = {mode = "forbid", ["exempt-files"] = {}}, exclusions = {}}}}
    local result = identities(findings_for("(require :plenary.busted)", "fnl/spec/app_spec.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-import", "fnl/spec/app_spec.fnl > top#1", "error"}}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("forbids direct test-library requires", _10_)
end
require("plenary.busted").describe("module-import", _8_)
local function _11_()
  local function _12_()
    local policy = {["required-form"] = {{severity = "error", ["applies-to"] = {forms = {"module"}}, options = {}, exclusions = {}}}}
    local result = identities(findings_for("(local value 1)", "fnl/app.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"required-form", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("reports a missing top-level form", _12_)
  local function _13_()
    local policy = {["required-form"] = {{severity = "error", ["applies-to"] = {forms = {"module"}}, options = {}, exclusions = {}}}}
    local result = identities(findings_for("(module app)", "fnl/app.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("accepts a compliant top-level form", _13_)
end
return require("plenary.busted").describe("required-form", _11_)
