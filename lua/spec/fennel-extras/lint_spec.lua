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
local all_severities = {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {}, options = {}, exclusions = {}}}, ["required-form"] = {{severity = "off", ["applies-to"] = {}, options = {}, exclusions = {}}}, ["module-import"] = {{severity = "error", ["applies-to"] = {}, options = {}, exclusions = {}}}, ["form-child-count"] = {{severity = "error", ["applies-to"] = {}, options = {}, exclusions = {}}}, ["file-size"] = {{severity = "warning", ["applies-to"] = {}, options = {}, exclusions = {}}}}
local matcher = require("fennel-extras.cli.matcher")
local registry = require("fennel-extras.lint.rules.registry")
local source_rules = {["forbidden-form"] = true, ["file-size"] = true}
local spec_rules = {["module-import"] = true, ["required-form"] = true, ["forbidden-form"] = true, ["form-child-count"] = true}
local all_options = {["forbidden-form"] = {forms = {}}, ["required-form"] = {forms = {"module"}}, ["module-import"] = {mode = "forbid", modules = {"plenary.busted", "luassert"}, exclusions = {{path = "^fnl/spec/eca/macros[.]fnlm$"}}}, ["form-child-count"] = {children = {"is"}, ["max-count"] = 1}, ["file-size"] = {["max-code-lines"] = 300}}
local canonical_selectors = {["forbidden-form"] = {forms = {}}, ["required-form"] = {forms = {"module"}}}
local canonical_options = {["file-size"] = {["max-code-lines"] = 300}, ["form-child-count"] = {children = {"is"}, ["max-count"] = 1}}
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
      if (rule == "forbidden-form") then
        policy[rule] = {{severity = "error", ["applies-to"] = {files = {"^fnl/spec/"}, modules = "module"}, options = {}, exclusions = {}}, {severity = severity, ["applies-to"] = {files = {"^fnl/[^s]"}, forms = {"var", "set", "while"}}, options = {}, exclusions = {}}}
      else
        policy[rule] = {{severity = severity, ["applies-to"] = core.merge(scope, (canonical_selectors[rule] or {})), options = (canonical_options[rule] or {}), exclusions = {}}}
      end
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
        local _11_
        if (entry["applies-to"] and (#vim.tbl_keys(entry["applies-to"]) > 0)) then
          _11_ = entry["applies-to"]
        else
          if source_rules[rule] then
            _11_ = {files = {"^fnl/[^s]"}}
          else
            if spec_rules[rule] then
              _11_ = {files = {"^fnl/spec/"}}
            else
              _11_ = {}
            end
          end
        end
        val_28_ = {severity = entry.severity, ["applies-to"] = core.merge(_11_, data["applies-to"]), options = data.options, exclusions = (entry.exclusions or {})}
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
      local _17_
      if (severity["applies-to"] and (#vim.tbl_keys(severity["applies-to"]) > 0)) then
        _17_ = severity["applies-to"]
      else
        if source_rules[rule] then
          _17_ = {files = {"^fnl/[^s]"}}
        else
          if spec_rules[rule] then
            _17_ = {files = {"^fnl/spec/"}}
          else
            _17_ = {}
          end
        end
      end
      return {{severity = severity.severity, ["applies-to"] = core.merge(_17_, data["applies-to"]), options = data.options, exclusions = (severity.exclusions or {})}}
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
  local function _25_()
    return lint.check(source, ctx)
  end
  return pcall(_25_)
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
  local function _40_()
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    return source
  end
  ok, result = pcall(_40_)
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
  local counts = {["forbidden-form"] = 0, ["module-import"] = 0, ["form-child-count"] = 3}
  local lint_files = {}
  local cli_files = {}
  if lint["module-missing"] then
    return {["module-missing"] = true}
  else
    return collect_repo_findings(lint, counts, lint_files, cli_files, rules)
  end
end
local function _49_()
  local function _50_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("the approved spec macro import is clean", _50_)
  local function _51_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-import", "fnl/spec/app_spec.fnl > top#1", "error"}}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing} :spec.eca.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec macro import missing is is reported", _51_)
  local function _52_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :other.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec macro import from another module is reported", _52_)
  local function _53_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(deftest run (is true))", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec with no macro import has the spec identity", _53_)
  local function _54_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = findings_for_rule("'(import-macros {: deftest : testing : is} :spec.eca.macros)", "fnl/spec/app_spec.fnl", "module-import")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a prefixed spec macro import is reported", _54_)
  local function _55_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = findings_for_rule("(do (import-macros {: deftest : testing : is} :spec.eca.macros))\n(deftest run (testing \"works\" (is true)))", "fnl/spec/x_spec.fnl", "module-import")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested spec macro import is reported", _55_)
  local function _56_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(import-macros {: deftest} :other) (deftest t (testing \"x\" (is true)))", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a wrong macro import is reported independently of test content", _56_)
  local function _57_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(require :foo)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec with only a direct require still has the spec identity", _57_)
  local function _58_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(module app)\n(import-macros {: deftest : testing : is} :spec.eca.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a module form in a spec is reported at that form", _58_)
  local function _59_()
    local function _60_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"module-import", "fnl/spec/app_spec.fnl > top#1", "error"}}
      local actual_7_auto = findings_for_rule("(require :plenary.busted)", "fnl/spec/app_spec.fnl", "module-import")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("keyword plenary require is forbidden in ordinary specs", _60_)
    local function _61_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"module-import", "fnl/spec/app_spec.fnl > top#1", "error"}}
      local actual_7_auto = findings_for_rule("(require \"luassert\")", "fnl/spec/app_spec.fnl", "module-import")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("string luassert require is forbidden in ordinary specs", _61_)
    local function _62_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(require :plenary.busted)\n(require \"luassert\")", "fnl/spec/eca/macros.fnlm", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("the spec macro implementation may require test libraries directly", _62_)
    local function _63_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module ordinary)\n(require :plenary.busted)\n(require \"luassert\")", "fnl/ordinary.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("direct test-library requires are not a non-spec finding", _63_)
  end
  require("plenary.busted").describe("module-import", _59_)
  local function _64_()
    local function _65_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"one\" (is true)))", "fnl/spec/app_spec.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("one direct is in testing is clean", _65_)
    local function _66_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"one\" (let [x 1] (is (= x 1)))))", "fnl/spec/app_spec.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("one is inside a let wrapper is clean", _66_)
    local function _67_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"form-child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"none\" (let [x 1] x)))", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("testing with no is is reported", _67_)
    local function _68_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"form-child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"two\" (is true) (is true)))", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("testing with two is forms is reported once", _68_)
    local function _69_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"form-child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"outer\" (testing \"inner\" (is true))))", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("nested testing forms are counted separately", _69_)
    local function _70_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"form-child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"quoted\" '(is true)))", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("quoted is data is not counted", _70_)
    local function _71_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"form-child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" '\n ;; comment\n (is true)))", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quoted is separated by a comment is not counted", _71_)
    local function _72_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"form-child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" `\n(is true)))", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quasiquoted is separated by a newline is not counted", _72_)
    local function _73_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"form-child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" ' (is true)))", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quoted is separated by whitespace is not counted", _73_)
    local function _74_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" '(is false) (is true)))", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quoted is plus an executable is is counted once", _74_)
    local function _75_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"form-child-count", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"is in text\" (print \"is\"))) ;; is\n", "fnl/spec/app_spec.fnl", "form-child-count")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("strings and comments containing is are not counted", _75_)
  end
  return require("plenary.busted").describe("form-child-count", _64_)
end
require("plenary.busted").describe("spec-shape", _49_)
local function function_findings(source)
  return findings_for_rule(source, "fnl/app.fnl", "forbidden-form", {["forbidden-form"] = {{severity = "off", ["applies-to"] = {}, options = {}, exclusions = {}}}})
end
local function _76_()
  local function _77_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_scenario(nil)["cli-files"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("cli implementation files are clean", _77_)
end
require("plenary.busted").describe("lint-repo-properties", _76_)
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
local function _80_()
  local function _81_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = check_context("(local c (require :eca.nfnl.core))", {path = "fnl/app.fnl"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("lint check reports no findings when rules are omitted", _81_)
  local function _82_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 5
    local actual_7_auto = policy_size(all_enabled_policy())
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("the shared compatibility policy enables all retained rules", _82_)
end
require("plenary.busted").describe("opt-in-policy", _80_)
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
local function _84_()
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
require("plenary.busted").it("narrows syntax-quoted if exclusion without hiding executable if findings", _84_)
local function _88_()
end
require("plenary.busted").describe("normalized-exclusion-identities", _88_)
local function forbidden_form_summary(source, path, rules)
  local result = findings_for_rule(source, path, "forbidden-form", rules)
  if (result["module-missing"] or result["value-nil?"]) then
    return result
  else
    local _89_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, finding in ipairs(result) do
        local val_28_ = finding[1]
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      _89_ = tbl_26_
    end
    local _91_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, finding in ipairs(result) do
        local val_28_ = finding[3]
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      _91_ = tbl_26_
    end
    return {count = #result, rules = _89_, severities = _91_}
  end
end
local function forbidden_form_forms(source, path, rules)
  local result = check_source(source, path, rules)
  if (result["module-missing"] or result["value-nil?"]) then
    return result
  else
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding in ipairs(result) do
      local val_28_
      if (finding.rule == "forbidden-form") then
        val_28_ = finding.form
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
local function _97_()
  local function _98_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 0, rules = {}, severities = {}}
    local actual_7_auto = forbidden_form_summary("(var x 1) (set x 2) (while ok (g))", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("does not flag mutations in a spec file", _98_)
end
require("plenary.busted").describe("forbidden-form", _97_)
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
local function _103_()
  local function _104_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #file_size_findings(repeated_code(4), "fnl/spec/app_spec.fnl", {}, 3, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("does not report a spec file", _104_)
end
require("plenary.busted").describe("file-size", _103_)
local function _105_()
end
require("plenary.busted").describe("forbidden-form-exclusions", _105_)
local function _106_()
end
require("plenary.busted").describe("forbidden-form-nested-exclusion", _106_)
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
  local function _110_()
    return findings_for_named_rule(source, path, rule, rules)
  end
  ok, result = pcall(_110_)
  local _111_
  if ok then
    _111_ = #result
  else
    _111_ = -1
  end
  return {ok = ok, count = _111_}
end
local function option_rule(rule, options)
  local merged = vim.tbl_extend("force", all_options[rule], options)
  local _
  merged.exclusions = nil
  _ = nil
  local target = options["applies-to"]
  local data = canonical_rule_data(rule, merged)
  local _113_
  if target then
    if ((target == "all") or (target == "all")) then
      _113_ = {}
    else
      _113_ = {files = {target}}
    end
  else
    if (source_rules[rule] and spec_rules[rule]) then
      _113_ = {}
    else
      if source_rules[rule] then
        _113_ = {files = {"^fnl/[^s]"}}
      else
        if spec_rules[rule] then
          _113_ = {files = {"^fnl/spec/"}}
        else
          _113_ = {}
        end
      end
    end
  end
  return {[rule] = {{severity = "warning", ["applies-to"] = core.merge(_113_, data["applies-to"]), options = data.options, exclusions = {}}}}
end
local function option_findings_call(lint, source, path, rule, options)
  local clean = vim.deepcopy(options)
  local _
  clean.exclusions = nil
  _ = nil
  local context = {path = path, rules = option_rule(rule, clean), matcher = matcher["vim-matcher"](), ["defer-exclusions"] = true}
  local _119_
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
    _119_ = tbl_26_
  end
  context["rules"][rule] = _119_
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
local function _122_()
  local function _123_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #option_findings("(import-macros {: check : verify} :my.spec.macros)", "fnl/spec/app_spec.fnl", "module-import", {module = "my.spec.macros", forms = {"check", "verify"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("module-import accepts configured macro names and module", _123_)
  local function _124_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #option_findings("(module app)", "fnl/spec/app_spec.fnl", "forbidden-form", {module = "custom-module"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("forbidden-form accepts a configured module form", _124_)
  local function _125_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #option_findings("(require :custom.test)", "fnl/spec/app_spec.fnl", "module-import", {mode = "forbid", modules = {"custom.test"}, exclusions = {}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("module-import accepts configured forbidden modules", _125_)
  local function _126_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #option_findings("(checking \"one\" (assertion true))", "fnl/spec/app_spec.fnl", "form-child-count", {children = {"assertion"}, ["max-count"] = 1})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("form-child-count accepts configured testing and assertion forms", _126_)
  local function _127_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #option_findings("(var x 1)", "fnl/spec/app_spec.fnl", "forbidden-form", {["applies-to"] = "all"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("applies-to all makes forbidden-form inspect spec files", _127_)
  local function _128_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #option_findings("(alter x 1)", "fnl/app.fnl", "forbidden-form", {forms = {"alter"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("forbidden-form accepts configured mutation forms", _128_)
  local function _129_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #option_findings("(local c (require :my.core))", "fnl/app.fnl", "module-import", {mode = "require", module = "my.core", binding = "c"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("module-import accepts configured module and binding", _129_)
  local function _130_()
  end
  require("plenary.busted").describe("selector-exclusions", _130_)
  local function _131_()
    local function _132_()
      local namespace_result = option_findings("(namespace foo)", "fnl/spec/app_spec.fnl", "forbidden-form", {forms = {"namespace"}})
      local module_result = option_findings("(module foo)", "fnl/spec/app_spec.fnl", "forbidden-form", {forms = {"namespace"}})
      local assert_28_auto = require("luassert")
      local value_29_auto = ((1 == #namespace_result) and (0 == #module_result))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 1 (length namespace-result)) (= 0 (length module-result)))")
      return true
    end
    return require("plenary.busted").it("forbidden-form uses the configured module-form", _132_)
  end
  return require("plenary.busted").describe("shipped-bug-regressions", _131_)
end
require("plenary.busted").describe("configurable-rule-options", _122_)
local function _133_()
  local function _134_()
    local result = check_source_exact("(require :plenary.busted)\n(require :luassert)", "fnl/spec/app_spec.fnl", {["module-import"] = {{severity = "error", ["applies-to"] = {modules = {"plenary.busted"}}, options = {mode = "forbid"}, exclusions = {}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"module-import"}
    local actual_7_auto
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, finding in ipairs(result) do
        local val_28_ = finding.rule
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
  require("plenary.busted").it("moved module selectors preserve exact, order-sensitive matching", _134_)
  local function _136_()
    local empty_result = check_source_exact("(var x 1)", "fnl/app.fnl", {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {forms = {}}, options = {}, exclusions = {}}}})
    local absent_result = check_source_exact("(var x 1)", "fnl/app.fnl", {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {}, options = {}, exclusions = {}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = #absent_result
    local actual_7_auto = #empty_result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("empty and absent form selectors both mean all forms", _136_)
  local function _137_()
    local result = check_source_exact("(module app)\n(local x 1)", "fnl/app.fnl", {["file-size"] = {{severity = "warning", ["applies-to"] = {files = {"^fnl/app[.]fnl$"}}, options = {["max-code-lines"] = 1}, exclusions = {}}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = ((1 == #result) and (nil == result[1].node))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 1 (length result)) (= nil (. result 1 \"node\")))")
    return true
  end
  return require("plenary.busted").it("file-level findings retain a nil node with moved file selectors", _137_)
end
require("plenary.busted").describe("migrated-selector-runtime-contract", _133_)
local function _138_()
  local function _139_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = check_source_exact("(defn f [] (if a b c))", "fnl/app.fnl", {["control-layout"] = {{severity = "warning", ["applies-to"] = {forms = {"if"}}, options = {}, exclusions = {}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("unknown control-layout runtime keys produce no findings", _139_)
  local function _140_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = check_source_exact("(let\n  [x 1]\n  x)", "fnl/app.fnl", {["multiline-layout"] = {{severity = "warning", ["applies-to"] = {}, options = {clauses = {"case", "match", "case-try", "match-try"}, bindings = {"let", "when-let", "if-let", "with-open"}}, exclusions = {}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("unknown multiline-layout runtime keys produce no findings", _140_)
end
require("plenary.busted").describe("removed-layout-rules-runtime", _138_)
local function _141_()
end
require("plenary.busted").describe("module-selector-vector-compatibility", _141_)
local form_chain_rules = {["form-chain"] = {{severity = "error", ["applies-to"] = {forms = {"let"}}, options = {["allowed-chains"] = {{"def", "<form>"}, {"defn", "<form>"}, {"defn-", "<form>"}, {"defn", "when", "<form>"}, {"defn", "fn", "<form>"}}}, exclusions = {}}}}
local multiple_form_chain_rules = {["form-chain"] = {{severity = "error", ["applies-to"] = {forms = {"let", "local"}}, options = {["allowed-chains"] = {{"def", "<form>"}}}, exclusions = {}}}}
local function _142_()
  local function _143_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = findings_for_rule("(def value (let [x 1] x))", "fnl/app.fnl", "form-chain", form_chain_rules)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a direct first-body let is allowed", _143_)
  local function _144_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #findings_for_rule("(def value (print \"before\") (let [x 1] x))", "fnl/app.fnl", "form-chain", form_chain_rules)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a let after another body form is rejected", _144_)
  local function _145_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = findings_for_rule("(defn value [] (when ready (let [x 1] x)))", "fnl/app.fnl", "form-chain", form_chain_rules)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("let through first-body when is allowed", _145_)
  local function _146_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = findings_for_rule("(defn value [] (fn [] (let [x 1] x)))", "fnl/app.fnl", "form-chain", form_chain_rules)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("let through first-body fn is allowed", _146_)
  local function _147_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #findings_for_rule("(defn value [] (when ready (when later (let [x 1] x))))", "fnl/app.fnl", "form-chain", form_chain_rules)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("nested when is rejected", _147_)
  local function _148_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #findings_for_rule("(defn value [] (when ready (print \"before\") (let [x 1] x)))", "fnl/app.fnl", "form-chain", form_chain_rules)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("later when is rejected", _148_)
  local function _149_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #findings_for_rule("(def value (let [x 1] x) (local y 2))", "fnl/app.fnl", "form-chain", multiple_form_chain_rules)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("each selected form target is evaluated", _149_)
  local function _150_()
    local function _151_()
      local ok, result, error = pcall(config.validate, {lint = {rules = {["form-chain"] = {{severity = "error", ["applies-to"] = {forms = {"let"}}, options = {["allowed-chains"] = {{"def", 42}}}, exclusions = {}}}}}})
      local assert_28_auto = require("luassert")
      local value_29_auto = (ok and not result and error)
      assert_28_auto.is_truthy(value_29_auto, "(and ok (not result) error)")
      return true
    end
    require("plenary.busted").it("invalid chain shape is rejected as a structured error", _151_)
    local function _152_()
      for _, exception in ipairs({"top-level", {"nested"}, {"top-level", "nested"}}) do
        local ok, result, error = pcall(config.validate, {lint = {rules = {["forbidden-form"] = {{severity = "error", ["applies-to"] = {forms = {"local"}}, options = {exception = exception}, exclusions = {}}}}}})
        local assert_28_auto = require("luassert")
        local value_29_auto = (not ok and (result or error))
        assert_28_auto.is_truthy(value_29_auto, "(and (not ok) (or result error))")
      end
      return nil
    end
    return require("plenary.busted").it("invalid forbidden-form exception shape is rejected", _152_)
  end
  return require("plenary.busted").describe("form-chain-config-validation", _150_)
end
require("plenary.busted").describe("form-chain-first-body", _142_)
local local_placement_rules = {["forbidden-form"] = {{severity = "error", ["applies-to"] = {forms = {"local"}}, options = {exception = {"top-level"}}, exclusions = {}}}, ["form-chain"] = {{severity = "error", ["applies-to"] = {forms = {"local"}}, options = {["allowed-chains"] = {{"<form>"}}}, exclusions = {}}}}
local function _153_()
  local function _154_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = findings_for_rule("(local value 1)", "fnl/app.fnl", "forbidden-form", local_placement_rules)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("top-level local is allowed by the top-level exception", _154_)
  local function _155_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #findings_for_rule("(defn run [] (local value 1))", "fnl/app.fnl", "forbidden-form", local_placement_rules)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("nested local is still reported", _155_)
end
require("plenary.busted").describe("forbidden-form-top-level-exception", _153_)
local function _156_()
  local function _157_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(local name (require :module))", "fnl/app.fnl", local_placement_rules)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("top-level require local is allowed", _157_)
  local function _158_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(local name (import :module))", "fnl/app.fnl", local_placement_rules)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("top-level import local is allowed", _158_)
  local function _159_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #findings_for_rule("(local value 1)", "fnl/app.fnl", "form-chain", {["form-chain"] = {{severity = "error", ["applies-to"] = {forms = {"local"}}, options = {["allowed-chains"] = {{"def", "<form>"}}}, exclusions = {}}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("top-level value local is rejected by the value policy", _159_)
  local function _160_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #findings_for_rule("(defn run [] (local name (require :module)))", "fnl/app.fnl", "form-chain", local_placement_rules)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("nested require local is rejected", _160_)
end
return require("plenary.busted").describe("local-placement-policy", _156_)
