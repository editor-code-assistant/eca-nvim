-- [nfnl] fnl/spec/fennel-extras/lint_spec.fnl
local core = require("eca.nfnl.core")
local config = require("fennel-extras.config")
local exclusion = require("fennel-extras.lint.exclusion")
local function load_lint()
  local ok, result = pcall(require, "fennel-extras.lint")
  if ok then
    return result
  else
    return {["module-missing"] = true}
  end
end
local all_severities = {["required-form"] = {{severity = "off", ["applies-to"] = {}, options = {}, exclusions = {}}}, ["module-import"] = {{severity = "error", ["applies-to"] = {}, options = {}, exclusions = {}}}, ["form-child-count"] = {{severity = "error", ["applies-to"] = {}, options = {}, exclusions = {}}}, ["file-size"] = {{severity = "warning", ["applies-to"] = {}, options = {}, exclusions = {}}}, ["form-chain"] = {{severity = "warning", ["applies-to"] = {}, options = {["allowed-chains"] = {}}, exclusions = {}}}}
local matcher = require("fennel-extras.cli.matcher")
local registry = require("fennel-extras.lint.rules.registry")
local source_rules = {["form-chain"] = true, ["file-size"] = true}
local spec_rules = {["module-import"] = true, ["required-form"] = true, ["form-child-count"] = true}
local all_options = {["required-form"] = {forms = {"module"}}, ["module-import"] = {mode = "forbid", modules = {"plenary.busted", "luassert"}, exclusions = {{path = "^fnl/spec/eca/macros[.]fnlm$"}}}, ["form-child-count"] = {children = {"is"}, ["max-count"] = 1}, ["form-chain"] = {["allowed-chains"] = {}}, ["file-size"] = {["max-code-lines"] = 300}}
local canonical_selectors = {["required-form"] = {forms = {"module"}}}
local canonical_options = {["file-size"] = {["max-code-lines"] = 300}, ["form-child-count"] = {children = {"is"}, ["max-count"] = 1}, ["form-chain"] = {["allowed-chains"] = {}}}
local function canonical_rule_data(rule, options)
  local clean = vim.deepcopy((options or {}))
  local applies = vim.deepcopy((canonical_selectors[rule] or {}))
  clean["applies-to"] = nil
  for key, _ in pairs({forms = true, modules = true}) do
    if clean[key] then
      applies[key] = clean[key]
      clean[key] = nil
    else
    end
  end
  if clean.module then
    applies.modules = clean.module
    if (rule == "module-import") then
      clean.mode = "require"
    else
    end
    clean.module = nil
  else
  end
  return {["applies-to"] = applies, options = clean}
end
local function all_enabled_policy()
  local policy = {}
  for rule, instances in pairs(all_severities) do
    local scope
    if (rule == "form-child-count") then
      scope = {files = {"^fnl/spec/"}, forms = {"testing"}}
    else
      if source_rules[rule] then
        scope = {files = {"^fnl/[^s]"}}
      else
        if spec_rules[rule] then
          scope = {files = {"^fnl/spec/"}}
        else
          scope = {}
        end
      end
    end
    local severity = instances[1].severity
    if (rule == "module-import") then
      policy[rule] = {{severity = "error", ["applies-to"] = {files = {"^fnl/spec/"}, forms = {"deftest", "testing", "is"}, modules = "spec.eca.macros"}, options = {mode = "require"}, exclusions = {{path = "^fnl/spec/eca/macros[.]fnlm$"}}}, {severity = "error", ["applies-to"] = {files = {"^fnl/spec/"}, modules = {"plenary.busted", "luassert"}}, options = {mode = "forbid"}, exclusions = {{path = "^fnl/spec/eca/macros[.]fnlm$"}}}, {severity = "error", ["applies-to"] = {modules = "eca.nfnl.core"}, options = {mode = "require", binding = "core"}, exclusions = {}}}
    else
      policy[rule] = {{severity = severity, ["applies-to"] = core.merge(scope, (canonical_selectors[rule] or {})), options = (canonical_options[rule] or {}), exclusions = {}}}
    end
  end
  return policy
end
local function compatibility_rule_value(rule, severity)
  if (("table" == type(severity)) and ("table" == type(severity[1]))) then
    local tbl_26_ = {}
    local i_27_ = 0
    for _, entry in ipairs(severity) do
      local val_28_
      do
        local raw
        if (entry.options and (#vim.tbl_keys(entry.options) > 0)) then
          raw = entry.options
        else
          raw = all_options[rule]
        end
        local data = canonical_rule_data(rule, raw)
        local _10_
        if (entry["applies-to"] and (#vim.tbl_keys(entry["applies-to"]) > 0)) then
          _10_ = entry["applies-to"]
        else
          if source_rules[rule] then
            _10_ = {files = {"^fnl/[^s]"}}
          else
            if spec_rules[rule] then
              _10_ = {files = {"^fnl/spec/"}}
            else
              _10_ = {}
            end
          end
        end
        val_28_ = {severity = entry.severity, ["applies-to"] = core.merge(_10_, data["applies-to"]), options = data.options, exclusions = (entry.exclusions or {})}
      end
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    return tbl_26_
  else
    if ("table" == type(severity)) then
      local raw
      if (severity.options and (#vim.tbl_keys(severity.options) > 0)) then
        raw = severity.options
      else
        raw = all_options[rule]
      end
      local data = canonical_rule_data(rule, raw)
      local _16_
      if (severity["applies-to"] and (#vim.tbl_keys(severity["applies-to"]) > 0)) then
        _16_ = severity["applies-to"]
      else
        if source_rules[rule] then
          _16_ = {files = {"^fnl/[^s]"}}
        else
          if spec_rules[rule] then
            _16_ = {files = {"^fnl/spec/"}}
          else
            _16_ = {}
          end
        end
      end
      return {{severity = severity.severity, ["applies-to"] = core.merge(_16_, data["applies-to"]), options = data.options, exclusions = (severity.exclusions or {})}}
    else
      local data = canonical_rule_data(rule, all_options[rule])
      return {{severity = severity, ["applies-to"] = data["applies-to"], options = data.options, exclusions = {}}}
    end
  end
end
local function compatibility_policy(rules)
  local policy = all_enabled_policy()
  for rule, severity in pairs(rules) do
    policy[rule] = compatibility_rule_value(rule, severity)
  end
  return policy
end
local function policy_size(policy)
  return (#vim.tbl_keys(policy) - ((policy.options and 1) or 0))
end
local function check_source_success(findings, err)
  if findings then
    return findings
  else
    return {["value-nil?"] = true, message = (err and err.message), line = (err and err.line), col = (err and err.col)}
  end
end
local function check_source_result(ok, findings, err)
  if ok then
    return check_source_success(findings, err)
  else
    return {["value-nil?"] = true, message = (findings and findings.message)}
  end
end
local function check_source_call(lint, source, ctx)
  local function _24_()
    return lint.check(source, ctx)
  end
  return pcall(_24_)
end
local function policy_for(rules)
  return ((rules and compatibility_policy(rules)) or all_enabled_policy())
end
local function lint_context(path, rules)
  return {path = path, rules = policy_for(rules), matcher = matcher["vim-matcher"]()}
end
local function check_source_loaded(lint, source, path, rules)
  local ok, findings, err = check_source_call(lint, source, lint_context(path, rules))
  return check_source_result(ok, findings, err)
end
local function check_source(source, path, rules)
  local lint = load_lint()
  if lint["module-missing"] then
    return lint
  else
    return check_source_loaded(lint, source, path, rules)
  end
end
local function no_findings_result(err)
  return {["value-nil?"] = true, message = (err and err.message)}
end
local function check_source_exact_call(lint, source, path, rules)
  local context = {path = path, rules = rules}
  return lint.check(source, context)
end
local function check_source_exact_result(findings, err)
  if findings then
    return findings
  else
    return no_findings_result(err)
  end
end
local function check_source_exact_loaded(lint, source, path, rules)
  local findings, err = check_source_exact_call(lint, source, path, rules)
  return check_source_exact_result(findings, err)
end
local function check_source_exact(source, path, rules)
  local lint = load_lint()
  if lint["module-missing"] then
    return lint
  else
    return check_source_exact_loaded(lint, source, path, rules)
  end
end
local function load_matcher()
  local ok, result = pcall(require, "fennel-extras.cli.matcher")
  if ok then
    return result
  else
    return {["module-missing"] = true}
  end
end
local function apply_test_exclusions(findings, source, exclusions, matcher0)
  if exclusions then
    local filtered, _ = exclusion.apply(findings, exclusions, source, matcher0)
    return filtered
  else
    return findings
  end
end
local function matcher_context(path, rules, exclusions)
  return {path = path, rules = compatibility_policy(rules), exclusions = exclusions, matcher = matcher["vim-matcher"]()}
end
local function check_source_with_matcher_call(lint, source, path, rules, exclusions)
  return lint.check(source, matcher_context(path, rules, exclusions))
end
local function check_source_with_matcher_result(ok, value, err)
  if ok then
    return value
  else
    return {["value-nil?"] = true, message = (err and err.message)}
  end
end
local function check_source_with_matcher_loaded(lint, source, path, rules, exclusions)
  local matcher0 = matcher["vim-matcher"]()
  local ok, value, err = pcall(check_source_with_matcher_call, lint, source, path, rules, exclusions)
  local filtered = (ok and apply_test_exclusions(value, source, exclusions, matcher0))
  return check_source_with_matcher_result(ok, filtered, err)
end
local function check_source_with_matcher(source, path, rules, exclusions)
  local lint = load_lint()
  local matcher0 = load_matcher()
  if (lint["module-missing"] or matcher0["module-missing"]) then
    return {["module-missing"] = true}
  else
    return check_source_with_matcher_loaded(lint, source, path, rules, exclusions)
  end
end
local function finding_summary(result)
  if (result["module-missing"] or result["value-nil?"]) then
    return result
  else
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding in ipairs(result) do
      local val_28_ = {kind = finding.kind, path = finding.path, line = finding.line, col = finding.col, ["end-line"] = finding["end-line"], ["end-col"] = finding["end-col"], severity = finding.severity, rule = finding.rule, form = finding.form, message = finding.message}
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    return tbl_26_
  end
end
local function finding_identities(result)
  if (result["module-missing"] or result["value-nil?"]) then
    return result
  else
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding in ipairs(result) do
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
local function findings_for_rule(source, path, rule, rules)
  local result = check_source(source, path, rules)
  if (result["module-missing"] or result["value-nil?"]) then
    return result
  else
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding in ipairs(result) do
      local val_28_
      if (finding.rule == rule) then
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
end
local function forms_for(source, path, rules)
  return finding_identities(check_source(source, path, rules))
end
local function read_source(path)
  local ok, result
  local function _39_()
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    return source
  end
  ok, result = pcall(_39_)
  if ok then
    return result
  else
    return {error = "read failed", path = path}
  end
end
local function project_fennel_files()
  local paths = {}
  local files = vim.fn.globpath("fnl", "**/*.fnl", false, true)
  for _, path in ipairs(files) do
    if not string.find(path, "^fnl/eca/nfnl/") then
      table.insert(paths, path)
    else
    end
  end
  return paths
end
local function count_finding(counts, finding)
  if counts[finding.rule] then
    counts[finding.rule] = (counts[finding.rule] + 1)
    return nil
  else
    return nil
  end
end
local function count_findings(counts, findings)
  for _, finding in ipairs(findings) do
    count_finding(counts, finding)
  end
  return nil
end
local function record_cli_findings(path, findings, cli_files)
  for _, finding in ipairs(findings) do
    table.insert(cli_files, {path, finding.rule})
  end
  return nil
end
local function record_lint_findings(path, findings, lint_files)
  for _, finding in ipairs(findings) do
    table.insert(lint_files, {path, finding.rule})
  end
  return nil
end
local function record_lint_findings_if_applicable(path, findings, lint_files)
  if string.find(path, "^fnl/fennel%-extras/lint") then
    return record_lint_findings(path, findings, lint_files)
  else
    return nil
  end
end
local function record_findings(path, findings, lint_files, cli_files)
  if string.find(path, "^fnl/fennel%-extras/cli") then
    return record_cli_findings(path, findings, cli_files)
  else
    return record_lint_findings_if_applicable(path, findings, lint_files)
  end
end
local function record_read_failure(path, lint_files, cli_files)
  if string.find(path, "^fnl/fennel%-extras/cli") then
    return table.insert(cli_files, path)
  else
    return table.insert(lint_files, path)
  end
end
local function collect_repo_success(lint, source, path, counts, lint_files, cli_files, rules)
  local findings = lint.check(source, lint_context(path, rules))
  count_findings(counts, findings)
  return record_findings(path, findings, lint_files, cli_files)
end
local function collect_repo_path(lint, path, counts, lint_files, cli_files, rules)
  local source = read_source(path)
  if source.error then
    return record_read_failure(path, lint_files, cli_files)
  else
    return collect_repo_success(lint, source, path, counts, lint_files, cli_files, rules)
  end
end
local function collect_repo_findings(lint, counts, lint_files, cli_files, rules)
  for _, path in ipairs(project_fennel_files()) do
    collect_repo_path(lint, path, counts, lint_files, cli_files, rules)
  end
  return {counts = counts, ["lint-files"] = lint_files, ["cli-files"] = cli_files}
end
local function repo_scenario(rules)
  local lint = load_lint()
  local counts = {["module-import"] = 0, ["form-child-count"] = 3, ["file-size"] = 0, ["form-chain"] = 0}
  local lint_files = {}
  local cli_files = {}
  if lint["module-missing"] then
    return {["module-missing"] = true}
  else
    return collect_repo_findings(lint, counts, lint_files, cli_files, rules)
  end
end
local function _48_()
  local function _49_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("the approved spec macro import is clean", _49_)
  local function _50_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-import", "fnl/spec/app_spec.fnl > top#1", "error"}}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing} :spec.eca.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec macro import missing is is reported", _50_)
  local function _51_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :other.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec macro import from another module is reported", _51_)
  local function _52_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(deftest run (is true))", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec with no macro import has the spec identity", _52_)
  local function _53_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = findings_for_rule("'(import-macros {: deftest : testing : is} :spec.eca.macros)", "fnl/spec/app_spec.fnl", "module-import")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a prefixed spec macro import is reported", _53_)
  local function _54_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = findings_for_rule("(do (import-macros {: deftest : testing : is} :spec.eca.macros))\n(deftest run (testing \"works\" (is true)))", "fnl/spec/x_spec.fnl", "module-import")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested spec macro import is reported", _54_)
  local function _55_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(import-macros {: deftest} :other) (deftest t (testing \"x\" (is true)))", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a wrong macro import is reported independently of test content", _55_)
  local function _56_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(require :foo)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec with only a direct require still has the spec identity", _56_)
  local function _57_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(module app)\n(import-macros {: deftest : testing : is} :spec.eca.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a module form in a spec is reported at that form", _57_)
  local function _58_()
    local function _59_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"module-import", "fnl/spec/app_spec.fnl > top#1", "error"}}
      local actual_7_auto = findings_for_rule("(require :plenary.busted)", "fnl/spec/app_spec.fnl", "module-import")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("keyword plenary require is forbidden in ordinary specs", _59_)
    local function _60_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"module-import", "fnl/spec/app_spec.fnl > top#1", "error"}}
      local actual_7_auto = findings_for_rule("(require \"luassert\")", "fnl/spec/app_spec.fnl", "module-import")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("string luassert require is forbidden in ordinary specs", _60_)
    local function _61_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(require :plenary.busted)\n(require \"luassert\")", "fnl/spec/eca/macros.fnlm", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("the spec macro implementation may require test libraries directly", _61_)
    local function _62_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module ordinary)\n(require :plenary.busted)\n(require \"luassert\")", "fnl/ordinary.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("direct test-library requires are not a non-spec finding", _62_)
  end
  require("plenary.busted").describe("module-import", _58_)
  local function _63_()
    local function _64_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"one\" (is true)))", "fnl/spec/app_spec.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("one direct is in testing is clean", _64_)
    local function _65_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"one\" (let [x 1] (is (= x 1)))))", "fnl/spec/app_spec.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("one is inside a let wrapper is clean", _65_)
    local function _66_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"form-child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"none\" (let [x 1] x)))", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("testing with no is is reported", _66_)
    local function _67_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"form-child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"two\" (is true) (is true)))", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("testing with two is forms is reported once", _67_)
    local function _68_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"form-child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"outer\" (testing \"inner\" (is true))))", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("nested testing forms are counted separately", _68_)
    local function _69_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"form-child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"quoted\" '(is true)))", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("quoted is data is not counted", _69_)
    local function _70_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"form-child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" '\n ;; comment\n (is true)))", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quoted is separated by a comment is not counted", _70_)
    local function _71_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"form-child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" `\n(is true)))", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quasiquoted is separated by a newline is not counted", _71_)
    local function _72_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"form-child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" ' (is true)))", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quoted is separated by whitespace is not counted", _72_)
    local function _73_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" '(is false) (is true)))", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quoted is plus an executable is is counted once", _73_)
    local function _74_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"form-child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"is in text\" (print \"is\"))) ;; is\n", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("strings and comments containing is are not counted", _74_)
  end
  return require("plenary.busted").describe("form-child-count", _63_)
end
require("plenary.busted").describe("spec-shape", _48_)
local function _75_()
  local function _76_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_scenario(nil)["cli-files"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("cli implementation files are clean", _76_)
end
require("plenary.busted").describe("lint-repo-properties", _75_)
local function context_base(ctx)
  return ((ctx.rules and vim.tbl_extend("force", ctx, {rules = compatibility_policy(ctx.rules)})) or ctx)
end
local function context_for_check(ctx)
  return vim.tbl_extend("force", {}, context_base(ctx))
end
local function check_context_result(findings, err)
  if findings then
    return findings
  else
    return {["value-nil?"] = true, error = err}
  end
end
local function check_context_loaded(lint, source, ctx)
  local matcher0 = matcher["vim-matcher"]()
  local context = vim.tbl_extend("force", context_for_check(ctx), {matcher = matcher0})
  local findings, err = lint.check(source, context)
  local filtered = (findings and apply_test_exclusions(findings, source, ctx.exclusions, matcher0))
  return check_context_result(filtered, err)
end
local function check_context(source, ctx)
  local lint = load_lint()
  if lint["module-missing"] then
    return lint
  else
    return check_context_loaded(lint, source, ctx)
  end
end
local function _79_()
  local function _80_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = check_context("(local c (require :eca.nfnl.core))", {path = "fnl/app.fnl"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("lint check reports no findings when rules are omitted", _80_)
  local function _81_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 5
    local actual_7_auto = policy_size(all_enabled_policy())
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("the shared compatibility policy enables all retained rules", _81_)
end
require("plenary.busted").describe("opt-in-policy", _79_)
local function first_finding_form(findings, rule)
  local result = nil
  for _, finding in ipairs(findings) do
    if ((result == nil) and (finding.rule == rule)) then
      result = finding.form
    else
    end
  end
  return result
end
local function _83_()
  local source = read_source("fnl/spec/eca/macros.fnlm")
  local result = check_source_with_matcher(source, "fnl/spec/eca/macros.fnlm", {["child-count"] = {{severity = "error", ["applies-to"] = {forms = {"if"}}, options = {["min-count"] = 2, ["max-count"] = 2, ["nil-count"] = false}, exclusions = {}}}}, {{rule = "child-count", code = "^[(]if has-message", reason = "syntax-quoted AST children are structural data, not semantic if branches"}})
  local summary
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding in ipairs(result) do
      local val_28_ = {finding.line, finding.code}
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    summary = tbl_26_
  end
  local assert_5_auto = require("luassert")
  local expected_6_auto = {}
  local actual_7_auto
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding in ipairs(summary) do
      local val_28_
      if (finding[1] == 17) then
        val_28_ = finding
      else
        val_28_ = nil
      end
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
require("plenary.busted").it("narrows syntax-quoted if exclusion without hiding executable if findings", _83_)
local function _87_()
end
require("plenary.busted").describe("normalized-exclusion-identities", _87_)
local function repeated_code(count)
  return string.rep("(local x 1)\n", count)
end
local function file_size_policy(policy, max_code_lines)
  local entry = policy["file-size"]
  if (entry and max_code_lines) then
    local instance = entry[1]
    return vim.tbl_extend("force", policy, {["file-size"] = {{severity = instance.severity, ["applies-to"] = instance["applies-to"], options = vim.tbl_extend("force", instance.options, {["max-code-lines"] = max_code_lines}), exclusions = instance.exclusions}}})
  else
    return policy
  end
end
local function file_size_findings(source, path, rules, max_code_lines, exclusions)
  local policy = file_size_policy(compatibility_policy(rules), max_code_lines)
  local result = check_context(source, {path = path, rules = policy, exclusions = exclusions})
  if (result["module-missing"] or result["value-nil?"]) then
    return result
  else
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding in ipairs(result) do
      local val_28_
      if (finding.rule == "file-size") then
        val_28_ = finding
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
end
local function _92_()
  local function _93_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #file_size_findings(repeated_code(4), "fnl/spec/app_spec.fnl", {}, 3, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("does not report a spec file", _93_)
end
require("plenary.busted").describe("file-size", _92_)
local function findings_for_named_rule(source, path, rule, rules)
  local result = check_source(source, path, rules)
  if (result["module-missing"] or result["value-nil?"]) then
    return result
  else
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding in ipairs(result) do
      local val_28_
      if (finding.rule == rule) then
        val_28_ = finding
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
end
local function safe_findings_for_named_rule(source, path, rule, rules)
  local ok, result
  local function _97_()
    return findings_for_named_rule(source, path, rule, rules)
  end
  ok, result = pcall(_97_)
  local _98_
  if ok then
    _98_ = #result
  else
    _98_ = -1
  end
  return {ok = ok, count = _98_}
end
local function option_rule(rule, options)
  local merged = vim.tbl_extend("force", all_options[rule], options)
  local _
  merged.exclusions = nil
  _ = nil
  local target = options["applies-to"]
  local data = canonical_rule_data(rule, merged)
  local _100_
  if target then
    if ((target == "all") or (target == "all")) then
      _100_ = {}
    else
      _100_ = {files = {target}}
    end
  else
    if (source_rules[rule] and spec_rules[rule]) then
      _100_ = {}
    else
      if source_rules[rule] then
        _100_ = {files = {"^fnl/[^s]"}}
      else
        if spec_rules[rule] then
          _100_ = {files = {"^fnl/spec/"}}
        else
          _100_ = {}
        end
      end
    end
  end
  return {[rule] = {{severity = "warning", ["applies-to"] = core.merge(_100_, data["applies-to"]), options = data.options, exclusions = {}}}}
end
local function option_findings_call(lint, source, path, rule, options)
  local clean = vim.deepcopy(options)
  local _
  clean.exclusions = nil
  _ = nil
  local context = {path = path, rules = option_rule(rule, clean), matcher = matcher["vim-matcher"](), ["defer-exclusions"] = true}
  local _106_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for index, instance in ipairs(context.rules[rule]) do
      local val_28_ = core.assoc(instance, "exclusions", (options.exclusions or {}))
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _106_ = tbl_26_
  end
  context["rules"][rule] = _106_
  return lint.check(source, context)
end
local function option_findings(source, path, rule, options)
  local lint = load_lint()
  local matcher0 = load_matcher()
  if (lint["module-missing"] or matcher0["module-missing"]) then
    return {["module-missing"] = true}
  else
    return option_findings_call(lint, source, path, rule, options)
  end
end
local function _109_()
  local function _110_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = check_source_exact("(defn f [] (if a b c))", "fnl/app.fnl", {["control-layout"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {}, exclusions = {}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("unknown control-layout runtime keys produce no findings", _110_)
  local function _111_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = check_source_exact("(let\n  [x 1]\n  x)", "fnl/app.fnl", {["multiline-layout"] = {{severity = "warning", ["applies-to"] = {}, options = {clauses = {"case", "match", "case-try", "match-try"}, bindings = {"let", "when-let", "if-let", "with-open"}}, exclusions = {}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("unknown multiline-layout runtime keys produce no findings", _111_)
end
require("plenary.busted").describe("removed-layout-rules-runtime", _109_)
local function _112_()
end
require("plenary.busted").describe("module-selector-vector-compatibility", _112_)
local form_chain_rules = {["form-chain"] = {{severity = "error", ["applies-to"] = {forms = {"let"}}, options = {["allowed-chains"] = {{"def", "<form>"}, {"defn", "<form>"}, {"defn-", "<form>"}, {"defn", "when", "<form>"}, {"defn", "fn", "<form>"}}}, exclusions = {}}}}
local multiple_form_chain_rules = {["form-chain"] = {{severity = "error", ["applies-to"] = {forms = {"let", "local"}}, options = {["allowed-chains"] = {{"def", "<form>"}}}, exclusions = {}}}}
local local_placement_rules = {["form-chain"] = {{severity = "error", ["applies-to"] = {forms = {"local"}}, options = {["allowed-chains"] = {{"<form>"}}}, exclusions = {}}}}
local function _113_()
  local function _114_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(local name (require :module))", "fnl/app.fnl", local_placement_rules)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("top-level require local is allowed", _114_)
  local function _115_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(local name (import :module))", "fnl/app.fnl", local_placement_rules)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("top-level import local is allowed", _115_)
  local function _116_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #findings_for_rule("(local value 1)", "fnl/app.fnl", "form-chain", {["form-chain"] = {{severity = "error", ["applies-to"] = {forms = {"local"}}, options = {["allowed-chains"] = {{"def", "<form>"}}}, exclusions = {}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("top-level value local is rejected by the value policy", _116_)
  local function _117_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #findings_for_rule("(defn run [] (local name (require :module)))", "fnl/app.fnl", "form-chain", local_placement_rules)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("nested require local is rejected", _117_)
end
require("plenary.busted").describe("local-placement-policy", _113_)
local unified_form_chain_rules = {["form-chain"] = {{severity = "error", ["applies-to"] = {forms = {"let", "local"}}, options = {["allowed-chains"] = {{"<root>", "<form>"}}, ["forms-between"] = {"when", "fn"}, ["forbidden-chains"] = {{"<root>", "local", "<form>"}}}, exclusions = {}}}}
local function _118_()
  local result = check_source_exact("(testing \"one\" (is (= 1 1)) (is (= 2 2)))", "fnl/spec/app_spec.fnl", {["child-count"] = {{severity = "error", ["applies-to"] = {forms = {"testing"}}, options = {children = {"is"}, ["max-count"] = 1}, exclusions = {}}}, ["form-chain"] = {{severity = "error", ["applies-to"] = {forms = {"is"}}, options = {["allowed-chains"] = {{"testing", "<form>"}}, ["forms-between"] = {}, ["forbidden-chains"] = {}}, exclusions = {}}}})
  local assert_5_auto = require("luassert")
  local expected_6_auto = 2
  local actual_7_auto = #result
  assert_5_auto.same(expected_6_auto, actual_7_auto)
  return true
end
require("plenary.busted").it("child-count and form-chain policies can coexist without changing counts", _118_)
local function _119_()
  local function _120_()
    local rules = {["form-chain"] = {{severity = "error", ["applies-to"] = {forms = {"let"}}, options = {["allowed-chains"] = {{"defn", "when", "<form>"}}, ["forms-between"] = {"fn"}}, exclusions = {}}}}
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #findings_for_rule("(fn [] (defn value [] (when ready (let [x 1] x))))", "fnl/app.fnl", "form-chain", rules)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it(":forms-between only skips after a matched explicit step", _120_)
  local function _121_()
    local rules = {["form-chain"] = {{severity = "error", ["applies-to"] = {forms = {"let"}}, options = {["allowed-chains"] = {{"defn", "when", "<form>"}}, ["forms-between"] = {"when"}}, exclusions = {}}}}
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #findings_for_rule("(defn value [] (when ready (when later (let [x 1] x))))", "fnl/app.fnl", "form-chain", rules)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it(":forms-between matches intermediate forms after an explicit step", _121_)
end
return require("plenary.busted").describe("form-chain-regressions", _119_)
