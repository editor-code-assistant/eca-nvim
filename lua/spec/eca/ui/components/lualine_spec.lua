-- [nfnl] fnl/spec/eca/ui/components/lualine_spec.fnl
local _local_1_ = require("plenary.busted")
local describe = _local_1_.describe
local it = _local_1_.it
local assert = require("luassert.assert")
local lualine = require("eca.ui.components.lualine")
local function _2_()
  local mock
  local function _3_()
  end
  mock = {setup = _3_}
  local _
  package.loaded.lualine = mock
  _ = nil
  local function _4_()
    return assert.equals(true, lualine["enabled?"]())
  end
  return it("return true when lualine plugin exists", _4_)
end
describe("enabled?", _2_)
local function _5_()
  local captured = {}
  local mock
  local function _6_(cfg)
    captured.cfg = cfg
    return nil
  end
  mock = {setup = _6_}
  local _
  package.loaded.lualine = mock
  _ = nil
  local function _7_()
    assert.equals(nil, lualine.setup({{value = "~/dev/eca-nvim"}, {value = "\226\143\177 0s"}, {value = "0/200K ($0.00)"}}))
    local ext = captured.cfg.extensions[1]
    return assert.same({"eca-chat"}, ext.filetypes)
  end
  return it("setup lualine extension with correct items order", _7_)
end
return describe("setup", _5_)
