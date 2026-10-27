-- [nfnl] fnl/spec/fennel-extras/lint/rules_spec.fnl
local identity = require("fennel-extras.lint.identity")
local function load_rules()
  local ok, result = pcall(require, "fennel-extras.lint.rules")
  if ok then
    return result
  else
    return {["module-missing"] = true}
  end
end
local function sort_severities(entries)
  local function _2_(a, b)
    return (a[1] < b[1])
  end
  table.sort(entries, _2_)
  return entries
end
local function default_severities()
  local rules = load_rules()
  if rules["module-missing"] then
    return rules
  else
    local defaults = rules.defaults()
    local entries
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for rule, severity in pairs(defaults) do
        local val_28_ = {rule, severity}
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      entries = tbl_26_
    end
    return sort_severities(entries)
  end
end
local function _5_()
  local function _6_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"binding-per-line", "off"}, {"call-data-arg", "off"}, {"control-layout", "off"}, {"core-require", "off"}, {"defn-args-newline", "off"}, {"file-size", "off"}, {"forbidden-form", "off"}, {"function-shape", "off"}, {"if-branch-call", "off"}, {"if-without-else", "off"}, {"module-style", "off"}, {"multiline-layout", "off"}, {"no-mutation", "off"}, {"one-is-per-testing", "off"}, {"spec-direct-require", "off"}, {"spec-macro-import", "off"}, {"spec-no-module", "off"}, {"unused-and-or", "off"}}
    local actual_7_auto
    do
      local entries = default_severities()
      if entries["module-missing"] then
        actual_7_auto = entries
      else
        actual_7_auto = sort_severities(entries)
      end
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("all eighteen lint rules are off by default", _6_)
end
require("plenary.busted").describe("defaults", _5_)
local function all_enabled_policy()
  return {["core-require"] = {{severity = "error", ["applies-to"] = {}, options = {module = "eca.nfnl.core", binding = "core"}, exclusions = {}}}}
end
local function core_require_scenario()
  local source = "(local c (require :eca.nfnl.core))"
  local path = "fnl/app.fnl"
  local policy = all_enabled_policy()
  local forms, error = identity.forms(source, path)
  if error then
    return {error = error}
  else
    local before
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, form in ipairs(forms) do
        local val_28_ = form.form
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      before = tbl_26_
    end
    local rules = load_rules()
    local findings = rules.check(path, forms, policy, source)
    local after
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, form in ipairs(forms) do
        local val_28_ = form.form
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      after = tbl_26_
    end
    return {before = before, after = after, findings = findings}
  end
end
local function core_require_identities(scenario)
  local tbl_26_ = {}
  local i_27_ = 0
  for _, finding in ipairs(scenario.findings) do
    local val_28_
    if (finding.rule == "core-require") then
      val_28_ = {finding.rule, finding.form, finding.severity}
    else
      val_28_ = nil
    end
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function forbidden_form_scenario()
  local source = "(require :plenary.busted)\n(local value 1)"
  local path = "fnl/spec/one.fnl"
  local policy = {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {files = {"fnl/spec/one.fnl"}, forms = {"require"}}, options = {module = "plenary.busted"}, exclusions = {}}}}
  local forms, error = identity.forms(source, path)
  if error then
    return {error = error}
  else
    local rules = load_rules()
    return {findings = rules.check(path, forms, policy, source)}
  end
end
local function forbidden_form_identities(scenario)
  local tbl_26_ = {}
  local i_27_ = 0
  for _, finding in ipairs(scenario.findings) do
    local val_28_ = {finding.rule, finding.form, finding.severity}
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function _15_()
  local function _16_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"forbidden-form", "fnl/spec/one.fnl > top#1", "warning"}}
    local actual_7_auto = forbidden_form_identities(forbidden_form_scenario())
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("reports the selected form head with the generic rule identity", _16_)
  local function _17_()
    local source = "(require :plenary.busted)\\n(import :plenary.busted)\\n(module plenary.busted)\\n(require :luassert)"
    local path = "fnl/spec/one.fnl"
    local policy = {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {files = {"fnl/spec/one.fnl"}, forms = {"require", "import", "module"}, modules = {"plenary.busted"}}, options = {}, exclusions = {}}}}
    local forms, error = identity.forms(source, path)
    local rules = load_rules()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"forbidden-form", "fnl/spec/one.fnl > top#1", "warning"}, {"forbidden-form", "fnl/spec/one.fnl > top#2", "warning"}, {"forbidden-form", "fnl/spec/one.fnl > module:plenary.busted", "warning"}}
    local actual_7_auto
    local _18_
    if error then
      _18_ = {}
    else
      _18_ = rules.check(path, forms, policy, source)
    end
    actual_7_auto = forbidden_form_identities({findings = _18_})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("filters require, import, and module targets by canonical modules", _17_)
end
require("plenary.busted").describe("forbidden-form", _15_)
local function _20_()
  local function _21_()
    local scenario = core_require_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = scenario.before
    local actual_7_auto = scenario.after
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not mutate identity forms", _21_)
  local function _22_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"core-require", "fnl/app.fnl > local:c", "error"}}
    local actual_7_auto = core_require_identities(core_require_scenario())
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("reports the core-require finding with its established identity", _22_)
end
return require("plenary.busted").describe("lint-rules-check", _20_)
