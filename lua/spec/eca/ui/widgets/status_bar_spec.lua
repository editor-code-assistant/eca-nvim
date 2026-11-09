-- [nfnl] fnl/spec/eca/ui/widgets/status_bar_spec.fnl
local status_bar = require("eca.ui.widgets.status-bar")
local function _1_()
  local function _2_()
    local canvas
    local function _3_(_, _0, _1)
      return nil
    end
    canvas = {["set-option"] = _3_}
    local widget = status_bar.create(canvas, {left = {{text = "L", ["hl-group"] = "EcaHeaderKey"}}})
    widget.update({right = {{text = "R"}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {left = 1, right = "R"}
    local actual_7_auto = {left = #widget["get-state"]().left, right = widget["get-state"]().right[1].text}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("updates one status section without losing the initial one", _2_)
end
require("plenary.busted").describe("state", _1_)
local function _4_()
  local function _5_()
    local options = {}
    local canvas
    local function _6_(_, scope, name, value)
      return table.insert(options, {scope, name, value})
    end
    canvas = {["set-option"] = _6_}
    local widget = status_bar.create(canvas, {left = {{text = "L", ["hl-group"] = "EcaHeaderKey"}}, right = {{text = "R"}}})
    widget.render()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"win", "statusline", "%#EcaHeaderKey# L %=%=%#Normal# R "}}
    local actual_7_auto = options
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("writes the formatted sections to the window statusline", _5_)
end
return require("plenary.busted").describe("render", _4_)
