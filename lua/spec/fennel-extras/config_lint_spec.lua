-- [nfnl] fnl/spec/fennel-extras/config_lint_spec.fnl
local function _1_()
  local function _2_()
    local lines = vim.fn.systemlist("scripts/fennel-extras lint fnl/fennel-extras/config.fnl")
    local code = vim.v.shell_error
    local assert_28_auto = require("luassert")
    local value_29_auto = ((0 == code) and (#lines > 0))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 0 code) (> (length lines) 0))")
    return true
  end
  require("plenary.busted").it("reports warning findings for canonical form-chain violations with exit 0", _2_)
  local function _3_()
    local lines = vim.fn.systemlist("scripts/fennel-extras lint fnl/fennel-extras/config.fnl")
    local assert_28_auto = require("luassert")
    local value_29_auto = string.match((lines[1] or ""), "form%-chain: form is outside the allowed form chain")
    assert_28_auto.is_truthy(value_29_auto, "(string.match (or (. lines 1) \"\") \"form%-chain: form is outside the allowed form chain\")")
    return true
  end
  return require("plenary.busted").it("reports structured form-chain findings instead of crashing", _3_)
end
return require("plenary.busted").describe("canonical-config-lint-diagnostics", _1_)
