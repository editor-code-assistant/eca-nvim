-- [nfnl] fnl/spec/fennel-extras/lint_spec.fnl
local function load_lint()
  local ok, result = pcall(require, "fennel-extras.lint")
  if ok then
    return result
  else
    return {["module-missing"] = true}
  end
end
local function check_source(source, path, rules)
  local lint = load_lint()
  if lint["module-missing"] then
    return lint
  else
    local ctx
    if rules then
      ctx = {path = path, rules = rules}
    else
      ctx = {path = path}
    end
    local findings, err = lint.check(source, ctx)
    if findings then
      return findings
    else
      return {["value-nil?"] = true, message = (err and err.message), line = (err and err.line), col = (err and err.col)}
    end
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
  local function _12_()
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    return source
  end
  ok, result = pcall(_12_)
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
local function collect_repo_findings(lint, counts, lint_files, cli_files, rules)
  for _, path in ipairs(project_fennel_files()) do
    local source = read_source(path)
    if source.error then
      if string.find(path, "^fnl/fennel%-extras/cli") then
        table.insert(cli_files, path)
      else
        table.insert(lint_files, path)
      end
    else
      local context
      if rules then
        context = {path = path, rules = rules}
      else
        context = {path = path}
      end
      local findings = lint.check(source, context)
      for _0, finding in ipairs(findings) do
        if counts[finding.rule] then
          counts[finding.rule] = (counts[finding.rule] + 1)
        else
        end
      end
      if string.find(path, "^fnl/fennel%-extras/cli") then
        for _0, finding in ipairs(findings) do
          table.insert(cli_files, {path, finding.rule})
        end
      else
        if string.find(path, "^fnl/fennel%-extras/lint") then
          for _0, finding in ipairs(findings) do
            table.insert(lint_files, {path, finding.rule})
          end
        else
        end
      end
    end
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
local function _22_()
  local function _23_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)", "fnl/app.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a compliant non-spec module is clean", _23_)
  local function _24_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/legacy.fnl > file", "error"}}
    local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(defn run [] 1)", "fnl/legacy.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a non-spec file without a module form has one file finding", _24_)
  local function _25_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/legacy.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(local x 1)", "fnl/legacy.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a non-spec file containing only a local still has one file finding", _25_)
  local function _26_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/legacy.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(if ok a b)", "fnl/legacy.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a non-spec file containing only an if still has one file finding", _26_)
  local function _27_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a module without the aniseed import has one file finding", _27_)
  local function _28_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = forms_for("(import-macros {: module : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)", "fnl/app.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a module-style file missing def in the macro import is reported", _28_)
  local function _29_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(if ok (module app) x)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested module form is reported in a non-spec file", _29_)
  local function _30_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(if ok (import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed) x)\n(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested aniseed import is reported in a non-spec file", _30_)
  local function _31_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n'(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a quoted top-level module form is reported as non-module style", _31_)
  local function _32_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n`(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a quasiquoted top-level module form is reported as non-module style", _32_)
  local function _33_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n,(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an unquoted top-level module form is reported as non-module style", _33_)
  local function _34_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n#(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a hashfn top-level module form is reported as non-module style", _34_)
  local function _35_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("'(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a prefixed aniseed import with a real module is reported as non-module style", _35_)
  local function _36_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(module app)\n;; between top-level forms\n(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)", "fnl/app.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("top-level module and import forms stay clean in either order with comments", _36_)
  local function _37_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/legacy.fnl > file", "error"}}
    local actual_7_auto = forms_for("(fn run [] 1)\n{:run run}", "fnl/legacy.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a legacy fn and final table are reported as non-module style", _37_)
  local function _38_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"works\" (is true)))", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("module-style never applies to spec files", _38_)
end
require("plenary.busted").describe("module-style", _22_)
local function _39_()
  local function _40_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("the approved spec macro import is clean", _40_)
  local function _41_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing} :spec.eca.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec macro import missing is is reported", _41_)
  local function _42_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :other.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec macro import from another module is reported", _42_)
  local function _43_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = forms_for("(deftest run (is true))", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec with no macro import has the spec identity", _43_)
  local function _44_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = findings_for_rule("'(import-macros {: deftest : testing : is} :spec.eca.macros)", "fnl/spec/app_spec.fnl", "spec-macro-import")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a prefixed spec macro import is reported", _44_)
  local function _45_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/x_spec.fnl > spec", "error"}}
    local actual_7_auto = findings_for_rule("(do (import-macros {: deftest : testing : is} :spec.eca.macros))\n(deftest run (testing \"works\" (is true)))", "fnl/spec/x_spec.fnl", "spec-macro-import")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested spec macro import is reported", _45_)
  local function _46_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = forms_for("(import-macros {: deftest} :other) (deftest t (testing \"x\" (is true)))", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a wrong macro import is reported independently of test content", _46_)
  local function _47_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = forms_for("(require :foo)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec with only a direct require still has the spec identity", _47_)
  local function _48_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-no-module", "fnl/spec/app_spec.fnl > module:app", "error"}}
    local actual_7_auto = forms_for("(module app)\n(import-macros {: deftest : testing : is} :spec.eca.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a module form in a spec is reported at that form", _48_)
  local function _49_()
    local function _50_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"spec-direct-require", "fnl/spec/app_spec.fnl > top#1", "error"}}
      local actual_7_auto = findings_for_rule("(require :plenary.busted)", "fnl/spec/app_spec.fnl", "spec-direct-require")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("keyword plenary require is forbidden in ordinary specs", _50_)
    local function _51_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"spec-direct-require", "fnl/spec/app_spec.fnl > top#1", "error"}}
      local actual_7_auto = findings_for_rule("(require \"luassert\")", "fnl/spec/app_spec.fnl", "spec-direct-require")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("string luassert require is forbidden in ordinary specs", _51_)
    local function _52_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(require :plenary.busted)\n(require \"luassert\")", "fnl/spec/eca/macros.fnlm", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("the spec macro implementation may require test libraries directly", _52_)
    local function _53_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module ordinary)\n(require :plenary.busted)\n(require \"luassert\")", "fnl/ordinary.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("direct test-library requires are not a non-spec finding", _53_)
  end
  require("plenary.busted").describe("spec-direct-require", _49_)
  local function _54_()
    local function _55_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"one\" (is true)))", "fnl/spec/app_spec.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("one direct is in testing is clean", _55_)
    local function _56_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"one\" (let [x 1] (is (= x 1)))))", "fnl/spec/app_spec.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("one is inside a let wrapper is clean", _56_)
    local function _57_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"none\" (let [x 1] x)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("testing with no is is reported", _57_)
    local function _58_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"two\" (is true) (is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("testing with two is forms is reported once", _58_)
    local function _59_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"outer\" (testing \"inner\" (is true))))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("nested testing forms are counted separately", _59_)
    local function _60_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"quoted\" '(is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("quoted is data is not counted", _60_)
    local function _61_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" '\n ;; comment\n (is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quoted is separated by a comment is not counted", _61_)
    local function _62_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" `\n(is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quasiquoted is separated by a newline is not counted", _62_)
    local function _63_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" ' (is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quoted is separated by whitespace is not counted", _63_)
    local function _64_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" '(is false) (is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quoted is plus an executable is is counted once", _64_)
    local function _65_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"is in text\" (print \"is\"))) ;; is\n", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("strings and comments containing is are not counted", _65_)
  end
  require("plenary.busted").describe("one-is-per-testing", _54_)
  local function _66_()
    local function _67_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "warning"}}
      local actual_7_auto = findings_for_rule("(defn run [] (if ok (do a b) c))", "fnl/app.fnl", "if-branch-call")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a multi-expression then do is a warning", _67_)
    local function _68_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(defn run [] (if ok (do a) c))", "fnl/app.fnl", "if-branch-call")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a one-expression do is clean", _68_)
    local function _69_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(defn run [] (if ok (let [x 1] x) (set x 1)))", "fnl/app.fnl", "if-branch-call")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("let and set branches are clean", _69_)
    local function _70_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > else", "warning"}, {"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "warning"}}
      local actual_7_auto
      do
        local findings = findings_for_rule("(defn run [] (if ok (do a b) (do c d)))", "fnl/app.fnl", "if-branch-call")
        local function _71_(a, b)
          return (a[2] < b[2])
        end
        table.sort(findings, _71_)
        actual_7_auto = findings
      end
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("both multi-expression branches have distinct identities", _70_)
    local function _72_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "warning"}, {"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then#2", "warning"}}
      local actual_7_auto = findings_for_rule("(defn run [] (if a (do x y) b (do c d) e))", "fnl/app.fnl", "if-branch-call")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("multi-clause then branches use both then identities", _72_)
    local function _73_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(defn run [] (if ok (let [x 1] (do a b)) c))", "fnl/app.fnl", "if-branch-call")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a do nested below a non-do branch root is clean", _73_)
    local function _74_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "error"}}
      local actual_7_auto = findings_for_rule("(defn run [] (if ok (do a b) c))", "fnl/app.fnl", "if-branch-call", {["if-branch-call"] = "error"})
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("if branch severity can be overridden to error", _74_)
    local function _75_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = findings_for_rule("(defn run [] (if ok (do a b) c))", "fnl/app.fnl", "if-branch-call", {["if-branch-call"] = "off"})
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("if branch rule can be disabled", _75_)
    local function _76_()
      local function _77_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {}
        local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(local core (require :eca.nfnl.core))", "fnl/app.fnl", nil)
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("the core local binding uses the canonical name", _77_)
      local function _78_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"core-require", "fnl/app.fnl > local:core", "error"}}
        local actual_7_auto = findings_for_rule("(local core (require :eca.nfnl.core) other)", "fnl/app.fnl", "core-require")
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("a core local with extra expressions is reported", _78_)
      local function _79_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {}
        local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(local core (require \"eca.nfnl.core\"))", "fnl/app.fnl", nil)
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("a string core local binding uses the canonical shape", _79_)
      local function _80_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"core-require", "fnl/app.fnl > local:c", "error"}}
        local actual_7_auto = findings_for_rule("(local c (require :eca.nfnl.core))", "fnl/app.fnl", "core-require")
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("a non-core local binding is reported", _80_)
      local function _81_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"core-require", "fnl/app.fnl > top#1", "error"}}
        local actual_7_auto = findings_for_rule("(require :eca.nfnl.core extra)", "fnl/app.fnl", "core-require")
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("a keyword core require with extra expressions is reported", _81_)
      local function _82_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"core-require", "fnl/app.fnl > top#1", "error"}}
        local actual_7_auto = findings_for_rule("(require \"eca.nfnl.core\" extra)", "fnl/app.fnl", "core-require")
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      return require("plenary.busted").it("a string core require with extra expressions is reported", _82_)
    end
    require("plenary.busted").describe("core-require", _76_)
    local function _83_()
      local function _84_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "warning"}, {"if-branch-call", "fnl/app.fnl > defn:run > if#1 > else", "warning"}}
        local actual_7_auto = findings_for_rule("(defn run [] (if ok (do a b) (do c d)))", "fnl/app.fnl", "if-branch-call", {["module-style"] = "off"})
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("the same source produces identical sorted findings", _84_)
      local function _85_()
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
      require("plenary.busted").it("no two findings share path rule and form", _85_)
      local function _87_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"core-require", "fnl/app.fnl > top#1", "error"}}
        local actual_7_auto = findings_for_rule("(require :eca.nfnl.core extra)\n(vim.api.nvim_set_option_value :x 1 {})", "fnl/app.fnl", "core-require")
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("the pure core returns findings without executing vim api text", _87_)
      local function _88_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {["value-nil?"] = true, message = "missing closing delimiter", line = 1, col = 1}
        local actual_7_auto = check_source("(unclosed", "fnl/bad.fnl", nil)
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      return require("plenary.busted").it("reader failure returns nil and a structured error table", _88_)
    end
    return require("plenary.busted").describe("determinism-and-boundary", _83_)
  end
  return require("plenary.busted").describe("if-branch-call", _66_)
end
require("plenary.busted").describe("spec-shape", _39_)
local function function_findings(source)
  return findings_for_rule(source, "fnl/app.fnl", "function-shape", {["module-style"] = "off"})
end
local function _89_()
  local function _90_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [x] (set x (if x 1 2)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested if in a set value reports the outer set form", _90_)
  local function _91_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (do a b))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a multi-expression do body reports the outer do form", _91_)
  local function _92_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (foo (fn [] a) (do a b)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("nested function and do forms report one outer offending form", _92_)
  local function _93_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"function-shape", "fnl/app.fnl > defn:f > sequence#1", "warning"}}
    local actual_7_auto = function_findings("(defn f [] [1 (if a b c)])")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested if in a sequence reports the sequence form", _93_)
  local function _94_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"function-shape", "fnl/app.fnl > defn:f > table#1", "warning"}}
    local actual_7_auto = function_findings("(defn f [] {:k (if a b c)})")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested if in a table reports the table form", _94_)
  local function _95_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (local y (let [z 1] z)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested let in a local value reports the outer local form", _95_)
  local function _96_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn f [x] (set x (g x)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a set with a leaf call value is clean", _96_)
  local function _97_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn f [] [1 (g a)])")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a sequence with a leaf call is clean", _97_)
  local function _98_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn f [] {:k (g a)})")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a table with a leaf call is clean", _98_)
  local function _99_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn f [] '(if a b c))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("quoted control forms are clean", _99_)
  local function _100_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"function-shape", "fnl/app.fnl > defn-:join > if#1 > else > if#1", "warning"}}
    local actual_7_auto = function_findings("(defn- join [xs]\n  (if (= xs [])\n      nil\n      (if (= (length xs) 1)\n          (first xs)\n          (table.concat (icollect [_ x (ipairs xs)] x) \" \"))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("the user's nested inner if is the single function-shape finding", _100_)
  local function _101_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn- join-parts [xs]\n  (table.concat (icollect [_ x (ipairs xs)] x) \" \"))\n(defn- join [xs]\n  (if (= xs [])\n      nil\n      (join-parts xs)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("the fixed join form is clean", _101_)
  local function _102_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [xs]\n  (let [parts (icollect [_ x (ipairs xs)] x)]\n    (table.concat parts \" \")))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a comprehension in the first let binding is reported", _102_)
  local function _103_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [xs] (if ok (icollect [_ x (ipairs xs)] x) nil))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a comprehension used as an if branch is reported", _103_)
  local function _104_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [xs] (when ok (icollect [_ x (ipairs xs)] x)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a comprehension used as a when body is reported", _104_)
  local function _105_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn f [xs] (icollect [_ x (ipairs xs)] x))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a direct comprehension body with a leaf body is clean", _105_)
  local function _106_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run []\n  (foo (fn [] (if a b c))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a function argument with an if body is reported", _106_)
  local function _107_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run []\n  (foo (fn [] (do a b))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a function argument with a do body is reported", _107_)
  local function _108_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [xs]\n  (foo (each [_ x (ipairs xs)] (when x (bar)))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a loop argument with a when body is reported", _108_)
  local function _109_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [xs]\n  (foo (fn [] a) (icollect [_ x (ipairs xs)] x)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a function argument and comprehension argument with leaf bodies are clean", _109_)
  local function _110_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [x]\n  (let [a x b 1]\n    (+ a b)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a first let with leaf bindings and body is clean", _110_)
  local function _111_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [x]\n  (let [a (if x 1 2)] a))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an if in a let binding value is reported", _111_)
  local function _112_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [x]\n  x\n  (let [a 1] a))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a let after the first body expression is reported", _112_)
  local function _113_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [x]\n  (let [a x]\n    (let [b a] b)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a second nested let is reported", _113_)
  local function _114_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn- f [] (while true (let [x (if a b c)] x)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested if in a while binding is reported", _114_)
  local function _115_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn- f [] (while true (do (if a b c) x)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested if in a while do body is reported", _115_)
  local function _116_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn- f [] (do x))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a single-expression do body is reported", _116_)
  local function _117_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn- f [] (if a (let [y 1] y) b))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a let inside an if branch is reported", _117_)
  local function _118_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn- f [] (each [_ v (ipairs xs)] (when v (print v))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested when in a loop body is reported", _118_)
  local function _119_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn- f [] (foo (fn [] a) (fn [] b)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("sibling callback layers are clean", _119_)
  local function _120_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (foo (bar (fn [] a))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a function nested in a call argument is reported", _120_)
  local function _121_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (let [x (foo (fn [] a))] x))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a function nested in a let binding call is reported", _121_)
  local function _122_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [xs] (foo (bar (icollect [_ x (ipairs xs)] x))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a comprehension nested in a call argument is reported", _122_)
  local function _123_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (if ok (foo (fn [] a)) nil))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a call with a function in an if branch is reported", _123_)
  local function _124_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [x]\n  (if x 1 y 2 3))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a multi-clause flat if is clean", _124_)
  local function _125_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [x]\n  (case x 1 :one 2 :two :other))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a case with leaf clauses is clean", _125_)
  local function _126_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [x]\n  (case x 1 (if x :one :other) :other))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested if in a case clause is reported", _126_)
  local function _127_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [x]\n  (match x 1 :one 2 :two :other))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a match with leaf clauses is clean", _127_)
  local function _128_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [x]\n  (match x 1 (if x :one :other) _ :other))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested if in a match clause is reported", _128_)
  local function _129_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [x]\n  (when x (print x) (print :done)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a when with several leaf steps is clean", _129_)
  local function _130_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [xs]\n  (each [_ x (ipairs xs)] (print x)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a loop with a leaf body is clean", _130_)
  local function _131_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [xs]\n  (each [_ x (ipairs xs)] (if x (print x) (print :none))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a loop with an if in its body is reported", _131_)
  local function _132_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [] (pcall (fn [] (leaf))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a function literal passed to pcall is clean", _132_)
  local function _133_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [xs]\n  (table.concat (icollect [_ x (ipairs xs)] (f x)) \" \"))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an icollect passed to table.concat is clean", _133_)
  local function _134_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [] (fn [] (if ok (if nested a b) c)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an anonymous function body is checked independently", _134_)
  local function _135_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [] (lambda [] (if ok (if nested a b) c)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a lambda body is checked independently", _135_)
  local function _136_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn run [] (\206\187 [] (if ok (if nested a b) c)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a unicode lambda body is checked independently", _136_)
  local function _137_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (fn [] (if a b c)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a body-level fn with a non-leaf if body is reported", _137_)
  local function _138_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (lambda [] (if a b c)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a body-level lambda with a non-leaf if body is reported", _138_)
  local function _139_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn f [] (\206\187 [] (if a b c)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a body-level unicode lambda with a non-leaf if body is reported", _139_)
  local function _140_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(fn named [] (if a (let [x 1] x) b))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a top-level fn body with a non-leaf if is reported", _140_)
  local function _141_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(local f (fn [] (each [_ x (ipairs xs)] (when x (g x)))))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a local fn with a nested loop body is reported", _141_)
  local function _142_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(local f (lambda [] (if a (let [x 1] x) b)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a local lambda body with a non-leaf if is reported", _142_)
  local function _143_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(local f (\206\187 [] (if a (let [x 1] x) b)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a local unicode lambda body with a non-leaf if is reported", _143_)
  local function _144_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(foo (fn [] (if a (let [x 1] x) b)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a top-level callback fn body with a non-leaf if is reported", _144_)
  local function _145_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(local f (fn [] (if a b c)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a local fn with a single if and leaf branches is clean", _145_)
  local function _146_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn g [] (fn h [] (if a (let [x 1] x) b)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested fn violation is deduplicated under its defn", _146_)
  local function _147_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #function_findings("(defn g [] (fn h [] (if a b c)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a valid nested fn still makes its defn body report once", _147_)
  local function _148_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn f [] (fn [] (g a)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a body-level fn with a leaf call body is clean", _148_)
  local function _149_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [x]\n  (while x (set x false)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a while with a leaf body is clean", _149_)
  local function _150_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [x]\n  (print x)\n  (+ x 1)\n  x)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("several leaf body expressions are clean", _150_)
  local function _151_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = function_findings("(defn run [] '(if x (let [a 1] a) b))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("quoted data is never flagged", _151_)
  local function _152_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"function-shape", "fnl/app.fnl > defn:run > if#1 > then > if#1", "warning"}}
    local actual_7_auto = function_findings("(defn run [] (if x (if y a b) c))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("function-shape defaults to warning", _152_)
  local function _153_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "function body is too deep; move this into a named private function"
    local actual_7_auto = finding_summary(check_source("(defn run [] (if x (if y a b) c))", "fnl/app.fnl", {["module-style"] = "off"}))[1].message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("function-shape uses the approved move-to-private-function message", _153_)
  local function _154_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"function-shape", "fnl/app.fnl > defn:run > if#1 > then > if#1", "error"}}
    local actual_7_auto = findings_for_rule("(defn run [] (if x (if y a b) c))", "fnl/app.fnl", "function-shape", {["module-style"] = "off", ["function-shape"] = "error"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("function-shape severity can be overridden to error", _154_)
  local function _155_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = findings_for_rule("(defn run [] (if x (if y a b) c))", "fnl/app.fnl", "function-shape", {["module-style"] = "off", ["function-shape"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("function-shape can be disabled", _155_)
  local function _156_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"function-shape", "fnl/app.fnl > defn:run > if#1 > then > if#1", "warning"}, {"function-shape", "fnl/app.fnl > defn:run > if#1 > else > if#1", "warning"}}
    local actual_7_auto = function_findings("(defn run []\n  (if x (if y a b) (if z c d)))")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("function-shape findings are unique and deterministic", _156_)
end
require("plenary.busted").describe("function-shape", _89_)
local function _157_()
  local function _158_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["module-style"] = 24, ["spec-macro-import"] = 0, ["spec-no-module"] = 0, ["spec-direct-require"] = 0, ["one-is-per-testing"] = 0, ["core-require"] = 0}
    local actual_7_auto = repo_scenario({["file-size"] = "off"}).counts
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("project Fennel files have the approved rule counts", _158_)
  local function _159_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_scenario(nil)["lint-files"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("lint implementation files are clean", _159_)
  local function _160_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_scenario(nil)["cli-files"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("cli implementation files are clean", _160_)
end
require("plenary.busted").describe("repo-properties", _157_)
local function check_context(source, ctx)
  local lint = load_lint()
  if lint["module-missing"] then
    return lint
  else
    local findings, err = lint.check(source, ctx)
    if findings then
      return findings
    else
      return {["value-nil?"] = true, error = err}
    end
  end
end
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
local function _164_()
  local source = "(defn run [] (if ok (do a b) c))"
  local path = "fnl/app.fnl"
  local rules = {["module-style"] = "off", ["function-shape"] = "off"}
  local baseline = check_context(source, {path = path, rules = rules})
  local form = first_finding_form(baseline, "if-branch-call")
  local function _165_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = check_context(source, {path = path, rules = rules, exclusions = {{rule = "if-branch-call", form = form, reason = "intentional"}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an exclusion suppresses only an exact rule and form match", _165_)
  local function _166_()
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
  require("plenary.busted").it("an exclusion with the same form but a different rule does not suppress", _166_)
  local function _168_()
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
  return require("plenary.busted").it("an exclusion with the same rule but a different form does not suppress", _168_)
end
require("plenary.busted").describe("exclusions", _164_)
local function no_mutation_summary(source, path, rules)
  local result = findings_for_rule(source, path, "no-mutation", rules)
  if (result["module-missing"] or result["value-nil?"]) then
    return result
  else
    local _170_
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
      _170_ = tbl_26_
    end
    local _172_
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
      _172_ = tbl_26_
    end
    return {count = #result, rules = _170_, severities = _172_}
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
local function _178_()
  local function _179_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 1, rules = {"no-mutation"}, severities = {"warning"}}
    local actual_7_auto = no_mutation_summary("(var x 1)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags var in a source file as one warning", _179_)
  local function _180_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 1, rules = {"no-mutation"}, severities = {"warning"}}
    local actual_7_auto = no_mutation_summary("(set x 2)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags set in a source file as one warning", _180_)
  local function _181_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 1, rules = {"no-mutation"}, severities = {"warning"}}
    local actual_7_auto = no_mutation_summary("(set state.x 2)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags a field set in a source file as one warning", _181_)
  local function _182_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 1, rules = {"no-mutation"}, severities = {"warning"}}
    local actual_7_auto = no_mutation_summary("(while ok (g))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags while in a source file as one warning", _182_)
  local function _183_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 2, rules = {"no-mutation", "no-mutation"}, severities = {"warning", "warning"}}
    local actual_7_auto = no_mutation_summary("(while ok (set x 1))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("flags every mutation form in a nested while and set", _183_)
  local function _184_()
    local forms = no_mutation_forms("(defn f [] (let [a (set x 1)] (set y 2)))", "fnl/app.fnl", {["module-style"] = "off"})
    local assert_28_auto = require("luassert")
    local value_29_auto = ((2 == #forms) and (forms[1] ~= forms[2]))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (length forms)) (not= (. forms 1) (. forms 2)))")
    return true
  end
  require("plenary.busted").it("gives nested mutation findings distinct form identities", _184_)
  local function _185_()
    local source = "(defn f [] (let [a (set x 1)] (set y 2)))"
    local first_forms = no_mutation_forms(source, "fnl/app.fnl", {["module-style"] = "off"})
    local second_forms = no_mutation_forms(source, "fnl/app.fnl", {["module-style"] = "off"})
    local assert_5_auto = require("luassert")
    local expected_6_auto = first_forms
    local actual_7_auto = second_forms
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("keeps nested mutation form identities stable across repeated linting", _185_)
  local function _186_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #no_mutation_forms("(macro m [] `(foo ,(set x 1)))", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("lints mutation in unquoted quasiquote code", _186_)
  local function _187_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #no_mutation_forms("`(set x ,y)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not lint mutation in quasiquoted data", _187_)
  local function _188_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = no_mutation_summary("(defn f [] `(outer ,(set x 1) `(set y ,(set z 2))))", "fnl/app.fnl", {["module-style"] = "off"}).count
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("lints only the outer unquote in nested quasiquote data", _188_)
  local function _189_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = no_mutation_summary("(defn f [] `(a `(b ,,(set x 1))))", "fnl/app.fnl", {["module-style"] = "off"}).count
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("lints a double-unquoted mutation at executable depth", _189_)
  local function _190_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = no_mutation_summary("(defn f [] '(foo ,(set x 1)))", "fnl/app.fnl", {["module-style"] = "off"}).count
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not lint mutation inside plain quote", _190_)
  local function _191_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 0, rules = {}, severities = {}}
    local actual_7_auto = no_mutation_summary("(var x 1) (set x 2) (while ok (g))", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not flag mutations in a spec file", _191_)
  local function _192_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 0, rules = {}, severities = {}}
    local actual_7_auto = no_mutation_summary("(local x 1) (tset t :k v) (table.insert xs 1) '(set x 1) (set-foo 1)", "fnl/app.fnl", {["module-style"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not flag non-mutation forms or quoted mutation data", _192_)
  local function _193_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 1, rules = {"no-mutation"}, severities = {"error"}}
    local actual_7_auto = no_mutation_summary("(var x 1)", "fnl/app.fnl", {["module-style"] = "off", ["no-mutation"] = "error"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses error severity when configured", _193_)
  local function _194_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {count = 0, rules = {}, severities = {}}
    local actual_7_auto = no_mutation_summary("(var x 1)", "fnl/app.fnl", {["module-style"] = "off", ["no-mutation"] = "off"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not report when disabled", _194_)
  local function _195_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "avoid mutation (var/set/while); prefer a functional form"
    local actual_7_auto = finding_summary(check_source("(var x 1)", "fnl/app.fnl", {["module-style"] = "off"}))[1].message
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("uses the suggested message", _195_)
end
require("plenary.busted").describe("no-mutation", _178_)
local function repeated_code(count)
  return string.rep("(local x 1)\n", count)
end
local function file_size_findings(source, path, rules, max_code_lines, exclusions)
  local result = check_context(source, {path = path, rules = rules, ["max-code-lines"] = max_code_lines, exclusions = exclusions})
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
local function _199_()
  local function _200_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #file_size_findings(repeated_code(301), "fnl/app.fnl", {["module-style"] = "off"}, nil, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("reports one finding for 301 code lines at the default limit", _200_)
  local function _201_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #file_size_findings(repeated_code(3), "fnl/app.fnl", {["module-style"] = "off"}, 3, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts exactly the configured code-line limit", _201_)
  local function _202_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #file_size_findings(repeated_code(4), "fnl/app.fnl", {["module-style"] = "off"}, 3, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("reports the first line above the configured code-line limit", _202_)
  local function _203_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #file_size_findings("(local a 1)\n\n; comment\n  ; indented comment\n(local b 2)\n;; another comment\n", "fnl/app.fnl", {["module-style"] = "off"}, 2, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not count blank or comment-only lines", _203_)
  local function _204_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #file_size_findings("(local text [[first\nsecond]])", "fnl/app.fnl", {["module-style"] = "off"}, 1, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("counts lines inside a multiline string as code", _204_)
  local function _205_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #file_size_findings(repeated_code(4), "fnl/spec/app_spec.fnl", nil, 3, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not report a spec file", _205_)
  local function _206_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "warning"
    local actual_7_auto = file_size_findings(repeated_code(4), "fnl/app.fnl", {["module-style"] = "off"}, 3, nil)[1].severity
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses warning severity by default", _206_)
  local function _207_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "error"
    local actual_7_auto = file_size_findings(repeated_code(4), "fnl/app.fnl", {["module-style"] = "off", ["file-size"] = "error"}, 3, nil)[1].severity
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses error severity when configured", _207_)
  local function _208_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #file_size_findings(repeated_code(4), "fnl/app.fnl", {["module-style"] = "off", ["file-size"] = "off"}, 3, nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not report when disabled", _208_)
  local function _209_()
    local message = file_size_findings(repeated_code(4), "fnl/app.fnl", {["module-style"] = "off"}, 3, nil)[1].message
    local assert_28_auto = require("luassert")
    local value_29_auto = (string.find(message, "4") and string.find(message, "3"))
    assert_28_auto.is_truthy(value_29_auto, "(and (string.find message \"4\") (string.find message \"3\"))")
    return true
  end
  require("plenary.busted").it("includes the count and limit in the message", _209_)
  local function _210_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "fnl/app.fnl > file"
    local actual_7_auto = file_size_findings(repeated_code(4), "fnl/app.fnl", {["module-style"] = "off"}, 3, nil)[1].form
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses a stable file-level identity", _210_)
  local function _211_()
    local finding = file_size_findings(repeated_code(4), "fnl/app.fnl", {["module-style"] = "off"}, 3, nil)
    local exclusion = {{rule = "file-size", form = finding[1].form, reason = "intentional"}}
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #file_size_findings(repeated_code(4), "fnl/app.fnl", {["module-style"] = "off"}, 3, exclusion)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("an exact file-size exclusion suppresses the finding", _211_)
end
require("plenary.busted").describe("file-size", _199_)
local function _212_()
  local function _213_()
    local source = "(set x 2)"
    local path = "fnl/app.fnl"
    local rules = {["module-style"] = "off"}
    local baseline = check_context(source, {path = path, rules = rules})
    local form = first_finding_form(baseline, "no-mutation")
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = check_context(source, {path = path, rules = rules, exclusions = {{rule = "no-mutation", form = form, reason = "intentional"}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("an exact no-mutation rule and form exclusion suppresses the finding", _213_)
end
require("plenary.busted").describe("no-mutation-exclusions", _212_)
local function _214_()
  local source = "(defn f [] (let [a (set x 1)] (set y 2)))"
  local path = "fnl/app.fnl"
  local rules = {["module-style"] = "off"}
  local baseline = check_context(source, {path = path, rules = rules})
  local form = first_finding_form(baseline, "no-mutation")
  local remaining = check_context(source, {path = path, rules = rules, exclusions = {{rule = "no-mutation", form = form, reason = "intentional"}}})
  local assert_5_auto = require("luassert")
  local expected_6_auto = 1
  local actual_7_auto = #remaining
  assert_5_auto.same(expected_6_auto, actual_7_auto)
  return true
end
return require("plenary.busted").it("an exclusion for one nested mutation leaves the other finding", _214_)
