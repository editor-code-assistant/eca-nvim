-- [nfnl] fnl/spec/eca/ui/components/separator_spec.fnl
local separator = require("eca.ui.components.separator")
local function _1_()
  local function _2_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {line = "-----", highlights = {{["hl-group"] = "EcaSeparator", ["col-start"] = 0, ["col-end"] = 5}}}
    local actual_7_auto = separator.render({char = "-", width = 5})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("uses the requested character and width", _2_)
end
return require("plenary.busted").describe("render", _1_)
