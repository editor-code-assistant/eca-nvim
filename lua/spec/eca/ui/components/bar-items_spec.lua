-- [nfnl] fnl/spec/eca/ui/components/bar-items_spec.fnl
local bar_items = require("eca.ui.components.bar-items")
local function _1_()
  local function _2_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = " %#EcaHeaderKey#Model%#EcaHeaderValue#:Claude"
    local actual_7_auto = bar_items.render({items = {{title = "Model", value = "Claude"}}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("renders a single titled item", _2_)
  local function _3_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = ""
    local actual_7_auto = bar_items.render({items = {}})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("renders an empty list as an empty string", _3_)
end
return require("plenary.busted").describe("render", _1_)
