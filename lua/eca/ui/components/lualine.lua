-- [nfnl] fnl/eca/ui/components/lualine.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["eca.ui.components.lualine"] = {}
  _2amodule_2a = pkg_1_auto.loaded["eca.ui.components.lualine"]
end
local core = require("eca.nfnl.core")
local filetype = "eca-chat"
local tail_slots = {"lualine_x", "lualine_y", "lualine_z", "lualine_c", "lualine_b"}
local plugin
do
  local function plugin0()
    local ok, lualine = pcall(require, "lualine")
    if ok then
      return lualine
    else
      return nil
    end
  end
  _2amodule_2a["plugin"] = plugin0
  plugin = _2amodule_2a.plugin
end
local function text(item)
  local title = core.get(item, "title", nil)
  local value = core.get(item, "value", nil)
  local title_str
  if title then
    title_str = core.str("%#EcaHeaderKey#", title, ":")
  else
    title_str = ""
  end
  local value_str
  if value then
    value_str = core.str("%#EcaHeaderValue#", value)
  else
    value_str = ""
  end
  return core.str(title_str, value_str)
end
local function add_item(sections, _4_)
  local i = _4_[1]
  local item = _4_[2]
  local slot = core.get(tail_slots, math.min(i, core.count(tail_slots)))
  local current = core.get(sections, slot, {})
  return core.assoc(sections, slot, core.concat(current, {text(item)}))
end
local function build_sections(items)
  return core.reduce(add_item, {lualine_a = {text(core.first(items))}}, core["map-indexed"](core.identity, core.rest(items)))
end
local function eca_extension(items)
  return {filetypes = {filetype}, sections = build_sections(items)}
end
local function eca_3f(ext)
  return core["contains?"](core.get(ext, "filetypes", {}), filetype)
end
local function register(extensions, ext)
  return core.concat(core.filter(core.complement(eca_3f), extensions), {ext})
end
local function register_eca_extension(p, items)
  local config = p.get_config()
  local extensions = core.get(config, "extensions", {})
  local extensions_2beca = register(extensions, eca_extension(items))
  return p.setup(core.assoc(config, "extensions", extensions_2beca))
end
local setup
do
  local function setup0(items)
    local p = plugin()
    if p then
      return register_eca_extension(p, items)
    else
      return nil
    end
  end
  _2amodule_2a["setup"] = setup0
  setup = _2amodule_2a.setup
end
return nil
