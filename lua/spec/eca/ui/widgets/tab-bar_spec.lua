-- [nfnl] fnl/spec/eca/ui/widgets/tab-bar_spec.fnl
local tab_bar = require("eca.ui.widgets.tab-bar")
local function _1_()
  local function _2_()
    local canvas
    local function _3_(_, _0, _1)
      return nil
    end
    canvas = {["set-option"] = _3_}
    local widget = tab_bar.create(canvas, {})
    widget["add-tab"]({id = "chat", label = "Chat"})
    widget["add-tab"]({id = "logs", label = "Logs"})
    widget["select-tab"]("logs")
    widget["remove-tab"]("logs")
    local assert_5_auto = require("luassert")
    local expected_6_auto = "chat"
    local actual_7_auto = widget["get-state"]()["active-id"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("selects tabs and falls back after removal", _2_)
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
    local widget = tab_bar.create(canvas, {})
    widget["add-tab"]({id = "chat", label = "Chat"})
    widget["add-tab"]({id = "logs", label = "Logs"})
    widget.render()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{"global", "tabline", "%#EcaTabActive# Chat %#Normal#\226\148\130%#EcaTabInactive# Logs "}, {"global", "showtabline", 2}}
    local actual_7_auto = options
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("writes tabline options with active and inactive tab formatting", _5_)
end
return require("plenary.busted").describe("render", _4_)
