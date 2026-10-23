-- [nfnl] fnl/spec/fennel-extras/lint_spec.fnl
local function load_lint()
  local ok, result = pcall(require, "fennel-extras.lint")
  if ok then
    return result
  else
    return {["module-missing"] = true}
  end
end
local all_severities = {["module-style"] = "error", ["spec-macro-import"] = "error", ["spec-no-module"] = "error", ["spec-direct-require"] = "error", ["one-is-per-testing"] = "error", ["if-branch-call"] = "warning", ["if-without-else"] = "warning", ["control-layout"] = "warning", ["defn-args-newline"] = "warning", ["multiline-layout"] = "warning", ["function-shape"] = "warning", ["no-mutation"] = "warning", ["file-size"] = "warning", ["core-require"] = "error", ["unused-and-or"] = "warning", ["binding-per-line"] = "warning", ["call-data-arg"] = "warning"}
local matcher = require("fennel-extras.cli.matcher")
local all_options = {["module-style"] = {["applies-to"] = "source", ["macro-module"] = "eca.nfnl.macros.aniseed", ["required-macros"] = {"module", "def", "defn", "defn-"}}, ["spec-macro-import"] = {["applies-to"] = "spec", ["macro-module"] = "spec.eca.macros", ["required-macros"] = {"deftest", "testing", "is"}, ["exempt-files"] = {"^fnl/spec/eca/macros[.]fnlm$"}}, ["spec-no-module"] = {["applies-to"] = "spec", ["module-form"] = "module"}, ["spec-direct-require"] = {["applies-to"] = "spec", ["forbidden-modules"] = {"plenary.busted", "luassert"}, ["exempt-files"] = {"^fnl/spec/eca/macros[.]fnlm$"}}, ["one-is-per-testing"] = {["applies-to"] = "all", ["testing-form"] = "testing", ["assertion-form"] = "is", count = 1}, ["if-branch-call"] = {["applies-to"] = "all", ["if-forms"] = {"if"}}, ["if-without-else"] = {["applies-to"] = "all", ["if-forms"] = {"if"}, ["flag-nil-else"] = true}, ["control-layout"] = {["applies-to"] = "all", ["control-forms"] = {"if", "when", "and", "or", "case", "match"}}, ["defn-args-newline"] = {["applies-to"] = "all", forms = {"defn", "defn-"}}, ["multiline-layout"] = {["applies-to"] = "all", ["clause-forms"] = {"case", "match", "case-try", "match-try"}, ["binding-forms"] = {"let", "when-let", "if-let", "with-open"}}, ["function-shape"] = {["applies-to"] = "all", ["function-forms"] = {"defn", "defn-", "fn", "lambda", "\206\187"}}, ["no-mutation"] = {["applies-to"] = "source", forms = {"var", "set", "while"}}, ["file-size"] = {["applies-to"] = "source", ["max-code-lines"] = 300}, ["core-require"] = {["applies-to"] = "all", module = "eca.nfnl.core", binding = "core"}, ["unused-and-or"] = {["applies-to"] = "all", forms = {"and", "or"}}, ["binding-per-line"] = {["applies-to"] = "all", forms = {"let", "when-let", "if-let", "with-open"}}, ["call-data-arg"] = {["applies-to"] = "source", ["ignore-forms"] = {}}}
local function all_enabled_policy()
  local policy = {}
  for rule, severity in pairs(all_severities) do
    policy[rule] = {severity = severity, options = all_options[rule]}
  end
  return policy
end
local function compatibility_rule_value(rule, severity)
  return ((("table" == type(severity)) and severity) or ((severity == "off") and "off") or {severity = severity, options = all_options[rule]})
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
  local function _4_()
    return lint.check(source, ctx)
  end
  return pcall(_4_)
end
local function policy_for(rules)
  return ((rules and compatibility_policy(rules)) or all_enabled_policy())
end
local function lint_context(path, rules)
  return {path = path, ["spec-files"] = {"^fnl/spec/"}, rules = policy_for(rules), matcher = matcher["vim-matcher"]()}
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
  local context = {path = path, ["spec-files"] = {"^fnl/spec/"}, rules = rules}
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
local function matcher_context(path, rules, exclusions)
  return vim.tbl_extend("force", lint_context(path, rules), {exclusions = exclusions})
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
  local ok, value, err = pcall(check_source_with_matcher_call, lint, source, path, rules, exclusions)
  return check_source_with_matcher_result(ok, value, err)
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
  local function _18_()
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    return source
  end
  ok, result = pcall(_18_)
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
  local counts = {["module-style"] = 0, ["spec-macro-import"] = 0, ["spec-no-module"] = 0, ["spec-direct-require"] = 0, ["one-is-per-testing"] = 0, ["core-require"] = 0}
  local lint_files = {}
  local cli_files = {}
  if lint["module-missing"] then
    return {["module-missing"] = true}
  else
    return collect_repo_findings(lint, counts, lint_files, cli_files, rules)
  end
end
local function _27_()
  local function _28_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)", "fnl/app.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a compliant non-spec module is clean", _28_)
  local function _29_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/legacy.fnl > file", "error"}}
    local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(defn run [] 1)", "fnl/legacy.fnl", {["defn-args-newline"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a non-spec file without a module form has one file finding", _29_)
  local function _30_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/legacy.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(local x 1)", "fnl/legacy.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a non-spec file containing only a local still has one file finding", _30_)
  local function _31_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/legacy.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(if ok a b)", "fnl/legacy.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a non-spec file containing only an if still has one file finding", _31_)
  local function _32_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a module without the aniseed import has one file finding", _32_)
  local function _33_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = forms_for("(import-macros {: module : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)", "fnl/app.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a module-style file missing def in the macro import is reported", _33_)
  local function _34_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(if ok (module app) x)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested module form is reported in a non-spec file", _34_)
  local function _35_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(if ok (import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed) x)\n(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested aniseed import is reported in a non-spec file", _35_)
  local function _36_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n'(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a quoted top-level module form is reported as non-module style", _36_)
  local function _37_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n`(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a quasiquoted top-level module form is reported as non-module style", _37_)
  local function _38_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n,(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an unquoted top-level module form is reported as non-module style", _38_)
  local function _39_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n#(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a hashfn top-level module form is reported as non-module style", _39_)
  local function _40_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("'(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a prefixed aniseed import with a real module is reported as non-module style", _40_)
  local function _41_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(module app)\n;; between top-level forms\n(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)", "fnl/app.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("top-level module and import forms stay clean in either order with comments", _41_)
  local function _42_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/legacy.fnl > file", "error"}}
    local actual_7_auto = forms_for("(fn run [] 1)\n{:run run}", "fnl/legacy.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a legacy fn and final table are reported as non-module style", _42_)
  local function _43_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"works\" (is true)))", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("module-style never applies to spec files", _43_)
end
require("plenary.busted").describe("module-style", _27_)
local function _44_()
  local function _45_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("the approved spec macro import is clean", _45_)
  local function _46_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing} :spec.eca.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec macro import missing is is reported", _46_)
  local function _47_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :other.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec macro import from another module is reported", _47_)
  local function _48_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = forms_for("(deftest run (is true))", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec with no macro import has the spec identity", _48_)
  local function _49_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = findings_for_rule("'(import-macros {: deftest : testing : is} :spec.eca.macros)", "fnl/spec/app_spec.fnl", "spec-macro-import")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a prefixed spec macro import is reported", _49_)
  local function _50_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/x_spec.fnl > spec", "error"}}
    local actual_7_auto = findings_for_rule("(do (import-macros {: deftest : testing : is} :spec.eca.macros))\n(deftest run (testing \"works\" (is true)))", "fnl/spec/x_spec.fnl", "spec-macro-import")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested spec macro import is reported", _50_)
  local function _51_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = forms_for("(import-macros {: deftest} :other) (deftest t (testing \"x\" (is true)))", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a wrong macro import is reported independently of test content", _51_)
  local function _52_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = forms_for("(require :foo)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec with only a direct require still has the spec identity", _52_)
  local function _53_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-no-module", "fnl/spec/app_spec.fnl > module:app", "error"}}
    local actual_7_auto = forms_for("(module app)\n(import-macros {: deftest : testing : is} :spec.eca.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a module form in a spec is reported at that form", _53_)
  local function _54_()
    local function _55_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"spec-direct-require", "fnl/spec/app_spec.fnl > top#1", "error"}}
      local actual_7_auto = findings_for_rule("(require :plenary.busted)", "fnl/spec/app_spec.fnl", "spec-direct-require")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("keyword plenary require is forbidden in ordinary specs", _55_)
    local function _56_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"spec-direct-require", "fnl/spec/app_spec.fnl > top#1", "error"}}
      local actual_7_auto = findings_for_rule("(require \"luassert\")", "fnl/spec/app_spec.fnl", "spec-direct-require")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("string luassert require is forbidden in ordinary specs", _56_)
    local function _57_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(require :plenary.busted)\n(require \"luassert\")", "fnl/spec/eca/macros.fnlm", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("the spec macro implementation may require test libraries directly", _57_)
    local function _58_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module ordinary)\n(require :plenary.busted)\n(require \"luassert\")", "fnl/ordinary.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("direct test-library requires are not a non-spec finding", _58_)
  end
  require("plenary.busted").describe("spec-direct-require", _54_)
  local function _59_()
    local function _60_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"one\" (is true)))", "fnl/spec/app_spec.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("one direct is in testing is clean", _60_)
    local function _61_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"one\" (let [x 1] (is (= x 1)))))", "fnl/spec/app_spec.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("one is inside a let wrapper is clean", _61_)
    local function _62_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"none\" (let [x 1] x)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("testing with no is is reported", _62_)
    local function _63_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"two\" (is true) (is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("testing with two is forms is reported once", _63_)
    local function _64_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"outer\" (testing \"inner\" (is true))))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("nested testing forms are counted separately", _64_)
    local function _65_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"quoted\" '(is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("quoted is data is not counted", _65_)
    local function _66_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" '\n ;; comment\n (is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quoted is separated by a comment is not counted", _66_)
    local function _67_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" `\n(is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quasiquoted is separated by a newline is not counted", _67_)
    local function _68_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" ' (is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quoted is separated by whitespace is not counted", _68_)
    local function _69_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" '(is false) (is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quoted is plus an executable is is counted once", _69_)
    local function _70_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"is in text\" (print \"is\"))) ;; is\n", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("strings and comments containing is are not counted", _70_)
  end
  require("plenary.busted").describe("one-is-per-testing", _59_)
  local function _71_()
    local function _72_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "warning"}}
      local actual_7_auto = findings_for_rule("(defn run [] (if ok (do a b) c))", "fnl/app.fnl", "if-branch-call")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a multi-expression then do is a warning", _72_)
    local function _73_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(defn run [] (if ok (do a) c))", "fnl/app.fnl", "if-branch-call")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a one-expression do is clean", _73_)
    local function _74_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(defn run [] (if ok (let [x 1] x) (set x 1)))", "fnl/app.fnl", "if-branch-call")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("let and set branches are clean", _74_)
    local function _75_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > else", "warning"}, {"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "warning"}}
      local actual_7_auto
      do
        local findings = findings_for_rule("(defn run [] (if ok (do a b) (do c d)))", "fnl/app.fnl", "if-branch-call")
        local function _76_(a, b)
          return (a[2] < b[2])
        end
        table.sort(findings, _76_)
        actual_7_auto = findings
      end
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("both multi-expression branches have distinct identities", _75_)
    local function _77_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "warning"}, {"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then#2", "warning"}}
      local actual_7_auto = findings_for_rule("(defn run [] (if a (do x y) b (do c d) e))", "fnl/app.fnl", "if-branch-call")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("multi-clause then branches use both then identities", _77_)
    local function _78_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(defn run [] (if ok (let [x 1] (do a b)) c))", "fnl/app.fnl", "if-branch-call")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a do nested below a non-do branch root is clean", _78_)
    local function _79_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "error"}}
      local actual_7_auto = findings_for_rule("(defn run [] (if ok (do a b) c))", "fnl/app.fnl", "if-branch-call", {["if-branch-call"] = "error"})
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("if branch severity can be overridden to error", _79_)
    local function _80_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = findings_for_rule("(defn run [] (if ok (do a b) c))", "fnl/app.fnl", "if-branch-call", {["if-branch-call"] = "off"})
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("if branch rule can be disabled", _80_)
    local function _81_()
      local function _82_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {}
        local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(local core (require :eca.nfnl.core))", "fnl/app.fnl", nil)
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("the core local binding uses the canonical name", _82_)
      local function _83_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"core-require", "fnl/app.fnl > local:core", "error"}}
        local actual_7_auto = findings_for_rule("(local core (require :eca.nfnl.core) other)", "fnl/app.fnl", "core-require")
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("a core local with extra expressions is reported", _83_)
      local function _84_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {}
        local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(local core (require \"eca.nfnl.core\"))", "fnl/app.fnl", nil)
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("a string core local binding uses the canonical shape", _84_)
      local function _85_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"core-require", "fnl/app.fnl > local:c", "error"}}
        local actual_7_auto = findings_for_rule("(local c (require :eca.nfnl.core))", "fnl/app.fnl", "core-require")
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("a non-core local binding is reported", _85_)
      local function _86_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"core-require", "fnl/app.fnl > top#1", "error"}}
        local actual_7_auto = findings_for_rule("(require :eca.nfnl.core extra)", "fnl/app.fnl", "core-require")
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("a keyword core require with extra expressions is reported", _86_)
      local function _87_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"core-require", "fnl/app.fnl > top#1", "error"}}
        local actual_7_auto = findings_for_rule("(require \"eca.nfnl.core\" extra)", "fnl/app.fnl", "core-require")
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      return require("plenary.busted").it("a string core require with extra expressions is reported", _87_)
    end
    require("plenary.busted").describe("core-require", _81_)
    local function _88_()
      local function _89_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "warning"}, {"if-branch-call", "fnl/app.fnl > defn:run > if#1 > else", "warning"}}
        local actual_7_auto = findings_for_rule("(defn run [] (if ok (do a b) (do c d)))", "fnl/app.fnl", "if-branch-call", {["module-style"] = "off"})
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("the same source produces identical sorted findings", _89_)
      local function _90_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {findings = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "warning"}, {"if-branch-call", "fnl/app.fnl > defn:run > if#1 > else", "warning"}}, duplicates = {}}
        local actual_7_auto
        do
          local findings = findings_for_rule("(defn run [] (if ok (do a b) (do c d)))", "fnl/app.fnl", "if-branch-call", {["module-style"] = "off"})
          local seen = {}
          local duplicates = {}
          for _, value in ipairs(findings) do
            local key = (value[1] .. "|" .. value[2])
            if seen[key] then
              table.insert(duplicates, key)
            else
              seen[key] = true
            end
          end
          actual_7_auto = {findings = findings, duplicates = duplicates}
        end
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("no two findings share path rule and form", _90_)
      local function _92_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"core-require", "fnl/app.fnl > top#1", "error"}}
        local actual_7_auto = findings_for_rule("(require :eca.nfnl.core extra)\n(vim.api.nvim_set_option_value :x 1 {})", "fnl/app.fnl", "core-require")
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("the pure core returns findings without executing vim api text", _92_)
      local function _93_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {["value-nil?"] = true, message = "missing closing delimiter", line = 1, col = 1}
        local actual_7_auto = check_source("(unclosed", "fnl/bad.fnl", nil)
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      return require("plenary.busted").it("reader failure returns nil and a structured error table", _93_)
    end
    return require("plenary.busted").describe("determinism-and-boundary", _88_)
  end
  return require("plenary.busted").describe("if-branch-call", _71_)
end
require("plenary.busted").describe("spec-shape", _44_)
local function function_findings(source)
  return findings_for_rule(source, "fnl/app.fnl", "function-shape", {["module-style"] = "off"})
end
local function _94_()
  local function _95_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [x] (set x (if x 1 2)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested if in a set value reports the outer set form", _95_)
  local function _96_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (do a b))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a multi-expression do body reports the outer do form", _96_)
  local function _97_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (foo (fn [] a) (do a b)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("nested function and do forms report one outer offending form", _97_)
  local function _98_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"function-shape", "fnl/app.fnl > defn:f > sequence#1", "warning"}}
    local actual_7_auto = function_findings("(defn f [] [1 (if a b c)])")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested if in a sequence reports the sequence form", _98_)
  local function _99_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"function-shape", "fnl/app.fnl > defn:f > table#1", "warning"}}
    local actual_7_auto = function_findings("(defn f [] {:k (if a b c)})")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested if in a table reports the table form", _99_)
  local function _100_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (local y (let [z 1] z)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested let in a local value reports the outer local form", _100_)
  local function _101_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn f [x] (set x (g x)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a set with a leaf call value is clean", _101_)
  local function _102_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn f [] [1 (g a)])")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a sequence with a leaf call is clean", _102_)
  local function _103_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn f [] {:k (g a)})")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a table with a leaf call is clean", _103_)
  local function _104_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn f [] '(if a b c))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("quoted control forms are clean", _104_)
  local function _105_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"function-shape", "fnl/app.fnl > defn-:join > if#1 > else > if#1", "warning"}}
    local actual_7_auto = function_findings("(defn- join [xs]\n  (if (= xs [])\n      nil\n      (if (= (length xs) 1)\n          (first xs)\n          (table.concat (icollect [_ x (ipairs xs)] x) \" \"))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("the user's nested inner if is the single function-shape finding", _105_)
  local function _106_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn- join-parts [xs]\n  (table.concat (icollect [_ x (ipairs xs)] x) \" \"))\n(defn- join [xs]\n  (if (= xs [])\n      nil\n      (join-parts xs)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("the fixed join form is clean", _106_)
  local function _107_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [xs]\n  (let [parts (icollect [_ x (ipairs xs)] x)]\n    (table.concat parts \" \")))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a comprehension in the first let binding is reported", _107_)
  local function _108_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [xs] (if ok (icollect [_ x (ipairs xs)] x) nil))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a comprehension used as an if branch is reported", _108_)
  local function _109_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [xs] (when ok (icollect [_ x (ipairs xs)] x)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a comprehension used as a when body is reported", _109_)
  local function _110_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn f [xs] (icollect [_ x (ipairs xs)] x))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a direct comprehension body with a leaf body is clean", _110_)
  local function _111_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run []\n  (foo (fn [] (if a b c))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a function argument with an if body is reported", _111_)
  local function _112_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run []\n  (foo (fn [] (do a b))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a function argument with a do body is reported", _112_)
  local function _113_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [xs]\n  (foo (each [_ x (ipairs xs)] (when x (bar)))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a loop argument with a when body is reported", _113_)
  local function _114_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [xs]\n  (foo (fn [] a) (icollect [_ x (ipairs xs)] x)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a function argument and comprehension argument with leaf bodies are clean", _114_)
  local function _115_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [x]\n  (let [a x b 1]\n    (+ a b)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a first let with leaf bindings and body is clean", _115_)
  local function _116_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [x]\n  (let [a (if x 1 2)] a))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an if in a let binding value is reported", _116_)
  local function _117_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [x]\n  x\n  (let [a 1] a))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a let after the first body expression is reported", _117_)
  local function _118_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [x]\n  (let [a x]\n    (let [b a] b)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a second nested let is reported", _118_)
  local function _119_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn- f [] (while true (let [x (if a b c)] x)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested if in a while binding is reported", _119_)
  local function _120_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn- f [] (while true (do (if a b c) x)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested if in a while do body is reported", _120_)
  local function _121_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn- f [] (do x))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a single-expression do body is reported", _121_)
  local function _122_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn- f [] (if a (let [y 1] y) b))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a let inside an if branch is reported", _122_)
  local function _123_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn- f [] (each [_ v (ipairs xs)] (when v (print v))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested when in a loop body is reported", _123_)
  local function _124_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn- f [] (foo (fn [] a) (fn [] b)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("sibling callback layers are clean", _124_)
  local function _125_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (foo (bar (fn [] a))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a function nested in a call argument is reported", _125_)
  local function _126_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (let [x (foo (fn [] a))] x))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a function nested in a let binding call is reported", _126_)
  local function _127_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [xs] (foo (bar (icollect [_ x (ipairs xs)] x))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a comprehension nested in a call argument is reported", _127_)
  local function _128_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (if ok (foo (fn [] a)) nil))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a call with a function in an if branch is reported", _128_)
  local function _129_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [x]\n  (if x 1 y 2 3))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a multi-clause flat if is clean", _129_)
  local function _130_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [x]\n  (case x 1 :one 2 :two :other))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a case with leaf clauses is clean", _130_)
  local function _131_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [x]\n  (case x 1 (if x :one :other) :other))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested if in a case clause is reported", _131_)
  local function _132_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [x]\n  (match x 1 :one 2 :two :other))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a match with leaf clauses is clean", _132_)
  local function _133_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [x]\n  (match x 1 (if x :one :other) _ :other))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested if in a match clause is reported", _133_)
  local function _134_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [x]\n  (when x (print x) (print :done)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a when with several leaf steps is clean", _134_)
  local function _135_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [xs]\n  (each [_ x (ipairs xs)] (print x)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a loop with a leaf body is clean", _135_)
  local function _136_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [xs]\n  (each [_ x (ipairs xs)] (if x (print x) (print :none))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a loop with an if in its body is reported", _136_)
  local function _137_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [] (pcall (fn [] (leaf))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a function literal passed to pcall is clean", _137_)
  local function _138_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [xs]\n  (table.concat (icollect [_ x (ipairs xs)] (f x)) \" \"))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an icollect passed to table.concat is clean", _138_)
  local function _139_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [] (fn [] (if ok (if nested a b) c)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an anonymous function body is checked independently", _139_)
  local function _140_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [] (lambda [] (if ok (if nested a b) c)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a lambda body is checked independently", _140_)
  local function _141_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [] (\206\187 [] (if ok (if nested a b) c)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a unicode lambda body is checked independently", _141_)
  local function _142_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (fn [] (if a b c)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a body-level fn with a non-leaf if body is reported", _142_)
  local function _143_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (lambda [] (if a b c)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a body-level lambda with a non-leaf if body is reported", _143_)
  local function _144_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (\206\187 [] (if a b c)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a body-level unicode lambda with a non-leaf if body is reported", _144_)
  local function _145_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(fn named [] (if a (let [x 1] x) b))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a top-level fn body with a non-leaf if is reported", _145_)
  local function _146_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(local f (fn [] (each [_ x (ipairs xs)] (when x (g x)))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a local fn with a nested loop body is reported", _146_)
  local function _147_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(local f (lambda [] (if a (let [x 1] x) b)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a local lambda body with a non-leaf if is reported", _147_)
  local function _148_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(local f (\206\187 [] (if a (let [x 1] x) b)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a local unicode lambda body with a non-leaf if is reported", _148_)
  local function _149_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(foo (fn [] (if a (let [x 1] x) b)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a top-level callback fn body with a non-leaf if is reported", _149_)
  local function _150_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(local f (fn [] (if a b c)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a local fn with a single if and leaf branches is clean", _150_)
  local function _151_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn g [] (fn h [] (if a (let [x 1] x) b)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested fn violation is deduplicated under its defn", _151_)
  local function _152_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn g [] (fn h [] (if a b c)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a valid nested fn still makes its defn body report once", _152_)
  local function _153_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn f [] (fn [] (g a)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a body-level fn with a leaf call body is clean", _153_)
  local function _154_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [x]\n  (while x (set x false)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a while with a leaf body is clean", _154_)
  local function _155_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [x]\n  (print x)\n  (+ x 1)\n  x)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("several leaf body expressions are clean", _155_)
  local function _156_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [] '(if x (let [a 1] a) b))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("quoted data is never flagged", _156_)
  local function _157_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"function-shape", "fnl/app.fnl > defn:run > if#1 > then > if#1", "warning"}}
    local actual_7_auto = function_findings("(defn run [] (if x (if y a b) c))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("function-shape defaults to warning", _157_)
  local function _158_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "function body is too deep; move this into a named private function"
    local actual_7_auto = finding_summary(check_source("(defn run [] (if x (if y a b) c))", "fnl/app.fnl", {["module-style"] = "off"}))[1].message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("function-shape uses the approved move-to-private-function message", _158_)
  local function _159_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"function-shape", "fnl/app.fnl > defn:run > if#1 > then > if#1", "error"}}
    local actual_7_auto = findings_for_rule("(defn run [] (if x (if y a b) c))", "fnl/app.fnl", "function-shape", {["module-style"] = "off", ["function-shape"] = "error"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("function-shape severity can be overridden to error", _159_)
  local function _160_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = findings_for_rule("(defn run [] (if x (if y a b) c))", "fnl/app.fnl", "function-shape", {["module-style"] = "off", ["function-shape"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("function-shape can be disabled", _160_)
  local function _161_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"function-shape", "fnl/app.fnl > defn:run > if#1 > then > if#1", "warning"}, {"function-shape", "fnl/app.fnl > defn:run > if#1 > else > if#1", "warning"}}
    local actual_7_auto = function_findings("(defn run []\n  (if x (if y a b) (if z c d)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("function-shape findings are unique and deterministic", _161_)
end
require("plenary.busted").describe("function-shape", _94_)
local function _162_()
  local function _163_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["module-style"] = 24, ["spec-macro-import"] = 0, ["spec-no-module"] = 0, ["spec-direct-require"] = 0, ["one-is-per-testing"] = 0, ["core-require"] = 0}
    local actual_7_auto = repo_scenario({["file-size"] = "off"}).counts
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("project Fennel files have the approved rule counts", _163_)
  local function _164_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_scenario(nil)["lint-files"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("lint implementation files are clean", _164_)
  local function _165_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_scenario(nil)["cli-files"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("cli implementation files are clean", _165_)
end
require("plenary.busted").describe("lint-repo-properties", _162_)
local function context_base(ctx)
  return ((ctx.rules and vim.tbl_extend("force", ctx, {rules = compatibility_policy(ctx.rules)})) or ctx)
end
local function context_for_check(ctx)
  return vim.tbl_extend("force", {["spec-files"] = {"^fnl/spec/"}}, context_base(ctx))
end
local function check_context_result(findings, err)
  if findings then
    return findings
  else
    return {["value-nil?"] = true, error = err}
  end
end
local function check_context_loaded(lint, source, ctx)
  local context = vim.tbl_extend("force", context_for_check(ctx), {matcher = matcher["vim-matcher"]()})
  local findings, err = lint.check(source, context)
  return check_context_result(findings, err)
end
local function check_context(source, ctx)
  local lint = load_lint()
  if lint["module-missing"] then
    return lint
  else
    return check_context_loaded(lint, source, ctx)
  end
end
local function _168_()
  local function _169_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = check_context("(local c (require :eca.nfnl.core))", {path = "fnl/app.fnl"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("lint check reports no findings when rules are omitted", _169_)
  local function _170_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 17
    local actual_7_auto = policy_size(all_enabled_policy())
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("the shared compatibility policy enables all approved rules", _170_)
end
require("plenary.busted").describe("opt-in-policy", _168_)
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
local function _172_()
  local source = "(defn run [] (if ok (do a b) c))"
  local path = "fnl/app.fnl"
  local rules = {["module-style"] = "off", ["function-shape"] = "off", ["defn-args-newline"] = "off", ["control-layout"] = "off"}
  local baseline = check_context(source, {path = path, rules = rules})
  local form = first_finding_form(baseline, "if-branch-call")
  local function _173_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = check_context(source, {path = path, rules = rules, exclusions = {{rule = "if-branch-call", form = form, reason = "intentional"}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an exclusion suppresses only an exact rule and form match", _173_)
  local function _174_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"if-branch-call"}
    local actual_7_auto
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, finding in ipairs(check_context(source, {path = path, rules = rules, exclusions = {{rule = "core-require", form = form, reason = "intentional"}}})) do
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
  require("plenary.busted").it("an exclusion with the same form but a different rule does not suppress", _174_)
  local function _176_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"if-branch-call"}
    local actual_7_auto
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, finding in ipairs(check_context(source, {path = path, rules = rules, exclusions = {{rule = "if-branch-call", form = (form .. " > other"), reason = "intentional"}}})) do
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
  return require("plenary.busted").it("an exclusion with the same rule but a different form does not suppress", _176_)
end
require("plenary.busted").describe("exclusions", _172_)
local function _178_()
  local source = "(defn run []\n  (if ok\n      (do\n        a\n        foo)\n      c))"
  local result = check_source_with_matcher(source, "fnl/app.fnl", {["module-style"] = "off", ["function-shape"] = "off", ["defn-args-newline"] = "off", ["control-layout"] = "off"}, {{rule = "if-branch-call", code = "foo", reason = "intentional"}})
  local assert_5_auto = require("luassert")
  local expected_6_auto = {}
  local actual_7_auto = finding_identities(result)
  assert_5_auto.same(expected_6_auto, actual_7_auto)
  return true
end
require("plenary.busted").it("a code exclusion matches text on an interior line of a multiline flagged branch", _178_)
local function _179_()
  local function _180_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = check_context("(if ok (do a b) c)", {path = "fnl/app.fnl", rules = {["module-style"] = "off"}, exclusions = {{rule = "if-branch-call", form = "fnl/app.fnl > top#1 > if#1 > then", reason = "intentional"}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("direct lint check suppresses a top-level branch using the printed normalized identity", _180_)
  local function _181_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = check_context("(testing \"two\" (is true) (is true))", {path = "fnl/spec/app_spec.fnl", rules = {["module-style"] = "off", ["spec-macro-import"] = "off"}, exclusions = {{rule = "one-is-per-testing", form = "fnl/spec/app_spec.fnl > top#1 > testing#1", reason = "intentional"}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("direct lint check suppresses top-level testing using the printed normalized identity", _181_)
end
require("plenary.busted").describe("normalized-exclusion-identities", _179_)
local function no_mutation_summary(source, path, rules)
  local result = findings_for_rule(source, path, "no-mutation", rules)
  if (result["module-missing"] or result["value-nil?"]) then
    return result
  else
    local _182_
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
      _182_ = tbl_26_
    end
    local _184_
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
      _184_ = tbl_26_
    end
    return {count = #result, rules = _182_, severities = _184_}
  end
end
local function no_mutation_forms(source, path, rules)
  local result = check_source(source, path, rules)
  if (result["module-missing"] or result["value-nil?"]) then
    return result
  else
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding in ipairs(result) do
      local val_28_
      if (finding.rule == "no-mutation") then
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
local function _190_()
  local function _191_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 1, rules = {"no-mutation"}, severities = {"warning"}}
    local actual_7_auto = no_mutation_summary("(var x 1)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags var in a source file as one warning", _191_)
  local function _192_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 1, rules = {"no-mutation"}, severities = {"warning"}}
    local actual_7_auto = no_mutation_summary("(set x 2)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags set in a source file as one warning", _192_)
  local function _193_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 1, rules = {"no-mutation"}, severities = {"warning"}}
    local actual_7_auto = no_mutation_summary("(set state.x 2)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a field set in a source file as one warning", _193_)
  local function _194_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 1, rules = {"no-mutation"}, severities = {"warning"}}
    local actual_7_auto = no_mutation_summary("(while ok (g))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags while in a source file as one warning", _194_)
  local function _195_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 2, rules = {"no-mutation", "no-mutation"}, severities = {"warning", "warning"}}
    local actual_7_auto = no_mutation_summary("(while ok (set x 1))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags every mutation form in a nested while and set", _195_)
  local function _196_()
    local forms = no_mutation_forms("(defn f [] (let [a (set x 1)] (set y 2)))", "fnl/app.fnl", {["module-style"] = "off"})
    local assert_28_auto = require("luassert")
    local value_29_auto = ((2 == #forms) and (forms[1] ~= forms[2]))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (length forms)) (not= (. forms 1) (. forms 2)))")
    return true
  end
  require("plenary.busted").it("gives nested mutation findings distinct form identities", _196_)
  local function _197_()
    local source = "(defn f [] (let [a (set x 1)] (set y 2)))"
    local first_forms = no_mutation_forms(source, "fnl/app.fnl", {["module-style"] = "off"})
    local second_forms = no_mutation_forms(source, "fnl/app.fnl", {["module-style"] = "off"})
    local assert_5_auto = require("luassert")
    local expected_6_auto = first_forms
    local actual_7_auto = second_forms
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("keeps nested mutation form identities stable across repeated linting", _197_)
  local function _198_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #no_mutation_forms("(macro m [] `(foo ,(set x 1)))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("lints mutation in unquoted quasiquote code", _198_)
  local function _199_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #no_mutation_forms("`(set x ,y)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not lint mutation in quasiquoted data", _199_)
  local function _200_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = no_mutation_summary("(defn f [] `(outer ,(set x 1) `(set y ,(set z 2))))", "fnl/app.fnl", {["module-style"] = "off"}).count
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("lints only the outer unquote in nested quasiquote data", _200_)
  local function _201_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = no_mutation_summary("(defn f [] `(a `(b ,,(set x 1))))", "fnl/app.fnl", {["module-style"] = "off"}).count
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("lints a double-unquoted mutation at executable depth", _201_)
  local function _202_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = no_mutation_summary("(defn f [] '(foo ,(set x 1)))", "fnl/app.fnl", {["module-style"] = "off"}).count
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not lint mutation inside plain quote", _202_)
  local function _203_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 0, rules = {}, severities = {}}
    local actual_7_auto = no_mutation_summary("(var x 1) (set x 2) (while ok (g))", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not flag mutations in a spec file", _203_)
  local function _204_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 0, rules = {}, severities = {}}
    local actual_7_auto = no_mutation_summary("(local x 1) (tset t :k v) (table.insert xs 1) '(set x 1) (set-foo 1)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not flag non-mutation forms or quoted mutation data", _204_)
  local function _205_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 1, rules = {"no-mutation"}, severities = {"error"}}
    local actual_7_auto = no_mutation_summary("(var x 1)", "fnl/app.fnl", {["module-style"] = "off", ["no-mutation"] = "error"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses error severity when configured", _205_)
  local function _206_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 0, rules = {}, severities = {}}
    local actual_7_auto = no_mutation_summary("(var x 1)", "fnl/app.fnl", {["module-style"] = "off", ["no-mutation"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not report when disabled", _206_)
  local function _207_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "avoid mutation (var/set/while); prefer a functional form"
    local actual_7_auto = finding_summary(check_source("(var x 1)", "fnl/app.fnl", {["module-style"] = "off"}))[1].message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("uses the suggested message", _207_)
end
require("plenary.busted").describe("no-mutation", _190_)
local function if_without_else_findings(source, path, rules)
  local result = check_source(source, path, rules)
  if (result["module-missing"] or result["value-nil?"]) then
    return result
  else
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding in ipairs(result) do
      local val_28_
      if (finding.rule == "if-without-else") then
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
local function _211_()
  local function _212_()
    local findings = if_without_else_findings("(defn f [] (if a b))", "fnl/app.fnl", {["module-style"] = "off"})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {rule = "if-without-else", severity = "warning", message = "if without else; use when"}
    local actual_7_auto = {rule = findings[1].rule, severity = findings[1].severity, message = findings[1].message}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a two-argument if with the default warning and message", _212_)
  local function _213_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #if_without_else_findings("(if a b c) (if a b c d e) (when a b)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not flag complete or multi-clause if forms or when", _213_)
  local function _214_()
    local finding = if_without_else_findings("(defn f\n  [ok resolved]\n  (if ok\n    resolved\n    nil))", "fnl/app.fnl", {["module-style"] = "off"})[1]
    local assert_5_auto = require("luassert")
    local expected_6_auto = {rule = "if-without-else", severity = "warning", message = "if without else; use when"}
    local actual_7_auto = {rule = finding.rule, severity = finding.severity, message = finding.message}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a single-clause if whose else branch is literal nil", _214_)
  local function _215_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #if_without_else_findings("(if a b c)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not flag a single-clause if with a non-nil else branch", _215_)
  local function _216_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #if_without_else_findings("(if a b c nil)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not flag a multi-clause if ending in literal nil", _216_)
  local function _217_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #if_without_else_findings("(if a nil b)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not flag an if with a literal nil then branch", _217_)
  local function _218_()
    local source = "(defn f [] (do (if x y) (if x y)))"
    local rules = {["module-style"] = "off"}
    local first = if_without_else_findings(source, "fnl/app.fnl", rules)
    local second = if_without_else_findings(source, "fnl/app.fnl", rules)
    local assert_28_auto = require("luassert")
    local value_29_auto
    local and_219_ = (2 == #first) and (first[1].form ~= first[2].form)
    if and_219_ then
      local _220_
      do
        local tbl_26_ = {}
        local i_27_ = 0
        for _, finding in ipairs(first) do
          local val_28_ = finding.form
          if (nil ~= val_28_) then
            i_27_ = (i_27_ + 1)
            tbl_26_[i_27_] = val_28_
          else
          end
        end
        _220_ = tbl_26_
      end
      local function _222_()
        local tbl_26_ = {}
        local i_27_ = 0
        for _, finding in ipairs(second) do
          local val_28_ = finding.form
          if (nil ~= val_28_) then
            i_27_ = (i_27_ + 1)
            tbl_26_[i_27_] = val_28_
          else
          end
        end
        return tbl_26_
      end
      and_219_ = vim.deep_equal(_220_, _222_())
    end
    value_29_auto = and_219_
    assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (length first)) (not= (. first 1 \"form\") (. first 2 \"form\")) (vim.deep_equal (icollect [_ finding (ipairs first)] (. finding \"form\")) (icollect [_ finding (ipairs second)] (. finding \"form\"))))")
    return true
  end
  require("plenary.busted").it("flags two nested if forms with distinct stable identities", _218_)
  local function _224_()
    local source = "(defn f [] (do (if x y) (if x y)))"
    local path = "fnl/app.fnl"
    local rules = {["module-style"] = "off"}
    local baseline = if_without_else_findings(source, path, rules)
    local form = baseline[1].form
    local result = check_context(source, {path = path, rules = rules, exclusions = {{rule = "if-without-else", form = form, reason = "intentional"}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto
    local _225_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, finding in ipairs(result) do
        local val_28_
        if (finding.rule == "if-without-else") then
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
      _225_ = tbl_26_
    end
    actual_7_auto = #_225_
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an exclusion for one nested if leaves the other finding", _224_)
  local function _228_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #if_without_else_findings("(if a b)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("applies to spec files", _228_)
  local function _229_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #if_without_else_findings("'(if a b) `(if a ,(if b c))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("ignores quoted if data and flags only executable unquoted quasiquote code", _229_)
  local function _230_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "error"
    local actual_7_auto = if_without_else_findings("(if a b)", "fnl/app.fnl", {["module-style"] = "off", ["if-without-else"] = "error"})[1].severity
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses error severity when configured", _230_)
  local function _231_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #if_without_else_findings("(if a b)", "fnl/app.fnl", {["module-style"] = "off", ["if-without-else"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("does not report when disabled", _231_)
end
require("plenary.busted").describe("if-without-else", _211_)
local function defn_args_newline_findings(source, path, rules)
  local result = check_source(source, path, rules)
  if (result["module-missing"] or result["value-nil?"]) then
    return result
  else
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding in ipairs(result) do
      local val_28_
      if (finding.rule == "defn-args-newline") then
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
local function _235_()
  local function _236_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #defn_args_newline_findings("(defn f [a]\n  a)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a defn whose argument vector starts on the name line", _236_)
  local function _237_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #defn_args_newline_findings("(defn- f [a] a)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a defn- whose argument vector starts on the name line", _237_)
  local function _238_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #defn_args_newline_findings("(defn f\n  [a]\n  a)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a defn with the argument vector on the line below the name", _238_)
  local function _239_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #defn_args_newline_findings("(defn- f\n  [a]\n  a)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a defn- with the argument vector on the line below the name", _239_)
  local function _240_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #defn_args_newline_findings("(defn f [] 1)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a one-line defn because the layout is always required", _240_)
  local function _241_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #defn_args_newline_findings("(defn f \"doc\" [a]\n  a)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("requires a docstring followed by arguments to start on a later line", _241_)
  local function _242_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #defn_args_newline_findings("(defn f \"doc\"\n  [a]\n  a)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a docstring on the name line when arguments start below it", _242_)
  local function _243_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #defn_args_newline_findings("(defn f\n  \"doc\"\n  [a]\n  a)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a docstring on its own line before arguments", _243_)
  local function _244_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #defn_args_newline_findings("(fn f [a] a) (lambda f [a] a) (macro f [a] a) (def f [a])", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not flag fn lambda macro or def forms", _244_)
  local function _245_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #defn_args_newline_findings("(defn f [a] a) '(defn f [a] a)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("applies to spec files and ignores quoted data", _245_)
  local function _246_()
    local finding = defn_args_newline_findings("(defn f [a]\n  a)", "fnl/app.fnl", {["module-style"] = "off"})[1]
    local assert_5_auto = require("luassert")
    local expected_6_auto = {form = "fnl/app.fnl > defn:f", severity = "warning", message = "put the defn argument vector on the line below the name"}
    local actual_7_auto = {form = finding.form, severity = finding.severity, message = finding.message}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses the stable defn identity and prescribed warning message", _246_)
  local function _247_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "error"
    local actual_7_auto = defn_args_newline_findings("(defn f [a] 1)", "fnl/app.fnl", {["module-style"] = "off", ["defn-args-newline"] = "error"})[1].severity
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses error severity when configured", _247_)
  local function _248_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #defn_args_newline_findings("(defn f [a] 1)", "fnl/app.fnl", {["module-style"] = "off", ["defn-args-newline"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not report when disabled", _248_)
  local function _249_()
    local source = "(defn f [a] a)\n(defn g [b] b)"
    local path = "fnl/app.fnl"
    local rules = {["module-style"] = "off"}
    local baseline = defn_args_newline_findings(source, path, rules)
    local result = check_context(source, {path = path, rules = rules, exclusions = {{rule = "defn-args-newline", form = baseline[1].form, reason = "intentional"}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto
    local _250_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, finding in ipairs(result) do
        local val_28_
        if (finding.rule == "defn-args-newline") then
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
      _250_ = tbl_26_
    end
    actual_7_auto = #_250_
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an exclusion removes only the selected defn finding", _249_)
  local function _253_()
    local result = check_source("(defn f [a]\n  (foo a b\n    c))", "fnl/app.fnl", {["module-style"] = "off"})
    local rules
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
      rules = tbl_26_
    end
    local assert_28_auto = require("luassert")
    local value_29_auto = ((2 == #rules) and vim.deep_equal({true, true}, {vim.tbl_contains(rules, "defn-args-newline"), vim.tbl_contains(rules, "multiline-layout")}))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (length rules)) (vim.deep_equal [true true] [(vim.tbl_contains rules \"defn-args-newline\")\n (vim.tbl_contains rules \"multiline-layout\")]))")
    return true
  end
  return require("plenary.busted").it("reports one finding across defn args and multiline layout", _253_)
end
require("plenary.busted").describe("defn-args-newline", _235_)
local function multiline_layout_findings(source, path, rules)
  local result = check_source(source, path, rules)
  if (result["module-missing"] or result["value-nil?"]) then
    return result
  else
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding in ipairs(result) do
      local val_28_
      if (finding.rule == "multiline-layout") then
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
local function _258_()
  local function _259_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #multiline_layout_findings("(defn f\n  [file]\n  (if\n    file\n    (read file)\n    \"\"))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("requires an if test on the head line", _259_)
  local function _260_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #multiline_layout_findings("(defn f\n  [file]\n  (if file\n    (read file)\n    \"\"))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an if test on the head line", _260_)
  local function _261_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #multiline_layout_findings("(defn f\n  [file]\n  (and\n    file\n    (close file)))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("requires an and argument on the head line", _261_)
  local function _262_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #multiline_layout_findings("(defn f\n  [file]\n  (and file\n    (close file)))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts an and argument on the head line", _262_)
  local function _263_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #multiline_layout_findings("(foo\n  a\n  b)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("requires a plain call argument on the head line", _263_)
  local function _264_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #multiline_layout_findings("(foo a\n     b)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a plain call argument on the head line", _264_)
  local function _265_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #multiline_layout_findings("(let\n  [x 1]\n  x)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("requires a let binding vector on the head line", _265_)
  local function _266_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #multiline_layout_findings("(do\n  (a)\n  (b))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not require a do body on the head line", _266_)
  local function _267_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #multiline_layout_findings("(defn f\n  [a]\n  a)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not require a defn name on the next line", _267_)
  local function _268_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #multiline_layout_findings("(if\n  (> i n) false\n  (= p x) true\n  (rec))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("requires a multi-clause if test on the head line", _268_)
  local function _269_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #multiline_layout_findings("(foo a b\n  c)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a list with two items starting on one line", _269_)
  local function _270_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #multiline_layout_findings("(foo a\n  b\n  c)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a list with one item starting on each line", _270_)
  local function _271_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #multiline_layout_findings("(foo a b c)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a one-line list", _271_)
  local function _272_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #multiline_layout_findings("(\n foo a b)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a list whose head starts below its opening paren", _272_)
  local function _273_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #multiline_layout_findings("(defn f\n  []\n  (\n   foo a b))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a list with a delayed head inside a defn", _273_)
  local function _274_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = (#multiline_layout_findings("[\n 1\n 2]", "fnl/app.fnl", {["module-style"] = "off"}) + #multiline_layout_findings("{\n :a 1}", "fnl/app.fnl", {["module-style"] = "off"}))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not flag vectors or maps whose first item starts below the opener", _274_)
  local function _275_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #multiline_layout_findings("(defn f\n  [n]\n  (if (> n 0) 1\n    0))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a single-clause if whose then branch shares the head line", _275_)
  local function _276_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #multiline_layout_findings("(defn f\n  [n]\n  (if (> n 0)\n    1\n    0))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a single-clause if with each branch on its own line", _276_)
  local function _277_()
    local findings = check_source("(defn f\n  [n]\n  (if (> n 0) 1\n    0))", "fnl/app.fnl", {["module-style"] = "off"})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"multiline-layout"}
    local actual_7_auto
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, finding in ipairs(findings) do
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
  require("plenary.busted").it("reports only multiline-layout for a malformed multi-line control form", _277_)
  local function _279_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #multiline_layout_findings("{:a 1 :b 2\n :c 3}", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a multi-line map with two pairs on one line", _279_)
  local function _280_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #multiline_layout_findings("{:a 1\n :b 2\n :c 3}", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a map with one pair starting on each line", _280_)
  local function _281_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #multiline_layout_findings("{:a\n  (long-value)\n :b 2}", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a map whose value starts on the next line", _281_)
  local function _282_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #multiline_layout_findings("[a b\n c]", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a vector with two elements starting on one line", _282_)
  local function _283_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #multiline_layout_findings("(foo a ; b\n  \"c\nd\"\n  e)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts comments and multi-line strings between items", _283_)
  local function _284_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #multiline_layout_findings("(let [a 1 b 2\n      c 3]\n  a)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a let binding vector with two bindings on one line", _284_)
  local function _285_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #multiline_layout_findings("(let [a 1\n      b 2]\n  a)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a let binding vector with one binding on each line", _285_)
  local function _286_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #multiline_layout_findings("(case x\n  1 :a 2 :b\n  _ :c)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a case with two clauses starting on one line", _286_)
  local function _287_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #multiline_layout_findings("(if (> i n) false\n  (= p x) true\n  (rec))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a multi-clause if with one pair on each line", _287_)
  local function _288_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #multiline_layout_findings("(foo (bar\n       x) y)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a unit that starts where the previous unit ends", _288_)
  local function _289_()
    local findings = multiline_layout_findings("(defn f [a] (foo a b\n  c))", "fnl/app.fnl", {["module-style"] = "off"})
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #findings
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("reports one finding for the inner call in a defn body", _289_)
  local function _290_()
    local findings = multiline_layout_findings("(defn f [] (foo a b\n  (bar x y\n    z)))", "fnl/app.fnl", {["module-style"] = "off"})
    local assert_28_auto = require("luassert")
    local value_29_auto = ((2 == #findings) and (findings[1].form ~= findings[2].form))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (length findings)) (not= (. findings 1 \"form\") (. findings 2 \"form\")))")
    return true
  end
  require("plenary.busted").it("reports one finding per nested offending form with distinct identities", _290_)
  local function _291_()
    local source = "(defn f [] (foo a b\n  (bar x y\n    z)))"
    local path = "fnl/app.fnl"
    local rules = {["module-style"] = "off"}
    local baseline = multiline_layout_findings(source, path, rules)
    local excluded = baseline[1].form
    local result = check_context(source, {path = path, rules = rules, exclusions = {{rule = "multiline-layout", form = excluded, reason = "intentional"}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto
    local _292_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, finding in ipairs(result) do
        local val_28_
        if (finding.rule == "multiline-layout") then
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
      _292_ = tbl_26_
    end
    actual_7_auto = #_292_
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an exclusion for one nested form leaves the other finding", _291_)
  local function _295_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #multiline_layout_findings("(foo a b\n  c)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("applies to spec files", _295_)
  local function _296_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #multiline_layout_findings("'(a b\n c)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("ignores quoted multi-line lists", _296_)
  local function _297_()
    local finding = multiline_layout_findings("(foo a b\n  c)", "fnl/app.fnl", {["module-style"] = "off"})[1]
    local assert_5_auto = require("luassert")
    local expected_6_auto = {severity = "warning", message = "multi-line form: put each item on its own line"}
    local actual_7_auto = {severity = finding.severity, message = finding.message}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses the default warning and prescribed message", _297_)
  local function _298_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "error"
    local actual_7_auto = multiline_layout_findings("(foo a b\n  c)", "fnl/app.fnl", {["module-style"] = "off", ["multiline-layout"] = "error"})[1].severity
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses error severity when configured", _298_)
  local function _299_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #multiline_layout_findings("(foo a b\n  c)", "fnl/app.fnl", {["module-style"] = "off", ["multiline-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("does not report when disabled", _299_)
end
require("plenary.busted").describe("multiline-layout", _258_)
local function control_layout_findings(source, path, rules)
  local result = check_source(source, path, rules)
  if (result["module-missing"] or result["value-nil?"]) then
    return result
  else
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding in ipairs(result) do
      local val_28_
      if (finding.rule == "control-layout") then
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
local function _303_()
  local function _304_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #control_layout_findings("(defn f\n  [ok resolved]\n  (if ok resolved nil))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a one-line if in direct function statement position", _304_)
  local function _305_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #control_layout_findings("(defn f\n  [ok resolved]\n  (if ok\n    resolved\n    nil))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a broken-out if in direct function statement position", _305_)
  local function _306_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #control_layout_findings("(defn f\n  [file]\n  (when (kept? file) file))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a one-line when in direct function statement position", _306_)
  local function _307_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #control_layout_findings("(defn f\n  [es]\n  (accumulate [r false _ e (ipairs es)]\n    (or r (m? e))))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not flag a one-line or as the last expression of a value-returning loop body", _307_)
  local function _308_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #control_layout_findings("(defn f\n  [a b]\n  (and a b))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not flag a one-line and as the returned function expression", _308_)
  local function _309_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #control_layout_findings("(defn f\n  [a b c]\n  (when a\n    (if b c a)))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a one-line control form as the sole when body expression", _309_)
  local function _310_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #control_layout_findings("(defn f\n  [es]\n  (accumulate [r false _ e (ipairs es)]\n    (or r\n      (m? e))))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a broken-out or in a loop body", _310_)
  local function _311_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #control_layout_findings("(defn f\n  [x]\n  (do (case x 1 :one _ :other)\n      (match x 1 :one _ :other)))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not flag controls when a do body has other expressions", _311_)
  local function _312_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #control_layout_findings("(defn f\n  [ok]\n  (let [x 1]\n    (if ok x 0)))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a one-line control form as the sole let body expression", _312_)
  local function _313_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #control_layout_findings("(defn f\n  [xs]\n  (each [_ x (ipairs xs)]\n    (if x x 0)))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a one-line control form as the sole each body expression", _313_)
  local function _314_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #control_layout_findings("(defn f\n  [a b c]\n  (let [x (or a b)]\n    {:p (if a b c)\n     :q [(when a b)]}\n    (foo (if a b c))\n    (if a\n      (or b c)\n      c)))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not require control forms in value, call, vector, map, or branch positions", _314_)
  local function _315_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #control_layout_findings("(defn f\n  []\n  (do (if a b c)\n      (when a b)))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not flag nested controls when a do body has other expressions", _315_)
  local function _316_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #control_layout_findings("(defn f [] (if a b c))", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("applies to spec files", _316_)
  local function _317_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #control_layout_findings("'(if a b c)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("ignores quoted control-form data", _317_)
  local function _318_()
    local finding = control_layout_findings("(defn f [] (if a b c))", "fnl/app.fnl", {["module-style"] = "off"})[1]
    local assert_5_auto = require("luassert")
    local expected_6_auto = {form = "fnl/app.fnl > defn:f > if#1", severity = "warning", message = "put this control form on several lines"}
    local actual_7_auto = {form = finding.form, severity = finding.severity, message = finding.message}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses the stable identity, warning severity, and prescribed message", _318_)
  local function _319_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "error"
    local actual_7_auto = control_layout_findings("(defn f [] (if a b c))", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "error"})[1].severity
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses error severity when configured", _319_)
  local function _320_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #control_layout_findings("(defn f [] (if a b c))", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not report when disabled", _320_)
  local function _321_()
    local source = "(defn f [] (if a b c))\n(defn g [] (when a b))"
    local path = "fnl/app.fnl"
    local rules = {["module-style"] = "off"}
    local baseline = control_layout_findings(source, path, rules)
    local result = check_context(source, {path = path, rules = rules, exclusions = {{rule = "control-layout", form = baseline[1].form, reason = "intentional"}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto
    local _322_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, finding in ipairs(result) do
        local val_28_
        if (finding.rule == "control-layout") then
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
      _322_ = tbl_26_
    end
    actual_7_auto = #_322_
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("an exclusion removes only the selected control-layout finding", _321_)
end
require("plenary.busted").describe("control-layout", _303_)
local function unused_and_or_findings(source, path, rules)
  local result = check_source(source, path, rules)
  if (result["module-missing"] or result["value-nil?"]) then
    return result
  else
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding in ipairs(result) do
      local val_28_
      if (finding.rule == "unused-and-or") then
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
local function _328_()
  local function _329_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #unused_and_or_findings("(defn f\n  [file]\n  (and file (close file))\n  (out file))", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a discarded and before the returned function expression", _329_)
  local function _330_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #unused_and_or_findings("(defn f\n  [a b]\n  (and a b))", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not flag the last and expression of a value-returning body", _330_)
  local function _331_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #unused_and_or_findings("(defn f\n  [xs]\n  (each [_ x (ipairs xs)]\n    (or x (warn))))", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags or in an each body", _331_)
  local function _332_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #unused_and_or_findings("(defn f\n  [xs]\n  (icollect [_ x (ipairs xs)]\n    (and x (f x))))", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not flag and as the last icollect body expression", _332_)
  local function _333_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #unused_and_or_findings("(defn f []\n  (let [x 1]\n    (or x (warn))\n    x))", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags or before the returned let expression", _333_)
  local function _334_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #unused_and_or_findings("(defn f []\n  (when ok\n    (and a (b))\n    c))", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags and before the returned when expression", _334_)
  local function _335_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #unused_and_or_findings("(defn f []\n  (do (and a (b)) c))", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags and before the returned do expression", _335_)
  local function _336_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #unused_and_or_findings("(defn f []\n  (let [y (and a b)] y)\n  (foo (or a b)))", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not flag and or in value positions", _336_)
  local function _337_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #unused_and_or_findings("'(and a b) '(or a b)", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("ignores quoted and-or data", _337_)
  local function _338_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #unused_and_or_findings("(defn f\n  []\n  (do `(and a b) out))", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("ignores and-or data in a quasiquote", _338_)
  local function _339_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #unused_and_or_findings("(defn f\n  []\n  `(do ,(do (and a (b)) c) `(do (and x y) z)))", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("checks only unquoted and-or code through nested quasiquotes", _339_)
  local function _340_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #unused_and_or_findings("(defn f\n  []\n  `(foo ,(do (or a (warn)) b)))", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("checks and-or code inside an unquote", _340_)
  local function _341_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #unused_and_or_findings("(defn f\n  []\n  (do '(and a b) out))", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("ignores plain quoted and-or data in a do body", _341_)
  local function _342_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #unused_and_or_findings("(defn f []\n  (and a b)\n  c)", "fnl/spec/app_spec.fnl", {["control-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("applies to spec files", _342_)
  local function _343_()
    local source = "(defn f []\n  (do (and a b) (or c d) (out)))"
    local rules = {["module-style"] = "off", ["control-layout"] = "off"}
    local first = unused_and_or_findings(source, "fnl/app.fnl", rules)
    local second = unused_and_or_findings(source, "fnl/app.fnl", rules)
    local assert_28_auto = require("luassert")
    local value_29_auto
    local and_344_ = (2 == #first) and (first[1].form ~= first[2].form)
    if and_344_ then
      local _345_
      do
        local tbl_26_ = {}
        local i_27_ = 0
        for _, finding in ipairs(first) do
          local val_28_ = finding.form
          if (nil ~= val_28_) then
            i_27_ = (i_27_ + 1)
            tbl_26_[i_27_] = val_28_
          else
          end
        end
        _345_ = tbl_26_
      end
      local function _347_()
        local tbl_26_ = {}
        local i_27_ = 0
        for _, finding in ipairs(second) do
          local val_28_ = finding.form
          if (nil ~= val_28_) then
            i_27_ = (i_27_ + 1)
            tbl_26_[i_27_] = val_28_
          else
          end
        end
        return tbl_26_
      end
      and_344_ = vim.deep_equal(_345_, _347_())
    end
    value_29_auto = and_344_
    assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (length first)) (not= (. first 1 \"form\") (. first 2 \"form\")) (vim.deep_equal (icollect [_ finding (ipairs first)] (. finding \"form\")) (icollect [_ finding (ipairs second)] (. finding \"form\"))))")
    return true
  end
  require("plenary.busted").it("gives nested discarded and-or forms distinct stable identities", _343_)
  local function _349_()
    local finding = unused_and_or_findings("(defn f []\n  (and a b)\n  c)", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "off"})[1]
    local assert_5_auto = require("luassert")
    local expected_6_auto = {form = "fnl/app.fnl > defn:f > and#1", severity = "warning", message = "and/or result is unused; use when"}
    local actual_7_auto = {form = finding.form, severity = finding.severity, message = finding.message}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses the stable identity warning severity and prescribed message", _349_)
  local function _350_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "error"
    local actual_7_auto = unused_and_or_findings("(defn f []\n  (and a b)\n  c)", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "off", ["unused-and-or"] = "error"})[1].severity
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses error severity when configured", _350_)
  local function _351_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #unused_and_or_findings("(defn f []\n  (and a b)\n  c)", "fnl/app.fnl", {["module-style"] = "off", ["control-layout"] = "off", ["unused-and-or"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not report when disabled", _351_)
  local function _352_()
    local source = "(defn f []\n  (do (and a b) (or c d) (out)))"
    local path = "fnl/app.fnl"
    local rules = {["module-style"] = "off", ["control-layout"] = "off"}
    local baseline = unused_and_or_findings(source, path, rules)
    local result = check_context(source, {path = path, rules = rules, exclusions = {{rule = "unused-and-or", form = baseline[1].form, reason = "intentional"}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto
    local _353_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, finding in ipairs(result) do
        local val_28_
        if (finding.rule == "unused-and-or") then
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
      _353_ = tbl_26_
    end
    actual_7_auto = #_353_
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("an exclusion removes only the selected unused-and-or finding", _352_)
end
require("plenary.busted").describe("unused-and-or", _328_)
local function repeated_code(count)
  return string.rep("(local x 1)\n", count)
end
local function file_size_policy(policy, max_code_lines)
  local entry = policy["file-size"]
  if (entry and (entry ~= "off") and max_code_lines) then
    return vim.tbl_extend("force", policy, {["file-size"] = vim.tbl_extend("force", entry, {options = vim.tbl_extend("force", entry.options, {["max-code-lines"] = max_code_lines})})})
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
local function _360_()
  local function _361_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #file_size_findings(repeated_code(301), "fnl/app.fnl", {["module-style"] = "off"}, nil, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("reports one finding for 301 code lines at the default limit", _361_)
  local function _362_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #file_size_findings(repeated_code(3), "fnl/app.fnl", {["module-style"] = "off"}, 3, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts exactly the configured code-line limit", _362_)
  local function _363_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #file_size_findings(repeated_code(4), "fnl/app.fnl", {["module-style"] = "off"}, 3, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("reports the first line above the configured code-line limit", _363_)
  local function _364_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #file_size_findings("(local a 1)\n\n; comment\n  ; indented comment\n(local b 2)\n;; another comment\n", "fnl/app.fnl", {["module-style"] = "off"}, 2, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not count blank or comment-only lines", _364_)
  local function _365_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #file_size_findings("(local text [[first\nsecond]])", "fnl/app.fnl", {["module-style"] = "off"}, 1, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("counts lines inside a multiline string as code", _365_)
  local function _366_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #file_size_findings(repeated_code(4), "fnl/spec/app_spec.fnl", {}, 3, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not report a spec file", _366_)
  local function _367_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "warning"
    local actual_7_auto = file_size_findings(repeated_code(4), "fnl/app.fnl", {["module-style"] = "off"}, 3, nil)[1].severity
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses warning severity by default", _367_)
  local function _368_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "error"
    local actual_7_auto = file_size_findings(repeated_code(4), "fnl/app.fnl", {["module-style"] = "off", ["file-size"] = "error"}, 3, nil)[1].severity
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses error severity when configured", _368_)
  local function _369_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #file_size_findings(repeated_code(4), "fnl/app.fnl", {["module-style"] = "off", ["file-size"] = "off"}, 3, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not report when disabled", _369_)
  local function _370_()
    local message = file_size_findings(repeated_code(4), "fnl/app.fnl", {["module-style"] = "off"}, 3, nil)[1].message
    local assert_28_auto = require("luassert")
    local value_29_auto = (string.find(message, "4") and string.find(message, "3"))
    assert_28_auto.is_truthy(value_29_auto, "(and (string.find message \"4\") (string.find message \"3\"))")
    return true
  end
  require("plenary.busted").it("includes the count and limit in the message", _370_)
  local function _371_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "fnl/app.fnl > file"
    local actual_7_auto = file_size_findings(repeated_code(4), "fnl/app.fnl", {["module-style"] = "off"}, 3, nil)[1].form
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses a stable file-level identity", _371_)
  local function _372_()
    local finding = file_size_findings(repeated_code(4), "fnl/app.fnl", {["module-style"] = "off"}, 3, nil)
    local exclusion = {{rule = "file-size", form = finding[1].form, reason = "intentional"}}
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #file_size_findings(repeated_code(4), "fnl/app.fnl", {["module-style"] = "off"}, 3, exclusion)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("an exact file-size exclusion suppresses the finding", _372_)
end
require("plenary.busted").describe("file-size", _360_)
local function _373_()
  local function _374_()
    local source = "(set x 2)"
    local path = "fnl/app.fnl"
    local rules = {["module-style"] = "off", ["defn-args-newline"] = "off"}
    local baseline = check_context(source, {path = path, rules = rules})
    local form = first_finding_form(baseline, "no-mutation")
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = check_context(source, {path = path, rules = rules, exclusions = {{rule = "no-mutation", form = form, reason = "intentional"}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("an exact no-mutation rule and form exclusion suppresses the finding", _374_)
end
require("plenary.busted").describe("no-mutation-exclusions", _373_)
local function _375_()
  local function _376_()
    local source = "(defn f [] (let [a (set x 1)] (set y 2)))"
    local path = "fnl/app.fnl"
    local rules = {["module-style"] = "off", ["defn-args-newline"] = "off"}
    local baseline = check_context(source, {path = path, rules = rules})
    local form = first_finding_form(baseline, "no-mutation")
    local remaining = check_context(source, {path = path, rules = rules, exclusions = {{rule = "no-mutation", form = form, reason = "intentional"}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #remaining
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("an exclusion for one nested mutation leaves the other finding", _376_)
end
require("plenary.busted").describe("no-mutation-nested-exclusion", _375_)
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
  local function _380_()
    return findings_for_named_rule(source, path, rule, rules)
  end
  ok, result = pcall(_380_)
  local _381_
  if ok then
    _381_ = #result
  else
    _381_ = -1
  end
  return {ok = ok, count = _381_}
end
local function _383_()
  local function _384_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #findings_for_named_rule("(defn f\n  []\n  (let [a 1 b 2]\n    a))", "fnl/app.fnl", "binding-per-line", {["module-style"] = "off", ["multiline-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags multiple let bindings sharing one line", _384_)
  local function _385_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #findings_for_named_rule("(let [a 1\n      b 2]\n  a)", "fnl/app.fnl", "binding-per-line", {["module-style"] = "off", ["multiline-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts one binding pair per line", _385_)
  local function _386_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #findings_for_named_rule("(let [a 1]\n  a)", "fnl/app.fnl", "binding-per-line", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a single binding pair", _386_)
  local function _387_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #findings_for_named_rule("(each [k v (pairs t)]\n  k)", "fnl/app.fnl", "binding-per-line", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not apply to each bindings", _387_)
  local function _388_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #findings_for_named_rule("(let [a 1 b 2\n      c 3]\n  a)", "fnl/app.fnl", "binding-per-line", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("reports one binding-per-line finding for a mixed multiline vector", _388_)
  local function _389_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 3
    local actual_7_auto = #findings_for_named_rule("(when-let [a 1 b 2] a)\n(if-let [a 1 b 2] a b)\n(with-open [a 1 b 2] a)", "fnl/app.fnl", "binding-per-line", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("applies to when-let if-let and with-open", _389_)
  local function _390_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #findings_for_named_rule("(let [a 1 b 2]\n  a)", "fnl/spec/app_spec.fnl", "binding-per-line", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("applies to spec files", _390_)
  local function _391_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #findings_for_named_rule("'(let [a 1 b 2]\n  a)", "fnl/app.fnl", "binding-per-line", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("ignores quoted binding data", _391_)
  local function _392_()
    local finding = findings_for_named_rule("(let [a 1 b 2])", "fnl/app.fnl", "binding-per-line", {["module-style"] = "off"})[1]
    local assert_5_auto = require("luassert")
    local expected_6_auto = {severity = "warning", message = "put each binding on its own line"}
    local actual_7_auto = {severity = finding.severity, message = finding.message}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses the prescribed warning and message", _392_)
  local function _393_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"error", 0}
    local actual_7_auto
    local _394_
    do
      local finding = findings_for_named_rule("(let [a 1 b 2])", "fnl/app.fnl", "binding-per-line", {["module-style"] = "off", ["binding-per-line"] = "error"})[1]
      _394_ = finding.severity
    end
    actual_7_auto = {_394_, #findings_for_named_rule("(let [a 1 b 2])", "fnl/app.fnl", "binding-per-line", {["module-style"] = "off", ["binding-per-line"] = "off"})}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("supports error severity and disabling", _393_)
end
require("plenary.busted").describe("binding-per-line", _383_)
local function _395_()
  local assert_5_auto = require("luassert")
  local expected_6_auto = {ok = true, count = 0}
  local actual_7_auto = safe_findings_for_named_rule("(let [a nil b])", "fnl/app.fnl", "binding-per-line", {["module-style"] = "off"})
  assert_5_auto.same(expected_6_auto, actual_7_auto)
  return true
end
require("plenary.busted").it("skips an odd-length binding vector without crashing", _395_)
local function _396_()
  local assert_5_auto = require("luassert")
  local expected_6_auto = {ok = true, count = 0}
  local actual_7_auto = safe_findings_for_named_rule("(let [a 1 b 2 c])", "fnl/app.fnl", "binding-per-line", {["module-style"] = "off"})
  assert_5_auto.same(expected_6_auto, actual_7_auto)
  return true
end
require("plenary.busted").it("skips a longer odd-length binding vector without crashing", _396_)
local function _397_()
  local assert_5_auto = require("luassert")
  local expected_6_auto = 0
  local actual_7_auto = #findings_for_named_rule("(let [;; note\n      a 1\n      b 2]\n  a)", "fnl/app.fnl", "binding-per-line", {["module-style"] = "off"})
  assert_5_auto.same(expected_6_auto, actual_7_auto)
  return true
end
require("plenary.busted").it("accepts a comment-only opening binding line", _397_)
local function _398_()
  local assert_5_auto = require("luassert")
  local expected_6_auto = 1
  local actual_7_auto = #findings_for_named_rule("(let [;; note\n      a 1 b 2]\n  a)", "fnl/app.fnl", "binding-per-line", {["module-style"] = "off"})
  assert_5_auto.same(expected_6_auto, actual_7_auto)
  return true
end
require("plenary.busted").it("flags bindings sharing a line after a comment-only opening line", _398_)
local function _399_()
  local source = "(let [a 1 b 2])"
  local first = findings_for_named_rule(source, "fnl/app.fnl", "binding-per-line", {["module-style"] = "off"})
  local second = findings_for_named_rule(source, "fnl/app.fnl", "binding-per-line", {["module-style"] = "off"})
  local assert_28_auto = require("luassert")
  local value_29_auto = ((nil ~= first[1].form) and (first[1].form == second[1].form))
  assert_28_auto.is_truthy(value_29_auto, "(and (not= nil (. first 1 \"form\")) (= (. first 1 \"form\") (. second 1 \"form\")))")
  return true
end
require("plenary.busted").it("keeps distinct identities stable across repeated linting", _399_)
local function _400_()
  local source = "(let [a 1 b 2])\n(let [c 3 d 4])"
  local path = "fnl/app.fnl"
  local rules = {["module-style"] = "off"}
  local baseline = findings_for_named_rule(source, path, "binding-per-line", rules)
  local context = {path = path, rules = rules, exclusions = {{rule = "binding-per-line", form = baseline[1].form, reason = "intentional"}}}
  local result = check_context(source, context)
  local assert_5_auto = require("luassert")
  local expected_6_auto = 1
  local actual_7_auto
  local _401_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding in ipairs(result) do
      local val_28_
      if (finding.rule == "binding-per-line") then
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
    _401_ = tbl_26_
  end
  actual_7_auto = #_401_
  assert_5_auto.same(expected_6_auto, actual_7_auto)
  return true
end
require("plenary.busted").it("an exact exclusion suppresses only the selected binding finding", _400_)
local function _404_()
  local function _405_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #findings_for_named_rule("(foo a {:x 1\n         :y 2})", "fnl/app.fnl", "call-data-arg", {["module-style"] = "off", ["multiline-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a multiline map literal passed to a plain call", _405_)
  local function _406_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #findings_for_named_rule("(foo a {:x 1 :y 2})", "fnl/app.fnl", "call-data-arg", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a one-line map literal call argument", _406_)
  local function _407_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #findings_for_named_rule("(let [opts {:x 1\n            :y 2}]\n  (foo a opts))", "fnl/app.fnl", "call-data-arg", {["module-style"] = "off", ["multiline-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts a map bound in a let before the call", _407_)
  local function _408_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #findings_for_named_rule("(foo (fn []\n  1))", "fnl/app.fnl", "call-data-arg", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("excludes fn arguments from plain call data findings", _408_)
  local function _409_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #findings_for_named_rule("(values {:a 1\n         :b 2} nil)", "fnl/app.fnl", "call-data-arg", {["module-style"] = "off", ["multiline-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("treats values as a plain call", _409_)
  local function _410_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #findings_for_named_rule("(foo [1\n      2])", "fnl/app.fnl", "call-data-arg", {["module-style"] = "off", ["multiline-layout"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a multiline vector literal passed to a plain call", _410_)
  local function _411_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #findings_for_named_rule("(foo {:x 1\n      :y 2})", "fnl/spec/app_spec.fnl", "call-data-arg", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not report in spec files", _411_)
  local function _412_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #findings_for_named_rule("'(foo {:x 1\n      :y 2})", "fnl/app.fnl", "call-data-arg", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("ignores quoted call data", _412_)
  local function _413_()
    local finding = findings_for_named_rule("(foo {:x 1\n      :y 2})", "fnl/app.fnl", "call-data-arg", {["module-style"] = "off", ["multiline-layout"] = "off"})[1]
    local assert_5_auto = require("luassert")
    local expected_6_auto = {severity = "warning", message = "move this multi-line map/vector into a let binding so the call fits on one line"}
    local actual_7_auto = {severity = finding.severity, message = finding.message}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses the prescribed warning and message", _413_)
  local function _414_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"error", 0}
    local actual_7_auto
    local _415_
    do
      local finding = findings_for_named_rule("(foo {:x 1\n      :y 2})", "fnl/app.fnl", "call-data-arg", {["module-style"] = "off", ["multiline-layout"] = "off", ["call-data-arg"] = "error"})[1]
      _415_ = finding.severity
    end
    actual_7_auto = {_415_, #findings_for_named_rule("(foo {:x 1\n      :y 2})", "fnl/app.fnl", "call-data-arg", {["module-style"] = "off", ["multiline-layout"] = "off", ["call-data-arg"] = "off"})}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("supports error severity and disabling", _414_)
end
require("plenary.busted").describe("call-data-arg", _404_)
local function _416_()
  local source = "(foo {:x 1\n      :y 2})"
  local rules = {["module-style"] = "off", ["multiline-layout"] = "off"}
  local first = findings_for_named_rule(source, "fnl/app.fnl", "call-data-arg", rules)
  local second = findings_for_named_rule(source, "fnl/app.fnl", "call-data-arg", rules)
  local assert_28_auto = require("luassert")
  local value_29_auto = ((nil ~= first[1].form) and (first[1].form == second[1].form))
  assert_28_auto.is_truthy(value_29_auto, "(and (not= nil (. first 1 \"form\")) (= (. first 1 \"form\") (. second 1 \"form\")))")
  return true
end
require("plenary.busted").it("keeps identities stable across repeated linting", _416_)
local function _417_()
  local source = "(foo {:x 1\n      :y 2})\n(bar {:a 1\n      :b 2})"
  local path = "fnl/app.fnl"
  local rules = {["module-style"] = "off", ["multiline-layout"] = "off"}
  local baseline = findings_for_named_rule(source, path, "call-data-arg", rules)
  local context = {path = path, rules = rules, exclusions = {{rule = "call-data-arg", form = baseline[1].form, reason = "intentional"}}}
  local result = check_context(source, context)
  local assert_5_auto = require("luassert")
  local expected_6_auto = 1
  local actual_7_auto
  local _418_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, finding in ipairs(result) do
      local val_28_
      if (finding.rule == "call-data-arg") then
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
    _418_ = tbl_26_
  end
  actual_7_auto = #_418_
  assert_5_auto.same(expected_6_auto, actual_7_auto)
  return true
end
require("plenary.busted").it("an exact exclusion suppresses the selected call finding", _417_)
local function option_rule(rule, options)
  return {[rule] = {severity = "warning", options = vim.tbl_extend("force", all_options[rule], options)}}
end
local function option_findings_call(lint, source, path, rule, options)
  local context = {path = path, ["spec-files"] = {"^fnl/spec/"}, rules = option_rule(rule, options), matcher = matcher["vim-matcher"]()}
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
local function _422_()
  local function _423_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #option_findings("(import-macros {: module : def : defn : defn-} :my.macros)\\n(module app)", "fnl/app.fnl", "module-style", {["macro-module"] = "my.macros"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("module-style accepts a configured macro module", _423_)
  local function _424_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #option_findings("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\\n(module app)", "fnl/app.fnl", "module-style", {["macro-module"] = "my.macros"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("module-style still flags the default macro module when configured away", _424_)
  local function _425_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #option_findings("(import-macros {: check : verify} :my.spec.macros)", "fnl/spec/app_spec.fnl", "spec-macro-import", {["macro-module"] = "my.spec.macros", ["required-macros"] = {"check", "verify"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("spec-macro-import accepts configured macro names and module", _425_)
  local function _426_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #option_findings("(deftest run)", "fnl/spec/app_spec.fnl", "spec-macro-import", {["exempt-files"] = {"^fnl/spec/app_spec[.]fnl$"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("spec-macro-import accepts configured exempt files", _426_)
  local function _427_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #option_findings("(module app)", "fnl/spec/app_spec.fnl", "spec-no-module", {["module-form"] = "custom-module"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("spec-no-module accepts a configured module form", _427_)
  local function _428_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #option_findings("(require :custom.test)", "fnl/spec/app_spec.fnl", "spec-direct-require", {["forbidden-modules"] = {"custom.test"}, ["exempt-files"] = {}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("spec-direct-require accepts configured forbidden modules", _428_)
  local function _429_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #option_findings("(require :custom.test)", "fnl/spec/app_spec.fnl", "spec-direct-require", {["forbidden-modules"] = {"custom.test"}, ["exempt-files"] = {"^fnl/spec/app_spec[.]fnl$"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("spec-direct-require accepts configured exempt files", _429_)
  local function _430_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #option_findings("(checking \"one\" (assertion true))", "fnl/spec/app_spec.fnl", "one-is-per-testing", {["testing-form"] = "checking", ["assertion-form"] = "assertion", count = 1})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("one-is-per-testing accepts configured testing and assertion forms", _430_)
  local function _431_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #option_findings("(unless ok (do a b) c)", "fnl/app.fnl", "if-branch-call", {["if-forms"] = {"unless"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("if-branch-call accepts configured conditional forms", _431_)
  local function _432_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #option_findings("(unless ok value nil)", "fnl/app.fnl", "if-without-else", {["if-forms"] = {"unless"}, ["flag-nil-else"] = false})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("if-without-else accepts configured conditional forms and nil policy", _432_)
  local function _433_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #option_findings("(unless ok\\n  a\\n  b)", "fnl/app.fnl", "control-layout", {["control-forms"] = {"unless"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("control-layout accepts configured control forms", _433_)
  local function _434_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #option_findings("(xor a b)", "fnl/app.fnl", "unused-and-or", {forms = {"xor"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("unused-and-or accepts configured forms", _434_)
  local function _435_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #option_findings("(fnx f [a] a)", "fnl/app.fnl", "defn-args-newline", {forms = {"fnx"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("defn-args-newline accepts configured function forms", _435_)
  local function _436_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #option_findings("(fnx f [] (if a (if b c d) e))", "fnl/app.fnl", "function-shape", {["function-forms"] = {"fnx"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("function-shape accepts configured function forms", _436_)
  local function _437_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #option_findings("(var x 1)", "fnl/spec/app_spec.fnl", "no-mutation", {["applies-to"] = "all"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("applies-to all makes no-mutation inspect spec files", _437_)
  local function _438_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #option_findings("(alter x 1)", "fnl/app.fnl", "no-mutation", {forms = {"alter"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("no-mutation accepts configured mutation forms", _438_)
  local function _439_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #option_findings("(branch x\\n  a b) (bind [a 1 b 2] a)", "fnl/app.fnl", "multiline-layout", {["clause-forms"] = {"branch"}, ["binding-forms"] = {"bind"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("multiline-layout accepts configured clause and binding forms", _439_)
  local function _440_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #option_findings("(local c (require :my.core))", "fnl/app.fnl", "core-require", {module = "my.core", binding = "c"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("core-require accepts configured module and binding", _440_)
  local function _441_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #option_findings("(when-let [a 1 b 2] a)", "fnl/app.fnl", "binding-per-line", {forms = {"let"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("binding-per-line accepts configured forms", _441_)
  local function _442_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #option_findings("(special [1\\n  2])", "fnl/app.fnl", "call-data-arg", {["ignore-forms"] = {"special"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("call-data-arg ignores configured call heads", _442_)
  local function _443_()
    local lint = load_lint()
    local matcher0 = load_matcher()
    local result = lint.check("(var x 1)", {path = "test/x.fnl", ["spec-files"] = {"^test/"}, rules = compatibility_policy({["module-style"] = "off", ["spec-macro-import"] = "off", ["spec-no-module"] = "off", ["spec-direct-require"] = "off", ["no-mutation"] = "warning"}), matcher = matcher0["vim-matcher"]()})
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("spec-files classifies a custom spec path", _443_)
  local function _444_()
    local lint = load_lint()
    local matcher0 = load_matcher()
    local result = lint.check("(module app)\n(var x 1)", {path = "tests/a.fnl", ["spec-files"] = {"^fnl/spec/", "^tests/"}, rules = compatibility_policy({["spec-macro-import"] = "off", ["spec-no-module"] = "error", ["no-mutation"] = "warning"}), matcher = matcher0["vim-matcher"]()})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"spec-no-module"}
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
  require("plenary.busted").it("spec-files combines multiple patterns and keeps source rules scoped", _444_)
  local function _446_()
    local lint = load_lint()
    local ok, result, err
    local function _447_()
      return lint.check("(var x 1)", {path = "fnl/spec/x.fnl", ["spec-files"] = {"^fnl/spec/.*$"}, rules = compatibility_policy({["module-style"] = "off", ["no-mutation"] = "warning"})})
    end
    ok, result, err = pcall(_447_)
    local assert_28_auto = require("luassert")
    local value_29_auto = (not lint["module-missing"] and not ok and result and result.message)
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. lint \"module-missing\")) (not ok) result (. result \"message\"))")
    return true
  end
  require("plenary.busted").it("regex spec-files without a matcher returns an error", _446_)
  local function _448_()
    local lint = load_lint()
    local result = lint.check("(var x 1)", {path = "fnl/spec/x.fnl", ["spec-files"] = {"^fnl/spec/"}, rules = compatibility_policy({["spec-macro-import"] = "off", ["spec-no-module"] = "off", ["spec-direct-require"] = "off", ["no-mutation"] = "warning"})})
    local assert_28_auto = require("luassert")
    local value_29_auto = (not lint["module-missing"] and (0 == #result))
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. lint \"module-missing\")) (= 0 (length result)))")
    return true
  end
  return require("plenary.busted").it("the default spec-files prefix works without a matcher", _448_)
end
require("plenary.busted").describe("configurable-rule-options", _422_)
local function _449_()
  local function _450_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = finding_summary(check_source_with_matcher("(if ok then)", "fnl/legacy/a.fnl", {["module-style"] = "off", ["if-without-else"] = "warning"}, {{rule = "if-without-else", pattern = "^fnl/legacy/"}}))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("matches an exclusion pattern against the repository-relative path", _450_)
  local function _451_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #check_source_with_matcher("(if one then)\n\n(if two then)", "fnl/app.fnl", {["module-style"] = "off", ["if-without-else"] = "warning"}, {{rule = "if-without-else", line = 1}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("matches a single finding line", _451_)
  local function _452_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #check_source_with_matcher("(if one then)\n\n(if two then)", "fnl/app.fnl", {["module-style"] = "off", ["if-without-else"] = "warning"}, {{rule = "if-without-else", lines = {from = 1, to = 2}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("matches an intersecting line range", _452_)
  local function _453_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = finding_summary(check_source_with_matcher("(if ok then)", "fnl/app.fnl", {["module-style"] = "off", ["if-without-else"] = "warning"}, {{rule = "if-without-else", code = "if"}}))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("matches code in the finding form", _453_)
  local function _454_()
    local result = check_source_with_matcher("(var baz 1)\n(var foo 2)", "fnl/app.fnl", {["module-style"] = "off", ["no-mutation"] = "warning"}, {{rule = "no-mutation", code = "baz"}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"no-mutation", "fnl/app.fnl > top#2", "warning"}}
    local actual_7_auto = finding_identities(result)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("matches code only against the selected finding source", _454_)
  local function _455_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = finding_summary(check_source_with_matcher("(if ok then)", "fnl/app.fnl", {["module-style"] = "off", ["if-without-else"] = "warning"}, {{rule = "if-without-else", pattern = "app[.]fnl", line = 1}}))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("combines path and line selectors with AND semantics", _455_)
  local function _456_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = finding_summary(check_source_with_matcher("(if ok then)", "fnl/app.fnl", {["module-style"] = "error", ["if-without-else"] = "warning"}, {{pattern = "app[.]fnl", line = 1}}))
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a general exclusion without a rule applies to every rule", _456_)
  local function _457_()
    local result = check_source_with_matcher("(if ok then)", "fnl/app.fnl", {["module-style"] = "error", ["if-without-else"] = {severity = "warning", options = all_options["if-without-else"], exclusions = {{line = 1}}}}, nil)
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"module-style"}
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
  require("plenary.busted").it("a per-rule exclusion applies only to its configured rule", _457_)
  local function _459_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #check_source_with_matcher("(local value 1)", "fnl/app.fnl", {["module-style"] = "error"}, {{rule = "module-style", code = "local"}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a code selector does not match a file-level finding", _459_)
  local function _460_()
    local lint = load_lint()
    local ok, result, err
    local function _461_()
      return lint.check("(if ok then)", {path = "fnl/app.fnl", rules = {["module-style"] = "off", ["if-without-else"] = "warning"}, exclusions = {{rule = "if-without-else", pattern = "app[.]fnl"}}})
    end
    ok, result, err = pcall(_461_)
    local assert_28_auto = require("luassert")
    local value_29_auto = (not lint["module-missing"] and not ok and result and result.message)
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. lint \"module-missing\")) (not ok) result (. result \"message\"))")
    return true
  end
  return require("plenary.busted").it("a regex exclusion without a matcher returns an error", _460_)
end
require("plenary.busted").describe("selector-exclusions", _449_)
local function _462_()
  local function _463_()
    local result = check_source_exact("(if ok then)\n(var x 1)", "fnl/app.fnl", {["module-style"] = "off", ["if-without-else"] = {severity = "warning", options = all_options["if-without-else"]}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"if-without-else"}
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
  require("plenary.busted").it("a listed rule leaves unlisted rules disabled", _463_)
  local function _465_()
    local source = "(module a)\n(local a 1)\n(local b 2)\n(local c 3)\n(local d 4)"
    local result = check_source(source, "fnl/app.fnl", {["module-style"] = "off", ["file-size"] = {severity = "warning", options = {["applies-to"] = "source", ["max-code-lines"] = 3}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"file-size"}
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
  require("plenary.busted").it("file-size honors a nested max-code-lines option", _465_)
  local function _467_()
    local namespace_result = option_findings("(namespace foo)", "fnl/spec/app_spec.fnl", "spec-no-module", {["module-form"] = "namespace"})
    local module_result = option_findings("(module foo)", "fnl/spec/app_spec.fnl", "spec-no-module", {["module-form"] = "namespace"})
    local assert_28_auto = require("luassert")
    local value_29_auto = ((1 == #namespace_result) and (0 == #module_result))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 1 (length namespace-result)) (= 0 (length module-result)))")
    return true
  end
  return require("plenary.busted").it("spec-no-module uses the configured module-form", _467_)
end
return require("plenary.busted").describe("shipped-bug-regressions", _462_)
