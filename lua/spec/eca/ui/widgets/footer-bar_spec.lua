-- [nfnl] fnl/spec/eca/ui/widgets/footer-bar_spec.fnl
local function with_cleanup(cleanup, f)
  local ok, result = pcall(f)
  cleanup()
  if ok then
    return result
  else
    return error(result, 0)
  end
end
local function with_api_stub(name, stub, f)
  local original = vim.api[name]
  vim.api[name] = stub
  local function _2_()
    vim.api[name] = original
    return nil
  end
  return with_cleanup(_2_, f)
end
local function with_footer_bar(mocks, f)
  local original_lualine = package.loaded["eca.ui.components.lualine"]
  local original_bar_items = package.loaded["eca.ui.components.bar-items"]
  local original_footer_bar = package.loaded["eca.ui.widgets.footer-bar"]
  package.loaded["eca.ui.components.lualine"] = (mocks.lualine or {})
  package.loaded["eca.ui.components.bar-items"] = (mocks["bar-items"] or {})
  package.loaded["eca.ui.widgets.footer-bar"] = nil
  local function _3_()
    package.loaded["eca.ui.components.lualine"] = original_lualine
    package.loaded["eca.ui.components.bar-items"] = original_bar_items
    package.loaded["eca.ui.widgets.footer-bar"] = original_footer_bar
    return nil
  end
  local function _4_()
    local function _5_(_, _0)
      return nil
    end
    local function _6_()
      return f(require("eca.ui.widgets.footer-bar"))
    end
    return with_api_stub("nvim_create_autocmd", _5_, _6_)
  end
  return with_cleanup(_3_, _4_)
end
local function lualine_scenario(items)
  local setup_calls = {}
  local function _7_()
    return true
  end
  local function _8_(new_items)
    return table.insert(setup_calls, new_items)
  end
  local function _9_(_)
    return error("bar-items.render should not be called")
  end
  local function _10_(footer_bar)
    return footer_bar.create(1, 2, items)
  end
  return {widget = with_footer_bar({lualine = {plugin = _7_, setup = _8_}, ["bar-items"] = {render = _9_}}, _10_), ["setup-calls"] = setup_calls}
end
local function native_scenario(items)
  local render_calls = {}
  local function _11_()
    return false
  end
  local function _12_(opts)
    table.insert(render_calls, opts)
    return "rendered"
  end
  local function _13_(footer_bar)
    return footer_bar.create(1, 2, items)
  end
  return {widget = with_footer_bar({lualine = {plugin = _11_}, ["bar-items"] = {render = _12_}}, _13_), ["render-calls"] = render_calls}
end
local function capture_set_option(f)
  local captured = {value = nil}
  local function _14_(name, value, opts)
    captured["value"] = {name, value, opts}
    return nil
  end
  local function _15_()
    f()
    return captured.value
  end
  return with_api_stub("nvim_set_option_value", _14_, _15_)
end
local function create_scenario(items)
  local function _16_(footer_bar)
    return footer_bar.create(1, 2, items)
  end
  return with_footer_bar({}, _16_)
end
local function _17_()
  local function _18_()
    local widget = create_scenario({{value = "initial"}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{value = "initial"}}
    local actual_7_auto = widget["get-state"]()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("get-state returns the initial items", _18_)
  local function _19_()
    local widget = create_scenario(nil)
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = widget["get-state"]()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("nil initial items become an empty table", _19_)
end
require("plenary.busted").describe("create", _17_)
local function _20_()
  local function _21_()
    local _let_22_ = lualine_scenario({{value = "one"}})
    local widget = _let_22_.widget
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = widget.render()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("returns zero", _21_)
  local function _23_()
    local _let_24_ = lualine_scenario({{value = "one"}})
    local widget = _let_24_.widget
    local setup_calls = _let_24_["setup-calls"]
    widget.render()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{{value = "one"}}}
    local actual_7_auto = setup_calls
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("passes the items to lualine.setup when lualine is available", _23_)
  local function _25_()
    local _let_26_ = native_scenario({{value = "two"}})
    local widget = _let_26_.widget
    local render_calls = _let_26_["render-calls"]
    capture_set_option(widget.render)
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{items = {{value = "two"}}}}
    local actual_7_auto = render_calls
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("renders bar-items with the items when lualine is unavailable", _25_)
  local function _27_()
    local _let_28_ = native_scenario({{value = "two"}})
    local widget = _let_28_.widget
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"statusline", "rendered", {}}
    local actual_7_auto = capture_set_option(widget.render)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("sets the native statusline when lualine is unavailable", _27_)
end
require("plenary.busted").describe("render", _20_)
local function _29_()
  local function _30_()
    local _let_31_ = lualine_scenario({{value = "initial"}})
    local widget = _let_31_.widget
    local setup_calls = _let_31_["setup-calls"]
    widget.update({{value = "updated"}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = setup_calls
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("before render does not apply", _30_)
  local function _32_()
    local _let_33_ = lualine_scenario({{value = "initial"}})
    local widget = _let_33_.widget
    widget.update({{value = "updated"}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{value = "updated"}}
    local actual_7_auto = widget["get-state"]()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("before render updates the state", _32_)
  local function _34_()
    local _let_35_ = lualine_scenario({{value = "initial"}})
    local widget = _let_35_.widget
    local setup_calls = _let_35_["setup-calls"]
    widget.render()
    widget.update({{value = "later"}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{{value = "initial"}}, {{value = "later"}}}
    local actual_7_auto = setup_calls
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("after render applies the new items", _34_)
  local function _36_()
    local _let_37_ = lualine_scenario({{value = "initial"}})
    local widget = _let_37_.widget
    widget.update({{value = "updated"}})
    widget.update({{value = "later"}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {{value = "later"}}
    local actual_7_auto = widget["get-state"]()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("get-state reflects later updates", _36_)
end
return require("plenary.busted").describe("update", _29_)
