-- [nfnl] fnl/spec/eca/ui/widgets/context_bar_spec.fnl
local context_bar = require("eca.ui.widgets.context-bar")
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
  local original_lines = vim.api.nvim_buf_set_lines
  local original_mark = vim.api.nvim_buf_set_extmark
  local calls = {namespace = {}, lines = {}, extmarks = {}}
  local function _2_(name)
    table.insert(calls.namespace, name)
    return 8
  end
  vim.api.nvim_create_namespace = _2_
  local function _3_(buf_id, start, _end, strict, lines)
    return table.insert(calls.lines, {buf_id, start, _end, strict, lines})
  end
  vim.api.nvim_buf_set_lines = _3_
  local function _4_(buf_id, ns, line, col, opts)
    return table.insert(calls.extmarks, {buf_id, ns, line, col, opts})
  end
  vim.api.nvim_buf_set_extmark = _4_
  local function _5_()
    vim.api.nvim_create_namespace = original_create
    vim.api.nvim_buf_set_lines = original_lines
    vim.api.nvim_buf_set_extmark = original_mark
    return nil
  end
  local function _6_()
    local widget = context_bar.create(2)
    widget.add({text = "@file", ["hl-group"] = "EcaContextFile"})
    widget.render(3)
    return f(calls)
  end
  return with_cleanup(_5_, _6_)
end
local function _7_()
  local function _8_()
    local widget = context_bar.create(1)
    widget.add({text = "@file", ["hl-group"] = "EcaContextFile"})
    widget.add({text = "@file", ["hl-group"] = "EcaContextFile"})
    widget.clear()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = #widget["get-state"]().items
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("deduplicates and clears context items", _8_)
end
require("plenary.busted").describe("state", _7_)
local function _9_()
  local function _10_()
    local function _11_(calls)
      local assert_5_auto = require("luassert")
      local expected_6_auto = {namespace = {"eca-context-bar"}, lines = {{2, 3, 4, false, {"@file"}}}, extmarks = {{2, 8, 3, 0, {end_col = 5, hl_group = "EcaContextFile"}}}}
      local actual_7_auto = {namespace = calls.namespace, lines = calls.lines, extmarks = calls.extmarks}
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return render_scenario(_11_)
  end
  return require("plenary.busted").it("writes the context line and highlight through the public renderer", _10_)
end
return require("plenary.busted").describe("render", _9_)
