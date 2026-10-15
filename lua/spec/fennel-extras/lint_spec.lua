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
local function collect_repo_findings(lint, counts, lint_files)
  for _, path in ipairs(project_fennel_files()) do
    local source = read_source(path)
    if source.error then
      table.insert(lint_files, path)
    else
      local findings = lint.check(source, {path = path})
      for _0, finding in ipairs(findings) do
        if counts[finding.rule] then
          counts[finding.rule] = (counts[finding.rule] + 1)
        else
        end
      end
      if string.find(path, "^fnl/fennel%-extras/lint") then
        for _0, finding in ipairs(findings) do
          table.insert(lint_files, {path, finding.rule})
        end
      else
      end
    end
  end
  return {counts = counts, ["lint-files"] = lint_files}
end
local function repo_scenario()
  local lint = load_lint()
  local counts = {["module-style"] = 0, ["spec-macro-import"] = 0, ["spec-no-module"] = 0, ["spec-direct-require"] = 0, ["one-is-per-testing"] = 0, ["core-require"] = 0}
  local lint_files = {}
  if lint["module-missing"] then
    return {["module-missing"] = true}
  else
    return collect_repo_findings(lint, counts, lint_files)
  end
end
local function _19_()
  local function _20_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)", "fnl/app.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a compliant non-spec module is clean", _20_)
  local function _21_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/legacy.fnl > file", "error"}}
    local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(defn run [] 1)", "fnl/legacy.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a non-spec file without a module form has one file finding", _21_)
  local function _22_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/legacy.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(local x 1)", "fnl/legacy.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a non-spec file containing only a local still has one file finding", _22_)
  local function _23_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/legacy.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(if ok a b)", "fnl/legacy.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a non-spec file containing only an if still has one file finding", _23_)
  local function _24_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a module without the aniseed import has one file finding", _24_)
  local function _25_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = forms_for("(import-macros {: module : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)", "fnl/app.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a module-style file missing def in the macro import is reported", _25_)
  local function _26_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(if ok (module app) x)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested module form is reported in a non-spec file", _26_)
  local function _27_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(if ok (import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed) x)\n(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested aniseed import is reported in a non-spec file", _27_)
  local function _28_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n'(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a quoted top-level module form is reported as non-module style", _28_)
  local function _29_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n`(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a quasiquoted top-level module form is reported as non-module style", _29_)
  local function _30_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n,(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an unquoted top-level module form is reported as non-module style", _30_)
  local function _31_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n#(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a hashfn top-level module form is reported as non-module style", _31_)
  local function _32_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/app.fnl > file", "error"}}
    local actual_7_auto = findings_for_rule("'(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)", "fnl/app.fnl", "module-style")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a prefixed aniseed import with a real module is reported as non-module style", _32_)
  local function _33_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(module app)\n;; between top-level forms\n(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)", "fnl/app.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("top-level module and import forms stay clean in either order with comments", _33_)
  local function _34_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"module-style", "fnl/legacy.fnl > file", "error"}}
    local actual_7_auto = forms_for("(fn run [] 1)\n{:run run}", "fnl/legacy.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a legacy fn and final table are reported as non-module style", _34_)
  local function _35_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"works\" (is true)))", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("module-style never applies to spec files", _35_)
end
require("plenary.busted").describe("module-style", _19_)
local function _36_()
  local function _37_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("the approved spec macro import is clean", _37_)
  local function _38_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing} :spec.eca.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec macro import missing is is reported", _38_)
  local function _39_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :other.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec macro import from another module is reported", _39_)
  local function _40_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = forms_for("(deftest run (is true))", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec with no macro import has the spec identity", _40_)
  local function _41_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = findings_for_rule("'(import-macros {: deftest : testing : is} :spec.eca.macros)", "fnl/spec/app_spec.fnl", "spec-macro-import")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a prefixed spec macro import is reported", _41_)
  local function _42_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/x_spec.fnl > spec", "error"}}
    local actual_7_auto = findings_for_rule("(do (import-macros {: deftest : testing : is} :spec.eca.macros))\n(deftest run (testing \"works\" (is true)))", "fnl/spec/x_spec.fnl", "spec-macro-import")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested spec macro import is reported", _42_)
  local function _43_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = forms_for("(import-macros {: deftest} :other) (deftest t (testing \"x\" (is true)))", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a wrong macro import is reported independently of test content", _43_)
  local function _44_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-macro-import", "fnl/spec/app_spec.fnl > spec", "error"}}
    local actual_7_auto = forms_for("(require :foo)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a spec with only a direct require still has the spec identity", _44_)
  local function _45_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"spec-no-module", "fnl/spec/app_spec.fnl > module:app", "error"}}
    local actual_7_auto = forms_for("(module app)\n(import-macros {: deftest : testing : is} :spec.eca.macros)", "fnl/spec/app_spec.fnl", nil)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a module form in a spec is reported at that form", _45_)
  local function _46_()
    local function _47_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"spec-direct-require", "fnl/spec/app_spec.fnl > top#1", "error"}}
      local actual_7_auto = findings_for_rule("(require :plenary.busted)", "fnl/spec/app_spec.fnl", "spec-direct-require")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("keyword plenary require is forbidden in ordinary specs", _47_)
    local function _48_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"spec-direct-require", "fnl/spec/app_spec.fnl > top#1", "error"}}
      local actual_7_auto = findings_for_rule("(require \"luassert\")", "fnl/spec/app_spec.fnl", "spec-direct-require")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("string luassert require is forbidden in ordinary specs", _48_)
    local function _49_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(require :plenary.busted)\n(require \"luassert\")", "fnl/spec/eca/macros.fnlm", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("the spec macro implementation may require test libraries directly", _49_)
    local function _50_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module ordinary)\n(require :plenary.busted)\n(require \"luassert\")", "fnl/ordinary.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("direct test-library requires are not a non-spec finding", _50_)
  end
  require("plenary.busted").describe("spec-direct-require", _46_)
  local function _51_()
    local function _52_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"one\" (is true)))", "fnl/spec/app_spec.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("one direct is in testing is clean", _52_)
    local function _53_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: deftest : testing : is} :spec.eca.macros)\n(deftest run (testing \"one\" (let [x 1] (is (= x 1)))))", "fnl/spec/app_spec.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("one is inside a let wrapper is clean", _53_)
    local function _54_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"none\" (let [x 1] x)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("testing with no is is reported", _54_)
    local function _55_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"two\" (is true) (is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("testing with two is forms is reported once", _55_)
    local function _56_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"outer\" (testing \"inner\" (is true))))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("nested testing forms are counted separately", _56_)
    local function _57_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"quoted\" '(is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("quoted is data is not counted", _57_)
    local function _58_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" '\n ;; comment\n (is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quoted is separated by a comment is not counted", _58_)
    local function _59_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" `\n(is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quasiquoted is separated by a newline is not counted", _59_)
    local function _60_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" ' (is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quoted is separated by whitespace is not counted", _60_)
    local function _61_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"x\" '(is false) (is true)))", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a quoted is plus an executable is is counted once", _61_)
    local function _62_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"one-is-per-testing", "fnl/spec/app_spec.fnl > deftest:run > testing#1", "error"}}
      local actual_7_auto = findings_for_rule("(deftest run (testing \"is in text\" (print \"is\"))) ;; is\n", "fnl/spec/app_spec.fnl", "one-is-per-testing")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("strings and comments containing is are not counted", _62_)
  end
  require("plenary.busted").describe("one-is-per-testing", _51_)
  local function _63_()
    local function _64_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "warning"}}
      local actual_7_auto = findings_for_rule("(defn run [] (if ok (do a b) c))", "fnl/app.fnl", "if-branch-call")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a multi-expression then do is a warning", _64_)
    local function _65_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(defn run [] (if ok (do a) c))", "fnl/app.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a one-expression do is clean", _65_)
    local function _66_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(defn run [] (if ok (let [x 1] x) (set x 1)))", "fnl/app.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("let and set branches are clean", _66_)
    local function _67_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > else", "warning"}, {"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "warning"}}
      local actual_7_auto
      do
        local findings = findings_for_rule("(defn run [] (if ok (do a b) (do c d)))", "fnl/app.fnl", "if-branch-call")
        local function _68_(a, b)
          return (a[2] < b[2])
        end
        table.sort(findings, _68_)
        actual_7_auto = findings
      end
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("both multi-expression branches have distinct identities", _67_)
    local function _69_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "warning"}, {"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then#2", "warning"}}
      local actual_7_auto = findings_for_rule("(defn run [] (if a (do x y) b (do c d) e))", "fnl/app.fnl", "if-branch-call")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("multi-clause then branches use both then identities", _69_)
    local function _70_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(defn run [] (if ok (let [x 1] (do a b)) c))", "fnl/app.fnl", nil)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a do nested below a non-do branch root is clean", _70_)
    local function _71_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "error"}}
      local actual_7_auto = findings_for_rule("(defn run [] (if ok (do a b) c))", "fnl/app.fnl", "if-branch-call", {["if-branch-call"] = "error"})
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("if branch severity can be overridden to error", _71_)
    local function _72_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = findings_for_rule("(defn run [] (if ok (do a b) c))", "fnl/app.fnl", "if-branch-call", {["if-branch-call"] = "off"})
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("if branch rule can be disabled", _72_)
    local function _73_()
      local function _74_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {}
        local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(local core (require :eca.nfnl.core))", "fnl/app.fnl", nil)
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("the core local binding uses the canonical name", _74_)
      local function _75_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"core-require", "fnl/app.fnl > local:core", "error"}}
        local actual_7_auto = findings_for_rule("(local core (require :eca.nfnl.core) other)", "fnl/app.fnl", "core-require")
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("a core local with extra expressions is reported", _75_)
      local function _76_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {}
        local actual_7_auto = forms_for("(import-macros {: module : def : defn : defn-} :eca.nfnl.macros.aniseed)\n(module app)\n(local core (require \"eca.nfnl.core\"))", "fnl/app.fnl", nil)
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("a string core local binding uses the canonical shape", _76_)
      local function _77_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"core-require", "fnl/app.fnl > local:c", "error"}}
        local actual_7_auto = findings_for_rule("(local c (require :eca.nfnl.core))", "fnl/app.fnl", "core-require")
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("a non-core local binding is reported", _77_)
      local function _78_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"core-require", "fnl/app.fnl > top#1", "error"}}
        local actual_7_auto = findings_for_rule("(require :eca.nfnl.core extra)", "fnl/app.fnl", "core-require")
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("a keyword core require with extra expressions is reported", _78_)
      local function _79_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"core-require", "fnl/app.fnl > top#1", "error"}}
        local actual_7_auto = findings_for_rule("(require \"eca.nfnl.core\" extra)", "fnl/app.fnl", "core-require")
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      return require("plenary.busted").it("a string core require with extra expressions is reported", _79_)
    end
    require("plenary.busted").describe("core-require", _73_)
    local function _80_()
      local function _81_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "warning"}, {"if-branch-call", "fnl/app.fnl > defn:run > if#1 > else", "warning"}}
        local actual_7_auto = finding_identities(check_source("(defn run [] (if ok (do a b) (do c d)))", "fnl/app.fnl", {["module-style"] = "off"}))
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("the same source produces identical sorted findings", _81_)
      local function _82_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {findings = {{"if-branch-call", "fnl/app.fnl > defn:run > if#1 > then", "warning"}, {"if-branch-call", "fnl/app.fnl > defn:run > if#1 > else", "warning"}}, duplicates = {}}
        local actual_7_auto
        do
          local findings = finding_identities(check_source("(defn run [] (if ok (do a b) (do c d)))", "fnl/app.fnl", {["module-style"] = "off"}))
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
      require("plenary.busted").it("no two findings share path rule and form", _82_)
      local function _84_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {{"core-require", "fnl/app.fnl > top#1", "error"}}
        local actual_7_auto = findings_for_rule("(require :eca.nfnl.core extra)\n(vim.api.nvim_set_option_value :x 1 {})", "fnl/app.fnl", "core-require")
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("the pure core returns findings without executing vim api text", _84_)
      local function _85_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {["value-nil?"] = true, message = "missing closing delimiter", line = 1, col = 1}
        local actual_7_auto = check_source("(unclosed", "fnl/bad.fnl", nil)
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      return require("plenary.busted").it("reader failure returns nil and a structured error table", _85_)
    end
    return require("plenary.busted").describe("determinism-and-boundary", _80_)
  end
  return require("plenary.busted").describe("if-branch-call", _63_)
end
require("plenary.busted").describe("spec-shape", _36_)
local function _86_()
  local function _87_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["module-style"] = 24, ["spec-macro-import"] = 0, ["spec-no-module"] = 0, ["spec-direct-require"] = 0, ["one-is-per-testing"] = 0, ["core-require"] = 0}
    local actual_7_auto = repo_scenario().counts
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("project Fennel files have the approved rule counts", _87_)
  local function _88_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_scenario()["lint-files"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("lint implementation files are clean", _88_)
end
require("plenary.busted").describe("repo-properties", _86_)
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
local function _92_()
  local source = "(defn run [] (if ok (do a b) c))"
  local path = "fnl/app.fnl"
  local rules = {["module-style"] = "off"}
  local baseline = check_context(source, {path = path, rules = rules})
  local form = first_finding_form(baseline, "if-branch-call")
  local function _93_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = check_context(source, {path = path, rules = rules, exclusions = {{rule = "if-branch-call", form = form, reason = "intentional"}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an exclusion suppresses only an exact rule and form match", _93_)
  local function _94_()
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
  require("plenary.busted").it("an exclusion with the same form but a different rule does not suppress", _94_)
  local function _96_()
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
  return require("plenary.busted").it("an exclusion with the same rule but a different form does not suppress", _96_)
end
return require("plenary.busted").describe("exclusions", _92_)
