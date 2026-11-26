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
    local val_28_ = {finding.rule, finding.form}
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
    local expected_6_auto = 5
    local actual_7_auto = #vim.tbl_keys(rules.defaults())
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("all retained lint rules are off by default", _4_)
end
require("plenary.busted").describe("defaults", _3_)
local function _5_()
  local function _6_()
    local policy = {["form-chain"] = {{severity = "warning", description = "explain this rule", ["applies-to"] = {forms = {"var"}}, options = {["allowed-chains"] = {}}, exclusions = {}}}}
    local result = findings_for("(var x 1)", "fnl/app.fnl", policy)
    local finding = result[1]
    local assert_5_auto = require("luassert")
    local expected_6_auto = {description = "explain this rule", rule = "form-chain", form = "fnl/app.fnl > top#1", instance = 1}
    local actual_7_auto = {description = finding.description, rule = finding.rule, form = finding.form, instance = finding.instance}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("propagates description without changing rule form or instance identity", _6_)
end
require("plenary.busted").describe("rule-instance-description", _5_)
local function _7_()
  local function _8_()
    local policy = {["module-import"] = {{severity = "error", ["applies-to"] = {modules = "eca.nfnl.core"}, options = {mode = "require", binding = "core"}, exclusions = {}}}}
    local result = identities(findings_for("(local c (require :eca.nfnl.core))", "fnl/app.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-import", "fnl/app.fnl > local:c"}}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("requires the canonical core binding", _8_)
  local function _9_()
    local policy = {["module-import"] = {{severity = "error", ["applies-to"] = {modules = {"plenary.busted"}}, options = {mode = "forbid"}, exclusions = {{path = "^fnl/spec/"}}}}}
    local result = identities(findings_for("(require :plenary.busted)", "fnl/spec/app_spec.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-import", "fnl/spec/app_spec.fnl > top#1"}}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("forbids direct test-library requires", _9_)
end
require("plenary.busted").describe("module-import", _7_)
local function _10_()
  local function _11_()
    local policy = {["required-form"] = {{severity = "error", ["applies-to"] = {forms = {"module"}}, options = {}, exclusions = {}}}}
    local result = identities(findings_for("(local value 1)", "fnl/app.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"required-form", "fnl/app.fnl > file"}}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("reports a missing top-level form", _11_)
  local function _12_()
    local policy = {["required-form"] = {{severity = "error", ["applies-to"] = {forms = {"module"}}, options = {}, exclusions = {}}}}
    local result = identities(findings_for("(module app)", "fnl/app.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("accepts a compliant top-level form", _12_)
end
require("plenary.busted").describe("required-form", _10_)
local function _13_()
  local function _14_()
    local policy = {["child-count"] = {{severity = "error", ["applies-to"] = {forms = {"testing"}}, options = {children = {"is"}, ["max-count"] = 1}, exclusions = {}}}}
    local result = identities(findings_for("(deftest run (testing \"x\" (is a) (is b)))", "fnl/spec/app_spec.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1"}}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("canonical child-count preserves named testing child checks", _14_)
end
require("plenary.busted").describe("migrated-child-count", _13_)
local function _15_()
  local policy = {["child-count"] = {{severity = "info", ["applies-to"] = {files = {"^fennel-extras/"}, forms = {"or"}}, options = {children = {"="}, ["max-count"] = 1, direct = true}, exclusions = {}}}}
  local findings
  local function _16_(source)
    return findings_for(source, "fennel-extras/app.fnl", policy)
  end
  findings = _16_
  local function _17_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fennel-extras/app.fnl > top#1"}}
    local actual_7_auto = identities(findings("(or (= a 1) (= b 2))"))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("canonical child-count reports or forms with two direct equality children", _17_)
  local function _18_()
    local result = findings("(or (= a 1) (= b 2))")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "or has an invalid child count"
    local actual_7_auto = result[1].message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("canonical child-count uses the form name in its message", _18_)
  local function _19_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = identities(findings("(or (= a 1) predicate)"))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("canonical child-count allows one direct equality child", _19_)
  local function _20_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = identities(findings("(or (and (= a 1)) (= b 2))"))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("canonical direct child-count ignores nested equality inside another child form", _20_)
end
require("plenary.busted").describe("canonical-or-child-count", _15_)
local function _21_()
  local function _22_()
    local policy = {["child-count"] = {{severity = "warning", ["applies-to"] = {forms = {"target"}}, options = {children = {"="}, ["max-count"] = 1}, exclusions = {}}}}
    local result = identities(findings_for("(target (wrapper (= a 1)) (= b 2))", "fnl/app.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > top#1"}}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("counts named children recursively when direct is omitted", _22_)
  local function _23_()
    local policy = {["child-count"] = {{severity = "warning", ["applies-to"] = {forms = {"target"}}, options = {children = {"="}, ["max-count"] = 1, direct = true}, exclusions = {}}}}
    local result = identities(findings_for("(target (wrapper (= a 1)) (= b 2))", "fnl/app.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("counts only immediate named children when direct is true", _23_)
  local function _24_()
    local policy = {["child-count"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {["min-count"] = 2, ["max-count"] = 2, ["nil-count"] = false}, exclusions = {}}}}
    local result = identities(findings_for("(if ok value)", "fnl/app.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > top#1"}}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses direct arity bounds when children and direct are omitted", _24_)
  local function _25_()
    local policy = {["child-count"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {["min-count"] = 2, ["max-count"] = 2, direct = true, ["nil-count"] = false}, exclusions = {}}}}
    local result = identities(findings_for("(if ok value)", "fnl/app.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > top#1"}}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("uses the same direct arity bounds when direct is true", _25_)
end
require("plenary.busted").describe("child-count-mode-combinations", _21_)
local function _26_()
  local policy = {["child-count"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {["min-count"] = 2, ["max-count"] = 2, ["nil-count"] = false}, exclusions = {}}}}
  local finding
  local function _27_(source)
    return identities(findings_for(source, "fnl/app.fnl", policy))
  end
  finding = _27_
  local function _28_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > defn:run > if#1"}}
    local actual_7_auto = finding("(defn run [] (if ok value))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an if with no else", _28_)
  local function _29_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > defn:run > if#1"}}
    local actual_7_auto = finding("(defn run [] (if ok value nil))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an if with a literal nil else", _29_)
  local function _30_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > defn:run > if#1"}}
    local actual_7_auto = finding("(defn run [] (if ok a b c d))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an if with multiple clauses", _30_)
  local function _31_()
    local broad_policy = {["child-count"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {["min-count"] = 0, ["max-count"] = 10, ["nil-count"] = true}, exclusions = {}}}}
    local broad_finding
    local function _32_(source)
      return identities(findings_for(source, "fnl/app.fnl", broad_policy))
    end
    broad_finding = _32_
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > defn:run > if#1"}}
    local actual_7_auto = broad_finding("(defn run [] (if ok a b c d))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a multi-clause if with broad direct bounds", _31_)
  local function _33_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = finding("(defn run [] (if ok value fallback))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("allows a normal two-branch if", _33_)
end
require("plenary.busted").describe("direct-child-arity", _26_)
local function _34_()
  local policy = {["child-count"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {["min-count"] = 2, ["max-count"] = 2, ["not-counted"] = {"nil", "true", "false"}}, exclusions = {}}}}
  local finding
  local function _35_(source)
    return identities(findings_for(source, "fnl/app.fnl", policy))
  end
  finding = _35_
  local function _36_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > defn:run > if#1"}}
    local actual_7_auto = finding("(defn run [] (if ok true fallback))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("excludes literal true from the direct count", _36_)
  local function _37_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > defn:run > if#1"}}
    local actual_7_auto = finding("(defn run [] (if ok false fallback))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("excludes literal false from the direct count", _37_)
  local function _38_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > defn:run > if#1"}}
    local actual_7_auto = finding("(defn run [] (if ok value nil))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("excludes literal nil from the direct count", _38_)
  local function _39_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = finding("(defn run [] (if ok value fallback))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("preserves two counted branches", _39_)
  local function _40_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > defn:run > if#1"}}
    local actual_7_auto = finding("(defn run [] (if ok value fallback extra))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("enforces the maximum of two counted branches", _40_)
end
require("plenary.busted").describe("direct-child-arity-not-counted", _34_)
local function _41_()
  local policy = {binding = {{severity = "warning", ["applies-to"] = {forms = {"let"}}, options = {}, exclusions = {}}}}
  local finding
  local function _42_(source)
    local result = findings_for(source, "fnl/app.fnl", policy)
    local tbl_26_ = {}
    local i_27_ = 0
    for _, item in ipairs(result) do
      local val_28_ = {rule = item.rule, form = item.form, message = item.message}
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    return tbl_26_
  end
  finding = _42_
  local function _44_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{rule = "binding", form = "fnl/app.fnl > let#1", message = "avoid introducing a local binding for a single body expression"}}
    local actual_7_auto = finding("(let [value 1] value)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("reports a let with one binding pair and one body expression", _44_)
  local function _45_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = finding("(let [first 1 second 2] first)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("allows a let with multiple bindings", _45_)
  local function _46_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = finding("(let [value 1] value (+ value 1))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("allows a let with multiple body expressions", _46_)
  local function _47_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = finding("(quote (let [value 1] value))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("ignores a let inside an explicit quote form", _47_)
end
require("plenary.busted").describe("generic-binding", _41_)
local function _48_()
  local function _49_()
    local policy = {["child-count"] = {{severity = "warning", ["applies-to"] = {forms = {"target"}}, options = {["min-count"] = 2}, exclusions = {}}}}
    local result = identities(findings_for("(target one two three)", "fnl/app.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a direct minimum-only bound", _49_)
  local function _50_()
    local policy = {["child-count"] = {{severity = "warning", ["applies-to"] = {forms = {"target"}}, options = {["max-count"] = 2}, exclusions = {}}}}
    local result = identities(findings_for("(target one two three)", "fnl/app.fnl", policy))
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > top#1"}}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a direct maximum-only bound", _50_)
  local function _51_()
    local policy = {["child-count"] = {{severity = "warning", ["applies-to"] = {forms = {"target"}}, options = {children = {"item"}, ["min-count"] = 2}, exclusions = {}}}}
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = identities(findings_for("(target (item) (item))", "fnl/app.fnl", policy))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts named minimum-only bound", _51_)
  local function _52_()
    local policy = {["child-count"] = {{severity = "warning", ["applies-to"] = {forms = {"target"}}, options = {children = {"item"}, ["max-count"] = 1}, exclusions = {}}}}
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"child-count", "fnl/app.fnl > top#1"}}
    local actual_7_auto = identities(findings_for("(target (item) (item))", "fnl/app.fnl", policy))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("accepts named maximum-only bound", _52_)
end
require("plenary.busted").describe("child-count-bound-combinations", _48_)
local function _53_()
  local assert_5_auto = require("luassert")
  local expected_6_auto = {"fnl/app.fnl > top#1", "fnl/app.fnl > top#1 > cond#1"}
  local actual_7_auto
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, item in ipairs(identity.forms("(target (cond ok value))", "fnl/app.fnl")) do
      local val_28_ = item.form
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    actual_7_auto = tbl_26_
  end
  assert_5_auto.same(expected_6_auto, actual_7_auto)
  return true
end
return require("plenary.busted").describe("nested-cond-identities", _53_)
