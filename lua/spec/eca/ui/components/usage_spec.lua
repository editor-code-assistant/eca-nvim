-- [nfnl] fnl/spec/eca/ui/components/usage_spec.fnl
local usage = require("eca.ui.components.usage")
local function _1_()
  local function _2_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {text = "31K/200K ($0.03)", ["hl-group"] = "EcaUsage"}
    local actual_7_auto = usage.render({text = "31K/200K ($0.03)", ["hl-group"] = "EcaUsage"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("preserves formatted usage text and highlight", _2_)
end
return require("plenary.busted").describe("render", _1_)
