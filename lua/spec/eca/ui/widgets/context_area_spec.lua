-- [nfnl] fnl/spec/eca/ui/widgets/context_area_spec.fnl
local context_area = require("eca.ui.widgets.context-area")
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
  local original_create = vim.api.nvim_create_namespace
  local original_clear = vim.api.nvim_buf_clear_namespace
  local original_lines = vim.api.nvim_buf_set_lines
  local original_mark = vim.api.nvim_buf_set_extmark
  local calls = {namespace = {}, clear = {}, lines = {}, extmarks = {}}
  local function _2_(name)
    table.insert(calls.namespace, name)
    return 7
  end
  vim.api.nvim_create_namespace = _2_
  local function _3_(buf_id, ns, start, _end)
    return table.insert(calls.clear, {buf_id, ns, start, _end})
  end
  vim.api.nvim_buf_clear_namespace = _3_
  local function _4_(buf_id, start, _end, strict, lines)
    return table.insert(calls.lines, {buf_id, start, _end, strict, lines})
  end
  vim.api.nvim_buf_set_lines = _4_
  local function _5_(buf_id, ns, line, col, opts)
    return table.insert(calls.extmarks, {buf_id, ns, line, col, opts})
  end
  vim.api.nvim_buf_set_extmark = _5_
  local function _6_()
    vim.api.nvim_create_namespace = original_create
    vim.api.nvim_buf_clear_namespace = original_clear
    vim.api.nvim_buf_set_lines = original_lines
    vim.api.nvim_buf_set_extmark = original_mark
    return nil
  end
  local function _7_()
    local widget = context_area.create(3)
    widget.add({text = "@file", ["hl-group"] = "EcaContextFile"})
    local result = widget.render(4)
    return f(calls, result, widget["get-end-line"]())
  end
  return with_cleanup(_6_, _7_)
end
local function _8_()
  local function _9_()
    local widget = context_area.create(1)
    widget.add({text = "@file", ["hl-group"] = "EcaContextFile"})
    widget.remove("@file")
    local assert_5_auto = require("luassert")
    local expected_6_auto = false
    local actual_7_auto = widget["has-items?"]()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("tracks unique context items", _9_)
end
require("plenary.busted").describe("state", _8_)
local function _10_()
  local function _11_()
    local function _12_(calls, result, end_line)
      local assert_5_auto = require("luassert")
      local expected_6_auto = {namespace = {"eca-context-area"}, clear = {{3, 7, 0, -1}}, lines = {{3, 4, 4, false, {"@file"}}}, extmarks = {{3, 7, 4, 0, {end_col = 5, hl_group = "EcaContextFile"}}}, result = 1, ["end-line"] = 5}
      local actual_7_auto = {namespace = calls.namespace, clear = calls.clear, lines = calls.lines, extmarks = calls.extmarks, result = result, ["end-line"] = end_line}
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return render_scenario(_12_)
  end
  return require("plenary.busted").it("writes the context line and highlight and returns its line count", _11_)
end
return require("plenary.busted").describe("render", _10_)
