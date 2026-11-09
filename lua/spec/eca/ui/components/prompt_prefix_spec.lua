-- [nfnl] fnl/spec/eca/ui/components/prompt_prefix_spec.fnl
local prompt_prefix = require("eca.ui.components.prompt-prefix")
local function _1_()
  local function _2_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {text = "> ", ["hl-group"] = "EcaPromptPrefix"}
    local actual_7_auto = prompt_prefix.render({["loading?"] = false})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("renders the idle prompt", _2_)
  local function _3_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {text = "\226\143\179 ", ["hl-group"] = "EcaPromptPrefixLoading"}
    local actual_7_auto = prompt_prefix.render({["loading?"] = true})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("renders the loading prompt", _3_)
end
return require("plenary.busted").describe("render", _1_)
