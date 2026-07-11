-- [nfnl] fnl/eca/ui/components/lualine.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["eca.ui.components.lualine"] = {}
  _2amodule_2a = pkg_1_auto.loaded["eca.ui.components.lualine"]
end
local enabled_3f
do
  local function enabled_3f0()
    local ok, _ = pcall(require, "lualine")
    return ok
  end
  _2amodule_2a["enabled?"] = enabled_3f0
  enabled_3f = _2amodule_2a["enabled?"]
end
local function build_sections(items)
  local head = "lualine_a"
  local tail = {"lualine_z", "lualine_y", "lualine_x"}
  return {lualine_a = {"%#EcaHeaderValue#Teste"}}
end
local setup
do
  local function setup0(items)
    local _, m = pcall(require, "lualine")
    local sections = build_sections(items)
    return m.setup({extensions = {{filetypes = {"eca-chat"}, sections = sections}}})
  end
  _2amodule_2a["setup"] = setup0
  setup = _2amodule_2a.setup
end
return nil
