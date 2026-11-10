-- [nfnl] fnl/spec/fennel-extras/config_lint_spec.fnl
local function _1_()
  local function _2_()
    local lines = vim.fn.systemlist("scripts/fennel-extras lint fnl/fennel-extras/config.fnl")
    local code = vim.v.shell_error
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("returns zero exit status", _2_)
  local function _3_()
    local lines = vim.fn.systemlist("scripts/fennel-extras lint fnl/fennel-extras/config.fnl")
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #lines
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("reports no lint findings", _3_)
end
return require("plenary.busted").describe("canonical-config-is-lint-clean", _1_)
