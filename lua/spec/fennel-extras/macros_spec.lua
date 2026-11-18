-- [nfnl] fnl/spec/fennel-extras/macros_spec.fnl
local function _1_()
  local function _2_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "first"
    local actual_7_auto
    if false then
      actual_7_auto = "never"
    else
      if true then
        actual_7_auto = "first"
      else
        actual_7_auto = "later"
      end
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("selects the first matching branch in source order", _2_)
  local function _5_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "fallback"
    local actual_7_auto
    if false then
      actual_7_auto = "first"
    else
      if false then
        actual_7_auto = "second"
      else
        actual_7_auto = "fallback"
      end
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("uses the explicit fallback when no branch matches", _5_)
end
return require("plenary.busted").describe("cond-macro", _1_)
