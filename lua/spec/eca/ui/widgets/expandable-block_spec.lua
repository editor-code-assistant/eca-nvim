-- [nfnl] fnl/spec/eca/ui/widgets/expandable-block_spec.fnl
local expandable = require("eca.ui.widgets.expandable-block")
local function _1_()
  local function _2_()
    local canvas
    local function _3_(_)
      return 1
    end
    local function _4_(_, _0, _1)
      return nil
    end
    local function _5_(_, _0, _1, _2)
      return nil
    end
    canvas = {["create-namespace"] = _3_, ["set-lines"] = _4_, ["add-extmark"] = _5_}
    local widget = expandable.create(canvas, {id = "x", label = "Details", content = {"one"}})
    widget.expand()
    widget["update-label"]("More")
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["expanded?"] = true, label = "More"}
    local actual_7_auto = {["expanded?"] = widget["get-state"]()["expanded?"], label = widget["get-state"]().label}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("supports expansion and label updates", _2_)
end
require("plenary.busted").describe("state", _1_)
local function _6_()
  local function _7_()
    local calls = {namespace = {}, lines = {}, extmarks = {}}
    local canvas
    local function _8_(_, name)
      table.insert(calls.namespace, name)
      return 4
    end
    local function _9_(_, start, _end, lines)
      return table.insert(calls.lines, {start, _end, lines})
    end
    local function _10_(_, ns, line, col, opts)
      return table.insert(calls.extmarks, {ns, line, col, opts})
    end
    canvas = {["create-namespace"] = _8_, ["set-lines"] = _9_, ["add-extmark"] = _10_}
    local widget = expandable.create(canvas, {id = "x", label = "Details", content = {"one", "two"}})
    widget.expand()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {namespace = {"eca-expandable-x"}, lines = {{5, 5, {"\226\143\183 Details", "  one", "  two"}}}, extmarks = {{4, 5, 0, {end_col = 11, hl_group = "EcaExpandableLabel"}}}, ["line-count"] = 3}
    local actual_7_auto = {namespace = calls.namespace, lines = calls.lines, extmarks = calls.extmarks, ["line-count"] = widget.render(5)}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("writes the expanded label and content with a label extmark", _7_)
end
return require("plenary.busted").describe("render", _6_)
