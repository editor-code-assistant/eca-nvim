-- [nfnl] fnl/spec/eca/ui/components/key-value_spec.fnl
local key_value = require("eca.ui.components.key-value")
local function _1_()
  local function _2_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {line = "model:Claude", highlights = {{["hl-group"] = "EcaHeaderKey", ["col-start"] = 0, ["col-end"] = 5}, {["hl-group"] = "EcaHeaderValue", ["col-start"] = 6, ["col-end"] = 12}}}
    local actual_7_auto = key_value.render({title = "model", value = "Claude"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("renders the line and zero-based end-exclusive ranges", _2_)
end
return require("plenary.busted").describe("render", _1_)
