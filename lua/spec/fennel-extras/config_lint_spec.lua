-- [nfnl] fnl/spec/fennel-extras/config_lint_spec.fnl
local function _1_()
  local function _2_()
    local lines = vim.fn.systemlist("scripts/fennel-extras lint fnl/fennel-extras/config.fnl")
    local code = vim.v.shell_error
    local assert_28_auto = require("luassert")
    local value_29_auto = ((0 == code) and (#lines > 0) and string.find(table.concat(lines, "\n"), "Keep or operands simple; extract conditional logic into private functions."))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 0 code) (> (length lines) 0) (string.find (table.concat lines \"\\n\") \"Keep or operands simple; extract conditional logic into private functions.\"))")
    return true
  end
  return require("plenary.busted").it("returns exit 0 with warning diagnostics for the canonical config", _2_)
end
return require("plenary.busted").describe("canonical-config-lint-diagnostics", _1_)
