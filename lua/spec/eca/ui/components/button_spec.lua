-- [nfnl] fnl/spec/eca/ui/components/button_spec.fnl
local button = require("eca.ui.components.button")
local function _1_()
  local function _2_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {text = "Accept (a)", ["hl-group"] = "EcaButtonAccept"}
    local actual_7_auto = button.render({label = "Accept", keybind = "a"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("includes a keybind when supplied", _2_)
  local function _3_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "EcaButtonReject"
    local actual_7_auto = button.render({label = "Reject", ["hl-group"] = "EcaButtonReject"})["hl-group"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("uses the requested highlight", _3_)
end
return require("plenary.busted").describe("render", _1_)
