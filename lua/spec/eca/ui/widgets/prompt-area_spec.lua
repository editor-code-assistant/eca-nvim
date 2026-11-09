-- [nfnl] fnl/spec/eca/ui/widgets/prompt-area_spec.fnl
local prompt_area = require("eca.ui.widgets.prompt-area")
local function with_cleanup(cleanup, f)
  local ok, result = pcall(f)
  cleanup()
  if ok then
    return result
  else
    return error(result, 0)
  end
end
local function with_api_stubs(stubs, f)
  local originals
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, stub in ipairs(stubs) do
      local val_28_ = {stub.name, vim.api[stub.name]}
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    originals = tbl_26_
  end
  for _, stub in ipairs(stubs) do
    vim.api[stub.name] = stub.value
  end
  local function _3_()
    for _, original in ipairs(originals) do
      vim.api[original[1]] = original[2]
    end
    return nil
  end
  return with_cleanup(_3_, f)
end
local function _4_()
  local function _5_()
    local lines = {"> first", "second"}
    local function _6_(_)
      return 2
    end
    local function _7_(_, start, _end, _0)
      local tbl_26_ = {}
      local i_27_ = 0
      for i, line in ipairs(lines) do
        local val_28_
        if (((i - 1) >= start) and ((i - 1) < _end)) then
          val_28_ = line
        else
          val_28_ = nil
        end
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      return tbl_26_
    end
    local function _10_(_)
      return 1
    end
    local function _11_(_, _0, _1, _2)
      return nil
    end
    local function _12_(_, _0, _1, _2)
      return 1
    end
    local function _13_(_, _0, _1, _2, _3)
      return nil
    end
    local function _14_(_, _0)
      return nil
    end
    local function _15_()
      local widget = prompt_area.create(1)
      local result
      do
        widget["set-text-internal"]("first\nsecond")
        widget.render(0)
        result = widget["get-text"]()
      end
      local assert_5_auto = require("luassert")
      local expected_6_auto = "first\nsecond"
      local actual_7_auto = result
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return with_api_stubs({{name = "nvim_buf_line_count", value = _6_}, {name = "nvim_buf_get_lines", value = _7_}, {name = "nvim_create_namespace", value = _10_}, {name = "nvim_buf_clear_namespace", value = _11_}, {name = "nvim_buf_set_extmark", value = _12_}, {name = "nvim_buf_set_lines", value = _13_}, {name = "nvim_create_autocmd", value = _14_}}, _15_)
  end
  return require("plenary.busted").it("preserves multiline prompt text from zero-based buffer ranges", _5_)
end
return require("plenary.busted").describe("get-text", _4_)
