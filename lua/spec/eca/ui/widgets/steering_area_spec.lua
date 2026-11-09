-- [nfnl] fnl/spec/eca/ui/widgets/steering_area_spec.fnl
local steering_area = require("eca.ui.widgets.steering-area")
local function with_cleanup(cleanup, f)
  local ok, result = pcall(f)
  cleanup()
  if ok then
    return result
  else
    return error(result, 0)
  end
end
local function _2_()
  local function _3_()
    local widget = steering_area.create(1)
    widget["set-items"]({"check this"})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"check this"}
    local actual_7_auto = widget["get-state"]().items
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("tracks queued steering items", _3_)
end
require("plenary.busted").describe("state", _2_)
local function _4_()
  local function _5_()
    local original_create_namespace = vim.api.nvim_create_namespace
    local original_clear_namespace = vim.api.nvim_buf_clear_namespace
    local original_set_lines = vim.api.nvim_buf_set_lines
    local original_set_extmark = vim.api.nvim_buf_set_extmark
    local original_get_cursor = vim.api.nvim_win_get_cursor
    local namespace_calls = {}
    local clear_calls = {}
    local line_calls = {}
    local extmark_calls = {}
    local function _6_(name)
      table.insert(namespace_calls, name)
      return 42
    end
    vim.api.nvim_create_namespace = _6_
    local function _7_(buf_id, ns, start, _end)
      return table.insert(clear_calls, {buf_id, ns, start, _end})
    end
    vim.api.nvim_buf_clear_namespace = _7_
    local function _8_(buf_id, start, _end, strict, lines)
      return table.insert(line_calls, {buf_id, start, _end, strict, lines})
    end
    vim.api.nvim_buf_set_lines = _8_
    local function _9_(buf_id, ns, line, col, opts)
      return table.insert(extmark_calls, {buf_id, ns, line, col, opts})
    end
    vim.api.nvim_buf_set_extmark = _9_
    local function _10_(_)
      return {4, 0}
    end
    vim.api.nvim_win_get_cursor = _10_
    local function _11_()
      vim.api.nvim_create_namespace = original_create_namespace
      vim.api.nvim_buf_clear_namespace = original_clear_namespace
      vim.api.nvim_buf_set_lines = original_set_lines
      vim.api.nvim_buf_set_extmark = original_set_extmark
      vim.api.nvim_win_get_cursor = original_get_cursor
      return nil
    end
    local function _12_()
      local widget = steering_area.create(7)
      widget["set-items"]({"check this"})
      local rendered_lines = widget.render(3)
      local on_steering_line_3f = widget["is-on-steering-line?"]()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {namespace = {"eca-steering-area"}, clear = {{7, 42, 0, -1}}, lines = {{7, 3, 3, false, {"-"}}}, extmarks = {{7, 42, 3, 0, {virt_text = {{"Steering: check this [", "EcaSteeringLabel"}}, virt_text_pos = "inline"}}, {7, 42, 3, 1, {virt_text = {{"]", "EcaStopLabel"}}, virt_text_pos = "inline"}}, {7, 42, 3, 0, {end_col = 1, hl_group = "EcaStopLabel"}}}, ["cursor-on-line"] = true, ["rendered-lines"] = 1}
      local actual_7_auto = {namespace = namespace_calls, clear = clear_calls, lines = line_calls, extmarks = extmark_calls, ["cursor-on-line"] = on_steering_line_3f, ["rendered-lines"] = rendered_lines}
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return with_cleanup(_11_, _12_)
  end
  return require("plenary.busted").it("writes the steering line, virtual text, extmarks, and cursor state", _5_)
end
return require("plenary.busted").describe("render", _4_)
