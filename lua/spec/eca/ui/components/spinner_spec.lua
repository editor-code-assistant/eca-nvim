-- [nfnl] fnl/spec/eca/ui/components/spinner_spec.fnl
local spinner = require("eca.ui.components.spinner")
local function _1_()
  local function _2_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 10
    local actual_7_auto = spinner["frame-count"]()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("exposes the number of frames", _2_)
  local function _3_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"\226\160\139", "\226\160\139"}
    local actual_7_auto = {spinner.render({frame = 0}).text, spinner.render({frame = 10}).text}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("wraps the zero-based frame index", _3_)
end
return require("plenary.busted").describe("render", _1_)
