-- [nfnl] fnl/spec/eca/ui/components/lualine_spec.fnl
local lualine = require("eca.ui.components.lualine")
local function with_cleanup(cleanup, f)
  local ok, result = pcall(f)
  cleanup()
  if ok then
    return result
  else
    return error(result, 0)
  end
end
local function with_lualine_plugin(plugin, f)
  local original = package.loaded.lualine
  package.loaded["lualine"] = plugin
  local function _2_()
    package.loaded["lualine"] = original
    return nil
  end
  return with_cleanup(_2_, f)
end
local function installed_plugin_scenario()
  local lualine_mock
  local function _3_()
  end
  lualine_mock = {setup = _3_}
  local function _4_()
    return {expected = lualine_mock, actual = lualine.plugin()}
  end
  return with_lualine_plugin(lualine_mock, _4_)
end
local function missing_plugin_scenario()
  local function _5_()
    return lualine.plugin()
  end
  return with_lualine_plugin(false, _5_)
end
local function setup_scenario()
  local captured = nil
  local plugin
  local function _6_()
    return {options = {theme = "gruvbox"}, extensions = {{filetypes = {"other"}}}}
  end
  local function _7_(cfg)
    captured = cfg
    return nil
  end
  plugin = {get_config = _6_, setup = _7_}
  local function _8_()
    lualine.setup({{value = "~/dev/eca-nvim"}, {value = "\226\143\177 0s"}, {value = "0/200K ($0.00)"}})
    return captured
  end
  return with_lualine_plugin(plugin, _8_)
end
local function _9_()
  local function _10_()
    local _let_11_ = installed_plugin_scenario()
    local expected = _let_11_.expected
    local actual = _let_11_.actual
    local assert_19_auto = require("luassert")
    local expected_20_auto = expected
    local actual_21_auto = actual
    assert_19_auto.equals(expected_20_auto, actual_21_auto)
    return true
  end
  require("plenary.busted").it("returns the lualine module when the plugin is installed", _10_)
  local function _12_()
    local assert_25_auto = require("luassert")
    local value_26_auto = missing_plugin_scenario()
    assert_25_auto.is_nil(value_26_auto)
    return true
  end
  return require("plenary.busted").it("returns nil when the plugin is missing", _12_)
end
require("plenary.busted").describe("plugin", _9_)
local function _13_()
  local function _14_()
    local captured = setup_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {extensions = {{filetypes = {"other"}}, {filetypes = {"eca-chat"}, sections = {lualine_a = {"%#EcaHeaderValue#~/dev/eca-nvim"}, lualine_x = {"%#EcaHeaderValue#\226\143\177 0s"}, lualine_y = {"%#EcaHeaderValue#0/200K ($0.00)"}}}}, options = {theme = "gruvbox"}}
    local actual_7_auto = captured
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("registers the eca-chat extension without touching other config", _14_)
end
return require("plenary.busted").describe("setup", _13_)
