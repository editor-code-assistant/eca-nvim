-- [nfnl] fnl/spec/eca/ui/components/message_spec.fnl
local message = require("eca.ui.components.message")
local function _1_()
  local function _2_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"> hello", "world", "", ""}
    local actual_7_auto = message.render({content = "hello\nworld", prefix = "> "}).lines
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("prefixes the first line and highlights each rendered line", _2_)
  local function _3_()
    local result = message.render({content = "hello", ["collapsed?"] = true})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lines = {"\226\150\184 hello", ""}, highlight = result.highlights[1]}
    local actual_7_auto = {lines = result.lines, highlight = {["line-idx"] = 0, ["hl-group"] = "EcaExpandableLabel", ["col-start"] = 0, ["col-end"] = 4}}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("renders collapsed content with its label range", _3_)
end
return require("plenary.busted").describe("render", _1_)
