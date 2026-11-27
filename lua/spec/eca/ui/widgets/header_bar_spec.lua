-- [nfnl] fnl/spec/eca/ui/widgets/header_bar_spec.fnl
local header_bar = require("eca.ui.widgets.header-bar")
local function with_cleanup(cleanup, f)
  local ok, result = pcall(f)
  cleanup()
  if ok then
    return result
  else
    return error(result, 0)
  end
end
local function render_scenario(f)
  local original_option = vim.api.nvim_set_option_value
  local original_lines = vim.api.nvim_buf_set_lines
  local calls = {options = {}, lines = {}}
  local function _2_(name, value, opts)
    return table.insert(calls.options, {name, value, opts})
  end
  vim.api.nvim_set_option_value = _2_
  local function _3_(buf_id, start, _end, strict, lines)
    return table.insert(calls.lines, {buf_id, start, _end, strict, lines})
  end
  vim.api.nvim_buf_set_lines = _3_
  local function _4_()
    vim.api.nvim_set_option_value = original_option
    vim.api.nvim_buf_set_lines = original_lines
    return nil
  end
  local function _5_()
    local widget = header_bar.create(1, 2, {{value = "x"}})
    local result = widget.render()
    return f(calls, result, widget["line-count"]())
  end
  return with_cleanup(_4_, _5_)
end
local function _6_()
  local function _7_()
    local options = {}
    local canvas
    local function _8_(_, name, value)
      return table.insert(options, {name, value})
    end
    canvas = {["set-option"] = _8_}
    local widget = header_bar.create(1, 2, {{value = "x"}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {items = {{value = "x"}}, ["line-count"] = 1}
    local actual_7_auto = {items = widget["get-state"](), ["line-count"] = widget["line-count"]()}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("exposes initial items and fixed line count", _7_)
end
require("plenary.busted").describe("state", _6_)
local function _9_()
  local function _10_()
    local function _11_(calls, result, line_count)
      local assert_5_auto = require("luassert")
      local expected_6_auto = {options = {{"winbar", " %#EcaHeaderValue#x", {win = 2}}}, lines = {{1, 0, 1, false, {""}}}, result = 1, ["line-count"] = 1}
      local actual_7_auto = {options = calls.options, lines = calls.lines, result = result, ["line-count"] = line_count}
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return render_scenario(_11_)
  end
  return require("plenary.busted").it("writes the winbar and spacing line and returns one line", _10_)
end
return require("plenary.busted").describe("render", _9_)
