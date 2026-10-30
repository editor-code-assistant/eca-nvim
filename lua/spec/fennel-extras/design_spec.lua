-- [nfnl] fnl/spec/fennel-extras/design_spec.fnl
local config = require("fennel-extras.config")
local identity = require("fennel-extras.lint.identity")
local rules = require("fennel-extras.lint.rules")
local function validation(value)
  local ok, result, error = pcall(config.validate, value)
  return {ok = (ok and result), value = result, error = error}
end
local function error_message(result)
  local error = result.error
  if ("table" == type(error)) then
    return error.message
  else
    return error
  end
end
local function findings_for(source, policy)
  local forms, error = identity.forms(source, "fnl/app.fnl")
  if error then
    return {}
  else
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding in ipairs(rules.check("fnl/app.fnl", forms, policy, source)) do
      local val_28_ = {finding.rule, finding.form, finding.severity}
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    return tbl_26_
  end
end
local function _4_()
  local function _5_()
    local result = validation({design = {rules = {["function-shape"] = {{severity = "warning", ["applies-to"] = {files = {"^fnl/"}, forms = {"defn", "defn-", "fn", "lambda", "\206\187"}}, options = {}, exclusions = {}}}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and result.value and result.value.design.rules["function-shape"][1]["applies-to"].forms)
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (. result \"value\") (. (. result \"value\") \"design\" \"rules\" \"function-shape\" 1 \"applies-to\" \"forms\"))")
    return true
  end
  require("plenary.busted").it("top-level design accepts the lint vector-instance rule schema", _5_)
  local function _6_()
    local instance = {severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {}, exclusions = {}}
    local result = validation({design = {rules = {["function-shape"] = {instance}, ["if-branch-call"] = {instance}, ["if-without-else"] = {instance}, ["nested-forms"] = {instance}, ["leading-bindings"] = {instance}, ["no-mutation"] = {instance}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and result.value)
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (. result \"value\"))")
    return true
  end
  return require("plenary.busted").it("design owns the structural rule keys", _6_)
end
require("plenary.busted").describe("design-configuration", _4_)
local function _7_()
  local function _8_()
    for name in ipairs({"function-shape", "if-branch-call", "if-without-else", "nested-forms", "leading-bindings", "no-mutation"}) do
      local instance = {severity = "warning", ["applies-to"] = {}, options = {forms = {"if"}}, exclusions = {}}
      local rules0 = {}
      local _
      rules0[name] = {instance}
      _ = nil
      local result = validation({lint = {rules = rules0}})
      local assert_28_auto = require("luassert")
      local value_29_auto = (not result.ok and (("unknown lint rule: " .. name) == error_message(result)))
      assert_28_auto.is_truthy(value_29_auto, "(and (not (. result \"ok\")) (= (.. \"unknown lint rule: \" name) (error-message result)))")
    end
    return nil
  end
  return require("plenary.busted").it("structural rule keys are absent from lint rules", _8_)
end
require("plenary.busted").describe("lint-design-separation", _7_)
local function _9_()
  local function _10_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"function-shape", "fnl/app.fnl > defn:run > if#1 > then > if#1", "warning"}}
    local actual_7_auto = findings_for("(defn run [] (if x (if y a b) c))", {["function-shape"] = {{severity = "warning", ["applies-to"] = {forms = {"defn", "defn-", "fn", "lambda", "\206\187"}}, options = {}, exclusions = {}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("design findings preserve function-shape identity and severity", _10_)
  local function _11_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "warning"}}
    local actual_7_auto = findings_for("(defn run [] (if ok (do a b) c))", {["if-branch-call"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {}, exclusions = {}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("design findings preserve if-branch-call identity and severity", _11_)
  local function _12_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"if-without-else", "fnl/app.fnl > defn:run > if#1", "warning"}}
    local actual_7_auto = findings_for("(defn run [] (if ok value))", {["if-without-else"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {["nil-else"] = true}, exclusions = {}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("design findings preserve if-without-else identity and severity", _12_)
end
return require("plenary.busted").describe("design-finding-compatibility", _9_)
