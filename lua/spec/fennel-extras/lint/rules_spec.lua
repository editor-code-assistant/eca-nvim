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
    local expected_6_auto = 6
    local actual_7_auto = #vim.tbl_keys(rules.defaults())
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("all retained lint rules are off by default", _4_)
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
    local policy = {["forbidden-form"] = {{severity = "warning", description = "explain this rule", ["applies-to"] = {forms = {"var"}}, options = {}, exclusions = {}}}}
    local result = findings_for("(var x 1)", "fnl/app.fnl", policy)
    local finding = result[1]
    local assert_5_auto = require("luassert")
    local expected_6_auto = {description = "explain this rule", rule = "forbidden-form", form = "fnl/app.fnl > top#1", instance = 1}
    local actual_7_auto = {description = finding.description, rule = finding.rule, form = finding.form, instance = finding.instance}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("propagates description without changing rule form or instance identity", _9_)
end
require("plenary.busted").describe("rule-instance-description", _8_)
local function _10_()
  local function _11_()
    local policy = {["module-import"] = {{severity = "error", ["applies-to"] = {modules = "eca.nfnl.core"}, options = {mode = "require", binding = "core"}, exclusions = {}}}}
    local result = identities(findings_for("(local c (require :eca.nfnl.core))", "fnl/app.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-import", "fnl/app.fnl > local:c", "error"}}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("requires the canonical core binding", _11_)
  local function _12_()
    local policy = {["module-import"] = {{severity = "error", ["applies-to"] = {modules = {"plenary.busted"}}, options = {mode = "forbid"}, exclusions = {{path = "^fnl/spec/"}}}}}
    local result = identities(findings_for("(require :plenary.busted)", "fnl/spec/app_spec.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-import", "fnl/spec/app_spec.fnl > top#1", "error"}}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("forbids direct test-library requires", _12_)
end
require("plenary.busted").describe("module-import", _10_)
local function _13_()
  local function _14_()
    local policy = {["required-form"] = {{severity = "error", ["applies-to"] = {forms = {"module"}}, options = {}, exclusions = {}}}}
    local result = identities(findings_for("(local value 1)", "fnl/app.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"required-form", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("reports a missing top-level form", _14_)
  local function _15_()
    local policy = {["required-form"] = {{severity = "error", ["applies-to"] = {forms = {"module"}}, options = {}, exclusions = {}}}}
    local result = identities(findings_for("(module app)", "fnl/app.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("accepts a compliant top-level form", _15_)
end
require("plenary.busted").describe("required-form", _13_)
local function _16_()
  local function _17_()
    local policy = {["child-count"] = {{severity = "error", ["applies-to"] = {forms = {"testing"}}, options = {children = {"is"}, ["max-count"] = 1}, exclusions = {}}}}
    local result = identities(findings_for("(deftest run (testing \"x\" (is a) (is b)))", "fnl/spec/app_spec.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("canonical child-count preserves named testing child checks", _17_)
end
require("plenary.busted").describe("migrated-child-count", _16_)
local function _18_()
  local policy = {["child-count"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {["min-count"] = 2, ["max-count"] = 2, ["nil-count"] = false}, exclusions = {}}}}
  local finding
  local function _19_(source)
    return identities(findings_for(source, "fnl/app.fnl", policy))
  end
  finding = _19_
  local function _20_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > defn:run > if#1", "warning"}}
    local actual_7_auto = finding("(defn run [] (if ok value))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an if with no else", _20_)
  local function _21_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > defn:run > if#1", "warning"}}
    local actual_7_auto = finding("(defn run [] (if ok value nil))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an if with a literal nil else", _21_)
  local function _22_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > defn:run > if#1", "warning"}}
    local actual_7_auto = finding("(defn run [] (if ok a b c d))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an if with multiple clauses", _22_)
  local function _23_()
    local broad_policy = {["child-count"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {["min-count"] = 0, ["max-count"] = 10, ["nil-count"] = true}, exclusions = {}}}}
    local broad_finding
    local function _24_(source)
      return identities(findings_for(source, "fnl/app.fnl", broad_policy))
    end
    broad_finding = _24_
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > defn:run > if#1", "warning"}}
    local actual_7_auto = broad_finding("(defn run [] (if ok a b c d))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a multi-clause if with broad direct bounds", _23_)
  local function _25_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = finding("(defn run [] (if ok value fallback))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("allows a normal two-branch if", _25_)
end
require("plenary.busted").describe("direct-child-arity", _18_)
local function _26_()
  local policy = {["child-count"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {["min-count"] = 2, ["max-count"] = 2, ["not-counted"] = {"nil", "true", "false"}}, exclusions = {}}}}
  local finding
  local function _27_(source)
    return identities(findings_for(source, "fnl/app.fnl", policy))
  end
  finding = _27_
  local function _28_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > defn:run > if#1", "warning"}}
    local actual_7_auto = finding("(defn run [] (if ok true fallback))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("excludes literal true from the direct count", _28_)
  local function _29_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > defn:run > if#1", "warning"}}
    local actual_7_auto = finding("(defn run [] (if ok false fallback))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("excludes literal false from the direct count", _29_)
  local function _30_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > defn:run > if#1", "warning"}}
    local actual_7_auto = finding("(defn run [] (if ok value nil))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("excludes literal nil from the direct count", _30_)
  local function _31_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = finding("(defn run [] (if ok value fallback))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("preserves two counted branches", _31_)
  local function _32_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > defn:run > if#1", "warning"}}
    local actual_7_auto = finding("(defn run [] (if ok value fallback extra))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("enforces the maximum of two counted branches", _32_)
end
return require("plenary.busted").describe("direct-child-arity-not-counted", _26_)
