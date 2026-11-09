-- [nfnl] fnl/spec/eca/ui/highlights_spec.fnl
local highlights = require("eca.ui.highlights")
local function _1_()
  local function _2_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"WarningMsg", "DiagnosticOk"}
    local actual_7_auto = {highlights.groups.EcaSpinner.link, highlights.groups.EcaButtonAccept.link}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("exposes the public highlight names", _2_)
end
return require("plenary.busted").describe("groups", _1_)
