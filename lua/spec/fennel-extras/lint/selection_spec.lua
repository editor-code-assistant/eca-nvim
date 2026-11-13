-- [nfnl] fnl/spec/fennel-extras/lint/selection_spec.fnl
local function load_selection()
  local ok, result = pcall(require, "fennel-extras.lint.selection")
  if ok then
    return result
  else
    return {["module-missing"] = true}
  end
end
local function parse_name_status(text)
  local selection = load_selection()
  if selection["module-missing"] then
    return selection
  else
    return selection["parse-name-status"](text)
  end
end
local function parse_untracked(text)
  local selection = load_selection()
  if selection["module-missing"] then
    return selection
  else
    return selection["parse-untracked"](text)
  end
end
local function parse_hunks(text)
  local selection = load_selection()
  if selection["module-missing"] then
    return selection
  else
    return selection["parse-hunks"](text)
  end
end
local function form_selected_3f(form, intervals)
  local selection = load_selection()
  if selection["module-missing"] then
    return selection
  else
    return selection["form-selected?"](form, intervals)
  end
end
local function plan(records, untracked)
  local selection = load_selection()
  if selection["module-missing"] then
    return selection
  else
    return selection.plan(records, untracked)
  end
end
local function _7_()
  local function _8_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{status = "M", path = "fnl/a file.fnl", ["old-path"] = nil}, {status = "A", path = "fnl/new\tfile.fnl", ["old-path"] = nil}}
    local actual_7_auto = parse_name_status("M\tfnl/a file.fnl\0A\tfnl/new\tfile.fnl\0")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("parses modified and added paths from NUL-separated name-status output", _8_)
  local function _9_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{status = "R", path = "fnl/new.fnl", ["old-path"] = "fnl/old.fnl"}, {status = "C", path = "fnl/copy.fnl", ["old-path"] = "fnl/source.fnl"}}
    local actual_7_auto = parse_name_status("R100\tfnl/old.fnl\0fnl/new.fnl\0C75\tfnl/source.fnl\0fnl/copy.fnl\0")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("parses rename and copy scores with destination and old paths", _9_)
  local function _10_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = parse_name_status("")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("returns an empty list for empty name-status output", _10_)
end
require("plenary.busted").describe("name-status", _7_)
local function _11_()
  local function _12_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/new file.fnl", "fnl/tab\tfile.fnl"}
    local actual_7_auto = parse_untracked("fnl/new file.fnl\0fnl/tab\tfile.fnl\0")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("parses NUL-separated untracked paths including spaces and tabs", _12_)
  local function _13_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = parse_untracked("")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("returns an empty list for empty untracked output", _13_)
end
require("plenary.busted").describe("untracked", _11_)
local function _14_()
  local function _15_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{start = 4, ["end"] = 5}, {start = 10, ["end"] = 12}}
    local actual_7_auto = parse_hunks("@@ -3,2 +4,2 @@\n@@ -9 +10,3 @@\n")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("parses added and changed new-side line intervals", _15_)
  local function _16_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{start = 7, ["end"] = 7}}
    local actual_7_auto = parse_hunks("@@ -7,2 +7,0 @@\n")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("treats a pure deletion as the new-side point at the deletion location", _16_)
  local function _17_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{start = 12, ["end"] = 12}}
    local actual_7_auto = parse_hunks("@@ -11 +12 @@\n")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("uses one line when an omitted hunk count is present", _17_)
end
require("plenary.busted").describe("hunks", _14_)
local function _18_()
  local function _19_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = true
    local actual_7_auto = form_selected_3f({line = 8, ["end-line"] = 12}, {{start = 12, ["end"] = 14}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("selects a form when its inclusive span overlaps a changed interval", _19_)
  local function _20_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = false
    local actual_7_auto = form_selected_3f({line = 8, ["end-line"] = 11}, {{start = 12, ["end"] = 14}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("does not select a form outside all changed intervals", _20_)
end
require("plenary.busted").describe("form-selection", _18_)
local function _21_()
  local function _22_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {whole = {"a.fnl", "new.fnl", "renamed.fnl"}, hunks = {}, deleted = {"old.fnl"}}
    local actual_7_auto = plan({{status = "A", path = "a.fnl", ["old-path"] = nil}, {status = "R", path = "renamed.fnl", ["old-path"] = "old.fnl"}}, {"new.fnl"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("classifies additions untracked files and rename destinations as whole-file scope", _22_)
  local function _23_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {whole = {}, hunks = {"changed.fnl"}, deleted = {"gone.fnl"}}
    local actual_7_auto = plan({{status = "M", path = "changed.fnl", ["old-path"] = nil}, {status = "D", path = "gone.fnl", ["old-path"] = nil}}, {})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("classifies modifications as hunk scope and deletions as deleted paths", _23_)
  local function _24_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {whole = {"copy.fnl"}, hunks = {}, deleted = {"source.fnl"}}
    local actual_7_auto = plan({{status = "C", path = "copy.fnl", ["old-path"] = "source.fnl"}}, {})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("classifies copied destinations as whole-file scope and old paths as deleted", _24_)
end
return require("plenary.busted").describe("planning", _21_)
