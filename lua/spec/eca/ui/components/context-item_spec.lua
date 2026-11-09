-- [nfnl] fnl/spec/eca/ui/components/context-item_spec.fnl
local context_item = require("eca.ui.components.context-item")
local function _1_()
  local function _2_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {text = "@file.lua", ["hl-group"] = "EcaContextFile"}
    local actual_7_auto = context_item.render({text = "@file.lua", ["hl-group"] = "EcaContextFile"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("returns text and its highlight", _2_)
  local function _3_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = ""
    local actual_7_auto = context_item.render({}).text
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("defaults missing text to an empty string", _3_)
end
return require("plenary.busted").describe("render", _1_)
