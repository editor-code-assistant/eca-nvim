-- [nfnl] fnl/eca/ui/components/context-item.fnl
local type_config = {file = {prefix = "@", ["hl-group"] = "EcaContextFile"}, dir = {prefix = "@", ["hl-group"] = "EcaContextDir"}, ["repo-map"] = {prefix = "@", ["hl-group"] = "EcaContextRepoMap", label = "repoMap"}, cursor = {prefix = "@", ["hl-group"] = "EcaContextCursor"}, mcp = {prefix = "@", ["hl-group"] = "EcaContextMcp"}}
local function render(_1_)
  local type = _1_.type
  local name = _1_.name
  local detail = _1_.detail
  local cfg = (type_config[type] or {prefix = "@", ["hl-group"] = "EcaContextFile"})
  local display_name = (cfg.label or name or "")
  local text
  if (type == "cursor") then
    local _2_
    if detail then
      _2_ = (" " .. detail)
    else
      _2_ = ""
    end
    text = (cfg.prefix .. "cursor(" .. (name or "") .. _2_ .. ")")
  elseif (type == "repo-map") then
    text = (cfg.prefix .. display_name)
  else
    local _ = type
    text = (cfg.prefix .. display_name)
  end
  return {text = text, ["hl-group"] = cfg["hl-group"]}
end
return {render = render}
