-- [nfnl] fnl/spec/eca/ui/builder_spec.fnl
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
local function fake_widget()
  local function _4_()
    return 0
  end
  local function _5_(_)
    return nil
  end
  local function _6_()
    return {}
  end
  local function _7_()
    return 0
  end
  local function _8_(_)
    return nil
  end
  local function _9_(_)
    return nil
  end
  local function _10_()
    return false
  end
  local function _11_(_)
    return nil
  end
  local function _12_()
    return false
  end
  local function _13_()
    return nil
  end
  local function _14_(_)
    return nil
  end
  local function _15_()
    return ""
  end
  local function _16_(_)
    return nil
  end
  local function _17_(_)
    return nil
  end
  local function _18_(_)
    return nil
  end
  local function _19_()
    return ""
  end
  local function _20_(_)
    return nil
  end
  local function _21_(_)
    return nil
  end
  local function _22_(_)
    return nil
  end
  local function _23_(_, _0)
    return nil
  end
  local function _24_(_)
    return nil
  end
  local function _25_(_)
    return nil
  end
  return {render = _4_, update = _5_, ["get-state"] = _6_, ["get-end-line"] = _7_, ["set-start-line"] = _8_, ["set-welcome"] = _9_, ["has-items?"] = _10_, ["render-highlights"] = _11_, ["is-on-steering-line?"] = _12_, clear = _13_, ["set-items"] = _14_, ["save-live-text"] = _15_, ["set-text-internal"] = _16_, ["set-status-anchor-line"] = _17_, ["set-status"] = _18_, ["get-text"] = _19_, ["add-to-history"] = _20_, ["set-loading"] = _21_, ["append-message"] = _22_, ["update-message"] = _23_, ["finish-streaming"] = _24_, ["abort-streaming"] = _25_}
end
local function with_builder(f)
  local module_names = {"eca.ui.builder", "eca.ui.highlights", "eca.ui.widgets.header-bar", "eca.ui.widgets.message-list", "eca.ui.widgets.context-area", "eca.ui.widgets.steering-area", "eca.ui.widgets.prompt-area", "eca.ui.widgets.footer-bar"}
  local originals
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, name in ipairs(module_names) do
      local val_28_ = {name, package.loaded[name]}
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    originals = tbl_26_
  end
  local widget = fake_widget()
  local modules
  local function _27_()
    return nil
  end
  local function _28_(_, _0, _1)
    return widget
  end
  local function _29_(_, _0)
    return widget
  end
  local function _30_(_)
    return widget
  end
  local function _31_(_)
    return widget
  end
  local function _32_(_, _0)
    return widget
  end
  local function _33_(_, _0, _1)
    return widget
  end
  modules = {["eca.ui.highlights"] = {setup = _27_}, ["eca.ui.widgets.header-bar"] = {create = _28_}, ["eca.ui.widgets.message-list"] = {create = _29_}, ["eca.ui.widgets.context-area"] = {create = _30_}, ["eca.ui.widgets.steering-area"] = {create = _31_}, ["eca.ui.widgets.prompt-area"] = {create = _32_}, ["eca.ui.widgets.footer-bar"] = {create = _33_}}
  for name, module in pairs(modules) do
    package.loaded[name] = module
  end
  package.loaded["eca.ui.builder"] = nil
  local function _34_()
    for _, original in ipairs(originals) do
      package.loaded[original[1]] = original[2]
    end
    return nil
  end
  local function _35_()
    local builder = require("eca.ui.builder")
    return f(builder)
  end
  return with_cleanup(_34_, _35_)
end
local function create_chat_ui_scenario()
  local function _36_(builder)
    local function _37_(_, _0)
      return 11
    end
    local function _38_(_, _0, _1)
      return 22
    end
    local function _39_(buf)
      return (11 == buf)
    end
    local function _40_(win)
      return (22 == win)
    end
    local function _41_(_, _0)
      return nil
    end
    local function _42_(_, _0)
      return nil
    end
    local function _43_(_, _0, _1)
      return nil
    end
    local function _44_(_, _0, _1, _2, _3)
      return nil
    end
    local function _45_(_)
      return 1
    end
    local function _46_(_, _0, _1, _2)
      return {"> "}
    end
    local function _47_(_)
      return 1
    end
    local function _48_(_, _0, _1, _2)
      return nil
    end
    local function _49_(_, _0, _1, _2, _3)
      return 1
    end
    local function _50_(_)
      return 80
    end
    local function _51_(_, _0)
      return nil
    end
    local function _52_(_, _0, _1)
      return true
    end
    local function _53_(_, _0)
      return nil
    end
    local function _54_()
      local ui
      local function _55_(_)
      end
      local function _56_()
      end
      ui = builder["create-chat-ui"]({["on-submit"] = _55_, ["on-stop"] = _56_, opts = {}})
      ui.open()
      local opened = {["open?"] = ui["is-open?"](), buf = ui["get-buf-id"]()}
      ui.close()
      return {opened = opened, closed = ui["is-open?"]()}
    end
    return with_api_stubs({{name = "nvim_create_buf", value = _37_}, {name = "nvim_open_win", value = _38_}, {name = "nvim_buf_is_valid", value = _39_}, {name = "nvim_win_is_valid", value = _40_}, {name = "nvim_win_close", value = _41_}, {name = "nvim_buf_set_name", value = _42_}, {name = "nvim_set_option_value", value = _43_}, {name = "nvim_buf_set_lines", value = _44_}, {name = "nvim_buf_line_count", value = _45_}, {name = "nvim_buf_get_lines", value = _46_}, {name = "nvim_create_namespace", value = _47_}, {name = "nvim_buf_clear_namespace", value = _48_}, {name = "nvim_buf_set_extmark", value = _49_}, {name = "nvim_win_get_width", value = _50_}, {name = "nvim_win_set_cursor", value = _51_}, {name = "nvim_buf_attach", value = _52_}, {name = "nvim_create_autocmd", value = _53_}}, _54_)
  end
  return with_builder(_36_)
end
local function _57_()
  local state = create_chat_ui_scenario()
  local function _58_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["open?"] = true, buf = 11}
    local actual_7_auto = state.opened
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("opens and exposes its buffer through the public API", _58_)
  local function _59_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = false
    local actual_7_auto = state.closed
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("close makes the public open state false", _59_)
end
return require("plenary.busted").describe("create-chat-ui", _57_)
