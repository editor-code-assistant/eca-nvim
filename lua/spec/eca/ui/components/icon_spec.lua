-- [nfnl] fnl/spec/eca/ui/components/icon_spec.fnl
local icon = require("eca.ui.components.icon")
local function _1_()
  local function _2_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {text = "\226\156\133", ["hl-group"] = "Normal"}
    local actual_7_auto = icon.render({name = "success"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("renders a named icon", _2_)
  local function _3_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "custom"
    local actual_7_auto = icon.render({name = "success", text = "custom"}).text
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("direct text overrides the named icon", _3_)
end
return require("plenary.busted").describe("render", _1_)
